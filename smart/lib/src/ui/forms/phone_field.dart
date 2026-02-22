import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/src/utilities/country/country_data.dart';
import 'package:smart/utilities.dart';

import '../export.dart';
import 'field_controller.dart';

/// Internal state class for tracking the currently selected country.
/// 
/// Used by [PhoneField] to manage country selection state.
/// 
/// {@macro field_state}
final class PhoneCountryState extends FieldState<Country> {
  PhoneCountryState(super.value);
}

/// Internal state class for tracking the country utility instance.
/// 
/// Contains the [CountryUtil] instance with the country list.
/// 
/// {@macro field_state}
final class PhoneCountryUtilState extends FieldState<CountryUtil> {
  PhoneCountryUtilState(super.value);
}

/// Internal state class for tracking custom validation messages.
/// 
/// Stores error messages from the [phoneValidator] callback.
/// 
/// {@macro field_state}
final class PhoneValidationMessageState extends FieldState<String?> {
  PhoneValidationMessageState([super.value]);
}

/// {@template phone_field}
/// A specialized text field for international phone number input with country selection.
/// 
/// Extends [Field] to provide phone number input with:
/// - Country code selection via a dropdown/picker
/// - Automatic phone number validation based on selected country
/// - Customizable flag display and country picker
/// - International phone number formatting and parsing
/// - Integration with phone autofill and dialers
/// 
/// ## Key Features
/// - **Country selection**: Visual flag + country code picker
/// - **Automatic validation**: Validates based on country-specific phone length
/// - **International support**: Built-in country database with dial codes
/// - **Customizable UI**: Flexible flag display and country picker
/// - **Type-safe data**: Returns [PhoneNumber] objects with structured data
/// 
/// ## Basic Usage
/// ```dart
/// PhoneField(
///   hint: 'Phone number',
///   onPhoneChanged: (phone) => print('Phone: ${phone.completeNumber}'),
/// )
/// 
/// // With country pre-selection
/// PhoneField(
///   hint: 'Mobile number',
///   initialCountry: 'US', // ISO country code
///   onPhoneChanged: (phone) => savePhone(phone),
/// )
/// ```
/// 
/// ## Country Selection
/// ```dart
/// // Custom country list
/// PhoneField(
///   countries: [
///     Country(code: 'US', name: 'United States', dialCode: '1'),
///     Country(code: 'GB', name: 'United Kingdom', dialCode: '44'),
///     Country(code: 'FR', name: 'France', dialCode: '33'),
///   ],
///   initialCountry: 'US',
/// )
/// 
/// // Custom flag display
/// PhoneField(
///   flagBuilder: (context, country, onChanged) {
///     return GestureDetector(
///       onTap: () => showCountryPicker(context, onChanged),
///       child: Row(
///         children: [
///           Text(country.flagEmoji),
///           SizedBox(width: 8),
///           Text('+${country.dialCode}'),
///         ],
///       ),
///     );
///   },
/// )
/// ```
/// 
/// ## Custom Styling
/// ```dart
/// // Flag button styling
/// PhoneField(
///   flagButtonDecoration: BoxDecoration(
///     border: Border(right: BorderSide(color: Colors.grey)),
///     borderRadius: BorderRadius.circular(8),
///   ),
///   flagButtonColor: Colors.white,
///   flagButtonPadding: EdgeInsets.all(8),
///   useFlagEmoji: true, // Use emoji flags instead of image assets
///   flagSize: 24,
///   flagTextSize: 14,
///   flagTextColor: Colors.blue,
/// )
/// ```
/// 
/// ## State Management
/// The field manages three internal states:
/// 1. `PhoneCountryState`: Currently selected country
/// 2. `PhoneCountryUtilState`: Country utility instance with country list
/// 3. `PhoneValidationMessageState`: Custom validation messages from phoneValidator
/// 
/// ```dart
/// final fieldController = FieldController();
/// PhoneField(
///   stateController: fieldController,
///   onInit: (controller) {
///     // Access states
///     final country = controller.find<PhoneCountryState>().value;
///     final validationMsg = controller.find<PhoneValidationMessageState>().value;
///   },
/// )
/// ```
/// 
/// ## Event Handling
/// ```dart
/// PhoneField(
///   onPhoneChanged: (phone) {
///     // PhoneNumber object with structured data
///     print('Country: ${phone.countryISOCode}');
///     print('Dial code: ${phone.countryCode}');
///     print('Number: ${phone.number}');
///     print('Complete: ${phone.completeNumber}');
///   },
///   onCountryChanged: (country) {
///     print('Country changed to: ${country.name} (+${country.dialCode})');
///   },
///   onChangeCountryClicked: (onChanged) {
///     // Custom country picker implementation
///     showModalBottomSheet(
///       context: context,
///       builder: (context) => CountryPicker(onCountrySelected: onChanged),
///     );
///   },
///   onPhoneSaved: (phone) {
///     // Save structured phone data
///     saveToDatabase(phone);
///   },
/// )
/// ```
/// 
/// ## Best Practices
/// 1. Always provide clear hints (default: "Phone Number")
/// 2. Consider using `autofillHints: [AutofillHints.telephoneNumber]`
/// 3. Pre-select country based on user's locale when appropriate
/// 4. Provide visual feedback for country selection
/// 5. Ensure country picker is accessible (keyboard navigation, screen readers)
/// 6. Validate phone numbers according to your business requirements
/// 
/// {@endtemplate}
final class PhoneField extends Field with FieldMixin {
  /// Called when the form is saved with a valid phone number.
  /// 
  /// Receives a structured [PhoneNumber] object containing:
  /// - `countryISOCode`: ISO country code (e.g., "US")
  /// - `countryCode`: Dial code with plus sign (e.g., "+1")
  /// - `number`: The local phone number part
  /// 
  /// The [PhoneNumber] class should provide a `completeNumber` getter
  /// that combines country code and number.
  final FormFieldSetter<PhoneNumber>? onPhoneSaved;

