import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/src/styles/colors/common_colors.dart';
import 'package:smart/utilities.dart';

import '../export.dart';

/// A customizable text input field widget.
///
/// This widget provides an enhanced [TextFormField] with various styling options,
/// validation support, and additional interactive features. It offers a flexible 
/// foundation for building various types of input fields within your application, 
/// such as standard text fields, password fields, and more.
class Field extends StatelessWidget {
  /// Whether the field is a password field.
  /// 
  /// If `true`, the input will be obscured, typically with dots, 
  /// for enhanced security.
  final bool _isPassword;

  /// The controller for managing the text input.
  /// 
  /// Allows you to programmatically set or get the text within the field.
  final TextEditingController? controller;

  /// The scroll controller for managing text scrolling.
  /// 
  /// Useful for controlling the scrolling behavior within the field, 
  /// especially for multiline text fields.
  final ScrollController? scrollController;

  /// Controls widget states.
  /// 
  /// Allows you to manage the visual and interactive states of the field, 
  /// such as error states or loading states.
  final WidgetStatesController? statesController;

  /// An optional default icon for a password field.
  /// 
  /// Typically displayed at the start of the field.
  final IconData? icon;

  /// Callback when the icon button is pressed in a password field.
  /// 
  /// This function is called when the user interacts with the optional icon 
  /// associated with the field.
  final VoidCallback? onPressed;

  /// Callback when editing is completed.
  /// 
  /// This function is called when the user finishes editing the text within the field.
  final VoidCallback? onEditingComplete;

  /// Callback when tapping outside the field.
  /// 
  /// This function is called when the user taps outside the field's boundaries.
  final TapRegionCallback? onTapOutside;

  /// Callback when the field is submitted.
  /// 
  /// This function is called when the user submits the field, 
  /// typically by pressing the "Enter" or "Done" key.
  final Consumer<String>? onFieldSubmitted;

  /// Function to validate the field.
  /// 
  /// This function is used to validate the input value. 
  /// It should return a String containing the error message 
  /// if the input is invalid, or null if the input is valid.
  final FieldValidator? validator;

  /// Callback when the field value changes.
  /// 
  /// This function is called whenever the user enters or modifies 
  /// the text within the field.
  final Consumer<String>? onChanged;

  /// Focus node to control focus handling.
  /// 
  /// Allows you to programmatically focus or unfocus the field.
  final FocusNode? focus;

  /// The input action for the keyboard.
  /// 
  /// Determines the action button displayed on the keyboard (e.g., "Next," "Done").
  final TextInputAction inputAction;

  /// The keyboard type for text input.
  /// 
  /// Specifies the type of keyboard to display (e.g., numbers, email).
  final TextInputType? keyboard;

  /// The placeholder text inside the field.
  /// 
  /// This text is displayed when the field is empty.
  final String? hint;

  /// The label text displayed above the field.
  /// 
  /// This provides a descriptive label for the field.
  final String? label;

  /// The size of the default icon  for a password field (if present).
  final double? iconSize;

  /// The height of the cursor.
  final double? cursorHeight;

  /// The border radius of the field.
  final double? borderRadius;

  /// The spacing between elements inside the field.
  final double? spacing;

  /// The cursor width inside the field.
  final double cursorWidth;

  /// The splash radius of the default icon button for a password field
  final double? iconSplashRadius;

  /// An optional suffix icon.
  /// 
  /// Displayed at the end of the input field.
  final Widget? suffixIcon;

  /// An optional prefix icon.
  /// 
  /// Displayed at the beginning of the input field.
  final Widget? prefixIcon;

  /// The background color of the field.
  final Color? fillColor;

  /// The color of the cursor.
  final Color? cursorColor;

  /// The color of the default icon for a password field.
  final Color? iconColor;

  /// The color of the default icon button for a password field
  final Color? iconButtonColor;

  /// The splash color of the default icon button for a password field
  final Color? iconSplashColor;

  /// The color of the cursor when there is an error.
  final Color? cursorErrorColor;

  /// Constraints for the suffix icon.
  final BoxConstraints? suffixIconConstraints;

  /// Constraints for the prefix icon.
  final BoxConstraints? prefixIconConstraints;

  /// Whether to use a larger field.
  /// 
  /// Increases the overall size of the field.
  final bool useBigField;

  /// Whether the field is enabled.
  /// 
  /// If `false`, the field is disabled and cannot be interacted with.
  final bool? enabled;

