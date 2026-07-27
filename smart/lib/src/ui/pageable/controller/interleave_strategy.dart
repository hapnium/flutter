import '../models/interleaved_source_state.dart';

/// {@template interleave_strategy}
/// Abstract strategy that determines two things for an
/// [InterleavablePageableController]:
///
/// 1. **Item ordering** — how items from multiple sources are merged into a
///    single list in the final feed.
/// 2. **Fetch routing** — which sources should be fetched from on the next
///    pagination cycle, and in what order.
///
/// Three built-in implementations are provided:
/// - [RoundRobinInterleaveStrategy] — takes N items from each source in turn.
/// - [PriorityInterleaveStrategy] — higher priority sources fill first.
/// - [CustomInterleaveStrategy] — user-provided functions for full control.
///
/// You can also implement this interface directly for bespoke behavior.
///
/// ## Implementing a Custom Strategy
///
/// ```dart
/// class MyStrategy implements InterleaveStrategy<Post> {
///   @override
///   List<Post> interleave(Map<String, InterleavedSourceState<Post>> sources) {
///     // Your custom merge logic here
///   }
///
///   @override
///   List<String> selectSourcesForFetch(Map<String, InterleavedSourceState<Post>> sources) {
///     // Your custom routing logic here
///   }
/// }
/// ```
///
/// The [sources] map is keyed by source ID and provides immutable snapshots
/// of each source's current state (items, priority, status, errors). Do not
/// mutate the map or its values.
/// {@endtemplate}
abstract class InterleaveStrategy<Item> {
  /// Merges items from all sources into a single ordered list.
  ///
  /// Called by [InterleavablePageableController] after each fetch cycle to
  /// produce the items for the next synthetic page.
  ///
  /// The [sources] map contains immutable snapshots of every registered
  /// source's current state, including their fetched items, priority, fetch
  /// status, and pagination cursor.
  ///
  /// Returns a flat list of items in the desired display order. The returned
  /// list replaces the entire feed — partial diffs are not supported.
  List<Item> interleave(Map<String, InterleavedSourceState<Item>> sources);

  /// Selects which sources should be fetched from on the next pagination
  /// cycle.
  ///
  /// Called by [InterleavablePageableController.fetchNextPage] to determine
  /// which sources to fire network requests for. Only sources returned by
  /// this method are fetched — others remain idle.
  ///
  /// The [sources] map contains immutable snapshots of every registered
  /// source's current state. Implementations should typically filter to
  /// sources where `canLoadMore == true` and `isFetching == false`.
  ///
  /// Returns a list of source IDs in the order they should be fetched.
  /// Sources are fetched concurrently, so the order primarily affects
  /// priority when the controller limits concurrent fetches in the future.
  List<String> selectSourcesForFetch(Map<String, InterleavedSourceState<Item>> sources);
}

/// {@template round_robin_interleave_strategy}
/// An [InterleaveStrategy] that takes a fixed number of items from each source
/// in sequential rounds.
///
/// For example, with `itemsPerSource: 3` and two sources A and B:
/// ```
/// Round 1: A₁ A₂ A₃ B₁ B₂ B₃
/// Round 2: A₄ A₅ A₆ B₄ B₅ B₆
/// ...
/// ```
///
/// Sources are iterated in sorted ID order for deterministic output. When a
/// source is exhausted mid-round, it is removed and the remaining sources
/// continue.
///
/// ## Fetch Routing
///
/// [selectSourcesForFetch] returns all sources that can load more and are not
/// currently fetching, sorted by source ID.
///
/// ## When to Use
///
/// Ideal for feeds where you want balanced representation from all sources,
/// such as a social feed mixing posts, ads, and recommendations.
/// {@endtemplate}
final class RoundRobinInterleaveStrategy<Item> implements InterleaveStrategy<Item> {
  /// The maximum number of items to take from each source per round.
  ///
  /// Defaults to `3`. Must be greater than 0.
  final int itemsPerSource;

  /// Creates a round-robin strategy that takes [itemsPerSource] items from
  /// each source per round.
  ///
  /// {@macro round_robin_interleave_strategy}
  const RoundRobinInterleaveStrategy({this.itemsPerSource = 3});

  /// Takes [itemsPerSource] items from each source in sorted ID order,
  /// repeating until all sources are exhausted.
  ///
  /// Sources are iterated via their [List.iterator] for O(1) advancement.
  /// Exhausted sources are removed after each round to avoid redundant
  /// iteration.
  @override
  List<Item> interleave(Map<String, InterleavedSourceState<Item>> sources) {
    final result = <Item>[];
    final sourceIds = sources.keys.toList()..sort();
    // Extract the iterators from the source state items
    final iterators = {for (final id in sourceIds) id: sources[id]!.items.iterator};

    while (iterators.isNotEmpty) {
      final toRemove = <String>[];
      for (final entry in iterators.entries) {
        for (var i = 0; i < itemsPerSource; i++) {
          if (entry.value.moveNext()) {
            result.add(entry.value.current);
          } else {
            toRemove.add(entry.key);
            break;
          }
        }
      }
      for (final id in toRemove) {
        iterators.remove(id);
      }
    }
    return result;
  }

