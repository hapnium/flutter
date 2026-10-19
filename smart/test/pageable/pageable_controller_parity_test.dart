import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';
import 'package:smart/src/ui/pageable/models/pageable_cache.dart';

PageableController<int, String> makeController({
  List<List<String>>? pages,
  int pageSize = 2,
  PreviousPageKeyGenerator<int, String>? getPreviousPageKey,
  bool enabled = true,
  Object? reloadKey,
  bool resetOnReloadKeyChange = false,
  String? cacheKey,
  PageableCache<int, String>? cache,
}) {
  List<String> fetch(int page) {
    if (pages != null && page >= 0 && page < pages.length) return pages[page];
    return [];
  }

  return PageableController<int, String>(
    fetchPage: (page) async => fetch(page),
    getFirstPageKey: 1,
    getNextPageKey: (key, items, total) => items.isEmpty ? null : key + 1,
    getPreviousPageKey: getPreviousPageKey,
    pageSize: pageSize,
    enabled: enabled,
    reloadKey: reloadKey,
    resetOnReloadKeyChange: resetOnReloadKeyChange,
    cacheKey: cacheKey,
    cache: cache,
    showLog: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Waits until [condition] holds (up to ~5s), tolerating slow machines
  /// where the 100ms fetch debounce may fire late.
  Future<void> waitForCondition(bool Function() condition) async {
    const step = Duration(milliseconds: 50);
    for (var i = 0; i < 100 && !condition(); i++) {
      await Future<void>.delayed(step);
    }
    expect(condition(), isTrue);
  }
  group('PageableController usePageable parity', () {
    test('fetch first then next page appends items and completes', () async {
      final controller = makeController(
        pages: [
          [],
          ['a', 'b'],
          ['c'],
        ],
      );

      await controller.fetchFirstPage();
      expect(controller.items, ['a', 'b']);
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.currentPageKey, 1);

      await controller.fetchNextPage();
      await waitForCondition(() => controller.items.length == 3);
      expect(controller.items, ['a', 'b', 'c']);
      expect(controller.status, PageableStatus.COMPLETED);

      controller.dispose();
    });

    test('fetchPreviousPage prepends earlier items', () async {
      final controller = makeController(
        pages: [
          ['prev'],
          ['a', 'b'],
          ['c'],
        ],
        getPreviousPageKey: (firstKey, items, total) => firstKey > 0 ? firstKey - 1 : null,
      );

      await controller.replaceSnapshot(items: ['a', 'b'], pageKey: 1);
      expect(controller.canLoadPrevious, isFalse);

      await controller.replaceSnapshot(items: ['a', 'b'], pageKey: 1, prevPageKey: 0);
      expect(controller.canLoadPrevious, isTrue);

      await controller.fetchPreviousPage();
      expect(controller.items, ['prev', 'a', 'b']);
      expect(controller.status, PageableStatus.LOADED_PAGE);

      controller.dispose();
    });

    test('replaceSnapshot applies items, keys, and status', () async {
      final controller = makeController();

      await controller.replaceSnapshot(items: ['x'], pageKey: 1, nextPageKey: 2);
      expect(controller.items, ['x']);
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.currentPageKey, 1);
      expect(controller.pageable.nextPageKey, 2);

      await controller.replaceSnapshot(items: []);
      expect(controller.items, isEmpty);
      expect(controller.status, PageableStatus.NO_ITEMS_FOUND);

      controller.dispose();
    });

    test('setReloadKey with same key is a no-op, reset reloads first page', () async {
      var calls = 0;
      final controller = PageableController<int, String>(
        fetchPage: (page) async {
          calls += 1;
          return ['a', 'b'];
        },
        getFirstPageKey: 1,
        getNextPageKey: (key, items, total) => null,
        pageSize: 2,
        reloadKey: 'v1',
        showLog: false,
      );

      await controller.setReloadKey('v1');
      expect(calls, 0);

      await controller.setReloadKey('v2', reset: true);
      expect(calls, 1);
      expect(controller.items, ['a', 'b']);

      controller.dispose();
    });

    test('setEnabled(false) parks controller and blocks auto-load flags', () async {
      final controller = makeController(enabled: false);
      expect(controller.status, PageableStatus.COMPLETED);
      expect(controller.canFetchNextPage, isFalse);
      expect(controller.canLoadPrevious, isFalse);

      await controller.setEnabled(true);
      controller.dispose();
    });

    test('retry recovers a previous-page error', () async {
      var attempts = 0;
      final controller = PageableController<int, String>(
        fetchPage: (page) async {
          if (page == 0 && attempts == 0) {
            attempts += 1;
            throw Exception('boom');
          }
          return page == 0 ? ['prev'] : ['a', 'b'];
        },
        getFirstPageKey: 1,
        getNextPageKey: (key, items, total) => null,
        getPreviousPageKey: (firstKey, items, total) => firstKey > 0 ? firstKey - 1 : null,
        pageSize: 2,
        showLog: false,
      );

      await controller.replaceSnapshot(items: ['a', 'b'], pageKey: 1, prevPageKey: 0);
      await controller.fetchPreviousPage();
      expect(controller.status, PageableStatus.PREVIOUS_PAGE_ERROR);

      await controller.retry();
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.items, ['prev', 'a', 'b']);

      controller.dispose();
    });

    test('InMemoryPageableCache round-trips snapshots', () async {
      final cache = InMemoryPageableCache<int, String>();
      final controller = makeController(
        pages: [[], ['a', 'b'], ['c']],
        cacheKey: 'parity-test-cache',
        cache: cache,
      );

      await controller.fetchFirstPage();
      final snapshot = await cache.read('parity-test-cache');
      expect(snapshot, isNotNull);
      expect(snapshot!.items, ['a', 'b']);

      await cache.clearAll();
      expect(await cache.read('parity-test-cache'), isNull);

      controller.dispose();
    });

    test('cacheKey without cache defaults to shared in-memory storage', () async {
      final first = makeController(
        pages: [[], ['a', 'b']],
        cacheKey: 'parity-default-cache',
      );
      expect(first.cache, isA<InMemoryPageableCache<int, String>>());

      await first.fetchFirstPage();

      final second = InMemoryPageableCache<int, String>();
      final snapshot = await second.read('parity-default-cache');
      expect(snapshot, isNotNull);
      expect(snapshot!.items, ['a', 'b']);

      await InMemoryPageableCache<int, String>().clearAll();

      first.dispose();
    });

    test('PageableStatus previous-page getters', () {
      expect(PageableStatus.LOADING_PREVIOUS_PAGE.isLoading, isTrue);
      expect(PageableStatus.LOADING_PREVIOUS_PAGE.isLoadingPreviousPage, isTrue);
      expect(PageableStatus.PREVIOUS_PAGE_ERROR.hasError, isTrue);
      expect(PageableStatus.PREVIOUS_PAGE_ERROR.isPreviousPageError, isTrue);
      expect(PageableStatus.PREVIOUS_PAGE_ERROR.canLoadPrevious, isTrue);
      expect(PageableStatus.REFRESHING.isLoading, isTrue);
    });
  });
}