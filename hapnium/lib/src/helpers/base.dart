import 'dart:collection';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'equals_and_hash_code.dart';
import 'to_string.dart';

/// Helper: identity pair for cycle-aware deep equality
class _IdentPair {
  final Object a;
  final Object b;
  _IdentPair(this.a, this.b);

  @override
  bool operator ==(Object other) => other is _IdentPair && identical(a, other.a) && identical(b, other.b);

  @override
  int get hashCode => identityHashCode(a) ^ (identityHashCode(b) << 1); // identity-based
}

/// Decide whether a value is a simple "leaf" that we should never add to visited.
bool _isLeaf(Object? v) {
  if (v == null) return true;
  return v is String ||
      v is num ||
      v is bool ||
      v is DateTime ||
      v is Duration ||
      v is Symbol;
}

/// Public equality entrypoint (keeps same signature)
@internal
bool equals(Object current, Object other) {
  if (identical(current, other)) {
    return true;
  }

  // Only compare domain objects that implement EqualsAndHashCode
  if (other is! EqualsAndHashCode || current is! EqualsAndHashCode) {
    return false;
  }

  final visited = HashSet<_IdentPair>();
  return _equalsEquals(current, other, visited);
}

/// Internal equals for two EqualsAndHashCode objects with visited-pairs to detect recursion.
bool _equalsEquals(EqualsAndHashCode a, EqualsAndHashCode b, HashSet<_IdentPair> visited) {
  if (identical(a, b)) return true;

  final pair = _IdentPair(a, b);
  if (visited.contains(pair)) {
    // We've already compared these two instances in this call graph — assume equal to avoid infinite recursion.
    return true;
  }
  visited.add(pair);

  try {
    final aProps = a.equalizedProperties();
    final bProps = b.equalizedProperties();

    // If both have no properties, fall back to simple runtime type equality.
    if (aProps.isEmpty && bProps.isEmpty) {
      if (a.runtimeType != b.runtimeType) return false;
      return true;
    }

    if (aProps.length != bProps.length) return false;

    for (int i = 0; i < aProps.length; i++) {
      if (!_deepEquals(aProps[i], bProps[i], visited)) return false;
    }
    return true;
  } finally {
    visited.remove(pair);
  }
}

/// Deep equality with visited-pairs to detect mutual/circular references.
///
/// NOTE: this method is used for arbitrary values (not only EqualsAndHashCode).
bool _deepEquals(Object? a, Object? b, [HashSet<_IdentPair>? visitedPairs]) {
  if (identical(a, b)) return true;

  if (a == null || b == null) return false;

  // Fast path for identical runtime types of simple leaves
  if (_isLeaf(a) && _isLeaf(b)) {
    return a == b;
  }

  visitedPairs ??= HashSet<_IdentPair>();

  // If both are EqualsAndHashCode, compare via the pair-aware equals
  if (a is EqualsAndHashCode && b is EqualsAndHashCode) {
    return _equalsEquals(a, b, visitedPairs);
  }

  // TypedData: compare bytes
  if (a is TypedData && b is TypedData) {
    if (a.runtimeType != b.runtimeType) return false;
    if (a.lengthInBytes != b.lengthInBytes) return false;

    final aBytes = a.buffer.asUint8List(a.offsetInBytes, a.lengthInBytes);
    final bBytes = b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes);

    if (identical(aBytes, bBytes)) return true;
    for (int i = 0; i < aBytes.length; i++) {
      if (aBytes[i] != bBytes[i]) return false;
    }
    return true;
  }

  // Lists
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i], visitedPairs)) return false;
    }
    return true;
  }

  // Sets - O(n^2) matching (preserve previous semantics)
  if (a is Set && b is Set) {
    if (a.length != b.length) return false;
    final used = <int>{};
    for (final item in a) {
      bool found = false;
      int idx = 0;
      for (final otherItem in b) {
        if (used.contains(idx)) {
          idx++;
          continue;
        }
        if (_deepEquals(item, otherItem, visitedPairs)) {
          found = true;
          used.add(idx);
          break;
        }
        idx++;
      }
      if (!found) return false;
    }
    return true;
  }

  // Maps
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      // Note: this uses Map's containsKey semantics (== on keys).
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key], visitedPairs)) return false;
    }
    return true;
  }

  // Fallback to default equality
  return a == b;
}

