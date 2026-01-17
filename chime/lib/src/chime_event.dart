import 'package:chime/flutter_local_notifications.dart';

import 'chime_notification.dart';

/// {@template chime_event}
/// Base type for all Chime events.
///
/// A [ChimeEvent] wraps a [ChimeNotification] and captures the time at which the
/// event instance was created. It is the common payload passed through the
/// event system (controllers, listeners, and streams).
///
/// Use the concrete subclasses (for example,
/// [NotificationReceivedEvent] or [NotificationTappedEvent]) to model specific
/// notification lifecycle moments. The event type indicates *when* it happened,
/// while the [notification] contains *what* happened.
///
/// ### Example
/// ```dart
/// final event = NotificationTappedEvent(
///   ChimeNotification(id: 1, action: 'open_chat', input: '', payload: null),
/// );
///
/// print(event.timestamp); // Time the event instance was created.
/// print(event.notification.action); // "open_chat"
/// ```
/// {@endtemplate}
sealed class ChimeEvent {
  /// The timestamp recorded when this event was created.
  ///
  /// This uses the local clock (`DateTime.now()`), so it is suitable for
  /// ordering or analytics in the current device context.
  final DateTime timestamp;

  /// The notification instance associated with this event.
  ///
  /// This contains the action, input, and payload that the rest of your
  /// application can use to route behavior.
  final ChimeNotification notification;

  /// {@macro chime_event}
  ChimeEvent(this.notification) : timestamp = DateTime.now();
}

/// {@template notification_received_event}
/// Event emitted when a notification is received by the device.
///
/// This usually represents the raw arrival of a push or local notification,
/// before any user interaction happens. It can be used to update badges,
/// prefetch content, or log delivery analytics.
///
/// ### Example
/// ```dart
/// final event = NotificationReceivedEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationReceivedEvent extends ChimeEvent {
  /// The platform response that triggered this event.
  ///
  /// This includes the payload and action information provided by the
  /// notification plugin.
  final NotificationResponse response;

  /// Whether this event was received while the app was in the background.
  ///
  /// Use this to distinguish background delivery from foreground handling.
  final bool isBackgroundNotification;

  /// {@macro notification_received_event}
  NotificationReceivedEvent(super.notification, {required this.response, this.isBackgroundNotification = false});
}

/// {@template notification_created_event}
/// Event emitted when a notification is created by your application.
///
/// This is typically fired after the notification payload has been assembled
/// and persisted, but before it is displayed or scheduled. It is a good place
/// to enforce deduplication or apply business rules.
///
/// ### Example
/// ```dart
/// final event = NotificationCreatedEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationCreatedEvent extends ChimeEvent {
  /// {@macro notification_created_event}
  NotificationCreatedEvent(ChimeCreatedNotification super.notification);
}

/// {@template notification_scheduled_event}
/// Event emitted when a notification is scheduled for a future time.
///
/// This is commonly used for local notifications or deferred push payloads,
/// and can be used to inform scheduling UIs or audits.
///
/// ### Example
/// ```dart
/// final event = NotificationScheduledEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationScheduledEvent extends ChimeEvent {
  /// {@macro notification_scheduled_event}
  NotificationScheduledEvent(ChimeScheduledNotification super.notification);
}

/// {@template app_launched_by_notification_event}
/// Event emitted when the app is launched by tapping a notification.
///
/// This allows routing or bootstrapping logic to react to the original
/// notification payload. It is typically emitted at startup, after the
/// notification intent has been resolved.
///
/// ### Example
/// ```dart
/// final event = NotificationLaunchedAppEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationLaunchedAppEvent extends ChimeEvent {
  /// The platform response that launched the app.
  ///
  /// This provides access to the action, payload, and notification metadata.
  final NotificationResponse response;

  /// {@macro app_launched_by_notification_event}
  NotificationLaunchedAppEvent(super.notification, {required this.response});
}

/// {@template notification_tapped_event}
/// Event emitted when the user taps a notification.
///
/// This typically occurs while the app is already running or in the
/// foreground/background. Use this to trigger navigation, mark a message as
/// read, or track engagement.
///
/// ### Example
/// ```dart
/// final event = NotificationTappedEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationTappedEvent extends ChimeEvent {
  /// {@macro notification_tapped_event}
  NotificationTappedEvent(super.notification);
}

