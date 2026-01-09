import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/utilities.dart';

import '../typedefs.dart';
import 'field.dart';
import 'field_controller.dart';

/// Signature for callbacks that handle password visibility toggle actions.
///
/// This typedef defines the function signature for callbacks that are invoked
/// when a password visibility toggle button is tapped.
///
/// The callback receives a [PasswordVisibilityState] parameter which indicates
/// whether the password should be shown or hidden.
///
/// Example usage:
/// ```dart
/// class PasswordField extends StatefulWidget {
///   final OnPasswordVisibilityTapped? onVisibilityTapped;
///
///   const PasswordField({this.onVisibilityTapped});
///
///   @override
///   State<PasswordField> createState() => _PasswordFieldState();
/// }
///
/// class _PasswordFieldState extends State<PasswordField> {
///   bool _obscureText = true;
///
///   void _togglePasswordVisibility() {
///     setState(() {
///       _obscureText = !_obscureText;
///     });
///
///     // Notify parent widget about the visibility change
///     widget.onVisibilityTapped?.call(
///       _obscureText 
///         ? PasswordVisibilityState.hidden 
///         : PasswordVisibilityState.visible,
///     );
///   }
/// }
/// ```
typedef OnPasswordVisibilityTapped = void Function(PasswordVisibilityState);

/// {@template password_visibility_state}
/// Tracks whether a password is currently visible or obscured.
///
/// This [FieldState] subclass manages the visibility state of a password field.
/// It's automatically added to the [FieldController] when a [PasswordField]
/// is created and is used by the visibility toggle icon.
///
/// ## State Values
/// - `true`: Password text is visible (not obscured)
/// - `false`: Password text is obscured (hidden with dots)
///
/// ## Default Behavior
/// Initially set to `true` (password obscured) for security.
///
/// ## Usage
/// Typically accessed through the field controller:
/// ```dart
/// final visibilityState = controller.find<PasswordVisibilityState>();
/// print('Password visible: ${visibilityState.value}');
/// visibilityState.value = true; // Show password
/// ```
///
/// ## Integration
/// Used by [PasswordField.getSuffixIcon] to determine which icon to display
/// and to update the [obscureText] property of the underlying text field.
/// {@endtemplate}
final class PasswordVisibilityState extends FieldState<bool> {
  /// {@macro password_visibility_state}
  PasswordVisibilityState(super.value);
}

