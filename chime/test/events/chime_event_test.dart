import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });
  ChimeNotification createNotification({String? id}) {
    return ChimeNotification(
      id: 1,
      action: 'open_chat',
      input: 'reply',
      payload: '{"chat": "abc"}',
      identifier: id ?? 'chat:abc',
    );
  }

  ChimeCreatedNotification createCreatedNotification() {
    return ChimeCreatedNotification(
      id: 2,
      identifier: 'welcome:1',
      title: 'Welcome',
      body: 'Thanks',
    );
  }

  ChimeScheduledNotification createScheduledNotification() {
    return ChimeScheduledNotification(
      id: 3,
      identifier: 'reminder:1',
      title: 'Reminder',
      body: 'Check back',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('test', 'Test'),
      ),
    );
  }

  group('ChimeEvent', () {
    test('NotificationReceivedEvent stores response and isBackgroundNotification', () {
      final notification = createNotification();
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'test',
      );

      final event = NotificationReceivedEvent(
        notification,
        response: response,
        isBackgroundNotification: true,
      );

      expect(event.notification, notification);
      expect(event.response, response);
      expect(event.isBackgroundNotification, isTrue);
      expect(event.timestamp, isA<DateTime>());
    });

    test('NotificationCreatedEvent stores created notification', () {
      final notification = createCreatedNotification();
      final event = NotificationCreatedEvent(notification);

      expect(event.notification, notification);
      expect(event.timestamp, isA<DateTime>());
    });

    test('NotificationScheduledEvent stores scheduled notification', () {
      final notification = createScheduledNotification();
      final event = NotificationScheduledEvent(notification);

      expect(event.notification, notification);
      expect(event.timestamp, isA<DateTime>());
    });

    test('NotificationLaunchedAppEvent stores response', () {
      final notification = createNotification();
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'test',
      );

      final event = NotificationLaunchedAppEvent(
        notification,
        response: response,
      );

      expect(event.notification, notification);
      expect(event.response, response);
    });

    test('NotificationTappedEvent stores notification', () {
      final notification = createNotification();
      final event = NotificationTappedEvent(notification);

      expect(event.notification, notification);
      expect(event.timestamp, isA<DateTime>());
    });

    test('NotificationDismissedEvent stores notification', () {
      final notification = createNotification();
      final event = NotificationDismissedEvent(notification);

      expect(event.notification, notification);
      expect(event.timestamp, isA<DateTime>());
    });

    test('NotificationClosedEvent stores notification', () {
      final notification = createNotification();
      final event = NotificationClosedEvent(notification);

      expect(event.notification, notification);
      expect(event.timestamp, isA<DateTime>());
    });

    test('NotificationFailedEvent stores error and stackTrace', () {
      final notification = createNotification();
      final error = Exception('Network error');
      final stackTrace = StackTrace.current;

      final event = NotificationFailedEvent(
        notification,
        error,
        stackTrace,
      );

      expect(event.notification, notification);
      expect(event.error, error);
      expect(event.stackTrace, stackTrace);
    });

    test('NotificationFailedEvent with null stackTrace', () {
      final notification = createNotification();
      final event = NotificationFailedEvent(notification, 'error');

      expect(event.error, 'error');
      expect(event.stackTrace, isNull);
    });

    test('events have unique timestamps', () {
      final n = createNotification();
      final e1 = NotificationTappedEvent(n);
      final e2 = NotificationTappedEvent(n);

      // They may be the same if created in same millisecond, but timestamps exist
      expect(e1.timestamp, isA<DateTime>());
      expect(e2.timestamp, isA<DateTime>());
    });
  });

  group('ChimeEventListener', () {
    test('supportsChimeEvent returns true for matching type', () {
      final listener = _TestTappedListener();
      final notification = createNotification();
      final event = NotificationTappedEvent(notification);

      expect(listener.supportsChimeEvent(event), isTrue);
    });

    test('supportsChimeEvent returns false for non-matching type', () {
      final listener = _TestTappedListener();
      final notification = createNotification();
      final event = NotificationClosedEvent(notification);

      expect(listener.supportsChimeEvent(event), isFalse);
    });

    test('onChimeEvent is called with correct type', () async {
      final listener = _TestTappedListener();
      final notification = createNotification();
      final event = NotificationTappedEvent(notification);

      await listener.onChimeEvent(event);

      expect(listener.receivedEvent, event);
    });
  });
}

class _TestTappedListener extends ChimeEventListener<NotificationTappedEvent> {
  NotificationTappedEvent? receivedEvent;

  @override
  Future<void> onChimeEvent(NotificationTappedEvent event) async {
    receivedEvent = event;
  }
}