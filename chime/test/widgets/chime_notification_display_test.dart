import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';

void main() {
  Widget buildApp({
    required String message,
    required ChimeInAppState state,
    ChimeNotificationDisplayConfiguration? config,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChimeNotificationDisplay(
          message: message,
          state: state,
          config: config ?? const ChimeNotificationDisplayConfiguration(),
        ),
      ),
    );
  }

  group('ChimeNotificationDisplay', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(buildApp(
        message: 'Hello World',
        state: ChimeInAppState.success,
      ));

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders success state with green icon', (tester) async {
      await tester.pumpWidget(buildApp(
        message: 'Success!',
        state: ChimeInAppState.success,
      ));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders error state with red icon', (tester) async {
      await tester.pumpWidget(buildApp(
        message: 'Error!',
        state: ChimeInAppState.error,
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders warning state with orange icon', (tester) async {
      await tester.pumpWidget(buildApp(
        message: 'Warning!',
        state: ChimeInAppState.warning,
      ));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders info state with blue icon', (tester) async {
      await tester.pumpWidget(buildApp(
        message: 'Info!',
        state: ChimeInAppState.info,
      ));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('applies custom config padding', (tester) async {
      final config = ChimeNotificationDisplayConfiguration(
        padding: const EdgeInsets.all(20),
      );

      await tester.pumpWidget(buildApp(
        message: 'Padded',
        state: ChimeInAppState.success,
        config: config,
      ));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(ChimeNotificationDisplay), matching: find.byType(Container)),
      );
      expect(container.padding, const EdgeInsets.all(20));
    });

    testWidgets('applies custom config margin', (tester) async {
      final config = ChimeNotificationDisplayConfiguration(
        margin: const EdgeInsets.all(10),
      );

      await tester.pumpWidget(buildApp(
        message: 'Margined',
        state: ChimeInAppState.success,
        config: config,
      ));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(ChimeNotificationDisplay), matching: find.byType(Container)),
      );
      expect(container.margin, const EdgeInsets.all(10));
    });

    testWidgets('custom iconBuilder is used', (tester) async {
      final config = ChimeNotificationDisplayConfiguration(
        stateStyles: {
          ChimeInAppState.success: ChimeNotificationDisplayStateStyle(
            color: Colors.green,
            iconBuilder: (context, state, color) => const Icon(Icons.thumb_up),
          ),
        },
      );

      await tester.pumpWidget(buildApp(
        message: 'Custom icon',
        state: ChimeInAppState.success,
        config: config,
      ));

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    });

    testWidgets('custom messageBuilder is used', (tester) async {
      final config = ChimeNotificationDisplayConfiguration(
        messageBuilder: (context, message, textStyle, state) {
          return Text('CUSTOM: $message', style: textStyle);
        },
      );

      await tester.pumpWidget(buildApp(
        message: 'Test msg',
        state: ChimeInAppState.success,
        config: config,
      ));

      expect(find.text('CUSTOM: Test msg'), findsOneWidget);
    });

    testWidgets('custom decorationBuilder is used', (tester) async {
      final config = ChimeNotificationDisplayConfiguration(
        decorationBuilder: (context, stateColor, state) {
          return BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(8),
          );
        },
      );

      await tester.pumpWidget(buildApp(
        message: 'Decorated',
        state: ChimeInAppState.success,
        config: config,
      ));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(ChimeNotificationDisplay), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.purple);
    });

    testWidgets('theme applies light background', (tester) async {
      final config = ChimeNotificationDisplayConfiguration(
        theme: const ChimeNotificationDisplayTheme(
          lightBackgroundColor: Colors.grey,
          darkBackgroundColor: Colors.black87,
          lightTextColor: Colors.black,
          darkTextColor: Colors.white,
        ),
      );

      await tester.pumpWidget(buildApp(
        message: 'Themed',
        state: ChimeInAppState.success,
        config: config,
      ));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(ChimeNotificationDisplay), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey);
    });
  });

  group('ChimeNotificationDisplayStateStyle', () {
    test('copyWith preserves unchanged fields', () {
      final original = ChimeNotificationDisplayStateStyle(
        color: Colors.red,
        icon: Icons.error,
      );

      final copied = original.copyWith(color: Colors.blue);

      expect(copied.color, Colors.blue);
      expect(copied.icon, Icons.error);
    });

    test('copyWith replaces icon', () {
      final original = ChimeNotificationDisplayStateStyle(
        color: Colors.red,
        icon: Icons.error,
      );

      final copied = original.copyWith(icon: Icons.warning);

      expect(copied.icon, Icons.warning);
      expect(copied.color, Colors.red);
    });
  });

  group('ChimeNotificationDisplayTheme', () {
    test('copyWith preserves unchanged fields', () {
      final original = ChimeNotificationDisplayTheme(
        lightBackgroundColor: Colors.white,
        darkBackgroundColor: Colors.black,
        lightTextColor: Colors.black,
        darkTextColor: Colors.white,
      );

      final copied = original.copyWith(lightBackgroundColor: Colors.grey);

      expect(copied.lightBackgroundColor, Colors.grey);
      expect(copied.darkBackgroundColor, Colors.black);
      expect(copied.lightTextColor, Colors.black);
      expect(copied.darkTextColor, Colors.white);
    });
  });

  group('ChimeNotificationDisplayConfiguration', () {
    test('defaults contain all 4 states', () {
      const config = ChimeNotificationDisplayConfiguration();
      expect(config.stateStyles.length, 4);
      expect(config.stateStyles.keys, containsAll(ChimeInAppState.values));
    });

    test('copyWith preserves unchanged fields', () {
      const original = ChimeNotificationDisplayConfiguration(
        iconSize: 24,
        borderWidth: 2,
      );

      final copied = original.copyWith(iconSize: 32);

      expect(copied.iconSize, 32);
      expect(copied.borderWidth, 2);
      expect(copied.margin, original.margin);
    });

    test('copyWith replaces specified fields', () {
      const original = ChimeNotificationDisplayConfiguration();
      final copied = original.copyWith(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(10),
      );

      expect(copied.margin, const EdgeInsets.all(5));
      expect(copied.padding, const EdgeInsets.all(10));
    });
  });
}