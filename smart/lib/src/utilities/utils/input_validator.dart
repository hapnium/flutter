// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:hapnium/hapnium.dart';

/// {@template input_validator}
/// A utility class for validating common user inputs such as email, text, and password.
/// 
/// {@endtemplate}
class InputValidator {
  InputValidator._();
  
  /// Validates an email address.
  ///
  /// Users can customize the regex by adding a specific domain or modifying parts of the default pattern.
  ///
  /// - [email]: The email address to validate.
  /// - [appendDomain]: A specific domain to enforce in the email (e.g., "example.com").
  /// - [pattern]: A custom regex pattern for email validation.
  /// - [success]: A success message to return if the email is valid.
  /// - [error]: An error message to return if the email is invalid or empty.
  static String? email(String? email, {
    /// Domain to append for specific validation, such as "@example.com".
    String? appendDomain,

    /// A custom regex pattern for validating the email.
    String? pattern,

    /// Message to return when validation passes.
    String? success,

    /// Message to return when validation fails.
    String? error,
  }) {
    if (email.isNull) {
      return error ?? 'Email is required';
    } else {
      String defaultPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+';
      String domainPattern = appendDomain != null ? '@$appendDomain' : r'\.[a-zA-Z]{2,}$';

      RegExp regex = RegExp(pattern ?? (defaultPattern + domainPattern));

      if (regex.hasMatch(email!)) {
        return success;
      } else {
        return error ?? 'Invalid email address. Ensure it matches the format username@domain.com.';
      }
    }
  }

  /// Validates a text value.
  ///
  /// Users can customize whether to enforce uppercase, length, and character set.
  ///
  /// - [text]: The text to validate.
  /// - [allowUppercase]: Whether uppercase letters are allowed in the text.
  /// - [minLength]: The minimum length of the text.
  /// - [maxLength]: The maximum length of the text.
  /// - [id]: A label for the text field (e.g., "Username" or "Name").
  /// - [pattern]: A custom regex pattern for text validation.
  /// - [success]: A success message to return if the text is valid.
  /// - [error]: An error message to return if the text is invalid or empty.
  static String? text(String? text, {
    /// Whether uppercase characters are allowed.
    bool allowUppercase = true,

    /// Minimum length for the text input.
    int minLength = 2,

    /// Maximum length for the text input.
    int maxLength = 50,

    /// Identifier for the text field (e.g., "Username").
    String id = "Text",

    /// A custom regex pattern for validation.
    String? pattern,

    /// Message to return when validation passes.
    String? success,

    /// Message to return when validation fails.
    String? error,
  }) {
    if (text.isNull) {
      return error ?? '$id is required';
    } else {
      String defaultPattern = r'^[A-Za-z';
      if (allowUppercase) defaultPattern += 'A-Z';
      defaultPattern += ']{' + minLength.toString() + ',' + maxLength.toString() + r'}$';

      RegExp regex = RegExp(pattern ?? defaultPattern);

      if (regex.hasMatch(text!)) {
        return success;
      } else {
        if (text.length < minLength) {
          return error ?? '$id must be at least $minLength characters long.';
        } else if (text.length > maxLength) {
          return error ?? '$id must not exceed $maxLength characters.';
        }
        return error ?? 'Invalid $id. Ensure it follows the expected format.';
      }
    }
  }

  /// Validates a password.
  ///
  /// Users can toggle requirements for uppercase, lowercase, numbers, and special characters.
  ///
  /// - [password]: The password to validate.
  /// - [requireUppercase]: Whether the password must include an uppercase letter.
  /// - [requireLowercase]: Whether the password must include a lowercase letter.
  /// - [requireNumber]: Whether the password must include at least one number.
  /// - [requireSpecialChar]: Whether the password must include a special character (e.g., @, $, %, &).
  /// - [minLength]: The minimum length of the password.
  /// - [pattern]: A custom regex pattern for password validation.
  /// - [success]: A success message to return if the password is valid.
  /// - [error]: An error message to return if the password is invalid or empty.
  /// - [addToPattern]: Whether to add the [pattern] to the existing pattern logic. [pattern] must be provided.
  static String? password(String? password, {
    /// Whether uppercase letters are required in the password.
    bool requireUppercase = true,

    /// Whether lowercase letters are required in the password.
    bool requireLowercase = true,

    /// Whether a number is required in the password.
    bool requireNumber = true,

    /// Whether a special character is required in the password.
    bool requireSpecialChar = true,

    /// Whether to add [pattern] to the existing pattern logic.
    bool addToPattern = false,

    /// Minimum length of the password.
    int minLength = 8,

    /// A custom regex pattern for validation.
    String? pattern,

    /// Message to return when validation passes.
    String? success,

    /// Message to return when validation fails.
    String? error,
  }) {
    assert(!addToPattern || (addToPattern && pattern != null), 'If addToPattern is true, pattern must be provided.');

    if (password.isNull) {
      return error ?? 'Password is required';
    } else {
      String defaultPattern = r'^';
      String upperCasePattern = r'(?=.*[A-Z])';
      String lowerCasePattern =r'(?=.*[a-z])';
      String numberPattern = r'(?=.*\d)';
      String specialCharacterPattern = r'(?=.*[@$!%*?&])';

      if (requireUppercase) defaultPattern += upperCasePattern;
      if (requireLowercase) defaultPattern += lowerCasePattern;
      if (requireNumber) defaultPattern += numberPattern;
      if (requireSpecialChar) defaultPattern += specialCharacterPattern;
      if(addToPattern) defaultPattern += pattern!;

      defaultPattern += r'.{' + minLength.toString() + r',}$';
      defaultPattern = addToPattern ? defaultPattern : pattern ?? defaultPattern;

      RegExp regex = RegExp(defaultPattern);

      if (regex.hasMatch(password!)) {
        return success;
      } else {
        List<String> missing = [];
        if (requireUppercase && !RegExp(upperCasePattern).hasMatch(password)) {
          missing.add('uppercase letter');
        }
        if (requireLowercase && !RegExp(lowerCasePattern).hasMatch(password)) {
          missing.add('lowercase letter');
        }
        if (requireNumber && !RegExp(numberPattern).hasMatch(password)) {
          missing.add('number');
        }
        if (requireSpecialChar && !RegExp(specialCharacterPattern).hasMatch(password)) {
          missing.add('special character');
        }
        if (password.length < minLength) {
          missing.add('at least $minLength characters');
        }

        return error ?? 'Password is invalid. Missing: ${missing.join(', ')}.';
      }
    }
  }
}