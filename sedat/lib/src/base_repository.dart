// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';
import 'package:hapnium/hapnium.dart';
import 'package:tracing/tracing.dart';

import 'repository_configuration.dart';
import 'secure_database_exception.dart';
import 'repository_service.dart';
import 'streamable_repository.dart';

/// {@template base_repository}
/// An abstract repository class providing CRUD (Create, Read, Update, Delete) operations
/// for data of type [Entity].
///
/// This class serves as a base for implementing repositories that interact with
/// a local storage using Hive. It handles the underlying storage logic,
/// allowing subclasses to focus on the specific data mapping and business
/// logic.
///
/// Type parameters:
///
/// * [Entity]: The type of the data you want to work with (e.g., `User`, `Address`,
///   `List<Item>`). This is the type your application will use.
/// * [Insert]: The type of the data as it's stored in the Hive box (e.g.,
///   `Map<String, dynamic>`, `List<Map<String, dynamic>>`, `String`).  This
///   is often a serialized form of [Entity].
///
/// Subclasses *must* implement the [toStore] and [fromStore] methods to handle
/// the conversion between [Entity] and [Insert].
/// 
/// {@endtemplate}
abstract class BaseRepository<Entity, Insert> extends AbstractStreamableRepository<Entity> implements RepositoryService<Entity> {
  /// The Hive box used for storing the data.
  late Box<dynamic> _box;

  /// Whether the repository has been initialized.
  bool _isInitialized = false;

  /// Whether to show logs during repository operations.
  bool _showLogs = true;

  /// Device identifier for data key.
  String _device = "";

  /// Prefix for database box names.
  String _prefix = "";

  /// Platform identifier for data key.
  String _platform = "";

  /// The name of the Hive box.
  late String _name;

  /// The key used for storing data in the Hive box.
  late String _key;

  /// Helper to compute the meta key used for list storage.
  String _metaKey() => '$_key:list_keys';

  /// Helper for the per-item key prefix used for list storage.
  String _itemPrefix() => '$_key:item:';

  /// Helper to compute the per-item storage key for a given item id.
  String _itemKey(String id) => '${_itemPrefix()}$id';

  /// The default value to return if the data is null.
  Entity? _defaultValue;

  /// Tag for log messages from this class.
  final String _from = "[SD-REPOSITORY]";

  /// Tag for exception messages from this class.
  final String _exPrefix = "[SD-EXCEPTION]";

  /// Creates a new [BaseRepository] instance.
  ///
  /// The [boxName] parameter is the name of the Hive box to use.  It will be
  /// combined with the prefix, device, and platform to create the final box name.
  /// 
  /// {@macro base_repository}
  BaseRepository(String boxName) {
    _name = "$boxName-database";
  }

  /// Opens the Hive box and initializes the repository.
  ///
  /// This method *must* be called before using the repository.  It opens the
  /// Hive box with the given name (combined with prefix, device, and platform)
  /// and sets the [_isInitialized] flag to `true`.
  ///
  /// The optional [prefix], [device], [platform], and [showLogs] parameters
  /// can be used to customize the box name and logging behavior.
  @nonVirtual
  Future<void> open({
    String? prefix,
    String? device,
    String? platform,
    bool showLogs = true,

    @Deprecated("The use of `canDestroy` is no more effective.")
    bool canDestroy = true,
    SecureRepositoryConfiguration? config
  }) async {
    _showLogs = showLogs;
    _device = device ?? "";
    _platform = platform ?? "";
    _prefix = prefix ?? "";
    _name = "${_prefix.toLowerCase()}-$_name";

    _key = "[${_prefix.toUpperCase()}]";

    if (_device.isNotEmpty) {
      _key = ":$_device";
    }

    if (_platform.isNotEmpty) {
      _key += ":$_platform";
    }

    _key += ":$_name";

    if (_showLogs) {
      console.log("Opening $_name local storage box", tag: _from);
    }

    final configuration = config ?? SecureRepositoryConfiguration();

    _box = await Hive.openBox<dynamic>(
      _name,
      encryptionCipher: configuration.encryptionCipher,
      keyComparator: configuration.keyComparator,
      collection: configuration.collection,
      compactionStrategy: configuration.compactionStrategy,
      crashRecovery: configuration.crashRecovery,
      path: configuration.path,
      encryptionKey: configuration.encryptionKey,
      bytes: configuration.bytes
    );
    _isInitialized = true;

    if(_showLogs) {
      console.log("$_name local storage box is now open and initialized with key set as $_key", tag: _from);
    }

    _emitInitial();
  }

