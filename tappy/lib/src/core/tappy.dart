import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/definitions.dart';
import '../enums/tappy_type.dart';
import '../models/notifier.dart';
import 'tappy_interface.dart';

/// {@template tappy}
/// The internal implementation of the Tappy notification handler.
///
/// This private class extends [TappyInterface] and serves as the core engine
/// for processing notification interactions within the Tappy system.
///
/// It provides logic for:
/// - Parsing notification responses
/// - Triggering custom user-defined handlers
/// - Delegating the tap event to the lifecycle listener
///
/// This class should not be instantiated manually. Instead, use the singleton
/// instance provided by [Tappy].
///
/// ### Example
/// ```dart
/// Tappy.handleNotificationResponse(response);
/// ```
/// 
/// {@endtemplate}
class _Tappy extends TappyInterface {
  /// {@macro tappy}
  _Tappy();

  /// Handles a response from a tapped or interacted notification.
  ///
  /// This method is typically called when the user taps a notification
  /// or performs a defined notification action (e.g., pressing a button).
  ///
  /// Internally, it does the following:
  /// 1. Parses the [NotificationResponse] into a [Notifier] object
  ///    using [TappyType.parse].
  /// 2. Passes the resulting [Notifier] into an optional custom [handler].
  ///    If the [handler] is provided, it will be called with the [Notifier].
  /// 3. Notifies the [TappyLifecycle] system by invoking `onTapped()`,
  ///    enabling app-level reaction to notification interactions.
  ///
  /// ---
  /// #### Parameters:
  /// - [response]: The notification interaction response provided by
  ///   `flutter_local_notifications`. This contains information like the
  ///   notification ID, action ID, payload, etc.
  ///
  /// - [handler] *(optional)*: A custom tap handler callback defined by
  ///   the user. If provided, it will be invoked with the parsed [Notifier]
  ///   before the lifecycle method is called. This allows apps to override
  ///   default behavior or perform side effects.
  ///
  /// ---
  /// #### Throws:
  /// - May throw [TappyException] if the required Tappy configuration (like
  ///   `lifecycle`) is missing. This is caught upstream during development
  ///   if `TappyApplication` is not properly configured.
  ///
  /// ---
  /// #### Example:
  /// ```dart
  /// Tappy.handleNotificationResponse(response, handler: (notifier) {
  ///   debugPrint("User tapped: ${notifier.title}");
  /// });
  /// ```
  void handleNotificationResponse(NotificationResponse response, {NotificationTapHandler? handler}) {
    Notifier notifier = TappyType.parse(response);
    process(handler, onProcess: (value) => value(notifier));

    lifecycle.onTapped(notifier);
  }
}

/// The global singleton instance of the internal Tappy notification engine.
///
/// This instance provides centralized access to Tappy’s notification
/// handling logic, including parsing platform-specific notification
/// responses, routing them through optional custom handlers, and dispatching
/// lifecycle callbacks.
///
/// The [_Tappy] class itself extends [TappyInterface], which holds shared
/// configuration and service bindings related to notification presentation
/// and interaction. By exposing this single instance, the Tappy framework
/// ensures that all notification-related behavior is managed consistently
/// across the application lifecycle.
///
/// This instance is intended to be used internally within the Tappy system
/// (such as inside `TappyApplication`) and should be accessed via the
/// public-facing APIs provided by the framework. However, you may also call
/// methods on `Tappy` directly if needed.
///
/// ---
/// ### Example Usage:
///
/// ```dart
/// // Handle notification tap from a NotificationResponse
/// Tappy.handleNotificationResponse(response);
/// ```
///
/// ---
/// ### Do Not:
/// - Attempt to instantiate `_Tappy` yourself.
/// - Create duplicate instances—this singleton is automatically
///   initialized by the framework.
///
/// ---
/// ### Related:
/// - [TappyInterface]
/// - [TappyApplication]
/// - [TappyLifecycle]
/// - [TappyMixin]
final _Tappy Tappy = _Tappy();