/// Computes a deep hash code for an object.
///
/// - Uses EqualsAndHashCode.equalizedProperties when available.
/// - Detects cycles using identity.
/// - Leaves (primitives/TypedData) are hashed without graph traversal.
int hashCode(Object current) {
  // Non-domain objects: just use their hashCode
  if (current is! EqualsAndHashCode) return current.hashCode;

  final props = current.equalizedProperties();
  if (props.isEmpty) return current.runtimeType.hashCode;

  final visited = HashSet<Object>.identity();
  int hash = current.runtimeType.hashCode;
  for (final prop in props) {
    hash = _combineHash(hash, _deepHashCode(prop, visited));
  }
  return hash;
}

/// Internal deep hash with cycle detection.
/// - Leaves (primitives, TypedData) are handled without adding to visited.
/// - Graph nodes are tracked in `visited` (identity based).
int _deepHashCode(Object? obj, [HashSet<Object>? visited]) {
  if (obj == null) return 0;

  // Fast/leaf types: don't add to visited
  if (obj is num || obj is bool || obj is String || obj is DateTime || obj is Duration || obj is Symbol) {
    return obj.hashCode;
  }

  // TypedData: produce a deterministic hash based on bytes (but treat as leaf)
  if (obj is TypedData) {
    int h = obj.runtimeType.hashCode;
    final bytes = obj.buffer.asUint8List(obj.offsetInBytes, obj.lengthInBytes);

    if (bytes.length > 1000) {
      final step = bytes.length ~/ 100;
      for (int i = 0; i < bytes.length; i += (step == 0 ? 1 : step)) {
        h = _combineHash(h, bytes[i]);
      }
      h = _combineHash(h, bytes.first);
      h = _combineHash(h, bytes.last);
    } else {
      for (final byte in bytes) {
        h = _combineHash(h, byte);
      }
    }
    return h;
  }

  visited ??= HashSet<Object>.identity();

  // If we've seen this instance already in this hashing traversal, short-circuit to avoid cycles
  if (visited.contains(obj)) return 0;

  visited.add(obj);
  try {
    // EqualsAndHashCode: compute from equalizedProperties rather than calling public hashCode (prevents recursion).
    if (obj is EqualsAndHashCode) {
      int h = obj.runtimeType.hashCode;
      final props = obj.equalizedProperties();
      for (final p in props) {
        h = _combineHash(h, _deepHashCode(p, visited));
      }
      return h;
    }

    if (obj is List) {
      int h = 1;
      for (final item in obj) {
        h = _combineHash(h, _deepHashCode(item, visited));
      }
      return h;
    }

    if (obj is Set) {
      int h = 0;
      for (final item in obj) {
        h = h ^ _deepHashCode(item, visited);
      }
      return h;
    }

    if (obj is Map) {
      int h = 0;
      for (final entry in obj.entries) {
        final k = _deepHashCode(entry.key, visited);
        final v = _deepHashCode(entry.value, visited);
        h = h ^ _combineHash(k, v);
      }
      return h;
    }

    // Fallback for arbitrary objects: use identityHashCode to avoid accidental recursion into custom hashCode that may call back.
    // Prefer identityHashCode for unknown object shapes inside deep hashing.
    return identityHashCode(obj);
  } finally {
    visited.remove(obj);
  }
}