  /// Called whenever the phone number changes (on every keystroke).
  /// 
  /// Provides a [PhoneNumber] object even while the user is typing.
  /// Useful for real-time validation or formatting.
  final PhoneNumberChanged? onPhoneChanged;

  /// Called whenever the phone number changes and is valid.
  /// 
  /// Provides a [PhoneNumber] object even while the user is typing.
  /// Useful for real-time validation or formatting. This works for
  /// situations where the user wants to get the phone number when it is
  /// validated.
  final PhoneNumberChanged? onValidPhoneNumber;

  /// Called when the user selects a different country.
  /// 
  /// Provides the newly selected [Country] object.
  /// Useful for updating UI or performing country-specific logic.
  final SelectedCountryChanged? onCountryChanged;

  /// Called when the country selection button is clicked.
  /// 
  /// Allows complete customization of the country selection flow.
  /// You receive an `onChanged` callback that you should call
  /// when the user selects a new country.
  /// 
  /// Example:
  /// ```dart
  /// PhoneField(
  ///   onChangeCountryClicked: (onChanged) {
  ///     showModalBottomSheet(
  ///       context: context,
  ///       builder: (context) => CountryPicker(
  ///         onCountrySelected: onChanged,
  ///       ),
  ///     );
  ///   },
  /// )
  /// ```
  final WhenSelectedCountryChanged? onChangeCountryClicked;

  /// Custom builder for the flag/country code display.
  /// 
  /// When provided, overrides the default flag button.
  /// Gives you complete control over the flag widget's appearance and behavior.
  final PhoneFlagBuilder? flagBuilder;

  /// Custom asynchronous phone number validator.
  /// 
  /// Runs in addition to the built-in length validation.
  /// Return a string error message if validation fails, or null if valid.
  /// 
  /// Note: This runs asynchronously. The field will show loading/error
  /// states appropriately while validation is in progress.
  final PhoneNumberValidator? phoneValidator;

  /// Whether to disable country-specific phone length validation.
  /// 
  /// When `false` (default), validates that the phone number length
  /// is within the selected country's min/max length range.
  /// When `true`, only custom validators ([phoneValidator] and [validator]) run.
  final bool disableLengthCheck;

