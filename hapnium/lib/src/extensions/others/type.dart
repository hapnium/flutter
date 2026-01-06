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

extension TypeExtension on Type {
  /// Generalized equality check to simplify type checking.
  ///
  /// This method allows for a cleaner way of comparing types
  bool equals(Type type) => this == Type || this == type || runtimeType == type;

  /// Checks if the given [this] is of type [Type].
  bool isEqualTo(Type type) => equals(type);

  /// Checks if the given [this] is of type [Type].
  bool isNotEqualTo(Type type) => !equals(type);
}