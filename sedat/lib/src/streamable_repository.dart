import 'dart:async';

import 'package:meta/meta.dart';

/// {@template repository_event}
/// Represents a single high-level lifecycle event emitted by a repository.
///
/// The base `RepositoryEvent` is an immutable value type that optionally
/// carries an entity payload. Subclasses represent concrete lifecycle
/// operations (Create, Read, Update, Delete) and may add extra fields or
/// behaviour (for example previous snapshots on update events).
///
/// Fields:
/// - `entity` (nullable): The primary entity payload associated with the
///   event. It may be `null` for events that represent removals or empty
///   states.
///
/// Behaviour:
/// - Events are plain data objects and should not perform I/O or side
///   effects. They are intended to be emitted by repositories and observed
///   by subscribers.
/// - Consumers must defensively handle `null` entities.
///
/// Example:
/// ```dart
/// final e = ReadRepositoryEvent<User>(user);
/// final user = e.getEntity(); // may be null
/// ```
/// {@endtemplate}
abstract final class RepositoryEvent<Entity> {
  /// The payload entity for the event, if any.
  final Entity? _entity;

  const RepositoryEvent(this._entity);

  /// Retrieve the entity payload carried by this event.
  ///
  /// Returns:
  /// - The associated entity, or `null` if the event has no payload.
  ///
  /// Notes:
  /// - Consumers must defensively handle `null` values.
  /// - This accessor is inexpensive and returns the underlying reference (no
  ///   defensive copy is performed).
  ///
  /// Example:
  /// ```dart
  /// final e = ReadRepositoryEvent<User>(user);
  /// final user = e.getEntity(); // may be null
  /// ```
  Entity? getEntity() => _entity;
}

/// {@template create_repository_event}
/// Event emitted when a repository successfully creates or inserts an
/// entity.
///
/// The event's payload is the created entity (non-null in typical
/// implementations). Subscribers may use this to update in-memory views
/// or trigger side-effects.
///
/// Example:
/// ```dart
/// repository.streamableEvents().listen((e) {
///   if (e is CreateRepositoryEvent<User>) {
///     // handle created user
///   }
/// });
/// ```
/// {@endtemplate}
final class CreateRepositoryEvent<Entity> extends RepositoryEvent<Entity> {
  /// {@macro create_repository_event}
  CreateRepositoryEvent(super.entity);
}

/// {@template read_repository_event}
/// Event emitted when a repository performs a read operation or emits its
/// initial value.
///
/// The payload contains the read entity and may be `null` when no value is
/// present (unless a default value is configured).
///
/// Use this event to update UI state on initial load or when a manual read
/// is performed.
/// {@endtemplate}
final class ReadRepositoryEvent<Entity> extends RepositoryEvent<Entity> {
  /// {@macro read_repository_event}
  ReadRepositoryEvent(super.entity);
}

/// {@template update_repository_event}
/// Event emitted when an entity is updated or replaced in the repository.
///
/// Fields:
/// - `entity`: The new entity snapshot.
/// - `previous`: The prior entity snapshot if known, otherwise `null`.
///
/// Consumers can use `getPreviousEntity()` to compute diffs or undo
/// operations.
/// {@endtemplate}
final class UpdateRepositoryEvent<Entity> extends RepositoryEvent<Entity> {
  /// The previous entity snapshot when available.
  final Entity? _previous;

  /// {@macro update_repository_event}
  UpdateRepositoryEvent(super.entity, this._previous);

  /// Retrieve the previous entity snapshot, if available.
  ///
  /// Returns:
  /// - The prior entity snapshot, or `null` when the previous value is not
  ///   known or the update replaced an absent value.
  ///
  /// Notes:
  /// - Useful for computing diffs, implementing undo, or audit logging.
  /// - The returned reference should be treated as immutable by consumers.
  ///
  /// Example:
  /// ```dart
  /// if (event is UpdateRepositoryEvent<User>) {
  ///   final prev = event.getPreviousEntity();
  ///   // compare prev and event.getEntity()
  /// }
  /// ```
  Entity? getPreviousEntity() => _previous;
}