  void _emitInitial() {
    try {
      final Entity current = _defaultValue ?? get();
      notifyEvent(ReadRepositoryEvent<Entity>(current));
    } catch (e) {
      // ignore if we cannot obtain the initial value
    }
  }

  /// Notifies listeners of a change in the repository.
  /// 
  /// This method emits the given [result] to the stream controller, which
  /// notifies any listeners of the change.
  void _notifyListeners(Entity result, [Entity? previous]) {
    // If there was no previous value (or it was an empty collection) and
    // the new result is non-empty, treat this as a Create event.
    final bool previousEmpty = previous == null || (previous is Iterable && (previous as Iterable).isEmpty);
    final bool resultEmpty = result is Iterable && (result as Iterable).isEmpty;

    if (previousEmpty && !resultEmpty) {
      notifyEvent(CreateRepositoryEvent<Entity>(result));
    } else {
      notifyEvent(UpdateRepositoryEvent<Entity>(result, previous));
    }
  }

  /// Throws a [SecureDatabaseException] if the repository is not initialized.
  /// 
  /// This method is used to ensure that the repository is initialized before
  /// performing any operations on it.
  void _throwIfNotInitialized() {
    if (!_isInitialized) {
      throw SecureDatabaseException("$_exPrefix - Repository is not initialized. Call open() first.");
    }
  }

  @override
  Future<Entity> save(Entity item) async {
    _throwIfNotInitialized();

    Entity? previous;
    try {
      previous = get();
    } catch (_) {}

    Entity result;
    if(put().isNotNull) {
      result = await put()!(_box, _key, item);
    } else {
      Insert data = toStore(item);

      if (data.instanceOf<JsonMap>()) {
        await _box.putAll(data as JsonMap);
      } else if (data.instanceOf<JsonMapCollection>()) {
        // Store lists in a readable way: keep an ordered list of item ids
        // under a meta key and save each item under its own human-readable key.
        final String metaKey = _metaKey();

        final JsonMapCollection list = data as JsonMapCollection;

        // Load existing ids (if any) and cache existing item values for diffs
        List<String> existingIds = [];
        final dynamic existingMeta = _box.get(metaKey);
        if (existingMeta is List) existingIds = existingMeta.cast<String>();

        final Map<String, dynamic> existingItems = {};
        for (final id in existingIds) {
          final dynamic raw = _box.get(_itemKey(id));
          if (raw == null) continue;
          existingItems[id] = Instance.of<Map>(raw) ? decode(raw) : raw;
        }

        final List<String> newIds = [];

        // Persist items and ensure each has a stable id
        for (int i = 0; i < list.length; i++) {
          dynamic value = list[i];

          String id;
          if (Instance.of<Map>(value) && (value as Map).containsKey('_id') && value['_id'] is String) {
            id = value['_id'] as String;
          } else {
            // simple readable id: epoch + index
            id = '${DateTime.now().microsecondsSinceEpoch}-$i';

            if (Instance.of<Map>(value)) {
              value = Map<String, dynamic>.from(value as Map);
              (value as Map<String, dynamic>)['_id'] = id;
            }
          }

          final bool isNew = !existingItems.containsKey(id);

          // write or update each individual item
          await _box.put(_itemKey(id), value);

          // Prepare a decoded representation for event payloads
          final dynamic storedDecoded = Instance.of<Map>(value) ? decode(value) : value;

          if (isNew) {
            // Emit item-level created event carrying the new item (may be a
            // different type than the repository Entity). Consumers can listen
            // for `ItemCreatedEvent<RepoEntity, ItemType>` to obtain the
            // item.
            notifyEvent(ItemCreatedEvent<Entity, dynamic>(storedDecoded));
          } else {
            // check for content change vs previous and emit per-item update
            final dynamic prev = existingItems[id];
            try {
              final String a = jsonEncode(prev);
              final String b = jsonEncode(storedDecoded);
              if (a != b) {
                notifyEvent(ItemUpdatedEvent<Entity, dynamic>(storedDecoded, prev));
              }
            } catch (_) {}
          }

          newIds.add(id);
        }

        // Remove stale items not present anymore, emitting per-item delete events
        for (final id in existingIds) {
          if (!newIds.contains(id)) {
            final dynamic removed = existingItems[id];
            if (removed != null) {
              notifyEvent(ItemDeletedEvent<Entity, dynamic>(removed));
            }

            await _box.delete(_itemKey(id));
          }
        }

        // update meta key preserving order
        await _box.put(metaKey, newIds);

        // Persisted. Now emit a repository-level create or update event
        final JsonMapCollection newCollectionData = [];
        for (final id in newIds) {
          final dynamic s = _box.get(_itemKey(id));
          if (s == null) continue;
          newCollectionData.add(Instance.of<Map>(s) ? decode(s) : s);
        }

        final Entity newSnapshot = fromStore(newCollectionData as Insert?);

        // If there was no previous content treat this as a Create at repository level
        final bool wasEmpty = previous == null || (previous is Iterable && (previous as Iterable).isEmpty);
        if (wasEmpty) {
          notifyEvent(CreateRepositoryEvent<Entity>(newSnapshot));
        } else {
          notifyEvent(UpdateRepositoryEvent<Entity>(newSnapshot, previous));
        }
      } else {
        await _box.put(_key, data);
      }

      result = item;
    }

    _notifyListeners(result, previous);
    return result;
  }

