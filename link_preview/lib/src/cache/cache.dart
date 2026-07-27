import 'package:link_preview/link_preview.dart';

/// {@template cache}
/// A concrete, final implementation of [CacheManager] that acts as a global
/// in-memory singleton cache for [LinkPreviewData] objects.
///
/// This class cannot be subclassed (marked `final`). It stores cached entries
/// in a plain `Map` held in memory, meaning all data is lost when the
/// application process terminates.
///
/// Access the singleton via [Cache.instance].
///
/// ### Example
///
/// ```dart
/// // Store a preview
/// await Cache.instance.set(url, previewData);
///
/// // Retrieve a preview
/// final data = await Cache.instance.get(url);
///
/// // Remove a single entry
/// await Cache.instance.delete(url);
///
/// // Clear everything
/// await Cache.instance.clear();
/// ```
///
/// ### Usage
///
/// The [Cache] singleton is the default cache implementation shipped with
/// `link_preview`. Use it when you need a simple, dependency-free cache
/// without persistence. For persistent caching, implement a custom
/// [CacheManager] subclass backed by SQLite, Hive, or disk.
///
/// ### Edge Cases
///
/// - Because storage is in-memory only, all cached data is lost on hot restart
///   or process termination.
/// - The cache has no size limit. Storing many entries without clearing may
///   increase memory usage.
/// - Concurrent `get` calls for the same URL will each return the same object
///   reference; mutations to the returned object will affect the cached copy.
/// {@endtemplate}
final class Cache extends CacheManager {
  /// {@template cache_instance}
  /// The singleton instance of [Cache].
  ///
  /// Returns the same instance on every access. The instance is created
  /// lazily on first use via the private constructor [Cache._].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final cache = Cache.instance;
  /// ```
  ///
  /// ### Usage
  ///
  /// Always access the cache through this static field rather than
  /// attempting to construct a [Cache] directly. The private constructor
  /// prevents external instantiation.
  ///
  /// ### Return value
  ///
  /// The single, process-wide [Cache] instance.
  /// {@endtemplate}
  static final Cache instance = Cache._();

  /// {@template cache_store}
  /// The in-memory cache storage mapping URL keys to [LinkPreviewData] objects.
  ///
  /// This map is the backing store for all cache operations. It is not
  /// persisted to disk or any external storage.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Internally, the cache stores entries like this:
  /// // _cache['https://example.com'] = LinkPreviewData(...);
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - The map is unbounded; no eviction policy is applied.
  /// - All entries share the same lifetime as the process.
  /// {@endtemplate}
  final Map<String, LinkPreviewData> _cache = {};

  /// {@template cache_constructor}
  /// Private constructor to enforce the singleton pattern.
  ///
  /// Only accessible through [Cache.instance]. Direct instantiation is
  /// not possible from outside this class.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // This is the only way to create a Cache:
  /// final cache = Cache.instance;
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// Because this constructor is private, attempting `Cache()` from
  /// outside this file will produce a compile-time error.
  /// {@endtemplate}
  Cache._();

  /// {@template cache_store_method}
  /// Stores a [LinkPreviewData] object in the in-memory cache under the
  /// given [key].
  ///
  /// If a value already exists for [key], it is overwritten silently.
  ///
  /// This operation completes synchronously but returns a [Future] to
  /// satisfy the [CacheManager] contract.
  ///
  /// ### Parameters
  ///
  /// - [key] — The string key under which the data is stored. Typically
  ///   the fully-qualified URL of the link preview.
  /// - [value] — The [LinkPreviewData] object to cache.
  ///
  /// ### Example
  ///
  /// ```dart
  /// await cache.store('https://example.com', previewData);
  /// ```
  ///
  /// ### Return value
  ///
  /// A [Future] that completes immediately with `null`.
  ///
  /// ### Edge Cases
  ///
  /// - Calling `store` with a [key] that already exists replaces the
  ///   previous value without warning.
  /// {@endtemplate}
  @override
  Future<void> store(String key, LinkPreviewData value) {
    _cache[key] = value;
    return Future.value();
  }

  /// {@template cache_retrieve_method}
  /// Retrieves the [LinkPreviewData] object associated with the given [key],
  /// or `null` if no entry exists for that key.
  ///
  /// This method does **not** perform expiration or validity checks; those
  /// are handled by [CacheManager.get] which delegates to this method.
  ///
  /// ### Parameters
  ///
  /// - [key] — The string key to look up. Typically the URL used when the
  ///   entry was stored via [store].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final data = await cache.retrieve('https://example.com');
  /// if (data != null) {
  ///   print('Title: ${data.title}');
  /// }
  /// ```
  ///
  /// ### Return value
  ///
  /// A [Future<LinkPreviewData?>] that completes with the cached data, or
  /// `null` if no entry matches [key].
  ///
  /// ### Edge Cases
  ///
  /// - Returns `null` for keys that were never stored.
  /// - Does not check expiration; stale entries are still returned.
  /// {@endtemplate}
  @override
  Future<LinkPreviewData?> retrieve(String key) {
    return Future.value(_cache[key]);
  }

  /// {@template cache_remove_method}
  /// Removes the cached [LinkPreviewData] entry identified by [key].
  ///
  /// If no entry exists for [key], this method is a no-op and completes
  /// successfully.
  ///
  /// ### Parameters
  ///
  /// - [key] — The string key of the entry to remove.
  ///
  /// ### Example
  ///
  /// ```dart
  /// await cache.remove('https://example.com');
  /// ```
  ///
  /// ### Return value
  ///
  /// A [Future] that completes immediately with `null`.
  ///
  /// ### Edge Cases
  ///
  /// - Calling `remove` on a key that does not exist is safe and does not
  ///   throw.
  /// {@endtemplate}
  @override
  Future<void> remove(String key) {
    _cache.remove(key);
    return Future.value();
  }

  /// {@template cache_clear_method}
  /// Removes all entries from the in-memory cache, effectively resetting
  /// the cache to an empty state.
  ///
  /// After this call, [CacheManager.get] will return `null` for every URL
  /// until new entries are stored.
  ///
  /// ### Example
  ///
  /// ```dart
  /// await cache.clear();
  /// // All entries are now gone.
  /// ```
  ///
  /// ### Return value
  ///
  /// A [Future] that completes immediately with `null`.
  ///
  /// ### Edge Cases
  ///
  /// - This is an irreversible operation for the in-memory cache.
  ///   Previously cached data cannot be recovered.
  /// - Does not affect any other cache instances (there is only one due
  ///   to the singleton pattern).
  /// {@endtemplate}
  @override
  Future<void> clear() {
    _cache.clear();
    return Future.value();
  }
}