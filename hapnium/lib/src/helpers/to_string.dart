import 'dart:typed_data';

import 'base.dart' as base;
import 'equals_and_hash_code.dart';

/// {@template to_string_options}
/// Configuration options for customizing `toString` output in JetLeaf objects.
///
/// Used together with [EqualsAndHashCode] and the `equalizer` utility to control
/// how objects are represented as strings. This allows fine-grained control over:
///
/// - Parameter naming (automatic, type-based, or custom)
/// - Multi-line vs compact formatting
/// - Inclusion/exclusion of class names
/// - Custom separators
///
/// ### Predefined Formats
/// - [STANDARD] → `User(id: 1, name: Alice)`
/// - [COMPACT] → `User(1, Alice)`
/// - [MULTILINE] → 
///   ```
///   User(
///     id: 1,
///     name: Alice
///   )
///   ```
/// - [COMPACT_MULTILINE] → 
///   ```
///   User(
///     1,
///     Alice
///   )
///   ```
/// - [SMART_NAMES] → infers names based on values (e.g., `"email"`, `"age"`)
/// - [TYPE_BASED_NAMES] → uses runtime types (e.g., `"string"`, `"int"`)
///
/// ### Example
/// ```dart
/// class User implements EqualsAndHashCode {
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
///   final user = User('1', 'Alice');
///   print(equalizer.toString(user, ToStringOptions.STANDARD));
///   // => User(id: 1, name: Alice)
///
///   print(equalizer.toString(user, ToStringOptions.COMPACT));
///   // => User(1, Alice)
/// }
/// ```
/// {@endtemplate}
class ToStringOptions {
  /// Whether to include parameter names (e.g., `"name: Alice"` vs `"Alice"`).
  bool includeParameterNames;
  
  /// Whether to use newlines between parameters.
  bool useNewlines;
  
  /// Custom separator between parameters.  
  /// Defaults to `", "` or `",\n"` depending on [useNewlines].
  String? customSeparator;
  
  /// Whether to include the class name in output.
  bool includeClassName;
  
  /// Explicit parameter names (overrides inference).  
  /// Must match the length of [EqualsAndHashCode.equalizedProperties].
  List<String>? customParameterNames;

  /// Custom generator for parameter names based on property values and indices.
  String Function(Object? value, int index)? customParameterNameGenerator;
  
  /// {@macro to_string_options}
  ToStringOptions({
    this.includeParameterNames = true,
    this.useNewlines = false,
    this.customSeparator,
    this.includeClassName = true,
    this.customParameterNames,
    this.customParameterNameGenerator,
  });
  
  /// Default options: parameter names included, single-line format.
  /// 
  /// {@macro to_string_options}
  static final STANDARD = ToStringOptions();
  
  /// Compact format: parameter names excluded, single-line format.
  /// 
  /// {@macro to_string_options}
  static final COMPACT = ToStringOptions(includeParameterNames: false);
  
  /// Multi-line format: parameter names included, each on a new line.
  /// 
  /// {@macro to_string_options}
  static final MULTILINE = ToStringOptions(useNewlines: true);
  
  /// Multi-line format: parameter names excluded.
  /// 
  /// {@macro to_string_options}
  static final COMPACT_MULTILINE = ToStringOptions(
    includeParameterNames: false,
    useNewlines: true,
  );

  /// Smart name generator that infers names from common property patterns:
  /// - Email addresses → `"email"`
  /// - Short strings → `"name"`
  /// - Small ints → `"age"`
  /// - Large ints → `"timestamp"`
  /// - Lists → `"items"`, Sets → `"collection"`, Maps → `"data"`, etc.
  static final SMART_NAMES = ToStringOptions(
    customParameterNameGenerator: _smartNameGenerator,
  );

  /// Type-based generator that uses the runtime type as parameter name.
  /// Example: `User(string: Alice, int: 42)`
  static final TYPE_BASED_NAMES = ToStringOptions(
    customParameterNameGenerator: _typeBasedNameGenerator,
  );

  static String _smartNameGenerator(Object? value, int index) {
    if (value == null) return 'nullValue$index';
    
    // Infer names based on common patterns
    if (value is String) {
      if (value.contains('@')) return 'email';
      if (value.length < 50) return 'name';
      return 'text';
    }
    
    if (value is int) {
      if (value >= 0 && value <= 150) return 'age';
      if (value > 1000000000) return 'timestamp';
      return 'number';
    }
    
    if (value is double) return 'decimal';
    if (value is bool) return 'flag';
    if (value is List) return 'items';
    if (value is Set) return 'collection';
    if (value is Map) return 'data';
    if (value is TypedData) return 'bytes';
    
    return 'property$index';
  }

  static String _typeBasedNameGenerator(Object? value, int index) {
    if (value == null) return 'nullValue';
    return value.runtimeType.toString().toLowerCase();
  }
}

/// {@template toString_mixin}
/// A mixin that provides customizable toString implementation using the same
/// properties defined in [EqualsAndHashCode.equalizedProperties].
///
/// This mixin automatically generates toString output based on the properties
/// used for equality comparison, with various formatting options.
///
/// ## Example
/// ```dart
/// class Person with EqualsAndHashCode, ToString {
///   final String name;
///   final int age;
///   final String email;
///
///   Person(this.name, this.age, this.email);
///
///   @override
///   List<Object?> equalizedProperties() => [name, age, email];
///   
///   @override
///   List<String> get propertyNames => ['name', 'age', 'email'];
/// }
///
/// void main() {
///   final person = Person('Alice', 25, 'alice@example.com');
///   
///   // Default: Person(name: Alice, age: 25, email: alice@example.com)
///   print(person.toString());
///   
///   // Compact: Person(Alice, 25, alice@example.com)
///   print(person.toStringWith(ToStringOptions.compact));
///   
///   // Multi-line:
///   // Person(
///   //   name: Alice,
///   //   age: 25,
///   //   email: alice@example.com
///   // )
///   print(person.toStringWith(ToStringOptions.multiline));
/// }
/// ```
/// {@endtemplate}
mixin ToString on EqualsAndHashCode {
  ToStringOptions toStringOptions() => ToStringOptions.STANDARD;
  
  @override
  String toString() => base.toStringWith(this);
}