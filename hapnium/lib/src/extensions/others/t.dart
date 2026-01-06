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

extension TExtensions<T> on T? {
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

  /// Checks for equality between the current [T] and the method [value]
  bool equals(T? value) => this == value;

  /// Checks for in-equality between the current [T] and the method [value]
  bool notEquals(T? value) => this != value;

  /// Checks if the given [this] is an instance of [E] type.
  bool instanceOf<E>() => this is E || this == E;

  /// Checks if data is blank (empty or only contains whitespace).
  bool isBlank() => _isEmpty(this);

  /// Returns the value if it's not null, otherwise returns [orElse].
  T? orElse(T? orElse) => this ?? orElse;

  /// Executes the given [action] if the value is not null.
  ///
  /// Returns the result of the [action] or null if the value is null.
  R? let<R>(R Function(T) action) => this != null ? action(this as T) : null;

  /// Executes the given [action] if the value is null.
  ///
  /// Returns the result of the [action] or the value if the value is not null.
  T? also(void Function(T?) action) {
    action(this);
    return this;
  }

  /// Returns this value if it is not null, otherwise throws a [JetException].
  T getOrThrow([String? message]) {
    if (isNull) {
      throw ArgumentError(message ?? "");
    }
    return this!;
  }
}