import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/ui/pageable/controller/interleavable_pageable_controller.dart';
import 'package:smart/src/ui/pageable/controller/interleave_strategy.dart';
import 'package:smart/src/ui/pageable/models/pageable_source.dart';
import 'package:smart/src/ui/pageable/models/pageable_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InterleavablePageableController', () {
    late InterleavablePageableController<String> controller;
    late List<String> feedItems;
    late List<String> adsItems;

    setUp(() {
      feedItems = ['post1', 'post2', 'post3', 'post4', 'post5'];
      adsItems = ['ad1', 'ad2', 'ad3'];

      controller = InterleavablePageableController<String>(
        strategy: const RoundRobinInterleaveStrategy<String>(itemsPerSource: 2),
        sources: [
          PageableSource<dynamic, String>(
            id: 'feed',
            fetchPage: (pageKey) async {
              final page = pageKey as int;
              if (page == 1) {
                return feedItems.sublist(0, 3);
              } else if (page == 2) {
                return feedItems.sublist(3);
              }
              return [];
            },
            firstPageKey: 1,
            getNextPageKey: (key, items, total) {
              if (total < feedItems.length) return (key as int) + 1;
              return null;
            },
            pageSize: 3,
          ),
          PageableSource<dynamic, String>(
            id: 'ads',
            fetchPage: (pageKey) async {
              final page = pageKey as int;
              if (page == 1) {
                return ['ad1', 'ad2'];
              } else if (page == 2) {
                return ['ad3'];
              }
              return [];
            },
            firstPageKey: 1,
            getNextPageKey: (key, items, total) {
              if (total < adsItems.length) return (key as int) + 1;
              return null;
            },
            pageSize: 2,
          ),
        ],
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('fetchFirstPage', () {
      test('fetches from all sources and interleaves', () async {
        await controller.fetchFirstPage();

        expect(controller.itemList, isNotEmpty);
        expect(controller.value.status, isNot(PageableStatus.LOADING_FIRST_PAGE));
      });

      test('sets loading status during fetch', () async {
        final future = controller.fetchFirstPage();
        expect(controller.isFetching, isTrue);
        await future;
      });

      test('isFetching returns true during fetch', () async {
        expect(controller.isFetching, isFalse);
        final future = controller.fetchFirstPage();
        expect(controller.isFetching, isTrue);
        await future;
        expect(controller.isFetching, isFalse);
      });
    });

    group('fetchNextPage', () {
      test('fetches next pages from sources', () async {
        await controller.fetchFirstPage();
        final firstItemCount = controller.itemList.length;

        await controller.fetchNextPage();

        expect(controller.itemList.length, greaterThan(firstItemCount));
      });

      test('does nothing when no sources can load more', () async {
        final singlePageController = InterleavablePageableController<String>(
          strategy: const RoundRobinInterleaveStrategy<String>(),
          sources: [
            PageableSource<dynamic, String>(
              id: 'single',
              fetchPage: (key) async => ['only'],
              firstPageKey: 1,
              getNextPageKey: (key, items, total) => null,
              pageSize: 10,
            ),
          ],
        );

        await singlePageController.fetchFirstPage();
        final itemCount = singlePageController.itemList.length;
        await singlePageController.fetchNextPage();
        expect(singlePageController.itemList.length, itemCount);

        singlePageController.dispose();
      });
    });

    group('refresh', () {
      test('resets and re-fetches from all sources', () async {
        await controller.fetchFirstPage();
        expect(controller.itemList, isNotEmpty);

        await controller.refresh();

        expect(controller.itemList, isNotEmpty);
        expect(controller.value.status, isNot(PageableStatus.REFRESHING));
      });

      test('clears errors on refresh', () async {
        await controller.fetchFirstPage();
        await controller.refresh();

        expect(controller.error, isNull);
      });
    });

    group('clear', () {
      test('resets to initial state', () async {
        await controller.fetchFirstPage();
        controller.clear();

        expect(controller.itemList, isEmpty);
        expect(controller.value.status, PageableStatus.LOADING_FIRST_PAGE);
      });
    });

    group('source management', () {
      test('addSource adds a new source', () async {
        controller.addSource(PageableSource<dynamic, String>(
          id: 'extra',
          fetchPage: (key) async => ['extra1'],
          firstPageKey: 1,
        ));

        expect(controller.sourceIds, contains('extra'));
      });

      test('addSource throws on duplicate id', () {
        expect(
          () => controller.addSource(PageableSource<dynamic, String>(
            id: 'feed',
            fetchPage: (key) async => [],
            firstPageKey: 1,
          )),
          throwsArgumentError,
        );
      });

      test('removeSource removes a source', () async {
        await controller.fetchFirstPage();
        controller.removeSource('ads');

        expect(controller.sourceIds, isNot(contains('ads')));
      });

      test('removeSource triggers re-interleave', () async {
        await controller.fetchFirstPage();
        final itemCountBefore = controller.itemList.length;

        controller.removeSource('ads');

        expect(controller.itemList.length, lessThanOrEqualTo(itemCountBefore));
      });

      test('getSource returns source config', () {
        final source = controller.getSource('feed');
        expect(source, isNotNull);
        expect(source!.id, 'feed');
      });

      test('getSource returns null for unknown id', () {
        expect(controller.getSource('unknown'), isNull);
      });
    });

    group('error handling', () {
      test('handles source fetch errors gracefully', () async {
        final errorController = InterleavablePageableController<String>(
          strategy: const RoundRobinInterleaveStrategy<String>(),
          sources: [
            PageableSource<dynamic, String>(
              id: 'failing',
              fetchPage: (key) async => throw Exception('Network error'),
              firstPageKey: 1,
            ),
            PageableSource<dynamic, String>(
              id: 'working',
              fetchPage: (key) async => ['item1', 'item2'],
              firstPageKey: 1,
              getNextPageKey: (key, items, total) => null,
              pageSize: 10,
            ),
          ],
        );

        await errorController.fetchFirstPage();

        // Should have items from working source
        expect(errorController.itemList, contains('item1'));
        expect(errorController.error, isNotNull);

        errorController.dispose();
      });
    });

    group('isFetching', () {
      test('returns false when idle', () {
        expect(controller.isFetching, isFalse);
      });

      test('returns true during fetch', () async {
        final future = controller.fetchFirstPage();
        expect(controller.isFetching, isTrue);
        await future;
        expect(controller.isFetching, isFalse);
      });
    });

    group('canFetchNextPage', () {
      test('returns true when idle with more pages', () async {
        await controller.fetchFirstPage();
        expect(controller.canFetchNextPage, isTrue);
      });

      test('returns false when no more pages available', () async {
        final singlePageController = InterleavablePageableController<String>(
          strategy: const RoundRobinInterleaveStrategy<String>(),
          sources: [
            PageableSource<dynamic, String>(
              id: 'single',
              fetchPage: (key) async => ['only'],
              firstPageKey: 1,
              getNextPageKey: (key, items, total) => null,
              pageSize: 10,
            ),
          ],
        );

        await singlePageController.fetchFirstPage();
        expect(singlePageController.canFetchNextPage, isFalse);

        singlePageController.dispose();
      });
    });
  });
}