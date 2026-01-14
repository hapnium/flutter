import 'package:hapnium/hapnium.dart';
import 'package:meta/meta.dart';

import 'base_repository.dart';
import 'paging.dart';
import 'repository.dart';
import 'secure_database_exception.dart';

/// Mixin that provides lazy, diagnostic repository resolution for a concrete
/// repository type `<Repository>`.
///
/// Use this mixin when a class (for example a service or a UI widget) needs
/// access to a repository instance that is registered and managed by the
/// application's global repository registry (`RepositoryContext`). This lets
/// calling code avoid manual wiring while still keeping the runtime lookup
/// explicit and type-safe.
///
/// Key characteristics:
/// - Resolution is performed lazily when the `repository` getter is first
///   accessed. This avoids ordering issues at startup while still providing
///   a clear, typed access point.
/// - If the repository is not found, the mixin throws `SecureDatabaseException`
///   with a detailed diagnostic message that explains likely causes and
///   lists currently registered repository types (helpful for debugging
///   startup/registration order problems).
/// - Because resolution uses the concrete static type parameter `Repository`,
///   callers must ensure that the exact repository type they expect is
///   registered. Registering a subtype under a different static type will not
///   satisfy lookups for the base type.
///
/// Example:
/// ```dart
/// class RuleService with SecureRepository<RuleRepository> {
///   Future<void> sync() async {
///     final repo = repository; // resolved from RepositoryContext.INSTANCE
///     await repo.save(...);
///   }
/// }
/// ```
///
/// When to prefer this mixin:
/// - Small apps or top-level application components where the global
///   registry pattern simplifies wiring.
/// - Runners and integration pieces that want to discover repositories by
///   type rather than receiving them via constructors.
///
/// When to avoid this mixin:
/// - Complex components where constructor (or DI) injection is preferred for
///   testability and explicit dependencies.
///
/// Throws:
/// - `SecureDatabaseException` if no repository of type `<Repository>` is
///   registered. The exception includes actionable remediation suggestions and
///   diagnostic information (registered repository types).
mixin SecureRepository<Repository extends BaseRepository> {
  /// Cached instance
  Repository? _repository;

  /// Return the repository instance of type `<Repository>` registered in
  /// `RepositoryContext.INSTANCE`.
  ///
  /// Behavior:
  /// - Performs a runtime lookup for the concrete static type parameter
  ///   `<Repository>` using `RepositoryContext.INSTANCE.find<Repository>()`.
  /// - Returns the registered instance when found.
  /// - Throws a `SecureDatabaseException` with a detailed diagnostic message
  ///   if no instance is registered (the message includes likely causes and
  ///   the list of currently registered repository types).
  /// 
  /// Example usage:
  /// ```dart
  /// class RuleService with SecureRepository<RuleRepository> {
  ///   Future<void> syncAll() async {
  ///     final repo = repository; // resolved from RepositoryContext.INSTANCE
  ///     await repo.findAll();
  ///   }
  /// }
  /// ```
  ///
  /// Throws:
  /// - `SecureDatabaseException` when no repository of type `<Repository>`
  ///   is registered; the exception message contains actionable remediation
  ///   and diagnostic information (including registered repository types).
  Repository get repository {
    if (_repository case final repository?) {
      return repository;
    }
    
    if (RepositoryContext.INSTANCE.find<Repository>() case final repository?) {
      return _repository = repository;
    }

    throw SecureDatabaseException(
      '[SECURE-REPOSITORY] Repository lookup failed.\n'
      'No repository of type <$Repository> is registered in RepositoryContext.\n\n'
      'This usually means:\n'
      '- The repository was never registered via AbstractSecureDatabaseConfigurer.repositories()\n'
      '- The registration happened after this access\n'
      '- A different repository type was registered than expected\n\n'
      'How to fix:\n'
      '1. Ensure all repositories are created and registered at application startup.\n'
      '2. Verify that the exact repository type <$Repository> is included in the '
      'AbstractSecureDatabaseConfigurer repositories.\n'
      '3. Avoid accessing repositories before initialization is complete.\n\n'
      'Registered repositories:\n'
      '${RepositoryContext.INSTANCE.getAll().map((r) => r.runtimeType).join(', ')}'
    );
  }
}