  /// Error message to show when phone number length validation fails.
  /// 
  /// Defaults to 'Invalid Mobile Number'.
  /// Only used when [disableLengthCheck] is `false`.
  final String phoneNumberErrorMessage;

  /// Custom list of countries to use instead of the default country database.
  /// 
  /// When null, uses `CountryData.instance.countries` (the default database).
  /// Useful for restricting to specific countries or adding custom entries.
  final List<Country>? countries;

  /// Initial country to select (ISO country code).
  /// 
  /// Examples: "US", "GB", "FR", "JP"
  /// If the country isn't found in the available countries list,
  /// falls back to the first available country.
  final String? initialCountry;

  /// Complete custom builder for the entire phone field.
  /// 
  /// When provided, overrides the entire field construction.
  /// Gives maximum flexibility for custom UI while still using
  /// the field's validation and state management.
  final PhoneFieldBuilder? phoneBuilder;
  
  // Flag styling properties

  /// Decoration for the default flag button container.
  /// 
  /// Only used when [flagBuilder] is null.
  final BoxDecoration? flagButtonDecoration;

  /// Padding around the entire flag button widget.
  /// 
  /// Only used when [flagBuilder] is null.
  final EdgeInsetsGeometry? flagButtonPadding;

  /// Background color for the flag button material.
  /// 
  /// Only used when [flagBuilder] is null.
  final Color? flagButtonColor;

  /// Padding inside the flag button's decorative box.
  /// 
  /// Only used when [flagBuilder] is null.
  final EdgeInsetsGeometry? flagButtonBoxPadding;

  /// Padding around the flag button's body (inside the Material widget).
  /// 
  /// Only used when [flagBuilder] is null.
  final EdgeInsetsGeometry? flagButtonBodyPadding;

  /// Whether to use flag emojis instead of image assets.
  /// 
  /// When `true`, uses emoji flags (🇺🇸, 🇬🇧, etc.)
  /// When `false`, uses image assets from the country data.
  /// Only used when [flagBuilder] is null.
  final bool useFlagEmoji;

  /// Size of the flag image/emoji in logical pixels.
  /// 
  /// Only used when [flagBuilder] is null.
  final double? flagSize;

  /// Spacing between the flag and the country code text.
  /// 
  /// Only used when [flagBuilder] is null.
  final double? flagSpacing;

  /// Font size for the country code text (+1, +44, etc.)
  /// 
  /// Only used when [flagBuilder] is null.
  final double? flagTextSize;

  /// Text color for the country code.
  /// 
  /// Only used when [flagBuilder] is null.
  final Color? flagTextColor;

  /// Main axis alignment for the flag button's row.
  /// 
  /// Only used when [flagBuilder] is null.
  final MainAxisAlignment? flagMainAxisAlignment;

  /// Main axis size for the flag button's row.
  /// 
  /// Only used when [flagBuilder] is null.
  final MainAxisSize? flagMainAxisSize;

  /// Cross axis alignment for the flag button's row.
  /// 
  /// Only used when [flagBuilder] is null.
  final CrossAxisAlignment? flagCrossAxisAlignment;

