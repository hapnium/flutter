import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';
import 'package:chime/src/chime_controller.dart';

void main() {
  setUp(() {
    Chime.showLogs = false;
    Chime.setController(DefaultChimeController());
  });

  group('Chime', () {
    group('controller', () {
      test('getController returns default when not set', () {
        final controller = Chime.getController();
        expect(controller, isA<ChimeController>());
      });

      test('setController stores controller', () {
        final controller = DefaultChimeController();
        Chime.setController(controller);
        expect(Chime.getController(), controller);
      });
    });

    group('logging', () {
      test('setShowLogs updates showLogs', () {
        Chime.setShowLogs(true);
        expect(Chime.showLogs, isTrue);

        Chime.setShowLogs(false);
        expect(Chime.showLogs, isFalse);
      });
    });

    group('applicationName and platform', () {
      test('setApplicationName is reflected in getPushNotification default', () {
        Chime.setApplicationName('TestApp');
        final push = Chime.getPushNotification();
        expect(push.getApplicationName(), 'TestApp');
      });

      test('setPlatform is reflected in getPushNotification default', () {
        Chime.setPlatform(ChimePlatform.IOS);
        final push = Chime.getPushNotification();
        expect(push.getPlatform(), ChimePlatform.IOS);
      });
    });

    group('inAppNotification', () {
      test('getInAppNotification returns default when not set', () {
        final inApp = Chime.getInAppNotification();
        expect(inApp, isA<ChimeInAppNotification>());
      });

      test('setChimeInAppNotification stores handler', () {
        final handler = _TestInAppNotification();
        Chime.setChimeInAppNotification(handler);
        expect(Chime.getInAppNotification(), handler);
      });
    });

    group('pushNotification', () {
      test('getPushNotification returns default when not set', () {
        final push = Chime.getPushNotification();
        expect(push, isA<ChimePushNotification>());
      });

      test('setChimePushNotification stores handler', () {
        final handler = _TestPushNotification();
        Chime.setChimePushNotification(handler);
        expect(Chime.getPushNotification(), handler);
      });
    });

    test('mixable returns ChimeMixin instance', () {
      expect(Chime.mixable, isA<ChimeMixin>());
    });
  });
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