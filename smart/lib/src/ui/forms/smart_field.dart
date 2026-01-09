import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:hapnium/hapnium.dart';

import '../export.dart';

/// {@template smart_field}
/// A versatile form field container that manages multiple input fields with
/// built-in form validation, scrolling capabilities, and flexible layout options.
///
/// `SmartField` provides two main construction modes for different use cases:
/// 
/// ### Construction Modes
/// 1. **Static Layout** (`SmartField.builder`): For forms with a fixed number
///    of fields that fit on screen
/// 2. **Scrollable Layout** (`SmartField.scrollable`): For longer forms that
///    require scrolling, with configurable scrolling behavior
///
/// ### Field Type Support
/// Automatically detects and renders different field types through specialized
/// `FieldItem` subclasses:
/// - `FieldItem`: Regular text input fields
/// - `PasswordFieldItem`: Password fields with visibility toggle
/// - `PhoneFieldItem`: Phone number fields with country selection
///
/// ### Form Integration
/// Can optionally wrap fields in a Flutter `Form` widget for:
/// - Unified validation state management
/// - Form submission handling
/// - Navigation guard to prevent data loss
/// - Auto-validation modes
///
/// ### Customization
/// - **Layout**: Control spacing, alignment, and sizing of fields
/// - **Builders**: Customize each field's appearance with `itemBuilder`
/// - **Metadata**: Receive field metadata (index, position) in builders
/// - **Scrolling**: Full control over scroll behavior when using scrollable mode
///
/// ### Basic Usage
/// ```dart
/// SmartField.builder(
///   items: [
///     FieldItem(
///       label: 'Email',
///       hint: 'Enter your email',
///       validator: validateEmail,
///     ),
///     PasswordFieldItem(
///       label: 'Password',
///       hint: 'Enter password',
///       validator: validatePassword,
///     ),
///   ],
///   itemBuilder: (context, field, metadata) {
///     // Customize field appearance
///     return Padding(
///       padding: EdgeInsets.only(bottom: 16),
///       child: field,
///     );
///   },
///   spacing: 24, // Space between fields
/// )
/// ```
///
/// ### Scrollable Forms
/// ```dart
/// SmartField.scrollable(
///   items: longFieldList,
///   padding: EdgeInsets.all(16),
///   physics: BouncingScrollPhysics(),
///   itemBuilder: (context, field, metadata) {
///     return Column(
///       children: [
///         field,
///         if (!metadata.isLast) Divider(height: 32),
///       ],
///     );
///   },
///   formKey: _formKey, // For form validation
///   validateMode: AutovalidateMode.onUserInteraction,
/// )
/// ```
///
/// ### Performance Considerations
/// - For long lists, use `SmartField.scrollable()` with lazy loading
/// - Consider using `AutovalidateMode.onUserInteraction` for better performance
/// - Avoid heavy computations in `itemBuilder` for each rebuild
///
/// ### Accessibility
/// - Form wrapper provides proper semantic grouping
/// - Fields maintain their individual accessibility properties
/// - Scrollable mode supports screen reader navigation
///
/// ### Error Handling
/// - Validators should return null for valid values, error strings for invalid
/// - Form validation state is managed when `formKey` is provided
/// - Individual field errors are displayed by their respective field widgets
/// 
/// See also:
/// - [FieldItem]
/// - [PasswordFieldItem]
/// - [PhoneFieldItem]
///
/// {@endtemplate}
class SmartField extends StatelessWidget {
  /// Whether the list of fields should be scrollable.
  /// 
  /// When `true`, wraps fields in a `SingleChildScrollView`.
  /// When `false` (default for `.builder` constructor), fields are rendered
  /// in a static `Column`.
  final bool isScrollable;

  /// The axis along which the list should scroll.
  /// 
  /// Only used when `isScrollable` is `true`.
  /// Defaults to `Axis.vertical`.
  final Axis? scrollDirection;

  /// Whether the scroll direction should be reversed.
  /// 
  /// Only used when `isScrollable` is `true`.
  final bool? reverse;

