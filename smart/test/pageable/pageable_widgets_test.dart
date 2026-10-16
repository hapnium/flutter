import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';
import 'package:smart/src/ui/pageable/helpers/pageable_helper.dart';

PageableController<int, String> makeController({
  required Future<List<String>> Function(int page) fetch,
  int pageSize = 2,
}) {
  return PageableController<int, String>(
    fetchPage: (page) => fetch(page),
    getFirstPageKey: 1,
    getNextPageKey: (key, items, total) => items.isEmpty ? null : key + 1,
    pageSize: pageSize,
    showLog: false,
  );
}

PageableBuilderDelegate<String> makeDelegate() {
  return PageableBuilderDelegate<String>(
    itemBuilder: (context, metadata) => Text(metadata.item, textDirection: TextDirection.ltr),
  );
}

Widget wrap(PageableController<int, String> controller) {
  return MaterialApp(
    home: Scaffold(
      body: PageableListView.builder(
        controller: controller,
        builderDelegate: makeDelegate(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageableController.fromPages', () {
    testWidgets('initializes state after the first frame', (tester) async {
      final controller = PageableController<int, String>.fromPages(
        pages: const [PageResult(pageKey: 1, items: ['a', 'b'])],
        fetchPage: (_) async => [],
        getFirstPageKey: 1,
        nextPageKey: 2,
        prevPageKey: 0,
        pageSize: 2,
        showLog: false,
      );
      await tester.pumpWidget(Container());
      await tester.pump();
      expect(controller.items, ['a', 'b']);
      expect(controller.status, PageableStatus.LOADED_PAGE);
      expect(controller.pageable.nextPageKey, 2);
      expect(controller.pageable.prevPageKey, 0);
      controller.dispose();
    });
  });

  group('PageableListView.builder', () {
    testWidgets('renders items once the first page loads', (tester) async {
      final controller = makeController(
        fetch: (_) async => ['alpha', 'beta'],
      );
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();
      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);
      expect(controller.status, PageableStatus.LOADED_PAGE);
      controller.dispose();
    });

    testWidgets('renders the empty state when no items load', (tester) async {
      final controller = makeController(fetch: (_) async => []);
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();
      expect(find.text('No items found'), findsOneWidget);
      expect(controller.status, PageableStatus.NO_ITEMS_FOUND);
      controller.dispose();
    });

    testWidgets('renders the error state when the first page fails', (tester) async {
      final controller = makeController(
        fetch: (_) async => throw Exception('nope'),
      );
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(controller.status, PageableStatus.FIRST_PAGE_ERROR);
      controller.dispose();
    });

    testWidgets('retry button recovers from a first-page error', (tester) async {
      var fail = true;
      final controller = makeController(
        fetch: (_) async {
          if (fail) throw Exception('nope');
          return ['recovered'];
        },
      );
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('recovered'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows a loading indicator while the next page loads', (tester) async {
      final gate = Completer<List<String>>();
      final controller = makeController(
        fetch: (page) => page == 1 ? Future.value(['a', 'b']) : gate.future,
      );
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);

      await controller.fetchNextPage();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(controller.status, PageableStatus.LOADING_NEW_PAGE);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      gate.complete(['c']);
      await tester.pumpAndSettle();
      expect(find.text('c'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows an inline error when the next page fails', (tester) async {
      final controller = makeController(
        fetch: (page) async {
          if (page == 1) return ['a', 'b'];
          throw Exception('next');
        },
      );
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();

      await controller.fetchNextPage();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(controller.status, PageableStatus.NEW_PAGE_ERROR);
      expect(find.text('Something went wrong. Tap to try again.'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      controller.dispose();
    });
  });

  group('PageableBuilderDelegate', () {
    test('rejects percentage thresholds outside 0-100', () {
      expect(
        () => PageableBuilderDelegate<String>(
          itemBuilder: (context, metadata) => const SizedBox(),
          percentageThreshold: 101,
        ),
        throwsAssertionError,
      );
    });

    test('accepts custom previous-page builders', () {
      const delegate = PageableBuilderDelegate<String>(
        itemBuilder: _stubItemBuilder,
        previousPageProgressIndicatorBuilder: _stubBuilder,
        previousPageErrorIndicatorBuilder: _stubBuilder,
      );
      expect(delegate.previousPageProgressIndicatorBuilder, isNotNull);
      expect(delegate.previousPageErrorIndicatorBuilder, isNotNull);
    });
  });

  group('PageableHelper.calculateTotalSeparators', () {
    testWidgets('counts separators with content', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));
      final count = PageableHelper.calculateTotalSeparators(
        (index) => index.isOdd,
        (context, index) => const SizedBox(width: 10, height: 10),
        context,
        6,
      );
      expect(count, 3);
    });

    testWidgets('skips separators without content', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));
      final count = PageableHelper.calculateTotalSeparators(
        (index) => true,
        (context, index) => const SizedBox.shrink(),
        context,
        6,
      );
      expect(count, 0);
    });

    testWidgets('returns zero without a separator builder', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));
      expect(PageableHelper.calculateTotalSeparators((index) => true, null, context, 6), 0);
    });
  });
}

Widget _stubBuilder(BuildContext context) => const SizedBox();

Widget _stubItemBuilder(BuildContext context, ItemMetadata<String> metadata) => const SizedBox();
