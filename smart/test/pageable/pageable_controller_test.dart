import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';

PageableController<int, String> makeController({
  required FutureOr<List<String>> Function(int page) fetch,
  int firstPageKey = 1,
  NextPageKeyGenerator<int, String>? getNextPageKey,
  PreviousPageKeyGenerator<int, String>? getPreviousPageKey,
  int pageSize = 2,
  int maxRetries = 0,
  PageableRetryIf? retryIf,
  PageableRetryCallback? onRetryAttempt,
  Duration? pollInterval,
  bool pausePollingWhenHidden = false,
}) {
  return PageableController<int, String>(
    fetchPage: (page) => fetch(page),
    getFirstPageKey: firstPageKey,
    getNextPageKey: getNextPageKey,
    getPreviousPageKey: getPreviousPageKey,
    pageSize: pageSize,
    maxRetries: maxRetries,
    retryIf: retryIf,
    onRetryAttempt: onRetryAttempt,
    pollInterval: pollInterval,
    pausePollingWhenHidden: pausePollingWhenHidden,
    showLog: false,
  );
}

Future<void> settleNextPage() => Future<void>.delayed(const Duration(milliseconds: 250));

/// Waits until [condition] holds (up to ~5s), tolerating slow CI machines
/// where the 100ms fetch debounce may fire late.
Future<void> waitForCondition(bool Function() condition, {String? reason}) async {
  const step = Duration(milliseconds: 50);
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(step);
  }
  expect(condition(), isTrue, reason: reason ?? 'condition not met within 5s');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageableController equality', () {
    test('controllers with matching configuration have distinct identities', () {
      final first = makeController(fetch: (_) async => []);
      final second = makeController(fetch: (_) async => []);

      expect(first, same(first));
      expect(first.uniqueId, isNot(second.uniqueId));
      expect(first, isNot(second));

      first.dispose();
      second.dispose();
    });
  });

  group('fetchFirstPage', () {
    test('empty first page resolves to NO_ITEMS_FOUND', () async {
      final controller = makeController(fetch: (_) async => []);
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.NO_ITEMS_FOUND);
      expect(controller.items, isEmpty);
      expect(controller.pageable.nextPageKey, isNull);
      controller.dispose();
    });

    test('full first page resolves to LOADED_PAGE with a next key', () async {
      final controller = makeController(
        fetch: (_) async => ['a', 'b'],
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.items, ['a', 'b']);
      expect(controller.pageable.nextPageKey, 2);
      expect(controller.currentPageKey, 1);
      controller.dispose();
    });

    test('short first page completes and clears the next key', () async {
      final controller = makeController(
        fetch: (_) async => ['a'],
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.COMPLETED);
      expect(controller.pageable.nextPageKey, isNull);
      controller.dispose();
    });

    test('full page without a generator stays loaded without a key', () async {
      final controller = makeController(fetch: (_) async => ['a', 'b']);
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.pageable.nextPageKey, isNull);
      controller.dispose();
    });

    test('failure resolves to FIRST_PAGE_ERROR', () async {
      final controller = makeController(
        fetch: (_) async => throw Exception('nope'),
      );
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.FIRST_PAGE_ERROR);
      expect(controller.error, isNotNull);
      controller.dispose();
    });

    test('SmartException failures expose the message', () async {
      final controller = makeController(
        fetch: (_) async => throw SmartException('oops'),
      );
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.FIRST_PAGE_ERROR);
      expect(controller.error, 'oops');
      controller.dispose();
    });

    test('reports loading while the fetch is in flight', () async {
      final gate = Completer<List<String>>();
      final controller = makeController(fetch: (_) => gate.future);
      final future = controller.fetchFirstPage();
      expect(controller.isFetching, isTrue);
      expect(controller.status, PageableStatus.LOADING_FIRST_PAGE);
      gate.complete(['a']);
      await future;
      expect(controller.isFetching, isFalse);
      expect(controller.items, ['a']);
      controller.dispose();
    });
  });

  group('fetchNextPage', () {
    test('appends pages and completes on a short page', () async {
      final controller = makeController(
        fetch: (page) async => page == 1 ? ['a', 'b'] : ['c'],
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      await controller.fetchNextPage();
      await waitForCondition(() => controller.items.length == 3);
      expect(controller.items, ['a', 'b', 'c']);
      expect(controller.status, PageableStatus.COMPLETED);
      expect(controller.pageable.nextPageKey, isNull);
      controller.dispose();
    });

    test('next-page failure keeps items with NEW_PAGE_ERROR', () async {
      final controller = makeController(
        fetch: (page) async {
          if (page == 1) return ['a', 'b'];
          throw Exception('next');
        },
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      await controller.fetchNextPage();
      await waitForCondition(() => controller.status == PageableStatus.NEW_PAGE_ERROR);
      expect(controller.status, PageableStatus.NEW_PAGE_ERROR);
      expect(controller.items, ['a', 'b']);
      expect(controller.error, isNotNull);
      controller.dispose();
    });

    test('missing next key completes without fetching', () async {
      var calls = 0;
      final controller = makeController(
        fetch: (_) async {
          calls += 1;
          return ['a', 'b'];
        },
      );
      await controller.fetchFirstPage();
      await controller.fetchNextPage();
      await waitForCondition(() => controller.status == PageableStatus.COMPLETED);
      expect(controller.status, PageableStatus.COMPLETED);
      expect(calls, 1);
      controller.dispose();
    });

    test('is a no-op when nothing can load', () async {
      var calls = 0;
      final controller = makeController(
        fetch: (_) async {
          calls += 1;
          return ['a'];
        },
      );
      await controller.fetchFirstPage();
      expect(controller.status, PageableStatus.COMPLETED);
      await controller.fetchNextPage();
      await settleNextPage();
      expect(calls, 1);
      controller.dispose();
    });

    test('debounces rapid calls into a single fetch', () async {
      var calls = 0;
      final controller = makeController(
        fetch: (page) async {
          calls += 1;
          return page == 1 ? ['a', 'b'] : ['c', 'd'];
        },
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      await controller.fetchNextPage();
      await controller.fetchNextPage();
      await waitForCondition(() => calls == 2);
      expect(calls, 2);
      expect(controller.items, ['a', 'b', 'c', 'd']);
      controller.dispose();
    });
  });

  group('refresh', () {
    test('replaces pages with a single fresh page', () async {
      var round = 1;
      final controller = makeController(
        fetch: (page) async => round == 1 ? ['a', 'b'] : ['z'],
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      await controller.fetchNextPage();
      await waitForCondition(() => controller.items.length == 4);
      round = 2;
      await controller.refresh();
      expect(controller.items, ['z']);
      expect(controller.pageable.pageCount, 1);
      controller.dispose();
    });

    test('failure with data keeps items and reports the error', () async {
      var fail = false;
      final controller = makeController(
        fetch: (_) async {
          if (fail) throw Exception('refresh');
          return ['a', 'b'];
        },
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      fail = true;
      await controller.refresh();
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.items, ['a', 'b']);
      expect(controller.error, isNotNull);
      controller.dispose();
    });

    test('failure without data resolves to FIRST_PAGE_ERROR', () async {
      final controller = makeController(
        fetch: (_) async => throw Exception('refresh'),
      );
      await controller.refresh();
      expect(controller.status, PageableStatus.FIRST_PAGE_ERROR);
      controller.dispose();
    });
  });

  group('retry', () {
    test('retries the next page after NEW_PAGE_ERROR', () async {
      var fail = true;
      final controller = makeController(
        fetch: (page) async {
          if (page == 1) return ['a', 'b'];
          if (fail) throw Exception('next');
          return ['c', 'd'];
        },
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      await controller.fetchNextPage();
      await waitForCondition(() => controller.status == PageableStatus.NEW_PAGE_ERROR);

      fail = false;
      await controller.retry();
      await waitForCondition(() => controller.items.length == 4);
      expect(controller.items, ['a', 'b', 'c', 'd']);
      controller.dispose();
    });

    test('is a no-op when nothing failed', () async {
      var calls = 0;
      final controller = makeController(
        fetch: (_) async {
          calls += 1;
          return ['a', 'b'];
        },
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.fetchFirstPage();
      await controller.retry();
      expect(calls, 1);
      controller.dispose();
    });
  });

  group('clear and notifyItemListChanged', () {
    test('clear resets to the initial state', () async {
      final controller = makeController(fetch: (_) async => ['a', 'b']);
      await controller.fetchFirstPage();
      controller.clear();
      expect(controller.items, isEmpty);
      expect(controller.status, PageableStatus.LOADING_FIRST_PAGE);
      controller.dispose();
    });

    test('notifyItemListChanged bumps the revision keeping items', () async {
      final controller = makeController(fetch: (_) async => ['a']);
      await controller.fetchFirstPage();
      final revision = controller.pageable.revision;
      controller.notifyItemListChanged();
      expect(controller.items, ['a']);
      expect(controller.pageable.revision, revision + 1);
      controller.dispose();
    });
  });

  group('retry configuration', () {
    test('retries until the fetch succeeds', () async {
      var attempts = 0;
      final controller = makeController(
        fetch: (_) async {
          attempts += 1;
          if (attempts < 3) throw Exception('flaky');
          return ['a'];
        },
        maxRetries: 3,
      );
      await controller.fetchFirstPage();
      expect(attempts, 3);
      expect(controller.items, ['a']);
      controller.dispose();
    });

    test('retryIf can veto retries', () async {
      var attempts = 0;
      final controller = makeController(
        fetch: (_) async {
          attempts += 1;
          throw Exception('nope');
        },
        maxRetries: 3,
        retryIf: (error, stackTrace, attempt) => false,
      );
      await controller.fetchFirstPage();
      expect(attempts, 1);
      expect(controller.status, PageableStatus.FIRST_PAGE_ERROR);
      controller.dispose();
    });

    test('onRetryAttempt observes every attempt', () async {
      final seen = <int>[];
      final controller = makeController(
        fetch: (_) async => throw Exception('nope'),
        maxRetries: 2,
        onRetryAttempt: (attempt, error, stackTrace, delay) => seen.add(attempt),
      );
      await controller.fetchFirstPage();
      expect(seen, [1, 2]);
      controller.dispose();
    });

    test('negative maxRetries throws', () {
      expect(
        () => makeController(fetch: (_) async => [], maxRetries: -1),
        throwsArgumentError,
      );
    });

    test('non-positive pollInterval throws', () {
      expect(
        () => makeController(
          fetch: (_) async => [],
          pollInterval: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });

  group('controller options', () {
    test('exposes status, items, and cursor getters', () async {
      final controller = makeController(
        fetch: (_) async => ['a', 'b'],
        getNextPageKey: (key, items, total) => key + 1,
      );
      await controller.replaceSnapshot(items: ['a'], pageKey: 1, nextPageKey: 2);
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.items, ['a']);
      expect(controller.hasData, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.pageSize, 2);
      expect(controller.currentPageKey, 1);
      expect(controller.currentFirstPageKey, 1);
      expect(controller.enabled, isTrue);
      expect(controller.reloadKey, isNull);
      expect(controller.error, isNull);
      controller.dispose();
    });

    test('setReloadKey without reset refreshes behind REFRESHING data', () async {
      var round = 1;
      final controller = PageableController<int, String>(
        fetchPage: (_) async => round == 1 ? ['a', 'b'] : ['c', 'd'],
        getFirstPageKey: 1,
        pageSize: 2,
        reloadKey: 'v1',
        showLog: false,
      );
      await controller.fetchFirstPage();
      round = 2;
      await controller.setReloadKey('v2');
      expect(controller.items, ['c', 'd']);
      expect(controller.status, PageableStatus.LOADED_PAGE);
      controller.dispose();
    });

    test('setEnabled(true) loads when parked empty', () async {
      final controller = makeController(
        fetch: (_) async => ['a'],
      );
      await controller.setEnabled(false);
      expect(controller.status, PageableStatus.COMPLETED);
      await controller.setEnabled(true);
      expect(controller.items, ['a']);
      controller.dispose();
    });

    test('polling refreshes on interval until stopped', () async {
      var calls = 0;
      final controller = makeController(
        fetch: (_) async {
          calls += 1;
          return ['a', 'b'];
        },
        getNextPageKey: (key, items, total) => key + 1,
        pollInterval: const Duration(milliseconds: 50),
      );
      controller.startPolling();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(calls, greaterThanOrEqualTo(2));
      controller.stopPolling();
      final seen = calls;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(calls, seen);
      controller.dispose();
    });

    test('polling pauses in background and resumes in foreground', () async {
      var calls = 0;
      final controller = makeController(
        fetch: (_) async {
          calls += 1;
          return ['a'];
        },
        pollInterval: const Duration(milliseconds: 50),
        pausePollingWhenHidden: true,
      );
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      controller.startPolling();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(calls, 0);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(calls, greaterThan(0));
      controller.dispose();
    });
  });
}