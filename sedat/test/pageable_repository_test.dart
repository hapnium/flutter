import 'package:flutter_test/flutter_test.dart';
import 'package:hapnium/hapnium.dart';

import 'package:sedat/src/base_repository.dart';
import 'package:sedat/src/repository_mixin.dart';

class FakeJsonEntityRepo extends BaseRepository<String, JsonMap> {
  FakeJsonEntityRepo() : super('json-entity');

  @override
  JsonMap toStore(String item) => {'value': item};

  @override
  String fromStore(JsonMap? data) => data?['value'] ?? '';
}

class DefaultPageableRepo extends FakeJsonEntityRepo
    with PageableRepository<String, JsonMap, DefaultPageableRepo> {}

class CustomFindPageRepo extends FakeJsonEntityRepo
    with PageableRepository<String, JsonMap, CustomFindPageRepo> {
  @override
  Future<Page<String>> findPage(Pageable pageable) async {
    final items = ['a', 'b', 'c'];
    return Page.of(items, pageable);
  }
}

class CustomFindAllSortedRepo extends FakeJsonEntityRepo
    with PageableRepository<String, JsonMap, CustomFindAllSortedRepo> {
  @override
  Future<List<String>> findAllSorted(PageSort sort) async {
    return ['x', 'y', 'z'];
  }
}

class CustomIterableRepo extends FakeJsonEntityRepo
    with PageableRepository<String, JsonMap, CustomIterableRepo> {
  @override
  Future<Iterable<String>> findAllSortedIterable(PageSort sort) async {
    return ['m', 'n', 'o'];
  }
}

class CustomBothRepo extends FakeJsonEntityRepo
    with PageableRepository<String, JsonMap, CustomBothRepo> {
  @override
  Future<Page<String>> findPage(Pageable pageable) async {
    return Page.of(['custom'], pageable);
  }

  @override
  Future<Iterable<String>> findAllSortedIterable(PageSort sort) async {
    return ['sorted1', 'sorted2'];
  }
}

void main() {
  group('PageableRepository', () {
    group('findPage', () {
      test('returns empty page by default', () async {
        final repo = DefaultPageableRepo();
        final pageable = Pageable.unpaged();

        final page = await repo.findPage(pageable);

        expect(page.isEmpty(), isTrue);
        expect(page.hasContent(), isFalse);
        expect(page.getContent(), isEmpty);
      });

      test('returns empty page for paged request by default', () async {
        final repo = DefaultPageableRepo();
        final pageable = Pageable.ofSize(10);

        final page = await repo.findPage(pageable);

        expect(page.getContent(), isEmpty);
      });

      test('override returns custom page', () async {
        final repo = CustomFindPageRepo();
        final pageable = Pageable.ofSize(10);

        final page = await repo.findPage(pageable);

        expect(page.getContent(), ['a', 'b', 'c']);
        expect(page.hasContent(), isTrue);
      });
    });

    group('findAllSorted', () {
      test('returns empty list by default', () async {
        final repo = DefaultPageableRepo();
        final sort = PageSort.UNSORTED;

        final result = await repo.findAllSorted(sort);

        expect(result, isEmpty);
      });

      test('delegates to findAllSortedIterable by default', () async {
        final repo = CustomIterableRepo();
        final sort = PageSort.UNSORTED;

        final result = await repo.findAllSorted(sort);

        expect(result, ['m', 'n', 'o']);
      });

      test('override returns custom sorted list', () async {
        final repo = CustomFindAllSortedRepo();
        final sort = PageSort.UNSORTED;

        final result = await repo.findAllSorted(sort);

        expect(result, ['x', 'y', 'z']);
      });
    });

    group('findAllSortedIterable', () {
      test('returns empty iterable by default', () async {
        final repo = DefaultPageableRepo();
        final sort = PageSort.UNSORTED;

        final result = await repo.findAllSortedIterable(sort);

        expect(result, isEmpty);
      });

      test('override returns custom iterable', () async {
        final repo = CustomIterableRepo();
        final sort = PageSort.UNSORTED;

        final result = await repo.findAllSortedIterable(sort);

        expect(result.toList(), ['m', 'n', 'o']);
      });
    });

    group('combined overrides', () {
      test('findPage and findAllSortedIterable work independently', () async {
        final repo = CustomBothRepo();
        final pageable = Pageable.ofSize(5);
        final sort = PageSort.UNSORTED;

        final page = await repo.findPage(pageable);
        final sorted = await repo.findAllSortedIterable(sort);

        expect(page.getContent(), ['custom']);
        expect(sorted.toList(), ['sorted1', 'sorted2']);
      });

      test('findAllSorted uses overridden findAllSortedIterable', () async {
        final repo = CustomBothRepo();
        final sort = PageSort.UNSORTED;

        final result = await repo.findAllSorted(sort);

        expect(result, ['sorted1', 'sorted2']);
      });
    });
  });
}