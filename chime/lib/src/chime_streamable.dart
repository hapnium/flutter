import 'dart:async';

import 'package:flutter/widgets.dart';

import 'chime_notification.dart';

/// {@template streamable_chime_notification}
/// Stream contract for notification lifecycle updates.
///
/// A [StreamableChimeNotification] exposes read-only streams for each
/// notification stage (received, created, scheduled, tapped, etc). Implementers
/// decide when and how notifications are emitted, while consumers can subscribe
/// to the specific stream that matches their use case.
///
/// This contract is commonly mixed into a controller so callers can observe
/// notification state without directly mutating it.
///
/// ### Example
/// ```dart
/// final streamable = controller;
/// streamable.getTappedChimeNotificationStream().listen((notification) {
///   print('Tapped: ${notification.id}');
/// });
/// ```
/// {@endtemplate}
abstract interface class StreamableChimeNotification {
  /// {@template streamable_chime_notification_received_stream}
  /// Stream of notifications received by the device.
  ///
  /// This fires as soon as a notification payload arrives, before any user
  /// interaction. Use this to update in-app counters or preload data.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getReceivedChimeNotificationStream().listen((notification) {
  ///   print('Received: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeNotification> getReceivedChimeNotificationStream();

  /// {@template streamable_chime_notification_created_stream}
  /// Stream of notifications created by the application.
  ///
  /// This is useful for tracking when a notification has been assembled and
  /// stored, even if it is not shown immediately.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getCreatedChimeNotificationStream().listen((notification) {
  ///   print('Created: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeCreatedNotification> getCreatedChimeNotificationStream();

  /// {@template streamable_chime_notification_scheduled_stream}
  /// Stream of notifications scheduled for future delivery.
  ///
  /// Subscribe to this to update local state or UI when a notification is
  /// queued but not yet displayed.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getScheduledChimeNotificationStream().listen((notification) {
  ///   print('Scheduled: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeScheduledNotification> getScheduledChimeNotificationStream();

  /// {@template streamable_chime_notification_launched_app_stream}
  /// Stream of notifications that launched the application.
  ///
  /// This is emitted when the user taps a notification and the app starts (or
  /// is brought to foreground) as a result.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getLaunchedAppChimeNotificationStream().listen((notification) {
  ///   print('Launched by: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeNotification> getLaunchedAppChimeNotificationStream();

  /// {@template streamable_chime_notification_tapped_stream}
  /// Stream of notifications the user tapped.
  ///
  /// This fires when the user explicitly interacts with a notification while
  /// the app is already running or in the background.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getTappedChimeNotificationStream().listen((notification) {
  ///   print('Tapped: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeNotification> getTappedChimeNotificationStream();

  /// {@template streamable_chime_notification_closed_stream}
  /// Stream of notifications closed by the user or auto-close completion.
  ///
  /// Use this to react when the notification UI is explicitly closed.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getClosedChimeNotificationStream().listen((notification) {
  ///   print('Closed: ${notification.identifier}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeNotification> getClosedChimeNotificationStream();

  /// {@template streamable_chime_notification_dismissed_stream}
  /// Stream of notifications dismissed by the user.
  ///
  /// Subscribe to this to clean up local state or track dismissal analytics.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getDismissedChimeNotificationStream().listen((notification) {
  ///   print('Dismissed: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeNotification> getDismissedChimeNotificationStream();

  /// {@template streamable_chime_notification_failed_stream}
  /// Stream of notifications that failed to schedule, display, or handle.
  ///
  /// This stream emits the notification payload associated with the failure.
  ///
  /// ### Example
  /// ```dart
  /// streamable.getFailedChimeNotificationStream().listen((notification) {
  ///   print('Failed: ${notification.id}');
  /// });
  /// ```
  /// {@endtemplate}
  Stream<ChimeNotification> getFailedChimeNotificationStream();

  /// {@template streamable_chime_notification_dispose}
  /// Releases internal stream resources.
  ///
  /// Implementations should close all stream controllers to avoid memory leaks.
  ///
  /// ### Example
  /// ```dart
  /// await streamable.dispose();
  /// ```
  /// {@endtemplate}
  Future<void> dispose();
}

