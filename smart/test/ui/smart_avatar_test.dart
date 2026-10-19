import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/ui/avatar/smart_avatar.dart';

void main() {
  Future<void> pumpAvatar(WidgetTester tester, Widget avatar) async {
    await tester.pumpWidget(MaterialApp(home: Center(child: avatar)));
  }

  /// The offset between the initials' center and the avatar's center.
  /// With correct centering this is (0, 0) — the regression that motivated
  /// this suite pushed the initials below center by ~3px (a hard-coded
  /// `EdgeInsets.only(top: 6)`), and font-metric padding shifted them
  /// further as the text size changed.
  Offset centerDelta(WidgetTester tester, String initials, Finder avatar) {
    return tester.getCenter(find.text(initials)) - tester.getCenter(avatar);
  }

  void expectCentered(Offset delta, {required String reason}) {
    expect(delta.dx, closeTo(0, 0.51), reason: reason);
    expect(delta.dy, closeTo(0, 0.51), reason: reason);
  }

  group('SmartAvatar initials centering', () {
    testWidgets('stays centered at every text size', (tester) async {
      for (final size in [10.0, 14.0, 22.0, 32.0, 48.0]) {
        await pumpAvatar(
          tester,
          SmartAvatar(radius: 32, fullName: 'Jane Doe', textSize: size),
        );

        expectCentered(
          centerDelta(tester, 'JD', find.byType(CircleAvatar)),
          reason: 'initials must be centered at textSize=$size',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('stays centered at every avatar size', (tester) async {
      for (final radius in [12.0, 16.0, 24.0, 40.0, 64.0]) {
        await pumpAvatar(
          tester,
          SmartAvatar(radius: radius, fullName: 'Jane Doe', textSize: 18),
        );

        expectCentered(
          centerDelta(tester, 'JD', find.byType(CircleAvatar)),
          reason: 'initials must be centered at radius=$radius',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('stays centered for square avatars at every text size', (tester) async {
      for (final size in [10.0, 14.0, 28.0]) {
        await pumpAvatar(
          tester,
          SmartAvatar.square(radius: 32, fullName: 'Jane Doe', textSize: size),
        );

        expectCentered(
          centerDelta(tester, 'JD', find.byType(SmartAvatar)),
          reason: 'square initials must be centered at textSize=$size',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('single-letter initials stay centered', (tester) async {
      for (final size in [12.0, 20.0, 36.0]) {
        await pumpAvatar(
          tester,
          SmartAvatar(radius: 28, fullName: 'Plato', textSize: size),
        );

        expectCentered(
          centerDelta(tester, 'P', find.byType(CircleAvatar)),
          reason: 'single-letter initials must be centered at textSize=$size',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('an explicit padding is still honored', (tester) async {
      await pumpAvatar(
        tester,
        SmartAvatar(
          radius: 32,
          fullName: 'Jane Doe',
          textSize: 16,
          padding: const EdgeInsets.only(top: 8),
        ),
      );

      final delta = centerDelta(tester, 'JD', find.byType(CircleAvatar));
      expect(delta.dy, greaterThan(0), reason: 'explicit top padding must shift the initials down');
    });

    testWidgets('fallback icon renders when no name is provided', (tester) async {
      await pumpAvatar(tester, SmartAvatar(radius: 24));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}