  @override
  @nonVirtual
  Entity get() {
    if(!_isInitialized) {
      throw SecureDatabaseException("$_exPrefix - Repository is not initialized. Call open() first.");
    } else if(read() case final reader?) {
      return reader(_box, _key);
    } else {
      dynamic data;

      if (Insert.instanceOf<JsonMap>()) {
        JsonMap map = {};

        for (final key in _box.keys) {
          if (key is String) {
            var value = _box.get(key);

            if(Instance.of<Map>(value)) {
              value = decode(value);
            }

            map[key] = value;
          }
        }
        data = map;
      } else if (Insert.instanceOf<JsonMapCollection>()) {
        // New format: a meta key stores ordered item ids and each item is
        // stored under a readable per-item key. Fall back to numeric-index
        // format for backwards compatibility.
        final String metaKey = _metaKey();

        final dynamic meta = _box.get(metaKey);

        if (meta is List) {
          // New format: iterate ordered ids and fetch each item
          JsonMapCollection list = [];
          for (final dynamic idD in meta) {
            final String id = idD.toString();
            final dynamic item = _box.get(_itemKey(id));
            if (item == null) continue;

            if (Instance.of<Map>(item)) {
              list.add(decode(item));
            } else {
              list.add(item);
            }
          }
          data = list;
        } else {
          // Fallback to older numeric keys approach
          JsonMapCollection list = [];

          for (int i = 0;; i++) {
            dynamic item = _box.get(i.toString());
            if (item == null) break;

            if (Instance.of<Map>(item)) {
              item = decode(item);
            }

            list.add(item);
          }

          data = list;
        }
      } else {
        data = _box.get(_key);
      }

      if (data == null && _defaultValue != null) {
        return _defaultValue as Entity;
      }

      return fromStore(data);
    }
  }

  @override
  @mustCallSuper
  Future<bool> close() async {
    try {
      await _box.close();
      disposeStreamable();
      _isInitialized = false;

      return true;
    } catch (e) {
      console.error("$_exPrefix - Error closing repository: $e", tag: _from);

      return false;
    }
  }

  @override
  @nonVirtual
  Future<Optional<Entity>> delete() async {
    _throwIfNotInitialized();

    // Capture previous snapshot (if any)
    Entity? previous;
    try {
      previous = get();
    } catch (_) {
      previous = null;
    }

    // Delete primary key
    await _box.delete(_key);

    // Clean up list meta and item keys if present
    final String metaKey = _metaKey();
    await _box.delete(metaKey);

    final String itemPrefix = _itemPrefix();
    final List<dynamic> keysToRemove = _box.keys
        .where((k) => k is String && k.startsWith(itemPrefix))
        .toList();

    for (final dynamic k in keysToRemove) {
      await _box.delete(k);
    }

    // Emit a delete event with the previous snapshot (may be null)
    notifyEvent(DeleteRepositoryEvent<Entity>(previous));

    // Also emit an update event indicating the repository now contains the default/null
    _notifyListeners(fromStore(null), previous);

    runDelete();
    return Optional.empty<Entity>();
  }

