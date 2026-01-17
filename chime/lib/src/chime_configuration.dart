import 'package:flutter/material.dart';

import 'chime_controller.dart';
import 'chime_event.dart';
import 'chime_in_app_notification.dart';
import 'chime_push_notification.dart';

/// {@template chime_configuration}
/// Top-level configuration for the Chime SDK.
///
/// Use this to wire the core pieces of Chime together at application startup.
/// You can provide your own controller, event listeners, in-app notification
/// handler, push notification handler, and an optional push builder for
/// provider integrations.
///
/// ### Example
/// ```dart
/// final config = ChimeConfiguration(
///   controller: MyChimeController(),
///   eventListeners: [MyEventListener()],
///   inAppNotification: DefaultChimeInAppNotification(),
///   pushNotification: DefaultChimePushNotification('MyApp', ChimePlatform.ANDROID),
/// );
/// ```
/// {@endtemplate}
final class ChimeConfiguration {
  /// The controller that manages Chime streams and events.
  final ChimeController? controller;

  /// Event listeners registered at startup for Chime events.
  final List<ChimeEventListener> eventListeners;

  /// Optional in-app notification handler.
  final ChimeInAppNotification? inAppNotification;

  /// Optional push notification handler.
  final ChimePushNotification? pushNotification;

  /// {@macro chime_configuration}
  const ChimeConfiguration({
    this.controller,
    this.eventListeners = const [],
    this.inAppNotification,
    this.pushNotification,
  });
}

const _defaultAlignment = AlignmentDirectional.topEnd;
const _itemAnimationDuration = Duration(milliseconds: 600);
const _defaultWidth = 400.0;
const _defaultClipBehavior = Clip.none;

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
/// {@template in_app_notification_animation_builder}
/// Builder for custom in-app notification animations.
///
/// The builder receives the [animation] value and should return a widget that
/// animates the [child] based on that value.
/// {@endtemplate}
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
/// {@template in_app_notification_margin_builder}
/// Builder for custom in-app notification margins.
///
/// Use this to adjust layout for safe areas or other UI overlays.
/// {@endtemplate}
typedef InAppNotificationMarginBuilder = EdgeInsetsGeometry Function(BuildContext context, AlignmentGeometry alignment);

/// {@template in_app_config}
/// Configuration for customizing in-app notification behavior and layout.
///
/// The `InAppConfig` class allows control over how in-app notifications are
/// displayed, including their position on the screen, size, animation behavior,
/// margins, and interaction with UI elements like the keyboard.
///
/// Use this class to tailor the look and feel of in-app notifications in your application.
///
/// ### Example usage:
///
/// ```dart
/// final config = InAppConfig(
///   alignment: Alignment.bottomCenter,
///   itemWidth: 300,
///   animationDuration: Duration(milliseconds: 400),
///   animationBuilder: (context, animation, child) {
///     return FadeTransition(opacity: animation, child: child);
///   },
/// );
/// ```
/// {@endtemplate}
class InAppConfiguration {
  /// The alignment of the in-app notification within the overlay.
  ///
  /// Default: [AlignmentDirectional.topEnd]
  final AlignmentGeometry? alignment;

  /// The width of the notification widget.
  ///
  /// Useful for setting a fixed width or adapting layout in responsive design.
  ///
  /// Default: `400.0`
  final double? itemWidth;

  /// Controls how the notification widget is clipped.
  ///
  /// Default: [Clip.none]
  final Clip? clipBehavior;

  /// The duration of the notification's entry/exit animation.
  ///
  /// Default: `Duration(milliseconds: 600)`
  final Duration? animationDuration;

  /// A custom builder function to define how the notification appears/disappears.
  ///
  /// Can be used to implement fade, slide, or other animated transitions.
  ///
  /// Default: `null` (uses default animation)
  final InAppNotificationAnimationBuilder? animationBuilder;

  /// A builder for generating margins around the notification widget.
  ///
  /// This allows spacing customization depending on the UI context.
  ///
  /// Default: `null`
  final InAppNotificationMarginBuilder? marginBuilder;

  /// Whether the notification should adjust its position based on the view insets (e.g., keyboard).
  ///
  /// Helps avoid overlay being hidden by the keyboard when shown.
  ///
  /// Default: `true`
  final bool? applyMediaQueryViewInsets;

  /// {@macro in_app_config}
  InAppConfiguration({
    this.alignment = _defaultAlignment,
    this.itemWidth = _defaultWidth,
    this.clipBehavior = _defaultClipBehavior,
    this.animationDuration = _itemAnimationDuration,
    this.animationBuilder,
    this.marginBuilder,
    this.applyMediaQueryViewInsets = true,
  });

  /// Creates a copy of the current config with selectively overridden values.
  ///
  /// This is useful when you want to preserve existing configuration
  /// and only update a few fields.
  ///
  /// {@macro in_app_config}
  InAppConfiguration copyWith({
    AlignmentGeometry? alignment,
    double? itemWidth,
    Clip? clipBehavior,
    Duration? animationDuration,
    InAppNotificationAnimationBuilder? animationBuilder,
    InAppNotificationMarginBuilder? marginBuilder,
    bool? applyMediaQueryViewInsets,
  }) {
    return InAppConfiguration(
      alignment: alignment ?? this.alignment,
      itemWidth: itemWidth ?? this.itemWidth,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      animationDuration: animationDuration ?? this.animationDuration,
      animationBuilder: animationBuilder ?? this.animationBuilder,
      marginBuilder: marginBuilder ?? this.marginBuilder,
      applyMediaQueryViewInsets: applyMediaQueryViewInsets ?? this.applyMediaQueryViewInsets,
    );
  }
}
