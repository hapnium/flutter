import 'dart:async';

import 'page_result.dart';

/// {@template pageable_cache_snapshot}
/// An immutable snapshot of paginated state that can be persisted and
/// later restored.
///
/// Holds the loaded [pages] plus the [nextPageKey] / [prevPageKey] cursors
/// so a restored controller can continue paginating in both directions.
/// {@endtemplate}
class PageableCacheSnapshot<PageKey, Item> {
  /// The loaded pages in fetch order.
  final List<PageResult<PageKey, Item>> pages;

  /// Key for the next page to load, or `null` if unknown/exhausted.
  final PageKey? nextPageKey;

  /// Key for the page before the first loaded page, or `null` if none.
  final PageKey? prevPageKey;

  /// Creates a snapshot of pageable state.
  ///
  /// {@macro pageable_cache_snapshot}
  const PageableCacheSnapshot({
    required this.pages,
    this.nextPageKey,
    this.prevPageKey,
  });

  /// Whether the snapshot contains any items.
  bool get hasItems => pages.any((page) => page.hasItems);

  /// All snapshot items as a flat list in page order.
  List<Item> get items => pages.expand((page) => page.items).toList();
}

/// {@template pageable_cache}
/// Storage contract for persisting [PageableCacheSnapshot]s across
/// controller lifetimes.
///
/// A [PageableController] writes a snapshot after every successful load and
/// reads it back on initialization when both [PageableController.cacheKey]
/// and a cache are configured, so recreated controllers can show the last
/// known items instantly while fresh data loads.
///
/// Because [Item] is generic, implementations decide how to retain values:
/// [InMemoryPageableCache] keeps them in memory for the session, while a
/// persistent implementation would serialize items (for example via `toJson`
/// and a matching `fromJson`) before writing them to disk.
///
/// Methods return [FutureOr] so simple stores can answer synchronously
/// while I/O-backed stores can return futures.
///
/// Example:
/// ```dart
/// final controller = PageableController<int, Post>(
///   fetchPage: (page) => api.fetchPosts(page),
///   getFirstPageKey: 0,
///   getNextPageKey: (key, items, total) => key + 1,
///   pageSize: 20,
///   cacheKey: 'feed-posts',
///   cache: InMemoryPageableCache<int, Post>(),
/// );
/// ```
/// {@endtemplate}
abstract class PageableCache<PageKey, Item> {
  /// Reads the snapshot stored under [key], or `null` if absent or invalid.
  ///
  /// Invalid entries (for example snapshots whose items no longer decode to
  /// [Item]) should resolve to `null` rather than throw, so callers fall
  /// back to a regular first-page load.
  FutureOr<PageableCacheSnapshot<PageKey, Item>?> read(String key);

  /// Writes [snapshot] under [key], replacing any existing entry.
  FutureOr<void> write(String key, PageableCacheSnapshot<PageKey, Item> snapshot);

  /// Deletes the entry stored under [key], if any.
  FutureOr<void> delete(String key);

  /// Clears every snapshot held by this store.
  FutureOr<void> clearAll();
}

/// {@template in_memory_pageable_cache}
/// Session-scoped [PageableCache] that retains snapshots in a shared,
/// process-wide map.
///
/// Useful for instant hydration when a controller is recreated (for example
/// navigating back to a feed) without refetching the first page from
/// scratch: any controller or cache instance using the same key observes the
/// same snapshot. Nothing is written to disk, and everything is dropped when
/// the process ends.
///
/// This is also the store a [PageableController] falls back to when
/// [PageableController.cacheKey] is set without an explicit
/// [PageableController.cache].
///
/// {@macro in_memory_pageable_cache}
/// {@endtemplate}
class InMemoryPageableCache<PageKey, Item> implements PageableCache<PageKey, Item> {
  /// Shared process-wide store so unrelated controllers and cache instances
  /// using the same key hydrate from the same snapshot.
  static final Map<String, PageableCacheSnapshot<dynamic, dynamic>> _store = {};

  /// Reads the snapshot stored under [key], defensively copying its pages.
  ///
  /// Returns `null` when nothing was stored or the stored values no longer
  /// match [PageKey]/[Item].
  @override
  FutureOr<PageableCacheSnapshot<PageKey, Item>?> read(String key) {
    final snapshot = _store[key];
    if (snapshot == null) return null;

    try {
      return PageableCacheSnapshot<PageKey, Item>(
        pages: snapshot.pages.map((page) {
          return PageResult<PageKey, Item>(
            pageKey: page.pageKey as PageKey,
            items: List<Item>.from(page.items),
            totalCount: page.totalCount,
            metadata: page.metadata,
          );
        }).toList(),
        nextPageKey: snapshot.nextPageKey as PageKey?,
        prevPageKey: snapshot.prevPageKey as PageKey?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Writes a defensive copy of [snapshot] under [key].
  @override
  FutureOr<void> write(String key, PageableCacheSnapshot<PageKey, Item> snapshot) {
    _store[key] = PageableCacheSnapshot<dynamic, dynamic>(
      pages: snapshot.pages.map((page) {
        return PageResult<dynamic, dynamic>(
          pageKey: page.pageKey,
          items: List.of(page.items),
          totalCount: page.totalCount,
          metadata: page.metadata == null ? null : Map.of(page.metadata!),
        );
      }).toList(),
      nextPageKey: snapshot.nextPageKey,
      prevPageKey: snapshot.prevPageKey,
    );
  }

  /// Deletes the entry stored under [key], if any.
  @override
  FutureOr<void> delete(String key) {
    _store.remove(key);
  }

  /// Clears every snapshot held by the shared store.
  @override
  FutureOr<void> clearAll() {
    _store.clear();
  }
}