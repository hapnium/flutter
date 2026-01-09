import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hapnium/hapnium.dart';
import 'package:meta/meta.dart';
import 'package:smart/src/styles/colors/common_colors.dart';
import 'package:smart/utilities.dart';

import '../text/text_builder.dart';
import '../typedefs.dart';
import 'field_controller.dart';
import 'models/field_decoration_config.dart';
import 'models/field_input_config.dart';
import 'password_field.dart';
import 'phone_field.dart';

/// {@template field}
/// A customizable, extensible text input field widget for Flutter applications.
///
/// The `Field` class provides a comprehensive text input solution with extensive
/// customization options, validation support, and controller management. It serves
/// as the base class for specialized input fields like [PasswordField] and [PhoneField].
///
/// ## Key Features
/// - **Extensive customization**: Control appearance, behavior, and validation
/// - **Controller management**: Built-in [FieldController] for state management
/// - **Validation**: Custom validators with multiple validation modes
/// - **Accessibility**: Full accessibility support including screen readers
/// - **Internationalization**: RTL support and locale-aware input
/// - **Security**: Secure text entry for passwords and sensitive data
/// - **Form integration**: Works seamlessly with Flutter's form system
///
/// ## Basic Usage
/// ```dart
/// // Simple text field
/// Field(
///   hint: 'Enter your name',
///   onChanged: (value) => print('Name: $value'),
/// )
///
/// // Field with validation
/// Field(
///   hint: 'Enter email',
///   validator: (value) => value?.contains('@') ?? false 
///       ? null 
///       : 'Invalid email',
///   modeValidator: AutovalidateMode.onUserInteraction,
/// )
///
/// // Field with custom styling
/// Field(
///   hint: 'Search...',
///   prefixIcon: Icon(Icons.search),
///   borderRadius: 20,
///   fillColor: Colors.grey[100],
/// )
/// ```
///
/// ## Controller Management
/// The field supports multiple controller types for different use cases:
/// ```dart
/// // TextEditingController for text management
/// final textController = TextEditingController();
/// Field(controller: textController)
///
/// // FieldController for advanced state management
/// final fieldController = FieldController();
/// Field(stateController: fieldController)
///
/// // Lifecycle callbacks
/// Field(
///   onInit: (controller) => print('Field initialized'),
///   onBind: (controller) => print('Field bound to widget'),
/// )
/// ```
///
/// ## Specialized Field Types
/// For specific input types, use the specialized subclasses:
/// ```dart
/// // Password input
/// PasswordField(
///   hint: 'Enter password',
///   obscureText: true,
/// )
///
/// // Phone number input
/// PhoneField(
///   hint: 'Enter phone number',
///   countryCode: '+1',
/// )
///
/// // Deprecated: Use PasswordField instead of Field.password()
/// // Field.password() is deprecated and will be removed
/// ```
///
/// ## Customization
/// The field can be customized through multiple mechanisms:
/// ```dart
/// // Using builders for dynamic configuration
/// Field(
///   inputDecorationBuilder: (config) => config.copyWith(
///     enabledBorder: OutlineInputBorder(
///       borderSide: BorderSide(color: Colors.blue),
///     ),
///   ),
///   inputConfigBuilder: (config) => config.copyWith(
///     textColor: Colors.black,
///     textSize: 16,
///   ),
/// )
///
/// // Direct property customization
/// Field(
///   cursorColor: Colors.red,
///   cursorWidth: 3,
///   cursorHeight: 20,
///   borderRadius: 10,
///   spacing: 8,
/// )
/// ```
///
/// ## Validation
/// Multiple validation strategies are supported:
/// ```dart
/// Field(
///   validator: (value) {
///     if (value == null || value.isEmpty) return 'Required';
///     if (value.length < 3) return 'Too short';
///     return null;
///   },
///   modeValidator: AutovalidateMode.onUserInteraction,
/// )
/// ```
///
/// ## Accessibility
/// The field includes comprehensive accessibility features:
/// ```dart
/// Field(
///   label: 'Username', // Used for screen readers
///   hint: 'Enter your username',
///   autofillHints: [AutofillHints.username],
///   textDirection: TextDirection.ltr,
///   keyboardAppearance: Brightness.light,
/// )
/// ```
///
/// ## Platform-Specific Features
/// ```dart
/// // iOS/Android specific features
/// Field(
///   enableIMEPersonalizedLearning: true,
///   stylusHandwritingEnabled: true,
///   selectionControls: materialTextSelectionControls,
///   contextMenuBuilder: buildAdaptiveTextSelectionToolbar,
/// )
/// ```
///
/// ## Layout Options
/// ```dart
/// // Standard field
/// Field(hint: 'Standard field')
///
/// // Large multi-line field
/// Field(
///   hint: 'Large text area',
///   useBigField: true,
///   maxLines: 10,
///   minLines: 3,
/// )
///
/// // OTP-style single character field
/// Field(
///   useOtpDesign: true,
///   maxLines: 1,
///   textAlign: TextAlign.center,
/// )
///
/// // Field with label above
/// Field(
///   label: 'Full Name',
///   hint: 'Enter your full name',
///   needLabel: true,
///   spacing: 4,
/// )
/// ```
///
/// ## Event Handling
/// ```dart
/// Field(
///   onChanged: (value) => print('Value changed: $value'),
///   onEditingComplete: () => print('Editing complete'),
///   onFieldSubmitted: (value) => print('Submitted: $value'),
///   onTapOutside: (event) => print('Tapped outside'),
///   onSaved: (value) => print('Saved: $value'),
/// )
/// ```
///
/// ## Input Formatting
/// ```dart
/// // Format phone numbers
/// Field(
///   inputFormatters: [
///     FilteringTextInputFormatter.digitsOnly,
///     LengthLimitingTextInputFormatter(10),
///     PhoneNumberFormatter(),
///   ],
/// )
///
/// // Format currency
/// Field(
///   inputFormatters: [
///     FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
///     CurrencyInputFormatter(),
///   ],
/// )
/// ```
///
/// ## State Management
/// The field integrates with various state management approaches:
/// ```dart
/// // Using FieldController
/// class MyForm extends StatefulWidget {
///   @override
///   _MyFormState createState() => _MyFormState();
/// }
///
/// class _MyFormState extends State<MyForm> {
///   final _fieldController = FieldController();
///   final _formKey = GlobalKey<FormState>();
///
///   @override
///   Widget build(BuildContext context) {
///     return Form(
///       key: _formKey,
///       child: Column(
///         children: [
///           Field(
///             stateController: _fieldController,
///             validator: _validateField,
///             onInit: (controller) => _setupController(controller),
///           ),
///           ElevatedButton(
///             onPressed: _submitForm,
///             child: Text('Submit'),
///           ),
///         ],
///       ),
///     );
///   }
///
///   void _submitForm() {
///     if (_formKey.currentState!.validate()) {
///       // Process form data
///     }
///   }
/// }
/// ```
///
/// ## Performance Considerations
/// - The widget is stateless for optimal performance
/// - ListenableBuilder is used for efficient rebuilds
/// - Controllers are managed to prevent memory leaks
/// - Large text fields use appropriate scroll physics
///
/// ## Best Practices
/// 1. Always provide appropriate `hint` or `label` for accessibility
/// 2. Use `validator` for input validation with user-friendly messages
/// 3. Set `autovalidateMode` based on your UX requirements
/// 4. Use `onChanged` for real-time validation or filtering
/// 5. Provide `autofillHints` for better user experience on mobile
/// 6. Consider using `copyWith()` for creating variations of fields
/// 7. Use specialized subclasses ([PasswordField], [PhoneField]) when appropriate
///
/// ## Common Pitfalls
/// - Forgetting to set `needLabel: true` when using labels
/// - Not handling `onTapOutside` to dismiss keyboard on mobile
/// - Overusing `autofocus` in forms with multiple fields
/// - Not providing appropriate `textInputAction` for form flow
/// - Ignoring `enabled` state when field should be disabled
///
/// ## Migration Notes
/// - `Field.password()` factory constructor is deprecated - use [PasswordField] instead
/// - Always check for null values in validators
/// - Test RTL layouts when using custom text directions
/// - Verify accessibility with screen readers
///
/// ## See Also
/// - [PasswordField] for password input fields
/// - [PhoneField] for phone number input fields
/// - [FieldController] for advanced field state management
/// - [FieldDecorationConfig] for border and decoration customization
/// - [FieldInputConfig] for text and styling customization
/// {@endtemplate}
base class Field extends StatelessWidget {
  /// Controller for advanced field state management and validation.
  ///
  /// Provides programmatic control over the field's state, validation,
  /// and lifecycle. When provided, the field integrates with the controller
  /// for state synchronization and validation events.
  ///
  /// ## Example
  /// ```dart
  /// final controller = FieldController();
  /// Field(stateController: controller)
  /// ```
  final FieldController? stateController;

  /// Called when the field controller is first initialized.
  ///
  /// This callback provides early access to the [FieldController] before
  /// the widget is built. Useful for setting up initial state or
  /// registering listeners.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   onInit: (controller) {
  ///     controller.addListener(() => print('Field state changed'));
  ///     controller.setValue('Initial value');
  ///   },
  /// )
  /// ```
  final FieldControllerValue? onInit;

  /// Called when the field is bound to the widget tree.
  ///
  /// Provides access to the [FieldController] after the widget is built
  /// and ready for interaction. Useful for post-build initialization.
  final FieldControllerValue? onBind;

  /// Controls the text being edited in the field.
  ///
  /// If null, a local [TextEditingController] is created automatically.
  /// Reuse controllers when you need to manage text across widget rebuilds.
  ///
  /// ## Example
  /// ```dart
  /// final controller = TextEditingController(text: 'Initial text');
  /// Field(controller: controller)
  /// ```
  final TextEditingController? controller;

  /// Controls the scroll position of the field.
  ///
  /// Useful for programmatically scrolling multi-line fields or
  /// implementing custom scroll behaviors.
  final ScrollController? scrollController;

  /// Controls the visual states of the field (hovered, focused, pressed).
  ///
  /// Allows customizing the field's appearance based on interaction states.
  final WidgetStatesController? statesController;

  /// Called when the user submits the content of the field.
  ///
  /// Typically triggered by the "done" action on the keyboard or when
  /// the user explicitly submits the form.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   onEditingComplete: () => print('Editing completed'),
  ///   inputAction: TextInputAction.done,
  /// )
  /// ```
  final VoidCallback? onEditingComplete;

  /// Called when the user taps outside the field.
  ///
  /// Useful for dismissing the keyboard or performing actions when
  /// the user taps elsewhere on the screen.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   onTapOutside: (event) => FocusScope.of(context).unfocus(),
  /// )
  /// ```
  final TapRegionCallback? onTapOutside;

  /// Called when the user submits the field value.
  ///
  /// Similar to [onEditingComplete] but provides the submitted value.
  /// Typically used in forms for processing individual field submissions.
  final Consumer<String>? onFieldSubmitted;

  /// Validates the field's current value.
  ///
  /// Returns an error message if validation fails, or null if valid.
  /// Used with [modeValidator] to control when validation occurs.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   validator: (value) {
  ///     if (value == null || value.isEmpty) return 'Required field';
  ///     if (value.length < 3) return 'Minimum 3 characters';
  ///     return null;
  ///   },
  /// )
  /// ```
  final FieldValidator? validator;

  /// Called whenever the text in the field changes.
  ///
  /// Provides real-time updates as the user types. Useful for live
  /// validation, search-as-you-type, or character counting.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   onChanged: (value) => print('Current value: $value'),
  /// )
  /// ```
  final Consumer<String>? onChanged;

  /// Controls whether this field has keyboard focus.
  ///
  /// Use to programmatically control focus or manage focus traversal
  /// between multiple fields in a form.
  ///
  /// ## Example
  /// ```dart
  /// final focusNode = FocusNode();
  /// Field(focus: focusNode)
  /// ```
  final FocusNode? focus;

  /// The action button to display on the keyboard.
  ///
  /// Controls which action appears in the keyboard's action area
  /// (e.g., "Next", "Done", "Search"). Also affects focus traversal.
  ///
  /// Defaults to [TextInputAction.next].
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   inputAction: TextInputAction.search,
  ///   onFieldSubmitted: (value) => performSearch(value),
  /// )
  /// ```
  final TextInputAction inputAction;

  /// The type of keyboard to display for text input.
  ///
  /// Controls which keyboard layout appears (text, number, email, etc.).
  /// Also affects input validation on some platforms.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   keyboard: TextInputType.emailAddress,
  ///   hint: 'Enter email',
  /// )
  /// ```
  final TextInputType? keyboard;

  /// Placeholder text displayed when the field is empty.
  ///
  /// Provides guidance to the user about what to enter. If [replaceHintWithLabel]
  /// is true and [label] is provided, the hint is replaced by the label.
  ///
  /// ## Accessibility
  /// Screen readers announce hints, so ensure they're descriptive.
  final String? hint;

  /// Label text displayed above or as part of the field.
  ///
  /// When [needLabel] is true, displays as a separate label above the field.
  /// Otherwise, may replace the hint based on [replaceHintWithLabel].
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   label: 'Username',
  ///   hint: 'Enter your username',
  ///   needLabel: true,
  ///   spacing: 4,
  /// )
  /// ```
  final String? label;

  /// Height of the text cursor in logical pixels.
  ///
  /// Defaults to the font size of the text being edited.
  final double? cursorHeight;

  /// Radius of the field's border corners.
  ///
  /// Controls the rounded corners of the input border. Defaults to 14.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   borderRadius: 20, // More rounded corners
  ///   fillColor: Colors.white,
  /// )
  /// ```
  final double? borderRadius;

  /// Spacing between label and field when [needLabel] is true.
  ///
  /// Controls the vertical gap between the label and the input field.
  /// Defaults to 3 when not specified.
  final double? spacing;

  /// Width of the text cursor in logical pixels.
  ///
  /// Defaults to 2.0. Set to 0.0 to hide the cursor.
  final double cursorWidth;

  /// Widget displayed after the input area.
  ///
  /// Commonly used for action buttons (clear, visibility toggle),
  /// indicators, or decorative icons.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   suffixIcon: IconButton(
  ///     icon: Icon(Icons.clear),
  ///     onPressed: () => controller.clear(),
  ///   ),
  /// )
  /// ```
  final Widget? suffixIcon;

  /// Widget displayed before the input area.
  ///
  /// Commonly used for decorative icons, currency symbols, or
  /// country code indicators.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   prefixIcon: Icon(Icons.search),
  ///   hint: 'Search...',
  /// )
  /// ```
  final Widget? prefixIcon;

  /// Background color of the input area.
  ///
  /// When null, defaults to the theme's scaffold background color.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   fillColor: Colors.grey[100],
  ///   hint: 'Search...',
  /// )
  /// ```
  final Color? fillColor;

  /// Color of the text cursor.
  ///
  /// When null, defaults to [inputConfig.textColor] or theme primary color.
  final Color? cursorColor;

  /// Color of the text cursor when the field has an error.
  ///
  /// Provides visual feedback for invalid input.
  final Color? cursorErrorColor;

  /// Constraints applied to the suffix icon.
  ///
  /// Controls the size and layout of the suffix icon widget.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   suffixIconConstraints: BoxConstraints(
  ///     minWidth: 40,
  ///     minHeight: 40,
  ///   ),
  ///   suffixIcon: Icon(Icons.search),
  /// )
  /// ```
  final BoxConstraints? suffixIconConstraints;

  /// Constraints applied to the prefix icon.
  ///
  /// Controls the size and layout of the prefix icon widget.
  final BoxConstraints? prefixIconConstraints;

  /// Whether to use a larger, multi-line field style.
  ///
  /// When true, enables multi-line input with appropriate styling
  /// for larger text areas (comments, descriptions, etc.).
  ///
  /// Defaults to false.
  final bool useBigField;

  /// Whether the field is enabled for user input.
  ///
  /// When false, the field appears disabled (greyed out) and doesn't
  /// respond to user input.
  final bool? enabled;

  /// Whether to display a separate label above the field.
  ///
  /// When true, [label] is displayed above the field with [spacing]
  /// between them. Requires either [label] or [hint] to be provided.
  ///
  /// Defaults to false.
  final bool needLabel;

  /// Whether to obscure the entered text.
  ///
  /// Typically used for password fields to hide sensitive input.
  /// For password fields, use [PasswordField] instead.
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Whether to use OTP (One-Time Password) field design.
  ///
  /// When true, formats the field for single character input with
  /// center alignment, typically used for verification codes.
  ///
  /// Defaults to false.
  final bool useOtpDesign;

  /// Whether to replace the hint text with the label when focused.
  ///
  /// When true and [label] is provided, the hint is replaced by
  /// the label when the field is focused or has content.
  ///
  /// Defaults to true.
  final bool replaceHintWithLabel;

  /// Whether this field should request focus when first displayed.
  ///
  /// Useful for the first field in a form or search interfaces.
  /// Use sparingly to avoid surprising users.
  ///
  /// Defaults to false.
  final bool autofocus;

  /// Whether to ignore pointer events on this field.
  ///
  /// When true, the field doesn't respond to taps or gestures.
  /// Useful for read-only fields that display data.
  final bool? ignorePointers;

  /// Whether to enable text selection and editing gestures.
  ///
  /// When false, disables text selection, copy/paste, and other
  /// editing interactions. Useful for read-only display fields.
  final bool? enableInteractiveSelection;

  /// Whether to enable personalized learning for IME (Input Method Editor).
  ///
  /// Allows the keyboard to learn from user input patterns to provide
  /// better suggestions. Consider privacy implications.
  ///
  /// Defaults to true.
  final bool enableIMEPersonalizedLearning;

  /// Whether the cursor opacity animates when fading in and out.
  ///
  /// Controls the fade animation of the text cursor.
  final bool? cursorOpacityAnimates;

  /// Whether to enable stylus handwriting input.
  ///
  /// Enables support for handwriting recognition with stylus input
  /// on supported devices.
  ///
  /// Defaults to true.
  final bool stylusHandwritingEnabled;

  /// Whether this field can request keyboard focus.
  ///
  /// When false, the field cannot receive focus via tap or tab.
  /// Useful for decorative or disabled fields.
  ///
  /// Defaults to true.
  final bool canRequestFocus;

  /// Padding inside the input area around the text.
  ///
  /// Controls the spacing between the text and the field's borders.
  /// When null, uses default padding based on field type.
  final EdgeInsets? padding;

  /// Padding that surrounds the scrollable when the keyboard is displayed.
  ///
  /// Prevents the field from being obscured by the keyboard.
  ///
  /// Defaults to EdgeInsets.all(20.0).
  final EdgeInsets scrollPadding;

  /// How the text should be aligned vertically.
  ///
  /// Useful for multi-line fields or fields with custom height.
  /// When [useBigField] is true, defaults to [TextAlignVertical.center].
  final TextAlignVertical? textAlignVertical;

  /// How to capitalize text as the user types.
  ///
  /// When [useBigField] is true, defaults to [TextCapitalization.sentences].
  /// Otherwise defaults to [TextCapitalization.none].
  final TextCapitalization? textCapitalization;

  /// When to automatically validate the field.
  ///
  /// Controls the timing of automatic validation calls.
  /// When null, defaults to [AutovalidateMode.onUserInteraction].
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   modeValidator: AutovalidateMode.always,
  ///   validator: validateEmail,
  /// )
  /// ```
  final AutovalidateMode? modeValidator;

  /// Maximum number of lines for the text to span.
  ///
  /// When [useBigField] is true, defaults to 20.
  /// Otherwise defaults to 1.
  final int? maxLines;

  /// Minimum number of lines for the text to span.
  ///
  /// Only effective when [maxLines] is greater than 1.
  /// When [useBigField] is true, defaults to 5.
  final int? minLines;

  /// Formatters to apply to the text as it's being edited.
  ///
  /// Useful for formatting phone numbers, currency, dates, or
  /// enforcing input patterns.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   inputFormatters: [
  ///     FilteringTextInputFormatter.digitsOnly,
  ///     LengthLimitingTextInputFormatter(10),
  ///   ],
  ///   hint: 'Enter phone number',
  /// )
  /// ```
  final List<TextInputFormatter>? inputFormatters;

  /// Builder for customizing the field's visual decoration.
  ///
  /// Provides complete control over borders, colors, and other
  /// visual aspects of the field.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   inputDecorationBuilder: (config) => config.copyWith(
  ///     enabledBorder: OutlineInputBorder(
  ///       borderRadius: BorderRadius.circular(10),
  ///       borderSide: BorderSide(color: Colors.blue),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FieldDecorationConfigBuilder? inputDecorationBuilder;

  /// Builder for customizing the field's input configuration.
  ///
  /// Provides control over text styling, colors, and other
  /// input-related properties.
  final FieldInputConfigBuilder? inputConfigBuilder;

  /// The directionality of the text.
  ///
  /// Useful for RTL (Right-to-Left) languages or mixed-direction text.
  final TextDirection? textDirection;

  /// How the text should be aligned horizontally.
  ///
  /// When [useOtpDesign] is true, defaults to [TextAlign.center].
  /// Otherwise defaults to [TextAlign.start].
  final TextAlign? textAlign;

  /// The radius of the corners of the cursor.
  ///
  /// Controls the rounded corners of the text cursor.
  final Radius? cursorRadius;

  /// The appearance of the keyboard.
  ///
  /// Controls whether the keyboard uses light or dark theme.
  /// Should match your app's theme for consistency.
  final Brightness? keyboardAppearance;

  /// Builds the text selection toolbar and handles.
  ///
  /// Customize the selection menu that appears when text is selected.
  /// Typically uses platform-appropriate controls.
  final TextSelectionControls? selectionControls;

  /// Builds a custom counter widget below the field.
  ///
  /// Useful for character counting or displaying validation info.
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   buildCounter: (context, {currentLength, isFocused, maxLength}) {
  ///     return Text('$currentLength / $maxLength');
  ///   },
  /// )
  /// ```
  final InputCounterWidgetBuilder? buildCounter;

  /// The physics for the scrollable viewport.
  ///
  /// Controls scrolling behavior for multi-line fields.
  final ScrollPhysics? scrollPhysics;

  /// Hints for the autofill service.
  ///
  /// Helps the platform's autofill service suggest appropriate data
  /// (names, addresses, passwords, etc.).
  ///
  /// ## Example
  /// ```dart
  /// Field(
  ///   autofillHints: [AutofillHints.email],
  ///   hint: 'Enter email',
  /// )
  /// ```
  final Iterable<String>? autofillHints;

  /// The cursor for mouse pointers when hovering over the field.
  ///
  /// Customizes the mouse cursor appearance on desktop platforms.
  final MouseCursor? mouseCursor;

  /// Builds the context menu for text selection and editing.
  ///
  /// Customizes the menu that appears on right-click or long-press.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Configuration for spell check functionality.
  ///
  /// Controls whether and how spell checking is performed.
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Configuration for text magnifier functionality.
  ///
  /// Controls the magnifier that appears during text selection.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Controller for undo/redo history.
  ///
  /// Manages the undo/redo stack for text editing operations.
  final UndoHistoryController? undoController;

  /// Called when the IME sends app-private commands.
  ///
  /// Handles special commands from input methods.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// Defines how the selection highlight's height is calculated.
  ///
  /// Controls the visual appearance of selected text.
  ///
  /// Defaults to [ui.BoxHeightStyle.tight].
  final ui.BoxHeightStyle selectionHeightStyle;

  /// Defines how the selection highlight's width is calculated.
  ///
  /// Controls the visual appearance of selected text.
  ///
  /// Defaults to [ui.BoxWidthStyle.tight].
  final ui.BoxWidthStyle selectionWidthStyle;

  /// Determines when a drag start behavior is recognized.
  ///
  /// Affects scrolling and text selection drag gestures.
  ///
  /// Defaults to [DragStartBehavior.start].
  final DragStartBehavior dragStartBehavior;

  /// Configuration for content insertion features.
  ///
  /// Controls features like drag-and-drop and paste functionality.
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// How to clip the field's contents.
  ///
  /// Controls whether content is clipped to the field's bounds.
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Called when the form is saved.
  ///
  /// Part of Flutter's form system. Called when Form.save() is invoked.
  final FormFieldSetter<String>? onSaved;

  /// How children are aligned horizontally in the column when [needLabel] is true.
  ///
  /// Controls alignment of label relative to the input field.
  final CrossAxisAlignment? crossAxisAlignment;

  /// Whether to enable auto-correction.
  ///
  /// When true, the platform may suggest corrections for misspelled words.
  ///
  /// Defaults to true for regular fields, false for password fields.
  final bool autoCorrect;

  /// How to enforce the maximum length limit.
  ///
  /// Controls whether input beyond max length is truncated or rejected.
  final MaxLengthEnforcement? maxLengthEnforcement;

  final InputDecoration? inputDecoration;

  /// {@macro field}
  const Field({
    super.key,
    this.controller,
    this.stateController,
    this.onInit,
    this.onBind,
    this.enabled,
    this.focus,
    this.inputAction = TextInputAction.next,
    this.keyboard,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.hint,
    this.suffixIcon,
    this.prefixIcon,
    this.borderRadius,
    this.useOtpDesign = false,
    this.fillColor,
    this.suffixIconConstraints,
    this.useBigField = false,
    this.needLabel = false,
    this.padding,
    this.label,
    this.spacing,
    this.inputConfigBuilder,
    this.cursorColor,
    this.cursorErrorColor,
    this.cursorHeight,
    this.prefixIconConstraints,
    this.modeValidator,
    this.textAlignVertical,
    this.textCapitalization,
    this.textAlign,
    this.textDirection,
    this.keyboardAppearance,
    this.selectionControls,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints,
    this.mouseCursor,
    this.contextMenuBuilder,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.undoController,
    this.onAppPrivateCommand,
    this.scrollController,
    this.statesController,
    this.onEditingComplete,
    this.onTapOutside,
    this.onFieldSubmitted,
    this.replaceHintWithLabel = true,
    this.ignorePointers,
    this.enableInteractiveSelection,
    this.cursorOpacityAnimates,
    this.maxLines,
    this.minLines,
    this.inputFormatters,
    this.inputDecorationBuilder,
    this.cursorRadius,
    this.contentInsertionConfiguration,
    this.crossAxisAlignment,
    this.onSaved,
    this.cursorWidth = 2.0,
    this.autofocus = false,
    this.enableIMEPersonalizedLearning = true,
    this.stylusHandwritingEnabled = true,
    this.canRequestFocus = true,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.autoCorrect = true,
    this.maxLengthEnforcement,
    this.inputDecoration
  });

  /// Deprecated: Use [PasswordField] instead.
  @Deprecated('Use PasswordField instead. This will be removed in future versions.')
  factory Field.password({
    Key? key,
    TextEditingController? controller,
    bool? enabled,
    bool obscureText = true,
    FieldValidator? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    VoidCallback? onPressed,
    IconData? icon,
    TextInputAction inputAction = TextInputAction.next,
    TextInputType? keyboard,
    Consumer<String>? onChanged,
    FocusNode? focus,
    double? iconSize,
    double? borderRadius,
    bool useOtpDesign = false,
    Color? fillColor,
    BoxConstraints? suffixIconConstraints,
    bool useBigField = false,
    bool needLabel = false,
    EdgeInsets? padding,
    String? label,
    String? hint,
    double? spacing,
    FieldInputConfigBuilder? inputConfigBuilder,
    Color? iconColor,
    Color? cursorColor,
    Color? cursorErrorColor,
    double? cursorHeight,
    BoxConstraints? prefixIconConstraints,
    AutovalidateMode? modeValidator,
    TextAlignVertical? textAlignVertical,
    TextCapitalization? textCapitalization,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Brightness? keyboardAppearance,
    TextSelectionControls? selectionControls,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    MouseCursor? mouseCursor,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    SpellCheckConfiguration? spellCheckConfiguration,
    TextMagnifierConfiguration? magnifierConfiguration,
    UndoHistoryController? undoController,
    AppPrivateCommandCallback? onAppPrivateCommand,
    ScrollController? scrollController,
    WidgetStatesController? statesController,
    VoidCallback? onEditingComplete,
    TapRegionCallback? onTapOutside,
    Consumer<String>? onFieldSubmitted,
    bool replaceHintWithLabel = true,
    bool? ignorePointers,
    bool? enableInteractiveSelection,
    bool? cursorOpacityAnimates,
    int? maxLines = 1,
    int? minLines,
    List<TextInputFormatter>? inputFormatters,
    FieldDecorationConfigBuilder? inputDecorationBuilder,
    Radius? cursorRadius,
    ContentInsertionConfiguration? contentInsertionConfiguration,
    FormFieldSetter<String>? onSaved,
    CrossAxisAlignment? crossAxisAlignment,
    double cursorWidth = 2.0,
    bool autofocus = false,
    bool enableIMEPersonalizedLearning = true,
    bool stylusHandwritingEnabled = true,
    bool canRequestFocus = true,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    Clip clipBehavior = Clip.hardEdge,
    bool autoCorrect = false,
    MaxLengthEnforcement? maxLengthEnforcement,
    double? iconSplashRadius,
    Color? iconButtonColor,
    Color? iconSplashColor,
  }) {
    return PasswordField(
      key: key,
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      visibleIcon: icon,
      inputAction: inputAction,
      keyboard: keyboard,
      onChanged: onChanged,
      focus: focus,
      iconSize: iconSize,
      borderRadius: borderRadius,
      useOtpDesign: useOtpDesign,
      fillColor: fillColor,
      suffixIconConstraints: suffixIconConstraints,
      useBigField: useBigField,
      needLabel: needLabel,
      padding: padding,
      label: label,
      hint: hint,
      spacing: spacing,
      inputConfigBuilder: inputConfigBuilder,
      iconColor: iconColor,
      cursorColor: cursorColor,
      cursorErrorColor: cursorErrorColor,
      cursorHeight: cursorHeight,
      prefixIconConstraints: prefixIconConstraints,
      modeValidator: modeValidator,
      textAlignVertical: textAlignVertical,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      textDirection: textDirection,
      keyboardAppearance: keyboardAppearance,
      selectionControls: selectionControls,
      buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      mouseCursor: mouseCursor,
      contextMenuBuilder: contextMenuBuilder,
      spellCheckConfiguration: spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration,
      undoController: undoController,
      onAppPrivateCommand: onAppPrivateCommand,
      scrollController: scrollController,
      statesController: statesController,
      onEditingComplete: onEditingComplete,
      onTapOutside: onTapOutside,
      onFieldSubmitted: onFieldSubmitted,
      replaceHintWithLabel: replaceHintWithLabel,
      ignorePointers: ignorePointers,
      enableInteractiveSelection: enableInteractiveSelection,
      cursorOpacityAnimates: cursorOpacityAnimates,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      inputDecorationBuilder: inputDecorationBuilder,
      cursorRadius: cursorRadius,
      contentInsertionConfiguration: contentInsertionConfiguration,
      onSaved: onSaved,
      crossAxisAlignment: crossAxisAlignment,
      cursorWidth: cursorWidth,
      autofocus: autofocus,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      stylusHandwritingEnabled: stylusHandwritingEnabled,
      canRequestFocus: canRequestFocus,
      scrollPadding: scrollPadding,
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
      dragStartBehavior: dragStartBehavior,
      clipBehavior: clipBehavior,
      autoCorrect: autoCorrect,
      maxLengthEnforcement: maxLengthEnforcement,
      iconSplashRadius: iconSplashRadius,
      iconButtonColor: iconButtonColor,
      iconSplashColor: iconSplashColor,
    );
  }

  /// {@macro field}
  const Field._internal({
    super.key,
    required this.stateController,
    required this.onInit,
    required this.onBind,
    required this.controller,
    required this.scrollController,
    required this.statesController,
    required this.onEditingComplete,
    required this.onTapOutside,
    required this.onFieldSubmitted,
    required this.validator,
    required this.onChanged,
    required this.focus,
    required this.inputAction,
    required this.keyboard,
    required this.hint,
    required this.label,
    required this.cursorHeight,
    required this.borderRadius,
    required this.spacing,
    required this.cursorWidth,
    required this.suffixIcon,
    required this.prefixIcon,
    required this.fillColor,
    required this.cursorColor,
    required this.cursorErrorColor,
    required this.suffixIconConstraints,
    required this.prefixIconConstraints,
    required this.useBigField,
    required this.enabled,
    required this.needLabel,
    required this.obscureText,
    required this.useOtpDesign,
    required this.replaceHintWithLabel,
    required this.autofocus,
    required this.ignorePointers,
    required this.enableInteractiveSelection,
    required this.enableIMEPersonalizedLearning,
    required this.cursorOpacityAnimates,
    required this.stylusHandwritingEnabled,
    required this.canRequestFocus,
    required this.padding,
    required this.scrollPadding,
    required this.textAlignVertical,
    required this.textCapitalization,
    required this.modeValidator,
    required this.maxLines,
    required this.minLines,
    required this.inputFormatters,
    required this.inputDecorationBuilder,
    required this.inputConfigBuilder,
    required this.textDirection,
    required this.textAlign,
    required this.cursorRadius,
    required this.keyboardAppearance,
    required this.selectionControls,
    required this.buildCounter,
    required this.scrollPhysics,
    required this.autofillHints,
    required this.mouseCursor,
    required this.contextMenuBuilder,
    required this.spellCheckConfiguration,
    required this.magnifierConfiguration,
    required this.undoController,
    required this.onAppPrivateCommand,
    required this.selectionHeightStyle,
    required this.selectionWidthStyle,
    required this.dragStartBehavior,
    required this.contentInsertionConfiguration,
    required this.clipBehavior,
    required this.onSaved,
    required this.crossAxisAlignment,
    required this.autoCorrect,
    required this.maxLengthEnforcement,
    required this.inputDecoration
  });

  /// {@template field_copyWith}
  /// Creates a copy of this field with updated properties.
  ///
  /// This method follows the immutable pattern, returning a new [Field]
  /// instance with specified properties replaced while keeping all other
  /// properties unchanged from the original.
  ///
  /// ## Parameters
  /// All parameters are optional. When a parameter is provided, its value
  /// replaces the corresponding property in the new instance. When null,
  /// the original value is preserved.
  ///
  /// ## Returns
  /// A new [Field] instance with the updated properties.
  ///
  /// ## Example
  /// ```dart
  /// // Create a base field
  /// final baseField = Field(
  ///   hint: 'Search...',
  ///   prefixIcon: Icon(Icons.search),
  ///   borderRadius: 10,
  /// );
  ///
  /// // Create a disabled version
  /// final disabledField = baseField.copyWith(
  ///   hint: 'Search (disabled)',
  ///   enabled: false,
  ///   fillColor: Colors.grey[200],
  /// );
  ///
  /// // Create an OTP-style variant
  /// final otpField = baseField.copyWith(
  ///   useOtpDesign: true,
  ///   maxLines: 1,
  ///   textAlign: TextAlign.center,
  ///   borderRadius: 8,
  /// );
  ///
  /// // Create a large text area variant
  /// final textArea = baseField.copyWith(
  ///   useBigField: true,
  ///   hint: 'Enter description...',
  ///   maxLines: 10,
  ///   minLines: 3,
  /// );
  /// ```
  ///
  /// ## Use Cases
  /// - Creating theme variations of fields
  /// - Building field variants for different form sections
  /// - Implementing field states (enabled/disabled, error/normal)
  /// - Creating specialized fields from a base configuration
  /// - Maintaining consistency while allowing customization
  ///
  /// ## Performance
  /// Since [Field] is immutable, `copyWith` creates a new instance efficiently
  /// by sharing unchanged properties between instances.
  /// {@endtemplate}
  Field copyWith({
    TextEditingController? controller,
    FieldController? stateController,
    FieldControllerValue? onInit,
    FieldControllerValue? onBind,
    ScrollController? scrollController,
    WidgetStatesController? statesController,
    VoidCallback? onEditingComplete,
    TapRegionCallback? onTapOutside,
    Consumer<String>? onFieldSubmitted,
    FieldValidator? validator,
    Consumer<String>? onChanged,
    FocusNode? focus,
    TextInputAction? inputAction,
    TextInputType? keyboard,
    String? hint,
    String? label,
    double? cursorHeight,
    double? borderRadius,
    double? spacing,
    double? cursorWidth,
    Widget? suffixIcon,
    Widget? prefixIcon,
    Color? fillColor,
    Color? cursorColor,
    Color? cursorErrorColor,
    BoxConstraints? suffixIconConstraints,
    BoxConstraints? prefixIconConstraints,
    bool? useBigField,
    bool? enabled,
    bool? needLabel,
    bool? obscureText,
    bool? useOtpDesign,
    bool? replaceHintWithLabel,
    bool? autofocus,
    bool? ignorePointers,
    bool? enableInteractiveSelection,
    bool? enableIMEPersonalizedLearning,
    bool? cursorOpacityAnimates,
    bool? stylusHandwritingEnabled,
    bool? canRequestFocus,
    EdgeInsets? padding,
    EdgeInsets? scrollPadding,
    TextAlignVertical? textAlignVertical,
    TextCapitalization? textCapitalization,
    AutovalidateMode? modeValidator,
    int? maxLines,
    int? minLines,
    List<TextInputFormatter>? inputFormatters,
    FieldDecorationConfigBuilder? inputDecorationBuilder,
    FieldInputConfigBuilder? inputConfigBuilder,
    TextDirection? textDirection,
    TextAlign? textAlign,
    Radius? cursorRadius,
    Brightness? keyboardAppearance,
    TextSelectionControls? selectionControls,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    MouseCursor? mouseCursor,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    SpellCheckConfiguration? spellCheckConfiguration,
    TextMagnifierConfiguration? magnifierConfiguration,
    UndoHistoryController? undoController,
    AppPrivateCommandCallback? onAppPrivateCommand,
    ui.BoxHeightStyle? selectionHeightStyle,
    ui.BoxWidthStyle? selectionWidthStyle,
    DragStartBehavior? dragStartBehavior,
    ContentInsertionConfiguration? contentInsertionConfiguration,
    Clip? clipBehavior,
    FormFieldSetter<String>? onSaved,
    CrossAxisAlignment? crossAxisAlignment,
    bool? autoCorrect,
    MaxLengthEnforcement? maxLengthEnforcement,
    InputDecoration? inputDecoration
  }) {
    return Field._internal(
      key: key,
      controller: controller ?? this.controller,
      stateController: stateController ?? this.stateController,
      onInit: onInit ?? this.onInit,
      onBind: onBind ?? this.onBind,
      scrollController: scrollController ?? this.scrollController,
      statesController: statesController ?? this.statesController,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      onFieldSubmitted: onFieldSubmitted ?? this.onFieldSubmitted,
      validator: validator ?? this.validator,
      onChanged: onChanged ?? this.onChanged,
      focus: focus ?? this.focus,
      inputAction: inputAction ?? this.inputAction,
      keyboard: keyboard ?? this.keyboard,
      hint: hint ?? this.hint,
      label: label ?? this.label,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      borderRadius: borderRadius ?? this.borderRadius,
      spacing: spacing ?? this.spacing,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      fillColor: fillColor ?? this.fillColor,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorErrorColor: cursorErrorColor ?? this.cursorErrorColor,
      suffixIconConstraints: suffixIconConstraints ?? this.suffixIconConstraints,
      prefixIconConstraints: prefixIconConstraints ?? this.prefixIconConstraints,
      useBigField: useBigField ?? this.useBigField,
      enabled: enabled ?? this.enabled,
      needLabel: needLabel ?? this.needLabel,
      obscureText: obscureText ?? this.obscureText,
      useOtpDesign: useOtpDesign ?? this.useOtpDesign,
      replaceHintWithLabel: replaceHintWithLabel ?? this.replaceHintWithLabel,
      autofocus: autofocus ?? this.autofocus,
      ignorePointers: ignorePointers ?? this.ignorePointers,
      enableInteractiveSelection: enableInteractiveSelection ?? this.enableInteractiveSelection,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning ?? this.enableIMEPersonalizedLearning,
      cursorOpacityAnimates: cursorOpacityAnimates ?? this.cursorOpacityAnimates,
      stylusHandwritingEnabled: stylusHandwritingEnabled ?? this.stylusHandwritingEnabled,
      canRequestFocus: canRequestFocus ?? this.canRequestFocus,
      padding: padding ?? this.padding,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      textAlignVertical: textAlignVertical ?? this.textAlignVertical,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      modeValidator: modeValidator ?? this.modeValidator,
      maxLines: maxLines ?? this.maxLines,
      minLines: minLines ?? this.minLines,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      inputDecorationBuilder: inputDecorationBuilder ?? this.inputDecorationBuilder,
      inputConfigBuilder: inputConfigBuilder ?? this.inputConfigBuilder,
      textDirection: textDirection ?? this.textDirection,
      textAlign: textAlign ?? this.textAlign,
      cursorRadius: cursorRadius ?? this.cursorRadius,
      keyboardAppearance: keyboardAppearance ?? this.keyboardAppearance,
      selectionControls: selectionControls ?? this.selectionControls,
      buildCounter: buildCounter ?? this.buildCounter,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      autofillHints: autofillHints ?? this.autofillHints,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
      spellCheckConfiguration: spellCheckConfiguration ?? this.spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration ?? this.magnifierConfiguration,
      undoController: undoController ?? this.undoController,
      onAppPrivateCommand: onAppPrivateCommand ?? this.onAppPrivateCommand,
      selectionHeightStyle: selectionHeightStyle ?? this.selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle ?? this.selectionWidthStyle,
      dragStartBehavior: dragStartBehavior ?? this.dragStartBehavior,
      contentInsertionConfiguration: contentInsertionConfiguration ?? this.contentInsertionConfiguration,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      onSaved: onSaved ?? this.onSaved,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      autoCorrect: autoCorrect ?? this.autoCorrect,
      maxLengthEnforcement: maxLengthEnforcement ?? this.maxLengthEnforcement,
      inputDecoration: inputDecoration ?? this.inputDecoration,
    );
  }

  /// Casts this field to a [PasswordField] if it is one.
  ///
  /// Returns `this` cast to [PasswordField] if the field is actually
  /// a [PasswordField] instance, otherwise returns `null`.
  ///
  /// ## Returns
  /// - [PasswordField] if this is a password field
  /// - `null` if this is not a password field
  ///
  /// ## Example
  /// ```dart
  /// // Using with a generic field
  /// final field = someCondition ? PasswordField() : Field();
  /// 
  /// // Safe casting
  /// final passwordField = field.asPasswordField();
  /// if (passwordField != null) {
  ///   // Use password-specific properties
  ///   passwordField.toggleVisibility();
  /// }
  /// ```
  PasswordField? asPasswordField() {
    if (this case PasswordField field) {
      return field;
    }

    return null;
  }

  /// Casts this field to a [PhoneField] if it is one.
  ///
  /// Returns `this` cast to [PhoneField] if the field is actually
  /// a [PhoneField] instance, otherwise returns `null`.
  ///
  /// ## Returns
  /// - [PhoneField] if this is a phone field
  /// - `null` if this is not a phone field
  ///
  /// ## Example
  /// ```dart
  /// // Using with a generic field
  /// final field = someCondition ? PhoneField() : Field();
  /// 
  /// // Safe casting
  /// final phoneField = field.asPhoneField();
  /// if (phoneField != null) {
  ///   // Use phone-specific properties
  ///   final countryCode = phoneField.countryCode;
  /// }
  /// ```
  PhoneField? asPhoneField() {
    if (this case PhoneField field) {
      return field;
    }

    return null;
  }

  /// The default input configuration for this field.
  ///
  /// Provides base styling and behavior configuration that can be
  /// customized via [inputConfigBuilder]. Subclasses can override
  /// to provide different defaults.
  ///
  /// ## Default Values
  /// - Text color: Theme primary color
  /// - Text size: Default font size
  /// - Text weight: Normal
  /// - Hint color: CommonColors.instance.hint
  @protected
  FieldInputConfig get defaultInputConfig => FieldInputConfig();

  /// The effective input configuration for this field.
  ///
  /// Combines the [defaultInputConfig] with any customizations provided
  /// via [inputConfigBuilder]. If no builder is provided, returns the
  /// default configuration.
  ///
  /// ## Example
  /// ```dart
  /// // In a subclass or extension
  /// @override
  /// FieldInputConfig get inputConfig {
  ///   final baseConfig = super.inputConfig;
  ///   return baseConfig.copyWith(
  ///     textColor: Colors.blue,
  ///     textSize: 16,
  ///   );
  /// }
  /// ```
  @protected
  FieldInputConfig get inputConfig {
    if (inputConfigBuilder case final builder?) {
      return builder(defaultInputConfig);
    }

    return defaultInputConfig;
  }

  /// The default decoration configuration for this field.
  ///
  /// Provides base border and visual styling that can be customized
  /// via [inputDecorationBuilder]. Subclasses can override to provide
  /// different defaults.
  ///
  /// ## Default Values
  /// - Enabled border: 2px solid theme primary color
  /// - Disabled border: 2px solid theme surface color
  /// - Focused border: 2px solid theme primary color
  /// - Error border: 2px solid error color
  @protected
  FieldDecorationConfig get defaultDecorationConfig => FieldDecorationConfig();

  /// The effective decoration configuration for this field.
  ///
  /// Combines the [defaultDecorationConfig] with any customizations provided
  /// via [inputDecorationBuilder]. If no builder is provided, returns the
  /// default configuration.
  @protected
  FieldDecorationConfig get decorationConfig {
    if (inputDecorationBuilder case final inputDecorationBuilder?) {
      return inputDecorationBuilder(defaultDecorationConfig);
    }

    return defaultDecorationConfig;
  }

  /// The border radius for the input field.
  ///
  /// Calculates the border radius based on the [borderRadius] parameter.
  /// If [borderRadius] is null, defaults to 14.
  ///
  /// ## Example
  /// ```dart
  /// // Custom border radius in a subclass
  /// @override
  /// BorderRadius get inputBorderRadius {
  ///   return BorderRadius.only(
  ///     topLeft: Radius.circular(10),
  ///     topRight: Radius.circular(10),
  ///   );
  /// }
  /// ```
  @protected
  BorderRadius get inputBorderRadius => BorderRadius.circular(borderRadius ?? 14);

  /// The border style for the input field.
  ///
  /// Returns the style used for all field borders. Defaults to
  /// [BorderStyle.solid]. Subclasses can override for different styles.
  ///
  /// ## Available Styles
  /// - [BorderStyle.solid]: Continuous line
  /// - [BorderStyle.none]: No border
  @protected
  BorderStyle get inputBorderStyle => BorderStyle.solid;

  /// The color used for error states.
  ///
  /// Returns the color to use for error borders, text, and indicators.
  /// Defaults to [CommonColors.instance.error].
  ///
  /// Subclasses can override to use different error colors or to
  /// integrate with custom theme systems.
  @protected
  Color get errorColor => CommonColors.instance.error;

  /// Returns the border to display when the field is enabled and not focused.
  ///
  /// This method provides the visual border for the field's normal state.
  /// Customization can be achieved through:
  /// 1. Setting [FieldDecorationConfig.enabledBorder] directly
  /// 2. Setting [FieldDecorationConfig.enabledBorderSide] for border side customization
  /// 3. Overriding this method in subclasses
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent styling
  ///
  /// ## Returns
  /// An [InputBorder] for the enabled state.
  ///
  /// ## Default Behavior
  /// - If [FieldDecorationConfig.enabledBorder] is set, returns it directly
  /// - Otherwise creates an [OutlineInputBorder] with:
  ///   - Radius: [inputBorderRadius]
  ///   - Width: 2 logical pixels
  ///   - Color: Based on [FieldDecorationConfig.useNotEnabled] and [FieldInputConfig.textColor]
  ///   - Style: [inputBorderStyle]
  @protected
  InputBorder getEnabledBorder(BuildContext context, FieldController fieldController) {
    if (decorationConfig.enabledBorder case final enabledBorder?) {
      return enabledBorder;
    }

    return OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: decorationConfig.enabledBorderSide ?? BorderSide(
        width: 2,
        color: decorationConfig.useNotEnabled
          ? Theme.of(context).colorScheme.surface
          : inputConfig.textColor ?? Theme.of(context).primaryColor,
        style: inputBorderStyle,
      ),
    );
  }

  /// Returns the border to display when the field is disabled.
  ///
  /// This method provides the visual border for the field's disabled state.
  /// Typically shows a muted or greyed-out appearance.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent styling
  ///
  /// ## Returns
  /// An [InputBorder] for the disabled state.
  ///
  /// ## Default Behavior
  /// - If [FieldDecorationConfig.disabledBorder] is set, returns it directly
  /// - Otherwise creates an [OutlineInputBorder] similar to enabled state
  ///   but potentially with different coloring
  @protected
  InputBorder getDisabledBorder(BuildContext context, FieldController fieldController) {
    if (decorationConfig.disabledBorder case final disabledBorder?) {
      return disabledBorder;
    }

    return OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: decorationConfig.disabledBorderSide ?? BorderSide(
        width: 2,
        color: decorationConfig.useNotEnabled
          ? Theme.of(context).colorScheme.surface
          : inputConfig.textColor ?? Theme.of(context).primaryColor,
        style: inputBorderStyle,
      ),
    );
  }

  /// Returns the border to display when the field has keyboard focus.
  ///
  /// This method provides the visual border for the field's focused state.
  /// Typically shows a more prominent or differently colored border.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent styling
  ///
  /// ## Returns
  /// An [InputBorder] for the focused state.
  ///
  /// ## Default Behavior
  /// - If [FieldDecorationConfig.focusedBorder] is set, returns it directly
  /// - Otherwise creates an [OutlineInputBorder] with:
  ///   - Radius: [inputBorderRadius]
  ///   - Width: 2 logical pixels
  ///   - Color: [FieldInputConfig.textColor] or theme primary color
  ///   - Style: [inputBorderStyle]
  @protected
  InputBorder getFocusedBorder(BuildContext context, FieldController fieldController) {
    if (decorationConfig.focusedBorder case final focusedBorder?) {
      return focusedBorder;
    }

    return OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: decorationConfig.focusedBorderSide ?? BorderSide(
        width: 2,
        color: inputConfig.textColor ?? Theme.of(context).primaryColor,
        style: inputBorderStyle,
      ),
    );
  }

  /// Returns the border to display when the field has validation errors.
  ///
  /// This method provides the visual border for the field's error state.
  /// Typically shows an error color (red) to indicate invalid input.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent styling
  ///
  /// ## Returns
  /// An [InputBorder] for the error state.
  ///
  /// ## Default Behavior
  /// - If [FieldDecorationConfig.errorBorder] is set, returns it directly
  /// - Otherwise creates an [OutlineInputBorder] with:
  ///   - Radius: [inputBorderRadius]
  ///   - Width: 2 logical pixels
  ///   - Color: [errorColor]
  ///   - Style: [inputBorderStyle]
  @protected
  InputBorder getErrorBorder(BuildContext context, FieldController fieldController) {
    if (decorationConfig.errorBorder case final errorBorder?) {
      return errorBorder;
    }

    return OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: decorationConfig.errorBorderSide ?? BorderSide(
        width: 2,
        color: errorColor,
        style: inputBorderStyle,
      ),
    );
  }

  /// Returns the border to display when the field has both focus and errors.
  ///
  /// This method provides the visual border for the field's focused error state.
  /// Combines the visual cues of both focused and error states.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent styling
  ///
  /// ## Returns
  /// An [InputBorder] for the focused error state.
  ///
  /// ## Default Behavior
  /// - If [FieldDecorationConfig.focusedErrorBorder] is set, returns it directly
  /// - Otherwise creates an [OutlineInputBorder] with:
  ///   - Radius: [inputBorderRadius]
  ///   - Width: 2 logical pixels
  ///   - Color: [errorColor]
  ///   - Style: [inputBorderStyle]
  @protected
  InputBorder getFocusedErrorBorder(BuildContext context, FieldController fieldController) {
    if (decorationConfig.focusedErrorBorder case final focusedErrorBorder?) {
      return focusedErrorBorder;
    }

    return OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: decorationConfig.focusedErrorBorderSide ?? BorderSide(
        width: 2,
        color: errorColor,
        style: inputBorderStyle,
      ),
    );
  }

  /// Returns the suffix icon widget for the field.
  ///
  /// This method provides the suffix icon, allowing subclasses to override
  /// or customize icon behavior based on field state or controller.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent icon changes
  ///
  /// ## Returns
  /// The suffix icon widget, or null if no icon should be displayed.
  ///
  /// ## Example Override
  /// ```dart
  /// @override
  /// Widget? getSuffixIcon(BuildContext context, FieldController fieldController) {
  ///   if (fieldController.hasError) {
  ///     return Icon(Icons.error, color: Colors.red);
  ///   }
  ///   return super.getSuffixIcon(context, fieldController);
  /// }
  /// ```
  @protected
  Widget? getSuffixIcon(BuildContext context, FieldController fieldController) => suffixIcon;

  /// Returns the prefix icon widget for the field.
  ///
  /// This method provides the prefix icon, allowing subclasses to override
  /// or customize icon behavior based on field state or controller.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access
  /// - [fieldController]: The field's controller for state-dependent icon changes
  ///
  /// ## Returns
  /// The prefix icon widget, or null if no icon should be displayed.
  @protected
  Widget? getPrefixIcon(BuildContext context, FieldController fieldController) => prefixIcon;

  /// Called when the field's value changes.
  ///
  /// This method delegates to the [onChanged] callback if provided.
  /// Subclasses can override to add additional behavior when the value changes.
  ///
  /// ## Parameters
  /// - [value]: The new field value
  /// - [fieldController]: The field's controller for state updates
  ///
  /// ## Example Override
  /// ```dart
  /// @override
  /// void whenChanged(String value, FieldController fieldController) {
  ///   // Perform custom processing
  ///   final processedValue = processValue(value);
  ///   
  ///   // Update controller state
  ///   fieldController.setCustomState(processedValue);
  ///   
  ///   // Call parent implementation to trigger onChanged callback
  ///   super.whenChanged(value, fieldController);
  /// }
  /// ```
  @protected
  void whenChanged(String value, FieldController fieldController) {
    if (onChanged case final onChanged?) {
      return onChanged(value);
    }
  }

  /// Called when the form containing the field is saved.
  ///
  /// This method delegates to the [onSaved] callback if provided.
  /// Subclasses can override to add additional save behavior.
  ///
  /// ## Parameters
  /// - [value]: The field value to save (may be null)
  /// - [fieldController]: The field's controller for state updates
  @protected
  void whenSaved(String? value, FieldController fieldController) {
    if (onSaved case final onSaved?) {
      return onSaved(value);
    }
  }

  /// Called to validate the field's current value.
  ///
  /// This method delegates to the [validator] callback if provided.
  /// Subclasses can override to add additional validation logic.
  ///
  /// ## Parameters
  /// - [value]: The value to validate (may be null)
  /// - [fieldController]: The field's controller for validation state
  ///
  /// ## Returns
  /// - `null` if validation passes
  /// - Error message string if validation fails
  ///
  /// ## Example Override
  /// ```dart
  /// @override
  /// String? whenValidated(String? value, FieldController fieldController) {
  ///   // Perform base validation
  ///   final baseError = super.whenValidated(value, fieldController);
  ///   if (baseError != null) return baseError;
  ///   
  ///   // Add custom validation
  ///   if (value != null && !isValidCustomFormat(value)) {
  ///     return 'Invalid format';
  ///   }
  ///   
  ///   return null;
  /// }
  /// ```
  @protected
  String? whenValidated(String? value, FieldController fieldController) {
    if (validator case final validator?) {
      return validator(value);
    }

    return null;
  }

  /// Determines whether the field's text should be obscured (hidden).
  ///
  /// This method returns `true` if the text should be displayed as obscured
  /// (e.g., for password fields), or `false` if the text should be visible.
  ///
  /// By default, this method returns the value of the [obscureText] property.
  /// Subclasses can override this method to provide dynamic obscuring logic
  /// based on the current field controller state.
  ///
  /// ## Parameters
  ///
  /// - [fieldController]: The [FieldController] managing the field's state.
  ///   Can be used to check for conditions like "show password" toggle states.
  ///
  /// ## Returns
  ///
  /// - `true` if the text should be obscured (displayed as dots/asterisks)
  /// - `false` if the text should be displayed normally
  ///
  /// ## Default Implementation
  ///
  /// The default implementation simply returns the [obscureText] property value:
  /// ```dart
  /// bool shouldObscureText(FieldController fieldController) => obscureText;
  /// ```
  ///
  /// ## See Also
  ///
  /// - [obscureText] property for the static obscuring configuration
  /// - [whenValidated] for validation logic
  /// - [TextField.obscureText] for the Flutter TextField property
  @protected
  bool shouldObscureText(BuildContext context, FieldController fieldController) => obscureText;

  @override
  Widget build(BuildContext context) => FieldFormManager(
    stateController: stateController,
    onInit: onInit,
    builder: (context, controller) {
      // Trigger the bind callback if provided
      if (onBind case final onBind?) {
        onBind(controller);
      }

      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => createView(context, controller),
      );
    },
  );

  /// Creates the complete widget hierarchy for the field.
  ///
  /// This non-virtual method serves as the main entry point for building
  /// the field's visual representation. It handles the conditional layout
  /// based on whether a label is needed above the field.
  ///
  /// ## Layout Logic
  /// - When [needLabel] is `true`: Creates a [Column] with label above field
  /// - When [needLabel] is `false`: Returns only the input field
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme and media query access
  /// - [fieldController]: The field's controller for state-dependent rendering
  ///
  /// ## Returns
  /// The complete widget tree for the field.
  ///
  /// ## Label Configuration
  /// When [needLabel] is `true`:
  /// - Requires either [label] or [hint] to be non-null (assertion enforced)
  /// - Uses [label] if provided, otherwise falls back to [hint]
  /// - Applies label styling from [inputConfig] or defaults
  /// - Adds vertical spacing controlled by [spacing] (defaults to 3)
  /// - Uses [crossAxisAlignment] for label alignment (defaults to start)
  ///
  /// ## Example Override
  /// While this method is marked `@nonVirtual`, subclasses can override
  /// [buildField] to customize the input field itself while preserving
  /// the label layout logic.
  ///
  /// ## Assertion
  /// When [needLabel] is `true`, asserts that either [label] or [hint]
  /// is provided with the message: "Because `needLabel` is true, `label` 
  /// or `hint` must be provided"
  @protected
  @nonVirtual
  Widget createView(BuildContext context, FieldController fieldController) {
    if(needLabel) {
      assert(label.isNotNull && hint.isNotNull, "Because `needLabel` is true, `label` or `hint` must be provided");

      return Column(
        spacing: spacing ?? 3,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
        children: [
          TextBuilder(
            text: label ?? hint ?? "",
            color: inputConfig.labelColor ?? Theme.of(context).scaffoldBackgroundColor,
            size: inputConfig.labelSize ?? Sizing.font(10),
            weight: inputConfig.labelWeight ?? FontWeight.normal,
          ),
          buildField(context, fieldController)
        ],
      );
    } else {
      return buildField(context, fieldController);
    }
  }

  /// Builds the core [TextFormField] widget with all configured properties.
  ///
  /// This method constructs the actual Flutter [TextFormField] with all
  /// the customization options specified through the field's parameters.
  /// Subclasses can override this method to create specialized field types
  /// while reusing most of the configuration logic.
  ///
  /// ## Parameters
  /// - [context]: BuildContext for theme access and localization
  /// - [fieldController]: The field's controller for validation and callbacks
  ///
  /// ## Returns
  /// A fully configured [TextFormField] widget.
  ///
  /// ## Key Configuration Areas
  ///
  /// ### Text Styling
  /// - Color: [FieldInputConfig.textColor] or theme primary color
  /// - Size: [FieldInputConfig.textSize]
  /// - Weight: [FieldInputConfig.textWeight]
  /// - Alignment: Based on [useOtpDesign] and [textAlign]
  ///
  /// ### Cursor Configuration
  /// - Color: [cursorColor] or [FieldInputConfig.textColor]
  /// - Height: [cursorHeight]
  /// - Width: [cursorWidth] (defaults to 2.0)
  /// - Radius: [cursorRadius]
  ///
  /// ### Layout & Behavior
  /// - Max lines: [maxLines] or based on [useBigField]
  /// - Min lines: [minLines] or based on [useBigField]
  /// - Vertical alignment: [textAlignVertical] or based on [useBigField]
  /// - Capitalization: [textCapitalization] or based on [useBigField]
  /// - Auto-validation: [modeValidator] (defaults to on user interaction)
  ///
  /// ### Input Configuration
  /// - Action: [inputAction] (defaults to next)
  /// - Auto-correct: [autoCorrect] (defaults to true)
  /// - Keyboard type: [keyboard]
  /// - Obscure text: [obscureText] (defaults to false)
  /// - Input formatters: Combines OTP formatting with [inputFormatters]
  ///
  /// ### Event Handlers
  /// - Validation: Delegates to [whenValidated]
  /// - Change: Delegates to [whenChanged]
  /// - Save: Delegates to [whenSaved]
  /// - Completion: [onEditingComplete]
  /// - Submission: [onFieldSubmitted]
  /// - Tap outside: [onTapOutside]
  ///
  /// ### Platform Features
  /// - Interactive selection: [enableInteractiveSelection]
  /// - IME learning: [enableIMEPersonalizedLearning] (defaults to true)
  /// - Stylus: [stylusHandwritingEnabled] (defaults to true)
  /// - Focus: [canRequestFocus] (defaults to true)
  /// - Scroll: [scrollPadding], [scrollPhysics], [scrollController]
  ///
  /// ### Accessibility & Internationalization
  /// - Text direction: [textDirection]
  /// - Keyboard appearance: [keyboardAppearance]
  /// - Autofill hints: [autofillHints]
  /// - Mouse cursor: [mouseCursor]
  /// - Context menu: [contextMenuBuilder]
  ///
  /// ### Advanced Features
  /// - Selection: [selectionControls], [selectionHeightStyle], [selectionWidthStyle]
  /// - Spell check: [spellCheckConfiguration]
  /// - Magnifier: [magnifierConfiguration]
  /// - Undo: [undoController]
  /// - App commands: [onAppPrivateCommand]
  /// - Content insertion: [contentInsertionConfiguration]
  /// - Drag behavior: [dragStartBehavior] (defaults to start)
  /// - Clip behavior: [clipBehavior] (defaults to hard edge)
  /// - Max length: [maxLengthEnforcement]
  ///
  /// ### Decoration
  /// - Hint text: Based on [replaceHintWithLabel], [label], and [hint]
  /// - Content padding: [padding] or zero for OTP design
  /// - Hint style: From [inputConfig] or defaults
  /// - Fill color: [fillColor] or theme scaffold background
  /// - Icon constraints: [suffixIconConstraints], [prefixIconConstraints]
  /// - Icons: [prefixIcon] and from [getSuffixIcon]
  /// - Borders: Delegated to border getter methods
  ///
  /// ## OTP Design Special Handling
  /// When [useOtpDesign] is `true`:
  /// - Text alignment centers horizontally
  /// - Content padding is set to zero
  /// - Input is limited to 1 character
  /// - Only digits are allowed
  /// - Typically used for verification code inputs
  ///
  /// ## Big Field Special Handling
  /// When [useBigField] is `true`:
  /// - Max lines defaults to 20 (vs 1 for regular fields)
  /// - Min lines defaults to 5
  /// - Text aligns vertically center
  /// - Capitalization defaults to sentences
  /// - Typically used for text areas and multi-line inputs
  ///
  /// ## Example Override
  /// ```dart
  /// class CustomField extends Field {
  ///   @override
  ///   Widget buildField(BuildContext context, FieldController fieldController) {
  ///     // Get the base field
  ///     final baseField = super.buildField(context, fieldController);
  ///     
  ///     // Add custom wrapper
  ///     return Container(
  ///       decoration: BoxDecoration(
  ///         border: Border.all(color: Colors.blue),
  ///         borderRadius: BorderRadius.circular(8),
  ///       ),
  ///       child: baseField,
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// ## Performance Considerations
  /// - The [TextFormField] constructor is called on every build
  /// - Consider using `const` where possible for static configurations
  /// - Large configurations may impact rebuild performance
  /// - The method delegates to multiple helper methods for modularity
  @protected
  Widget buildField(BuildContext context, FieldController fieldController) => TextFormField(
    style: TextStyle(
      color: inputConfig.textColor ?? Theme.of(context).primaryColor,
      fontSize: inputConfig.textSize,
      fontWeight: inputConfig.textWeight
    ),
    textAlign: textAlign ?? (useOtpDesign ? TextAlign.center : TextAlign.start),
    cursorColor: cursorColor ?? inputConfig.textColor ?? Theme.of(context).primaryColor,
    cursorHeight: cursorHeight,
    controller: controller,
    enabled: enabled,
    focusNode: focus,
    maxLines: maxLines ?? (useBigField ? 20 : 1),
    minLines: minLines ?? (useBigField ? 5 : null),
    textAlignVertical: textAlignVertical ?? (useBigField ? TextAlignVertical.center : null),
    textCapitalization: textCapitalization ?? (useBigField ? TextCapitalization.sentences : TextCapitalization.none),
    autovalidateMode: modeValidator ?? AutovalidateMode.onUserInteraction,
    textInputAction: inputAction,
    autocorrect: autoCorrect,
    keyboardType: keyboard,
    obscureText: shouldObscureText(context, fieldController),
    validator: (value) => whenValidated(value, fieldController),
    onChanged: (value) => whenChanged(value, fieldController),
    onSaved: (value) => whenSaved(value, fieldController),
    onTapOutside: onTapOutside,
    onEditingComplete: onEditingComplete,
    onFieldSubmitted: onFieldSubmitted,
    ignorePointers: ignorePointers,
    textDirection: textDirection,
    autofocus: autofocus,
    cursorWidth: cursorWidth,
    cursorRadius: cursorRadius,
    keyboardAppearance: keyboardAppearance,
    scrollPadding: scrollPadding,
    enableInteractiveSelection: enableInteractiveSelection,
    selectionControls: selectionControls,
    buildCounter: buildCounter,
    scrollPhysics: scrollPhysics,
    autofillHints: autofillHints,
    scrollController: scrollController,
    enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
    mouseCursor: mouseCursor,
    contextMenuBuilder: contextMenuBuilder,
    spellCheckConfiguration: spellCheckConfiguration,
    magnifierConfiguration: magnifierConfiguration,
    undoController: undoController,
    onAppPrivateCommand: onAppPrivateCommand,
    cursorOpacityAnimates: cursorOpacityAnimates,
    selectionHeightStyle: selectionHeightStyle,
    selectionWidthStyle: selectionWidthStyle,
    dragStartBehavior: dragStartBehavior,
    contentInsertionConfiguration: contentInsertionConfiguration,
    statesController: statesController,
    clipBehavior: clipBehavior,
    stylusHandwritingEnabled: stylusHandwritingEnabled,
    canRequestFocus: canRequestFocus,
    maxLengthEnforcement: maxLengthEnforcement,
    inputFormatters: [
      if(useOtpDesign) ...[
        LengthLimitingTextInputFormatter(1),
        FilteringTextInputFormatter.digitsOnly
      ],
      ...inputFormatters ?? []
    ],
    decoration: inputDecoration ?? InputDecoration(
      hintText: replaceHintWithLabel ? label : hint,
      contentPadding: useOtpDesign ? EdgeInsets.zero : padding,
      hintStyle: TextStyle(
        color: inputConfig.hintColor ?? CommonColors.instance.hint,
        fontSize: inputConfig.hintSize ?? inputConfig.textSize,
        fontWeight: inputConfig.hintWeight
      ),
      filled: true,
      suffixIconConstraints: suffixIconConstraints,
      prefixIconConstraints: prefixIconConstraints,
      prefixIcon: getPrefixIcon(context, fieldController),
      suffixIcon: getSuffixIcon(context, fieldController),
      fillColor: fillColor ?? Theme.of(context).scaffoldBackgroundColor,
      enabledBorder: getEnabledBorder(context, fieldController),
      disabledBorder: getDisabledBorder(context, fieldController),
      focusedBorder: getFocusedBorder(context, fieldController),
      errorBorder: getErrorBorder(context, fieldController),
      focusedErrorBorder: getFocusedErrorBorder(context, fieldController),
    ),
  );
}