  /// {@macro phone_field}
  /// 
  /// ## Default Values
  /// - `keyboard`: `TextInputType.phone`
  /// - `hint`: "Phone Number"
  /// - `maxLines`: `1`
  /// - `autoCorrect`: `false`
  /// - `disableLengthCheck`: `false`
  /// - `phoneNumberErrorMessage`: 'Invalid Mobile Number'
  /// - `useFlagEmoji`: `true`
  /// 
  /// ## Initialization
  /// The constructor automatically:
  /// 1. Sets up the country utility with provided or default countries
  /// 2. Finds the initial country based on [initialCountry] parameter
  /// 3. Adds three states to the controller:
  ///    - `PhoneCountryState`: Current selected country
  ///    - `PhoneValidationMessageState`: Custom validation messages
  ///    - `PhoneCountryUtilState`: Country utility instance
  PhoneField({
    super.key,
    super.controller,
    super.stateController,
    FieldControllerValue? onInit,
    super.onBind,
    super.enabled,
    super.focus,
    super.inputAction,
    super.obscureText,
    super.validator,
    super.onChanged,
    super.hint = "Phone Number",
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
    super.filled,
    this.onPhoneSaved,
    this.onPhoneChanged,
    this.onCountryChanged,
    this.onChangeCountryClicked,
    this.flagBuilder,
    this.phoneValidator,
    this.disableLengthCheck = false,
    this.phoneNumberErrorMessage = 'Invalid Mobile Number',
    this.countries,
    this.initialCountry,
    this.flagButtonDecoration,
    this.flagButtonPadding,
    this.flagButtonColor,
    this.flagButtonBoxPadding,
    this.flagButtonBodyPadding,
    this.useFlagEmoji = true,
    this.flagSize,
    this.flagSpacing,
    this.flagTextSize,
    this.flagTextColor,
    this.flagMainAxisAlignment,
    this.flagMainAxisSize,
    this.flagCrossAxisAlignment,
    this.phoneBuilder,
    this.onValidPhoneNumber
  }) : super(
    keyboard: TextInputType.phone,
    onInit: (controller) {
      if (onInit case final onInit?) {
        onInit(controller);
      }

      // Setup countries registry and initial selection
      final countryUtil = CountryUtil.instance;
      countryUtil.set(countries ?? CountryData.instance.countries);
      
      // Add initial states to controller
      controller.add(PhoneCountryState(countryUtil.find(initialCountry ?? "")));
      controller.add(PhoneValidationMessageState());
      controller.add(PhoneCountryUtilState(countryUtil));
    },
  );

  /// {@macro field_copyWith}
  /// 
  /// Creates a copy of this phone field with updated properties.
  /// Includes all [PhoneField] specific properties in addition to
  /// the base [Field] properties.
  @override
  PhoneField copyWith({
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
    InputDecoration? inputDecoration,
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
    bool? filled,
    bool? autoCorrect,
    MaxLengthEnforcement? maxLengthEnforcement,
    FormFieldSetter<PhoneNumber>? onPhoneSaved,
    PhoneNumberChanged? onPhoneChanged,
    PhoneNumberChanged? onValidPhoneNumber,
    SelectedCountryChanged? onCountryChanged,
    WhenSelectedCountryChanged? onChangeCountryClicked,
    PhoneFlagBuilder? flagBuilder,
    PhoneNumberValidator? phoneValidator,
    bool? disableLengthCheck,
    String? phoneNumberErrorMessage,
    List<Country>? countries,
    String? initialCountry,
    PhoneFieldBuilder? phoneBuilder,
    BoxDecoration? flagButtonDecoration,
    EdgeInsetsGeometry? flagButtonPadding,
    Color? flagButtonColor,
    EdgeInsetsGeometry? flagButtonBoxPadding,
    EdgeInsetsGeometry? flagButtonBodyPadding,
    bool? useFlagEmoji,
    double? flagSize,
    double? flagSpacing,
    double? flagTextSize,
    Color? flagTextColor,
    MainAxisAlignment? flagMainAxisAlignment,
    MainAxisSize? flagMainAxisSize,
    CrossAxisAlignment? flagCrossAxisAlignment,
  }) {
    return PhoneField(
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
      filled: filled ?? this.filled,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      autoCorrect: autoCorrect ?? this.autoCorrect,
      maxLengthEnforcement: maxLengthEnforcement ?? this.maxLengthEnforcement,
      onPhoneSaved: onPhoneSaved ?? this.onPhoneSaved,
      onPhoneChanged: onPhoneChanged ?? this.onPhoneChanged,
      onCountryChanged: onCountryChanged ?? this.onCountryChanged,
      onChangeCountryClicked: onChangeCountryClicked ?? this.onChangeCountryClicked,
      flagBuilder: flagBuilder ?? this.flagBuilder,
      phoneValidator: phoneValidator ?? this.phoneValidator,
      inputDecoration: inputDecoration ?? this.inputDecoration,
      disableLengthCheck: disableLengthCheck ?? this.disableLengthCheck,
      phoneNumberErrorMessage: phoneNumberErrorMessage ?? this.phoneNumberErrorMessage,
      countries: countries ?? this.countries,
      initialCountry: initialCountry ?? this.initialCountry,
      phoneBuilder: phoneBuilder ?? this.phoneBuilder,
      flagButtonDecoration: flagButtonDecoration ?? this.flagButtonDecoration,
      flagButtonPadding: flagButtonPadding ?? this.flagButtonPadding,
      flagButtonColor: flagButtonColor ?? this.flagButtonColor,
      flagButtonBoxPadding: flagButtonBoxPadding ?? this.flagButtonBoxPadding,
      flagButtonBodyPadding: flagButtonBodyPadding ?? this.flagButtonBodyPadding,
      useFlagEmoji: useFlagEmoji ?? this.useFlagEmoji,
      flagSize: flagSize ?? this.flagSize,
      flagSpacing: flagSpacing ?? this.flagSpacing,
      flagTextSize: flagTextSize ?? this.flagTextSize,
      flagTextColor: flagTextColor ?? this.flagTextColor,
      flagMainAxisAlignment: flagMainAxisAlignment ?? this.flagMainAxisAlignment,
      flagMainAxisSize: flagMainAxisSize ?? this.flagMainAxisSize,
      onValidPhoneNumber: onValidPhoneNumber ?? this.onValidPhoneNumber,
      flagCrossAxisAlignment: flagCrossAxisAlignment ?? this.flagCrossAxisAlignment,
    );
  }

