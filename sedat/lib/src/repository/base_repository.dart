import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';
import 'package:hapnium/hapnium.dart';
import 'package:tracing/tracing.dart';

import '../exceptions/secure_database_exception.dart';
import 'repository_service.dart';

/// {@template base_repository}
/// An abstract repository class providing CRUD (Create, Read, Update, Delete) operations
/// for data of type [Result].
///
/// This class serves as a base for implementing repositories that interact with
/// a local storage using Hive. It handles the underlying storage logic,
/// allowing subclasses to focus on the specific data mapping and business
/// logic.
///
/// Type parameters:
///
/// * [Result]: The type of the data you want to work with (e.g., `User`, `Address`,
///   `List<Item>`). This is the type your application will use.
/// * [Insert]: The type of the data as it's stored in the Hive box (e.g.,
///   `Map<String, dynamic>`, `List<Map<String, dynamic>>`, `String`).  This
///   is often a serialized form of [Result].
///
/// Subclasses *must* implement the [toStore] and [fromStore] methods to handle
/// the conversion between [Result] and [Insert].
/// 
/// {@endtemplate}
abstract class BaseRepository<Result, Insert> implements RepositoryService<Result> {
  /// The Hive box used for storing the data.
  late Box<dynamic> _box;

  /// Whether the repository has been initialized.
  bool _isInitialized = false;

  /// Whether to destroy saved data while uploading changes
  bool _canDestroy = true;

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

  /// The default value to return if the data is null.
  Result? _defaultValue;

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

  /// The stream subscription for listening to Hive box events.
  StreamSubscription<BoxEvent>? _subscription;

  /// The stream controller for broadcasting data changes.
  final StreamController<Result> _controller = StreamController<Result>.broadcast();

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
    bool canDestroy = true
  }) async {
    _showLogs = showLogs;
    _device = device ?? "";
    _platform = platform ?? "";
    _prefix = prefix ?? "";
    _canDestroy = canDestroy;
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

    _box = await Hive.openBox<dynamic>(_name);
    _isInitialized = true;

    if(_showLogs) {
      console.log("$_name local storage box is now open and initialized with key set as $_key", tag: _from);
    }

    _startListening();
  }

  /// Starts listening to changes in the Hive box and emits them to the stream.
  /// 
  /// This method is called by the [open] method and is used to set up a stream
  /// that emits the current data and any subsequent changes to the data in the
  /// Hive box.
  void _startListening() {
    _notifyListeners(get()); // Emit the current data

    _subscription = _box.watch(key: _key).listen((event) {
      if (event.deleted) {
        if(_defaultValue != null) {
          _notifyListeners(_defaultValue as Result);
        } else {
          _notifyListeners(fromStore(null));
        }
      } else {
        _notifyListeners(fromStore(event.value)); // Emit the new value
      }
    });
  }

  /// Notifies listeners of a change in the repository.
  /// 
  /// This method emits the given [result] to the stream controller, which
  /// notifies any listeners of the change.
  void _notifyListeners(Result result) {
    _controller.add(result);
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
  Future<Result> save(Result item) async {
    _throwIfNotInitialized();

    Result result;
    if(put().isNotNull) {
      result = await put()!(_box, _key, item);
    } else {
      Insert data = toStore(item);

      if (data.instanceOf<JsonMap>()) {
        await _box.putAll(data as JsonMap);
      } else if (data.instanceOf<JsonMapCollection>()) {
        for (int i = 0; i < (data as JsonMapCollection).length; i++) {
          String key = i.toString();
          JsonMap value = data[i];

          if(_canDestroy) {
            int index = 0;
            while (_box.containsKey(index.toString())) {
              await _box.delete(index.toString());
              index++;
            }
          } else if(_box.containsKey(key)) {
            int index = _box.keys.findIndex((i) => i == key);
            if(index.notEquals(-1)) {
              _box.putAt(index, value);
            } else {
              await _box.delete(key);
            }
          }

          await _box.put(key, value);
        }
      } else {
        await _box.put(_key, data);
      }

      result = item;
    }

    _notifyListeners(result);
    return result;
  }

  @override
  @nonVirtual
  Result get() {
    if(!_isInitialized) {
      throw SecureDatabaseException("$_exPrefix - Repository is not initialized. Call open() first.");
    } else if(read().isNotNull) {
      return read()!(_box, _key);
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
        JsonMapCollection list = [];

        for (int i = 0;; i++) {
          dynamic item = _box.get(i.toString());
          if (item == null) break;

          if (Instance.of<Map>(item)) {
            item = decode(item);
            list.add(item);
          }
        }
        data = list;
      } else {
        data = _box.get(_key);
      }

      return fromStore(data);
    }
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
  Stream<Result> get stream {
    _throwIfNotInitialized();
    
    return _controller.stream;
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
  @nonVirtual
  int get length => _box.length;

  /// Returns whether the Hive box is empty.
  ///
  /// **Returns:**
  ///
  /// `true` if the box is empty, `false` otherwise.
  @nonVirtual
  bool get isEmpty => _box.isEmpty;

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
  BaseRepository<Result, Insert> registerDefault(Result value) {
    _defaultValue = value;

    return this;
  }

  /// Converts the item [Result] to the storage format [Insert].
  ///
  /// This method *must* be implemented by subclasses to define how the data
  /// is stored in the database.  The conversion process depends on the types
  /// of [Result] and [Insert].
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
  ///   [Result] and [Insert] are the same, you might not need to do any conversion.  If
  ///   they are different, you'll need to transform the data from the format
  ///   of [Result] to the format of [Insert].
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
  Insert toStore(Result item);

  /// Converts the storage format [Insert] to the item format [Result].
  ///
  /// This method *must* be implemented by subclasses to define how the data
  /// is retrieved from the database and converted back into your data model.
  /// The conversion process depends on the types of [Result] and [Insert].  It should be
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
  Result fromStore(Insert? data);

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
  Future<Result> Function(Box<dynamic>, String, Result)? put() {
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
  Result Function(Box<dynamic>, String)? read() {
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

  @override
  @mustCallSuper
  Future<bool> close() async {
    try {
      _subscription?.cancel();
      _controller.close();
      await _box.close();
      _isInitialized = false;

      return true;
    } catch (e) {
      console.error("$_exPrefix - Error closing repository: $e", tag: _from);

      return false;
    }
  }

  @override
  @nonVirtual
  Future<Optional<Result>> delete() async {
    _throwIfNotInitialized();
    
    await _box.delete(_key);
    _notifyListeners(fromStore(null));

    runDelete();
    return Optional.empty<Result>();
  }

  @override
  Future<List<Result>> fetchAll() async {
    throw SecureDatabaseException("$_exPrefix - Method not implemented");
  }

  @override
  Future<void> deleteAll(List<Result> items) async {
    throw SecureDatabaseException("$_exPrefix - Method not implemented");
  }
}