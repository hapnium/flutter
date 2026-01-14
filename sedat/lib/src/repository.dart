import 'package:meta/meta.dart';
import 'package:hapnium/hapnium.dart';

import 'base_repository.dart';
import 'secure_database_exception.dart';

/// A lightweight adapter function used to translate between storage and
/// domain representations.
///
/// Generics:
/// - `Output`: The target domain model type produced by the adapter.
/// - `Input`: The source type held in persistent storage.
///
/// Expectations:
/// - Implementations should be pure functions that map `Input` to `Output`.
/// - The function should validate the input shape and throw if required
///   fields are missing or the data is invalid.
/// - When `Input` is nullable (e.g., storage may return `null`) callers should
///   guard accordingly or the adapter can accept nullable and provide a
///   default conversion.
///
/// Example:
/// ```dart
/// typedef UserAdapter = User Function(Map<String, dynamic> json);
/// final userAdapter = (Map<String, dynamic> json) => User.fromJson(json);
/// ```
typedef RepositoryAdapter<Output, Input> = Output Function(Input data);

/// {@template repository}
/// A generic repository abstraction that bridges domain models and
/// persistent storage using explicit type adapters.
///
/// `Repository` builds on top of [BaseRepository] by introducing
/// **encoder** and **decoder** adapters that define how data is transformed
/// between:
///
/// - **Domain model** ([Entity]) used by the application
/// - **Storage model** ([Insert]) persisted in the database
///
/// This design enforces a clear separation between storage concerns
/// and business logic while remaining lightweight and highly configurable.
///
/// ## Type Parameters
/// - `Result`: The domain model type exposed to the application
/// - `Insert`: The serialized or database-friendly representation
///
/// ## Responsibilities
/// - Decode stored data into domain models
/// - Encode domain models into storage format
/// - Provide a safe default value when stored data is absent
/// - Enforce adapter registration at runtime
///
/// ## Adapter Registration
/// A `Repository` must be configured before use by registering:
/// - A **decoder** (`Insert → Result`)
/// - An **encoder** (`Result → Insert`)
/// - A **default value** for null or missing storage entries
///
/// This can be done individually or via [registerAll].
///
/// ## Runtime Guarantees
/// - Calling read operations without a registered default value
///   will throw a [SecureDatabaseException]
/// - Calling write operations without a registered encoder
///   will throw a [SecureDatabaseException]
///
/// These safeguards prevent silent data corruption and undefined behavior.
///
/// ## Example
/// ```dart
/// final userRepository = UserRepository('users')
///   ..registerAll(
///     decoder: (json) => User.fromJson(json),
///     encoder: (user) => user.toJson(),
///     defaultValue: User.empty(),
///   );
///
/// final user = await userRepository.get();
/// await userRepository.put(user.copyWith(name: 'Alice'));
/// ```
///
/// ## Design Notes
/// - Adapter registration is mutable, but data access is guarded
/// - Conversion logic is centralized and reusable
/// - Serialization is explicit and type-safe
///
/// {@endtemplate}
abstract class Repository<Entity, Insert> extends BaseRepository<Entity, Insert> {
  /// {@macro repository}
  Repository(super.boxName);

  /// The adapter responsible for converting stored data into the domain model.
  ///
  /// This decoder transforms values retrieved from persistent storage
  /// (of type [Insert]) into their corresponding domain representation
  /// (of type [Entity]).
  ///
  /// This adapter **must** be registered before attempting to read data,
  /// otherwise a [SecureDatabaseException] will be thrown at runtime.
  RepositoryAdapter<Entity, Insert>? _adapter;

  /// The default value returned when no data exists in storage.
  ///
  /// This value is used when the underlying storage returns `null`,
  /// ensuring that repository consumers always receive a valid
  /// domain object.
  ///
  /// A default value **must** be registered before any read operation,
  /// otherwise a [SecureDatabaseException] will be thrown.
  late Entity _defaultValue;

  /// The adapter responsible for converting domain models into storage format.
  ///
  /// This encoder transforms a domain model ([Entity]) into its
  /// persisted representation ([Insert]) before it is written
  /// to the database.
  ///
  /// This adapter **must** be registered before any write operation.
  RepositoryAdapter<Insert, Entity>? _encoder;