/// {@template password_field}
/// A specialized text field for password input with visibility toggle.
///
/// Extends [Field] to provide secure password input with additional features:
/// - Toggle visibility of entered text
/// - Secure text entry by default
/// - Customizable visibility icons
/// - Accessibility considerations for password fields
/// - Integration with password managers and autofill
///
/// ## Key Features
/// - **Visibility toggle**: Eye icon to show/hide password text
/// - **Secure defaults**: `obscureText` defaults to `true`, `autoCorrect` to `false`
/// - **State management**: Tracks visibility state via [PasswordVisibilityState]
/// - **Custom icons**: Configurable show/hide icons
/// - **Accessibility**: Properly labeled for screen readers
/// - **Security**: Disables text suggestions and auto-correction
///
/// ## Basic Usage
/// ```dart
/// PasswordField(
///   hint: 'Enter password',
///   onChanged: (value) => print('Password: $value'),
/// )
///
/// // With validation
/// PasswordField(
///   hint: 'Create password',
///   validator: (value) {
///     if (value == null || value.isEmpty) return 'Required';
///     if (value.length < 8) return 'Minimum 8 characters';
///     return null;
///   },
/// )
/// ```
///
/// ## Visibility Control
/// ```dart
/// // Custom visibility icons
/// PasswordField(
///   hint: 'Enter password',
///   visibleIcon: Icons.visibility_outlined,
///   nonVisibleIcon: Icons.visibility_off_outlined,
///   iconSize: 20,
///   iconColor: Colors.blue,
///   onVisibilityTapped: (state) => print('Visibility: ${state.value}'),
/// )
///
/// // Programmatic control
/// final fieldController = FieldController();
/// PasswordField(
///   stateController: fieldController,
///   onInit: (controller) {
///     // Set initial visibility
///     controller.find<PasswordVisibilityState>().value = false;
///   },
/// )
/// ```
///
/// ## Security Considerations
/// - `obscureText` defaults to `true` for security
/// - `autoCorrect` defaults to `false` to prevent password suggestions
/// - Consider using `autofillHints: [AutofillHints.password]`
/// - For sensitive applications, consider additional security measures
///
/// ## Accessibility
/// ```dart
/// PasswordField(
///   label: 'Password', // Screen reader announcement
///   hint: 'Enter your password',
///   autofillHints: [AutofillHints.password],
///   // The visibility toggle is automatically accessible
/// )
/// ```
///
/// ## Integration with Forms
/// ```dart
/// Form(
///   child: Column(
///     children: [
///       // Email field
///       Field(
///         hint: 'Email',
///         autofillHints: [AutofillHints.email],
///       ),
///       // Password field
///       PasswordField(
///         hint: 'Password',
///         autofillHints: [AutofillHints.password],
///         inputAction: TextInputAction.done,
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## Customization
/// ```dart
/// // Custom styling
/// PasswordField(
///   hint: 'Secret phrase',
///   prefixIcon: Icon(Icons.lock),
///   borderRadius: 20,
///   fillColor: Colors.grey[100],
///   cursorColor: Colors.blue,
///   iconColor: Colors.grey,
///   iconButtonColor: Colors.transparent,
///   iconSplashRadius: 20,
/// )
///
/// // Using copyWith for variations
/// final basePasswordField = PasswordField(hint: 'Password');
/// final disabledVersion = basePasswordField.copyWith(
///   enabled: false,
///   hint: 'Password (set)',
/// );
/// ```
///
/// ## State Management
/// The field manages visibility state through [PasswordVisibilityState]:
/// ```dart
/// final fieldController = FieldController();
/// PasswordField(
///   stateController: fieldController,
///   onVisibilityTapped: (state) {
///     // State contains current visibility (true = visible, false = obscured)
///     analytics.logPasswordVisibilityToggle(state.value);
///   },
/// )
///
/// // Programmatic control
/// final visibilityState = fieldController.find<PasswordVisibilityState>();
/// visibilityState.value = true; // Show password
/// visibilityState.value = false; // Hide password
/// ```
///
/// ## Platform-Specific Behavior
/// - **Android/iOS**: Integrates with platform password managers
/// - **Web**: Supports browser password saving and generation
/// - **Desktop**: Appropriate keyboard shortcuts and interactions
///
/// ## Best Practices
/// 1. Always provide clear hints or labels for password fields
/// 2. Consider minimum password length validation
/// 3. Use `autofillHints: [AutofillHints.password]` for better UX
/// 4. Provide feedback on password strength if applicable
/// 5. Ensure the visibility toggle is clearly understandable
/// 6. Consider adding a "show password" accessibility label
///
/// ## Common Patterns
/// ```dart
/// // Login form pattern
/// Column(
///   children: [
///     Field(hint: 'Username or email'),
///     PasswordField(hint: 'Password'),
///     TextButton(
///       onPressed: () => showForgotPasswordDialog(),
///       child: Text('Forgot password?'),
///     ),
///   ],
/// )
///
/// // Password confirmation pattern
/// Column(
///   children: [
///     PasswordField(hint: 'New password'),
///     PasswordField(
///       hint: 'Confirm password',
///       validator: (value) {
///         if (value != passwordController.text) {
///           return 'Passwords do not match';
///         }
///         return null;
///       },
///     ),
///   ],
/// )
/// ```
///
/// ## Migration from Field.password()
/// The deprecated `Field.password()` factory constructor has been replaced
/// by the dedicated `PasswordField` class:
/// ```dart
/// // OLD (deprecated)
/// Field.password(hint: 'Password')
///
/// // NEW
/// PasswordField(hint: 'Password')
/// ```
///
/// {@macro field}
/// {@endtemplate}
final class PasswordField extends Field with FieldMixin {
  /// Icon to display when the password is visible (text shown).
  ///
  /// Defaults to `Icons.visibility_off` (eye with slash).
  /// Set to customize the visible state icon.
  ///
  /// ## Example
  /// ```dart
  /// PasswordField(
  ///   visibleIcon: Icons.remove_red_eye,
  ///   nonVisibleIcon: Icons.remove_red_eye_outlined,
  /// )
  /// ```
  final IconData? visibleIcon;

