import 'package:hapnium/hapnium.dart';

import 'secure_database_exception.dart';

/// A concise, storage-agnostic contract for repository-like services.
///
/// This interface defines the minimal CRUD surface used across the package
/// for working with a single logical data type `Entity`:
///
/// - `save` to create or update an entity
/// - `get` to synchronously obtain the current entity (convenience for
///   cache-backed repositories)
/// - `fetchAll` to retrieve all items (useful for list-oriented stores)
/// - `delete` / `deleteAll` to remove stored values
/// - `close` to release resources and shut down the repository
///
/// Design goals and guidance for implementors:
/// - Storage-agnostic: the interface does not prescribe how entities are
///   persisted — it can be backed by in-memory caches, Hive boxes, SQLite
///   tables, remote endpoints, etc.
/// - Error handling: repository operations must throw a [SecureDatabaseException]
///   on errors related to storage or access. This makes error handling
///   predictable for callers.
/// - `get()` is synchronous by design here to allow quick access from a
///   cached backend; concrete implementations must document behaviour when no
///   value exists (throw, return a default, or provide a nullable wrapper).
/// - `fetchAll()` returns an empty list when the repository is empty; avoid
///   returning `null`.
/// - The interface intentionally excludes event streaming, transactions and
///   migrations — these belong in higher-level abstractions built on top of
///   this contract.
///
/// Example usage:
/// ```dart
/// final repo = MyUserRepository();
/// await repo.save(user);
/// final current = repo.get();
/// final all = await repo.fetchAll();
/// await repo.delete();
/// await repo.close();
/// ```
abstract interface class RepositoryService<Entity> {
  /// Persist the provided [item] in the repository and return the final,
  /// persisted instance.
  ///
  /// Implementations may either create a new record or update an existing
  /// one depending on the presence of identifiers or other domain rules.
  /// The returned `Future` completes with the persisted object which may be
  /// the same instance passed in or a new object enriched with generated
  /// metadata (for example an assigned id, timestamps or version fields).
  ///
  /// Concurrency and idempotency:
  /// - Implementations should document how concurrent calls are handled
  ///   (last-writer-wins, optimistic locking, etc.).
  /// - Calling `save` repeatedly with the same data should be safe and
  ///   either update the stored representation or be a no-op depending on
  ///   the backend semantics.
  ///
  /// Errors:
  /// - On I/O, validation, or other storage errors the method must throw a
  ///   [SecureDatabaseException] to make failure modes explicit to callers.
  ///
  /// Example:
  /// ```dart
  /// final saved = await repo.save(user);
  /// // saved may contain generated fields like `id` or `updatedAt`.
  /// ```
  Future<Entity> save(Entity item);

  /// Retrieve a single item synchronously from the repository.
  ///
  /// This method is intentionally synchronous to allow quick access to cached
  /// values in implementations that maintain an in-memory view. Concrete
  /// repositories must document their behaviour when no value exists:
  /// - throw a [SecureDatabaseException], or
  /// - return a default sentinel value, or
  /// - return a wrapper type (e.g., `Optional`) in higher-level APIs.
  ///
  /// Note: If your backend cannot support synchronous reads, prefer an
  /// implementation that throws or clearly documents the constraint.
  ///
  /// Example:
  /// ```dart
  /// final current = repo.get();
  /// // `current` may be a cached object or may cause an exception if no
  /// // value is present depending on the implementation.
  /// ```
  ///
  /// Throws a [SecureDatabaseException] on error.
  Entity get();

  /// Asynchronously retrieve all items stored in the repository.
  ///
  /// Return value:
  /// - Must complete with a `List<Entity>`; when no items exist an empty
  ///   list should be returned (avoid returning `null`).
  /// - The ordering of the returned list is implementation-defined; if a
  ///   particular order (insertion, sorted, stable, etc.) matters, document
  ///   it on the concrete repository.
  ///
  /// Performance and filtering:
  /// - Implementations may provide pagination or filtering helpers; keep
  ///   this method simple and synchronous for small datasets or delegate
  ///   larger queries to specialized APIs.
  ///
  /// Errors:
  /// - Throw a [SecureDatabaseException] on I/O or query errors.
  ///
  /// Example:
  /// ```dart
  /// final all = await repo.fetchAll();
  /// if (all.isEmpty) {
  ///   // handle empty store
  /// }
  /// ```
  Future<List<Entity>> fetchAll();

  /// Delete multiple items from the repository in a single operation.
  ///
  /// Behaviour expectations:
  /// - Prefer atomic removal when the backend supports transactions;
  ///   otherwise perform best-effort removal and document partial failure
  ///   semantics.
  /// - This operation should be idempotent: removing the same items again
  ///   should have no adverse effect.
  ///
  /// Errors:
  /// - Throw a [SecureDatabaseException] if the operation cannot be
  ///   completed (e.g., I/O error or validation failure).
  ///
  /// Example:
  /// ```dart
  /// await repo.deleteAll(usersToDelete);
  /// ```
  Future<void> deleteAll(List<Entity> items);

  /// Remove stored content from the repository and optionally return the
  /// removed entity inside an `Optional`.
  ///
  /// Semantics:
  /// - For repositories that represent a single value this should return
  ///   `Optional.of(removedValue)` when a value existed or `Optional.empty()`
  ///   when there was nothing to remove.
  /// - For collection-oriented repositories the implementation may return
  ///   `Optional.empty()` if there is no single meaningful removed value.
  ///
  /// Idempotency:
  /// - Calling `delete()` multiple times should be safe and produce the same
  ///   end result (no value stored) — callers should be able to rely on
  ///   idempotent behaviour.
  ///
  /// Errors:
  /// - On failure the method throws a [SecureDatabaseException].
  ///
  /// Example:
  /// ```dart
  /// final removed = await repo.delete();
  /// if (removed.isPresent) {
  ///   // handle removed value
  /// }
  /// ```
  Future<Optional<Entity>> delete();

  /// Shut down the repository and release any held resources (files,
  /// connections, stream controllers, etc.).
  ///
  /// Implementation notes:
  /// - The returned `Future<bool>` should complete to `true` when the
  ///   repository closed successfully and to `false` when the close operation
  ///   failed or could not complete cleanly (for example due to I/O errors).
  /// - Calling `close()` multiple times should be safe (idempotent).
  /// - After a successful close, other repository operations may throw or
  ///   behave as documented by the concrete implementation.
  ///
  /// Example:
  /// ```dart
  /// final ok = await repo.close();
  /// if (!ok) {
  ///   // handle close failure
  /// }
  /// ```
  Future<bool> close();
}