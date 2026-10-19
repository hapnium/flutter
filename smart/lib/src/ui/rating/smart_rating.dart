import 'package:flutter/material.dart';

import '../export.dart';

/// A utility class providing convenient methods to create various rating widgets.
///
/// `SmartRating` simplifies the creation of rating bars, rating indicators, and
/// rating icons with customizable configurations. It provides static methods
/// to generate instances of `RatingBar`, `RatingBarIndicator`, and `RatingIcon`
/// with optional parameters for customization.
class SmartRating {
  /// Creates an interactive rating bar widget.
  ///
  /// This method returns a `RatingBar` widget, which allows users to input
  /// ratings through tapping or dragging. You can customize the appearance
  /// and behavior of the rating bar using the provided parameters.
  ///
  /// **Parameters:**
  ///
  /// * `child`: Customizes the Rating Bar item with [RatingBarWidget].
  /// * `onRatingUpdate`: Callback that returns the current rating whenever the rating is updated.
  /// * `glowColor`: Defines the color for the glow effect when the rating bar is touched.
  /// * `maxRating`: Sets the maximum rating value.
  /// * `textDirection`: The text flows from right to left if [textDirection] = TextDirection.rtl.
  /// * `unratedColor`: Defines the color for the unrated portion of the rating bar.
  /// * `allowHalfRating`: Enables half-rating support if set to `true`.
  /// * `direction`: Direction of the rating bar.
  /// * `glow`: Enables the glow effect when the rating bar is touched.
  /// * `glowRadius`: Defines the radius of the glow effect.
  /// * `ignoreGestures`: Disables any gestures over the rating bar if set to `true`.
  /// * `initialRating`: Defines the initial rating value.
  /// * `itemCount`: Defines the total number of rating bar items.
  /// * `itemPadding`: The amount of space by which to inset each rating item.
  /// * `itemSize`: Defines the width and height of each rating item in the bar.
  /// * `minRating`: Sets the minimum rating value.
  /// * `tapOnlyMode`: Disables drag-to-rate functionality if set to `true`.
  /// * `updateOnDrag`: Defines whether the `onRatingUpdate` callback is triggered during drag gestures.
  /// * `wrapAlignment`: How the items within the [RatingBar] should be placed in the main axis.
  static RatingBar bar({
    /// Customizes the Rating Bar item with [RatingBarWidget].
    required RatingBarWidget child,

    /// Callback that returns the current rating whenever the rating is updated.
    ///
    /// [updateOnDrag] can be used to control when the callback is triggered
    /// during drag gestures.
    required ValueChanged<double> onRatingUpdate,
    /// Defines the color for the glow effect when the rating bar is touched.
    ///
    /// Defaults to `ColorScheme.secondary` if available, otherwise no glow.
    Color? glowColor,

    /// Sets the maximum rating value.
    ///
    /// Defaults to [itemCount].
    double? maxRating,

    /// The text flows from right to left if [textDirection] = TextDirection.rtl.
    TextDirection? textDirection,

    /// Defines the color for the unrated portion of the rating bar.
    ///
    /// Defaults to `ThemeData.disabledColor`.
    Color? unratedColor,

    /// Enables half-rating support if set to `true`.
    ///
    /// Defaults to `false`.
    bool allowHalfRating = false,

    /// Direction of the rating bar.
    ///
    /// Defaults to `Axis.horizontal`.
    Axis direction = Axis.horizontal,

    /// Enables the glow effect when the rating bar is touched.
    ///
    /// Defaults to `true`.
    bool glow = true,

    /// Defines the radius of the glow effect.
    ///
    /// Defaults to `2`.
    double glowRadius = 2,

    /// Disables any gestures over the rating bar if set to `true`.
    ///
    /// Defaults to `false`.
    bool ignoreGestures = false,

    /// Defines the initial rating value.
    ///
    /// Defaults to `0.0`.
    double initialRating = 0.0,

    /// Defines the total number of rating bar items.
    ///
    /// Defaults to `5`.
    int itemCount = 5,

    /// The amount of space by which to inset each rating item.
    EdgeInsetsGeometry itemPadding = EdgeInsets.zero,

    /// Defines the width and height of each rating item in the bar.
    ///
    /// Defaults to `40.0`.
    double itemSize = 40.0,

    /// Sets the minimum rating value.
    ///
    /// Defaults to `0`.
    double minRating = 0.0,

    /// Disables drag-to-rate functionality if set to `true`.
    ///
    /// Note: Enabling this mode disables half-rating capability.
    /// Defaults to `false`.
    bool tapOnlyMode = false,

    /// Defines whether the `onRatingUpdate` callback is triggered during drag gestures.
    ///
    /// Defaults to `false`.
    bool updateOnDrag = false,

    /// How the items within the [RatingBar] should be placed in the main axis.
    ///
    /// For example, if [wrapAlignment] is [WrapAlignment.center], the items in
    /// the RatingBar are grouped together in the center of their run in the main axis.
    ///
    /// Defaults to `WrapAlignment.start`.
    WrapAlignment wrapAlignment = WrapAlignment.start,
  }) {
    return RatingBar(
      child: child,
      onRatingUpdate: onRatingUpdate,
      glowColor: glowColor,
      glow: glow,
      glowRadius: glowRadius,
      ignoreGestures: ignoreGestures,
      initialRating: initialRating,
      itemCount: itemCount,
      itemPadding: itemPadding,
      itemSize: itemSize,
      minRating: minRating,
      tapOnlyMode: tapOnlyMode,
      updateOnDrag: updateOnDrag,
      wrapAlignment: wrapAlignment,
      direction: direction,
      allowHalfRating: allowHalfRating,
      unratedColor: unratedColor,
      maxRating: maxRating,
      textDirection: textDirection,
    );
  }