  @override
  Widget buildField(BuildContext context, FieldController fieldController) {
    if(phoneBuilder case final phoneBuilder?) {
      final country = fieldController.find<PhoneCountryState>().value;
      final util = fieldController.find<PhoneCountryUtilState>().value;

      return phoneBuilder(
        context,
        country,
        util.countries.isNotEmpty,
        // onCountryChanged
        (newCountry) => _handleChangedCountry(fieldController, newCountry),
        // onPhoneChanged
        (value) => whenChanged(value, fieldController),
        // validator
        (value) => whenValidated(value, fieldController),
        // onSaved
        (value) => whenSaved(value, fieldController),
      );
    }

    return super.buildField(context, fieldController);
  }

  @override
  Widget? getPrefixIcon(BuildContext context, FieldController fieldController) {
    final countryState = fieldController.find<PhoneCountryState>();
    final country = countryState.value;

    if (flagBuilder case final flagBuilder?) {
      return flagBuilder(context, country, (c) => _handleChangedCountry(fieldController, c));
    }

    final util = fieldController.find<PhoneCountryUtilState>();
    
    if (util.value.countries.isNotEmpty) {
      return Padding(
        padding: flagButtonPadding ?? const EdgeInsets.only(right: 3),
        child: _buildDefaultFlagButton(context, fieldController, country),
      );
    }
    
    return super.getPrefixIcon(context, fieldController);
  }

  /// Builds the default flag button with customizable styling.
  /// 
  /// Creates a Material+InkWell button showing the country flag and dial code.
  /// Applies all the flag styling properties ([flagButtonDecoration],
  /// [flagButtonColor], [flagSize], [flagTextSize], etc.)
  Widget _buildDefaultFlagButton(BuildContext context, FieldController controller, Country country) {
    final decoration = flagButtonDecoration ?? BoxDecoration(
      border: Border(right: BorderSide(color: Theme.of(context).primaryColor)),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomLeft: Radius.circular(10),
      ),
    );

