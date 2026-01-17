import 'package:flutter/cupertino.dart' show Alignment, AlignmentGeometry, Animation, BuildContext, EdgeInsetsGeometry, Widget;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../tappy.dart';

/// Callback type for decrypting messages.
///
/// The [MessageDecryptionCallback] takes a single `String` argument
/// representing the encrypted message and returns the decrypted message.
typedef MessageDecryptionCallback = String Function(String message);

/// Callback type for handling in-app notifications.
///
/// The [InAppNotificationCallback] takes a single `String` argument
/// representing the notification ID.
typedef InAppNotificationCallback = void Function(String id);

/// A builder function for creating custom title or description widgets in in-app notifications.
///
/// The [text] parameter contains the notification's title or description text.
/// The [state] parameter provides access to the current state of the in-app notification,
/// allowing for dynamic content and styling based on the notification's state.
typedef InAppNotificationBuilder = Widget Function(String text, TappyInAppState state);

/// A builder function for creating custom icon widgets in in-app notifications.
///
/// The [state] parameter provides access to the current state of the in-app notification,
/// allowing for dynamic icon selection and styling based on the notification's state.
typedef InAppNotificationIconBuilder = Widget Function(TappyInAppState state);

/// A builder function for creating custom animations for in-app notifications.
///
/// This function allows you to define a custom animation for how the in-app
/// notification appears and disappears.
///
/// The [context] parameter provides the build context.
/// The [animation] parameter is an [Animation<double>] that represents the
/// animation progress (typically from 0.0 to 1.0).
/// The [alignment] parameter is the [Alignment] of the notification.
/// The [child] parameter is the actual notification widget that you should
/// wrap with your animation.
typedef InAppNotificationAnimationBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Alignment alignment,
  Widget child,
);

/// A builder function for creating custom margins for the in-app notification overlay.
///
/// This function allows you to define custom margins for the in-app notification
/// overlay.  This can be useful for positioning the notifications relative to
/// other UI elements or for handling screen edges and safe areas.
///
/// The [context] parameter provides the build context.
/// The [alignment] parameter is the [Alignment] of the notification.
typedef InAppNotificationMarginBuilder = EdgeInsetsGeometry Function(BuildContext context, AlignmentGeometry alignment);

/// A typedef for a function that configures an [InAppConfiguration] object.
///
/// This allows for a more concise way to customize the in-app notification
/// configuration.  You can create a function that takes an existing
/// [InAppConfiguration] and returns a modified version.
typedef InAppNotificationConfigurer = InAppConfiguration Function(InAppConfiguration config);

/// Callback type for handling notification permissions.
///
/// The [PermissionCallback] is invoked with a boolean value
/// indicating whether notification permissions were granted.
typedef PermissionCallback = void Function(bool granted);

/// Callback type for handling notification taps.
///
/// The [NotificationTapHandler] is invoked when a notification is tapped,
/// providing the associated [Notifier] object.
typedef NotificationTapHandler = void Function(Notifier notifier);

/// Callback type for handling notification responses.
///
/// The [NotificationResponseHandler] is invoked when a user interacts
/// with a notification and returns the associated [NotificationResponse].
typedef NotificationResponseHandler = void Function(NotificationResponse notifier);

/// Represents a generic data structure, typically a map of key-value pairs.
typedef Data = Map<String, dynamic>;

/// Utility function to check if a value is not null.
///
/// Returns `true` if the value [T] is not null, otherwise `false`.
bool isNotNull<T>(T value) => value != null;

/// Qualifies a value by checking if it's a non-empty String.
/// If the provided `value` is a `String` and it's not empty,
/// the function returns the original `value`.
///
/// If the `value` is an empty String and an `orElse` value is provided,
/// the function returns the `orElse` value.
///
/// Otherwise, the function returns the original `value` as is.
/// **Example:**
/// ```dart
/// String? name = qualify<String>('', orElse: 'Guest'); // name will be 'Guest'
/// String? city = qualify<String>('New York'); // city will be 'New York'
/// int? number = qualify<int>(null); // number will be null
/// ```
T qualify<T>(T value, {T? orElse}) {
  if (value is String) {
    if (value.isNotEmpty) {
      return value;
    } else if (orElse != null) {
      return orElse;
    }
  }

  return value;
}

/// Processes the provided value [T] if it is not null.
///
/// If [T] is a function, it executes the function and returns its result.
/// Otherwise, it simply returns the value itself. If [value] is null,
/// it does nothing and returns `null`.
///
/// Example usage:
/// ```dart
/// String? result = process(() => someFunction());
/// int? data = process<int>(someValue);
/// ```
R? process<T, R>(T? value, {R Function(T value)? onProcess, R Function()? orElse}) {
  if (isNotNull(value)) {
    if (onProcess != null) {
      return onProcess(value as T);
    } else {
      return value as R?;
    }
  }

  if(isNotNull(orElse)) {
    return orElse!();
  } else {
    return null;
  }
}