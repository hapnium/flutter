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

extension BoolExtensions on bool {
  /// Converts the boolean to an integer (1 for true, 0 for false).
  int toInt() => this ? 1 : 0;

  /// Checks if the current value of this boolean is `false`
  bool get isFalse => this == false;

  /// Checks if the current value of this boolean is `true`
  bool get isTrue => this == true;

  /// Case equality check.
  bool equals(bool other) => this == other;

  /// Case in-equality check.
  bool notEquals(bool other) => this != other;

  /// Case equality check.
  bool isEqualTo(bool other) => equals(other);

  /// Case in-equality check.
  bool isNotEqualTo(bool other) => notEquals(other);
}