  /// Whether to show a label.
  /// 
  /// Controls the visibility of the label above the field.
  final bool needLabel;

  /// Whether to obscure text for passwords.
  /// 
  /// If `true`, the input text will be hidden, typically by displaying dots.
  final bool obscureText;

  /// Whether to use OTP input styling.
  /// 
  /// Applies a specific styling suitable for One-Time Passwords (OTPs).
  final bool useOtpDesign;

  /// Whether to replace the hint with the label.
  /// 
  /// If `true`, the label will be displayed as the placeholder text when the field is empty.
  final bool replaceHintWithLabel;

  /// Whether the field should autofocus.
  /// 
  /// If `true`, the field will automatically receive focus when the screen loads.
  final bool autofocus;

  /// Whether the field should ignore pointer interactions.
  /// 
  /// If `true`, the field will not respond to user input.
  final bool? ignorePointers;

  /// Whether interactive text selection is enabled.
  /// 
  /// Controls whether the user can select and interact with the text within the field.
  final bool? enableInteractiveSelection;

  /// Whether personalized IME learning is enabled.
  /// 
  /// Enables or disables personalized input method editor (IME) learning.
  final bool enableIMEPersonalizedLearning;

  /// Whether the cursor opacity animates.
  /// 
  /// Controls whether the cursor opacity should animate.
  final bool? cursorOpacityAnimates;

  /// Whether scribble input is enabled.
  /// 
  /// Enables or disables scribble input for handwriting recognition.
  final bool stylusHandwritingEnabled;

  /// Whether the field can request focus.
  /// 
  /// Controls whether the field can be programmatically focused.
  final bool canRequestFocus;

  /// Padding inside the field.
  /// 
  /// Controls the spacing between the edges of the field and its content.
  final EdgeInsets? padding;

  /// The default scroll padding.
  final EdgeInsets scrollPadding;

  /// The vertical text alignment.
  /// 
  /// Controls the vertical alignment of the text within the field.
  final TextAlignVertical? textAlignVertical;

  /// The text capitalization strategy.
  /// 
  /// Controls how the input text is capitalized (e.g., all uppercase, all lowercase).
  final TextCapitalization? textCapitalization;

  /// The auto-validation mode.
  /// 
  /// Controls when the field should be automatically validated.
  final AutovalidateMode? modeValidator;

  /// The maximum number of lines for the input.
  /// 
  /// Limits the number of lines that can be entered in the field.
  final int? maxLines;

  /// The minimum number of lines for the input.
  /// 
  /// Sets the minimum number of lines for the input.
  final int? minLines;

  /// Input formatters applied to the field.
  /// 
  /// Allows you to apply formatting rules to the input text 
  /// (e.g., masking, restricting input characters).
  final List<TextInputFormatter>? inputFormatters;

  /// A function to customize field decoration.
  /// 
  /// Allows you to customize the appearance of the field's 
  /// border, background, and other visual elements.
  final FieldDecorationConfigBuilder? inputDecorationBuilder;

  /// A function to customize the text settings of the label, hint and text
  /// 
  /// Allows you to customize the appearance of the text within the field, 
  /// such as font size, color, and weight.
  final FieldInputConfigBuilder? inputConfigBuilder;

  /// The text direction of the field.
  /// 
  /// Controls the direction of the text within the field
  final TextDirection? textDirection;

  /// The text alignment inside the field.
  final TextAlign? textAlign;

  /// The radius of the cursor.
  final Radius? cursorRadius;

  /// The keyboard appearance (light/dark mode).
  final Brightness? keyboardAppearance;

  /// Custom selection controls.
  final TextSelectionControls? selectionControls;

  /// Custom input counter widget.
  final InputCounterWidgetBuilder? buildCounter;

  /// The scroll physics for the field.
  final ScrollPhysics? scrollPhysics;

  /// Autofill hints for the input.
  final Iterable<String>? autofillHints;

  /// The mouse cursor when hovering over the field.
  final MouseCursor? mouseCursor;

  /// Context menu builder for text selection.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Configuration for spell checking.
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Configuration for text magnification.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Controller for undo/redo functionality.
  final UndoHistoryController? undoController;

  /// Callback for app private commands.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// The selection height style.
  final ui.BoxHeightStyle selectionHeightStyle;

  /// The selection width style.
  final ui.BoxWidthStyle selectionWidthStyle;

  /// The drag start behavior.
  final DragStartBehavior dragStartBehavior;

  /// Configuration for content insertion.
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// The clipping behavior of the field.
  final Clip clipBehavior;

