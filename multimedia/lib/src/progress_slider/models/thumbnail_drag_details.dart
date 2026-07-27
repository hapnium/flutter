part of '../progress_slider.dart';

/// {@template thumb_drag_details}
/// Encapsulates the data available during a thumb drag gesture on a
/// [ProgressSlider].
///
/// Passed to [ThumbDragStartCallback] and [ThumbDragUpdateCallback] so
/// that the caller can track both the semantic position (a [Duration])
/// and the physical position (pixel [Offset]s) of the drag event.
///
/// The [timeStamp] is always clamped between `Duration.zero` and the
/// slider's total duration, making it safe to use directly for seek
/// operations or preview rendering.
/// {@endtemplate}
final class ThumbDragDetails {
  /// The duration position of the thumb on the progress bar.
  ///
  /// This is the semantic value corresponding to the thumb's current
  /// pixel position. It is clamped to the range
  /// `[Duration.zero, ProgressSlider.total]` and updates continuously
  /// as the user drags.
  final Duration timeStamp;

  /// The global position of the drag event in screen coordinates.
  ///
  /// Useful for positioning overlays (e.g., a video preview tooltip)
  /// that need to float above the slider at the exact touch point,
  /// regardless of the slider's position in the widget tree.
  final Offset globalPosition;

  /// The local position of the drag event relative to the slider widget.
  ///
  /// Useful for calculations that depend on the thumb's position within
  /// the slider's own coordinate space, such as determining whether
  /// the drag is near the start or end of the bar.
  final Offset localPosition;

  /// Creates a [ThumbDragDetails] instance.
  ///
  /// All parameters default to zero values, which represent a drag
  /// at the very start of the progress bar with no movement.
  ///
  /// {@macro thumb_drag_details}
  const ThumbDragDetails({
    this.timeStamp = Duration.zero,
    this.globalPosition = Offset.zero,
    this.localPosition = Offset.zero,
  });

  @override
  String toString() => '${objectRuntimeType(this, 'ThumbDragDetails')}('
      'time: $timeStamp, '
      'global: $globalPosition, '
      'local: $localPosition)';
}