// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'iterable.dart';

extension NumExtensions on num {
  /// Case equality check.
  /// 
  /// ## Parameters
  /// - `other`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value equals the other value
  /// - `false` otherwise
  bool equals(num other) => this == other;

  /// Case equality check.
  /// 
  /// ## Parameters
  /// - `other`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value equals the other value
  /// - `false` otherwise
  bool isEqualTo(num other) => equals(other);

  /// Checks if num equals any item in the list
  /// 
  /// ## Parameters
  /// - `values`: The list of values to compare
  /// 
  /// ## Returns
  /// - `true` if this value equals any item in the list
  /// - `false` otherwise
  bool equalsAny(List<num> values) => values.any((v) => equals(v));
  
  /// Checks if num equals all items in the list
  /// 
  /// ## Parameters
  /// - `values`: The list of values to compare
  /// 
  /// ## Returns
  /// - `true` if this value equals all items in the list
  /// - `false` otherwise
  bool equalsAll(List<num> values) => values.all((v) => equals(v));

  /// Case in-equality check.
  /// 
  /// ## Parameters
  /// - `other`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value does not equal the other value
  /// - `false` otherwise
  bool notEquals(num other) => this != other;

  /// Case in-equality check.
  /// 
  /// ## Parameters
  /// - `other`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value does not equal the other value
  /// - `false` otherwise
  bool isNotEqualTo(num other) => notEquals(other);

  /// Checks if num does not equals any item in the list
  /// 
  /// ## Parameters
  /// - `values`: The list of values to compare
  /// 
  /// ## Returns
  /// - `true` if this value does not equal any item in the list
  /// - `false` otherwise
  bool notEqualsAny(List<num> values) => !values.any((v) => equals(v));
  
  /// Checks if num does not equals all items in the list
  /// 
  /// ## Parameters
  /// - `values`: The list of values to compare
  /// 
  /// ## Returns
  /// - `true` if this value does not equal all items in the list
  /// - `false` otherwise
  bool notEqualsAll(List<num> values) => !values.all((v) => equals(v));

  /// Returns the length of this int value
  int get length => toString().replaceAll('.', '').length;

  /// Checks if LOWER than num b.
  /// 
  /// ## Parameters
  /// - `b`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value is less than the other value
  /// - `false` otherwise
  bool isLessThan(num b) => this < b;

  /// Short form for `isLessThan`
  bool isLt(num b) => isLessThan(b);

  /// Checks if GREATER than num b.
  /// 
  /// ## Parameters
  /// - `b`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value is greater than the other value
  /// - `false` otherwise
  bool isGreaterThan(num b) => this > b;

  /// Short form for `isGreaterThan`
  bool isGt(num b) => isGreaterThan(b);

  /// Checks if LOWER than num b.
  /// 
  /// ## Parameters
  /// - `b`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value is less than or equal to the other value
  /// - `false` otherwise
  bool isLessThanOrEqualTo(num b) => isLessThan(b) || equals(b);

  /// Short form for `isLessThanOrEqualTo`
  bool isLtOrEt(num b) => isLessThanOrEqualTo(b);

  /// Checks if GREATER than num b.
  /// 
  /// ## Parameters
  /// - `b`: The value to compare
  /// 
  /// ## Returns
  /// - `true` if this value is greater than or equal to the other value
  /// - `false` otherwise
  bool isGreaterThanOrEqualTo(num b) => isGreaterThan(b) || equals(b);

  /// Short form for `isGreaterThanOrEqualTo`
  bool isGtOrEt(num b) => isGreaterThanOrEqualTo(b);

  /// Checks if length of double value is GREATER than max.
  /// 
  /// ## Parameters
  /// - `max`: The maximum length
  /// 
  /// ## Returns
  /// - `true` if the length of this value is greater than the maximum length
  /// - `false` otherwise
  bool isLengthGreaterThan(int max) => length > max;

  /// Short form for `isLengthGreaterThan`
  bool isLengthGt(int max) => isLengthGreaterThan(max);

  /// Checks if length of double value is GREATER OR EQUAL to max.
  /// 
  /// ## Parameters
  /// - `max`: The maximum length
  /// 
  /// ## Returns
  /// - `true` if the length of this value is greater than or equal to the maximum length
  /// - `false` otherwise
  bool isLengthGreaterThanOrEqualTo(int max) => length >= max;

  /// Short form for `isLengthGreaterThanOrEqualTo`
  bool isLengthGtOrEt(int max) => isLengthGreaterThanOrEqualTo(max);

