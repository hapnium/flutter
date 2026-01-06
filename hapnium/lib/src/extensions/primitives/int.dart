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

import 'dart:math';

import 'iterable.dart';

extension IntExtensions on int {
  /// Case equality check.
  bool equals(int other) => this == other;

  /// Case equality check.
  bool isEqualTo(int other) => equals(other);

  /// Checks if int equals any item in the list
  bool equalsAny(List<int> values) => values.any((v) => equals(v));
  
  /// Checks if int equals all items in the list
  bool equalsAll(List<int> values) => values.all((v) => equals(v));

  /// Case in-equality check.
  bool notEquals(int other) => this != other;

  /// Case in-equality check.
  bool isNotEqualTo(int other) => notEquals(other);

  /// Checks if int does not equals any item in the list
  bool notEqualsAny(List<int> values) => !values.any((v) => equals(v));
  
  /// Checks if int does not equals all items in the list
  bool notEqualsAll(List<int> values) => !values.all((v) => equals(v));

  /// Returns the next integer.
  int get increment => this + 1;

  /// Returns the previous integer.
  int get decrement => this - 1;

  /// Returns the length of this int value
  int get length => toString().length;

  /// Generates a list of integers from 0 up to (but not including) this integer.
  List<int> get listGenerator => List.generate(this, (index) => index);

  /// Formats the integer as a two-digit time unit for playback duration (MM or SS).
  ///
  /// Ensures that single-digit values are zero-padded (e.g., `5` → `"05"`, `12` → `"12"`).
  ///
  /// Returns a string representation of the integer in a two-digit format.
  String toTimeUnit() {
    String numberStr = toString();
    return this < 10 ? '0$numberStr' : numberStr;
  }

  /// Gets file size from byte to YB
  String get toFileSize {
    if (this <= 0) return "0 B";
    List<String> units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    int i = (log(this) / log(1024)).floor();
    return '${(this / pow(1024, i)).toStringAsFixed(2)} ${units[i]}';
  }

  /// Checks if all int values have same value.
  bool get isOneAKind {
    String value = toString();
    String first = value[0];

    for (int i = 0; i < value.length; i++) {
      if (value[i] != first) {
        return false;
      }
    }

    return true;
  }

  /// Checks if LOWER than int b.
  bool isLessThan(int b) => this < b;

  /// Short form for `isLessThan`
  bool isLt(int b) => isLessThan(b);

  /// Checks if GREATER than int b.
  bool isGreaterThan(int b) => this > b;

  /// Short form for `isGreaterThan`
  bool isGt(int b) => isGreaterThan(b);

  /// Checks if LOWER than int b.
  bool isLessThanOrEqualTo(int b) => isLessThan(b) || equals(b);

  /// Short form for `isLessThanOrEqualTo`
  bool isLtOrEt(int b) => isLessThanOrEqualTo(b);

  /// Checks if GREATER than int b.
  bool isGreaterThanOrEqualTo(int b) => isGreaterThan(b) || equals(b);

  /// Short form for `isGreaterThanOrEqualTo`
  bool isGtOrEt(int b) => isGreaterThanOrEqualTo(b);

  /// Checks if length of double value is GREATER than max.
  bool isLengthGreaterThan(int max) => length > max;

  /// Short form for `isLengthGreaterThan`
  bool isLengthGt(int max) => isLengthGreaterThan(max);

  /// Checks if length of double value is GREATER OR EQUAL to max.
  bool isLengthGreaterThanOrEqualTo(int max) => length >= max;

  /// Short form for `isLengthGreaterThanOrEqualTo`
  bool isLengthGtOrEt(int max) => isLengthGreaterThanOrEqualTo(max);

  /// Checks if length of double value is LESS than max.
  bool isLengthLessThan(int max) => length < max;

  /// Short form for `isLengthLessThan`
  bool isLengthLt(int max) => isLengthLessThan(max);

  /// Checks if length of double value is LESS OR EQUAL to max.
  bool isLengthLessThanOrEqualTo(int max) => length <= max;

  /// Short form for `isLengthLessThanOrEqualTo`
  bool isLengthLtOrEt(int max) => isLengthLessThanOrEqualTo(max);

  /// Checks if length of double value is EQUAL to max.
  bool isLengthEqualTo(int other) => length == other;

  /// Short form for `isLengthEqualTo`
  bool isLengthEt(int max) => isLengthEqualTo(max);

  /// Checks if length of int value is BETWEEN minLength to max.
  bool isLengthBetween(int min, int max) => isLengthGreaterThanOrEqualTo(min) && isLengthLessThanOrEqualTo(max);

  /// Converts the double value to a `Duration` in seconds.
  Duration get seconds => Duration(seconds: toInt());

  /// Converts the double value to a `Duration` in days.
  Duration get days => Duration(days: toInt());

  /// Converts the double value to a `Duration` in hours.
  Duration get hours => Duration(hours: toInt());

  /// Converts the double value to a `Duration` in minutes.
  Duration get minutes => Duration(minutes: toInt());

  /// Converts the double value to a `Duration` in milliseconds.
  Duration get milliseconds => Duration(milliseconds: toInt());

  /// Converts the double value to a `Duration` in microseconds.
  Duration get microseconds => Duration(microseconds: toInt());

  /// Divides the current integer by the given value.
  double divideBy(int value) => this / value;

  /// Multiplies the current integer by the given value.
  int multiplyBy(int value) => this * value;

  /// Adds the given value to the current integer.
  int plus(int value) => this + value;

  /// Subtracts the given value from the current integer.
  int minus(int value) => this - value;

  /// Returns the remainder of the division.
  int remainder(int value) => this % value;

  /// Performs integer division and returns the quotient.
  int iq(int value) => this ~/ value;

  /// Negates the number.
  int negated() => -this;

  /// Formats the media duration into a human-readable string.
  ///
  /// - Converts total seconds into hours, minutes, and seconds.
  /// - Displays hours only if the duration is 1 hour or more.
  /// - Supports optional spacing between time units.
  ///
  /// Example outputs:
  /// - `45` seconds → `"00:45"`
  /// - `125` seconds → `"02:05"`
  /// - `4000` seconds → `"01:06:40"`
  ///
  /// [addSpacing] If `true`, adds spaces around colons (`"01 : 06 : 40"`).
  /// If `false`, returns a compact format (`"01:06:40"`).
  ///
  /// Returns a formatted string representing the media duration.
  String mediaDuration({bool addSpacing = true}) {
    String hours = (this ~/ 3600).toTimeUnit();
    String minutes = ((this % 3600) ~/ 60).toTimeUnit();
    String seconds = (this % 60).toTimeUnit();

    String separator = addSpacing ? " : " : ":";

    return hours != "00" ? "$hours$separator$minutes$separator$seconds" : "$minutes$separator$seconds";
  }

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
  String toDigits([int digits = 2]) {
    if(digits <= 0) {
      throw ArgumentError('digits must be greater than 0');
    }

    return toString().padLeft(digits, '0');
  }
}