  /// Icon to display when the password is not visible (text hidden).
  ///
  /// Defaults to `Icons.visibility` (eye).
  /// Set to customize the non-visible state icon.
  final IconData? nonVisibleIcon;

  /// Size of the visibility toggle icon in logical pixels.
  ///
  /// When null, defaults to `Sizing.font(24)`.
  final double? iconSize;

  /// The splash radius of the visibility toggle icon button.
  ///
  /// Controls the ripple effect size when the icon is pressed.
  final double? iconSplashRadius;

  /// Color of the visibility toggle icon.
  ///
  /// When null, defaults to `Theme.of(context).colorScheme.surface`.
  final Color? iconColor;

  /// Background color of the visibility toggle icon button.
  ///
  /// Affects the icon button's background color.
  final Color? iconButtonColor;

  /// Splash color of the visibility toggle icon button.
  ///
  /// Controls the ripple effect color when the icon is pressed.
  final Color? iconSplashColor;

  /// Called when the visibility toggle is tapped.
  ///
  /// Provides the current [PasswordVisibilityState] allowing you to
  /// respond to visibility changes (e.g., analytics, additional UI updates).
  ///
  /// ## Example
  /// ```dart
  /// PasswordField(
  ///   onVisibilityTapped: (state) {
  ///     print('Password visibility toggled: ${state.value}');
  ///     analytics.logEvent('password_visibility_toggle');
  ///   },
  /// )
  /// ```
  final OnPasswordVisibilityTapped? onVisibilityTapped;

  /// {@macro password_field}
  ///
  /// ## Default Values
  /// - `obscureText`: `true` (passwords are hidden by default)
  /// - `autoCorrect`: `false` (disable auto-correction for passwords)
  /// - `maxLines`: `1` (single-line input)
  ///
  /// ## Initialization
  /// The constructor automatically adds a [PasswordVisibilityState] to the
  /// controller with initial value `true` (password obscured).
  PasswordField({
    super.key,
    super.controller,
    super.stateController,
    FieldControllerValue? onInit,
    super.onBind,
    super.enabled,
    super.focus,
    super.inputAction,
    super.keyboard,
    super.obscureText = true,
    super.validator,
    super.onChanged,
    super.hint,
    super.suffixIcon,
    super.prefixIcon,
    super.borderRadius,
    super.useOtpDesign,
    super.fillColor,
    super.suffixIconConstraints,
    super.useBigField,
    super.needLabel,
    super.padding,
    super.label,
    super.spacing,
    super.inputConfigBuilder,
    super.cursorColor,
    super.cursorErrorColor,
    super.cursorHeight,
    super.prefixIconConstraints,
    super.modeValidator,
    super.textAlignVertical,
    super.textCapitalization,
    super.textAlign,
    super.textDirection,
    super.keyboardAppearance,
    super.selectionControls,
    super.buildCounter,
    super.scrollPhysics,
    super.autofillHints,
    super.mouseCursor,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
    super.undoController,
    super.onAppPrivateCommand,
    super.scrollController,
    super.statesController,
    super.onEditingComplete,
    super.onTapOutside,
    super.onFieldSubmitted,
    super.replaceHintWithLabel,
    super.ignorePointers,
    super.enableInteractiveSelection,
    super.cursorOpacityAnimates,
    super.maxLines = 1,
    super.minLines,
    super.inputFormatters,
    super.inputDecorationBuilder,
    super.cursorRadius,
    super.contentInsertionConfiguration,
    super.crossAxisAlignment,
    super.onSaved,
    super.cursorWidth,
    super.autofocus,
    super.enableIMEPersonalizedLearning,
    super.stylusHandwritingEnabled,
    super.canRequestFocus,
    super.scrollPadding,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.dragStartBehavior,
    super.clipBehavior,
    super.autoCorrect = false,
    super.maxLengthEnforcement,
    super.inputDecoration,
    this.visibleIcon,
    this.nonVisibleIcon,
    this.iconSize,
    this.iconSplashRadius,
    this.iconColor,
    this.iconButtonColor,
    this.iconSplashColor,
    this.onVisibilityTapped,
  }) : super(
    onInit: (controller) {
      if (onInit case final onInit?) {
        onInit(controller);
      }

      controller.add(PasswordVisibilityState(true));
    }
  );

