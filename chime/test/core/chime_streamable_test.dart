import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late _TestChimeStreamable streamable;

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  setUp(() {
    streamable = _TestChimeStreamable();
  });

  tearDown(() async {
    await streamable.dispose();
  });

  group('ChimeStreamable', () {
    test('getReceivedChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getReceivedChimeNotificationStream();
      expect(stream, isA<Stream<ChimeNotification>>());
    });

    test('getCreatedChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getCreatedChimeNotificationStream();
      expect(stream, isA<Stream<ChimeCreatedNotification>>());
    });

    test('getScheduledChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getScheduledChimeNotificationStream();
      expect(stream, isA<Stream<ChimeScheduledNotification>>());
    });

    test('getTappedChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getTappedChimeNotificationStream();
      expect(stream, isA<Stream<ChimeNotification>>());
    });

    test('getClosedChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getClosedChimeNotificationStream();
      expect(stream, isA<Stream<ChimeNotification>>());
    });

    test('getDismissedChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getDismissedChimeNotificationStream();
      expect(stream, isA<Stream<ChimeNotification>>());
    });

    test('getFailedChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getFailedChimeNotificationStream();
      expect(stream, isA<Stream<ChimeNotification>>());
    });

    test('getLaunchedAppChimeNotificationStream returns broadcast stream', () {
      final stream = streamable.getLaunchedAppChimeNotificationStream();
      expect(stream, isA<Stream<ChimeNotification>>());
    });

    test('hasReceivedNotificationListener returns false when no listener', () {
      expect(streamable.hasReceivedNotificationListener(), isFalse);
    });

    test('hasReceivedNotificationListener returns true with listener', () {
      streamable.getReceivedChimeNotificationStream().listen((_) {});
      expect(streamable.hasReceivedNotificationListener(), isTrue);
    });

    test('hasCreatedNotificationListener returns false when no listener', () {
      expect(streamable.hasCreatedNotificationListener(), isFalse);
    });

    test('hasTappedNotificationListener returns false when no listener', () {
      expect(streamable.hasTappedNotificationListener(), isFalse);
    });

    test('hasClosedNotificationListener returns false when no listener', () {
      expect(streamable.hasClosedNotificationListener(), isFalse);
    });

    test('hasDismissedNotificationListener returns false when no listener', () {
      expect(streamable.hasDismissedNotificationListener(), isFalse);
    });

    test('hasFailedNotificationListener returns false when no listener', () {
      expect(streamable.hasFailedNotificationListener(), isFalse);
    });

    test('hasLaunchedAppNotificationListener returns false when no listener', () {
      expect(streamable.hasLaunchedAppNotificationListener(), isFalse);
    });

    test('hasScheduledNotificationListener returns false when no listener', () {
      expect(streamable.hasScheduledNotificationListener(), isFalse);
    });

    test('emitReceivedNotification delivers to listener', () async {
      final notification = _createNotification();
      final received = <ChimeNotification>[];

      streamable.getReceivedChimeNotificationStream().listen(received.add);
      streamable.emitReceivedNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitReceivedNotification does nothing without listener', () {
      final notification = _createNotification();
      streamable.emitReceivedNotification(notification);
    });

    test('emitCreatedNotification delivers to listener', () async {
      final notification = _createCreatedNotification();
      final received = <ChimeCreatedNotification>[];

      streamable.getCreatedChimeNotificationStream().listen(received.add);
      streamable.emitCreatedNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitTappedNotification delivers to listener', () async {
      final notification = _createNotification();
      final received = <ChimeNotification>[];

      streamable.getTappedChimeNotificationStream().listen(received.add);
      streamable.emitTappedNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitClosedNotification delivers to listener', () async {
      final notification = _createNotification();
      final received = <ChimeNotification>[];

      streamable.getClosedChimeNotificationStream().listen(received.add);
      streamable.emitClosedNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitDismissedNotification delivers to listener', () async {
      final notification = _createNotification();
      final received = <ChimeNotification>[];

      streamable.getDismissedChimeNotificationStream().listen(received.add);
      streamable.emitDismissedNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitFailedNotification delivers to listener', () async {
      final notification = _createNotification();
      final received = <ChimeNotification>[];

      streamable.getFailedChimeNotificationStream().listen(received.add);
      streamable.emitFailedNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitLaunchedAppNotification delivers to listener', () async {
      final notification = _createNotification();
      final received = <ChimeNotification>[];

      streamable.getLaunchedAppChimeNotificationStream().listen(received.add);
      streamable.emitLaunchedAppNotification(notification);

      await Future.delayed(Duration.zero);
      expect(received, [notification]);
    });

    test('emitScheduledNotification delivers to scheduled and created streams', () async {
      final notification = _createScheduledNotification();
      final scheduledReceived = <ChimeScheduledNotification>[];
      final createdReceived = <ChimeCreatedNotification>[];

      streamable.getScheduledChimeNotificationStream().listen(scheduledReceived.add);
      streamable.getCreatedChimeNotificationStream().listen(createdReceived.add);
      streamable.emitScheduledNotification(notification);

      await Future.delayed(Duration.zero);
      expect(scheduledReceived, [notification]);
      expect(createdReceived, [notification]);
    });

    test('dispose closes all controllers', () async {
      final streamable2 = _TestChimeStreamable();
      await streamable2.dispose();

      expect(() => streamable2.emitReceivedNotification(_createNotification()), returnsNormally);
    });
  });
}

ChimeNotification _createNotification() {
  return ChimeNotification(
    id: 1,
    action: 'test',
    input: null,
    payload: null,
    identifier: 'test:1',
  );
}

ChimeCreatedNotification _createCreatedNotification() {
  return ChimeCreatedNotification(
    id: 2,
    identifier: 'created:1',
    title: 'Test',
    body: 'Body',
  );
}

ChimeScheduledNotification _createScheduledNotification() {
  return ChimeScheduledNotification(
    id: 3,
    identifier: 'scheduled:1',
    title: 'Scheduled',
    body: 'Body',
    scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails('test', 'Test'),
    ),
  );
}

class _TestChimeStreamable extends ChimeStreamable {}