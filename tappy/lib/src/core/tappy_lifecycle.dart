import 'package:flutter/foundation.dart';

import '../models/notifier.dart';
import 'tappy_mixin.dart';

/// An abstract class defining a service for updating notification-related streams.
///
/// The `TappyUpdateService` provides an interface for updating various streams
/// that tappy listeners about notification-related events. This interface
/// serves as a foundation for implementing services that handle notification
/// events such as created, received, scheduled, tapped, and in-app notifications.
///
/// ### Example Usage
/// ```dart
/// class MyNotificationService extends TappyUpdateService {
///   @override
///   void onCreated(Notifier notifier) {
///     // Handle logic for created notifications.
///     super.onCreated(notifier);
///   }
///
///   @override
///   void onReceived(Notifier notifier) {
///     // Handle logic for received notifications.
///     super.onReceived(notifier);
///   }
///
///   @override
///   void onScheduled(Notifier notifier) {
///     // Handle logic for scheduled notifications.
///     super.onScheduled(notifier);
///   }
///
///   @override
///   void onAppLaunched(Notifier notifier) {
///     // Handle logic for app launched notifications.
///     super.onAppLaunched(notifier);
///   }
///
///   @override
///   void onTapped(Notifier notifier) {
///     // Handle logic for tapped notifications.
///     super.onTapped(notifier);
///   }
///
///   @override
///   void onUseInApp(Notifier notifier) {
///     // Handle logic for in-app notifications.
///     super.onUseInApp(notifier);
///   }
///
///   // Implement other methods as needed.
/// }
/// ```
abstract class TappyLifecycle with TappyMixin {
  /// Updates the stream with a created notification.
  ///
  /// This method should be called when a new notification is created.
  ///
  /// For example, a notification is considered "created" when:
  /// - A notification is configured and displayed to the user.
  /// - The notification details (e.g., title, body, payload) are defined and set.
  ///
  /// Implementations of this method should add the `notifier` object to the
  /// appropriate stream, making the created notification data available to
  /// listeners.
  ///
  /// #### Parameters:
  /// - [notifier]: The `Notifier` object containing details about the created notification.
  @mustCallSuper
  void onCreated(Notifier notifier) {
    if(!controller.hasCreatedNotification(notifier)) {
      controller.addCreated(notifier);
      controller.createdController.add(notifier);
    }
  }

  /// Updates the stream with a received notification.
  ///
  /// This method should be called when the application receives a new
  /// notification. Notifications can be received while the app is in the
  /// foreground, background, or terminated state.
  ///
  /// Use this method to handle notifications received via remote push
  /// notification services (e.g., Firebase Cloud Messaging) or local
  /// notifications triggered by the app.
  ///
  /// #### Parameters:
  /// - [notifier]: The `Notifier` object containing details about the received notification.
  @mustCallSuper
  void onReceived(Notifier notifier) {
    controller.receivedController.add(notifier);
  }

  /// Updates the stream with a scheduled notification.
  ///
  /// This method should be called when a notification is successfully
  /// scheduled to trigger at a future time.
  ///
  /// For example, use this method to tappy listeners when:
  /// - A notification is scheduled to remind the user of a task.
  /// - Notifications are configured to recur periodically (e.g., daily, weekly).
  ///
  /// #### Parameters:
  /// - [notifier]: The `Notifier` object containing details about the scheduled notification.
  @mustCallSuper
  void onScheduled(Notifier notifier) {
    controller.scheduledController.add(notifier);
  }

  /// Updates the stream with an app launch triggered by a notification.
  ///
  /// This method should be called when a user taps a notification and the app
  /// is launched as a result. Use this method to tappy listeners that the app
  /// has been opened via a notification.
  ///
  /// This is particularly useful for:
  /// - Navigating the user to a specific screen or feature.
  /// - Handling any payload or action associated with the notification tap.
  ///
  /// #### Parameters:
  /// - [notifier]: The `Notifier` object containing details about the notification that triggered the app launch.
  @mustCallSuper
  void onAppLaunched(Notifier notifier) {
    controller.launchedAppController.add(notifier);
  }

  /// Updates the stream with a tapped notification.
  ///
  /// This method should be called when a user taps on a notification while the
  /// app is already running (foreground or background). It allows the app to
  /// respond to user interactions with notifications, such as:
  /// - Opening a specific section of the app.
  /// - Processing user input provided via the notification action.
  ///
  /// #### Parameters:
  /// - [notifier]: The `Notifier` object containing details about the tapped notification.
  @mustCallSuper
  void onTapped(Notifier notifier) {
    if (controller.tappedController.hasListener) {
      controller.tappedController.add(notifier);
    } else {
      controller.addTapped(notifier);
    }
  }

  /// Updates the stream with an in-app notification received.
  ///
  /// This method should be called when an in-app notification is displayed and
  /// received by the user. In-app notifications are typically lightweight
  /// notifications shown within the app, such as banners or popups, without
  /// involving the system's notification tray.
  ///
  /// Use this method to:
  /// - Tappy listeners about the in-app notification event.
  /// - Handle custom logic or analytics related to in-app notifications.
  ///
  /// #### Parameters:
  /// - [notifier]: The `Notifier` object containing details about the in-app notification.
  @mustCallSuper
  void onUseInApp(Notifier notifier) {
    controller.inAppReceivedController.add(notifier);
  }
}