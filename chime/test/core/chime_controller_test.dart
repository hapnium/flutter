import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';
import 'package:chime/src/chime_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  late DefaultChimeController controller;

  setUp(() {
    controller = DefaultChimeController();
  });

  tearDown(() async {
    await controller.dispose();
  });

  ChimeNotification notif0({String identifier = 'test:1'}) {
    return ChimeNotification(
      id: 1,
      action: 'open',
      input: 'reply',
      payload: '{"a": 1}',
      identifier: identifier,
    );
  }

  ChimeCreatedNotification createdNotif({String identifier = 'created:1'}) {
    return ChimeCreatedNotification(
      id: 2,
      identifier: identifier,
      title: 'Title',
      body: 'Body',
    );
  }

  group('DefaultChimeController', () {
    group('listener management', () {
      test('addChimeEventListener adds listener', () async {
        final listener = _TestListener();
        await controller.addChimeEventListener(listener);
      });

      test('addChimeEventListener does not add duplicate', () async {
        final listener = _TestListener();
        await controller.addChimeEventListener(listener);
        await controller.addChimeEventListener(listener);
      });

      test('removeChimeEventListener removes listener', () async {
        final listener = _TestListener();
        await controller.addChimeEventListener(listener);
        await controller.removeChimeEventListener(listener);
      });

      test('removeAllChimeEventListeners clears all', () async {
        final l1 = _TestListener();
        final l2 = _TestListener();
        await controller.addChimeEventListener(l1);
        await controller.addChimeEventListener(l2);
        await controller.removeAllChimeEventListeners();
      });

      test('removeChimeEventListeners removes by predicate', () async {
        final l1 = _TappedListener();
        final l2 = _ClosedListener();
        await controller.addChimeEventListener(l1);
        await controller.addChimeEventListener(l2);
        await controller.removeChimeEventListeners(
          (l) => l is _TappedListener,
        );
      });
    });

    group('publishEvent', () {
      test('NotificationTappedEvent emits to tapped stream', () async {
        final notification = notif0();
        final received = <ChimeNotification>[];

        controller.getTappedChimeNotificationStream().listen(received.add);
        await controller.publishEvent(NotificationTappedEvent(notification));

        expect(received, [notification]);
      });

      test('NotificationTappedEvent buffers in tappedNotifications', () async {
        final notification = notif0();
        await controller.publishEvent(NotificationTappedEvent(notification));

        expect(controller.getTappedNotifications(), contains(notification));
      });

      test('NotificationClosedEvent emits to closed stream', () async {
        final notification = notif0();
        final received = <ChimeNotification>[];

        controller.getClosedChimeNotificationStream().listen(received.add);
        await controller.publishEvent(NotificationClosedEvent(notification));

        expect(received, [notification]);
      });

      test('NotificationDismissedEvent emits to dismissed stream', () async {
        final notification = notif0();
        final received = <ChimeNotification>[];

        controller.getDismissedChimeNotificationStream().listen(received.add);
        await controller.publishEvent(NotificationDismissedEvent(notification));

        expect(received, [notification]);
      });

      test('NotificationReceivedEvent emits to received stream', () async {
        final notification = notif0();
        final received = <ChimeNotification>[];

        controller.getReceivedChimeNotificationStream().listen(received.add);
        final response = NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
        );
        await controller.publishEvent(
          NotificationReceivedEvent(notification, response: response),
        );

        expect(received, [notification]);
      });

      test('NotificationCreatedEvent emits to created stream and buffers', () async {
        final notification = createdNotif();
        final received = <ChimeCreatedNotification>[];

        controller.getCreatedChimeNotificationStream().listen(received.add);
        await controller.publishEvent(NotificationCreatedEvent(notification));

        expect(received, [notification]);
        expect(controller.getCreatedNotifications(), contains(notification));
      });

      test('NotificationLaunchedAppEvent emits to launched stream', () async {
        final notification = notif0();
        final received = <ChimeNotification>[];

        controller.getLaunchedAppChimeNotificationStream().listen(received.add);
        final response = NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
        );
        await controller.publishEvent(
          NotificationLaunchedAppEvent(notification, response: response),
        );

        expect(received, [notification]);
      });

      test('NotificationFailedEvent emits to failed stream', () async {
        final notification = notif0();
        final received = <ChimeNotification>[];

        controller.getFailedChimeNotificationStream().listen(received.add);
        await controller.publishEvent(
          NotificationFailedEvent(notification, Exception('error')),
        );

        expect(received, [notification]);
      });

      test('dispatches to matching listeners', () async {
        final listener = _TappedListener();
        await controller.addChimeEventListener(listener);

        final notification = notif0();
        await controller.publishEvent(NotificationTappedEvent(notification));

        expect(listener.receivedEvents, [notification]);
      });

      test('does not dispatch to non-matching listeners', () async {
        final listener = _ClosedListener();
        await controller.addChimeEventListener(listener);

        final notification = notif0();
        await controller.publishEvent(NotificationTappedEvent(notification));

        expect(listener.receivedEvents, isEmpty);
      });

      test('dispatches to multiple matching listeners', () async {
        final l1 = _TappedListener();
        final l2 = _TappedListener();
        await controller.addChimeEventListener(l1);
        await controller.addChimeEventListener(l2);

        final notification = notif0();
        await controller.publishEvent(NotificationTappedEvent(notification));

        expect(l1.receivedEvents, [notification]);
        expect(l2.receivedEvents, [notification]);
      });
    });

    group('notification management', () {
      test('getTappedNotifications returns unmodifiable list', () {
        final list = controller.getTappedNotifications();
        expect(() => list.add(notif0()), throwsA(isA<UnsupportedError>()));
      });

      test('getCreatedNotifications returns unmodifiable list', () {
        final list = controller.getCreatedNotifications();
        expect(() => list.add(createdNotif()), throwsA(isA<UnsupportedError>()));
      });

      test('getCreatedAppNotifications returns unmodifiable list', () {
        final list = controller.getCreatedAppNotifications();
        expect(list, isEmpty);
      });

      test('hasCreatedNotification returns false when empty', () {
        expect(controller.hasCreatedNotification(createdNotif()), isFalse);
      });

      test('hasCreatedNotification returns true when added', () {
        final notif = createdNotif();
        controller.addCreatedNotification(notif);
        expect(controller.hasCreatedNotification(notif), isTrue);
      });

      test('hasCreatedNotification returns true for same identifier', () {
        controller.addCreatedNotification(createdNotif(identifier: 'abc'));
        expect(
          controller.hasCreatedNotification(
            createdNotif(identifier: 'abc'),
          ),
          isTrue,
        );
      });

      test('removeCreatedNotification removes by identifier', () {
        controller.addCreatedNotification(createdNotif(identifier: 'abc'));
        controller.removeCreatedNotification('abc');
        expect(controller.getCreatedNotifications(), isEmpty);
      });

      test('removeTappedNotification removes by identifier', () async {
        final notif = notif0(identifier: 'tap:1');
        await controller.publishEvent(NotificationTappedEvent(notif));
        controller.removeTappedNotification('tap:1');
        expect(controller.getTappedNotifications(), isEmpty);
      });

      test('flushCreatedNotifications emits buffered and clears', () async {
        final notif = createdNotif();
        controller.addCreatedNotification(notif);

        final received = <ChimeCreatedNotification>[];
        controller.getCreatedChimeNotificationStream().listen(received.add);

        controller.flushCreatedNotifications();
        await Future.delayed(Duration.zero);

        expect(received, [notif]);
        expect(controller.getCreatedNotifications(), isEmpty);
      });

      test('flushPendingTappedNotifications emits buffered and clears', () async {
        final notif = notif0();
        controller.addTappedNotification(notif);

        final received = <ChimeNotification>[];
        controller.getTappedChimeNotificationStream().listen(received.add);

        controller.flushPendingTappedNotifications();
        await Future.delayed(Duration.zero);

        expect(received, [notif]);
        expect(controller.getTappedNotifications(), isEmpty);
      });
    });

    group('getCreatedAppNotifications', () {
      test('filters only ChimeCreatedAppNotification instances', () {
        final created = createdNotif(identifier: 'regular');
        controller.addCreatedNotification(created);

        final list = controller.getCreatedAppNotifications();
        expect(list, isEmpty);
      });
    });

    group('dispose', () {
      test('closes all streams', () async {
        await controller.dispose();
        expect(controller.getTappedChimeNotificationStream().isBroadcast, isTrue);
      });
    });
  });
}

class _TestListener extends ChimeEventListener<ChimeEvent> {
  @override
  Future<void> onChimeEvent(ChimeEvent event) async {}
}

class _TappedListener extends ChimeEventListener<NotificationTappedEvent> {
  final List<ChimeNotification> receivedEvents = [];

  @override
  Future<void> onChimeEvent(NotificationTappedEvent event) async {
    receivedEvents.add(event.notification);
  }
}

class _ClosedListener extends ChimeEventListener<NotificationClosedEvent> {
  final List<ChimeNotification> receivedEvents = [];

  @override
  Future<void> onChimeEvent(NotificationClosedEvent event) async {
    receivedEvents.add(event.notification);
  }
}