  /// Tracks whether a default value has been explicitly registered.
  ///
  /// This flag is used to enforce repository configuration rules
  /// and prevent silent failures when storage returns `null`.
  bool _isDefaultRegistered = false;

  /// Register the decoder used to transform stored data ([Insert]) into
  /// domain model instances ([Entity]).
  ///
  /// Responsibilities:
  /// - The decoder must produce a valid domain object given a storage value.
  /// - It may assume well-formed input but should throw or validate when
  ///   required fields are missing.
  ///
  /// Parameters:
  /// - `decoder`: A function of type `Insert → Entity` used to convert
  ///   persisted values into domain models.
  ///
  /// Returns:
  /// - The repository instance to allow method chaining.
  ///
  /// Errors:
  /// - If the decoder later throws during a read operation, the repository
  ///   will surface that as a [SecureDatabaseException].
  ///
  /// Example:
  /// ```dart
  /// repository.registerDecoder((json) => User.fromJson(json));
  /// ```
  Repository<Entity, Insert> registerDecoder(RepositoryAdapter<Entity, Insert> decoder) {
    _adapter = decoder;

    return this;
  }

  /// Register a default domain value returned when storage contains `null`.
  ///
  /// Behavior:
  /// - When a read operation encounters `null` (no stored value), the
  ///   repository will return this value instead of propagating `null`.
  /// - This protects consumers from `null` checks and keeps read results
  ///   predictable.
  ///
  /// Parameters:
  /// - `value`: The default `Entity` instance to return on missing data.
  ///
  /// Returns:
  /// - The repository instance for fluent chaining.
  ///
  /// Example:
  /// ```dart
  /// repository.registerDefault(User.empty());
  /// final user = repository.get(); // never null
  /// ```
  @override
  Repository<Entity, Insert> registerDefault(Entity value) {
    _defaultValue = value;
    _isDefaultRegistered = true;
    super.registerDefault(value);

    return this;
  }

  /// Register the encoder that converts domain models ([Entity]) into the
  /// storage format ([Insert]).
  ///
  /// Responsibilities:
  /// - The encoder should produce storage-friendly values (e.g., JSON maps,
  ///   primitives) and should validate required fields as necessary.
  /// - If encoding can fail (e.g., missing required fields), the encoder
  ///   should throw so the repository can surface the error as a
  ///   [SecureDatabaseException].
  ///
  /// Parameters:
  /// - `encoder`: A function of type `Entity → Insert`.
  ///
  /// Returns:
  /// - The repository instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// repository.registerEncoder((user) => user.toJson());
  /// ```
  Repository<Entity, Insert> registerEncoder(RepositoryAdapter<Insert, Entity> encoder) {
    _encoder = encoder;

    return this;
  }

  /// Convenience helper to register decoder, encoder and default value in
  /// a single call.
  ///
  /// Notes:
  /// - Registration order is not important but all three pieces are required
  ///   for normal read and write operations.
  /// - This method is offered for convenience but callers may register
  ///   adapters individually when needed.
  ///
  /// Parameters:
  /// - `decoder`: Required decoder function `Insert → Entity`.
  /// - `encoder`: Required encoder function `Entity → Insert`.
  /// - `defaultValue`: Required default value to return on missing data.
  ///
  /// Returns:
  /// - The repository instance for chaining.
  Repository<Entity, Insert> registerAll({
    required RepositoryAdapter<Entity, Insert> decoder,
    required RepositoryAdapter<Insert, Entity> encoder,
    required Entity defaultValue,
  }) {
    registerDecoder(decoder);
    registerEncoder(encoder);
    registerDefault(defaultValue);
    return this;
  }

  /// Convert storage data ([Insert]) into a domain model instance ([Entity]).
  ///
  /// Behavior:
  /// - If the stored value is `null`, the registered default is returned.
  /// - If a decoder (_adapter) is registered it is used to perform the
  ///   conversion and any decoding errors will surface as
  ///   [SecureDatabaseException].
  /// - If no decoder has been registered the method throws a
  ///   [SecureDatabaseException] to avoid silent data corruption.
  ///
  /// Parameters:
  /// - `data`: The stored representation (may be `null`).
  ///
  /// Returns:
  /// - The resulting domain model instance.
  ///
  /// Errors:
  /// - Throws [SecureDatabaseException] when a default value or decoder is
  ///   missing, or when the adapter fails to decode the input.
  ///
  /// Example:
  /// ```dart
  /// final user = repository.fromStore(jsonMap);
  /// ```
  @override
  @nonVirtual
  Entity fromStore(Insert? data) {
    if (_isDefaultRegistered.isFalse) {
      throw SecureDatabaseException("[SD-EXCEPTION] Default value must be provided");
    }

    if (data == null && _isDefaultRegistered) {
      return _defaultValue;
    }

    if (_adapter.isNotNull) {
      return _adapter!(data as Insert);
    }

    throw SecureDatabaseException("[SD-EXCEPTION] You must call `registerAdapter`");
  }