  /// Checks if length of double value is LESS than max.
  /// 
  /// ## Parameters
  /// - `max`: The maximum length
  /// 
  /// ## Returns
  /// - `true` if the length of this value is less than the maximum length
  /// - `false` otherwise
  bool isLengthLessThan(int max) => length < max;

  /// Short form for `isLengthLessThan`
  bool isLengthLt(int max) => isLengthLessThan(max);

  /// Checks if length of double value is LESS OR EQUAL to max.
  /// 
  /// ## Parameters
  /// - `max`: The maximum length
  /// 
  /// ## Returns
  /// - `true` if the length of this value is less than or equal to the maximum length
  /// - `false` otherwise
  bool isLengthLessThanOrEqualTo(int max) => length <= max;

  /// Short form for `isLengthLessThanOrEqualTo`
  bool isLengthLtOrEt(int max) => isLengthLessThanOrEqualTo(max);

  /// Checks if length of double value is EQUAL to max.
  /// 
  /// ## Parameters
  /// - `other`: The other value
  /// 
  /// ## Returns
  /// - `true` if the length of this value is equal to the other value
  /// - `false` otherwise
  bool isLengthEqualTo(int other) => length == other;

  /// Short form for `isLengthEqualTo`
  bool isLengthEt(int max) => isLengthEqualTo(max);

  /// Checks if length of double value is BETWEEN minLength to max.
  /// 
  /// ## Parameters
  /// - `min`: The minimum length
  /// - `max`: The maximum length
  /// 
  /// ## Returns
  /// - `true` if the length of this value is between the minimum and maximum length
  /// - `false` otherwise
  bool isLengthBetween(int min, int max) => isLengthGreaterThanOrEqualTo(min) && isLengthLessThanOrEqualTo(max);

  /// Divides the current number by the given value.
  num divideBy(num value) => this / value;

  /// Multiplies the current number by the given value.
  num multiplyBy(num value) => this * value;

  /// Adds the given value to the current number.
  num plus(num value) => this + value;

  /// Subtracts the given value from the current number.
  num minus(num value) => this - value;

  /// Returns the remainder of the division.
  num remainder(num value) => this % value;

  /// Performs integer division and returns the quotient.
  int iq(num value) => this ~/ value;

  /// Negates the number.
  num negated() => -this;

  /// Converts the integer to a string and left-pads it with zeroes until it reaches [digits] length.
  ///
  /// Useful for formatting numeric values such as dates, times, and identifiers
  /// where a fixed-width string is expected.
  ///
  /// ### Example:
  /// ```dart
  /// final padded = 7.toDigits(3); // '007'
  /// final padded2 = 123.toDigits(5); // '00123'
  /// ```
  ///
  /// ### Parameters:
  /// - [digits]: The total number of digits the output string should have.
  ///
  /// ### Returns:
  /// A string version of this integer, padded with '0' on the left if necessary.
  ///
  /// ### Throws:
  /// - If [digits] is less than or equal to zero.
  ///
  /// ### Notes:
  /// - If the integer already has the same or more digits, it returns the number as a string.
  String toDigits(int digits) => toString().padLeft(digits, '0');

  /// Converts numbers to human-readable strings.
  ///
  /// This function takes a numeric input and formats it into a more concise,
  /// human-readable string representation, using abbreviations for large numbers.
  ///
  /// **Examples:**
  ///
  /// * `3300` -> `"3.3k"`
  /// * `2300000` -> `"2.3M"`
  /// * `1200000000` -> `"1.2B"`
  ///
  /// **Behavior:**
  ///
  /// * Numbers less than 1000 are returned as their string representation.
  /// * Numbers between 1000 and 1,000,000 are divided by 1000 and appended with "k" (thousands).
  /// * Numbers between 1,000,000 and 1,000,000,000 are divided by 1,000,000 and appended with "M" (millions).
  /// * Numbers greater than or equal to 1,000,000,000 are divided by 1,000,000,000 and appended with "B" (billions).
  /// * The result is formatted to one decimal place.
  ///
  /// **Parameters:**
  ///
  /// * `number`: The numeric value to be converted.
  ///
  /// **Returns:**
  ///
  /// A human-readable string representation of the input number.
  String get prettyFormat {
    if (this < 1000) {
      return toString();
    } else if (this < 1_000_000) {
      return "${(this / 1000.0).toStringAsFixed(1)}k";
    } else if (this < 1_000_000_000) {
      return "${(this / 1_000_000.0).toStringAsFixed(1)}M";
    } else {
      return "${(this / 1_000_000_000.0).toStringAsFixed(1)}B";
    }
  }
}