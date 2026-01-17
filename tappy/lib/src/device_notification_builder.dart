import 'models/remote_notification_config.dart';

/// {@template device_notification_builder_service}
/// An abstract class defining the blueprint for building device-level notifications.
///
/// [DeviceNotificationBuilderInterface] provides an interface for constructing and
/// displaying notifications using the app’s local or remote configuration payloads.
/// It allows platform-agnostic handling of various notification types, including
/// in-app and push notifications.
///
/// This service is useful for translating remote server payloads into actionable
/// UI-level device notifications, helping maintain consistency and behavior across platforms.
///
/// ### Example
/// ```dart
/// class MyNotificationBuilder extends DeviceNotificationBuilderService {
///   @override
///   void build(RemoteNotificationConfig config) {
///     // Show notification based on config data
///   }
///
///   @override
///   void handleFirebase(RemoteNotificationConfig config) {
///     // Handle legacy Firebase background message
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class DeviceNotificationBuilderInterface<T> {
  /// {@macro device_notification_builder_service}
  const DeviceNotificationBuilderInterface();

  /// Builds and displays a generic notification using a given config.
  ///
  /// - **Default**: `null`
  ///
  /// This method constructs the notification UI and behavior from the provided
  /// [RemoteNotificationConfig] payload. The payload typically contains metadata such
  /// as title, body, type, and routing logic. The implementation is expected to handle
  /// the user experience when tapping on or interacting with the notification.
  ///
  /// @param config The payload that configures how the notification should behave and display.
  void build(RemoteNotificationConfig<T> config);
}