  /// Creates an interactive rating bar widget using an [itemBuilder].
  ///
  /// Similar to `bar()`, but uses an `IndexedWidgetBuilder` to create the
  /// rating items, providing more flexibility in customization.
  static RatingBar builder({
    /// Widget for each rating bar item.
    required IndexedWidgetBuilder itemBuilder,

    /// Callback that returns the current rating whenever the rating is updated.
    ///
    /// [updateOnDrag] can be used to control when the callback is triggered
    /// during drag gestures.
    required ValueChanged<double> onRatingUpdate,
    /// Defines the color for the glow effect when the rating bar is touched.
    ///
    /// Defaults to `ColorScheme.secondary` if available, otherwise no glow.
    Color? glowColor,

    /// Sets the maximum rating value.
    ///
    /// Defaults to [itemCount].
    double? maxRating,

    /// The text flows from right to left if [textDirection] = TextDirection.rtl.
    TextDirection? textDirection,

    /// Defines the color for the unrated portion of the rating bar.
    ///
    /// Defaults to `ThemeData.disabledColor`.
    Color? unratedColor,

    /// Enables half-rating support if set to `true`.
    ///
    /// Defaults to `false`.
    bool allowHalfRating = false,

    /// Direction of the rating bar.
    ///
    /// Defaults to `Axis.horizontal`.
    Axis direction = Axis.horizontal,

    /// Enables the glow effect when the rating bar is touched.
    ///
    /// Defaults to `true`.
    bool glow = true,

    /// Defines the radius of the glow effect.
    ///
    /// Defaults to `2`.
    double glowRadius = 2,

    /// Disables any gestures over the rating bar if set to `true`.
    ///
    /// Defaults to `false`.
    bool ignoreGestures = false,

    /// Defines the initial rating value.
    ///
    /// Defaults to `0.0`.
    double initialRating = 0.0,

    /// Defines the total number of rating bar items.
    ///
    /// Defaults to `5`.
    int itemCount = 5,

    /// The amount of space by which to inset each rating item.
    EdgeInsetsGeometry itemPadding = EdgeInsets.zero,

    /// Defines the width and height of each rating item in the bar.
    ///
    /// Defaults to `40.0`.
    double itemSize = 40.0,

    /// Sets the minimum rating value.
    ///
    /// Defaults to `0`.
    double minRating = 0.0,

    /// Disables drag-to-rate functionality if set to `true`.
    ///
    /// Note: Enabling this mode disables half-rating capability.
    /// Defaults to `false`.
    bool tapOnlyMode = false,

    /// Defines whether the `onRatingUpdate` callback is triggered during drag gestures.
    ///
    /// Defaults to `false`.
    bool updateOnDrag = false,

    /// How the items within the [RatingBar] should be placed in the main axis.
    ///
    /// For example, if [wrapAlignment] is [WrapAlignment.center], the items in
    /// the RatingBar are grouped together in the center of their run in the main axis.
    ///
    /// Defaults to `WrapAlignment.start`.
    WrapAlignment wrapAlignment = WrapAlignment.start,
  }) {
    return RatingBar.builder(
      itemBuilder: itemBuilder,
      onRatingUpdate: onRatingUpdate,
      glowColor: glowColor,
      glow: glow,
      glowRadius: glowRadius,
      ignoreGestures: ignoreGestures,
      initialRating: initialRating,
      itemCount: itemCount,
      itemPadding: itemPadding,
      itemSize: itemSize,
      minRating: minRating,
      tapOnlyMode: tapOnlyMode,
      updateOnDrag: updateOnDrag,
      wrapAlignment: wrapAlignment,
      direction: direction,
      allowHalfRating: allowHalfRating,
      unratedColor: unratedColor,
      maxRating: maxRating,
      textDirection: textDirection,
    );
  }