/// {@template delete_repository_event}
/// Event emitted after a delete operation.
///
/// The payload of this event is flexible and context-dependent:
/// - For repositories that represent a single stored value, the payload will
///   typically contain the removed entity (or `null` if nothing was present).
/// - For collection-oriented repositories (for example, when the repository
///   stores a `List<T>`), the payload *may* contain the single item that was
///   removed from the collection rather than the entire collection value.
///
/// This design allows consumers to react to granular removals (delete of a
/// single list item) or full removals (delete of the whole stored value).  
/// Implementations should document what the event payload contains so
/// subscribers can safely interpret it.
///
/// Examples:
/// ```dart
/// // Deleting a single item from a list-backed repository:
/// notifyEvent(DeleteRepositoryEvent(deletedItem));
///
/// // Deleting the repository's primary value and returning the removed value:
/// notifyEvent(DeleteRepositoryEvent(previousValue));
/// ```
/// {@endtemplate}
final class DeleteRepositoryEvent<Entity> extends RepositoryEvent<Entity> {
  /// {@macro delete_repository_event}
  DeleteRepositoryEvent(super.entity);
}

/// Event emitted when a single item in a collection-backed repository is
/// created.
///
/// This event focuses on the *item* that was added (not the repository
/// snapshot). The type parameters are:
/// - `Entity`: the repository entity type (for consumers that inspect the
///   repository-level events).
/// - `Item`: the concrete type of the added item (e.g. `RuleVersionControl`).
///
/// Behavior:
/// - The event does *not* populate the `RepositoryEvent.getEntity()` value
///   (it is intentionally `null`) because item events carry the item in a
///   separate accessor. This avoids confusing the repository snapshot type
///   with the item type.
///
/// Example:
/// ```dart
/// repo.streamableEvents().listen((e) {
///   if (e is ItemCreatedEvent<List<RuleVersionControl>, RuleVersionControl>) {
///     final created = e.getItem();
///     // handle created item
///   }
/// });
/// ```
final class ItemCreatedEvent<Entity, Item> extends RepositoryEvent<Entity> {
  /// The created item payload.
  final Item _item;

  /// Create a new item-created event carrying the item payload.
  ItemCreatedEvent(this._item) : super(null);

  /// Retrieve the created item.
  Item getItem() => _item;
}

/// Event emitted when a single item in a collection-backed repository is
/// updated.
///
/// Carries both the new item and, optionally, the previous item snapshot.
/// Like other item events, `getEntity()` is left `null` — use `getItem()` and
/// `getPreviousItem()` to access item-level payloads.
///
/// Example:
/// ```dart
/// repo.streamableEvents().listen((e) {
///   if (e is ItemUpdatedEvent<List<MyModel>, MyModel>) {
///     final updated = e.getItem();
///     final previous = e.getPreviousItem();
///     // handle update
///   }
/// });
/// ```
final class ItemUpdatedEvent<Entity, Item> extends RepositoryEvent<Entity> {
  final Item _item;
  final Item? _previousItem;

  /// Create an item-updated event with `item` and an optional `previousItem`.
  ItemUpdatedEvent(this._item, [this._previousItem]) : super(null);

  /// The updated item payload.
  Item getItem() => _item;

  /// The previous item payload, if available.
  Item? getPreviousItem() => _previousItem;
}

/// Event emitted when a single item in a collection-backed repository is
/// deleted.
///
/// The event carries the deleted item as payload and, like other item
/// events, does not populate `RepositoryEvent.getEntity()`.
///
/// Use case:
/// - Use `ItemDeletedEvent<RepoEntity, ItemType>` when a single element is
///   removed from a collection and consumers should receive that element.
/// - Use `DeleteRepositoryEvent<RepoEntity>` when the repository's *entire*
///   stored value is removed (for example, `delete()` on a single-value
///   repository) and you want to communicate the removed snapshot.
///
/// Example:
/// ```dart
/// repo.streamableEvents().listen((e) {
///   if (e is ItemDeletedEvent<List<T>, T>) {
///     final removed = e.getItem();
///     // handle single-item removal
///   }
/// });
/// ```
final class ItemDeletedEvent<Entity, Item> extends RepositoryEvent<Entity> {
  final Item _item;

