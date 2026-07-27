part of '../progress_slider.dart';

/// {@template time_label_location}
/// Controls where the current-time and total-time text labels are
/// positioned relative to the [ProgressSlider] bar.
///
/// The default is [TimeLabelLocation.below]. Set to [TimeLabelLocation.none]
/// to hide labels entirely.
/// {@endtemplate}
enum TimeLabelLocation {
  /// Labels appear above the progress bar.
  ///
  /// ```
  ///  | 01:23              05:00 |
  ///  | -------O---------------- |
  /// ```
  above,

  /// Labels appear below the progress bar.
  ///
  /// ```
  ///  | -------O---------------- |
  ///  | 01:23              05:00 |
  /// ```
  ///
  /// This is the default.
  below,

  /// Labels appear on the left and right sides of the progress bar.
  ///
  /// ```
  ///  | 01:23 -------O---------------- 05:00 |
  /// ```
  ///
  /// The bar shrinks horizontally to make room for the labels. Extra
  /// spacing is controlled by [ProgressSlider.timeLabelPadding].
  sides,

  /// No time labels are displayed.
  ///
  /// ```
  ///  | -------O---------------- |
  /// ```
  ///
  /// Useful when the slider is embedded in a context where time
  /// information is shown elsewhere (e.g., a separate timestamp widget).
  none,
}