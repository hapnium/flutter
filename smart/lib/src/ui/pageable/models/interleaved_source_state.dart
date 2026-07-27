import 'package:hapnium/hapnium.dart';

import 'pageable_status.dart';

/// {@template interleaved_source_state}
/// An immutable snapshot of a single data source's state within an
/// [InterleavablePageableController].
///
/// This class is used by [InterleaveStrategy] implementations to make
/// decisions about:
/// - **Item ordering** — how to merge items from multiple sources into one
///   list (via [items] and [priority]).
/// - **Fetch routing** — which sources to fetch from next (via [canLoadMore],
///   [isFetching], and [status]).
///
/// Instances are created by the controller's internal `_buildSourceStates`
/// method and are **immutable** — the [items] list is wrapped in
/// `List.unmodifiable` to prevent accidental mutation by strategies.
///
/// This class mixes in [EqualsAndHashCode] for value-based equality,
/// enabling efficient change detection in widgets.
/// {@endtemplate}
final class InterleavedSourceState<Item> with EqualsAndHashCode {
  /// The unique identifier of the source this state represents.
  ///
  /// Matches the [PageableSource.id] used when registering the source with
  /// the controller. Used as the key in the `Map<String, InterleavedSourceState>`
  /// passed to [InterleaveStrategy] methods.
  final String id;

  /// The priority of the source, where lower numbers indicate higher priority.
  ///
  /// Used by [PriorityInterleaveStrategy] to determine fill order — sources
  /// with priority `0` appear before priority `1`, and so on. The
  /// [RoundRobinInterleaveStrategy] ignores priority and uses source ID order
  /// instead.
  final int priority;

  /// The cumulative list of items fetched from this source across all pages.
  ///
  /// This is a snapshot — the list is unmodifiable and will not change after
  /// construction. Strategies can safely iterate over it without risk of
  /// concurrent modification.
  ///
  /// The list grows as the source fetches more pages. It is cleared when the
  /// source is reset (e.g., during [InterleavablePageableController.refresh]).
  final List<Item> items;

  /// Whether this source can load more data.
  ///
  /// `true` when the source has a non-null `nextPageKey` and is not currently
  /// exhausted. When `false`, the source has reached its last page.
  ///
  /// Used by [InterleaveStrategy.selectSourcesForFetch] to filter out
  /// sources that have no more data to fetch.
  final bool canLoadMore;

  /// Whether this source is currently executing a fetch operation.
  ///
  /// `true` while [InterleavablePageableController] is awaiting a network
  /// request for this source. Used by strategies to avoid scheduling
  /// redundant fetches for sources that are already mid-request.
  final bool isFetching;

  /// The computed [PageableStatus] of this source, derived from its internal
  /// state.
  ///
  /// Status mapping:
  /// - [PageableStatus.LOADING_FIRST_PAGE] — fetching first page, no items yet
  /// - [PageableStatus.LOADING_NEW_PAGE] — fetching next page, has existing items
  /// - [PageableStatus.FIRST_PAGE_ERROR] — first page fetch failed, no items
  /// - [PageableStatus.NEW_PAGE_ERROR] — next page fetch failed, has items
  /// - [PageableStatus.NO_ITEMS_FOUND] — first page returned empty
  /// - [PageableStatus.LOADED_PAGE] — has items, more pages available
  /// - [PageableStatus.COMPLETED] — all pages loaded, no more data
  final PageableStatus status;

  /// The most recent error thrown by this source's fetch callback, or `null`
  /// if the last fetch succeeded.
  ///
  /// Stored for partial failure tracking — allows the controller to report
  /// per-source errors while still rendering items from successful sources.
  /// Cleared on successful fetch or source reset.
  final dynamic error;

  /// Creates an immutable snapshot of a source's state.
  ///
  /// {@macro interleaved_source_state}
  const InterleavedSourceState({
    /// The unique identifier of the source.
    required this.id,

    /// The priority of the source (lower = higher priority).
    required this.priority,

    /// The cumulative items fetched from this source.
    required this.items,

    /// Whether the source can load more data.
    required this.canLoadMore,

    /// Whether the source is currently fetching.
    required this.isFetching,

    /// The computed status of the source.
    required this.status,

    /// The most recent error, or `null` if no error.
    this.error,
  });

  /// The number of items fetched from this source.
  ///
  /// Convenience getter equivalent to `items.length`.
  int get itemCount => items.length;

  /// Whether this source has fetched any items.
  bool get hasItems => items.isNotEmpty;

  /// Whether this source encountered an error.
  bool get hasError => error != null;

  @override
  List<Object?> equalizedProperties() => [id, priority, canLoadMore, status, error, items, isFetching];

  @override
  String toString() {
    return 'InterleavedSourceState(id: $id, priority: $priority, '
        'itemCount: $itemCount, canLoadMore: $canLoadMore, '
        'isFetching: $isFetching, status: $status, hasError: $hasError)';
  }
}