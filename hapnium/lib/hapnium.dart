/// {@template hapnium_library}
/// # Hapnium Library
///
/// `hapnium` is a Dart utility library designed to enhance developer productivity
/// by providing a collection of robust helper classes, extension methods, and
/// utility functions that extend the capabilities of the Dart language.
///
/// This package simplifies common programming tasks such as:
/// - Working with optional values safely
/// - Enhancing built-in types through extensions
/// - Performing frequent operations on collections and primitives
/// - Parsing and manipulating JSON
/// - Dynamically working with instances and types
///
/// ## 📦 Features
///
/// ### ✅ Classes
/// - `Optional<T>`: A type-safe representation for optional values, inspired by
///   concepts in functional programming.
///
/// ### ❗ Exceptions
/// - `HapniumException`: A custom base exception class for throwing meaningful
///   and consistent errors from this library.
///
/// ### 🔧 Extensions
/// Extend core Dart types with extra functionality for more expressive and concise code:
///
/// #### ▸ Primitive Extensions:
/// - `StringExtensions`: Capitalization, casing, trimming, regex handling, etc.
/// - `IntExtensions`, `DoubleExtensions`, `NumExtensions`: Math helpers, range checks, formatting.
/// - `BoolExtensions`: Logic enhancements and value switching.
///
/// #### ▸ Collection Extensions:
/// - `ListExtensions`: Sorting, chunking, flattening, and more.
/// - `MapExtensions`: Key-value transformations, safe accessors.
/// - `IterableExtensions`: Advanced traversal, uniqueness filters.
///
/// #### ▸ Other Extensions:
/// - `DynamicExtensions`: Dynamic value checking and casting.
/// - `TTypeExtensions<T>`: Generic helpers for all types.
/// - `DurationExtensions`: Conversion between units, human-readable strings.
/// - `DateTimeExtensions`: Temporal arithmetic, formatting, and comparison.
///
/// ### 🛠 Utils
/// - `JsonUtils`: Safely decode/encode JSON and work with dynamic maps.
/// - `InstanceUtils`: Utility methods to work with types, constructors, and instances.
/// - `RegexUtils`: Common regex patterns and validation helpers.
/// - `Typedefs`: Common function type aliases used across the library.
///
/// ## 🧪 Example
///
/// ```dart
/// import 'package:hapnium/hapnium.dart';
///
/// void main() {
///   final name = 'hapnium';
///   print(name.capitalize()); // "Hapnium"
///
///   final list = [1, 2, 3];
///   print(list.chunk(2)); // [[1, 2], [3]]
///
///   final optional = Optional.ofNullable<String>(null);
///   print(optional.isPresent); // false
/// }
/// ```
///
/// Hapnium is modular and well-structured, allowing you to use only the components you need.
///
/// {@endtemplate}
library;

/// =========================
/// ========== API =========
/// =========================

/// 🌟 CLASSES
export 'src/classes/optional.dart';

/// ❗ EXCEPTIONS
export 'src/exceptions/hapnium_exception.dart';

/// 🧩 EXTENSIONS

// ▸ Primitives
export 'src/extensions/primitives/string.dart';
export 'src/extensions/primitives/bool.dart';
export 'src/extensions/primitives/int.dart';
export 'src/extensions/primitives/list.dart';
export 'src/extensions/primitives/map.dart';
export 'src/extensions/primitives/double.dart';
export 'src/extensions/primitives/num.dart';
export 'src/extensions/primitives/iterable.dart';

// ▸ Others
export 'src/extensions/others/dynamic.dart';
export 'src/extensions/others/t.dart';
export 'src/extensions/others/duration.dart';
export 'src/extensions/others/date_time.dart';

/// 🧰 UTILS
export 'src/utils/instance.dart';
export 'src/utils/json_utils.dart';
export 'src/utils/regex_utils.dart';
export 'src/utils/typedefs.dart';

export 'src/helpers/equals_and_hash_code.dart';
export 'src/helpers/to_string.dart';

export 'src/io/base_stream/base_stream.dart';
export 'src/io/base_stream/double/double_stream.dart';
export 'src/io/base_stream/generic/generic_stream.dart';
export 'src/io/base_stream/double/_double_stream.dart';
export 'src/io/base_stream/generic/_generic_stream.dart';
export 'src/io/base_stream/int/_int_stream.dart';
export 'src/io/base_stream/int/int_stream.dart';
export 'src/io/stream_support.dart';