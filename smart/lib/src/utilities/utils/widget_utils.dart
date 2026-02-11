import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hapnium/hapnium.dart';

/// {@template widget_utils}
/// A utility class for measuring the size of a Flutter widget.
///
/// This class provides a static method [measure] to calculate the size of a given widget
/// by laying it out in a temporary render tree.
/// 
/// {@endtemplate}
class WidgetUtils {
  WidgetUtils._();
  
  /// Measures the size of the given [widget].
  ///
  /// This method creates a temporary render tree, attaches the [widget] to it,
  /// lays out the tree, and returns the size of the root render object.
  ///
  /// The [widget] must be a widget that has a size, such as [Container], [SizedBox], or [ConstrainedBox].
  ///
  /// Throws an [AssertionError] if the [widget] does not have a size.
  ///
  /// Example:
  /// ```dart
  /// final size = WidgetUtils.measure(Container(width: 100, height: 50));
  /// print(size); // Output: Size(100.0, 50.0)
  /// ```
  static Size measure(Widget widget) {
    final PipelineOwner pipelineOwner = PipelineOwner();
    final MeasurementView rootView = pipelineOwner.rootNode = MeasurementView();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    final RenderObjectToWidgetElement<RenderBox> element = RenderObjectToWidgetAdapter<RenderBox>(
      container: rootView,
      debugShortDescription: '[root]',
      child: widget,
    ).attachToRenderTree(buildOwner);

    try {
      rootView.scheduleInitialLayout();
      pipelineOwner.flushLayout();
      return rootView.size;
    } finally {
      // Clean up.
      element.update(RenderObjectToWidgetAdapter<RenderBox>(container: rootView));
      buildOwner.finalizeTree();
    }
  }

  /// Determines if a given widget has valid content with defined dimensions.
  ///
  /// This method measures the widget and verifies that at least one dimension
  /// is finite and greater than zero.
  ///
  /// - [widget]: The widget to validate.
  ///
  /// Returns `true` if the widget has valid dimensions, otherwise `false`.
  static bool hasContent(Widget widget) {
    try {
      Size size = measure(widget);
      bool hasWidth = size.width.isFinite && size.width.isGt(0);
      bool hasHeight = size.height.isFinite && size.height.isGt(0);
      return hasWidth || hasHeight;
    } catch (_) {
      return false;
    }
  }
}

/// A custom [RenderBox] used for measuring the size of a widget.
///
/// This render box is used as the root of the temporary render tree in [WidgetUtils.measure].
/// It lays out its child with no constraints and sets its size to the child's size.
class MeasurementView extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  @override
  void performLayout() {
    assert(child != null, "MeasurementView must have a child.");
    child!.layout(const BoxConstraints(), parentUsesSize: true);
    size = child!.size;
  }

  @override
  void debugAssertDoesMeetConstraints() => true;
}