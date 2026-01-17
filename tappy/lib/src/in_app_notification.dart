import 'package:flutter/cupertino.dart';

import 'config/definitions.dart';

/// {@template in_app_notification_service}
/// An abstract service for handling in-app notifications.
///
/// The [InAppNotificationInterface] defines the contract for how notifications
/// should be received, displayed, and interacted with while the app is running.
///
/// It is a generic class that supports typed data for notification payloads.
/// This allows implementations to specialize in handling different types of
/// domain models, such as messages, trips, or events.
///
/// ### Example
/// ```dart
/// class ChatNotificationService extends InAppNotificationService<ChatMessage> {
///   @override
///   void dismissInAppNotification(String id) {
///     // Custom logic to show chat popup, etc.
///   }
/// }
/// ```
///
/// This abstraction is useful for implementing modular notification pipelines
/// and decoupling platform-specific delivery logic from UI-level handling.
/// {@endtemplate}
abstract interface class InAppNotificationInterface<T> {
  /// Displays a success notification with the given message and optional callbacks.
  ///
  /// @param title The title of the notification. Defaults to "Success notification".
  /// @param message The message of the notification. This is required.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  void success({
    String title = "Success notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  });

  /// Displays an error notification with the given message and optional callbacks.
  ///
  /// @param title The title of the notification. Defaults to "Error notification".
  /// @param message The message of the notification. This is required.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  void error({
    String title = "Error notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  });

  /// Displays an informational notification with the given message and optional callbacks.
  ///
  /// @param title The title of the notification. Defaults to "For your information,".
  /// @param message The message of the notification. This is required.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  void info({
    String title = "For your information,",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  });

  /// Displays an warning notification with the given message and optional callbacks.
  ///
  /// @param title The title of the notification. Defaults to "Important!".
  /// @param message The message of the notification. This is required.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  void warn({
    String title = "Important!",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  });

  /// Displays a small tip notification with the given message and optional callbacks.
  ///
  /// @param color The color of the notification.
  /// @param textColor The color of the notification text.
  /// @param message The message of the notification. This is required.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  void tip({Color? color, required String message, int duration = 5, Color? textColor});

  /// Displays a custom notification with the given content and duration.
  ///
  /// @param content The custom content of the notification.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  void custom({
    int duration = 5,
    required Widget content,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  });

  /// Dismiss either all, by [String] notification or by [String] notification id
  void dismissInAppNotification({required String id});
}