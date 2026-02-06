import 'package:hapnium/hapnium.dart';

/// A model representing a phone number with country-specific details.
///
/// This class helps manage phone numbers by storing the country ISO code, 
/// country calling code, and the local phone number.
///
/// Example usage:
/// ```dart
/// PhoneNumber phone = PhoneNumber(
///   countryISOCode: "US",
///   countryCode: "+1",
///   number: "1234567890",
/// );
///
/// print(phone.completeNumber); // Output: +11234567890
/// print(phone.toString()); 
/// // Output: PhoneNumber(countryISOCode: US, countryCode: +1, number: 1234567890)
/// ```
class PhoneNumber with EqualsAndHashCode, ToString {
  /// The **ISO country code** (e.g., "US" for United States, "IN" for India).
  ///
  /// This is a **two-letter** country code representing the country 
  /// associated with the phone number.
  final String countryISOCode;

  /// The **country calling code** (e.g., "+1" for the USA, "+91" for India).
  ///
  /// This is the **international dialing prefix** used to call numbers 
  /// in the respective country.
  final String countryCode;

  /// The **actual phone number** (excluding the country code).
  ///
  /// This is the **local** phone number assigned within the country.
  final String number;

  /// Creates an instance of [PhoneNumber].
  ///
  /// Requires all three parameters:
  /// - [countryISOCode]: The ISO 3166-1 alpha-2 country code (e.g., "US").
  /// - [countryCode]: The country calling code (e.g., "+1").
  /// - [number]: The actual phone number.
  ///
  /// Example:
  /// ```dart
  /// PhoneNumber(
  ///   countryISOCode: "GB",
  ///   countryCode: "+44",
  ///   number: "7911123456",
  /// );
  /// ```
  const PhoneNumber({
    required this.countryISOCode,
    required this.countryCode,
    required this.number,
  });

  /// Returns the **complete phone number** with the country code.
  ///
  /// Example:
  /// ```dart
  /// PhoneNumber phone = PhoneNumber(countryISOCode: "US", countryCode: "+1", number: "9876543210");
  /// print(phone.completeNumber); // Output: +19876543210
  /// ```
  String get completeNumber => countryCode + number;

  @override
  List<Object?> equalizedProperties() => [countryCode, countryISOCode, number];

  /// Returns a string representation of the phone number.
  ///
  /// Example:
  /// ```dart
  /// PhoneNumber phone = PhoneNumber(countryISOCode: "FR", countryCode: "+33", number: "612345678");
  /// print(phone.toString());
  /// // Output: PhoneNumber(countryISOCode: FR, countryCode: +33, number: 612345678)
  /// ```
  @override
  String toString() => 'PhoneNumber(countryISOCode: $countryISOCode, countryCode: $countryCode, number: $number)';
}