    return Padding(
      padding: flagButtonBodyPadding ?? const EdgeInsets.only(left: 6),
      child: Material(
        color: flagButtonColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: decoration.borderRadius as BorderRadius?,
        child: InkWell(
          borderRadius: decoration.borderRadius as BorderRadius?,
          onTap: () => _changeCountry(controller),
          child: DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: flagButtonBoxPadding ?? EdgeInsets.all(Sizing.space(9)),
              child: Row(
                spacing: flagSpacing ?? 3,
                mainAxisSize: flagMainAxisSize ?? MainAxisSize.min,
                mainAxisAlignment: flagMainAxisAlignment ?? MainAxisAlignment.center,
                crossAxisAlignment: flagCrossAxisAlignment ?? CrossAxisAlignment.center,
                children: [
                  CountryUtil.instance.getFlag(
                    country,
                    useFlagEmoji: useFlagEmoji,
                    size: flagSize,
                  ),
                  TextBuilder(
                    text: '+${country.dialCode}',
                    size: flagTextSize ?? Sizing.font(14),
                    color: flagTextColor ?? Theme.of(context).primaryColor,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles tap on the country flag button.
  /// 
  /// If [onChangeCountryClicked] is provided, calls it with the country
  /// change callback. Otherwise, presumably shows a default country picker.
  void _changeCountry(FieldController controller) {
    if (onChangeCountryClicked case final onChangeCountryClicked?) {
      onChangeCountryClicked((c) => _handleChangedCountry(controller, c));
    }
  }

  /// Updates the selected country and notifies listeners.
  /// 
  /// Updates the [PhoneCountryState] in the controller and calls
  /// [onCountryChanged] callback if provided.
  void _handleChangedCountry(FieldController controller, Country country) {
    controller.update<PhoneCountryState, Country>(country);

    if (onCountryChanged case final onCountryChanged?) {
      onCountryChanged(country);
    }
  }

  @override
  void whenChanged(String value, FieldController fieldController) async {
    final country = fieldController.find<PhoneCountryState>().value;
    
    final phoneNumber = PhoneNumber(
      countryISOCode: country.code,
      countryCode: '+${country.dialCode}',
      number: value,
    );

    if (phoneValidator case final phoneValidator?) {
      final msg = await phoneValidator(phoneNumber);
      fieldController.update<PhoneValidationMessageState, String?>(msg);
    }

    if (onPhoneChanged case final onPhoneChanged?) {
      onPhoneChanged(phoneNumber);
    }

    validateAndSend(value, phoneNumber, fieldController);
    
    super.whenChanged(value, fieldController);
  }

  void validateAndSend(String value, PhoneNumber phoneNumber, FieldController fieldController) async {
    if (phoneValidator case final phoneValidator?) {
      final msg = await phoneValidator(phoneNumber);
      
      if (msg == null || msg.isEmpty) {
        if (onValidPhoneNumber case final onValidPhoneNumber?) {
          onValidPhoneNumber(phoneNumber);
        }
      } else {
        fieldController.update<PhoneValidationMessageState, String?>(msg);
      }
    } else {
      fieldController.update<PhoneValidationMessageState, String?>(null);

      if (whenValidated(value, fieldController) case final msg) {
        if (msg == null || msg.isEmpty) {
          if (onValidPhoneNumber case final onValidPhoneNumber?) {
            onValidPhoneNumber(phoneNumber);
          }
        } else {
          fieldController.update<PhoneValidationMessageState, String?>(msg);
        }
      }
    }
  }

  @override
  String? whenValidated(String? value, FieldController fieldController) {
    final country = fieldController.find<PhoneCountryState>().value;
    final validationMsg = fieldController.find<PhoneValidationMessageState>().value;

    if (!disableLengthCheck && value != null) {
      final isValid = value.length >= country.min && value.length <= country.max;
      if (!isValid) return phoneNumberErrorMessage;
    }

    return validationMsg;
  }

  @override
  void whenSaved(String? value, FieldController fieldController) {
    if (value case final value?) {
      final country = fieldController.find<PhoneCountryState>().value;
      final phoneNumber = PhoneNumber(
        countryISOCode: country.code,
        countryCode: '+${country.dialCode}',
        number: value,
      );

      if (onPhoneSaved case final onPhoneSaved?) {
        onPhoneSaved(phoneNumber);
      }

      validateAndSend(value, phoneNumber, fieldController);
    }

    super.whenSaved(value, fieldController);
  }
}