  /// Convert a domain model instance ([Entity]) into its persisted form
  /// ([Insert]).
  ///
  /// Responsibilities:
  /// - Ensure the returned value is serializable by the underlying storage
  ///   backend (e.g., primitives, JSON-like maps). If the encoder cannot
  ///   produce a valid result it should throw.
  ///
  /// Parameters:
  /// - `item`: The domain model instance to encode.
  ///
  /// Returns:
  /// - The encoded representation suitable for storage.
  ///
  /// Errors:
  /// - Throws [SecureDatabaseException] when no encoder is registered or
  ///   if the encoder fails to produce a valid storage value.
  ///
  /// Example:
  /// ```dart
  /// final json = repository.toStore(user);
  /// ```
  @override
  @nonVirtual
  Insert toStore(Entity item) {
    if (_encoder.isNotNull) {
      return _encoder!(item);
    }

    throw SecureDatabaseException("[SD-EXCEPTION] You must call `registerAdapter`");
  }
}

/// {@template json_repository}
/// A specialized `Repository` type that stores domain objects as
/// JSON-compatible maps (`JsonMap`).
///
/// Use this class for models where the storage representation is a
/// `Map<String, dynamic>` (typical for JSON serialization). It provides a
/// clear signal to implementors and consumers about the expected storage
/// shape and encourages adapters that convert to/from maps.
///
/// Practical notes:
/// - Keep adapters simple and side-effect free; decoding should validate
///   required fields and the encoder should produce only serializable
///   values.
/// - When using in tests, provide deterministic `defaultValue` instances to
///   make assertions reliable.
///
/// Example:
/// ```dart
/// class UserRepository extends JsonRepository<User> {
///   UserRepository() : super('userBox');
/// }
/// ```
/// {@endtemplate}
abstract class JsonRepository<Entity> extends Repository<Entity, JsonMap> {
  /// {@macro json_repository}
  JsonRepository(super.boxName);
}

/// {@template collection_repository}
/// A `Repository` specialized for storing collections represented as
/// `JsonMapCollection` (lists of JSON maps).
///
/// Use this when the domain model naturally serializes to an ordered
/// list of objects (for example, a list of messages, orders or events).
/// Implementations should ensure that ordering semantics are clear to
/// consumers (insertion order vs. custom ordering).
///
/// Example:
/// ```dart
/// class OrderRepository extends CollectionRepository<Order> {
///   OrderRepository() : super('orderBox');
/// }
/// ```
/// {@endtemplate}
abstract class CollectionRepository<Entity> extends Repository<Entity, JsonMapCollection> {
  /// {@macro collection_repository}
  CollectionRepository(super.boxName);
}

/// {@template string_repository}
/// A `Repository` convenience type for storing raw `String` values in the
/// underlying storage.
///
/// Typical use cases include tokens, serialized payloads, or single-line
/// configuration values. The encoder/decoder should be trivial in most
/// cases (identity or simple string <-> object mappings).
///
/// Example:
/// ```dart
/// class TokenRepository extends StringRepository<String> {
///   TokenRepository() : super('tokenBox');
/// }
/// ```
/// {@endtemplate}
abstract class StringRepository<Entity> extends Repository<Entity, String> {
  /// {@macro string_repository}
  StringRepository(super.boxName);
}

/// {@template int_repository}
/// A `Repository` convenience type for storing `int` values.
///
/// Commonly used for counters, timestamps, or ordinal values. Encoders and
/// decoders should clearly document units (milliseconds vs. seconds) when
/// using timestamps.
///
/// Example:
/// ```dart
/// class ScoreRepository extends IntRepository<int> {
///   ScoreRepository() : super('scoreBox');
/// }
/// ```
/// {@endtemplate}
abstract class IntRepository<Entity> extends Repository<Entity, int> {
  /// {@macro int_repository}
  IntRepository(super.boxName);
}

