import 'package:flutter/widgets.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/utilities.dart';

import '../../typedefs.dart';
import '../password_field.dart';
import 'phone_number.dart';

/// {@template field_item}
/// A configuration model that describes a single input field used by
/// [SmartField].
///
/// `FieldItem` is a lightweight, immutable data object that defines how an
/// individual form field should behave and appear. It does **not** render UI
/// by itself—instead, it is interpreted and rendered by `SmartField` into a
/// concrete field widget such as:
///
/// - [Field] (default text input)
/// - [PasswordField] (via `PasswordFieldItem`)
/// - [PhoneField] (via `PhoneFieldItem`)
///
/// ### Responsibilities
/// A `FieldItem` is responsible for defining:
/// - Input behavior (keyboard type, obscuring text)
/// - Validation logic
/// - State management (controller, focus)
/// - Label and hint presentation
///
/// ### Immutability
/// `FieldItem` is immutable. To modify an existing instance, use [copyWith],
/// which creates a new instance with updated values.
///
/// ### Common Usage
/// ```dart
/// FieldItem(
///   label: 'Email',
///   hint: 'Enter your email',
///   type: TextInputType.emailAddress,
///   validator: validateEmail,
/// )
/// ```
///
/// ### Integration with SmartField
/// When passed to `SmartField`, each `FieldItem`:
/// - Is automatically converted into a concrete field widget
/// - Participates in form validation if wrapped in a `Form`
/// - Rebuilds when form state changes
///
/// ### Specialized Field Types
/// For advanced use cases, consider using:
/// - [PasswordFieldItem] for password inputs
/// - [PhoneFieldItem] for phone number inputs with country support
///
/// These subclasses extend `FieldItem` while preserving the same API shape.
///
/// See also:
/// - [SmartField]
/// - [PasswordFieldItem]
/// - [PhoneFieldItem]
/// {@endtemplate}
final class FieldItem {
  /// Controls the text being edited.
  ///
  /// If null, the underlying field widget will create its own controller.
  /// Providing a controller allows external access to the field value.
  final TextEditingController? controller;

  /// Hint text displayed when the field is empty.
  ///
  /// If [replaceHintWithLabel] is `true`, this may be replaced by [label]
  /// once the field gains focus.
  final String? hint;

  /// A descriptive label for the field.
  ///
  /// Typically displayed above or within the field depending on the
  /// implementation of the rendered widget.
  final String? label;

  /// The keyboard configuration for this field.
  ///
  /// Examples:
  /// - [TextInputType.emailAddress]
  /// - [TextInputType.number]
  /// - [TextInputType.phone]
  final TextInputType? type;

  /// Validation logic for the field.
  ///
  /// Should return `null` if the value is valid, or a string describing the
  /// error if invalid.
  final FieldValidator? validator;

  /// Callback invoked when the field value changes.
  ///
  /// This is triggered in addition to any form-level `onChanged` callback
  /// provided to [SmartField].
  final Consumer<String>? onChanged;

  /// Manages focus for the field.
  ///
  /// Useful for manual focus control, keyboard navigation, or advanced
  /// form workflows.
  final FocusNode? focus;

  /// Whether the field text should be obscured.
  ///
  /// Commonly used for sensitive inputs such as passwords.
  final bool obscureText;

  /// Whether the hint should be replaced by the label when focused.
  ///
  /// When `true`, the hint text may disappear and the label will take its place
  /// to reduce visual clutter.
  final bool replaceHintWithLabel;

  /// Creates a new [FieldItem].
  ///
  /// All parameters are optional, allowing flexible configuration based on
  /// the needs of the form.
  /// 
  /// {@macro field_item}
  const FieldItem({
    this.controller,
    this.hint,
    this.label,
    this.type,
    this.validator,
    this.onChanged,
    this.focus,
    this.obscureText = false,
    this.replaceHintWithLabel = false,
  });

  /// Creates a copy of this [FieldItem] with the given fields replaced.
  ///
  /// This is the preferred way to modify a `FieldItem`, as instances are
  /// immutable.
  FieldItem copyWith({
    TextEditingController? controller,
    String? hint,
    String? label,
    TextInputType? type,
    FieldValidator? validator,
    Consumer<String>? onChanged,
    FocusNode? focus,
    bool? obscureText,
    bool? replaceHintWithLabel,
  }) {
    return FieldItem(
      controller: controller ?? this.controller,
      hint: hint ?? this.hint,
      label: label ?? this.label,
      type: type ?? this.type,
      validator: validator ?? this.validator,
      onChanged: onChanged ?? this.onChanged,
      focus: focus ?? this.focus,
      obscureText: obscureText ?? this.obscureText,
      replaceHintWithLabel: replaceHintWithLabel ?? this.replaceHintWithLabel,
    );
  }
}

