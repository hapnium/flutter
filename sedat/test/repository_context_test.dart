import 'package:flutter_test/flutter_test.dart';

import 'package:sedat/src/base_repository.dart';
import 'package:sedat/src/repository_mixin.dart';

class FakeRepositoryA extends BaseRepository<String, String> {
  FakeRepositoryA() : super('repo-a');

  @override
  String toStore(String item) => item;

  @override
  String fromStore(String? data) => data ?? '';
}

class FakeRepositoryB extends BaseRepository<int, int> {
  FakeRepositoryB() : super('repo-b');

  @override
  int toStore(int item) => item;

  @override
  int fromStore(int? data) => data ?? 0;
}

class FakeRepositoryC extends BaseRepository<String, String> {
  FakeRepositoryC() : super('repo-c');

  @override
  String toStore(String item) => item;

  @override
  String fromStore(String? data) => data ?? '';
}

void main() {
  late RepositoryContext context;

  setUp(() {
    context = RepositoryContext();
  });

  tearDown(() {
    context.clear();
  });

  group('RepositoryContext', () {
    group('find<T>', () {
      test('returns null when empty', () {
        expect(context.find<FakeRepositoryA>(), isNull);
      });

      test('returns null for unregistered type', () {
        context.register([FakeRepositoryA()]);
        expect(context.find<FakeRepositoryB>(), isNull);
      });

      test('returns registered repository by type', () {
        final repo = FakeRepositoryA();
        context.register([repo]);

        final found = context.find<FakeRepositoryA>();
        expect(found, same(repo));
      });

      test('returns first matching instance when multiple registered', () {
        final repo1 = FakeRepositoryA();
        final repo2 = FakeRepositoryA();
        context.register([repo1, repo2]);

        final found = context.find<FakeRepositoryA>();
        expect(found, same(repo1));
      });

      test('returns different types independently', () {
        final repoA = FakeRepositoryA();
        final repoB = FakeRepositoryB();
        context.register([repoA, repoB]);

        expect(context.find<FakeRepositoryA>(), same(repoA));
        expect(context.find<FakeRepositoryB>(), same(repoB));
      });
    });

    group('register', () {
      test('adds repositories to the registry', () {
        final repo = FakeRepositoryA();
        context.register([repo]);

        expect(context.getAll(), contains(same(repo)));
      });

      test('appends to existing registrations', () {
        final repoA = FakeRepositoryA();
        final repoB = FakeRepositoryB();
        context.register([repoA]);
        context.register([repoB]);

        final all = context.getAll().toList();
        expect(all.length, 2);
        expect(all[0], same(repoA));
        expect(all[1], same(repoB));
      });

      test('handles empty list', () {
        context.register([]);
        expect(context.getAll(), isEmpty);
      });
    });

    group('getAll', () {
      test('returns empty iterable when no repositories registered', () {
        expect(context.getAll(), isEmpty);
      });

      test('returns all registered repositories in order', () {
        final repoA = FakeRepositoryA();
        final repoB = FakeRepositoryB();
        final repoC = FakeRepositoryC();
        context.register([repoA, repoB, repoC]);

        final all = context.getAll().toList();
        expect(all, [same(repoA), same(repoB), same(repoC)]);
      });
    });

    group('clear', () {
      test('removes all registered repositories', () {
        context.register([FakeRepositoryA(), FakeRepositoryB()]);
        context.clear();

        expect(context.getAll(), isEmpty);
        expect(context.find<FakeRepositoryA>(), isNull);
        expect(context.find<FakeRepositoryB>(), isNull);
      });

      test('is safe to call on empty context', () {
        expect(() => context.clear(), returnsNormally);
      });

      test('can re-register after clearing', () {
        final repo1 = FakeRepositoryA();
        context.register([repo1]);
        context.clear();

        final repo2 = FakeRepositoryA();
        context.register([repo2]);

        expect(context.find<FakeRepositoryA>(), same(repo2));
        expect(context.getAll().length, 1);
      });
    });

    group('INSTANCE', () {
      test('is not null', () {
        expect(RepositoryContext.INSTANCE, isNotNull);
      });

      test('is the same reference across accesses', () {
        expect(identical(RepositoryContext.INSTANCE, RepositoryContext.INSTANCE), isTrue);
      });

      test('can be replaced with a fresh instance', () {
        final original = RepositoryContext.INSTANCE;
        final fresh = RepositoryContext();
        RepositoryContext.INSTANCE = fresh;

        try {
          expect(RepositoryContext.INSTANCE, same(fresh));
          expect(RepositoryContext.INSTANCE, isNot(same(original)));
        } finally {
          RepositoryContext.INSTANCE = original;
        }
      });
    });
  });
}