/// {@template double_repository}
/// A `Repository` convenience type for storing `double` values (floats).
///
/// Useful for prices, ratios, and other fractional numeric types. As with
/// other numeric repositories, document precision and scale expectations.
///
/// Example:
/// ```dart
/// class RatingRepository extends DoubleRepository<double> {
///   RatingRepository() : super('ratingBox');
/// }
/// ```
/// {@endtemplate}
abstract class DoubleRepository<Entity> extends Repository<Entity, double> {
  /// {@macro double_repository}
  DoubleRepository(super.boxName);
}

/// {@template bool_repository}
/// A `Repository` convenience type for storing boolean toggle or flag values.
///
/// Keep usage simple: a boolean repository typically stores a single state
/// value such as a feature flag or a preference toggle.
///
/// Example:
/// ```dart
/// class PreferenceRepository extends BoolRepository<bool> {
///   PreferenceRepository() : super('prefsBox');
/// }
/// ```
/// {@endtemplate}
abstract class BoolRepository<Entity> extends Repository<Entity, bool> {
  /// {@macro bool_repository}
  BoolRepository(super.boxName);
}

/// {@template datetime_repository}
/// A `Repository` convenience type for storing `DateTime` values.
///
/// Use for timestamps or scheduled event storage. The encoder/decoder
/// should clearly document timezone behaviour and whether times are stored
/// as epoch milliseconds or ISO strings.
///
/// Example:
/// ```dart
/// class LogRepository extends DateTimeRepository<DateTime> {
///   LogRepository() : super('logBox');
/// }
/// ```
/// {@endtemplate}
abstract class DateTimeRepository<Entity> extends Repository<Entity, DateTime> {
  /// {@macro datetime_repository}
  DateTimeRepository(super.boxName);
}

/// {@template duration_repository}
/// A `Repository` convenience type for storing `Duration` values.
///
/// Useful for timers, delays or performance benchmarks. Document unit
/// expectations (microseconds, milliseconds, seconds) in adapters.
///
/// Example:
/// ```dart
/// class TimerRepository extends DurationRepository<Duration> {
///   TimerRepository() : super('timerBox');
/// }
/// ```
/// {@endtemplate}
abstract class DurationRepository<Entity> extends Repository<Entity, Duration> {
  /// {@macro duration_repository}
  DurationRepository(super.boxName);
}

/// {@template list_repository}
/// A `Repository` convenience type for storing `List<dynamic>` values.
///
/// Commonly used for caching, logs, history, or other ordered collections.
/// Implementors should document whether items are appended or replaced on
/// `save` calls.
///
/// Example:
/// ```dart
/// class HistoryRepository extends ListRepository<List<dynamic>> {
///   HistoryRepository() : super('historyBox');
/// }
/// ```
/// {@endtemplate}
abstract class ListRepository<Entity> extends Repository<Entity, List<dynamic>> {
  /// {@macro list_repository}
  ListRepository(super.boxName);
}

/// {@template set_repository}
/// A `Repository` convenience type for storing `Set<dynamic>` values.
///
/// Use when uniqueness is required. Adapters should document equality and
/// hashing expectations for elements.
///
/// Example:
/// ```dart
/// class TagRepository extends SetRepository<Set<dynamic>> {
///   TagRepository() : super('tagBox');
/// }
/// ```
/// {@endtemplate}
abstract class SetRepository<Entity> extends Repository<Entity, Set<dynamic>> {
  /// {@macro set_repository}
  SetRepository(super.boxName);
}

/// {@template dynamic_map_repository}
/// A `Repository` convenience type for storing dynamic maps `Map<dynamic, dynamic>`.
///
/// Useful when keys or values may vary in type. It's recommended to provide
/// adapters that normalise keys and values for stable behaviour across
/// platforms and runtimes.
///
/// Example:
/// ```dart
/// class CacheRepository extends DynamicMapRepository<Map<dynamic, dynamic>> {
///   CacheRepository() : super('cacheBox');
/// }
/// ```
/// {@endtemplate}
abstract class DynamicMapRepository<Entity> extends Repository<Entity, Map<dynamic, dynamic>> {
  /// {@macro dynamic_map_repository}
  DynamicMapRepository(super.boxName);
}