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

/// Returns whether a dynamic value PROBABLY
/// has the isEmpty getter/method by checking
/// standard dart types that contain it.
///
/// This is here to avoid code duplication ('DRY').
bool _isEmpty(dynamic value) {
  if (value is String) {
    return value.toString().trim().isEmpty;
  }

  if (value is Iterable || value is Map || value is Set) {
    return value.isEmpty as bool? ?? false;
  }
  return false;
}

extension DynamicExtensions on dynamic {
  /// Checks if the value is not null.
  bool get isNotNull => this != null;

  /// Checks if the value is null.
  bool get isNull => this == null;

  /// Checks if data is null or blank (empty or only contains whitespace).
  bool isNullOrBlank() {
    if (isNull) {
      return true;
    }
    return _isEmpty(this);
  }

  /// Checks if data is blank (empty or only contains whitespace).
  bool isBlank() => _isEmpty(this);
}