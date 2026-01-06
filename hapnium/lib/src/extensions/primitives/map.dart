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

import '../../utils/instance.dart';
import '../others/t.dart';

extension MapExtensions<K, V> on Map<K, V> {
  /// Converts a Map to JSON with formatted keys (`_`, `-`, or `camelCase`).
  /// 
  /// ## Parameters
  /// - `delimiter`: The delimiter to use for formatting keys
  /// 
  /// ## Returns
  /// - A new Map with formatted keys
  Map<String, dynamic> asJson({String delimiter = '_'}) {
    return mapKeys((key) {
      if (key is String) {
        return formatKeys(key, delimiter);
      }
      return Instance.valueOf(key);
    });
  }

  /// Formats map keys (snake_case, kebab-case, camelCase)
  /// 
  /// ## Parameters
  /// - `key`: The key to format
  /// - `delimiter`: The delimiter to use for formatting keys
  /// 
  /// ## Returns
  /// - The formatted key
  static String formatKeys(String key, String delimiter) {
    switch (delimiter) {
      case '_':
        return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]!.toLowerCase()}');
      case '-':
        return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}-${m[2]!.toLowerCase()}');
      default:
        return key; // Return as is
    }
  }

  /// Merges another Map into the current Map, overriding duplicate keys.
  /// 
  /// ## Parameters
  /// - `other`: The Map to merge
  /// 
  /// ## Returns
  /// - A new Map with merged key-value pairs
  Map<K, V> merge(Map<K, V> other) {
    return {...this, ...other};
  }

  /// Applies a transformation function to the keys of the Map.
  /// 
  /// ## Parameters
  /// - `convert`: The transformation function to apply to the keys
  /// 
  /// ## Returns
  /// - A new Map with transformed keys
  Map<K2, V> mapKeys<K2>(K2 Function(K key) convert) {
    return map<K2, V>((key, value) => MapEntry(convert(key), value));
  }

  /// Add item
  /// 
  /// If the key already exists, it will be updated only if the value is different.
  /// 
  /// ## Parameters
  /// - `key`: The key to add
  /// - `item`: The value to add
  void add(K key, V item) {
    update(key, (v) => v.notEquals(item) ? item : v, ifAbsent: () => item);
  }

  /// Add item
  /// 
  /// If the key already exists, it will be updated only if the value is different.
  /// 
  /// ## Parameters
  /// - `key`: The key to add
  /// - `value`: The value to add
  void put(K key, V value) {
    putIfAbsent(key, () => value);
  }

  /// Get value by key
  /// 
  /// ## Parameters
  /// - `key`: The key to get
  /// 
  /// ## Returns
  /// - The value associated with the key
  V? get(K key) {
    return this[key];
  }

  /// Computes a value for the given key if it is not already present in the map.
  /// 
  /// ## Parameters
  /// - `key`: The key to compute a value for
  /// - `ifAbsent`: The function to compute the value if the key is not present
  /// 
  /// ## Returns
  /// - The computed value
  V computeIfAbsent(K key, V Function(K key) ifAbsent) {
    if (containsKey(key)) {
      return this[key] as V;
    } else {
      final V newValue = ifAbsent(key);
      this[key] = newValue;
      return newValue;
    }
  }
}