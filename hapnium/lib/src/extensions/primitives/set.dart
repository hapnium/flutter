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

/// {@template set_utils}
/// Utility extension methods for working with sets in Dart.
///
/// Provides helpful methods for checking subset and superset relationships
/// between sets, particularly when working with sets of nullable objects.
///
/// Example:
/// ```dart
/// final a = {1, 2};
/// final b = {1, 2, 3};
/// print(a.isSubsetOf(b)); // true
/// print(b.isSupersetOf(a)); // true
/// ```
/// {@endtemplate}
extension SetUtils on Set<Object?> {
  /// {@macro set_utils}
  ///
  /// Returns `true` if this set is a subset of [other], meaning all elements
  /// in this set also exist in [other]. If this set has more elements than
  /// [other], it immediately returns `false` as an optimization.
  ///
  /// Example:
  /// ```dart
  /// final a = {'x'};
  /// final b = {'x', 'y'};
  /// print(a.isSubsetOf(b)); // true
  /// ```
  bool isSubsetOf(Set<Object?> other) {
    if (length > other.length) return false;
    for (final element in this) {
      if (!other.contains(element)) return false;
    }
    return true;
  }

  /// {@macro set_utils}
  ///
  /// Returns `true` if this set is a superset of [other], meaning it contains
  /// all elements of [other]. Internally delegates to [isSubsetOf].
  ///
  /// Example:
  /// ```dart
  /// final a = {1, 2, 3};
  /// final b = {2};
  /// print(a.isSupersetOf(b)); // true
  /// ```
  bool isSupersetOf(Set<Object?> other) {
    return other.isSubsetOf(this);
  }
}