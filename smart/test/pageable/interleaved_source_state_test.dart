import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/ui/pageable/models/interleaved_source_state.dart';
import 'package:smart/src/ui/pageable/models/pageable_status.dart';

void main() {
  group('InterleavedSourceState', () {
    test('stores all properties', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 1,
        items: ['a', 'b'],
        canLoadMore: true,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
        error: 'some error',
      );

      expect(state.id, 'test');
      expect(state.priority, 1);
      expect(state.items, ['a', 'b']);
      expect(state.canLoadMore, isTrue);
      expect(state.isFetching, isFalse);
      expect(state.status, PageableStatus.LOADED_PAGE);
      expect(state.error, 'some error');
    });

    test('itemCount returns items length', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: ['a', 'b', 'c'],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.COMPLETED,
      );

      expect(state.itemCount, 3);
    });

    test('hasItems returns true when items non-empty', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: ['a'],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
      );

      expect(state.hasItems, isTrue);
    });

    test('hasItems returns false when items empty', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: [],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.NO_ITEMS_FOUND,
      );

      expect(state.hasItems, isFalse);
    });

    test('hasError returns true when error is non-null', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: [],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.FIRST_PAGE_ERROR,
        error: 'failed',
      );

      expect(state.hasError, isTrue);
    });

    test('hasError returns false when error is null', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: [],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.COMPLETED,
      );

      expect(state.hasError, isFalse);
    });

    test('equality is value-based', () {
      final state1 = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: ['a'],
        canLoadMore: true,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
      );

      final state2 = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: ['a'],
        canLoadMore: true,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
      );

      expect(state1, equals(state2));
    });

    test('different states are not equal', () {
      final state1 = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: [],
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.COMPLETED,
      );

      final state2 = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: ['a'],
        canLoadMore: true,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
      );

      expect(state1, isNot(equals(state2)));
    });

    test('toString includes key properties', () {
      final state = InterleavedSourceState<String>(
        id: 'feed',
        priority: 1,
        items: ['a', 'b'],
        canLoadMore: true,
        isFetching: false,
        status: PageableStatus.LOADED_PAGE,
      );

      final str = state.toString();
      expect(str, contains('feed'));
      expect(str, contains('1'));
      expect(str, contains('2'));
      expect(str, contains('true'));
    });

    test('items list is unmodifiable', () {
      final state = InterleavedSourceState<String>(
        id: 'test',
        priority: 0,
        items: List.unmodifiable(['a', 'b']),
        canLoadMore: false,
        isFetching: false,
        status: PageableStatus.COMPLETED,
      );

      expect(() => state.items.add('c'), throwsA(isA<UnsupportedError>()));
      expect(() => state.items.removeAt(0), throwsA(isA<UnsupportedError>()));
    });
  });
}