  /// Creates a rating icon widget.
  ///
  /// Returns a `RatingIcon` widget that displays a rating using icons and
  /// optionally a text value.
  static RatingIcon icon({
    /// The rating value to be displayed.
    required double rating,

    /// Configuration for customizing rating icons and calculations.
    RatingIconConfig config = const RatingIconConfig(),

    /// Optional text size for the rating text.
    double? textSize,

    /// Optional color for the icons and text.
    Color? color,

    /// Whether to include text value
    bool showText = true,
  }) {
    return RatingIcon(
      rating: rating,
      config: config,
      textSize: textSize,
      color: color,
      showText: showText,
    );
  }

  static RatingBarIndicator indicator({
    /// {@macro flutterRatingBar.itemBuilder}
    /// Widget for each rating bar item.
    /// This allows you to customize the appearance of each item in the rating bar.
    required IndexedWidgetBuilder itemBuilder,

    /// {@macro flutterRatingBar.textDirection}
    /// The text flows from right to left if [textDirection] = TextDirection.rtl.
    TextDirection? textDirection,

    /// {@macro flutterRatingBar.unratedColor}
    /// Defines the color for the unrated portion of the rating bar.
    /// If not specified, the unrated portion will use the default color.
    Color? unratedColor,

    /// {@macro flutterRatingBar.direction}
    /// Direction of the rating bar. Defaults to `Axis.horizontal`.
    Axis direction = Axis.horizontal,

    /// {@macro flutterRatingBar.itemCount}
    /// Defines the total number of rating bar items. Defaults to 5.
    int itemCount = 5,

    /// {@macro flutterRatingBar.itemPadding}
    /// The amount of space by which to inset each rating item. Defaults to EdgeInsets.zero.
    EdgeInsets itemPadding = EdgeInsets.zero,

    /// {@macro flutterRatingBar.itemSize}
    /// Defines the width and height of each rating item in the bar. Defaults to 40.0.
    double itemSize = 40.0,

    /// Controls the scrolling behaviour of the rating bar.
    /// Since this is a read-only widget, scrolling is disabled by default.
    /// Defaults to [NeverScrollableScrollPhysics].
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),

    /// Defines the rating value to be displayed. Defaults to 0.0.
    /// This value determines how many items are filled.
    double rating = 0.0,
  }) {
    return RatingBarIndicator(
      itemBuilder: itemBuilder,
      unratedColor: unratedColor,
      textDirection: textDirection,
      direction: direction,
      itemCount: itemCount,
      itemPadding: itemPadding,
      itemSize: itemSize,
      physics: physics,
      rating: rating,
    );
  }
}