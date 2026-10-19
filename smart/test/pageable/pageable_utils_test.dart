import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';
import 'package:smart/src/ui/pageable/helpers/pageable_helper.dart';

void main() {
  group('PageResultBuilderExtension', () {
    test('buildPageablePages chunks items from page zero', () {
      final items = List.generate(25, (i) => 'Item $i');
      final pages = items.buildPageablePages(pageSize: 10);
      expect(pages.length, 3);
      expect(pages[0].pageKey, 0);
      expect(pages[0].items.length, 10);
      expect(pages[2].items.length, 5);
    });

    test('buildPageablePages rejects non-positive page sizes', () {
      expect(() => ['a'].buildPageablePages(pageSize: 0), throwsArgumentError);
    });

    test('buildPageablePagesWithKeyBuilder uses custom keys', () {
      final items = List.generate(25, (i) => 'Item $i');
      final pages = items.buildPageablePagesWithKeyBuilder(
        keyBuilder: (startIndex) => 'page_${startIndex ~/ 10}',
        pageSize: 10,
      );
      expect(pages.length, 3);
      expect(pages[0].pageKey, 'page_0');
      expect(pages[2].items.length, 5);
    });

    test('buildPageablePagesWithKeyBuilder rejects non-positive page sizes', () {
      expect(
        () => ['a'].buildPageablePagesWithKeyBuilder(
          keyBuilder: (index) => 'page_$index',
          pageSize: 0,
        ),
        throwsArgumentError,
      );
    });

    test('buildPageablePage slices the requested page', () {
      final items = List.generate(25, (i) => 'Item $i');
      final page = items.buildPageablePage(pageKey: 1, pageSize: 10);
      expect(page.pageKey, 1);
      expect(page.items.length, 10);
      expect(page.items.first, 'Item 10');
    });

    test('buildPageablePage returns empty pages out of bounds', () {
      final items = List.generate(5, (i) => 'Item $i');
      expect(items.buildPageablePage(pageKey: 3, pageSize: 10).items, isEmpty);
      expect(items.buildPageablePage(pageKey: -1, pageSize: 10).items, isEmpty);
    });

    test('buildPageablePage rejects non-positive page sizes', () {
      expect(() => ['a'].buildPageablePage(pageKey: 0, pageSize: 0), throwsArgumentError);
    });
  });

  group('PageableHelper pure functions', () {
    test('defaultStrategy alternates from index zero', () {
      expect(PageableHelper.defaultStrategy(0), isFalse);
      expect(PageableHelper.defaultStrategy(1), isTrue);
      expect(PageableHelper.defaultStrategy(2), isFalse);
    });

    test('countSeparatorsBeforeIndex counts matching indices', () {
      bool even(int index) => index.isEven;
      expect(PageableHelper.countSeparatorsBeforeIndex(even, 0), 0);
      expect(PageableHelper.countSeparatorsBeforeIndex(even, 5), 3);
    });

    test('getActualItemIndex subtracts separators', () {
      bool even(int index) => index.isEven;
      expect(PageableHelper.getActualItemIndex(even, false, 4), 4);
      expect(PageableHelper.getActualItemIndex(even, true, 5), 5 - 3);
    });

    test('canAddExtra covers loading, error, and completed', () {
      expect(PageableHelper.canAddExtra(PageableStatus.LOADING_NEW_PAGE), isTrue);
      expect(PageableHelper.canAddExtra(PageableStatus.NEW_PAGE_ERROR), isTrue);
      expect(PageableHelper.canAddExtra(PageableStatus.COMPLETED), isTrue);

      expect(PageableHelper.canAddExtra(PageableStatus.LOADING_FIRST_PAGE), isFalse);
      expect(PageableHelper.canAddExtra(PageableStatus.LOADED_PAGE), isFalse);
      expect(PageableHelper.canAddExtra(PageableStatus.FIRST_PAGE_ERROR), isFalse);
      expect(PageableHelper.canAddExtra(PageableStatus.NO_ITEMS_FOUND), isFalse);
      expect(PageableHelper.canAddExtra(PageableStatus.REFRESHING), isFalse);
    });
  });
}