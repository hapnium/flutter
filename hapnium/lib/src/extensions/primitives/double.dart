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

import 'int.dart';
import 'iterable.dart';

extension DoubleExtensions on double {
  /// Case equality check.
  bool equals(double other) => this == other;

  /// Case equality check.
  bool isEqualTo(double other) => equals(other);

  /// Checks if double equals any item in the list
  bool equalsAny(List<double> values) => values.any((v) => equals(v));
  
  /// Checks if double equals all items in the list
  bool equalsAll(List<double> values) => values.all((v) => equals(v));

  /// Case in-equality check.
  bool notEquals(double other) => this != other;

  /// Case in-equality check.
  bool isNotEqualTo(double other) => notEquals(other);

  /// Checks if double does not equals any item in the list
  bool notEqualsAny(List<double> values) => !values.any((v) => equals(v));
  
  /// Checks if double does not equals all items in the list
  bool notEqualsAll(List<double> values) => !values.all((v) => equals(v));

  /// Returns the length of this int value
  int get length => toString().replaceAll('.', '').length;

  /// Checks if LOWER than double b.
  bool isLessThan(double b) => this < b;

  /// Short form for `isLessThan`
  bool isLt(double b) => isLessThan(b);

  /// Checks if GREATER than double b.
  bool isGreaterThan(double b) => this > b;

  /// Short form for `isGreaterThan`
  bool isGt(double b) => isGreaterThan(b);

  /// Checks if LOWER than double b.
  bool isLessThanOrEqualTo(double b) => isLessThan(b) || equals(b);

  /// Short form for `isLessThanOrEqualTo`
  bool isLtOrEt(double b) => isLessThanOrEqualTo(b);

  /// Checks if GREATER than double b.
  bool isGreaterThanOrEqualTo(double b) => isGreaterThan(b) || equals(b);

  /// Short form for `isGreaterThanOrEqualTo`
  bool isGtOrEt(double b) => isGreaterThanOrEqualTo(b);

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

  /// Checks if length of double value is BETWEEN minLength to max.
  bool isLengthBetween(int min, int max) => isLengthGreaterThanOrEqualTo(min) && isLengthLessThanOrEqualTo(max);

  /// Rounds the double value to the specified number of decimal places.
  double toPrecision(int fractionDigits) {
    double mod = pow(10, fractionDigits.toDouble()).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }

  /// Divides the current number by the given value.
  double divideBy(double value) => this / value;

  /// Multiplies the current number by the given value.
  double multiplyBy(double value) => this * value;

  /// Adds the given value to the current number.
  double plus(double value) => this + value;

  /// Subtracts the given value from the current number.
  double minus(double value) => this - value;

  /// Formats the number to the specified number of decimal places.
  /// 
  /// If `decimalPlaces` is not provided, it defaults to 2.
  String toDp([int decimalPlaces = 2]) => toStringAsFixed(decimalPlaces);

  /// Converts the double value to a `Duration` in milliseconds.
  Duration get milliseconds => Duration(microseconds: (this * 1000).round());

  /// Alias for `milliseconds`.
  Duration get ms => milliseconds;

  /// Converts the double value to a `Duration` in seconds.
  Duration get seconds => Duration(milliseconds: (this * 1000).round());

  /// Converts the double value to a `Duration` in minutes.
  Duration get minutes => Duration(seconds: (this * Duration.secondsPerMinute).round());

  /// Converts the double value to a `Duration` in hours.
  Duration get hours => Duration(minutes: (this * Duration.minutesPerHour).round());

  /// Converts the double value to a `Duration` in days.
  Duration get days => Duration(hours: (this * Duration.hoursPerDay).round());

  /// Calculates the distance of the double value and returns it in `km` or `m`,
  String get distance {
    if(isGtOrEt(1000)) {
      double kilometers = this / 1000;
      return "${kilometers.toDp()} km";
    } else {
      return "${toDp()} m";
    }
  }

  /// Returns the remainder of the division.
  double remainder(double value) => this % value;

  /// Performs integer division and returns the quotient.
  int iq(double value) => this ~/ value;

  /// Negates the number.
  double negated() => -this;

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
    int totalSeconds = toInt();

    String hours = (totalSeconds ~/ 3600).toTimeUnit();
    String minutes = ((totalSeconds % 3600) ~/ 60).toTimeUnit();
    String seconds = (totalSeconds % 60).toTimeUnit();

    String separator = addSpacing ? " : " : ":";

    return hours != "00" ? "$hours$separator$minutes$separator$seconds" : "$minutes$separator$seconds";
  }
}