  @override
  Future<List<Entity>> fetchAll() async {
    _throwIfNotInitialized();

    try {
      final Entity current = get();

      // If the current snapshot is an iterable, return its elements as a list
      if (current is Iterable) {
        return (current as Iterable).cast<Entity>().toList();
      }

      // Single value repository: return a single-element list when present
      return [current];
    } catch (_) {
      // Fallback: try to reconstruct from storage directly for collection format
      if (Insert.instanceOf<JsonMapCollection>()) {
        final String metaKey = _metaKey();
        final dynamic meta = _box.get(metaKey);
        List<Entity> results = [];

        if (meta is List) {
          for (final dynamic idD in meta) {
            final String id = idD.toString();
            final dynamic item = _box.get(_itemKey(id));
            if (item == null) continue;

            dynamic decoded = item;
            if (Instance.of<Map>(decoded)) decoded = decode(decoded);

            try {
              // Try to convert a single item to Entity by using fromStore when
              // possible. If that fails, attempt a direct cast.
              final Entity e = fromStore(decoded as Insert?);
              results.add(e);
            } catch (_) {
              results.add(decoded as Entity);
            }
          }
        } else {
          // Fallback to numeric-index approach
          for (int i = 0;; i++) {
            dynamic item = _box.get(i.toString());
            if (item == null) break;

            if (Instance.of<Map>(item)) {
              item = decode(item);
            }

            try {
              final Entity e = fromStore(item as Insert?);
              results.add(e);
            } catch (_) {
              results.add(item as Entity);
            }
          }
        }

        return results;
      }

      // If nothing else works return empty list
      return <Entity>[];
    }
  }