/// {@template password_field_item}
/// A specialized [FieldItem] for password input fields.
///
/// `PasswordFieldItem` configures a secure text field that:
/// - Obscures input text by default
/// - Uses a password-optimized keyboard
/// - Supports visibility toggling via an optional callback
///
/// This item is automatically detected by [SmartField] and rendered as a
/// [PasswordField] widget instead of a regular [Field].
///
/// ### Default Behavior
/// - `obscureText` defaults to `true`
/// - `TextInputType.visiblePassword` is enforced
/// - Visibility toggle support is optional
///
/// ### Visibility Toggle
/// The [onVisibilityTapped] callback allows integration with UI controls
/// (such as an eye icon) to toggle password visibility.
///
/// The actual visibility state is controlled by the rendered field widget,
/// while this callback provides a hook for reacting to user interaction.
///
/// ### Common Usage
/// ```dart
/// PasswordFieldItem(
///   label: 'Password',
///   hint: 'Enter your password',
///   validator: validatePassword,
///   onVisibilityTapped: () {
///     // Handle visibility toggle
///   },
/// )
/// ```
///
/// ### Integration with SmartField
/// When used inside a `SmartField`:
/// - It is automatically rendered as a [PasswordField]
/// - It participates in form validation
/// - It respects form-level autovalidation and navigation guards
///
/// ### Immutability
/// Like all `FieldItem` subclasses, `PasswordFieldItem` is immutable.
/// Use [copyWith] to create modified instances.
///
/// See also:
/// - [FieldItem]
/// - [PasswordField]
/// - [SmartField]
/// {@endtemplate}
final class PasswordFieldItem extends FieldItem {
  /// Called when the password visibility toggle is tapped.
  ///
  /// This callback is typically wired to an icon button that switches
  /// between obscured and visible text.
  final OnPasswordVisibilityTapped? onVisibilityTapped;

  /// Creates a new [PasswordFieldItem].
  ///
  /// The field:
  /// - Uses [TextInputType.visiblePassword]
  /// - Obscures text by default
  /// 
  /// {@macro password_field_item}
  const PasswordFieldItem({
    super.controller,
    super.hint,
    super.label,
    super.validator,
    super.onChanged,
    super.focus,
    super.replaceHintWithLabel,
    super.obscureText = true,
    this.onVisibilityTapped,
  }) : super(type: TextInputType.visiblePassword);

  /// Creates a copy of this [PasswordFieldItem] with the given fields replaced.
  ///
  /// This preserves immutability while allowing selective updates.
  @override
  PasswordFieldItem copyWith({
    TextEditingController? controller,
    String? hint,
    String? label,
    TextInputType? type,
    FieldValidator? validator,
    Consumer<String>? onChanged,
    FocusNode? focus,
    bool? obscureText,
    bool? replaceHintWithLabel,
    OnPasswordVisibilityTapped? onVisibilityTapped,
  }) {
    return PasswordFieldItem(
      controller: controller ?? this.controller,
      hint: hint ?? this.hint,
      label: label ?? this.label,
      validator: validator ?? this.validator,
      onChanged: onChanged ?? this.onChanged,
      focus: focus ?? this.focus,
      replaceHintWithLabel: replaceHintWithLabel ?? this.replaceHintWithLabel,
      obscureText: obscureText ?? this.obscureText,
      onVisibilityTapped: onVisibilityTapped ?? this.onVisibilityTapped,
    );
  }
}

