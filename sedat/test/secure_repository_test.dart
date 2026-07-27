import 'package:flutter_test/flutter_test.dart';

import 'package:sedat/src/base_repository.dart';
import 'package:sedat/src/repository_mixin.dart';
import 'package:sedat/src/secure_database_exception.dart';

class FakeRepoA extends BaseRepository<String, String> {
  FakeRepoA() : super('test-a');

  @override
  String toStore(String item) => item;

  @override
  String fromStore(String? data) => data ?? '';
}

class FakeRepoB extends BaseRepository<int, int> {
  FakeRepoB() : super('test-b');

  @override
  int toStore(int item) => item;

  @override
  int fromStore(int? data) => data ?? 0;
}

class ServiceA with SecureRepository<FakeRepoA> {
  String get repoName => repository.runtimeType.toString();
}

class ServiceB with SecureRepository<FakeRepoB> {
  int get repoHashCode => repository.hashCode;
}

void main() {
  setUp(() {
    RepositoryContext.INSTANCE.clear();
  });

  tearDown(() {
    RepositoryContext.INSTANCE.clear();
  });

  group('SecureRepository', () {
    group('repository getter', () {
      test('returns registered repository', () {
        final repo = FakeRepoA();
        RepositoryContext.INSTANCE.register([repo]);

        final service = ServiceA();
        expect(service.repository, same(repo));
      });

      test('returns cached instance on subsequent access', () {
        final repo = FakeRepoA();
        RepositoryContext.INSTANCE.register([repo]);

        final service = ServiceA();
        final first = service.repository;
        final second = service.repository;

        expect(identical(first, second), isTrue);
      });

      test('throws SecureDatabaseException when not registered', () {
        final service = ServiceA();

        expect(
          () => service.repository,
          throwsA(isA<SecureDatabaseException>()),
        );
      });

      test('exception message contains the missing type', () {
        final service = ServiceA();

        expect(
          () => service.repository,
          throwsA(
            isA<SecureDatabaseException>().having(
              (e) => e.message,
              'message',
              contains('FakeRepoA'),
            ),
          ),
        );
      });

      test('exception message contains remediation steps', () {
        final service = ServiceA();

        expect(
          () => service.repository,
          throwsA(
            isA<SecureDatabaseException>().having(
              (e) => e.message,
              'message',
              contains('How to fix'),
            ),
          ),
        );
      });

      test('exception message lists registered repositories', () {
        RepositoryContext.INSTANCE.register([FakeRepoB()]);
        final service = ServiceA();

        expect(
          () => service.repository,
          throwsA(
            isA<SecureDatabaseException>().having(
              (e) => e.message,
              'message',
              contains('FakeRepoB'),
            ),
          ),
        );
      });

      test('works with different type parameter', () {
        final repo = FakeRepoB();
        RepositoryContext.INSTANCE.register([repo]);

        final service = ServiceB();
        expect(service.repository, same(repo));
      });

      test('different services resolve independently', () {
        final repoA = FakeRepoA();
        final repoB = FakeRepoB();
        RepositoryContext.INSTANCE.register([repoA, repoB]);

        final serviceA = ServiceA();
        final serviceB = ServiceB();

        expect(serviceA.repository, same(repoA));
        expect(serviceB.repository, same(repoB));
      });

      test('each service instance has its own cache', () {
        final repo = FakeRepoA();
        RepositoryContext.INSTANCE.register([repo]);

        final service1 = ServiceA();
        final service2 = ServiceA();

        // Both return the same repo from context
        expect(service1.repository, same(repo));
        expect(service2.repository, same(repo));

        // Caches are independent: clearing context doesn't affect cached services
        RepositoryContext.INSTANCE.clear();
        expect(service1.repository, same(repo));
        expect(service2.repository, same(repo));
      });
    });
  });
}