/// Mixin providing a small, opt-in paging/sorting contract for repositories.
///
/// The `PageableRepository` mixin defines three complementary extension
/// points for repositories that support pagination and sorting:
///
/// - `findPage(Pageable)`: perform a paged query returning a `Page<T>` with
///   the requested slice and pagination metadata.
/// - `findAllSorted(Sort)`: return a fully materialized `List<T>` containing
///   all elements ordered according to the provided `Sort`.
/// - `findAllSortedIterable(Sort)`: return an `Iterable<T>` of elements
///   ordered according to `Sort`. This is useful for backends that can
///   produce sorted streams or iterables without materializing large lists.
///
/// Design goals and notes:
/// - Safe defaults: each method provides a sensible default (empty results)
///   so that mixing in `PageableRepository` is non-breaking — override the
///   operations you actually support.
/// - Choice of override: implementors that can produce streaming sorted
///   results should override `findAllSortedIterable` and let the default
///   `findAllSorted` materialize a list when needed. Use `findPage` for
///   efficient, database-style pagination where available.
/// - Threading and I/O: the methods are `Future` returning; implementors
///   should perform asynchronous I/O (queries, file reads) within the
///   implementation.
///
/// Example — efficient paged query:
/// ```dart
/// class MyModelRepository extends CollectionRepository<List<MyModel>>
///     with PageableRepository<MyModel, JsonMapCollection, MyModelRepository> {
///   @override
///   Future<Page<MyModel>> findPage(Pageable pageable) async {
///     // translate pageable into limit/offset and retrieve items
///   }
/// }
/// ```
///
/// Error handling:
/// - Implementations should propagate meaningful exceptions and avoid
///   swallowing errors silently; callers can then decide how to recover or
///   surface errors to the user.
///
/// Performance:
/// - Prefer `findPage` for large datasets to avoid loading full datasets into
///   memory; use `findAllSortedIterable` when streaming sorted results.
mixin PageableRepository<Entity, Insert, Repository extends BaseRepository<Entity, Insert>> on BaseRepository<Entity, Insert> {
  /// Find a page of elements described by [pageable].
  ///
  /// Implementations should return a `Page<Entity>` object representing
  /// the requested page (content list, total elements, current page info).
  /// The default implementation returns `Page.empty(pageable)` so callers
  /// should not assume that paging is supported unless overridden.
  Future<Page<Entity>> findPage(Pageable pageable) async => Page.empty<Entity>(pageable);

  /// Return all elements sorted according to [sort] as a `List<Entity>`.
  ///
  /// Default implementation delegates to [findAllSortedIterable] and
  /// materializes the result into a `List<Entity>`. Override this method
  /// when your backend can efficiently return a fully-sorted list.
  Future<List<Entity>> findAllSorted(Sort sort) async => List<Entity>.from(await findAllSortedIterable(sort));

  /// Return all elements sorted according to [sort] as an `Iterable<Entity>`.
  ///
  /// Prefer overriding this method when your data source can produce a
  /// sorted stream/iterator without materializing everything in memory.
  /// The default implementation returns an empty iterable.
  Future<Iterable<Entity>> findAllSortedIterable(Sort sort) async => <Entity>[];
} 

/// Convenience mixin for `JsonRepository<T>` implementations that want to
/// opt into the pageable contract provided by [PageableRepository].
///
/// This mixin specializes the `Insert` backing type to `JsonMap`, making it
/// ergonomic to use for repositories that persist single-object JSON maps
/// (for example, a repository that stores versioned JSON objects).
///
/// Use this mixin when your repository stores elements as `JsonMap` values
/// and you want to add paging/sorting support without repeating generic
/// parameters.
///
/// Example:
/// ```dart
/// class VersionRepository extends JsonRepository<Version>
///     with JsonPageableRepository<Version, VersionRepository> {
///   @override
///   Future<Page<Version>> findPage(Pageable pageable) { ... }
/// }
/// ```
mixin JsonPageableRepository<Entity, Repository extends JsonRepository<Entity>> on PageableRepository<Entity, JsonMap, Repository> {}