  /// The padding around the scrollable content.
  /// 
  /// Only used when `isScrollable` is `true`.
  final EdgeInsetsGeometry? padding;

  /// Whether to use the primary scroll controller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final bool? primary;

  /// The physics to apply to the scroller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final ScrollPhysics? physics;

  /// The scroll controller to use.
  /// 
  /// Only used when `isScrollable` is `true`.
  final ScrollController? controller;

  /// The drag start behavior for the scroller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final DragStartBehavior? dragStartBehavior;

  /// The clipping behavior of the scroller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final Clip? clipBehavior;

  /// The hit test behavior for the scroller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final HitTestBehavior? hitTestBehavior;

  /// The restoration ID for the scroller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final String? restorationId;

  /// The keyboard dismiss behavior for the scroller.
  /// 
  /// Only used when `isScrollable` is `true`.
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  /// A list of FieldItem objects representing the fields to be displayed.
  /// 
  /// Supports `FieldItem`, `PasswordFieldItem`, and `PhoneFieldItem` types.
  /// The list must contain at least one element.
  final List<FieldItem> items;

  /// The main axis alignment of the children in the column.
  final MainAxisAlignment? mainAxisAlignment;

  /// The cross axis alignment of the children in the column.
  final CrossAxisAlignment? crossAxisAlignment;

  /// The size constraint for the children in the main axis.
  final MainAxisSize? mainAxisSize;

  /// The text direction of the children.
  final TextDirection? textDirection;

  /// The vertical direction of the children.
  final VerticalDirection? verticalDirection;

  /// The text baseline of the children.
  final TextBaseline? textBaseline;

  /// The spacing between consecutive fields.
  /// 
  /// Applied as padding between each field widget.
  final double? spacing;

  /// A builder function that creates a widget for each FieldItem.
  /// 
  /// Receives:
  /// - `context`: The build context
  /// - `field`: The built Field widget (Field, PasswordField, or PhoneField)
  /// - `metadata`: ItemMetadata with position and field information
  /// 
  /// Allows custom wrapping or modification of each field.
  final JustFieldItemBuilder itemBuilder;

  /// Optional key for the Form widget that wraps the fields.
  /// 
  /// When provided, wraps all fields in a `Form` widget with validation
  /// and navigation guard capabilities.
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

  /// Creates a non-scrollable SmartField with a static layout.
  /// 
  /// Use this constructor for forms with a fixed number of fields that
  /// fit within the available screen space.
  /// 
  /// {@macro smart_field}
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

  /// Creates a scrollable SmartField for longer forms.
  /// 
  /// Use this constructor for forms that may not fit on screen and
  /// require scrolling to access all fields.
  /// 
  /// {@macro smart_field}
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

  Field _buildField(FieldItem field) {
    if (field case PasswordFieldItem password) {
      return PasswordField(
        label: password.label,
        hint: password.hint,
        onChanged: password.onChanged,
        validator: password.validator,
        keyboard: password.type,
        controller: password.controller,
        focus: password.focus,
        obscureText: password.obscureText,
        replaceHintWithLabel: password.replaceHintWithLabel,
        onVisibilityTapped: password.onVisibilityTapped,
      );
    }

    if (field case PhoneFieldItem phone) {
      return PhoneField(
        label: phone.label,
        hint: phone.hint,
        onChanged: phone.onChanged,
        validator: phone.validator,
        onPhoneSaved: phone.onPhoneSaved,
        controller: phone.controller,
        focus: phone.focus,
        obscureText: phone.obscureText,
        replaceHintWithLabel: phone.replaceHintWithLabel,
        onPhoneChanged: phone.onPhoneChanged,
        initialCountry: phone.initialCountry,
        countries: phone.countries,
        phoneValidator: phone.phoneValidator
      );
    }

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

  Widget _buildList(BuildContext context) {
    final children = items.asMap().entries.map((entry) {
      final index = entry.key;
      final field = entry.value;
      
      return itemBuilder(context, _buildField(field), ItemMetadata(
        isFirst: index.equals(0),
        isLast: index.equals(items.length - 1),
        index: index,
        totalItems: items.length,
        item: field,
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