/// {@template chime_streamable}
/// Base implementation for [StreamableChimeNotification].
///
/// This class owns the internal broadcast controllers and provides helper
/// methods to:
/// - check if any listeners are attached
/// - emit notifications only when there is a consumer
///
/// Extend this class in a controller and call the `emit*` methods as part of
/// your event routing or buffering logic.
///
/// ### Example
/// ```dart
/// class MyController extends ChimeStreamable {
///   void handleTap(ChimeNotification notification) {
///     emitTappedNotification(notification);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class ChimeStreamable implements StreamableChimeNotification {
  final StreamController<ChimeNotification> _receivedController = StreamController.broadcast();
  final StreamController<ChimeCreatedNotification> _createdController = StreamController.broadcast();
  final StreamController<ChimeScheduledNotification> _scheduledController = StreamController.broadcast();
  final StreamController<ChimeNotification> _launchedAppController = StreamController.broadcast();
  final StreamController<ChimeNotification> _tappedController = StreamController.broadcast();
  final StreamController<ChimeNotification> _closedController = StreamController.broadcast();
  final StreamController<ChimeNotification> _dismissedController = StreamController.broadcast();
  final StreamController<ChimeNotification> _failedController = StreamController.broadcast();

  @override
  Stream<ChimeNotification> getReceivedChimeNotificationStream() => _receivedController.stream;

  @override
  Stream<ChimeCreatedNotification> getCreatedChimeNotificationStream() => _createdController.stream;

  @override
  Stream<ChimeScheduledNotification> getScheduledChimeNotificationStream() => _scheduledController.stream;

  @override
  Stream<ChimeNotification> getLaunchedAppChimeNotificationStream() => _launchedAppController.stream;

  @override
  Stream<ChimeNotification> getTappedChimeNotificationStream() => _tappedController.stream;

  @override
  Stream<ChimeNotification> getClosedChimeNotificationStream() => _closedController.stream;

  @override
  Stream<ChimeNotification> getDismissedChimeNotificationStream() => _dismissedController.stream;

  @override
  Stream<ChimeNotification> getFailedChimeNotificationStream() => _failedController.stream;

  /// {@template chime_streamable_has_received_listener}
  /// Whether there is an active listener for received notifications.
  ///
  /// Use this to decide whether to emit or buffer incoming notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasReceivedNotificationListener()) {
  ///   emitReceivedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasReceivedNotificationListener() => _receivedController.hasListener;

  /// {@template chime_streamable_has_created_listener}
  /// Whether there is an active listener for created notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasCreatedNotificationListener()) {
  ///   emitCreatedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasCreatedNotificationListener() => _createdController.hasListener;

  /// {@template chime_streamable_has_scheduled_listener}
  /// Whether there is an active listener for scheduled notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasScheduledNotificationListener()) {
  ///   emitScheduledNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasScheduledNotificationListener() => _scheduledController.hasListener;

  /// {@template chime_streamable_has_launched_app_listener}
  /// Whether there is an active listener for launch-from-notification events.
  ///
  /// ### Example
  /// ```dart
  /// if (hasLaunchedAppNotificationListener()) {
  ///   emitLaunchedAppNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasLaunchedAppNotificationListener() => _launchedAppController.hasListener;

  /// {@template chime_streamable_has_tapped_listener}
  /// Whether there is an active listener for tapped notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasTappedNotificationListener()) {
  ///   emitTappedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasTappedNotificationListener() => _tappedController.hasListener;

  /// {@template chime_streamable_has_closed_listener}
  /// Whether there is an active listener for closed notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasClosedNotificationListener()) {
  ///   emitClosedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasClosedNotificationListener() => _closedController.hasListener;

  /// {@template chime_streamable_has_dismissed_listener}
  /// Whether there is an active listener for dismissed notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasDismissedNotificationListener()) {
  ///   emitDismissedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasDismissedNotificationListener() => _dismissedController.hasListener;

  /// {@template chime_streamable_has_failed_listener}
  /// Whether there is an active listener for failed notifications.
  ///
  /// ### Example
  /// ```dart
  /// if (hasFailedNotificationListener()) {
  ///   emitFailedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasFailedNotificationListener() => _failedController.hasListener;

  /// {@template chime_streamable_emit_received}
  /// Emits a received notification to the stream if a listener exists.
  ///
  /// This avoids unnecessary work when nobody is subscribed.
  ///
  /// ### Example
  /// ```dart
  /// emitReceivedNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitReceivedNotification(ChimeNotification notification) {
    if (hasReceivedNotificationListener()) {
      _receivedController.add(notification);
    }
  }

  /// {@template chime_streamable_emit_created}
  /// Emits a created notification to the stream if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitCreatedNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitCreatedNotification(ChimeCreatedNotification notification) {
    if (hasCreatedNotificationListener()) {
      _createdController.add(notification);
    }
  }

  /// {@template chime_streamable_emit_scheduled}
  /// Emits a scheduled notification to the stream if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitScheduledNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitScheduledNotification(ChimeScheduledNotification notification) {
    if (hasScheduledNotificationListener()) {
      _scheduledController.add(notification);
    }

    emitCreatedNotification(notification);
  }

  /// {@template chime_streamable_emit_launched_app}
  /// Emits a launch-by-notification event if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitLaunchedAppNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitLaunchedAppNotification(ChimeNotification notification) {
    if (hasLaunchedAppNotificationListener()) {
      _launchedAppController.add(notification);
    }
  }

  /// {@template chime_streamable_emit_tapped}
  /// Emits a tapped notification if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitTappedNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitTappedNotification(ChimeNotification notification) {
    if (hasTappedNotificationListener()) {
      _tappedController.add(notification);
    }
  }

  /// {@template chime_streamable_emit_closed}
  /// Emits a closed notification if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitClosedNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitClosedNotification(ChimeNotification notification) {
    if (hasClosedNotificationListener()) {
      _closedController.add(notification);
    }
  }

  /// {@template chime_streamable_emit_dismissed}
  /// Emits a dismissed notification if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitDismissedNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitDismissedNotification(ChimeNotification notification) {
    if (hasDismissedNotificationListener()) {
      _dismissedController.add(notification);
    }
  }

  /// {@template chime_streamable_emit_failed}
  /// Emits a failed notification if a listener exists.
  ///
  /// ### Example
  /// ```dart
  /// emitFailedNotification(notification);
  /// ```
  /// {@endtemplate}
  void emitFailedNotification(ChimeNotification notification) {
    if (hasFailedNotificationListener()) {
      _failedController.add(notification);
    }
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await Future.wait([
      _receivedController.close(),
      _createdController.close(),
      _scheduledController.close(),
      _launchedAppController.close(),
      _tappedController.close(),
      _closedController.close(),
      _dismissedController.close(),
      _failedController.close(),
    ]);
  }
}