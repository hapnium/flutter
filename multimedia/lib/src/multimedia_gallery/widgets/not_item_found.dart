import 'package:flutter/material.dart';
import 'package:smart/smart.dart';

/// {@template no_item_found_indicator}
/// A generic empty-state widget that displays an icon, a descriptive message,
/// and an optional refresh button.
///
/// This widget is used throughout the multimedia gallery to indicate three
/// distinct states: (1) permission denied — with a retry button to re-request
/// access, (2) loading complete but no albums found on the device, and
/// (3) an album opened but it contains no media items. Each usage can
/// override the default icon, message, and button styling through the
/// constructor parameters.
///
/// The icon is rendered at [opacity] (default `0.2`) to keep it visually
/// subdued. When [onRefresh] is provided, a styled [TextButton] appears
/// below the message, allowing the user to retry the failed operation.
/// When [onRefresh] is `null`, no button is rendered at all.
/// {@endtemplate}
class NoItemFoundIndicator extends StatelessWidget {
  /// The message to display below the icon.
  ///
  /// This should describe the empty state in user-friendly language,
  /// such as "Permission is needed to access your gallery" or
  /// "No gallery asset found in your device".
  final String message;

  /// An optional [IconData] to display above the message.
  ///
  /// When provided, rendered as a Material [Icon] at [iconSize] (default
  /// `100`) with [textColor]. Ignored if [customIcon] is also provided.
  final IconData? icon;

  /// An optional custom widget to display in place of [icon].
  ///
  /// Takes precedence over [icon] when both are provided. Use this to
  /// display an animated illustration, an SVG, or any non-icon widget
  /// as the empty-state visual.
  final Widget? customIcon;

  /// Color for the message text and the default [icon].
  ///
  /// Defaults to the theme's primary color. Applied uniformly to both
  /// the text and the icon to maintain visual consistency.
  final Color? textColor;

  /// Callback invoked when the refresh button is tapped.
  ///
  /// Typically used to re-check permissions or re-fetch album data.
  /// When `null`, no button is rendered — only the icon and message
  /// are shown. The button is styled with [buttonColor], [buttonWeight],
  /// [buttonSize], and other button-related parameters.
  final VoidCallback? onRefresh;

  /// Color for the refresh button text.
  ///
  /// Defaults to the theme's primary color. Should contrast with the
  /// button's background (which defaults to transparent).
  final Color? buttonColor;

  /// Opacity applied to the icon widget.
  ///
  /// Defaults to `0.2`. A low opacity keeps the icon visually subdued
  /// so the message text remains the focal point of the empty state.
  final double? opacity;

  /// Size of the default [icon] in logical pixels.
  ///
  /// Defaults to `100`. Only applies when [icon] is provided and
  /// [customIcon] is not.
  final double? iconSize;

  /// Font size of the message text in logical pixels.
  ///
  /// Defaults to `Sizing.font(16)`. The message should be large enough
  /// to read comfortably but smaller than the page title.
  final double? textSize;

  /// Vertical spacing between the icon, message, and refresh button.
  ///
  /// Defaults to `10`. Applied as the `spacing` parameter of the
  /// enclosing [Column].
  final double? spacing;

  /// Font weight of the refresh button text.
  ///
  /// Defaults to [FontWeight.bold]. Bold text helps the button stand
  /// out as an interactive element.
  final FontWeight? buttonWeight;

  /// Font size of the refresh button text in logical pixels.
  ///
  /// Defaults to `Sizing.font(14)`. Should be slightly smaller than
  /// the message text to maintain visual hierarchy.
  final double? buttonSize;

  /// Text label for the refresh button.
  ///
  /// Defaults to `"Refresh"`. Use a verb that describes the action,
  /// such as "Retry", "Try Again", or "Request Access".
  final String? buttonText;

  /// Padding inside the refresh button.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 6)`. Horizontal
  /// padding gives the button a comfortable tap target width.
  final EdgeInsets? buttonPadding;

  /// Shape of the refresh button.
  ///
  /// Defaults to `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))`.
  /// A fully rounded shape gives the button a pill-like appearance.
  final OutlinedBorder? buttonShape;

  /// Splash/overlay color when the refresh button is pressed.
  ///
  /// Defaults to the theme's splash color. This is the ripple effect
  /// color that appears briefly on tap.
  final Color? buttonOverlayColor;

  /// Background color of the refresh button.
  ///
  /// Defaults to [Colors.transparent]. A transparent background keeps
  /// the button visually lightweight and consistent with the empty state.
  final Color? buttonBackgroundColor;

  /// Foreground (text) color of the refresh button.
  ///
  /// Defaults to [Colors.transparent]. The actual text color is
  /// controlled by [buttonColor] applied to the [TextBuilder] child.
  final Color? buttonForegroundColor;

  /// {@macro no_item_found_indicator}
  ///
  /// [message] is required and describes the empty state to the user.
  const NoItemFoundIndicator({
    required this.message,
    this.icon,
    this.customIcon,
    this.textColor,
    this.onRefresh,
    this.buttonColor,
    this.opacity,
    this.iconSize,
    this.textSize,
    this.spacing,
    this.buttonWeight,
    this.buttonSize,
    this.buttonText,
    this.buttonPadding,
    this.buttonShape,
    this.buttonOverlayColor,
    this.buttonBackgroundColor,
    this.buttonForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: spacing ?? 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(opacity: opacity ?? 0.2, child: _buildIcon(context)),
          TextBuilder.center(
            text: message,
            autoSize: false,
            size: textSize ?? Sizing.font(16),
            color: textColor ?? Theme.of(context).primaryColor,
          ),
          if(onRefresh.isNotNull) ...[
            TextButton(
              onPressed: onRefresh,
              style: ButtonStyle(
                overlayColor: WidgetStatePropertyAll(buttonOverlayColor ?? Theme.of(context).splashColor),
                backgroundColor: WidgetStateProperty.all(buttonBackgroundColor ?? Colors.transparent),
                foregroundColor: WidgetStateProperty.all(buttonForegroundColor ?? Colors.transparent),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: WidgetStateProperty.all(buttonShape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                padding: WidgetStateProperty.all(buttonPadding ?? EdgeInsets.symmetric(horizontal: 6))
              ),
              child: TextBuilder(
                text: buttonText ?? "Refresh",
                weight: buttonWeight ?? FontWeight.bold,
                size: buttonSize ?? Sizing.font(14),
                color: buttonColor ?? Theme.of(context).primaryColor,
              )
            )
          ]
        ],
      ),
    );
  }

  /// Builds the icon widget, preferring [customIcon] over [icon].
  ///
  /// If [icon] is provided, returns a Material [Icon] with [textColor]
  /// and [iconSize]. If [customIcon] is provided, returns it directly.
  /// If neither is provided, returns an empty [Container] as a placeholder
  /// to maintain the column's spacing.
  Widget _buildIcon(BuildContext context) {
    if(icon.isNotNull) {
      return Icon(icon, color: textColor ?? Theme.of(context).primaryColor, size: iconSize ?? 100);
    } else if(customIcon.isNotNull) {
      return customIcon!;
    } else {
      return Container();
    }
  }
}