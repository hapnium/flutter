import 'package:hapnium/hapnium.dart';

import 'country_data.dart';

/// {@template country}
/// A representation of a country.
/// 
/// This class represents a country with its various attributes, including:
///  * `name`: The full name of the country (e.g., "Nigeria").
///  * `flag`: The emoji flag representation of the country (e.g., "🇳🇬").
///  * `code`: The ISO 3166-1 alpha-2 country code (e.g., "NG").
///  * `dialCode`: The country's dialing code (e.g., "+234").
///  * `min`: The minimum length of a valid phone number for this country (inclusive).
///  * `max`: The maximum length of a valid phone number for this country (inclusive).
///  * `image`: An optional image path or URL representing the country's flag.
/// 
/// {@endtemplate}
class Country with EqualsAndHashCode, ToString {
  /// The full name of the country (e.g., "Nigeria").
  final String name;

  /// The emoji flag representation of the country (e.g., "🇳🇬").
  final String flag;

  /// The ISO 3166-1 alpha-2 country code (e.g., "NG").
  final String code;

  /// The country's dialing code (e.g., "+234").
  final String dialCode;

  /// The minimum length of a valid phone number for this country (inclusive).
  final int min;

  /// The maximum length of a valid phone number for this country (inclusive).
  final int max;

  /// An optional image path or URL representing the country's flag.
  final String image;

  /// Creates a new `Country` object.

  /// All parameters are required.
  /// 
  /// {@macro country}
  Country({
    required this.name,
    required this.flag,
    required this.code,
    required this.dialCode,
    required this.min,
    required this.max,
    required this.image,
  });

  /// Creates a `Country` object from a JSON map.

  /// This factory constructor attempts to parse the provided JSON map
  /// and extract the necessary data to create a `Country` object.
  /// If a key is missing in the JSON, an empty string or default value (0 for integers)
  /// will be used for the corresponding field.
  /// 
  /// {@macro country}
  factory Country.fromJson(JsonMap json) {
    return Country(
      name: json["name"] ?? "",
      flag: json["flag"] ?? "",
      code: json["code"] ?? "",
      dialCode: json["dialCode"] ?? "",
      min: json["min"] ?? 0,
      max: json["max"] ?? 0,
      image: json["image"] ?? "",
    );
  }

  /// Converts the `Country` object back to a JSON map.

  JsonMap toJson() {
    return {
      "name": name,
      "flag": flag,
      "code": code,
      "dialCode": dialCode,
      "min": min,
      "max": max,
      "image": image,
    };
  }

  /// Checks if the provided value (case-insensitive) matches the country's name.

  bool matchesCountry(String value) => name.equalsIgnoreCase(value);

  /// Returns the primary country (currently set to Nigeria).
  /// 
  /// {@macro country}
  factory Country.primary() => CountryData.instance.nigeria;

  @override
  List<Object?> equalizedProperties() => [name, flag, code, dialCode, min, max, image];

  /// Finds a country by name (case-insensitive search).

  /// This static method searches for a country object within the internal list
  /// of countries maintained by `CountryUtil`. It performs a case-insensitive
  /// search on the country name. If a matching country is found, it is returned.
  /// Otherwise, the first country in the list is returned as a default.
  /// 
  /// {@macro country}
  static Country find(String name) {
    return CountryData.instance.countries.firstWhere((country) {
      return country.name.equalsIgnoreCase(name);
    }, orElse: () => CountryData.instance.countries.first);
  }
}