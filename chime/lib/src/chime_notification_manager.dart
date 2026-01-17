import 'chime_notification.dart';

/// {@template chime_notification_manager}
/// Contract for managing notification state and buffers.
///
/// A [ChimeNotificationManager] is responsible for tracking created and tapped
/// notifications, deduplicating by identifier, and flushing any buffered items
/// when a consumer becomes available.
///
/// The identifier used here is a string to allow flexible sources (UUIDs,
/// backend IDs, or composite keys).
///
/// ### Example
/// ```dart
/// if (!manager.hasCreatedNotification(notification)) {
///   manager.addCreatedNotification(notification);
/// }
/// manager.flushCreatedNotifications();
/// ```
/// {@endtemplate}
abstract interface class ChimeNotificationManager {
  /// {@template chime_controller_get_tapped_notifications}
  /// Returns the list of notifications that have been tapped.
  ///
  /// This list represents buffered items collected when no tap listeners were
  /// attached, or when the controller intentionally queues taps for later.
  ///
  /// Implementations should return a read-only view to avoid external mutation.
  ///
  /// ### Example
  /// ```dart
  /// final taps = controller.getTappedNotifications();
  /// for (final notification in taps) {
  ///   print(notification.id);
  /// }
  /// ```
  /// {@endtemplate}
  List<ChimeNotification> getTappedNotifications();

  /// {@template chime_controller_get_created_notifications}
  /// Returns the list of notifications that have been created.
  ///
  /// This list is typically used to prevent duplicate notification creation
  /// or to delay display until a listener is ready.
  ///
  /// Implementations should return a read-only view to avoid external mutation.
  ///
  /// ### Example
  /// ```dart
  /// final created = controller.getCreatedNotifications();
  /// print('Created count: ${created.length}');
  /// ```
  /// {@endtemplate}
  List<ChimeCreatedNotification> getCreatedNotifications();

  /// {@template chime_controller_get_created_app_notifications}
  /// Returns the list of created in-app notifications.
  ///
  /// This exposes the in-app notification payloads created by your UI layer,
  /// allowing dismissal logic to find the matching notification instance.
  ///
  /// ### Example
  /// ```dart
  /// final createdApps = controller.getCreatedAppNotifications();
  /// final match = createdApps.firstWhere((n) => n.identifier == id);
  /// ```
  /// {@endtemplate}
  List<ChimeAppNotification> getCreatedAppNotifications();

  /// {@template chime_controller_has_created_notification}
  /// Checks whether a notification has already been created.
  ///
  /// Use this to prevent duplicate notifications when multiple event sources
  /// can emit the same payload.
  ///
  /// ### Example
  /// ```dart
  /// if (!controller.hasCreatedNotification(notification)) {
  ///   controller.addCreatedNotification(notification);
  /// }
  /// ```
  /// {@endtemplate}
  bool hasCreatedNotification(ChimeCreatedNotification notifier);

  /// {@template chime_controller_add_created_notification}
  /// Adds a newly created notification to the internal list.
  ///
  /// This helps prevent the same notification from being created multiple
  /// times while still allowing deferred processing.
  ///
  /// ### Example
  /// ```dart
  /// controller.addCreatedNotification(notification);
  /// ```
  /// {@endtemplate}
  void addCreatedNotification(ChimeCreatedNotification notifier);

  /// {@template chime_controller_remove_created_notification}
  /// Removes a created notification by its identifier.
  ///
  /// Use this after a notification has been displayed or persisted so it can
  /// be re-created in the future if needed.
  ///
  /// ### Example
  /// ```dart
  /// controller.removeCreatedNotification(notification.identifier);
  /// ```
  /// {@endtemplate}
  void removeCreatedNotification(String identifier);

  /// {@template chime_controller_remove_tapped_notification}
  /// Removes a tapped notification by its identifier.
  ///
  /// Use this after a tap has been processed to avoid repeated navigation or
  /// duplicated analytics.
  ///
  /// ### Example
  /// ```dart
  /// controller.removeTappedNotification(notification.identifier);
  /// ```
  /// {@endtemplate}
  void removeTappedNotification(String identifier);

  /// {@template chime_controller_flush_created_notifications}
  /// Flushes all created notifications and exposes them to listeners.
  ///
  /// This is useful when a listener is attached after notifications were
  /// created and you want to emit the backlog immediately.
  ///
  /// ### Example
  /// ```dart
  /// controller.flushCreatedNotifications();
  /// ```
  /// {@endtemplate}
  void flushCreatedNotifications();

  /// {@template chime_controller_flush_pending_tapped_notifications}
  /// Flushes all pending tapped notifications and exposes them to listeners.
  ///
  /// Call this once a tap listener is attached and you want to immediately
  /// deliver any queued taps.
  ///
  /// ### Example
  /// ```dart
  /// controller.flushPendingTappedNotifications();
  /// ```
  /// {@endtemplate}
  void flushPendingTappedNotifications();

  /// {@template chime_controller_add_tapped_notification}
  /// Adds a tapped notification to the internal list.
  ///
  /// This is typically called when a tap event occurs before any listener
  /// is ready to process it.
  ///
  /// ### Example
  /// ```dart
  /// controller.addTappedNotification(notification);
  /// ```
  /// {@endtemplate}
  void addTappedNotification(ChimeNotification notifier);
}