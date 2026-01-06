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

extension DateTimeExtensions on DateTime {
  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool equals(DateTime date) => year == date.year && month == date.month && day == date.day;

  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool isEqualTo(DateTime date) => equals(date);

  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool notEquals(DateTime date) => !equals(date);

  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool isNotEqualTo(DateTime date) => notEquals(date);
}