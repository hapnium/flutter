// ignore_for_file: constant_identifier_names

import 'dart:convert';

import '../../definitions.dart';

/// {@template is_token_char}
/// Checks whether a byte value is a valid HTTP token character.
///
/// HTTP token characters are defined in RFC 7230 as any visible ASCII character
/// except delimiters. This function is used for validating HTTP header field names.
///
/// ## Parameters
/// - [byte]: The byte value to check (0-127).
///
/// ## Returns
/// `true` if the byte is a valid token character.
///
/// ## Example
/// ```dart
/// if (isTokenChar(65)) { // 'A'
///   print('Valid token character');
/// }
/// ```
/// {@endtemplate}
bool isTokenChar(int byte) {
  return byte > 31 && byte < 128 && !SEPARATOR_MAP[byte];
}

/// {@template is_value_char}
/// Checks whether a byte value is a valid HTTP header value character.
///
/// HTTP header value characters include visible ASCII characters, space,
/// and horizontal tab. This function is used for validating HTTP header values.
///
/// ## Parameters
/// - [byte]: The byte value to check (0-127).
///
/// ## Returns
/// `true` if the byte is a valid value character.
///
/// ## Example
/// ```dart
/// if (isValueChar(32)) { // space
///   print('Valid value character');
/// }
/// ```
/// {@endtemplate}
bool isValueChar(int byte) {
  return (byte > 31 && byte < 128) ||
      (byte == CharCode.SP) ||
      (byte == CharCode.HT);
}

/// {@template char_code}
/// Character code constants for HTTP protocol characters.
///
/// These constants define the ASCII codes for commonly used characters
/// in HTTP headers and protocol parsing.
///
/// ## Example
/// ```dart
/// if (byte == CharCode.CR) {
///   print('Carriage return');
/// }
/// ```
/// {@endtemplate}
class CharCode {
  /// Horizontal tab character (ASCII 9).
  static const int HT = 9;

  /// Line feed character (ASCII 10).
  static const int LF = 10;

  /// Carriage return character (ASCII 13).
  static const int CR = 13;

  /// Space character (ASCII 32).
  static const int SP = 32;

  /// Comma character (ASCII 44).
  static const int COMMA = 44;

  /// Forward slash character (ASCII 47).
  static const int SLASH = 47;

  /// Zero digit character (ASCII 48).
  static const int ZERO = 48;

  /// One digit character (ASCII 49).
  static const int ONE = 49;

  /// Colon character (ASCII 58).
  static const int COLON = 58;

  /// Semicolon character (ASCII 59).
  static const int SEMI_COLON = 59;
}

/// Boolean constant for false (used in SEPARATOR_MAP).
const bool F = false;

/// Boolean constant for true (used in SEPARATOR_MAP).
const bool T = true;

/// Separator map for HTTP token character validation.
///
/// This map identifies ASCII characters that are not valid in HTTP token names.
/// Separators include spaces, tabs, and various punctuation marks.
const SEPARATOR_MAP = [
  F, F, F, F, F, F, F, F, F, T, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, T, F, T, F, F, F, F, F, T, T, F, F, T, F, F, T, //
  F, F, F, F, F, F, F, F, F, F, T, T, T, T, T, T, T, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, T, T, T, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, T, F, T, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, //
  F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F
];

/// Validates an HTTP header field name.
///
/// Checks that all characters in [field] are valid HTTP token characters.
/// Returns the lowercased field name if valid.
///
/// ## Parameters
/// - [field]: The header field name to validate.
///
/// ## Returns
/// The lowercased field name.
///
/// ## Throws
/// [FormatException] if the field contains invalid characters.
///
/// ## Example
/// ```dart
/// final name = validateField('Content-Type');
/// print(name); // 'content-type'
/// ```
String validateField(String field) {
  for (var i = 0; i < field.length; i++) {
    if (!isTokenChar(field.codeUnitAt(i))) {
      throw FormatException(
          'Invalid HTTP header field name: ${json.encode(field)}', field, i);
    }
  }
  return field.toLowerCase();
}

/// Regular expression for matching ASCII-only strings.
final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

/// Regular expression for matching newline characters.
///
/// Matches `\r\n`, `\r`, or `\n`.
final newlineRegExp = RegExp(r'\r\n|\r|\n');

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
///
/// ## Parameters
/// - [string]: The string to check.
///
/// ## Returns
/// `true` if the string contains only ASCII characters.
///
/// ## Example
/// ```dart
/// if (isPlainAscii('Hello')) {
///   print('Pure ASCII');
/// }
/// ```
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

/// {@template get_boundary}
/// The default boundary prefix for multipart form data.
///
/// This is used as the base string for generating unique boundaries
/// for multipart/form-data requests.
/// {@endtemplate}
const String GET_BOUNDARY = 'hap-http-boundary-';

/// {@template browser_encode}
/// Encodes a value for safe use in HTTP headers.
///
/// Replaces newlines with `%0D%0A` and double quotes with `%22` to prevent
/// header injection attacks.
///
/// ## Parameters
/// - [value]: The value to encode.
///
/// ## Returns
/// The encoded value safe for use in headers.
///
/// ## Example
/// ```dart
/// final safe = browserEncode('Hello\nWorld');
/// // 'Hello%0D%0AWorld'
/// ```
/// {@endtemplate}
String browserEncode(String value) {
  return value.replaceAll(newlineRegExp, '%0D%0A').replaceAll('"', '%22');
}

/// List of valid boundary characters for multipart boundaries.
///
/// Contains ASCII alphanumeric characters plus `+`, `_`, and `-`.
const BodyBytes boundaryCharacters = <int>[
  43,  // +
  95,  // _
  45,  // -
  46,  // .
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, // 0-9
  65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, // A-Z
  97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122 // a-z
];

/// Returns the [Encoding] that corresponds to [charset].
///
/// ## Parameters
/// - [charset]: The charset name (e.g., 'utf-8', 'iso-8859-1').
/// - [fallback]: The fallback encoding if charset is null or unknown.
///
/// ## Returns
/// The matching [Encoding], or [fallback].
///
/// ## Example
/// ```dart
/// final encoding = encodingForCharset('utf-8');
/// // Returns utf8 encoding
/// ```
Encoding encodingForCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) {
    return fallback;
  }
  final encoding = Encoding.getByName(charset);
  return encoding ?? fallback;
}