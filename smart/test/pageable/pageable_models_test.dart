import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';

void main() {
  group('PageResult', () {
    test('hasItems and itemCount reflect items', () {
      const empty = PageResult<int, String>(pageKey: 1, items: []);
      expect(empty.hasItems, isFalse);
      expect(empty.itemCount, 0);

      const full = PageResult<int, String>(pageKey: 1, items: ['a', 'b']);
      expect(full.hasItems, isTrue);
      expect(full.itemCount, 2);
    });

    test('toString summarizes the page', () {
      const page = PageResult<int, String>(pageKey: 1, items: ['a'], totalCount: 10);
      expect(page.toString(), contains('pageKey: 1'));
      expect(page.toString(), contains('totalCount: 10'));
    });

    test('equality includes metadata', () {
      const a = PageResult<int, String>(pageKey: 1, items: ['a']);
      const b = PageResult<int, String>(pageKey: 1, items: ['a']);
      const c = PageResult<int, String>(pageKey: 2, items: ['a']);
      expect(a, b);
      expect(a == c, isFalse);
    });
  });

  group('PageableView.initial', () {
    test('starts empty and loading the first page', () {
      final view = PageableView<int, String>.initial(pageSize: 20);
      expect(view.pages, isEmpty);
      expect(view.items, isEmpty);
      expect(view.itemCount, 0);
      expect(view.pageCount, 0);
      expect(view.status, PageableStatus.LOADING_FIRST_PAGE);
      expect(view.hasData, isFalse);
      expect(view.isEmpty, isFalse);
      expect(view.hasNextPage, isFalse);
      expect(view.hasPreviousPage, isFalse);
      expect(view.nextPageKey, isNull);
      expect(view.prevPageKey, isNull);
      expect(view.firstPageKey, isNull);
      expect(view.lastPageKey, isNull);
    });
  });

  group('PageableView.fromPages', () {
    test('empty pages resolve to NO_ITEMS_FOUND', () {
      final view = PageableView<int, String>.fromPages(pages: []);
      expect(view.status, PageableStatus.NO_ITEMS_FOUND);
      expect(view.hasData, isFalse);
    });

    test('non-empty pages resolve to LOADED_PAGE with cursors', () {
      final view = PageableView<int, String>.fromPages(
        pages: const [
          PageResult(pageKey: 1, items: ['a']),
          PageResult(pageKey: 2, items: ['b', 'c']),
        ],
        nextPageKey: 3,
        prevPageKey: 0,
        pageSize: 2,
      );
      expect(view.status, PageableStatus.LOADED_PAGE);
      expect(view.items, ['a', 'b', 'c']);
      expect(view.itemCount, 3);
      expect(view.pageCount, 2);
      expect(view.hasData, isTrue);
      expect(view.nextPageKey, 3);
      expect(view.prevPageKey, 0);
      expect(view.firstPageKey, 1);
      expect(view.lastPageKey, 2);
      expect(view.firstPage?.items, ['a']);
      expect(view.lastPage?.items, ['b', 'c']);
    });
  });

  group('PageableView pagination flags', () {
    test('hasNextPage prefers an explicit next key', () {
      final view = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a'])],
        nextPageKey: 2,
        pageSize: 10,
      );
      expect(view.hasNextPage, isTrue);
    });

    test('hasNextPage falls back to the page-size heuristic', () {
      final full = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a', 'b'])],
        pageSize: 2,
      );
      expect(full.hasNextPage, isTrue);

      final short = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a'])],
        pageSize: 2,
      );
      expect(short.hasNextPage, isFalse);
    });

    test('canLoadMore combines cursor and status', () {
      final loadable = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a'])],
        nextPageKey: 2,
      );
      expect(loadable.canLoadMore, isTrue);

      final completed = loadable.copyWith(status: PageableStatus.COMPLETED, clearNextPageKey: true);
      expect(completed.canLoadMore, isFalse);
    });

    test('canLoadPrevious combines cursor and status', () {
      final loadable = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a'])],
        prevPageKey: 0,
      );
      expect(loadable.hasPreviousPage, isTrue);
      expect(loadable.canLoadPrevious, isTrue);

      final loading = loadable.copyWith(status: PageableStatus.LOADING_FIRST_PAGE);
      expect(loading.canLoadPrevious, isFalse);
    });
  });

  group('PageableView.copyWith', () {
    test('clear flags drop cursors and errors', () {
      final view = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a'])],
        nextPageKey: 2,
        prevPageKey: 0,
      ).copyWith(error: 'bad', status: PageableStatus.NEW_PAGE_ERROR);

      final cleared = view.copyWith(
        clearError: true,
        clearNextPageKey: true,
        clearPrevPageKey: true,
      );
      expect(cleared.error, isNull);
      expect(cleared.nextPageKey, isNull);
      expect(cleared.prevPageKey, isNull);
      expect(cleared.items, ['a']);
    });

    test('explicit keys replace stored cursors', () {
      final view = PageableView<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a'])],
        nextPageKey: 2,
      );
      final updated = view.copyWith(nextPageKey: 5, prevPageKey: 0);
      expect(updated.nextPageKey, 5);
      expect(updated.prevPageKey, 0);
    });

    test('bumps revision by default', () {
      final view = PageableView<int, String>.initial();
      expect(view.copyWith().revision, view.revision + 1);
      expect(view.copyWith(bumpRevision: false).revision, view.revision);
    });
  });

  group('PageableView lookups', () {
    PageableView<int, String> view() {
      return PageableView<int, String>.fromPages(
        pages: const [
          PageResult(pageKey: 1, items: ['a'], totalCount: 10),
          PageResult(pageKey: 2, items: ['b']),
        ],
      );
    }

    test('getPage finds pages by key', () {
      expect(view().getPage(1)?.items, ['a']);
      expect(view().getPage(2)?.items, ['b']);
      expect(view().getPage(9), isNull);
    });

    test('totalCount uses the most recent page that provides it', () {
      expect(view().totalCount, 10);
      expect(PageableView<int, String>.initial().totalCount, isNull);
    });

    test('reset returns to the initial state', () {
      final reset = view().reset();
      expect(reset.pages, isEmpty);
      expect(reset.status, PageableStatus.LOADING_FIRST_PAGE);
    });

    test('toString summarizes pages and status', () {
      expect(view().toString(), contains('pages: 2'));
    });
  });

  group('PageableSource', () {
    PageableSource<int, String> source(String id) {
      return PageableSource<int, String>(
        id: id,
        fetchPage: (page) async => [],
        firstPageKey: 1,
      );
    }

    test('same configuration is equal', () {
      expect(source('a'), source('a'));
    });

    test('different ids are not equal', () {
      expect(source('a') == source('b'), isFalse);
    });

    test('toString names the source', () {
      expect(source('feed').toString(), contains('feed'));
    });
  });

  group('InterleavedSourceState', () {
    test('convenience getters reflect state', () {
      const state = InterleavedSourceState<String>(
        id: 'feed',
        priority: 0,
        items: ['a', 'b'],
        canLoadMore: true,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
      );
      expect(state.itemCount, 2);
      expect(state.hasItems, isTrue);
      expect(state.hasError, isFalse);
    });

    test('error state is reported', () {
      const state = InterleavedSourceState<String>(
        id: 'ads',
        priority: 1,
        items: [],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.FIRST_PAGE_ERROR,
        error: 'bad',
      );
      expect(state.hasItems, isFalse);
      expect(state.hasError, isTrue);
      expect(state.toString(), contains('ads'));
    });
  });
}
