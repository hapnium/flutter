import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hapnium/hapnium.dart';
import 'package:toastification/toastification.dart';
import 'package:tracing/tracing.dart';

import 'chime_notification.dart';
import 'chime_event.dart';
import 'chime_mixin.dart';
import 'enums.dart';

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
typedef InAppNotificationBuilder = Widget Function(String text, ChimeInAppState state);

/// A builder function for creating custom icon widgets in in-app notifications.
///
/// The [state] parameter provides access to the current state of the in-app notification,
/// allowing for dynamic icon selection and styling based on the notification's state.
typedef InAppNotificationIconBuilder = Widget Function(ChimeInAppState state);

/// {@template in_app_notification_service}
/// An abstract service for handling in-app notifications.
///
/// The [ChimeInAppNotification] defines the contract for how notifications
/// should be received, displayed, and interacted with while the app is running.
///
/// It is a generic class that supports typed data for notification payloads.
/// This allows implementations to specialize in handling different types of
/// domain models, such as messages, trips, or events.
///
/// ### Example
/// ```dart
/// class ChatNotificationService extends ChimeInAppNotification {
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
abstract interface class ChimeInAppNotification {
  /// Displays a success notification with the given message and optional callbacks.
  ///
  /// @param title The title of the notification. Defaults to "Success notification".
  /// @param message The message of the notification. This is required.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  Future<void> showInAppSuccessNotification({
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
  Future<void> showInAppErrorNotification({
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
  Future<void> showInAppInfoNotification({
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
  Future<void> showInAppWarningNotification({
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
  Future<void> showInAppNotification({Color? color, required String message, int duration = 5, Color? textColor});

  /// Displays a custom notification with the given content and duration.
  ///
  /// @param content The custom content of the notification.
  /// @param duration The duration for which the notification will be displayed, in seconds. Defaults to 5.
  /// @param onTapped Optional callback to be called when the notification is tapped.
  /// @param onClosed Optional callback to be called when the notification is closed.
  /// @param onCompleted Optional callback to be called when the notification completes its display duration.
  /// @param onDismissed Optional callback to be called when the notification is dismissed.
  Future<void> showInAppCustomNotification({
    int duration = 5,
    required ToastificationBuilder contentBuilder,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  });

  /// Dismiss either all, by [String] notification or by [String] notification id
  Future<void> dismissInAppNotification({required String id});
}

/// A class for managing in-app notifications.
///
/// This class provides a customizable way to display in-app notifications
/// with various options for styling, content, and behavior.
@internal
class DefaultChimeInAppNotification with ChimeMixin implements ChimeInAppNotification {
  /// Prefix for log messages.
  final String prefix = "Tappy InApp Core";

  /// The color of the text in the notification.
  final Color textColor;

  /// The background color of the notification.
  final Color backgroundColor;

  /// The foreground color of the notification (e.g., for icons).
  final Color? foregroundColor;

  /// The font size of the title text.
  final double titleSize;

  /// The size of the icon.
  final double iconSize;

  /// The font size of the description text.
  final double descriptionSize;

  /// The font family to use for the text.
  final String? fontFamily;

  /// Whether to show log messages.
  final bool showLogs;

  /// Whether to close the notification when it is clicked.
  final bool? closeOnClick;

  /// Whether the notification can be dismissed by dragging.
  final bool? dragToClose;

  /// Whether to show an icon in the notification.
  final bool? showIcon;

  /// Whether to pause the notification's timer when the mouse hovers over it.
  final bool? pauseOnHover;

  /// Whether to apply a blur effect to the background.
  final bool? applyBlurEffect;

  /// Whether to show a progress bar.
  final bool? showProgressBar;

  /// The [OverlayState] to use for displaying the notification.
  final OverlayState? overlayState;

  /// The style of the notification.
  final ChimeInAppStyle style;

  /// The font weight of the title text.
  final FontWeight titleWeight;

  /// The font weight of the description text.
  final FontWeight descriptionWeight;

  /// The padding around the notification content.
  final EdgeInsetsGeometry? padding;

  /// The margin around the notification.
  final EdgeInsetsGeometry? margin;

  /// The padding around the title text.
  final EdgeInsetsGeometry? titlePadding;

  /// The padding around the description text.
  final EdgeInsetsGeometry? descriptionPadding;

  /// A builder function for creating a custom title widget.
  final InAppNotificationBuilder? titleBuilder;

  /// A builder function for creating a custom description widget.
  final InAppNotificationBuilder? descriptionBuilder;

  /// The duration of the animation for showing and hiding the notification.
  final Duration? animationDuration;

  /// The text direction of the notification.
  final TextDirection? direction;

  /// The direction in which the notification can be dismissed.
  final DismissDirection? dismissDirection;

  /// A builder function for creating a custom icon widget.
  final InAppNotificationIconBuilder? iconBuilder;

  /// The border radius of the notification.
  final BorderRadiusGeometry? borderRadius;

  /// The border side of the notification.
  final BorderSide? borderSide;

  /// A list of box shadows to apply to the notification.
  final List<BoxShadow>? boxShadow;

  /// The theme data for the progress bar.
  final ProgressIndicatorThemeData? progressBarTheme;

  /// Creates an [DefaultChimeInAppNotification] instance.
  DefaultChimeInAppNotification({
    this.titleSize = 16,
    this.descriptionSize = 14,
    this.iconSize = 32,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.fontFamily,
    this.showLogs = false,
    this.style = ChimeInAppStyle.minimal,
    this.titleBuilder,
    this.descriptionBuilder,
    this.titlePadding,
    this.descriptionPadding,
    this.titleWeight = FontWeight.bold,
    this.descriptionWeight = FontWeight.normal,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderSide,
    this.boxShadow,
    this.progressBarTheme,
    this.closeOnClick,
    this.dragToClose,
    this.showIcon,
    this.pauseOnHover,
    this.applyBlurEffect,
    this.showProgressBar,
    this.overlayState,
    this.foregroundColor,
    this.iconBuilder,
    this.animationDuration,
    this.direction,
    this.dismissDirection,
  });

  Widget _text(String text, double size, FontWeight weight) => Text(
    text,
    textAlign: TextAlign.left,
    style: TextStyle(
      fontFamily: fontFamily,
      color: textColor,
      fontSize: size,
      fontWeight: weight,
    ),
  );

  ToastificationItem _show({
    required String title,
    required String description,
    int duration = 5,
    Alignment position = Alignment.topRight,
    ToastificationType type = ToastificationType.success,
    Color color = Colors.green,
    IconData? icon,
    InAppNotificationCallback? onTap,
    InAppNotificationCallback? onClose,
    InAppNotificationCallback? onDismissed,
    InAppNotificationCallback? onComplete,
  }) {
    ChimeInAppState state;
    switch (type) {
      case ToastificationType.error:
        state = ChimeInAppState.error;
        break;

      case ToastificationType.info:
        state = ChimeInAppState.info;
        break;

        case ToastificationType.warning:
        state = ChimeInAppState.warning;
        break;

      default:
        state = ChimeInAppState.success;
        break;
    }

    Widget? titleWidget;
    if(title.isNotEmpty) {
      if(titleBuilder != null) {
        titleWidget = titleBuilder!(title, state);
      } else {
        titleWidget = Padding(
          padding: titlePadding ?? EdgeInsets.only(top: 12),
          child: _text(title, titleSize, titleWeight),
        );
      }
    }

    Widget? descriptionWidget;
    if(description.isNotEmpty) {
      if (descriptionBuilder != null) {
        descriptionWidget = descriptionBuilder!(description, state);
      } else {
        descriptionWidget = Padding(
          padding: descriptionPadding ?? EdgeInsets.only(top: 6),
          child: _text(description, descriptionSize, descriptionWeight),
        );
      }
    }

    Widget? iconWidget;
    if(iconBuilder != null) {
      iconWidget = iconBuilder!(state);
    } else if(icon != null) {
      iconWidget = Icon(icon, color: color, size: iconSize);
    }

    return toastification.show(
      type: type,
      style: style.toast,
      autoCloseDuration: Duration(seconds: duration),
      title: titleWidget,
      description: descriptionWidget,
      alignment: position,
      direction: direction ?? TextDirection.ltr,
      animationDuration: animationDuration ?? const Duration(milliseconds: 300),
      icon: iconWidget,
      primaryColor: color,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      showProgressBar: showProgressBar ?? true,
      closeButton: ToastCloseButton(
        showType: CloseButtonShowType.onHover,
        // buttonBuilder: (BuildContext context, void Function() onClicked) {}
      ),
      closeOnClick: closeOnClick ?? false,
      borderSide: borderSide ?? BorderSide.none,
      pauseOnHover: pauseOnHover ?? true,
      dragToClose: dragToClose ?? true,
      boxShadow: boxShadow,
      applyBlurEffect: applyBlurEffect,
      dismissDirection: dismissDirection,
      overlayState: overlayState,
      progressBarTheme: progressBarTheme ?? ProgressIndicatorThemeData(
        linearTrackColor: Colors.transparent,
        linearMinHeight: 2,
        color: color
      ),
      // applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (item) async {
          if (onTap case final tap?) {
            tap(item.id);
          }

          await publishEvent(NotificationTappedEvent(ChimeAppNotification(
            description: description,
            state: state,
            title: title,
            identifier: item.id,
            item: item
          )));
        },
        onCloseButtonTap: (item) async {
          if (onClose case final tap?) {
            tap(item.id);
          }

          await publishEvent(NotificationClosedEvent(ChimeAppNotification(
            description: description,
            state: state,
            title: title,
            identifier: item.id,
            item: item
          )));
        },
        onAutoCompleteCompleted: (item) async {
          if (onComplete case final tap?) {
            tap(item.id);
          }

          await publishEvent(NotificationClosedEvent(ChimeAppNotification(
            description: description,
            state: state,
            title: title,
            identifier: item.id,
            item: item
          )));
        },
        onDismissed: (item) async {
          if (onDismissed case final tap?) {
            tap(item.id);
          }

          await publishEvent(NotificationDismissedEvent(ChimeAppNotification(
            description: description,
            state: state,
            title: title,
            identifier: item.id,
            item: item
          )));
        },
      ),
    );
  }

  @override
  Future<void> showInAppCustomNotification({
    int duration = 5,
    required ToastificationBuilder contentBuilder,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) async {
    if(showLogs) {
      console.debug("Building `custom` notification", tag: prefix);
    }

    final item = toastification.showCustom(
      builder: contentBuilder,
      autoCloseDuration: Duration(seconds: duration),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      callbacks: ToastificationCallbacks(
        onTap: (item) => onTapped?.call(item.id),
        onCloseButtonTap: (item) => onClosed?.call(item.id),
        onAutoCompleteCompleted: (item) => onCompleted?.call(item.id),
        onDismissed: (item) => onDismissed?.call(item.id),
      ),
    );
    
    if(showLogs) {
      console.info("Notification built successfully", tag: prefix);
    }

    await publishEvent(NotificationCreatedEvent(ChimeCreatedCustomAppNotification(identifier: item.id, item: item)));
  }

  @override
  Future<void> showInAppErrorNotification({
    String title = "Error notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) async {
    if(showLogs) {
      console.debug("Building `error` notification", tag: prefix);
    }

    final item = _show(
      title: title,
      description: message,
      duration: duration,
      type: ToastificationType.error,
      color: Colors.red,
      icon: Icons.error,
      onTap: onTapped,
      onClose: onClosed,
      onComplete: onCompleted,
      onDismissed: onDismissed,
      position: position,
    );

    if(showLogs) {
      console.info("Notification built successfully", tag: prefix);
    }

    await publishEvent(NotificationCreatedEvent(ChimeCreatedAppNotification(
      description: message,
      state: ChimeInAppState.error,
      title: title,
      identifier: item.id,
      item: item
    )));
  }

  @override
  Future<void> showInAppInfoNotification({
    String title = "For your information",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) async {
    if(showLogs) {
      console.debug("Building `info` notification", tag: prefix);
    }

    final item = _show(
      title: title,
      description: message,
      duration: duration,
      type: ToastificationType.info,
      color: Colors.blue,
      icon: Icons.info,
      onTap: onTapped,
      onClose: onClosed,
      onComplete: onCompleted,
      onDismissed: onDismissed,
      position: position,
    );

    if(showLogs) {
      console.info("Notification built successfully", tag: prefix);
    }

    await publishEvent(NotificationCreatedEvent(ChimeCreatedAppNotification(
      description: message,
      state: ChimeInAppState.error,
      title: title,
      identifier: item.id,
      item: item
    )));
  }

  @override
  Future<void> showInAppNotification({required String message, int duration = 5, Color? color, Color? textColor}) async {
    if(showLogs) {
      console.debug("Building `tip` notification", tag: prefix);
    }

    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: color,
      textColor: textColor,
      gravity: ToastGravity.BOTTOM,
      webBgColor: color != null ? "#${color.r}${color.g}${color.b}" : "#050404"
    );

    if(showLogs) {
      console.info("Notification built successfully", tag: prefix);
    }
  }

  @override
  Future<void> showInAppSuccessNotification({
    String title = "Success notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) async {
    if(showLogs) {
      console.debug("Building `success` notification", tag: prefix);
    }

    final item = _show(
      title: title,
      description: message,
      duration: duration,
      type: ToastificationType.success,
      color: Colors.green,
      icon: Icons.check_circle,
      onTap: onTapped,
      onClose: onClosed,
      onComplete: onCompleted,
      onDismissed: onDismissed,
      position: position,
    );

    if(showLogs) {
      console.info("Notification built successfully", tag: prefix);
    }

    await publishEvent(NotificationCreatedEvent(ChimeCreatedAppNotification(
      description: message,
      state: ChimeInAppState.error,
      title: title,
      identifier: item.id,
      item: item
    )));
  }

  @override
  Future<void> showInAppWarningNotification({
    String title = "Important!",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) async {
    if(showLogs) {
      console.debug("Building `warn` notification", tag: prefix);
    }

    final item = _show(
      title: title,
      description: message,
      duration: duration,
      type: ToastificationType.warning,
      color: Colors.yellow,
      icon: Icons.warning_amber_outlined,
      onTap: onTapped,
      onClose: onClosed,
      onComplete: onCompleted,
      onDismissed: onDismissed,
      position: position,
    );

    if(showLogs) {
      console.info("Notification built successfully", tag: prefix);
    }

    await publishEvent(NotificationCreatedEvent(ChimeCreatedAppNotification(
      description: message,
      state: ChimeInAppState.error,
      title: title,
      identifier: item.id,
      item: item
    )));
  }

  @override
  Future<void> dismissInAppNotification({required String id}) async {
    if (id.isEmpty) {
      toastification.dismissAll();

      for (final notification in getCreatedAppNotifications()) {
        await publishEvent(NotificationDismissedEvent(notification));
      }

      return;
    }

    toastification.dismissById(id);
    if (getCreatedAppNotifications().find((notification) => notification.identifier == id) case final notification?) {
      await publishEvent(NotificationDismissedEvent(notification));
    }
  }
}