  @override
  Future<void> deleteAll(List<Entity> items) async {
    _throwIfNotInitialized();

    if (!Insert.instanceOf<JsonMapCollection>()) {
      // For non-collection types, treat deleteAll as bulk delete only when
      // the provided items match the stored value
      try {
        final Entity current = get();
        for (final Entity i in items) {
          if (i == current) {
            await delete();
            return;
          }
        }
      } catch (_) {}

      throw SecureDatabaseException("$_exPrefix - deleteAll is only supported for collection repositories");
    }

    final String metaKey = _metaKey();

    final dynamic meta = _box.get(metaKey);
    if (meta is! List) {
      // Numeric-index legacy case: collect previous state first
      final List<dynamic> previousData = [];
      for (int i = 0;; i++) {
        final String key = i.toString();
        final dynamic stored = _box.get(key);
        if (stored == null) break;

        dynamic decoded = stored;
        if (Instance.of<Map>(decoded)) decoded = decode(decoded);
        previousData.add(decoded);
      }

      // Find keys to remove
      List<String> toDeleteIds = [];

      for (int i = 0; i < previousData.length; i++) {
        final String key = i.toString();
        final dynamic storedDecoded = previousData[i];

        for (final Entity candidate in items) {
          bool matches = false;

          // If candidate is a Map and contains _id, match by id
          if (Instance.of<Map>(candidate) && (candidate as Map).containsKey('_id')) {
            final String id = (candidate as Map)['_id'].toString();
            if (id == key) matches = true;
          }

          // Otherwise compare by JSON content
          if (!matches) {
            try {
              final String a = jsonEncode(storedDecoded);
              final String b = jsonEncode(candidate);
              if (a == b) matches = true;
            } catch (_) {}
          }

          if (matches) {
            toDeleteIds.add(key);
          }
        }
      }

      // Perform deletions and emit events
      for (final id in toDeleteIds) {
        final dynamic removed = _box.get(id);
        final dynamic decodedRemoved = Instance.of<Map>(removed) ? decode(removed) : removed;
        await _box.delete(id);
        notifyEvent(ItemDeletedEvent<Entity, dynamic>(decodedRemoved));
      }

      // Reconstruct new state after deletions
      final JsonMapCollection newData = [];
      for (int i = 0;; i++) {
        final String key = i.toString();
        final dynamic stored = _box.get(key);
        if (stored == null) break;
        newData.add(Instance.of<Map>(stored) ? decode(stored) : stored);
      }

      final Entity previousSnapshot = fromStore(previousData as Insert?);
      final Entity newSnapshot = fromStore(newData as Insert?);

      _notifyListeners(newSnapshot, previousSnapshot);

      return;
    }

    List<String> existingIds = meta.cast<String>();
    final List<String> newIds = List<String>.from(existingIds);

    // Capture previous collection snapshot before deletions
    final List<dynamic> previousCollectionData = [];
    for (final id in existingIds) {
      final dynamic s = _box.get(_itemKey(id));
      if (s == null) continue;
      previousCollectionData.add(Instance.of<Map>(s) ? decode(s) : s);
    }

    final List<String> removedIds = [];

    for (final Entity candidate in items) {
      String? matchedId;

      // If candidate is a Map with an `_id`, use it directly
      if (Instance.of<Map>(candidate) && (candidate as Map).containsKey('_id')) {
        matchedId = (candidate as Map)['_id']?.toString();
        if (matchedId != null && !existingIds.contains(matchedId)) matchedId = null;
      }

      if (matchedId == null) {
        // Try matching by JSON representation
        for (final id in existingIds) {
          final dynamic stored = _box.get(_itemKey(id));
          if (stored == null) continue;

          dynamic decoded = stored;
          if (Instance.of<Map>(decoded)) decoded = decode(decoded);

          try {
            final String a = jsonEncode(decoded);
            final String b = jsonEncode(candidate);
            if (a == b) {
              matchedId = id;
              break;
            }
          } catch (_) {}
        }
      }

      if (matchedId != null) {
        removedIds.add(matchedId);
        newIds.remove(matchedId);
        final dynamic removed = _box.get(_itemKey(matchedId));

        await _box.delete(_itemKey(matchedId));

        // Emit an event for each removed item with the removed item as payload
        final dynamic decodedRemoved = Instance.of<Map>(removed) ? decode(removed) : removed;
        notifyEvent(ItemDeletedEvent<Entity, dynamic>(decodedRemoved));
      }
    }

    // Persist updated keys preserving order
    await _box.put(metaKey, newIds);

    // Emit update event for the collection change
    final JsonMapCollection newCollectionData = [];
    for (final id in newIds) {
      final dynamic stored = _box.get(_itemKey(id));
      if (stored == null) continue;
      newCollectionData.add(Instance.of<Map>(stored) ? decode(stored) : stored);
    }

    final Entity newSnapshot = fromStore(newCollectionData as Insert?);
    final Entity previousSnapshot = fromStore(previousCollectionData as Insert?);

    _notifyListeners(newSnapshot, previousSnapshot);
  }

  /// Returns a stream of data changes from the Hive box.
  ///
  /// This method provides a stream that emits the current data and any
  /// subsequent changes to the data in the Hive box.
  ///
  /// **Returns:**
  ///
  /// A `Stream<Result>` that emits the current data and any changes.
  ///
  /// **Throws:**
  ///
  /// * [SecureDatabaseException] if the repository is not initialized.
  @nonVirtual
  @Deprecated("Use `streamable() or streamableEvents()")
  Stream<Entity> get stream {
    _throwIfNotInitialized();
    
    return super.streamable();
  }

  /// Disposes of the repository and cancels the stream subscription.
  ///
  /// This method should be called when the repository is no longer needed to
  /// release resources and prevent memory leaks.
  @mustCallSuper
  void dispose() {
    close();
  }

  /// Returns an iterable of the keys in the Hive box.
  ///
  /// **Returns:**
  ///
  /// An `Iterable<dynamic>` containing the keys.
  @nonVirtual
  Iterable<dynamic> get keys => _box.keys;

  /// Returns the number of items in the Hive box.
  ///
  /// **Returns:**
  ///
  /// The number of items as an `int`.
  /// 
  /// This is different from [length] which gets the length of this stream while [getLength] gets the length of items in the store.
  @nonVirtual
  int getLength() => _box.length;

  /// Returns whether the Hive box is empty.
  ///
  /// **Returns:**
  ///
  /// `true` if the box is empty, `false` otherwise.
  /// This is different from [isEmpty] which gets the length of this stream while [isStoreEmpty] gets the length of items in the store.
  @nonVirtual
  bool isStoreEmpty() => _box.isEmpty;

