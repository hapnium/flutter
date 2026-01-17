/// {@template device_notification_manager_service}
/// An abstract interface for managing device notifications programmatically.
///
/// The [DeviceNotificationManagerInterface] defines core operations for dismissing
/// notifications, such as dismissing by ID, by channel, by group key (Android only),
/// or clearing all notifications at once.
///
/// This is particularly useful for providing a consistent interface across platforms
/// when managing notification lifecycles at the system level.
///
/// ### Example
/// ```dart
/// class MyNotificationManager extends DeviceNotificationManagerService {
///   @override
///   void dismissById(int id) {
///     // Platform-specific logic to cancel a notification
///   }
/// }
/// ```
///
/// Use this class when you want to ensure granular or global control over active
/// device notifications from your app logic.
///
/// {@endtemplate}
abstract interface class DeviceNotificationManagerInterface<T> {
  /// Dismisses a notification by its unique identifier.
  ///
  /// Throws a `TappyException` if the method is not implemented.
  ///
  /// @param id The unique identifier of the notification to dismiss.
  void dismissById(int id);

  /// Dismisses all notifications.
  ///
  /// Throws a `TappyException` if the method is not implemented.
  void dismissAll();

  /// Dismisses all notifications from the `channel` value.
  ///
  /// Throws a `TappyException` if the method is not implemented.
  void dismissChannelNotifications(String channel);

  /// Dismisses all notifications from the group key (Android only).
  ///
  /// @param groupKey The group identifier key for the notification
  /// Throws a `TappyException` if the method is not implemented.
  void dismissGroupedNotifications(String groupKey);
}