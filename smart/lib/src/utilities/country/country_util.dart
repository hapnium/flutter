/// Utility class for country-related operations.
library;
import 'package:flutter/widgets.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/ui.dart';

import 'country.dart';
import 'country_data.dart';

/// {@template country_util}
/// Utility class for country-related operations.
/// 
/// This class is **not meant to be instantiated** and should be accessed statically.
/// 
/// {@endtemplate}
class CountryUtil {
  CountryUtil._internal();

  /// The singleton instance of [CountryUtil].
  /// 
  /// {@macro country_util}
  static CountryUtil instance = CountryUtil._internal();

  List<Country> _list = [];
  void set (List<Country> countries) {
    if(countries.isNotEmpty) {
      _list = countries;
    } else {
      _list = CountryData.instance.countries;
    }
  }

  List<Country> get countries => _list.isEmpty ? CountryData.instance.countries : _list;

  /// Finds a country by its name.
  Country findByName(String name) {
    return countries.firstWhere((country) {
      return country.name.equalsIgnoreCase(name);
    }, orElse: () => countries.first);
  }

  /// Finds a country by its country code.
  Country findByCode(String code) {
    return countries.firstWhere((country) {
      return country.code.equalsIgnoreCase(code);
    }, orElse: () => countries.first);
  }

  /// Finds a country by its dial code.
  Country findByDialCode(String dialCode) {
    return countries.firstWhere((country) {
      return country.dialCode.equalsIgnoreCase(dialCode);
    }, orElse: () => countries.first);
  }

  /// Finds a country by its flag.
  Country findByFlag(String flag) {
    return countries.firstWhere((country) {
      return country.flag.equalsIgnoreCase(flag);
    }, orElse: () => countries.first);
  }

  /// Finds a country by its associated image.
  Country findByImage(String image) {
    return countries.firstWhere((country) {
      return country.image.equalsIgnoreCase(image);
    }, orElse: () => countries.first);
  }

  /// Finds a country by either its country code or dial code.
  Country findByCodeOrDialCode(String value) {
    return countries.firstWhere((country) {
      return value.equalsAny([country.dialCode, country.code], isIgnoreCase: true);
    }, orElse: () => countries.first);
  }

  /// Finds a country by either its country code or name.
  Country findByCodeOrName(String value) {
    return countries.firstWhere((country) {
      return value.equalsAny([country.code, country.name], isIgnoreCase: true);
    }, orElse: () => countries.first);
  }

  /// Finds a country by either its country code or flag.
  Country findByCodeOrFlag(String value) {
    return countries.firstWhere((country) {
      return value.equalsAny([country.code, country.flag], isIgnoreCase: true);
    }, orElse: () => countries.first);
  }

  /// Finds a country by either its country code or associated image.
  Country findByCodeOrImage(String value) {
    return countries.firstWhere((country) {
      return value.equalsAny([country.code, country.image], isIgnoreCase: true);
    }, orElse: () => countries.first);
  }

  /// Finds a country by any of its attributes: dial code, code, image, flag, or name.
  Country find(String value) {
    return countries.firstWhere((country) {
      return value.equalsAny([country.dialCode, country.code, country.image, country.flag, country.name], isIgnoreCase: true);
    }, orElse: () => countries.first);
  }

  /// This returns the proper widget for displaying the flag image or flag emoji
  Widget getFlag(Country country, {bool useFlagEmoji = false, double? size}) {
    if(useFlagEmoji.isFalse || country.image.isNotEmpty) {
      return Image.network(country.image, width: size ?? 32);
    } else {
      return TextBuilder(text: country.flag, size: size ?? 18);
    }
  }

  /// Finds the country that most likely matches the given phone number.
  ///
  /// This method attempts to identify the correct country using the following logic:
  ///
  /// 1. **Dial Code with '+'**: If the number starts with '+', it strips the '+' and
  ///    checks which country's dial code it starts with (e.g., "+234" → Nigeria).
  ///
  /// 2. **Dial Code without '+'**: If the number does not start with '+', it checks
  ///    if it starts with any known dial code (e.g., "234803..." → Nigeria).
  ///
  /// 3. **Length-based Matching**: If no dial code matches, it attempts to match the
  ///    number to a country based on whether its length falls within the country's
  ///    expected `min` and `max` phone number lengths.
  ///
  /// 4. **Fallback**: If no match is found using the above strategies, the first
  ///    country in the list is returned as a fallback.
  ///
  /// This method assumes that the country data (with dial codes and number lengths)
  /// is already initialized in `CountryUtil`.
  ///
  /// Example inputs and expected behavior:
  ///
  /// - "+2348011111111" → Matches Nigeria
  /// - "2348011111111"  → Matches Nigeria
  /// - "08011111111"    → Falls back to length match (Nigeria if it fits)
  /// - "14155552671"    → Matches USA
  ///
  /// Parameters:
  /// - [phoneNumber]: The input phone number string (can be raw, formatted, or with '+').
  /// - [countryLocale]: The default country to use if no match is found.
  ///
  /// Returns:
  /// - A [Country] object representing the most likely match.
  Country findByPhoneNumber(String phoneNumber, {String countryLocale = ""}) {
    List<Country> sorted = countries..sort((Country a, Country b) => b.dialCode.length.compareTo(a.dialCode.length));

    // 1. If it starts with '+', extract dial code and match
    if (phoneNumber.startsWith('+')) {
      for (Country country in sorted) {
        if (phoneNumber.startsWith(country.dialCode)) {
          return country;
        }
      }
    }

    // 2. If it doesn't start with '+', try matching dial codes without '+'
    for (Country country in sorted) {
      if (phoneNumber.startsWith(country.dialCode)) {
        return country;
      }
    }

    // 3. Fallback: Match by length
    int numberLength = phoneNumber.length;
    for (var country in countries) {
      if (numberLength >= country.min && numberLength <= country.max) {
        return country;
      }
    }

    /// 4. If no match is found, check the country locale
    if(countryLocale.isNotEmpty) {
      return findByCode(countryLocale);
    }

    // 4. Final fallback
    return countries.first;
  }
}