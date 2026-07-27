part of '../progress_slider.dart';

/// Signature for a callback fired when the user begins dragging the thumb.
///
/// Receives a [ThumbDragDetails] containing the initial [Duration] position,
/// and the global/local [Offset] of the touch event. Use this to initialize
/// overlays (e.g., a video preview or time label) that track the thumb.
///
/// ```dart
/// ProgressSlider(
///   progress: current,
///   total: duration,
///   onDragStart: (details) {
///     showPreviewAt(details.localPosition);
///   },
/// );
/// ```
typedef ThumbDragStartCallback = void Function(ThumbDragDetails details);

/// Signature for a callback fired repeatedly as the user drags the thumb.
///
/// Receives a [ThumbDragDetails] with the current [Duration] position and
/// the updated global/local [Offset]. The [Duration] is clamped between
/// `Duration.zero` and [ProgressSlider.total], so it is safe to use
/// directly for seek previews.
///
/// ```dart
/// ProgressSlider(
///   progress: current,
///   total: duration,
///   onDragUpdate: (details) {
///     updatePreviewPosition(details.localPosition);
///     updateCustomLabel(details.timeStamp);
///   },
/// );
/// ```
typedef ThumbDragUpdateCallback = void Function(ThumbDragDetails details);