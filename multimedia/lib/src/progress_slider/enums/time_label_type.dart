part of '../progress_slider.dart';

/// {@template time_label_type}
/// Determines what the right-hand time label on the [ProgressSlider]
/// displays.
///
/// The left label always shows the current playback position. This
/// enum controls only the right label. The default is
/// [TimeLabelType.totalTime].
/// {@endtemplate}
enum TimeLabelType {
  /// The right label shows the total duration of the media.
  ///
  /// ```
  ///  | -------O---------------- |
  ///  | 01:23              05:00 |
  /// ```
  ///
  /// This is the default.
  totalTime,

  /// The right label shows the remaining time as a negative number.
  ///
  /// ```
  ///  | -------O---------------- |
  ///  | 01:23             -03:37 |
  /// ```
  ///
  /// Useful for countdown-style UIs where the user expects to see
  /// how much time is left rather than the total length.
  remainingTime,
}