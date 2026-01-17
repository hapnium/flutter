import 'dart:collection';

import 'package:flutter/foundation.dart' show internal;

import 'chime_notification.dart';
import 'chime_event.dart';
import 'chime_notification_manager.dart';
import 'chime_streamable.dart';

/// {@template chime_controller}
/// Contract for a Chime notification controller.
///
/// A [ChimeController] combines three responsibilities:
/// 1) It is a [ChimeStreamable] source that exposes notification streams.
/// 2) It is a [ChimeEventManager] that routes [ChimeEvent] instances.
/// 3) It is a [ChimeNotificationManager] that buffers and deduplicates state.
///
/// In addition, it defines a consistent API for:
/// - Tracking created notifications to prevent duplicates.
/// - Buffering tapped notifications when no listeners are attached.
/// - Flushing buffered items once a consumer is ready.
///
/// ### Example
/// ```dart
/// final controller = MyChimeController();
///
/// controller.getCreatedChimeNotificationStream().listen((notification) {
///   print('Created: ${notification.id}');
/// });
///
/// await controller.onChimeEvent(
///   NotificationCreatedEvent(
///     ChimeNotification(id: 7, action: 'show', input: '', payload: null),
///   ),
/// );
/// ```
/// {@endtemplate}
abstract class ChimeController extends ChimeStreamable implements ChimeEventManager, ChimeNotificationManager {}

/// {@template default_chime_controller}
/// Default implementation of [ChimeController].
///
/// This controller provides a complete, ready-to-use in-memory event and
/// stream implementation:
/// - Keeps a listener registry for [ChimeEventListener] subscribers.
/// - Buffers created and tapped notifications until a consumer is ready.
/// - Emits notification streams based on the event type.
///
/// It is intended as the base controller for most apps unless you need
/// custom persistence, analytics hooks, or advanced buffering policies.
///
/// ### Example
/// ```dart
/// final controller = DefaultChimeController();
///
/// controller.getTappedChimeNotificationStream().listen((notification) {
///   print('Tapped: ${notification.id}');
/// });
///
/// await controller.onChimeEvent(
///   NotificationTappedEvent(
///     ChimeNotification(id: 42, action: 'open', input: '', payload: null),
///   ),
/// );
/// ```
/// {@endtemplate}
@internal
final class DefaultChimeController extends ChimeController {
  /// Internal collection of event listeners.
  final List<ChimeEventListener> _listeners = [];

  // Internal buffer to store created notifications when no listeners are active.
  final List<ChimeCreatedNotification> _createdNotifications = [];

  // Internal buffer to store tapped notifications when no listeners are active.
  final List<ChimeNotification> _tappedNotifications = [];

  /// {@macro default_chime_controller}
  DefaultChimeController();

  @override
  List<ChimeNotification> getTappedNotifications() => UnmodifiableListView(_tappedNotifications);

  @override
  List<ChimeCreatedNotification> getCreatedNotifications() => UnmodifiableListView(_createdNotifications);

  @override
  List<ChimeAppNotification> getCreatedAppNotifications() {
    final created = <ChimeAppNotification>[];
    for (final notification in _createdNotifications) {
      if (notification is ChimeCreatedAppNotification) {
        created.add(ChimeAppNotification(
          identifier: notification.identifier,
          description: notification.description,
          state: notification.state,
          title: notification.title ?? "",
          item: notification.item,
        ));
      }
    }

    return UnmodifiableListView(created);
  }

  @override
  bool hasCreatedNotification(ChimeCreatedNotification notifier) => _createdNotifications.any((c) {
    return c.identifier == notifier.identifier || c == notifier;
  });

  @override
  void addCreatedNotification(ChimeCreatedNotification notifier) {
    _createdNotifications.add(notifier);
  }

  @override
  void removeCreatedNotification(String identifier) {
    _createdNotifications.removeWhere((n) => n.identifier == identifier);
  }

  @override
  void removeTappedNotification(String identifier) {
    _tappedNotifications.removeWhere((n) => n.identifier == identifier);
  }

  @override
  void flushCreatedNotifications() {
    for (final notifier in _createdNotifications) {
      emitCreatedNotification(notifier);
    }

    _createdNotifications.clear();
  }

  @override
  void flushPendingTappedNotifications() {
    for (final notifier in _tappedNotifications) {
      emitTappedNotification(notifier);
    }

    _tappedNotifications.clear();
  }

  @override
  void addTappedNotification(ChimeNotification notifier) {
    _tappedNotifications.add(notifier);
  }

  @override
  Future<void> addChimeEventListener(ChimeEventListener<ChimeEvent> listener) async {
    if (_listeners.contains(listener)) {
      return;
    }

    _listeners.add(listener);
  }

  @override
  Future<void> publishEvent(ChimeEvent event) async {
    if (_listeners.isNotEmpty) {
      final futures = <Future<void>>[];
      for (final listener in List<ChimeEventListener<ChimeEvent>>.from(_listeners)) {
        if (listener.supportsChimeEvent(event)) {
          futures.add(listener.onChimeEvent(event));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    }

    if (event case NotificationReceivedEvent receivedEvent) {
      emitReceivedNotification(receivedEvent.notification);
    } else if (event case NotificationCreatedEvent createdEvent) {
      final notification = createdEvent.notification as ChimeCreatedNotification;

      emitCreatedNotification(notification);
      _createdNotifications.add(notification);
    } else if (event case NotificationScheduledEvent scheduledEvent) {
      final notification = scheduledEvent.notification as ChimeScheduledNotification;

      emitScheduledNotification(notification);
    } else if (event case NotificationLaunchedAppEvent launchedEvent) {
      emitLaunchedAppNotification(launchedEvent.notification);
    } else if (event case NotificationTappedEvent tappedEvent) {
      emitTappedNotification(tappedEvent.notification);
      _tappedNotifications.add(tappedEvent.notification);
    } else if (event case NotificationClosedEvent closedEvent) {
      emitClosedNotification(closedEvent.notification);
    } else if (event case NotificationDismissedEvent dismissedEvent) {
      emitDismissedNotification(dismissedEvent.notification);
    } else if (event case NotificationFailedEvent failedEvent) {
      emitFailedNotification(failedEvent.notification);
    }
  }

  @override
  Future<void> removeAllChimeEventListeners() async {
    _listeners.clear();
  }

  @override
  Future<void> removeChimeEventListener(ChimeEventListener<ChimeEvent> listener) async {
    _listeners.remove(listener);
  }

  @override
  Future<void> removeChimeEventListeners(bool Function(ChimeEventListener<ChimeEvent>) listener) async {
    _listeners.removeWhere(listener);
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    removeAllChimeEventListeners();
  }
}