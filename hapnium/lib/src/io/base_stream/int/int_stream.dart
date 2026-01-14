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

import '../base_stream.dart';
import '../double/double_stream.dart';
import '_int_stream.dart';
import '../../../classes/optional.dart';

/// {@template int_stream}
/// A sequence of primitive `int`-valued elements supporting sequential and parallel
/// aggregate operations.
/// 
/// This is the `int` primitive specialization of [BaseStream]. It supports
/// fluent-style functional operations such as `map`, `filter`, `reduce`,
/// and terminal operations for processing or collecting data.
/// 
/// ## Example Usage
/// ```dart
/// // Create an IntStream from a range
/// final sum = IntStream.range(1, 10)
///     .filter((n) => n % 2 == 0)
///     .sum();
/// print(sum); // 20
/// 
/// // Statistical operations
/// final stats = IntStream.of([1, 2, 3, 4, 5])
///     .summaryStatistics();
/// print('Average: ${stats.average}');
/// print('Max: ${stats.max}');
/// 
/// // Complex transformations
/// final result = IntStream.range(1, 100)
///     .filter((n) => n % 3 == 0)
///     .map((n) => n * n)
///     .limit(5)
///     .toList();
/// ```
/// 
/// {@endtemplate}
abstract class IntStream extends BaseStream<int, IntStream> {
  /// {@macro int_stream}
  IntStream();

  /// Creates an [IntStream] from the given values.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = IntStream.of([1, 2, 3, 4, 5]);
  /// ```
  /// 
  /// {@macro int_stream}
  factory IntStream.of(Iterable<int> values) = StandardIntStream.of;

  /// Creates an [IntStream] from a range of integers.
  /// 
  /// The range includes [startInclusive] and excludes [endExclusive].
  /// 
  /// ## Example
  /// ```dart
  /// final stream = IntStream.range(1, 10); // 1, 2, 3, 4, 5, 6, 7, 8, 9
  /// ```
  /// {@macro int_stream}
  factory IntStream.range(int startInclusive, int endExclusive) = StandardIntStream.range;

  /// Creates an [IntStream] from a closed range of integers.
  /// 
  /// The range includes both [startInclusive] and [endInclusive].
  /// 
  /// ## Example
  /// ```dart
  /// final stream = IntStream.rangeClosed(1, 5); // 1, 2, 3, 4, 5
  /// ```
  /// {@macro int_stream}
  factory IntStream.rangeClosed(int startInclusive, int endInclusive) = StandardIntStream.rangeClosed;

  /// Creates an empty [IntStream].
  /// 
  /// ## Example
  /// ```dart
  /// final stream = IntStream.empty();
  /// print(stream.count()); // 0
  /// ```
  /// {@macro int_stream}
  factory IntStream.empty() = StandardIntStream.empty;

  // Intermediate operations

  /// Returns a stream consisting of elements that match the given predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final evens = IntStream.range(1, 10)
  ///     .filter((n) => n % 2 == 0);
  /// ```
  IntStream filter(bool Function(int) predicate);

  /// Returns a stream consisting of the results of applying the given function
  /// to the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final squares = IntStream.range(1, 5)
  ///     .map((n) => n * n);
  /// ```
  IntStream map(int Function(int) mapper);

  /// Returns a `DoubleStream` consisting of the results of applying the given
  /// function to the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final halves = IntStream.range(1, 5)
  ///     .mapToDouble((n) => n / 2.0);
  /// ```
  DoubleStream mapToDouble(double Function(int) mapper);

  /// Returns a stream consisting of the results of replacing each element
  /// with the contents of a mapped stream.
  /// 
  /// ## Example
  /// ```dart
  /// final expanded = IntStream.range(1, 3)
  ///     .flatMap((n) => IntStream.range(0, n));
  /// ```
  IntStream flatMap(IntStream Function(int) mapper);

  /// Returns a stream with duplicate elements removed.
  /// 
  /// ## Example
  /// ```dart
  /// final unique = IntStream.of([1, 2, 2, 3, 3, 3])
  ///     .distinct();
  /// ```
  IntStream distinct();

  /// Returns a stream with elements sorted in natural ascending order.
  /// 
  /// ## Example
  /// ```dart
  /// final sorted = IntStream.of([3, 1, 4, 1, 5])
  ///     .sorted();
  /// ```
  IntStream sorted();

  /// Returns a stream consisting of the elements of this stream, additionally
  /// performing the provided action on each element as they are consumed.
  /// 
  /// ## Example
  /// ```dart
  /// final result = IntStream.range(1, 5)
  ///     .peek((n) => print('Processing: $n'))
  ///     .map((n) => n * 2)
  ///     .toList();
  /// ```
  IntStream peek(void Function(int) action);

  /// Truncates the stream to be no longer than [maxSize].
  /// 
  /// ## Example
  /// ```dart
  /// final first5 = IntStream.range(1, 100)
  ///     .limit(5);
  /// ```
  IntStream limit(int maxSize);