int _combineHash(int hash, int value) {
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// Stringification helpers (kept largely as you had them; they already use identity visited)
@internal
String toString(Object obj) {
  if (obj is! EqualsAndHashCode) return obj.toString();
  return _toStringSafe(obj, Set<Object>.identity());
}

String _toStringSafe(Object obj, Set<Object> visited) {
  if (obj is! EqualsAndHashCode) return obj.toString();

  if (visited.contains(obj)) return '(circular ref)';

  visited.add(obj);
  try {
    final props = obj.equalizedProperties();
    final className = obj.runtimeType.toString();

    if (props.isEmpty) return '$className()';

    final propStrings = <String>[];
    for (final prop in props) {
      propStrings.add(_propToString(prop, visited));
    }

    return '$className(${propStrings.join(', ')})';
  } finally {
    visited.remove(obj);
  }
}

String _propToString(Object? prop, Set<Object> visited) {
  if (prop == null) return 'null';

  if (_isLeaf(prop)) return prop.toString();

  if (prop is TypedData) {
    final typeName = prop.runtimeType.toString();
    if (prop.lengthInBytes <= 32) {
      final bytes = prop.buffer.asUint8List(prop.offsetInBytes, prop.lengthInBytes);
      return '$typeName([${bytes.join(', ')}])';
    } else {
      return '$typeName(${prop.lengthInBytes} bytes)';
    }
  }

  if (prop is EqualsAndHashCode) {
    return _toStringSafe(prop, visited);
  }

  if (prop is List) {
    if (visited.contains(prop)) return '[/* circular ref */]';
    visited.add(prop);
    try {
      final inner = prop.map((e) => _propToString(e, visited)).join(', ');
      return '[$inner]';
    } finally {
      visited.remove(prop);
    }
  }

  if (prop is Set) {
    if (visited.contains(prop)) return '{/* circular ref */}';
    visited.add(prop);
    try {
      final inner = prop.map((e) => _propToString(e, visited)).join(', ');
      return '{$inner}';
    } finally {
      visited.remove(prop);
    }
  }

  if (prop is Map) {
    if (visited.contains(prop)) return '{/* circular ref */}';
    visited.add(prop);
    try {
      final entries = prop.entries
          .map((e) => '${_propToString(e.key, visited)}: ${_propToString(e.value, visited)}')
          .join(', ');
      return '{$entries}';
    } finally {
      visited.remove(prop);
    }
  }

  return prop.toString();
}

/// toStringWith (kept as you had it; uses visited)
@internal
String toStringWith(ToString current) {
  final visited = Set<Object>.identity();

  List<String> inferred() {
    final props = current.equalizedProperties();
    return List.generate(props.length, (index) => 'property$index');
  }

  final options = current.toStringOptions();
  final props = current.equalizedProperties();
  final className = current.runtimeType.toString();

  if (props.isEmpty) {
    return options.includeClassName ? '$className()' : '()';
  }

  List<String> effectiveNames;

  if (options.customParameterNameGenerator != null) {
    effectiveNames =
        List.generate(props.length, (index) => options.customParameterNameGenerator!(props[index], index));
  } else if (options.customParameterNames != null) {
    final customNames = options.customParameterNames!;
    effectiveNames = customNames.length >= props.length
        ? customNames.take(props.length).toList()
        : [...customNames, ...List.generate(props.length - customNames.length, (i) => 'property${customNames.length + i}')];
  } else {
    final names = inferred();
    effectiveNames = names.length >= props.length
        ? names.take(props.length).toList()
        : [...names, ...List.generate(props.length - names.length, (i) => 'property${names.length + i}')];
  }

  final separator = options.customSeparator ?? (options.useNewlines ? ',\n' : ', ');

  final propStrings = <String>[];
  for (int i = 0; i < props.length; i++) {
    final propValue = _propToString(props[i], visited);
    final propString = options.includeParameterNames ? '${effectiveNames[i]}: $propValue' : propValue;
    propStrings.add(propString);
  }

  final content = propStrings.join(separator);

  if (options.useNewlines && propStrings.length > 1) {
    final indentedContent = content.split('\n').map((line) => '  $line').join('\n');
    return options.includeClassName ? '$className(\n$indentedContent\n)' : '(\n$indentedContent\n)';
  }

  return options.includeClassName ? '$className($content)' : '($content)';
}