/// {@template phone_field_item}
/// A specialized [FieldItem] for phone number input with country support.
///
/// `PhoneFieldItem` configures a phone number field that:
/// - Uses a phone-optimized keyboard
/// - Supports country selection
/// - Provides structured phone number validation
/// - Emits strongly-typed [PhoneNumber] values
///
/// When used inside a [SmartField], this item is automatically rendered
/// as a [PhoneField] widget instead of a standard text [Field].
///
/// ### Key Features
/// - Country-aware phone number formatting
/// - Optional country restriction
/// - Strongly-typed change and save callbacks
/// - Custom phone number validation
///
/// ### Default Behavior
/// - `TextInputType.phone` is enforced
/// - Hint defaults to `"Phone Number"`
///
/// ### Country Handling
/// - [initialCountry] defines the initially selected country
/// - [countries] can be used to restrict available country options
///
/// If neither is provided, the field falls back to the widget’s default
/// country behavior.
///
/// ### Phone Number Callbacks
/// - [onPhoneChanged] emits a [PhoneNumber] object whenever the value changes
/// - [onPhoneSaved] emits the final [PhoneNumber] when the form is saved
///
/// These callbacks complement the string-based [onChanged] callback inherited
/// from [FieldItem].
///
/// ### Validation
/// Use [phoneValidator] to validate structured phone numbers instead of
/// raw strings. This validator is evaluated by the rendered [PhoneField].
///
/// ### Common Usage
/// ```dart
/// PhoneFieldItem(
///   label: 'Phone',
///   initialCountry: 'US',
///   phoneValidator: validatePhoneNumber,
///   onPhoneChanged: (phone) {
///     // Handle phone number change
///   },
/// )
/// ```
///
/// ### Integration with SmartField
/// When included in a `SmartField`:
/// - It is rendered as a [PhoneField]
/// - It participates in form validation
/// - It respects form-level autovalidation and navigation guards
///
/// ### Immutability
/// Like all `FieldItem` subclasses, `PhoneFieldItem` is immutable.
/// Use [copyWith] to create modified instances.
///
/// See also:
/// - [FieldItem]
/// - [PhoneField]
/// - [PasswordFieldItem]
/// - [SmartField]
/// {@endtemplate}
final class PhoneFieldItem extends FieldItem {
  /// Called when the form containing this field is saved.
  ///
  /// Emits the final [PhoneNumber] value.
  final FormFieldSetter<PhoneNumber>? onPhoneSaved;

  /// Called whenever the phone number value changes.
  ///
  /// Emits a structured [PhoneNumber] instead of a raw string.
  final ValueChanged<PhoneNumber>? onPhoneChanged;

  /// The ISO country code to use as the initially selected country.
  ///
  /// Example values: `"US"`, `"GB"`, `"NG"`.
  final String? initialCountry;

  /// A list of supported countries for selection.
  ///
  /// When provided, limits the available country options.
  final List<Country>? countries;

  /// Validation logic for structured phone numbers.
  ///
  /// Should return `null` if the phone number is valid, or an error message
  /// if invalid.
  final PhoneNumberValidator? phoneValidator;

  /// Creates a new [PhoneFieldItem].
  ///
  /// The field:
  /// - Uses [TextInputType.phone]
  /// - Defaults the hint to `"Phone Number"`
  /// 
  /// {@macro phone_field_item}
  const PhoneFieldItem({
    super.controller,
    super.hint = "Phone Number",
    super.label,
    super.onChanged,
    super.focus,
    super.replaceHintWithLabel,
    this.onPhoneSaved,
    this.onPhoneChanged,
    this.initialCountry,
    this.countries,
    this.phoneValidator,
  }) : super(type: TextInputType.phone);

  /// Creates a copy of this [PhoneFieldItem] with the given fields replaced.
  ///
  /// This preserves immutability while allowing selective updates.
  @override
  PhoneFieldItem copyWith({
    TextEditingController? controller,
    String? hint,
    String? label,
    TextInputType? type,
    FieldValidator? validator,
    Consumer<String>? onChanged,
    FocusNode? focus,
    bool? obscureText,
    bool? replaceHintWithLabel,
    FormFieldSetter<PhoneNumber>? onPhoneSaved,
    ValueChanged<PhoneNumber>? onPhoneChanged,
    String? initialCountry,
    List<Country>? countries,
    PhoneNumberValidator? phoneValidator,
  }) {
    return PhoneFieldItem(
      controller: controller ?? this.controller,
      hint: hint ?? this.hint,
      label: label ?? this.label,
      onChanged: onChanged ?? this.onChanged,
      focus: focus ?? this.focus,
      replaceHintWithLabel:
          replaceHintWithLabel ?? this.replaceHintWithLabel,
      onPhoneSaved: onPhoneSaved ?? this.onPhoneSaved,
      onPhoneChanged: onPhoneChanged ?? this.onPhoneChanged,
      initialCountry: initialCountry ?? this.initialCountry,
      countries: countries ?? this.countries,
      phoneValidator: phoneValidator ?? this.phoneValidator,
    );
  }
}