  /// Skips the first [n] elements of the stream.
  /// 
  /// ## Example
  /// ```dart
  /// final afterFirst5 = IntStream.range(1, 100)
  ///     .skip(5);
  /// ```
  IntStream skip(int n);

  /// Returns a stream consisting of the elements taken from this stream
  /// until the predicate returns `false`.
  /// 
  /// ## Example
  /// ```dart
  /// final lessThan5 = IntStream.range(1, 10)
  ///     .takeWhile((n) => n < 5);
  /// ```
  IntStream takeWhile(bool Function(int) predicate);

  /// Drops elements from the stream while the predicate returns `true`,
  /// then returns the remaining elements.
  /// 
  /// ## Example
  /// ```dart
  /// final from5 = IntStream.range(1, 10)
  ///     .dropWhile((n) => n < 5);
  /// ```
  IntStream dropWhile(bool Function(int) predicate);

  // Terminal operations

  /// Performs the given action for each element of the stream.
  /// 
  /// ## Example
  /// ```dart
  /// IntStream.range(1, 5)
  ///     .forEach(print); // prints 1, 2, 3, 4
  /// ```
  void forEach(void Function(int) action);

  /// Performs the given action for each element, respecting the encounter order.
  /// 
  /// ## Example
  /// ```dart
  /// IntStream.range(1, 5)
  ///     .forEachOrdered(print); // prints 1, 2, 3, 4 in order
  /// ```
  void forEachOrdered(void Function(int) action);

  /// Collects the elements into a [List].
  /// 
  /// ## Example
  /// ```dart
  /// final list = IntStream.range(1, 5).toList(); // [1, 2, 3, 4]
  /// ```
  List<int> toList();

  /// Performs a reduction on the elements using the given identity and
  /// associative accumulation function.
  /// 
  /// ## Example
  /// ```dart
  /// final sum = IntStream.range(1, 5)
  ///     .reduce(0, (a, b) => a + b); // 10
  /// ```
  int reduce(int identity, int Function(int, int) op);

  /// Performs a reduction and returns an [Optional] of the result.
  /// 
  /// ## Example
  /// ```dart
  /// final max = IntStream.of([1, 2, 3, 4, 5])
  ///     .reduceOptional((a, b) => a > b ? a : b);
  /// ```
  Optional<int> reduceOptional(int Function(int, int) op);

  /// Returns the sum of the elements.
  /// 
  /// ## Example
  /// ```dart
  /// final sum = IntStream.range(1, 5).sum(); // 10
  /// ```
  int sum();

  /// Returns the minimum value as an [Optional], or empty if the stream is empty.
  /// 
  /// ## Example
  /// ```dart
  /// final min = IntStream.of([3, 1, 4, 1, 5]).min(); // Optional(1)
  /// ```
  Optional<int> min();

  /// Returns the maximum value as an [Optional], or empty if the stream is empty.
  /// 
  /// ## Example
  /// ```dart
  /// final max = IntStream.of([3, 1, 4, 1, 5]).max(); // Optional(5)
  /// ```
  Optional<int> max();

  /// Returns the count of elements in the stream.
  /// 
  /// ## Example
  /// ```dart
  /// final count = IntStream.range(1, 10).count(); // 9
  /// ```
  int count();

  /// Returns the arithmetic mean of values in the stream.
  /// 
  /// ## Example
  /// ```dart
  /// final avg = IntStream.range(1, 5).average(); // 2.5
  /// ```
  double average();

  /// Returns `true` if any elements match the predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final hasEven = IntStream.range(1, 5)
  ///     .anyMatch((n) => n % 2 == 0); // true
  /// ```
  bool anyMatch(bool Function(int) predicate);

  /// Returns `true` if all elements match the predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final allPositive = IntStream.range(1, 5)
  ///     .allMatch((n) => n > 0); // true
  /// ```
  bool allMatch(bool Function(int) predicate);

  /// Returns `true` if no elements match the predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final noNegative = IntStream.range(1, 5)
  ///     .noneMatch((n) => n < 0); // true
  /// ```
  bool noneMatch(bool Function(int) predicate);

  /// Returns the first element of the stream, if present.
  /// 
  /// ## Example
  /// ```dart
  /// final first = IntStream.range(1, 5).findFirst(); // Optional(1)
  /// ```
  Optional<int> findFirst();

  /// Returns any element from the stream, which may be useful in parallel contexts.
  /// 
  /// ## Example
  /// ```dart
  /// final any = IntStream.range(1, 5).findAny(); // Optional(some element)
  /// ```
  Optional<int> findAny();

  /// Converts this `IntStream` to a `DoubleStream`.
  /// 
  /// ## Example
  /// ```dart
  /// final doubleStream = IntStream.range(1, 5).asDoubleStream();
  /// ```
  DoubleStream asDoubleStream();
}