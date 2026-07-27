part of '../progress_slider.dart';

/// {@template bar_cap_shape}
/// Determines the shape drawn at the left and right ends of the
/// [ProgressSlider] bar.
///
/// This affects the base bar, the progress bar, and the buffered
/// progress bar equally. The default is [BarCapShape.round].
/// {@endtemplate}
enum BarCapShape {
  /// The ends of the bar are drawn as semicircles.
  ///
  /// ```
  ///  (-------O----------------)
  /// ```
  ///
  /// This is the default. The cap radius equals half the bar height,
  /// so the bar visually extends slightly beyond its start and end
  /// coordinates.
  round,

  /// The ends of the bar are drawn as flat vertical edges.
  ///
  /// ```
  ///  |-------O----------------|
  /// ```
  ///
  /// Useful when you need precise alignment with adjacent widgets
  /// or when the bar must not overflow its bounding box.
  square,
}