/// Convenience mixin for `CollectionRepository<T>` implementations.
///
/// This mixin is targeted at repositories that persist list-style collections
/// via `JsonMapCollection`. It specializes the `Insert` backing type to
/// `JsonMapCollection` and signals that the repository expects collection
/// semantics (multiple items stored under a single logical entity).
///
/// Implementors should override `findPage` and/or `findAllSorted*` to
/// provide collection-aware paging (for example, storing a primary-keyed
/// index and emitting items in a deterministic order).
///
/// Example:
/// ```dart
/// class RulesRepository extends CollectionRepository<Rule>
///     with CollectionPageableRepository<Rule, RulesRepository> {
///   @override
///   Future<Page<Rule>> findPage(Pageable pageable) { ... }
/// }
/// ```
mixin CollectionPageableRepository<Entity, Repository extends CollectionRepository<Entity>> on PageableRepository<Entity, JsonMapCollection, Repository> {}

/// Convenience mixin for repositories backed by raw `List` values.
///
/// Use this on `ListRepository<List<T>>` implementations to make the
/// pageable/sort contract available when your repo's backing store is a
/// plain list (e.g., `List<dynamic>`). As with other pageable mixins, the
/// default implementations are safe no-ops and should be overridden to
/// provide meaningful behavior.
///
/// Example:
/// ```dart
/// class SimpleListRepo extends ListRepository<MyModel>
///     with ListablePageableRepository<MyModel, SimpleListRepo> {
///   @override
///   Future<Page<MyModel>> findPage(Pageable pageable) { ... }
/// }
/// ```
mixin ListablePageableRepository<Entity, Repository extends ListRepository<Entity>> on PageableRepository<Entity, List<dynamic>, Repository> {}

/// Convenience mixins for primitive and typed repository variants.
///
/// These mixins do not alter runtime behavior, but make it ergonomic to
/// opt a strongly-typed repository into the pageable contract without
/// repeating generic parameters. Use the exact typed mixin that matches
/// your repository's backing value to avoid ambiguous or verbose generics.
///
/// Note: each of these mixins simply specializes the `Insert` type used by
/// `PageableRepository`. They rely on the repository implementation to
/// override paging methods when meaningful paging is supported.

/// Pageable support for repositories that persist `String` values.
/// Use on `StringRepository<T>` implementations.
///
/// Example:
/// ```dart
/// class TokenRepo extends StringRepository<Token>
///     with StringPageableRepository<Token, TokenRepo> { ... }
/// ```
mixin StringPageableRepository<Entity, Repository extends StringRepository<Entity>> on PageableRepository<Entity, String, Repository> {}

/// Pageable support for repositories that persist `int` values.
/// Use on `IntRepository<T>` implementations.
///
/// Example:
/// ```dart
/// class CounterRepo extends IntRepository<Counter>
///     with IntPageableRepository<Counter, CounterRepo> { ... }
/// ```
mixin IntPageableRepository<Entity, Repository extends IntRepository<Entity>> on PageableRepository<Entity, int, Repository> {}

/// Pageable support for repositories that persist `double` values.
mixin DoublePageableRepository<Entity, Repository extends DoubleRepository<Entity>> on PageableRepository<Entity, double, Repository> {}

/// Pageable support for repositories that persist `bool` values.
mixin BoolPageableRepository<Entity, Repository extends BoolRepository<Entity>> on PageableRepository<Entity, bool, Repository> {}

/// Pageable support for repositories that persist `DateTime` values.
mixin DateTimePageableRepository<Entity, Repository extends DateTimeRepository<Entity>> on PageableRepository<Entity, DateTime, Repository> {}

