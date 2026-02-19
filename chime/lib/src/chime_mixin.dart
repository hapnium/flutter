import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show FlutterLocalNotificationsPlugin, ActiveNotification;
import 'package:toastification/toastification.dart' show ToastificationBuilder;

import '../chime.dart';

/// {@template chime_mixin}
/// Convenience mixin for accessing Chime controller capabilities.
///
/// Use this mixin when you want simple access to Chime streams, event routing,
/// and notification management from any class. It lets you call the Chime
/// APIs directly on the host class without manual plumbing.
///
/// The mixin forwards all calls to the [chimeController] getter and provides
/// quick dismissal helpers via the local notifications plugin.
///
/// This is ideal for services, repositories, or view models that need to:
/// - subscribe to notification streams
/// - dispatch or observe events
/// - clear notifications by id, group, or channel
///
/// ### Example
/// ```dart
/// class InboxService with ChimeMixin {
///   InboxService(this._controller);
///
///   final ChimeController _controller;
///
///   @override
///   ChimeController get chimeController => _controller;
///
///   @override
///   bool get showChimeLogs => true;
///
///   void listenForTaps() {
///     getTappedChimeNotificationStream().listen((notification) {
///       // Navigate or mark as read.
///     });
///   }
/// }
/// ```
/// {@endtemplate}
mixin ChimeMixin implements ChimeNotificationManager, ChimeStreamable, ChimeEventManager {
  /// {@template chime_mixin_controller}
  /// The backing controller that performs all delegated work.
  ///
  /// Implementers must provide a concrete [ChimeController] instance.
  /// All mixin methods forward directly to this controller, so lifecycle and
  /// configuration are owned by the host class.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// ChimeController get chimeController => _controller;
  /// ```
  /// {@endtemplate}
  ChimeController get chimeController => Chime.getController();

  /// {@template chime_mixin_show_logs}
  /// Whether to emit Chime logs for debugging.
  ///
  /// Use this to toggle verbose behavior in implementations that read
  /// this flag to log events or state transitions. The mixin does not
  /// log by itself, but downstream code can check this getter.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// bool get showChimeLogs => const bool.fromEnvironment('CHIME_LOGS');
  /// ```
  /// {@endtemplate}
  bool get showChimeLogs => Chime.showLogs;

  /// {@template chime_mixin_plugin}
  /// The local notifications plugin used for dismissal operations.
  ///
  /// Override this getter if you need a shared instance or custom configuration,
  /// such as injecting a pre-initialized plugin.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// FlutterLocalNotificationsPlugin get plugin => _sharedPlugin;
  /// ```
  /// {@endtemplate}
  FlutterLocalNotificationsPlugin get plugin => FlutterLocalNotificationsPlugin();

  @override
  Future<void> addChimeEventListener(ChimeEventListener<ChimeEvent> listener)
    => chimeController.addChimeEventListener(listener);

  @override
  void addCreatedNotification(ChimeCreatedNotification notifier)
    => chimeController.addCreatedNotification(notifier);

  @override
  void addTappedNotification(ChimeNotification notifier)
    => chimeController.addTappedNotification(notifier);

  @override
  Future<void> dispose()
    => chimeController.dispose();

  @override
  void emitCreatedNotification(ChimeCreatedNotification notification)
    => chimeController.emitCreatedNotification(notification);

  @override
  void emitLaunchedAppNotification(ChimeNotification notification)
    => chimeController.emitLaunchedAppNotification(notification);

  @override
  void emitReceivedNotification(ChimeNotification notification)
    => chimeController.emitReceivedNotification(notification);

  @override
  void emitScheduledNotification(ChimeScheduledNotification notification)
    => chimeController.emitScheduledNotification(notification);

  @override
  void emitTappedNotification(ChimeNotification notification)
    => chimeController.emitTappedNotification(notification);

  @override
  void emitClosedNotification(ChimeNotification notification)
    => chimeController.emitClosedNotification(notification);

  @override
  void emitDismissedNotification(ChimeNotification notification)
    => chimeController.emitDismissedNotification(notification);

  @override
  void emitFailedNotification(ChimeNotification notification)
    => chimeController.emitFailedNotification(notification);

  @override
  void flushCreatedNotifications()
    => chimeController.flushCreatedNotifications();

  @override
  void flushPendingTappedNotifications()
    => chimeController.flushPendingTappedNotifications();

  @override
  Stream<ChimeCreatedNotification> getCreatedChimeNotificationStream()
    => chimeController.getCreatedChimeNotificationStream();

  @override
  List<ChimeCreatedNotification> getCreatedNotifications()
    => chimeController.getCreatedNotifications();

  @override
  List<ChimeAppNotification> getCreatedAppNotifications()
    => chimeController.getCreatedAppNotifications();

  @override
  Stream<ChimeNotification> getLaunchedAppChimeNotificationStream()
    => chimeController.getLaunchedAppChimeNotificationStream();

  @override
  Stream<ChimeNotification> getReceivedChimeNotificationStream()
    => chimeController.getReceivedChimeNotificationStream();

  @override
  Stream<ChimeScheduledNotification> getScheduledChimeNotificationStream()
    => chimeController.getScheduledChimeNotificationStream();

  @override
  Stream<ChimeNotification> getTappedChimeNotificationStream()
    => chimeController.getTappedChimeNotificationStream();

  @override
  Stream<ChimeNotification> getClosedChimeNotificationStream()
    => chimeController.getClosedChimeNotificationStream();

  @override
  Stream<ChimeNotification> getDismissedChimeNotificationStream()
    => chimeController.getDismissedChimeNotificationStream();

  @override
  Stream<ChimeNotification> getFailedChimeNotificationStream()
    => chimeController.getFailedChimeNotificationStream();

  @override
  List<ChimeNotification> getTappedNotifications()
    => chimeController.getTappedNotifications();

  @override
  bool hasCreatedNotification(ChimeCreatedNotification notifier)
    => chimeController.hasCreatedNotification(notifier);

  @override
  bool hasCreatedNotificationListener()
    => chimeController.hasCreatedNotificationListener();

  @override
  bool hasLaunchedAppNotificationListener()
    => chimeController.hasLaunchedAppNotificationListener();

  @override
  bool hasReceivedNotificationListener()
    => chimeController.hasReceivedNotificationListener();

  @override
  bool hasScheduledNotificationListener()
    => chimeController.hasScheduledNotificationListener();

  @override
  bool hasTappedNotificationListener()
    => chimeController.hasTappedNotificationListener();

  @override
  bool hasClosedNotificationListener()
    => chimeController.hasClosedNotificationListener();

  @override
  bool hasDismissedNotificationListener()
    => chimeController.hasDismissedNotificationListener();

  @override
  bool hasFailedNotificationListener()
    => chimeController.hasFailedNotificationListener();

  @override
  Future<void> publishEvent(ChimeEvent event)
    => chimeController.publishEvent(event);

  @override
  Future<void> removeAllChimeEventListeners()
    => chimeController.removeAllChimeEventListeners();

  @override
  Future<void> removeChimeEventListener(ChimeEventListener<ChimeEvent> listener)
    => chimeController.removeChimeEventListener(listener);

  @override
  Future<void> removeChimeEventListeners(bool Function(ChimeEventListener<ChimeEvent>) listener)
    => chimeController.removeChimeEventListeners(listener);

  @override
  void removeCreatedNotification(String identifier)
    => chimeController.removeCreatedNotification(identifier);

  @override
  void removeTappedNotification(String identifier)
    => chimeController.removeTappedNotification(identifier);

  /// {@template chime_mixin_dismiss_by_id}
  /// Dismisses a notification by its numeric identifier.
  ///
  /// This uses the local notifications plugin to cancel the notification.
  ///
  /// ### Example
  /// ```dart
  /// final notificationId = notification.id;
  /// dismissById(notificationId);
  /// ```
  /// {@endtemplate}
  void dismissById(int id, {String? tag}) async {
    await plugin.cancel(id: id, tag: tag);
  }

  /// {@template chime_mixin_dismiss_all}
  /// Dismisses all active notifications.
  ///
  /// Use this when you need a full cleanup, such as on logout or reset.
  ///
  /// ### Example
  /// ```dart
  /// // Useful on logout or account switch.
  /// dismissAll();
  /// ```
  /// {@endtemplate}
  void dismissAll() async {
    await plugin.cancelAll();
  }

  /// {@template chime_mixin_dismiss_channel}
  /// Dismisses notifications that belong to a given channel id.
  ///
  /// This method filters active notifications by channel and cancels each one.
  ///
  /// ### Example
  /// ```dart
  /// dismissChannelNotifications('messages');
  /// ```
  /// {@endtemplate}
  void dismissChannelNotifications(String channel) => _dismiss(channel);

  /// {@template chime_mixin_dismiss_channel_internal}
  /// Internal helper that filters active notifications by channel id.
  ///
  /// This is used by [dismissChannelNotifications].
  /// {@endtemplate}
  void _dismiss(String id) async {
    List<ActiveNotification> notifications = await plugin.getActiveNotifications();
    notifications = notifications.where((n) => n.channelId == id).toList();

    if(notifications.isNotEmpty) {
      for (final n in notifications) {
        if(n.id case int id?) {
          await plugin.cancel(id: id);
        }
      }
    }
  }

  /// {@template chime_mixin_dismiss_group}
  /// Dismisses notifications that belong to a given group key.
  ///
  /// Useful when your notifications are grouped (e.g., per conversation).
  ///
  /// ### Example
  /// ```dart
  /// dismissGroupedNotifications('chat:42');
  /// ```
  /// {@endtemplate}
  void dismissGroupedNotifications(String groupKey) async {
    List<ActiveNotification> notifications = await plugin.getActiveNotifications();
    notifications = notifications.where((n) => n.groupKey == groupKey).toList();

    if(notifications.isNotEmpty) {
      for (final n in notifications) {
        if(n.id case int id?) {
          await plugin.cancel(id: id);
        }
      }
    }
  }
}