  /// Returns whether the Hive box is not empty.
  ///
  /// **Returns:**
  ///
  /// `true` if the box is not empty, `false` otherwise.
  @nonVirtual
  bool get isNotEmpty => _box.isNotEmpty;

  /// Returns the key at the specified index in the Hive box.
  ///
  /// **Parameters:**
  ///
  /// * `index`: The index of the key to retrieve.
  ///
  /// **Returns:**
  ///
  /// The key at the specified index.
  @nonVirtual
  dynamic keyAt(int index) => _box.keyAt(index);

  /// Returns the name of the Hive box.
  ///
  /// **Returns:**
  ///
  /// The name of the box as a `String`.
  @nonVirtual
  String get name => _name;

  /// Recursively decodes a dynamic data structure, handling nested lists and maps.
  ///
  /// This function converts nested lists and maps into appropriate Dart types,
  /// ensuring that maps are represented as `JsonMap` objects.  Basic types are
  /// returned as-is.
  ///
  /// **Parameters:**
  ///
  /// * `data`: The dynamic data structure to decode. This can be a `Map`, a
  ///   `List`, or any other type.
  ///
  /// **Returns:**
  ///
  /// The decoded data structure.  Lists are returned as `List<dynamic>`, maps
  /// as `JsonMap`, and other types are returned as their original type.
  ///
  /// **Behavior:**
  ///
  /// * **Lists:** If `data` is a `List`, the function recursively calls itself
  ///   on each item in the list and returns a new `List` containing the
  ///   decoded items.
  /// * **Maps:** If `data` is a `Map`, the function recursively calls itself
  ///   on each value in the map and returns a `JsonMap` with the same keys
  ///   and the recursively decoded values.
  /// * **Other types:** If `data` is neither a `List` nor a `Map`, it is returned
  ///   as-is.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// dynamic nestedData = {
  ///   'name': 'Example',
  ///   'items': [
  ///     {'id': 1, 'value': 'A'},
  ///     {'id': 2, 'value': 'B'},
  ///   ],
  ///   'details': {
  ///     'address': '123 Main St',
  ///     'city': 'Anytown',
  ///   },
  /// };
  ///
  /// dynamic decodedData = decode(nestedData);
  ///
  /// print(decodedData);
  /// // Output: {name: Example, items: [{id: 1, value: A}, {id: 2, value: B}], details: {address: 123 Main St, city: Anytown}}
  /// ```
  dynamic decode(dynamic data) {
    if (Instance.of<List>(data)) {
      // If it's a list, recursively apply to all items
      return (data as List).map((dynamic item) => decode(item)).toList();
    } else if (Instance.of<Map>(data)) {
      return JsonMap.from(data.map((dynamic key, dynamic nested) {
        return MapEntry(key, decode(nested));
      }));
    } else {
      return data;
    }
  }

  /// Registers a default value to be returned if the data is null.
  /// 
  /// This method sets the default value that will be returned when data is
  /// retrieved from the database and found to be null.
  /// 
  /// **Parameters:**
  /// 
  /// * `value`: The default value to register.
  /// 
  /// **Returns:**
  /// 
  /// The [BaseRepository] instance for method chaining.
  BaseRepository<Entity, Insert> registerDefault(Entity value) {
    _defaultValue = value;

    return this;
  }

