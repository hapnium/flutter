import 'package:flutter/material.dart' show IconData, Color, Icons, Colors;
import 'package:toastification/toastification.dart';

/// {@template in_app_style}
/// Represents the visual styling options available for in-app notifications.
///
/// This enum wraps around [ToastificationStyle] to provide descriptive and
/// customizable display styles for different notification types.
///
/// Each [ChimeInAppStyle] corresponds to a visual layout and behavior that
/// affects how notifications appear on screen—ranging from minimal alerts
/// to filled backgrounds with text and icons.
///
/// ### Example usage:
/// ```dart
/// final style = InAppStyle.fillColored;
/// showToast(
///   style: style.toast,
///   title: "Upload Complete",
///   description: "Your file was uploaded successfully"
/// );
/// ```
/// {@endtemplate}
enum ChimeInAppStyle {
  /// {@macro in_app_style}
  ///
  /// Displays a compact and subtle notification.
  /// - Style: [ToastificationStyle.minimal]
  minimal(ToastificationStyle.minimal),

  /// {@macro in_app_style}
  ///
  /// Displays the notification with a prominent filled background color.
  /// Suitable for high-visibility alerts.
  /// - Style: [ToastificationStyle.fillColored]
  fillColored(ToastificationStyle.fillColored),

  /// {@macro in_app_style}
  ///
  /// Displays a notification with a solid flat background color.
  /// Cleaner and bolder than [minimal], but less visually intense than [fillColored].
  /// - Style: [ToastificationStyle.flatColored]
  flatColored(ToastificationStyle.flatColored),

  /// {@macro in_app_style}
  ///
  /// Displays a notification with a flat layout and no background color.
  /// Best for non-intrusive informational messages.
  /// - Style: [ToastificationStyle.flat]
  flat(ToastificationStyle.flat),

  /// {@macro in_app_style}
  ///
  /// A bare-bones notification showing only the title text.
  /// No icons, actions, or decorations are included.
  /// - Style: [ToastificationStyle.simple]
  simple(ToastificationStyle.simple);

  /// The associated [ToastificationStyle] that defines the visual behavior.
  final ToastificationStyle toast;

  /// Creates an [ChimeInAppStyle] enum value.
  ///
  /// This links the style to its corresponding [ToastificationStyle] for UI rendering.
  /// 
  /// {@macro in_app_style}
  const ChimeInAppStyle(this.toast);
}

/// {@template in_app_state}
/// Defines the visual and behavioral characteristics of in-app notification states.
///
/// Each [ChimeInAppState] corresponds to a type of notification with a predefined:
/// - [ToastificationType] to control toast style
/// - [IconData] to visually indicate the context
/// - [Color] to signal urgency or type (e.g., info, error)
///
/// This enum simplifies UI feedback logic by centralizing styling and toast logic
/// in one place, which improves consistency across the application.
///
/// ### Example usage:
/// ```dart
/// final state = InAppState.warning;
/// showToast(
///   type: state.type,
///   icon: Icon(state.icon, color: state.color),
///   message: "This is a warning!"
/// );
/// ```
/// {@endtemplate}
enum ChimeInAppState {
  /// {@macro in_app_state}
  ///
  /// Used for general informational messages that require no user action.
  /// - Toast type: [ToastificationType.info]
  /// - Icon: [Icons.info]
  /// - Color: [Colors.blue]
  info(ToastificationType.info, Icons.info, Colors.blue),

  /// {@macro in_app_state}
  ///
  /// Used to alert users of a potential issue or something to pay attention to.
  /// - Toast type: [ToastificationType.warning]
  /// - Icon: [Icons.warning_amber_outlined]
  /// - Color: [Colors.yellow]
  warning(ToastificationType.warning, Icons.warning_amber_outlined, Colors.yellow),

  /// {@macro in_app_state}
  ///
  /// Used to indicate successful completion of a task or process.
  /// - Toast type: [ToastificationType.success]
  /// - Icon: [Icons.check_circle]
  /// - Color: [Colors.green]
  success(ToastificationType.success, Icons.check_circle, Colors.green),

  /// {@macro in_app_state}
  ///
  /// Used to tappy the user of errors or critical problems.
  /// - Toast type: [ToastificationType.error]
  /// - Icon: [Icons.error]
  /// - Color: [Colors.red]
  error(ToastificationType.error, Icons.error, Colors.red);

  /// The toastification type used to determine the style of the notification.
  ///
  /// This influences the animation, background, and general layout of the toast.
  final ToastificationType type;

  /// The icon used in the UI for the toast, corresponding to the notification's context.
  final IconData icon;

  /// The primary color used for the toast's visual cues (e.g., icon tint or background).
  final Color color;

  /// Creates an instance of [ChimeInAppState] with associated metadata.
  ///
  /// All fields are required and constant.
  /// 
  /// {@macro in_app_state}
  const ChimeInAppState(this.type, this.icon, this.color);
}

/// Enum representing the platform the device is running on.
///
/// The [ChimePlatform] enum is used to distinguish between different
/// platforms the application may run on, such as Android, iOS, and Web.
///
/// - [ANDROID]: Represents the Android platform.
/// - [IOS]: Represents the iOS platform.
/// - [WEB]: Represents the Web platform.
enum ChimePlatform {
  /// Represents the Android platform.
  ANDROID,

  /// Represents the iOS platform.
  IOS,

  /// Represents the Web platform.
  WEB,
}