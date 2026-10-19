import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';
import 'package:smart/src/ui/pageable/models/pageable_cache.dart';

void main() {
  group('PageableCacheSnapshot', () {
    test('hasItems and items flatten pages', () {
      const snapshot = PageableCacheSnapshot<int, String>(
        pages: [
          PageResult(pageKey: 1, items: ['a']),
          PageResult(pageKey: 2, items: ['b', 'c']),
        ],
        nextPageKey: 3,
        prevPageKey: 0,
      );
      expect(snapshot.hasItems, isTrue);
      expect(snapshot.items, ['a', 'b', 'c']);
      expect(snapshot.nextPageKey, 3);
      expect(snapshot.prevPageKey, 0);

      const empty = PageableCacheSnapshot<int, String>(pages: []);
      expect(empty.hasItems, isFalse);
      expect(empty.items, isEmpty);
    });
  });

  group('InMemoryPageableCache', () {
    late InMemoryPageableCache<int, String> cache;

    setUp(() async {
      cache = InMemoryPageableCache<int, String>();
      await cache.clearAll();
    });

    PageableCacheSnapshot<int, String> snapshot() {
      return const PageableCacheSnapshot<int, String>(
        pages: [PageResult(pageKey: 1, items: ['a', 'b'])],
        nextPageKey: 2,
        prevPageKey: 0,
      );
    }

    test('reads null before anything is written', () async {
      expect(await cache.read('missing'), isNull);
    });

    test('round-trips snapshots with cursors', () async {
      await cache.write('feed', snapshot());
      final restored = await cache.read('feed');
      expect(restored, isNotNull);
      expect(restored!.items, ['a', 'b']);
      expect(restored.nextPageKey, 2);
      expect(restored.prevPageKey, 0);
    });

    test('writes replace previous entries', () async {
      await cache.write('feed', snapshot());
      await cache.write(
        'feed',
        const PageableCacheSnapshot<int, String>(
          pages: [PageResult(pageKey: 1, items: ['z'])],
        ),
      );
      expect((await cache.read('feed'))!.items, ['z']);
    });

    test('writes are defensively copied', () async {
      final items = ['a'];
      await cache.write(
        'feed',
        PageableCacheSnapshot<int, String>(
          pages: [PageResult(pageKey: 1, items: items)],
        ),
      );
      items.add('mutated');
      expect((await cache.read('feed'))!.items, ['a']);
    });

    test('delete removes entries', () async {
      await cache.write('feed', snapshot());
      await cache.delete('feed');
      expect(await cache.read('feed'), isNull);
      await cache.delete('missing');
    });

    test('clearAll drops every entry', () async {
      await cache.write('a', snapshot());
      await cache.write('b', snapshot());
      await cache.clearAll();
      expect(await cache.read('a'), isNull);
      expect(await cache.read('b'), isNull);
    });

    test('mismatched types read back as null', () async {
      await cache.write('feed', snapshot());
      final other = InMemoryPageableCache<String, int>();
      expect(await other.read('feed'), isNull);
      await other.clearAll();
    });

    test('store is shared across instances', () async {
      await cache.write('feed', snapshot());
      final second = InMemoryPageableCache<int, String>();
      expect((await second.read('feed'))!.items, ['a', 'b']);
      await second.clearAll();
    });
  });
}