  /// Callback for when the form is saved.
  final FormFieldSetter<String>? onSaved;

  /// Content cross axis alignment
  final CrossAxisAlignment? crossAxisAlignment;

  /// Handles auto correction
  final bool autoCorrect;

  /// Determines how the [maxLength] limit should be enforced.
  ///
  /// {@macro flutter.services.textFormatter.effectiveMaxLengthEnforcement}
  ///
  /// {@macro flutter.services.textFormatter.maxLengthEnforcement}
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Creates a standard text field.
  /// 
  /// [hint] is used as placeholder text.
  /// [textSize] determines the font size of the input text.
  /// [obscureText] can be set to true for password fields.
  /// Additional styling and functional properties are available.
  Field({
    super.key,
    this.controller,
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
    this.maxLengthEnforcement
  }) : _isPassword = false,
    icon = null,
    iconSize = null,
    iconColor = null,
    onPressed = null,
    iconSplashRadius = null,
    iconSplashColor = null,
    iconButtonColor = null;

  /// Creates a password field with an optional visibility toggle.
  /// 
  /// This constructor sets [_isPassword] to true, making it suitable for
  /// password input fields.
  Field.password({
    super.key,
    this.hint,
    this.controller,
    this.enabled,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onPressed,
    this.icon,
    this.inputAction = TextInputAction.next,
    this.keyboard,
    this.onChanged,
    this.focus,
    this.iconSize,
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
    this.iconColor,
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
    this.onSaved,
    this.crossAxisAlignment,
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
    this.iconSplashRadius,
    this.iconButtonColor,
    this.iconSplashColor,
    this.maxLengthEnforcement
  }) : _isPassword = true;

  /// Internal accessor to maintain states from the copyWith method.
  Field._internal({
    required this.controller,
    required this.enabled,
    required this.focus,
    required this.inputAction,
    required this.keyboard,
    required this.obscureText,
    required this.validator,
    required this.onChanged,
    required this.hint,
    required this.suffixIcon,
    required this.prefixIcon,
    required this.borderRadius,
    this.icon,
    this.onPressed,
    this.iconSize,
    required this.useOtpDesign,
    required this.fillColor,
    required this.suffixIconConstraints,
    required this.useBigField,
    required this.needLabel,
    required this.padding,
    required this.label,
    required this.spacing,
    required this.inputConfigBuilder,
    this.iconColor,
    required this.cursorColor,
    required this.cursorErrorColor,
    required this.cursorHeight,
    required this.prefixIconConstraints,
    required this.modeValidator,
    required this.textAlignVertical,
    required this.textCapitalization,
    required this.textAlign,
    required this.textDirection,
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
    required this.scrollController,
    required this.statesController,
    required this.onEditingComplete,
    required this.onTapOutside,
    required this.onFieldSubmitted,
    required this.replaceHintWithLabel,
    required this.ignorePointers,
    required this.enableInteractiveSelection,
    required this.cursorOpacityAnimates,
    required this.maxLines,
    required this.minLines,
    required this.inputFormatters,
    required this.inputDecorationBuilder,
    required this.cursorRadius,
    required this.contentInsertionConfiguration,
    required this.crossAxisAlignment,
    required this.onSaved,
    required this.cursorWidth,
    required this.autofocus,
    required this.enableIMEPersonalizedLearning,
    required this.stylusHandwritingEnabled,
    required this.canRequestFocus,
    required this.scrollPadding,
    required this.selectionHeightStyle,
    required this.selectionWidthStyle,
    required this.dragStartBehavior,
    required this.clipBehavior,
    required this.autoCorrect,
    required this.maxLengthEnforcement,
    bool isPassword = false,
    this.iconButtonColor,
    this.iconSplashColor,
    this.iconSplashRadius
  }) : _isPassword = isPassword;

