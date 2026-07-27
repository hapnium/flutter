import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';
import 'package:chime/src/chime_controller.dart';

void main() {
  group('ChimeConfiguration', () {
    test('constructs with defaults', () {
      const config = ChimeConfiguration();

      expect(config.controller, isNull);
      expect(config.eventListeners, isEmpty);
      expect(config.inAppNotification, isNull);
      expect(config.pushNotification, isNull);
    });

    test('constructs with all fields', () {
      final controller = DefaultChimeController();
      final listener = _TestListener();
      final inApp = _TestInAppNotification();
      final push = _TestPushNotification();

      final config = ChimeConfiguration(
        controller: controller,
        eventListeners: [listener],
        inAppNotification: inApp,
        pushNotification: push,
      );

      expect(config.controller, controller);
      expect(config.eventListeners, [listener]);
      expect(config.inAppNotification, inApp);
      expect(config.pushNotification, push);
    });
  });

  group('InAppConfiguration', () {
    test('constructs with defaults', () {
      final config = InAppConfiguration();

      expect(config.alignment, AlignmentDirectional.topEnd);
      expect(config.itemWidth, 400.0);
      expect(config.clipBehavior, Clip.none);
      expect(config.animationDuration, const Duration(milliseconds: 600));
      expect(config.animationBuilder, isNull);
      expect(config.marginBuilder, isNull);
      expect(config.applyMediaQueryViewInsets, isTrue);
    });

    test('constructs with custom values', () {
      final config = InAppConfiguration(
        alignment: Alignment.bottomCenter,
        itemWidth: 300,
        clipBehavior: Clip.hardEdge,
        animationDuration: const Duration(milliseconds: 400),
        applyMediaQueryViewInsets: false,
      );

      expect(config.alignment, Alignment.bottomCenter);
      expect(config.itemWidth, 300);
      expect(config.clipBehavior, Clip.hardEdge);
      expect(config.animationDuration, const Duration(milliseconds: 400));
      expect(config.applyMediaQueryViewInsets, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = InAppConfiguration(
        alignment: Alignment.topLeft,
        itemWidth: 500,
      );

      final copied = original.copyWith(itemWidth: 250);

      expect(copied.alignment, Alignment.topLeft);
      expect(copied.itemWidth, 250);
      expect(copied.clipBehavior, original.clipBehavior);
      expect(copied.animationDuration, original.animationDuration);
    });

    test('copyWith replaces specified fields', () {
      final original = InAppConfiguration();
      final copied = original.copyWith(
        alignment: Alignment.bottomLeft,
        animationDuration: const Duration(seconds: 2),
      );

      expect(copied.alignment, Alignment.bottomLeft);
      expect(copied.animationDuration, const Duration(seconds: 2));
      expect(copied.itemWidth, original.itemWidth);
    });

    test('copyWith returns new instance', () {
      final original = InAppConfiguration();
      final copied = original.copyWith();
      expect(identical(original, copied), isFalse);
    });
  });
}

class _TestListener extends ChimeEventListener<ChimeEvent> {
  @override
  Future<void> onChimeEvent(ChimeEvent event) async {}
}

class _TestInAppNotification implements ChimeInAppNotification {
  @override
  Future<void> showInAppSuccessNotification({
    String title = "Success notification",
    required String message,
    int duration = 5,
    dynamic position,
    dynamic onTapped,
    dynamic onClosed,
    dynamic onCompleted,
    dynamic onDismissed,
  }) async {}

  @override
  Future<void> showInAppErrorNotification({
    String title = "Error notification",
    required String message,
    int duration = 5,
    dynamic position,
    dynamic onTapped,
    dynamic onClosed,
    dynamic onCompleted,
    dynamic onDismissed,
  }) async {}

  @override
  Future<void> showInAppInfoNotification({
    String title = "For your information,",
    required String message,
    int duration = 5,
    dynamic position,
    dynamic onTapped,
    dynamic onClosed,
    dynamic onCompleted,
    dynamic onDismissed,
  }) async {}

  @override
  Future<void> showInAppWarningNotification({
    String title = "Important!",
    required String message,
    int duration = 5,
    dynamic position,
    dynamic onTapped,
    dynamic onClosed,
    dynamic onCompleted,
    dynamic onDismissed,
  }) async {}

  @override
  Future<void> showInAppNotification({dynamic color, required String message, int duration = 5, dynamic textColor}) async {}

  @override
  Future<void> showInAppCustomNotification({
    int duration = 5,
    required dynamic contentBuilder,
    dynamic position,
    dynamic onTapped,
    dynamic onClosed,
    dynamic onCompleted,
    dynamic onDismissed,
  }) async {}

  @override
  Future<void> dismissInAppNotification({required String id}) async {}
}

class _TestPushNotification implements ChimePushNotification {
  @override
  Future<bool> requestPermission() async => true;

  @override
  ChimePlatform getPlatform() => ChimePlatform.ANDROID;

  @override
  String getApplicationName() => 'TestApp';

  @override
  Future<bool> get isPermitted async => true;

  @override
  Future<void> initialize({required dynamic initializationSettings, dynamic onNotificationTapped, dynamic onBackgroundNotificationReceived}) async {}

  @override
  Future<void> onAppLaunchedByNotification(dynamic callback) async {}
}