  /// Create an item-deleted event carrying the deleted item payload.
  ItemDeletedEvent(this._item) : super(null);

  /// Retrieve the deleted item.
  Item getItem() => _item;
}

/// {@template streamable_repository}
/// Interface defining a stable streaming contract for repositories.
///
/// This contract provides two observable surfaces:
/// - `streamableEvents()` — a stream of `RepositoryEvent<Entity>` instances
///   representing high-level lifecycle events (create/read/update/delete).
/// - `streamable()` — a convenience stream emitting the entity
///   snapshots themselves whenever an event with a non-null entity occurs.
///
/// Design considerations:
/// - Decouples consumers from backend-specific change notifications (e.g.
///   Hive `Box.watch`) and standardizes event emission across repository
///   implementations.
/// - Implementations should ensure events are emitted in a deterministic
///   order and document threading/async behaviour.
/// - Consumers should not rely on any single concrete event type unless
///   they explicitly check using `is` checks.
///
/// Methods are provided to intercept events (`onEvent`) and to close the
/// underlying streams (`closeStream`).
///
/// Example:
/// ```dart
/// final sub = repository.streamableEvents().listen((event) {
///   if (event is UpdateRepositoryEvent<User>) {
///     // update UI
///   }
/// });
/// ```
/// {@endtemplate}
abstract interface class StreamableRepository<Entity> extends Stream<RepositoryEvent<Entity>> {
  /// Returns a stream of high-level repository events.
  ///
  /// Returns:
  /// - A broadcast `Stream<RepositoryEvent<Entity>>` suitable for multiple
  ///   listeners.
  ///
  /// Example — subscribe to events and handle update/create/delete:
  /// ```dart
  /// final sub = repo.streamableEvents().listen((event) {
  ///   if (event is CreateRepositoryEvent<MyModel>) {
  ///     // handle creation
  ///   } else if (event is UpdateRepositoryEvent<MyModel>) {
  ///     final previous = event.getPreviousEntity();
  ///     // handle update
  ///   } else if (event is DeleteRepositoryEvent<MyModel>) {
  ///     // clean up
  ///   }
  /// }, onError: (e) {
  ///   // log or handle error from listeners
  /// });
  ///
  /// // remember to cancel when no longer needed:
  /// // await sub.cancel();
  /// ```
  Stream<RepositoryEvent<Entity>> streamableEvents();

  /// Returns a convenience stream of entity snapshots.
  ///
  /// The stream emits the entity payload for events that carry a non-null
  /// entity. The stream is suitable for UI updates and state synchronization.
  ///
  /// Example — listen to entity snapshots directly for UI binding:
  /// ```dart
  /// final sub = repo.streamable().listen((entity) {
  ///   // update view model with `entity`
  /// });
  /// // cancel when done: await sub.cancel();
  /// ```
  Stream<Entity> streamable();

  /// Lifecycle hook invoked when an event is published.
  ///
  /// Default behaviour should be to forward the event to subscribers. Use
  /// this hook to perform side-effects, logging or to transform events
  /// before emission. If overridden, ensure events are still emitted when
  /// appropriate.
  ///
  /// Example — intercept events and add logging before forwarding:
  /// ```dart
  /// @override
  /// FutureOr<void> onEvent(RepositoryEvent<MyModel> event) {
  ///   logger.info('Event: ${event.runtimeType}');
  ///   // forward to subscribers
  ///   return super.onEvent(event);
  /// }
  /// ```
  FutureOr<void> onEvent(RepositoryEvent<Entity> event);

  /// Close the repository streams and release resources.
  ///
  /// This should be idempotent: calling `closeStream()` multiple times
  /// should not throw.
  ///
  /// Example:
  /// ```dart
  /// repo.closeStream();
  /// // or as part of tear down
  /// await repo.close();
  /// ```
  void closeStream();
}