  /// {@macro field_copyWith}
  ///
  /// Creates a copy of this password field with updated properties.
  /// Includes all [PasswordField] specific properties in addition to
  /// the base [Field] properties.
  @override
  PasswordField copyWith({
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
    IconData? visibleIcon,
    IconData? nonVisibleIcon,
    double? iconSize,
    double? iconSplashRadius,
    Color? iconColor,
    Color? iconButtonColor,
    Color? iconSplashColor,
    OnPasswordVisibilityTapped? onVisibilityTapped,
    InputDecoration? inputDecoration
  }) {
    return PasswordField(
      key: key,
      controller: controller ?? this.controller,
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
      inputDecoration: inputDecoration ?? this.inputDecoration,
      contentInsertionConfiguration: contentInsertionConfiguration ?? this.contentInsertionConfiguration,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      onSaved: onSaved ?? this.onSaved,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      autoCorrect: autoCorrect ?? this.autoCorrect,
      maxLengthEnforcement: maxLengthEnforcement ?? this.maxLengthEnforcement,
      visibleIcon: visibleIcon ?? this.visibleIcon,
      nonVisibleIcon: nonVisibleIcon ?? this.nonVisibleIcon,
      iconSize: iconSize ?? this.iconSize,
      iconSplashRadius: iconSplashRadius ?? this.iconSplashRadius,
      iconColor: iconColor ?? this.iconColor,
      iconButtonColor: iconButtonColor ?? this.iconButtonColor,
      iconSplashColor: iconSplashColor ?? this.iconSplashColor,
      stateController: stateController ?? this.stateController,
      onBind: onBind ?? this.onBind,
      onInit: onInit ?? this.onInit,
      onVisibilityTapped: onVisibilityTapped ?? this.onVisibilityTapped,
    );
  }

  @override
  bool shouldObscureText(BuildContext context, FieldController fieldController) {
    if (super.getSuffixIcon(context, fieldController) != null) {
      return super.shouldObscureText(context, fieldController);
    }

    return fieldController.find<PasswordVisibilityState>().value;
  }

  /// Overrides the base implementation to provide a visibility toggle icon
  /// when no custom suffix icon is provided. The toggle:
  /// - Shows `Icons.visibility` when password is hidden
  /// - Shows `Icons.visibility_off` when password is visible
  /// - Toggles the [PasswordVisibilityState] when pressed
  /// - Calls [onVisibilityTapped] callback if provided
  /// - Respects custom icon configuration ([visibleIcon], [nonVisibleIcon])
  ///
  /// ## Behavior
  /// 1. If a custom [suffixIcon] is provided, uses it instead
  /// 2. Otherwise creates an [IconButton] that toggles visibility
  /// 3. Updates the [PasswordVisibilityState] in the controller
  /// 4. Triggers the [onVisibilityTapped] callback
  ///
  /// ## Accessibility
  /// The icon button includes appropriate semantics for screen readers,
  /// indicating whether the password is currently visible or hidden.
  @override
  Widget? getSuffixIcon(BuildContext context, FieldController fieldController) {
    if (super.getSuffixIcon(context, fieldController) case final icon?) {
      return icon;
    }

    final visibility = fieldController.find<PasswordVisibilityState>();

    return IconButton(
      onPressed: () {
        visibility.value = !visibility.value;
        
        if (onVisibilityTapped case final onVisibilityTapped?) {
          onVisibilityTapped(visibility);
        }
      },
      icon: Icon(
        visibility.value ? Icons.visibility_off : Icons.visibility,
        size: iconSize ?? Sizing.font(24),
        color: iconColor ?? Theme.of(context).colorScheme.surface
      ),
      color: iconButtonColor,
      splashColor: iconSplashColor,
      splashRadius: iconSplashRadius,
    );
  }
}