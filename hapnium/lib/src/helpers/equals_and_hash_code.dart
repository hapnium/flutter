import 'package:meta/meta.dart';

import 'base.dart' as equalizer;

/// {@template equals_and_hash_code}
/// Mixin-style contract for value-based equality, `hashCode`, and `toString`.
///
/// Implementations must override [equalizedProperties] to return the list
/// of values that uniquely define the identity of this object. These values
/// are then used by the central [equalizer] utility to implement:
///
/// - [operator ==] → deep equality across selected properties
/// - [hashCode] → stable hash based on property order
/// - [toString] → human-readable representation
///
/// ### Rules
/// - Always include **all properties** that define identity.
/// - The order of properties **matters** for [hashCode].
/// - `null` values are supported and compared safely.
/// - Exclude transient or derived values (only core identity).
///
/// ### Example
/// ```dart
/// class User with EqualsAndHashCode {
///   final String id;
///   final String name;
///
///   User(this.id, this.name);
///
///   @override
///   List<Object?> equalizedProperties() => [id, name];
/// }
///
/// void main() {
///   final a = User('1', 'Alice');
///   final b = User('1', 'Alice');
///
///   print(a == b);         // true
///   print(a.hashCode == b.hashCode); // true
///   print(a);              // User(id=1, name=Alice)
/// }
/// ```
/// {@endtemplate}
mixin EqualsAndHashCode {
  /// {@macro equals_and_hash_code}
  ///
  /// Returns a list of properties that should be used for equality comparison
  /// and [hashCode] calculation.
  ///
  /// ⚠️ **Important:**  
  /// - Include all properties that define identity.  
  /// - Maintain a consistent order for [hashCode] stability.  
  /// - Include `null` explicitly if it affects equality.  
  @protected
  List<Object?> equalizedProperties();

  @override
  bool operator ==(Object other) => equalizer.equals(this, other);

  @override
  int get hashCode => equalizer.hashCode(this);

  @override
  String toString() => equalizer.toString(this);
}