/// {@template abstract_streamable_repository}
/// Base implementation providing consistent streaming behaviour for
/// repositories.
///
/// `AbstractStreamableRepository` encapsulates the mechanics of event
/// publication and exposes two internal controllers:
/// - `_eventController`: `StreamController<RepositoryEvent<Entity>>`
/// - `_valueController`: `StreamController<Entity>`
///
/// Subclasses should call `notifyEvent` to publish events or override
/// `onEvent` to intercept events and perform side-effects. The controllers
/// are created as broadcast streams to support multiple concurrent
/// subscribers.
///
/// Lifecycle:
/// - Call `disposeStreamable()` (or `closeStream()`) as part of repository
///   shutdown to free resources.
/// - After closing, further emissions should be avoided; calling
///   `closeStream()` multiple times is safe and should be idempotent.
///
/// Example:
/// ```dart
/// class MyRepo extends AbstractStreamableRepository<MyEntity> {
///   void example() {
///     notifyEvent(CreateRepositoryEvent<MyEntity>(entity));
///   }
/// }
/// ```
/// {@endtemplate}
/// {@macro abstract_streamable_repository}
abstract class AbstractStreamableRepository<Entity> extends StreamableRepository<Entity> {
  /// Broadcast controller that publishes raw `RepositoryEvent<Entity>` values.
  ///
  /// - Supports multiple listeners.
  /// - Use `notifyEvent` to add events so the entity stream remains
  ///   consistent with event emissions.
  final StreamController<RepositoryEvent<Entity>> _eventController = StreamController<RepositoryEvent<Entity>>.broadcast();

  /// Broadcast controller that publishes entity snapshots for convenience.
  ///
  /// Emits the entity payload whenever an event with a non-null entity is
  /// published. Useful for UI bindings and state synchronization.
  final StreamController<Entity> _valueController = StreamController<Entity>.broadcast();

  @override
  StreamSubscription<RepositoryEvent<Entity>> listen(FutureOr<void> Function(RepositoryEvent<Entity> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _eventController.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Stream<RepositoryEvent<Entity>> streamableEvents() => _eventController.stream;

  @override
  Stream<Entity> streamable() => _valueController.stream;

  /// Emit a repository event and, if present, publish the entity payload.
  ///
  /// Behaviour:
  /// - Adds the [event] to the internal event stream synchronously.
  /// - If the event carries a non-null entity (`event.getEntity()`), that
  ///   entity is also emitted on the entity stream to simplify consumer code.
  /// - Exceptions thrown by subscribers are not caught here; subscribers
  ///   should provide `onError` handlers if they may throw.
  ///
  /// Access:
  /// - `@protected` and `@visibleForOverriding` so that subclasses can
  ///   publish events while preventing accidental public use.
  ///
  /// Example:
  /// ```dart
  /// notifyEvent(CreateRepositoryEvent<MyModel>(created)); // emits event + entity
  /// ```
  @protected
  @visibleForOverriding
  void notifyEvent(RepositoryEvent<Entity> event) {
    _eventController.add(event);

    final Entity? e = event.getEntity();
    if (e != null) {
      _valueController.add(e);
    }
  }

  /// Close internal controllers and release resources. Subclasses should
  /// invoke this as part of their own cleanup (for example when the
  /// repository is closed).
  ///
  /// Behaviour:
  /// - Closes event and entity controllers. After calling, attempting to
  ///   add events will throw a `StateError`.
  /// - Closing an already closed controller is a no-op; callers may safely
  ///   call this method multiple times.
  ///
  /// Example — call from a repository's `close()` implementation:
  /// ```dart
  /// @override
  /// Future<bool> close() async {
  ///   disposeStreamable();
  ///   await _box.close();
  ///   return true;
  /// }
  /// ```
  @protected
  @visibleForOverriding
  void disposeStreamable() {
    _eventController.close();
    _valueController.close();
  }

  @override
  FutureOr<void> onEvent(RepositoryEvent<Entity> event) async => notifyEvent(event);

  @override
  void closeStream() => disposeStreamable();
}