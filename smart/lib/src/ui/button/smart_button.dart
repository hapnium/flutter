import 'package:flutter/material.dart';
import 'package:smart/utilities.dart';
import 'package:hapnium/hapnium.dart';

import '../export.dart';

/// {@template smart_button}
/// A button widget used for page navigation with optional notification support.
///
/// The button displays an icon or image along with a label, and it optionally shows a
/// notification indicator if [needNotification] is set to `true`.
/// Users can customize the button's appearance, including colors, padding, and text sizes.
/// Additionally, a custom notification widget can be provided via [notification].
/// 
/// {@endtemplate}
class SmartButton extends StatelessWidget {
  /// The button's configuration containing an icon, image, header, and body text.
  final ButtonView tab;

  /// The callback function when the button is tapped.
  final VoidCallback? onTap;

  /// Determines whether a notification should be displayed.
  ///
  /// If `true`, a notification indicator will appear on the button.
  final bool needNotification;

  /// The color of the icon and text.
  ///
  /// Defaults to the theme's primary color if not provided.
  final Color? color;

  /// The background color of this button.
  ///
  /// Defaults to the scaffold background color.
  final Color? backgroundColor;

  /// The color applied to the image icon.
  ///
  /// If `null`, the default color is used.
  final Color? imageColor;

  /// The color applied to the body text.
  ///
  /// If `null`, the default color is used (Range is: color is not null, color else default color).
  final Color? bodyColor;

  /// The color applied to the notification widget.
  ///
  /// If `null`, the default color is used (Range is: color is not null, color else default color).
  final Color? notificationColor;

  /// Whether to show an icon if an image is not available.
  ///
  /// If `true`, the icon specified in [tab] will be displayed when an image is absent.
  final bool showIcon;

  /// Custom widget for displaying notifications.
  ///
  /// If `null`, a default notification indicator is used.
  final Widget? notification;

  /// Padding around the button.
  ///
  /// Defaults to `Sizing.space(8)`.
  final EdgeInsetsGeometry? padding;

  /// Padding around the notification widget.
  ///
  /// Defaults to `Sizing.space(3)`.
  final EdgeInsetsGeometry? notificationPadding;

  /// The size of the icon.
  ///
  /// Defaults to `Sizing.space(24)`.
  final double? iconSize;

  /// The text size for the header.
  ///
  /// Defaults to `Sizing.font(15)`.
  final double? headerTextSize;

  /// The text size for the body.
  ///
  /// Defaults to `Sizing.font(12)`.
  final double? bodyTextSize;

  /// The height of the image icon.
  ///
  /// If `null`, the default size is used.
  final double? imageHeight;

  /// The width of the image icon.
  ///
  /// If `null`, the default size is used.
  final double? imageWidth;

  /// The spacing between the icon and text.
  ///
  /// Defaults to `10`.
  final double? spacing;

  /// Determines the **main axis alignment** of the button's content.
  ///
  /// Defaults to `MainAxisAlignment.start`.
  final MainAxisAlignment? mainAxisAlignment;

  /// Determines the **cross axis alignment** of the button's content.
  ///
  /// Defaults to `CrossAxisAlignment.center`.
  final CrossAxisAlignment? crossAxisAlignment;

  /// Main axis spacing between children.
  ///
  /// Defaults to min
  final MainAxisSize mainAxisSize;

  /// The border radius applied to the image.
  ///
  /// Defaults to `BorderRadius.circular(10)`.
  final BorderRadiusGeometry? imageBorderRadius;

  /// The font weight of the header text
  /// 
  /// Defaults to `FontWeight.normal`
  final FontWeight? fontWeight;

  /// The font weight of the body text
  /// 
  /// Defaults to `FontWeight.normal`
  final FontWeight? bodyWeight;

  /// Whether the button is in selective mode.
  ///
  /// If `true`, the button will be visually styled differently to indicate
  /// that it is currently selected.
  final bool isSelective;

  /// The text size for the header when in selective mode.
  final double? selectiveTextSize;

  /// The border radius of the container when in selective mode.
  final double? selectiveBorderRadius;

  /// The width of the container when in selective mode.
  final double? selectiveWidth;

  /// Creates an instance of [SmartButton].
  ///
  /// This widget provides a navigational button with an optional notification badge.
  ///
  /// - [tab]: The button details (icon, image, header, body text).
  /// - [onTap]: Callback when the button is tapped.
  /// - [needNotification]: If `true`, a notification indicator is displayed.
  /// - [color]: Color of the text and icon.
  /// - [backgroundColor]: Background color of the button.
  /// - [showIcon]: If `true`, an icon is displayed when an image is absent.
  /// - [notification]: Custom widget for notifications (defaults to a red dot).
  /// - [padding]: The padding around the button (defaults to `Sizing.space(8)`).
  /// - [iconSize]: The size of the icon (defaults to `Sizing.space(24)`).
  /// - [headerTextSize]: The font size of the header text (defaults to `Sizing.font(15)`).
  /// - [bodyTextSize]: The font size of the body text (defaults to `Sizing.font(12)`).
  /// 
  /// {@macro smart_button}
  const SmartButton({
    super.key,
    required this.tab,
    this.onTap,
    this.needNotification = false,
    this.color,
    this.showIcon = true,
    this.notification,
    this.padding,
    this.iconSize,
    this.headerTextSize,
    this.bodyTextSize,
    this.backgroundColor,
    this.imageColor,
    this.imageHeight,
    this.imageWidth,
    this.spacing,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.imageBorderRadius,
    this.bodyColor,
    this.notificationColor,
    this.notificationPadding,
    this.fontWeight,
    this.bodyWeight,
    this.mainAxisSize = MainAxisSize.max
  }) : isSelective = false,
    selectiveTextSize = null,
    selectiveBorderRadius = null,
    selectiveWidth = null;