  /// Converts the item [Entity] to the storage format [Insert].
  ///
  /// This method *must* be implemented by subclasses to define how the data
  /// is stored in the database.  The conversion process depends on the types
  /// of [Entity] and [Insert].
  ///
  /// **Common Cases:**
  ///
  /// * **`JsonMap` (Result is your data model, Insert is `Map<String, dynamic>`):**
  ///   Convert your data model object into a `Map<String, dynamic>` that can
  ///   be stored in the database.  This typically involves serializing the
  ///   data model's properties into a map.
  /// * **`JsonMapCollection` (Result is your data model, Insert is `List<Map<String, dynamic>>`):**
  ///   If you are storing a collection of your data models, convert each data
  ///   model object into a `Map<String, dynamic>` and return a `List` of
  ///   these maps.
  /// * **Other Types (Result and Insert are the same or different):**
  ///   For other data types, implement the appropriate conversion logic.  If
  ///   [Entity] and [Insert] are the same, you might not need to do any conversion.  If
  ///   they are different, you'll need to transform the data from the format
  ///   of [Entity] to the format of [Insert].
  ///
  /// Example (`JsonMap` case):
  ///
  /// ```dart
  /// @override
  /// Map<String, dynamic> toStore(User user) {
  ///   return {
  ///     'name': user.name,
  ///     'age': user.age,
  ///   };
  /// }
  /// ```
  ///
  /// Example (`JsonMapCollection` case):
  ///
  /// ```dart
  /// @override
  /// List<Map<String, dynamic>> toStore(List<User> users) {
  ///   return users.map((user) => user.toJson()).toList();
  /// }
  /// ```
  Insert toStore(Entity item);

  /// Converts the storage format [Insert] to the item format [Entity].
  ///
  /// This method *must* be implemented by subclasses to define how the data
  /// is retrieved from the database and converted back into your data model.
  /// The conversion process depends on the types of [Entity] and [Insert].  It should be
  /// the inverse of the [toStore] method.
  ///
  /// **Common Cases:**
  ///
  /// * **`JsonMap` (Result is your data model, Insert is `Map<String, dynamic>`):**
  ///   Convert the `Map<String, dynamic>` retrieved from the database back
  ///   into an instance of your data model.  This typically involves
  ///   deserializing the map's properties into the data model's fields.
  /// * **`JsonMapCollection` (Result is your data model, Insert is `List<Map<String, dynamic>>`):**
  ///   If you stored a collection of data models, convert each `Map<String, dynamic>`
  ///   in the list back into an instance of your data model.
  /// * **Other Types (Result and Insert are the same or different):**
  ///   For other data types, implement the appropriate conversion logic to
  ///   reconstruct your data model from the stored data.
  ///
  /// Example (`JsonMap` case):
  ///
  /// ```dart
  /// @override
  /// User fromStore(Map<String, dynamic>? data) {
  ///   if (data == null) {
  ///     return User(name: '', age: 0); // Or handle null as needed
  ///   }
  ///   return User(
  ///     name: data['name'] as String,
  ///     age: data['age'] as int,
  ///   );
  /// }
  /// ```
  ///
  /// Example (`JsonMapCollection` case):
  ///
  /// ```dart
  /// @override
  /// List<User> fromStore(List<Map<String, dynamic>>? data) {
  ///   if (data == null) {
  ///     return []; // Or handle null as needed
  ///   }
  ///   return data.map((json) => User.fromJson(json)).toList();
  /// }
  /// ```
  Entity fromStore(Insert? data);

  /// User-provided put function.
  ///
  /// This function allows users to provide a custom implementation for
  /// storing data in the Hive box.
  ///
  /// If provided, this function will be used instead of the default put logic.
  ///
  /// **Parameters:**
  ///
  /// * `Box<dynamic> box`: The Hive box to store the data in.
  /// * `String key`: The key to use for storing the data.
  /// * `Result value`: The value to store.
  ///
  /// **Returns:**
  ///
  /// A `Future<Result>` that completes when the data is stored, or `null` if the
  /// default put logic should be used.
  Future<Entity> Function(Box<dynamic>, String, Entity)? put() {
    return null;
  }

  /// User-provided read function.
  ///
  /// This function allows users to provide a custom implementation for
  /// reading data from the Hive box.
  ///
  /// If provided, this function will be used instead of the default read logic.
  ///
  /// **Parameters:**
  ///
  /// * `Box<dynamic> box`: The Hive box to read the data from.
  /// * `String key`: The key to use for retrieving the data.
  ///
  /// **Returns:**
  ///
  /// The value read from the box, or `null` if the default read logic should
  /// be used.
  Entity Function(Box<dynamic>, String)? read() {
    return null;
  }

  /// Handles the deletion of data.
  ///
  /// This method is responsible for deleting data from the storage.
  /// Subclasses can override this method to provide custom deletion logic.
  ///
  /// By default, this method performs no action.
  ///
  /// **Returns:**
  ///
  /// A `Future<void>` that completes when the deletion is finished.
  Future<void> runDelete() async {}
}