  Field copyWith({
    TextEditingController? controller,
    ScrollController? scrollController,
    WidgetStatesController? statesController,
    IconData? icon,
    VoidCallback? onPressed,
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
    double? iconSize,
    double? iconSplashRadius,
    double? cursorHeight,
    double? borderRadius,
    double? spacing,
    double? cursorWidth,
    Widget? suffixIcon,
    Widget? prefixIcon,
    Color? fillColor,
    Color? cursorColor,
    Color? iconColor,
    Color? iconSplashColor,
    Color? iconButtonColor,
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
  }) {
    return Field._internal(
      controller: controller ?? this.controller,
      scrollController: scrollController ?? this.scrollController,
      statesController: statesController ?? this.statesController,
      icon: icon ?? this.icon,
      onPressed: onPressed ?? this.onPressed,
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
      iconSize: iconSize ?? this.iconSize,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      borderRadius: borderRadius ?? this.borderRadius,
      spacing: spacing ?? this.spacing,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      fillColor: fillColor ?? this.fillColor,
      cursorColor: cursorColor ?? this.cursorColor,
      iconColor: iconColor ?? this.iconColor,
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
      iconButtonColor: iconButtonColor ?? this.iconButtonColor,
      iconSplashColor: iconSplashColor ?? this.iconSplashColor,
      iconSplashRadius: iconSplashRadius ?? this.iconSplashRadius,
      isPassword: _isPassword,
      maxLengthEnforcement: maxLengthEnforcement ?? this.maxLengthEnforcement,
    );
  }

  @override
  Widget build(BuildContext context) {
    FieldInputConfig defConfig = FieldInputConfig();
    FieldInputConfig inputConfig = inputConfigBuilder.isNotNull ? inputConfigBuilder!(defConfig) : defConfig;

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
          _form(context, inputConfig)
        ],
      );
    } else {
      return _form(context, inputConfig);
    }
  }

  Widget _form(BuildContext context, FieldInputConfig inputConfig) {
    FieldDecorationConfig defaultConfig = FieldDecorationConfig();
    FieldDecorationConfig useConfig = inputDecorationBuilder.isNotNull ? inputDecorationBuilder!(defaultConfig) : defaultConfig;

    BorderRadius inputBorderRadius = BorderRadius.circular(borderRadius ?? 14);
    BorderStyle inputBorderStyle = BorderStyle.solid;
    Color error = CommonColors.instance.error;

    InputBorder enabledBorder = useConfig.enabledBorder ?? OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: useConfig.enabledBorderSide ?? BorderSide(
        width: 2,
        color: useConfig.useNotEnabled
          ? Theme.of(context).colorScheme.surface
          : inputConfig.textColor ?? Theme.of(context).primaryColor,
        style: inputBorderStyle,
      ),
    );

    InputBorder disabledBorder = useConfig.disabledBorder ?? OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: useConfig.disabledBorderSide ?? BorderSide(
        width: 2,
        color: useConfig.useNotEnabled
          ? Theme.of(context).colorScheme.surface
          : inputConfig.textColor ?? Theme.of(context).primaryColor,
        style: inputBorderStyle,
      ),
    );

    InputBorder focusedBorder = useConfig.focusedBorder ?? OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: useConfig.focusedBorderSide ?? BorderSide(
        width: 2,
        color: inputConfig.textColor ?? Theme.of(context).primaryColor,
        style: inputBorderStyle,
      ),
    );

    InputBorder errorBorder = useConfig.errorBorder ?? OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: useConfig.errorBorderSide ?? BorderSide(
        width: 2,
        color: error,
        style: inputBorderStyle,
      ),
    );

    InputBorder focusedErrorBorder = useConfig.focusedErrorBorder ?? OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: useConfig.focusedErrorBorderSide ?? BorderSide(
        width: 2,
        color: error,
        style: inputBorderStyle,
      ),
    );


    return TextFormField(
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
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
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
      decoration: InputDecoration(
        hintText: replaceHintWithLabel ? label : hint,
        contentPadding: useOtpDesign ? EdgeInsets.zero : padding,
        hintStyle: TextStyle(
          color: inputConfig.hintColor ?? CommonColors.instance.hint,
          fontSize: inputConfig.hintSize ?? inputConfig.textSize,
          fontWeight: inputConfig.hintWeight
        ),
        filled: true,
        suffixIcon: suffixIcon ?? (_isPassword ? _buildPasswordSuffixIcon(context) : null),
        suffixIconConstraints: suffixIconConstraints,
        prefixIconConstraints: prefixIconConstraints,
        prefixIcon: prefixIcon,
        fillColor: fillColor ?? Theme.of(context).scaffoldBackgroundColor,
        enabledBorder: enabledBorder,
        disabledBorder: disabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: focusedErrorBorder,
      ),
    );
  }

  Widget _buildPasswordSuffixIcon(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon ?? Icons.lock_rounded,
        size: iconSize ?? Sizing.font(24),
        color: iconColor ?? Theme.of(context).colorScheme.surface
      ),
      color: iconButtonColor,
      splashColor: iconSplashColor,
      splashRadius: iconSplashRadius,
    );
  }
}