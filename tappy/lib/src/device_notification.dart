import 'config/definitions.dart';

/// {@template device_notification_service}
/// An abstract service for handling device-level notifications.
///
/// The [DeviceNotificationInterface] defines the interface for handling notifications
/// that are received at the device level, regardless of whether the application is
/// in the foreground, background, or terminated state.
///
/// It is designed to support strongly typed notification data, represented by [T],
/// and is intended to encapsulate low-level notification platform handling, parsing,
/// and routing logic.
///
/// ### Example
/// ```dart
/// class MyDeviceNotificationService extends DeviceNotificationService<MyModel> {
///   @override
///   void onAppLaunchedByNotification(NotificationTapHandler<MyModel> onAppLaunchedByNotification) {
///     // Parse and dispatch to app logic or UI
///   }
/// }
/// ```
///
/// This service can be used to process push notifications received through Firebase,
/// APNs, or other push delivery mechanisms before passing them to app-level handlers.
/// {@endtemplate}
abstract interface class DeviceNotificationInterface {
  /// Requests permission for notifications.
  ///
  /// This method should be implemented to request necessary permissions for
  /// displaying notifications. Depending on the platform, it may involve requesting
  /// permission to send alerts, badges, or sounds.
  ///
  /// Throws a [TappyException] since the method is not yet implemented.
  ///
  /// @return A [Future] that resolves to a [bool] indicating if the permission was granted.
  Future<bool> requestPermission();

  /// Checks if notifications are permitted for the device.
  ///
  /// Returns a [Future] that resolves to `true` if notification permissions are granted,
  /// and `false` otherwise.
  ///
  /// @return A [Future] indicating whether notifications are permitted.
  Future<bool> get isPermitted;

  /// Initializes the notification service for the given [info].
  ///
  /// This method sets up the notification service, including info-specific
  /// configurations such as notification channels or permissions.
  ///
  /// @param handler To handle any notification tap
  /// @param backgroundHandler To handle any background notification tap
  void init(NotificationTapHandler? handler, NotificationResponseHandler? backgroundHandler);

  /// Registers a callback to handle events when the app is launched via a notification.
  ///
  /// The [onAppLaunchedByNotification] function is invoked with a [Notifier] containing details about
  /// the notification that launched the app.
  ///
  /// @param onAppLaunchedByNotification A callback function to handle the notification data.
  void onAppLaunchedByNotification(NotificationTapHandler onAppLaunchedByNotification);
}