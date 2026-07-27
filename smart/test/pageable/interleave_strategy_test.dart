import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/ui/pageable/controller/interleave_strategy.dart';
import 'package:smart/src/ui/pageable/models/interleaved_source_state.dart';
import 'package:smart/src/ui/pageable/models/pageable_status.dart';

void main() {
  InterleavedSourceState<String> createState({
    required String id,
    int priority = 0,
    List<String> items = const [],
    bool canLoadMore = true,
    bool isFetching = false,
    PageableStatus status = PageableStatus.LOADED_PAGE,
    dynamic error,
  }) {
    return InterleavedSourceState(
      id: id,
      priority: priority,
      items: items,
      canLoadMore: canLoadMore,
      isFetching: isFetching,
      status: status,
      error: error,
    );
  }

  group('RoundRobinInterleaveStrategy', () {
    late RoundRobinInterleaveStrategy<String> strategy;

    setUp(() {
      strategy = const RoundRobinInterleaveStrategy(itemsPerSource: 2);
    });

    test('interleaves items from multiple sources', () {
      final sources = {
        'a': createState(id: 'a', items: ['a1', 'a2', 'a3']),
        'b': createState(id: 'b', items: ['b1', 'b2', 'b3']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['a1', 'a2', 'b1', 'b2', 'a3', 'b3']);
    });

    test('handles single source', () {
      final sources = {
        'a': createState(id: 'a', items: ['a1', 'a2']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['a1', 'a2']);
    });

    test('handles empty sources', () {
      final sources = <String, InterleavedSourceState<String>>{};

      final result = strategy.interleave(sources);
      expect(result, isEmpty);
    });

    test('handles sources with different lengths', () {
      final sources = {
        'a': createState(id: 'a', items: ['a1']),
        'b': createState(id: 'b', items: ['b1', 'b2', 'b3', 'b4']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['a1', 'b1', 'b2', 'b3', 'b4']);
    });

    test('sorts by source ID for determinism', () {
      final sources = {
        'b': createState(id: 'b', items: ['b1', 'b2']),
        'a': createState(id: 'a', items: ['a1', 'a2']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['a1', 'a2', 'b1', 'b2']);
    });

    test('default itemsPerSource is 3', () {
      const defaultStrategy = RoundRobinInterleaveStrategy<String>();
      expect(defaultStrategy.itemsPerSource, 3);
    });

    test('selectSourcesForFetch returns sources that can load more', () {
      final sources = {
        'a': createState(id: 'a', canLoadMore: true),
        'b': createState(id: 'b', canLoadMore: false),
        'c': createState(id: 'c', canLoadMore: true),
      };

      final result = strategy.selectSourcesForFetch(sources);
      expect(result, ['a', 'c']);
    });

    test('selectSourcesForFetch excludes fetching sources', () {
      final sources = {
        'a': createState(id: 'a', canLoadMore: true, isFetching: true),
        'b': createState(id: 'b', canLoadMore: true, isFetching: false),
      };

      final result = strategy.selectSourcesForFetch(sources);
      expect(result, ['b']);
    });

    test('selectSourcesForFetch sorts by source ID', () {
      final sources = {
        'c': createState(id: 'c', canLoadMore: true),
        'a': createState(id: 'a', canLoadMore: true),
        'b': createState(id: 'b', canLoadMore: true),
      };

      final result = strategy.selectSourcesForFetch(sources);
      expect(result, ['a', 'b', 'c']);
    });
  });

  group('PriorityInterleaveStrategy', () {
    late PriorityInterleaveStrategy<String> strategy;

    setUp(() {
      strategy = const PriorityInterleaveStrategy();
    });

    test('interleaves items ordered by priority', () {
      final sources = {
        'low': createState(id: 'low', priority: 2, items: ['low1', 'low2']),
        'high': createState(id: 'high', priority: 0, items: ['high1', 'high2']),
        'mid': createState(id: 'mid', priority: 1, items: ['mid1', 'mid2']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['high1', 'high2', 'mid1', 'mid2', 'low1', 'low2']);
    });

    test('uses source ID as tie-breaker for same priority', () {
      final sources = {
        'b': createState(id: 'b', priority: 0, items: ['b1']),
        'a': createState(id: 'a', priority: 0, items: ['a1']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['a1', 'b1']);
    });

    test('selectSourcesForFetch sorts by priority', () {
      final sources = {
        'low': createState(id: 'low', priority: 2, canLoadMore: true),
        'high': createState(id: 'high', priority: 0, canLoadMore: true),
        'mid': createState(id: 'mid', priority: 1, canLoadMore: true),
      };

      final result = strategy.selectSourcesForFetch(sources);
      expect(result, ['high', 'mid', 'low']);
    });

    test('selectSourcesForFetch excludes non-fetchable sources', () {
      final sources = {
        'a': createState(id: 'a', priority: 0, canLoadMore: false),
        'b': createState(id: 'b', priority: 1, canLoadMore: true),
      };

      final result = strategy.selectSourcesForFetch(sources);
      expect(result, ['b']);
    });
  });

  group('CustomInterleaveStrategy', () {
    test('delegates interleave to provided function', () {
      final strategy = CustomInterleaveStrategy<String>(
        interleaveFn: (sources) {
          final allItems = <String>[];
          for (final source in sources.values) {
            allItems.addAll(source.items.reversed);
          }
          return allItems;
        },
        routingFn: (sources) => sources.keys.toList(),
      );

      final sources = {
        'a': createState(id: 'a', items: ['a1', 'a2']),
        'b': createState(id: 'b', items: ['b1', 'b2']),
      };

      final result = strategy.interleave(sources);
      expect(result, ['a2', 'a1', 'b2', 'b1']);
    });

    test('delegates selectSourcesForFetch to provided function', () {
      final strategy = CustomInterleaveStrategy<String>(
        interleaveFn: (sources) => [],
        routingFn: (sources) => ['custom-order', ...sources.keys.where((k) => k != 'custom-order')],
      );

      final sources = {
        'a': createState(id: 'a'),
        'custom-order': createState(id: 'custom-order'),
        'b': createState(id: 'b'),
      };

      final result = strategy.selectSourcesForFetch(sources);
      expect(result.first, 'custom-order');
    });
  });
}