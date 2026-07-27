import 'package:link_preview/link_preview.dart';

import '../cache/cache.dart';
import '../link_preview_interface.dart';

/// {@template cache_extension}
/// Extension on [LinkPreviewInterface] to provide convenient access
/// to a [CacheManager] instance for link preview data.
///
/// This extension simplifies cache management by providing a default
/// [CacheManager] and enabling easy caching of preview data.
/// Use this extension when you need to store or retrieve cached
/// link preview data.
///
/// ### Common actions
///
/// - Access the default cache: `linkPreview.cacheManager()`
/// - Use a custom cache: `linkPreview.cacheManager(myCacheManager)`
///
/// ### Edge cases
///
/// - If [cacheManager] parameter is `null`, falls back to [Cache.instance]
/// - [Cache.instance] is a global singleton shared across the app
///
/// ### Usage
///
/// ```dart
/// // Access the default global cache
/// final manager = linkPreview.cacheManager();
///
/// // Use a custom cache manager for testing or isolation
/// final testCache = MemoryCacheManager();
/// final manager = linkPreview.cacheManager(testCache);
/// ```
/// {@endtemplate}
extension CacheExtension on LinkPreviewInterface {
  /// {@template cache_extension_cache_manager}
  /// Returns the provided [cacheManager] if it's not null;
  /// otherwise returns the global singleton [Cache.instance].
  ///
  /// This enables flexibility in testing or customization by allowing
  /// callers to inject a custom [CacheManager] or rely on the default
  /// singleton. The default [Cache.instance] persists data across
  /// app sessions.
  ///
  /// ### Parameters
  ///
  /// - [cacheManager]: Optional custom [CacheManager] instance.
  ///   When `null` (the default), the global [Cache.instance] is returned.
  ///
  /// ### Return value
  ///
  /// Returns a [CacheManager] instance — either the provided one
  /// or the global [Cache.instance].
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Default behavior — uses global singleton
  /// final manager = linkPreview.cacheManager();
  /// final data = await manager.get('https://example.com');
  /// ```
  ///
  /// ```dart
  /// // Custom cache for isolation or testing
  /// final customCache = MemoryCacheManager();
  /// final manager = linkPreview.cacheManager(customCache);
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Retrieve cached preview data by URL
  /// - Store newly fetched preview data
  /// - Clear cache entries for specific URLs
  ///
  /// ### Edge cases
  ///
  /// - Passing `null` returns the global singleton, which is shared
  ///   across all instances — concurrent access is thread-safe
  /// - Custom cache instances are not shared and must be managed manually
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Use in a widget to fetch cached or fresh data
  /// final manager = linkPreview.cacheManager();
  /// final cached = await manager.get(url);
  /// if (cached != null) {
  ///   // Use cached data
  /// } else {
  ///   // Fetch fresh data and store it
  ///   final data = await linkPreview.fetchPreviewData(url);
  ///   await manager.put(url, data);
  /// }
  /// ```
  /// {@endtemplate}
  CacheManager cacheManager([CacheManager? cacheManager]) {
    return cacheManager ?? Cache.instance;
  }
}