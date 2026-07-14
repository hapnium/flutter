import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tracing/tracing.dart';
import 'package:toastification/toastification.dart';

import '../enums/in_app_style.dart';
import '../enums/in_app_state.dart';
import '../config/definitions.dart';
import '../in_app_notification.dart';

/// A class for managing in-app notifications.
///
/// This class provides a customizable way to display in-app notifications
/// with various options for styling, content, and behavior.
///
/// [T] represents the type of data associated with the notification.
class DefaultInAppNotification<T> implements InAppNotificationInterface<T> {
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
  final TappyInAppStyle style;

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

  /// Creates an [DefaultInAppNotification] instance.
  DefaultInAppNotification({
    this.titleSize = 16,
    this.descriptionSize = 14,
    this.iconSize = 32,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.fontFamily,
    this.showLogs = false,
    this.style = TappyInAppStyle.minimal,
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
    TappyInAppState state;
    switch (type) {
      case ToastificationType.error:
        state = TappyInAppState.error;
        break;

      case ToastificationType.info:
        state = TappyInAppState.info;
        break;

        case ToastificationType.warning:
        state = TappyInAppState.warning;
        break;

      default:
        state = TappyInAppState.success;
        break;
    }

    Widget? titleWidget;
    if(title.isNotEmpty) {
      if(titleBuilder case InAppNotificationBuilder? inAppNotificationBuilder when inAppNotificationBuilder != null) {
        titleWidget = inAppNotificationBuilder(title, state);
      } else {
        titleWidget = Padding(
          padding: titlePadding ?? EdgeInsets.only(top: 12),
          child: _text(title, titleSize, titleWeight),
        );
      }
    }

    Widget? descriptionWidget;
    if(description.isNotEmpty) {
      if (descriptionBuilder case InAppNotificationBuilder? inAppNotificationBuilder when inAppNotificationBuilder != null) {
        descriptionWidget = inAppNotificationBuilder(description, state);
      } else {
        descriptionWidget = Padding(
          padding: descriptionPadding ?? EdgeInsets.only(top: 6),
          child: _text(description, descriptionSize, descriptionWeight),
        );
      }
    }

    Widget? iconWidget;
    if(iconBuilder case InAppNotificationIconBuilder? inAppNotificationIconBuilder when inAppNotificationIconBuilder != null) {
      iconWidget = inAppNotificationIconBuilder(state);
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
        onTap: (item) {
          process(onTap, onProcess: (tap) => tap(item.id));
        },
        onCloseButtonTap: (item) {
          process(onClose, onProcess: (tap) => tap(item.id));
        },
        onAutoCompleteCompleted: (item) {
          process(onComplete, onProcess: (tap) => tap(item.id));
        },
        onDismissed: (item) {
          process(onDismissed, onProcess: (tap) => tap(item.id));
        },
      ),
    );
  }

  @override
  void custom({
    int duration = 5,
    required Widget content,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) {
    if(showLogs) {
      console.debug("Building `custom` notification", tag: prefix);
    }

    toastification.show(
      autoCloseDuration: Duration(seconds: duration),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      primaryColor: Colors.grey,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 16,
          offset: Offset(0, 16),
          spreadRadius: 0,
        )
      ],
      showProgressBar: true,
      closeButton: ToastCloseButton(
        showType: CloseButtonShowType.onHover,
        // buttonBuilder: (BuildContext context, void Function() onClicked) {}
      ),
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
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
  }

  @override
  void error({
    String title = "Error notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) {
    if(showLogs) {
      console.debug("Building `error` notification", tag: prefix);
    }

    _show(
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
  }

  @override
  void info({
    String title = "For your information",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) {
    if(showLogs) {
      console.debug("Building `info` notification", tag: prefix);
    }

    _show(
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
  }

  @override
  void tip({required String message, int duration = 5, Color? color, Color? textColor}) async {
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
  void success({
    String title = "Success notification",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) {
    if(showLogs) {
      console.debug("Building `success` notification", tag: prefix);
    }

    _show(
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
  }

  @override
  void warn({
    String title = "Important!",
    required String message,
    int duration = 5,
    Alignment position = Alignment.topRight,
    InAppNotificationCallback? onTapped,
    InAppNotificationCallback? onClosed,
    InAppNotificationCallback? onCompleted,
    InAppNotificationCallback? onDismissed
  }) {
    if(showLogs) {
      console.debug("Building `warn` notification", tag: prefix);
    }

    _show(
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
  }

  @override
  void dismissInAppNotification({required String id}) {
    if(id.isNotEmpty) {
      toastification.dismissById(id);
    } else {
      toastification.dismissAll();
    }
  }
}