  /// Returns all sources that can load more and are not currently fetching,
  /// sorted by source ID for deterministic fetch order.
  @override
  List<String> selectSourcesForFetch(Map<String, InterleavedSourceState<Item>> sources) {
    return sources.entries
        .where((e) => e.value.canLoadMore && !e.value.isFetching)
        .map((e) => e.key)
        .toList()
      ..sort();
  }
}

/// {@template priority_interleave_strategy}
/// An [InterleaveStrategy] that concatenates items from sources ordered by
/// priority, with lower priority numbers appearing first.
///
/// For example, with source A (priority 0) and source B (priority 1):
/// ```
/// [A₁, A₂, A₃, ..., B₁, B₂, B₃, ...]
/// ```
///
/// All items from the highest-priority source appear before any items from
/// the next source. Ties are broken by source ID for determinism.
///
/// ## Fetch Routing
///
/// [selectSourcesForFetch] returns sources sorted by priority (lowest number
/// first). This means the highest-priority source is always fetched first.
///
/// ## When to Use
///
/// Ideal when certain sources should always dominate the feed, such as
/// showing all "urgent" items before "normal" items.
/// {@endtemplate}
final class PriorityInterleaveStrategy<Item> implements InterleaveStrategy<Item> {
  /// Creates a priority-based interleave strategy.
  ///
  /// {@macro priority_interleave_strategy}
  const PriorityInterleaveStrategy();

  /// Concatenates all items from each source, ordered by priority (lowest
  /// number = highest priority), with ties broken by source ID.
  @override
  List<Item> interleave(Map<String, InterleavedSourceState<Item>> sources) {
    final sorted = sources.entries.toList()
      ..sort((a, b) {
        // 1. Sort by priority (lowest number = highest priority)
        final priorityComparison = a.value.priority.compareTo(b.value.priority);
        if (priorityComparison != 0) return priorityComparison;

        // 2. Tie-breaker: sort by key for determinism
        return a.key.compareTo(b.key);
      });

    // Expand the items from the sorted states
    return sorted.expand((e) => e.value.items).toList();
  }

  /// Returns sources that can load more and are not currently fetching,
  /// sorted by priority (lowest number first).
  @override
  List<String> selectSourcesForFetch(Map<String, InterleavedSourceState<Item>> sources) {
    // 1. Filter the sources that can load more and aren't already fetching
    final fetchable = sources.entries
        .where((e) => e.value.canLoadMore && !e.value.isFetching)
        .toList();

    // 2. Sort them by priority in place
    fetchable.sort((a, b) => a.value.priority.compareTo(b.value.priority));

    // 3. Map to their keys and return the List<String>
    return fetchable.map((e) => e.key).toList();
  }
}

/// {@template custom_interleave_strategy}
/// An [InterleaveStrategy] that delegates both item ordering and fetch routing
/// to user-provided functions.
///
/// Use this when the built-in strategies don't satisfy your requirements and
/// you need full control over the interleave logic.
///
/// ## Example
///
/// ```dart
/// final strategy = CustomInterleaveStrategy<Post>(
///   interleaveFn: (sources) {
///     // Custom merge logic, e.g., sort by timestamp across sources
///     final allItems = sources.values.expand((s) => s.items).toList();
///     allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
///     return allItems;
///   },
///   routingFn: (sources) {
///     // Always fetch from 'breaking-news' first, then others
///     final ids = sources.keys.toList();
///     ids.remove('breaking-news');
///     return ['breaking-news', ...ids];
///   },
/// );
/// ```
/// {@endtemplate}
final class CustomInterleaveStrategy<Item> implements InterleaveStrategy<Item> {
  /// The function that determines how items from multiple sources are merged.
  ///
  /// Receives an immutable map of source states keyed by source ID. Must
  /// return a flat list of items in the desired display order.
  final List<Item> Function(Map<String, InterleavedSourceState<Item>> sources) interleaveFn;

  /// The function that determines which sources to fetch from next.
  ///
  /// Receives an immutable map of source states keyed by source ID. Must
  /// return a list of source IDs in fetch priority order.
  final List<String> Function(Map<String, InterleavedSourceState<Item>> sources) routingFn;

  /// Creates a custom interleave strategy with the provided functions.
  ///
  /// {@macro custom_interleave_strategy}
  const CustomInterleaveStrategy({
    required this.interleaveFn,
    required this.routingFn,
  });

  /// Delegates to [interleaveFn] with the given source states.
  @override
  List<Item> interleave(Map<String, InterleavedSourceState<Item>> sources) => interleaveFn(sources);

  /// Delegates to [routingFn] with the given source states.
  @override
  List<String> selectSourcesForFetch(Map<String, InterleavedSourceState<Item>> sources) => routingFn(sources);
}