/// {@template chime_in_app_mixin}
/// Convenience mixin for accessing in-app notification helpers.
///
/// Apply this mixin to any class that wants a simple pass-through API for
/// showing and dismissing in-app notifications. All calls are delegated to
/// the [_inAppNotifier] instance you provide, so the host class does not need
/// to implement the rendering logic itself.
///
/// Typical use cases include services, view models, or controllers that need
/// to trigger in-app banners, alerts, or custom overlays.
///
/// ### Example
/// ```dart
/// class InAppService with ChimeInAppMixin {
///   InAppService(this._notifier);
///
///   final ChimeInAppNotification _notifier;
///
///   @override
///   ChimeInAppNotification get _inAppNotifier => _notifier;
/// }
/// ```
/// {@endtemplate}
mixin ChimeInAppMixin implements ChimeInAppNotification {
  ChimeInAppNotification get _inAppNotifier => Chime.getInAppNotification();

  @override
  Future<void> dismissInAppNotification({required String id}) => _inAppNotifier.dismissInAppNotification(id: id);

  @override
  Future<void> showInAppCustomNotification({
    int duration = 5,
    required ToastificationBuilder contentBuilder,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed,
  }) => _inAppNotifier.showInAppCustomNotification(
    duration: duration,
    contentBuilder: contentBuilder,
    position: position,
    onTapped: onTapped,
    onClosed: onClosed,
    onCompleted: onCompleted,
    onDismissed: onDismissed,
  );

  @override
  Future<void> showInAppErrorNotification({
    String title = "Error notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed,
  }) => _inAppNotifier.showInAppErrorNotification(
    title: title,
    message: message,
    duration: duration,
    position: position,
    onTapped: onTapped,
    onClosed: onClosed,
    onCompleted: onCompleted,
    onDismissed: onDismissed,
  );

  @override
  Future<void> showInAppInfoNotification({
    String title = "For your information,",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed,
  }) => _inAppNotifier.showInAppInfoNotification(
    title: title,
    message: message,
    duration: duration,
    position: position,
    onTapped: onTapped,
    onClosed: onClosed,
    onCompleted: onCompleted,
    onDismissed: onDismissed,
  );

  @override
  Future<void> showInAppNotification({
    Color? color,
    required String message,
    int duration = 5,
    Color? textColor,
  }) => _inAppNotifier.showInAppNotification(
    color: color,
    message: message,
    duration: duration,
    textColor: textColor,
  );

  @override
  Future<void> showInAppSuccessNotification({
    String title = "Success notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed,
  }) => _inAppNotifier.showInAppSuccessNotification(
    title: title,
    message: message,
    duration: duration,
    position: position,
    onTapped: onTapped,
    onClosed: onClosed,
    onCompleted: onCompleted,
    onDismissed: onDismissed,
  );

  @override
  Future<void> showInAppWarningNotification({
    String title = "Important!",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed,
  }) => _inAppNotifier.showInAppWarningNotification(
    title: title,
    message: message,
    duration: duration,
    position: position,
    onTapped: onTapped,
    onClosed: onClosed,
    onCompleted: onCompleted,
    onDismissed: onDismissed,
  );
}