/// Pageable support for repositories that persist `Duration` values.
mixin DurationPageableRepository<Entity, Repository extends DurationRepository<Entity>> on PageableRepository<Entity, Duration, Repository> {}

/// Pageable support for repositories that persist `Set` values.
mixin SetPageableRepository<Entity, Repository extends SetRepository<Entity>> on PageableRepository<Entity, Set<dynamic>, Repository> {}

/// Pageable support for repositories that persist arbitrary `Map` values.
mixin DynamicMapPageableRepository<Entity, Repository extends DynamicMapRepository<Entity>> on PageableRepository<Entity, Map<dynamic, dynamic>, Repository> {} 

/// Global lookup and registration context for repositories used by the
/// `SecureRepository` mixin and other convenience helpers.
///
/// `RepositoryContext` is a minimal, in-memory registry designed to be
/// populated during application initialization (for example inside a
/// `AbstractSecureDatabaseConfigurer`). It provides typed lookup for
/// repository instances, diagnostics access to registered repository types,
/// and utilities to clear or re-register the registry (useful in tests).
///
/// Important notes:
/// - Registration is additive: calling `register([...])` appends the
///   provided repositories to the existing list. Clearing the registry before
///   re-registering is recommended in test setups.
/// - The context is intentionally simple and **not** intended to be a
///   full-featured dependency injection container; prefer constructor
///   injection or explicit DI frameworks in large applications.
/// - Thread-safety: this implementation is not explicitly synchronized and
///   should be used during single-threaded startup or with external
///   synchronization if mutated concurrently.
///
/// Example (registration at startup):
/// ```dart
/// final ctx = RepositoryContext.INSTANCE;
/// ctx.register([userRepo, ruleRepo, settingsRepo]);
/// ```
///
/// Testing note:
/// - Call `RepositoryContext.INSTANCE.clear()` between tests to avoid state
///   leakage.
@internal
abstract final class RepositoryContext {
  /// Factory that returns the default implementation.
  factory RepositoryContext() = _RepositoryContext;

  /// Singleton instance used throughout the package.
  ///
  /// This may be replaced in tests with a fresh instance by assigning a new
  /// `RepositoryContext()` to `RepositoryContext.INSTANCE` prior to test
  /// execution.
  static RepositoryContext INSTANCE = RepositoryContext();

  /// Find a repository of type `T` if registered, otherwise `null`.
  ///
  /// The lookup matches by the static type `T` supplied. If multiple
  /// repositories with the same runtime type are registered, the first
  /// matching instance is returned.
  T? find<T>();

  /// Register a collection of repositories (called at initialization).
  ///
  /// Implementations should append or replace the internal registry as
  /// appropriate. Consumers are responsible for managing duplicates and
  /// registration order if deterministic lookup is required.
  void register(List<BaseRepository> repositories);

  /// Returns all registered repository instances for diagnostics.
  Iterable<BaseRepository> getAll();

  /// Clear all registered repositories (used for tests or shutdown).
  void clear();
}

/// Default in-memory implementation of [RepositoryContext].
///
/// This is a compact, straightforward implementation that stores repositories
/// in an internal `List<BaseRepository>` in registration order. Lookup is
/// performed by Dart `is`/`whereType` checks; the first matching instance is
/// returned when calling `find<T>()`.
///
/// Implementation notes:
/// - Ordering matters: because the lookup returns the first matching
///   instance, register repositories in the deterministic order you want
///   them to be discovered. Avoid duplicates when possible.
/// - `getAll()` yields the repositories in the order they were registered.
/// - `clear()` removes all registered instances and is useful for test
///   teardown.
final class _RepositoryContext implements RepositoryContext {
  final List<BaseRepository> _repositories = [];

  @override
  T? find<T>() => _repositories.whereType<T>().firstOrNull;

  @override
  void register(List<BaseRepository> repositories) {
    _repositories.addAll(repositories);
  }

  @override
  Iterable<BaseRepository<dynamic, dynamic>> getAll() sync* {
    yield* _repositories;
  }

  @override
  void clear() {
    _repositories.clear();
  }
}