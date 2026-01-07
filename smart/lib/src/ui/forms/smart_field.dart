import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:hapnium/hapnium.dart';

import '../export.dart';

/// A widget that displays a list of fields.
///
/// This widget can be configured to be scrollable or not.
/// It provides options to customize the layout and behavior of the field list.
class SmartField extends StatelessWidget {
  /// Whether the list of fields should be scrollable.
  final bool isScrollable;

  /// The axis along which the list should scroll.
  final Axis? scrollDirection;

  /// Whether the scroll direction should be reversed.
  final bool? reverse;

  /// The padding of the scrollable area.
  final EdgeInsetsGeometry? padding;

  /// Whether to use the primary scroll controller.
  final bool? primary;

  /// The physics to apply to the scroller.
  final ScrollPhysics? physics;

  /// The scroll controller to use.
  final ScrollController? controller;

  /// The drag start behavior for the scroller.
  final DragStartBehavior? dragStartBehavior;

  /// The clipping behavior of the scroller.
  final Clip? clipBehavior;

  /// The hit test behavior for the scroller.
  final HitTestBehavior? hitTestBehavior;

  /// The restoration ID for the scroller.
  final String? restorationId;

  /// The keyboard dismiss behavior for the scroller.
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  /// A list of FieldItem objects representing the fields to be displayed.
  final List<FieldItem> items;

  /// The main axis alignment of the children.
  final MainAxisAlignment? mainAxisAlignment;

  /// The cross axis alignment of the children.
  final CrossAxisAlignment? crossAxisAlignment;

  /// The size constraint for the children in the main axis.
  final MainAxisSize? mainAxisSize;

  /// The text direction of the children.
  final TextDirection? textDirection;

  /// The vertical direction of the children.
  final VerticalDirection? verticalDirection;

  /// The text baseline of the children.
  final TextBaseline? textBaseline;

  /// The spacing between the children.
  final double? spacing;

  /// A builder function that creates a widget for each FieldItem.
  final JustFieldItemBuilder itemBuilder;

  final Key? formKey;

  /// {@macro flutter.widgets.PopScope.canPop}
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how to use this parameter to show a confirmation
  /// dialog when a navigation pop would cause form data to be lost.
  ///
  /// ** See code in examples/api/lib/widgets/form/form.1.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [onPopInvokedWithResult], which also comes from [PopScope] and is often used in
  ///    conjunction with this parameter.
  ///  * [PopScope.canPop], which is what [Form] delegates to internally.
  final bool? canPop;

  /// Called when one of the form fields changes.
  ///
  /// In addition to this callback being invoked, all the form fields themselves
  /// will rebuild.
  final VoidCallback? onChanged;

  /// Used to enable/disable form fields auto validation and update their error
  /// text.
  ///
  /// {@macro flutter.widgets.FormField.autovalidateMode}
  final AutovalidateMode validateMode;

  /// {@macro flutter.widgets.navigator.onPopInvokedWithResult}
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how to use this parameter to show a confirmation
  /// dialog when a navigation pop would cause form data to be lost.
  ///
  /// ** See code in examples/api/lib/widgets/form/form.1.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [canPop], which also comes from [PopScope] and is often used in
  ///    conjunction with this parameter.
  ///  * [PopScope.onPopInvokedWithResult], which is what [Form] delegates to internally.
  final PopInvokedWithResultCallback<Object?>? onPopInvokedWithResult;

  SmartField.builder({
    super.key,
    required this.items,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
    this.spacing,
    required this.itemBuilder,
    this.formKey,
    this.canPop,
    this.onChanged,
    this.validateMode = AutovalidateMode.onUserInteraction,
    this.onPopInvokedWithResult,
  }) : isScrollable = false,
    scrollDirection = null,
    reverse = null,
    padding = null,
    physics = null,
    controller = null,
    dragStartBehavior = null,
    clipBehavior = null,
    hitTestBehavior = null,
    primary = null,
    restorationId = null,
    keyboardDismissBehavior = null;

  SmartField.scrollable({
    super.key,
    required this.items,
    this.scrollDirection,
    this.reverse,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    this.dragStartBehavior,
    this.clipBehavior,
    this.hitTestBehavior,
    this.restorationId,
    this.keyboardDismissBehavior,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
    this.spacing,
    required this.itemBuilder,
    this.formKey,
    this.canPop,
    this.onChanged,
    this.validateMode = AutovalidateMode.onUserInteraction,
    this.onPopInvokedWithResult,
  }) : isScrollable = true;

  @override
  Widget build(BuildContext context) {
    assert(items.length.isGt(0), "Item must contain atleast one `FieldItem` element");

    if(isScrollable) {
      return SingleChildScrollView(
        scrollDirection: scrollDirection ?? Axis.vertical,
        reverse: reverse ?? false,
        padding: padding,
        primary: primary,
        physics: physics,
        controller: controller,
        dragStartBehavior: dragStartBehavior ?? DragStartBehavior.start,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
        hitTestBehavior: hitTestBehavior ?? HitTestBehavior.opaque,
        keyboardDismissBehavior: keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
        child: _build(context),
      );
    } else {
      return _build(context);
    }
  }

  Widget _build(BuildContext context) {
    if(formKey.isNotNull) {
      return Form(
        key: formKey,
        canPop: canPop,
        autovalidateMode: validateMode,
        onChanged: onChanged,
        onPopInvokedWithResult: onPopInvokedWithResult,
        child: _buildList(context),
      );
    } else {
      return _buildList(context);
    }
  }

  Widget _buildList(BuildContext context) {
    final children = items.asMap().entries.map((entry) {
      Field buildField() {
        final field = entry.value;

        if(field.isPassword) {
          return Field.password(
            label: field.label,
            hint: field.hint,
            onChanged: field.onChanged,
            validator: field.validator,
            keyboard: field.type,
            controller: field.controller,
            focus: field.focus,
            obscureText: field.obscureText,
            replaceHintWithLabel: field.replaceHintWithLabel,
            onPressed: field.onVisibilityTapped,
          );
        } else {
          return Field(
            label: field.label,
            hint: field.hint,
            onChanged: field.onChanged,
            validator: field.validator,
            keyboard: field.type,
            controller: field.controller,
            focus: field.focus,
            obscureText: field.obscureText,
            replaceHintWithLabel: field.replaceHintWithLabel,
          );
        }
      }
      
      return itemBuilder(context, buildField(), ItemMetadata(
        isFirst: entry.key.equals(0),
        isLast: entry.key.equals(items.length - 1),
        index: entry.key,
        totalItems: items.length,
        item: entry.value,
      ));
    }).toList();

    return Column(
      spacing: spacing ?? 10,
      verticalDirection: verticalDirection ?? VerticalDirection.down,
      textBaseline: textBaseline,
      textDirection: textDirection,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      mainAxisSize: mainAxisSize ?? MainAxisSize.min,
      children: children,
    );
  }
}