/// {@template notification_dismissed_event}
/// Event emitted when a notification is dismissed by the user.
///
/// Use this to update badges, analytics, or clean up queued state when the
/// user clears a notification without interacting. This is useful for
/// understanding dismissal rates or avoiding stale UI state.
///
/// ### Example
/// ```dart
/// final event = NotificationDismissedEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationDismissedEvent extends ChimeEvent {
  /// {@macro notification_dismissed_event}
  NotificationDismissedEvent(super.notification);
}

/// {@template notification_closed_event}
/// Event emitted when a notification is closed by the user or by auto-close.
///
/// This is distinct from [NotificationDismissedEvent] when your UI or plugin
/// differentiates between a manual close action and a dismiss gesture.
///
/// ### Example
/// ```dart
/// final event = NotificationClosedEvent(notification);
/// ```
/// {@endtemplate}
final class NotificationClosedEvent extends ChimeEvent {
  /// {@macro notification_closed_event}
  NotificationClosedEvent(super.notification);
}

/// {@template notification_failed_event}
/// Event emitted when a notification fails to schedule, display, or handle.
///
/// The [error] field contains the failure cause so you can inspect, log, or
/// surface the issue. This is often used for telemetry or retry logic.
///
/// ### Example
/// ```dart
/// final event = NotificationFailedEvent(notification, StateError('bad state'));
/// ```
/// {@endtemplate}
final class NotificationFailedEvent extends ChimeEvent {
  /// The error associated with the failed notification operation.
  final Object error;

  /// The stack trace that comes with the notification failed event.
  final StackTrace? stackTrace;

  /// {@macro notification_failed_event}
  NotificationFailedEvent(super.notification, this.error, [this.stackTrace]);
}

/// {@template chime_event_listener}
/// Listener interface for consuming [ChimeEvent] objects.
///
/// Implementers can declare a generic event type to filter which events they
/// accept, and use [supportsChimeEvent] to guard dynamic event routing. A
/// listener can be registered with a [ChimeEventManager] and will receive only
/// the event types it supports.
///
/// ### Example
/// ```dart
/// final listener = _TappedListener();
///
/// class _TappedListener extends ChimeEventListener<NotificationTappedEvent> {
///   @override
///   Future<void> onChimeEvent(NotificationTappedEvent event) async {
///     print('Tapped: ${event.notification.id}');
///   }
/// }
/// ```
/// {@endtemplate}
abstract class ChimeEventListener<E extends ChimeEvent> {
  /// Handles a matching Chime event.
  ///
  /// This method is called only when [supportsChimeEvent] returns `true`.
  /// Implementations can perform asynchronous work such as analytics or
  /// navigation. If your handler may throw, consider catching and logging
  /// errors to avoid breaking the event pipeline.
  Future<void> onChimeEvent(E event);

  /// Whether this listener supports the provided [event] instance.
  ///
  /// The default implementation relies on the generic type [E] to check
  /// runtime compatibility. Override when you need custom filtering, such as
  /// by notification type or action.
  bool supportsChimeEvent(ChimeEvent event) => event is E;
}

/// {@template chime_event_manager}
/// Contract for managing and dispatching [ChimeEventListener] instances.
///
/// Implementations typically store listeners, route events to them, and provide
/// removal utilities for cleanup or lifecycle control. This keeps event
/// delivery centralized and consistent.
///
/// ### Example
/// ```dart
/// await manager.addChimeEventListener(listener);
/// await manager.dispatchEvent(NotificationReceivedEvent(notification));
/// ```
/// {@endtemplate}
abstract interface class ChimeEventManager {
  /// {@macro chime_event_manager}
  ///
  /// Implementations should avoid duplicate registrations.
  Future<void> addChimeEventListener(ChimeEventListener<ChimeEvent> listener) async {}

  /// Removes a specific [listener] instance.
  ///
  /// Use this to stop receiving events for a single subscriber. If the listener
  /// is not registered, this should be a no-op.
  Future<void> removeChimeEventListener(ChimeEventListener<ChimeEvent> listener) async {}

  /// Removes listeners based on a predicate.
  ///
  /// Return `true` from [listener] to remove that subscriber. This is useful
  /// for bulk cleanup in tests or lifecycle teardown.
  Future<void> removeChimeEventListeners(bool Function(ChimeEventListener<ChimeEvent>) listener) async {}

  /// Removes all registered listeners.
  ///
  /// Use this to clear state when disposing the manager.
  Future<void> removeAllChimeEventListeners() async {}

  /// Dispatches an event to all applicable listeners.
  ///
  /// Implementations should ensure only compatible listeners are notified
  /// (typically by calling [ChimeEventListener.supportsChimeEvent]) and should
  /// consider isolating listener failures.
  Future<void> publishEvent(ChimeEvent event) async {}
}
