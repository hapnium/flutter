import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/ui/pageable/models/pageable_source.dart';

void main() {
  group('PageableSource', () {
    test('stores all properties', () {
      final source = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async => [],
        firstPageKey: 1,
        getNextPageKey: (key, items, total) => key + 1,
        priority: 2,
        pageSize: 25,
      );

      expect(source.id, 'test');
      expect(source.firstPageKey, 1);
      expect(source.priority, 2);
      expect(source.pageSize, 25);
      expect(source.getNextPageKey, isNotNull);
    });

    test('default priority is 0', () {
      final source = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async => [],
        firstPageKey: 1,
      );

      expect(source.priority, 0);
    });

    test('default pageSize is 20', () {
      final source = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async => [],
        firstPageKey: 1,
      );

      expect(source.pageSize, 20);
    });

    test('getNextPageKey is nullable', () {
      final source = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async => [],
        firstPageKey: 1,
      );

      expect(source.getNextPageKey, isNull);
    });

    test('equality is based on id, priority, firstPageKey, pageSize', () {
      final source1 = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async => [],
        firstPageKey: 1,
        priority: 0,
        pageSize: 20,
      );

      final source2 = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async => ['item'],
        firstPageKey: 1,
        priority: 0,
        pageSize: 20,
      );

      expect(source1, equals(source2));
    });

    test('different ids are not equal', () {
      final source1 = PageableSource<int, String>(
        id: 'a',
        fetchPage: (key) async => [],
        firstPageKey: 1,
      );

      final source2 = PageableSource<int, String>(
        id: 'b',
        fetchPage: (key) async => [],
        firstPageKey: 1,
      );

      expect(source1, isNot(equals(source2)));
    });

    test('toString includes key properties', () {
      final source = PageableSource<int, String>(
        id: 'feed',
        fetchPage: (key) async => [],
        firstPageKey: 1,
        priority: 1,
        pageSize: 10,
      );

      final str = source.toString();
      expect(str, contains('feed'));
      expect(str, contains('1'));
      expect(str, contains('10'));
    });

    test('fetchPage callback is invoked', () async {
      var called = false;
      final source = PageableSource<int, String>(
        id: 'test',
        fetchPage: (key) async {
          called = true;
          return ['item'];
        },
        firstPageKey: 1,
      );

      final result = await source.fetchPage(1);
      expect(called, isTrue);
      expect(result, ['item']);
    });

    test('supports different PageKey types', () {
      final source = PageableSource<String, int>(
        id: 'cursor',
        fetchPage: (key) async => [1, 2, 3],
        firstPageKey: 'start',
        getNextPageKey: (key, items, total) => items.last.toString(),
      );

      expect(source.firstPageKey, 'start');
    });
  });
}