  /// Creates an instance of [SmartButton] in selective mode.
  /// 
  /// {@macro smart_button}
  const SmartButton.selective({
    super.key,
    required this.tab,
    this.onTap,
    this.color,
    this.padding,
    this.iconSize,
    this.backgroundColor,
    this.spacing,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.fontWeight,
    this.selectiveTextSize,
    this.selectiveBorderRadius,
    this.selectiveWidth,
    this.showIcon = true,
    this.mainAxisSize = MainAxisSize.min
  }) : bodyWeight = null,
    isSelective = true,
    imageBorderRadius = null,
    bodyColor = null,
    notificationColor = null,
    notificationPadding = null,
    needNotification = false,
    notification = null,
    headerTextSize = null,
    bodyTextSize = null,
    imageColor = null,
    imageHeight = null,
    imageWidth = null;

  @override
  Widget build(BuildContext context) {
    if(isSelective) {
      return _selective(context);
    } else {
      return _standard(context);
    }
  }

  /// Selective view
  Widget _selective(BuildContext context) {
    return SizedBox(
      width: selectiveWidth ?? 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(selectiveBorderRadius ?? 8.0),
        child: Material(
          color: backgroundColor ?? Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: padding ?? EdgeInsets.all(8.0),
              child: Center(child: _selectiveChild(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectiveChild(BuildContext context) {
    Widget child = TextBuilder.center(
      text: tab.header,
      color: color ?? tab.color,
      size: Sizing.font(selectiveTextSize ?? 12),
      flow: TextOverflow.ellipsis,
      weight: fontWeight ?? FontWeight.normal
    );

    if(showIcon) {
      return Column(
        spacing: spacing ?? 10,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
        children: [
          Icon(
            tab.icon,
            color: color ?? tab.color,
            size: iconSize ?? 18,
          ),
          child
        ],
      );
    } else {
      return child;
    }
  }

  /// Standard button mode
  Widget _standard(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? EdgeInsets.all(Sizing.space(8)),
          child: Row(
            spacing: spacing ?? 10,
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
            mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
            children: [
              // Display image widget if available, else check image if available, otherwise fallback to icon
              if (tab.imageWidget.isNotNull) ...[
                tab.imageWidget!,
              ] else if (tab.image.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: imageBorderRadius ?? BorderRadius.circular(10),
                  child: Image.asset(
                    tab.image,
                    width: imageWidth ?? 45,
                    height: imageHeight,
                    color: imageColor,
                  ),
                ),
              ] else if (showIcon) ...[
                Icon(
                  tab.icon,
                  color: color ?? Theme.of(context).primaryColor,
                  size: Sizing.space(iconSize ?? 24),
                ),
              ],
              // Display text content
              Expanded(child: _body(context)),
              // Display notification if enabled
              _notification(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the button's text section.
  ///
  /// - Displays the `header` text and optionally the `body` text (if available).
  Widget _body(BuildContext context) {
    Widget header = TextBuilder(
      text: tab.header,
      size: Sizing.font(headerTextSize ?? 15),
      color: color ?? Theme.of(context).primaryColor,
      weight: fontWeight ?? FontWeight.normal
    );

    if (tab.body.isEmpty) {
      return header;
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          TextBuilder(
            text: tab.body,
            size: Sizing.font(bodyTextSize ?? 12),
            color: bodyColor ?? color ?? Theme.of(context).primaryColorLight,
            weight: bodyWeight ?? FontWeight.normal
          ),
        ],
      );
    }
  }

  /// Builds the notification widget.
  ///
  /// - Returns an empty `Container` if [needNotification] is `false`.
  /// - Uses the provided [notification] widget if available.
  /// - Otherwise, falls back to the [_defaultNotification] widget.
  Widget _notification(BuildContext context) {
    if (!needNotification) return Container();
    return notification ?? _defaultNotification(context);
  }

  /// Builds the default notification indicator (a small red dot).
  ///
  /// - Uses the **HeartBeating** animation for a pulsing effect.
  /// - The color is based on the primary theme.
  Widget _defaultNotification(BuildContext context) {
    return HeartBeating(
      child: Container(
        padding: notificationPadding ?? EdgeInsets.all(Sizing.space(3)),
        decoration: BoxDecoration(
          color: notificationColor ?? color ?? Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}