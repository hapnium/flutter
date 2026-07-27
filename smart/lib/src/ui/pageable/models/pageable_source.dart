import 'package:hapnium/hapnium.dart';

import '../controller/pageable_controller.dart';

/// {@template pageable_source}
/// A self-contained paginated data source that contributes items to an
/// [InterleavablePageableController].
///
/// Each source defines its own fetch logic and pagination independently —
/// different sources can have different page key types, page sizes, and
/// fetch callbacks. The interleaved controller manages all sources internally,
/// calling [fetchPage] and [getNextPageKey] as needed.
///
/// Unlike wrapping a full [PageableController], a source is a lightweight
/// configuration object. The interleaved controller owns all pagination state
/// (item buffers, cursors, errors) internally via `_SourceEntry`.
///
/// ## Type Parameters
///
/// - [PageKey] — the type identifying pages (e.g., `int`, `String`, `DateTime`).
///   Different sources can use different page key types.
/// - [Item] — the type of items returned by [fetchPage]. All sources in a
///   single [InterleavablePageableController] must share the same [Item] type.
///
/// ## Usage
///
/// ```dart
/// final feedSource = PageableSource<int, Post>(
///   id: 'feed',
///   fetchPage: (pageKey) => api.fetchFeed(pageKey),
///   firstPageKey: 1,
///   getNextPageKey: (key, items, total) => key + 1,
///   pageSize: 20,
/// );
///
/// final adsSource = PageableSource<int, Post>(
///   id: 'ads',
///   fetchPage: (pageKey) => api.fetchAds(pageKey),
///   firstPageKey: 1,
///   getNextPageKey: (key, items, total) => key + 1,
///   pageSize: 5,
///   priority: 1,
/// );
///
/// final controller = InterleavablePageableController<Post>(
///   strategy: RoundRobinInterleaveStrategy(itemsPerSource: 5),
///   sources: [feedSource, adsSource],
/// );
/// ```
///
/// ## Equality
///
/// Two sources with the same [id] are considered equal regardless of other
/// fields, as [id] is the primary key used by the controller's source
/// registry.
/// {@endtemplate}
final class PageableSource<PageKey, Item> with EqualsAndHashCode {
  /// The unique identifier for this source.
  ///
  /// Used as the key in the controller's internal source registry and in
  /// the `Map<String, InterleavedSourceState>` passed to [InterleaveStrategy]
  /// methods. Must be unique across all sources registered with a single
  /// controller.
  final String id;

  /// The priority of this source for interleave ordering and fetch routing.
  ///
  /// Lower numbers indicate higher priority. Used by:
  /// - [PriorityInterleaveStrategy] — sources with priority `0` fill before
  ///   priority `1`.
  /// - [RoundRobinInterleaveStrategy] — ignored; sources are iterated by
  ///   sorted ID instead.
  /// - [InterleaveStrategy.selectSourcesForFetch] — affects fetch order when
  ///   the strategy sorts by priority.
  ///
  /// Defaults to `0` (highest priority).
  final int priority;

  /// Fetches a page of items for the given [pageKey].
  ///
  /// Called by the interleaved controller during [fetchFirstPage] (with
  /// [firstPageKey]) and during [fetchNextPage] (with the key returned by
  /// [getNextPageKey]).
  ///
  /// The callback receives a [pageKey] and must return a [Future] or direct
  /// [List] of items. Returning an empty list signals the end of available
  /// data for this source.
  ///
  /// Must match the [PageableCallback] signature:
  /// ```dart
  /// FutureOr<List<Item>> Function(PageKey pageKey)
  /// ```
  final PageableCallback<PageKey, Item> fetchPage;

  /// The initial page key used for the first fetch.
  ///
  /// Passed to [fetchPage] when the controller calls [fetchFirstPage] or
  /// [refresh]. For offset-based APIs this is typically `1`; for cursor-based
  /// APIs it might be a string like `'start'` or `null`.
  final PageKey firstPageKey;

  /// Generates the next page key, or `null` if no more pages are available.
  ///
  /// Called after each successful [fetchPage] invocation with:
  /// - `currentPageKey` — the key that was just fetched
  /// - `currentPageItems` — the items returned from that fetch
  /// - `totalLoadedItems` — the cumulative item count for this source
  ///
  /// Must match the [NextPageKeyGenerator] signature:
  /// ```dart
  /// PageKey? Function(PageKey currentPageKey, List<Item> currentPageItems, int totalLoadedItems)
  /// ```
  ///
  /// Returning `null` marks the source as exhausted. If this generator is
  /// not provided, the source is treated as a single-page source and will
  /// not fetch beyond the first page.
  final NextPageKeyGenerator<PageKey, Item>? getNextPageKey;

  /// The expected number of items per page, used for last-page detection.
  ///
  /// When [getNextPageKey] is `null`, the controller falls back to page-size
  /// heuristics. This value is also stored in the outer [PageableView] for
  /// compatibility with widgets that use `pageSize` for viewport calculations.
  ///
  /// Defaults to `20`.
  final int pageSize;

  /// Creates a paginated data source.
  ///
  /// At minimum, provide [id], [fetchPage], and [firstPageKey]. The
  /// [getNextPageKey] generator is optional — if omitted, the source is
  /// treated as a single-page source.
  ///
  /// {@macro pageable_source}
  const PageableSource({
    /// The unique identifier for this source. Must not collide with other
    /// source IDs registered with the same controller.
    required this.id,

    /// The callback that fetches a page of items for a given page key.
    required this.fetchPage,

    /// The initial page key passed to [fetchPage] on first fetch.
    required this.firstPageKey,

    /// Optional generator for the next page key. Return `null` to signal
    /// that no more pages are available.
    this.getNextPageKey,

    /// Priority for interleave ordering. Lower = higher priority.
    /// Defaults to `0`.
    this.priority = 0,

    /// Expected items per page for last-page detection.
    /// Defaults to `20`.
    this.pageSize = 20,
  });

  @override
  List<Object?> equalizedProperties() => [id, priority, firstPageKey, pageSize];

  @override
  String toString() {
    return 'PageableSource(id: $id, priority: $priority, '
        'firstPageKey: $firstPageKey, pageSize: $pageSize, '
        'hasGenerator: ${getNextPageKey != null})';
  }
}