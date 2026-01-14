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

import '../../../classes/optional.dart';
import '../base_stream.dart';
import '../int/int_stream.dart';
import '../double/double_stream.dart';
import '../../../collectors/collector.dart';
import '_generic_stream.dart';

/// {@template generic_stream}
/// A sequence of elements supporting sequential and parallel aggregate operations.
/// 
/// The following example illustrates an aggregate operation using [GenericStream]:
/// 
/// ```dart
/// final sum = widgets.stream()
///     .filter((w) => w.color == RED)
///     .mapToInt((w) => w.weight)
///     .sum();
/// ```
/// 
/// In this example, `widgets` is a [List] of `Widget` objects. We create a stream
/// of `Widget` objects via [List.stream], filter it to produce a stream containing
/// only the red widgets, and then transform it into a stream of `int` values
/// representing the weight of each red widget. Then this stream is summed to
/// produce a total weight.
/// 
/// In addition to [GenericStream], which is a stream of object references, there are
/// primitive specializations for [IntStream] and [DoubleStream], all of which are
/// referred to as "streams" and conform to the characteristics and restrictions
/// described here.
/// 
/// To perform a computation, stream operations are composed into a stream pipeline.
/// A stream pipeline consists of a source (which might be an array, a collection,
/// a generator function, an I/O channel, etc), zero or more intermediate operations
/// (which transform a stream into another stream, such as [filter]), and a terminal
/// operation (which produces a result or side-effect, such as [count] or [forEach]).
/// Streams are lazy; computation on the source data is only performed when the
/// terminal operation is initiated, and source elements are consumed only as needed.
/// 
/// ## Example Usage
/// ```dart
/// final people = [
///   Person('Alice', 25, 'Engineering'),
///   Person('Bob', 30, 'Marketing'),
///   Person('Charlie', 35, 'Engineering'),
///   Person('Diana', 28, 'Sales'),
/// ];
/// 
/// // Filter and collect
/// final engineers = GenericStream.of(people)
///     .filter((p) => p.department == 'Engineering')
///     .toList();
/// 
/// // Transform and reduce
/// final totalAge = GenericStream.of(people)
///     .mapToInt((p) => p.age)
///     .sum();
/// 
/// // Group by department
/// final byDepartment = GenericStream.of(people)
///     .collect(Collectors.groupingBy((p) => p.department));
/// 
/// // Complex pipeline
/// final result = GenericStream.of(people)
///     .filter((p) => p.age > 25)
///     .map((p) => p.name.toUpperCase())
///     .sorted()
///     .limit(2)
///     .collect(Collectors.joining(', '));
/// ```
/// 
/// {@endtemplate}
abstract class GenericStream<T> extends BaseStream<T, GenericStream<T>> {
  /// {@macro generic_stream}
  GenericStream();

  /// Creates a [GenericStream] from the given values.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = GenericStream.of([1, 2, 3, 4, 5]);
  /// ```
  /// {@macro generic_stream}
  factory GenericStream.of(Iterable<T> values) = StandardGenericStream<T>.of;

  /// Creates an empty [GenericStream].
  /// 
  /// ## Example
  /// ```dart
  /// final stream = GenericStream<String>.empty();
  /// print(stream.count()); // 0
  /// ```
  /// 
  /// {@macro generic_stream}
  factory GenericStream.empty() = StandardGenericStream<T>.empty;

  /// Creates a [GenericStream] from a single element.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = GenericStream.ofSingle('Hello');
  /// ```
  /// 
  /// {@macro generic_stream}
  factory GenericStream.ofSingle(T value) = StandardGenericStream<T>.ofSingle;

  /// Creates an infinite [GenericStream] by repeatedly applying a function.
  /// 
  /// ## Example
  /// ```dart
  /// final fibonacci = GenericStream.iterate(
  ///   [0, 1],
  ///   (pair) => [pair[1], pair[0] + pair[1]]
  /// ).map((pair) => pair[0]).limit(10);
  /// ```
  /// 
  /// {@macro generic_stream}
  factory GenericStream.iterate(T seed, T Function(T) f) = StandardGenericStream<T>.iterate;

  /// Creates a [GenericStream] by repeatedly calling a supplier function.
  /// 
  /// ## Example
  /// ```dart
  /// final random = GenericStream.generate(() => Random().nextInt(100))
  ///     .limit(5);
  /// ```
  /// 
  /// {@macro generic_stream}
  factory GenericStream.generate(T Function() supplier) = StandardGenericStream<T>.generate;

  /// Creates an [IntStream] from a range of integers.
  /// 
  /// The range includes [startInclusive] and excludes [endExclusive].
  /// 
  /// ## Example
  /// ```dart
  /// final numbers = GenericStream.range(1, 10); // 1, 2, 3, 4, 5, 6, 7, 8, 9
  /// ```
  /// 
  /// {@macro int_stream}
  static IntStream range(int startInclusive, int endExclusive) {
    return IntStream.range(startInclusive, endExclusive);
  }

  /// Creates an [IntStream] from a closed range of integers.
  /// 
  /// The range includes both [startInclusive] and [endInclusive].
  /// 
  /// ## Example
  /// ```dart
  /// final numbers = GenericStream.rangeClosed(1, 5); // 1, 2, 3, 4, 5
  /// ```
  /// 
  /// {@macro int_stream}
  static IntStream rangeClosed(int startInclusive, int endInclusive) {
    return IntStream.rangeClosed(startInclusive, endInclusive);
  }

  // Intermediate operations

  /// Returns a stream consisting of the elements of this stream that match
  /// the given predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final evens = GenericStream.range(1, 10)
  ///     .filter((n) => n % 2 == 0);
  /// ```
  GenericStream<T> filter(bool Function(T) predicate);

  /// Returns a stream consisting of the results of applying the given
  /// function to the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final lengths = GenericStream.of(['hello', 'world'])
  ///     .map((s) => s.length);
  /// ```
  GenericStream<R> map<R>(R Function(T) mapper);

  /// Returns an [IntStream] consisting of the results of applying the given
  /// function to the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final lengths = GenericStream.of(['hello', 'world'])
  ///     .mapToInt((s) => s.length);
  /// ```
  IntStream mapToInt(int Function(T) mapper);

  /// Returns a [DoubleStream] consisting of the results of applying the given
  /// function to the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final prices = GenericStream.of(['10.5', '20.3', '15.7'])
  ///     .mapToDouble((s) => double.parse(s));
  /// ```
  DoubleStream mapToDouble(double Function(T) mapper);

  /// Returns a stream consisting of the results of replacing each element of
  /// this stream with the contents of a mapped stream produced by applying
  /// the provided mapping function to each element.
  /// 
  /// ## Example
  /// ```dart
  /// final words = GenericStream.of(['hello world', 'foo bar'])
  ///     .flatMap((s) => GenericStream.of(s.split(' ')));
  /// ```
  GenericStream<R> flatMap<R>(GenericStream<R> Function(T) mapper);

  /// Returns a stream consisting of the distinct elements (according to
  /// [Object.==]) of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final unique = GenericStream.of([1, 2, 2, 3, 3, 3])
  ///     .distinct();
  /// ```
  GenericStream<T> distinct();

  /// Returns a stream consisting of the elements of this stream, sorted
  /// according to natural order.
  /// 
  /// ## Example
  /// ```dart
  /// final sorted = GenericStream.of([3, 1, 4, 1, 5])
  ///     .sorted();
  /// ```
  GenericStream<T> sorted([int Function(T, T)? comparator]);

  /// Returns a stream consisting of the elements of this stream, additionally
  /// performing the provided action on each element as elements are consumed
  /// from the resulting stream.
  /// 
  /// ## Example
  /// ```dart
  /// final result = GenericStream.of([1, 2, 3])
  ///     .peek((n) => print('Processing: $n'))
  ///     .map((n) => n * 2)
  ///     .toList();
  /// ```
  GenericStream<T> peek(void Function(T) action);

  /// Returns a stream consisting of the elements of this stream, truncated
  /// to be no longer than [maxSize] in length.
  /// 
  /// ## Example
  /// ```dart
  /// final first5 = GenericStream.range(1, 100)
  ///     .limit(5);
  /// ```
  GenericStream<T> limit(int maxSize);

  /// Returns a stream consisting of the remaining elements of this stream
  /// after discarding the first [n] elements of the stream.
  /// 
  /// ## Example
  /// ```dart
  /// final afterFirst5 = GenericStream.range(1, 100)
  ///     .skip(5);
  /// ```
  GenericStream<T> skip(int n);

  /// Returns a stream consisting of the longest prefix of elements taken from
  /// this stream that match the given predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final lessThan5 = GenericStream.range(1, 10)
  ///     .takeWhile((n) => n < 5);
  /// ```
  GenericStream<T> takeWhile(bool Function(T) predicate);

  /// Returns a stream consisting of the remaining elements of this stream
  /// after dropping the longest prefix of elements that match the given predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final from5 = GenericStream.range(1, 10)
  ///     .dropWhile((n) => n < 5);
  /// ```
  GenericStream<T> dropWhile(bool Function(T) predicate);

  // Terminal operations

  /// Performs an action for each element of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// GenericStream.of([1, 2, 3, 4, 5])
  ///     .forEach(print); // prints 1, 2, 3, 4, 5
  /// ```
  void forEach(void Function(T) action);

  /// Performs an action for each element of this stream, in the encounter
  /// order of the stream if the stream has a defined encounter order.
  /// 
  /// ## Example
  /// ```dart
  /// GenericStream.of([1, 2, 3, 4, 5])
  ///     .forEachOrdered(print); // prints 1, 2, 3, 4, 5 in order
  /// ```
  void forEachOrdered(void Function(T) action);

  /// Returns the first element of this stream that matches the given predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final firstEven = GenericStream.range(1, 10)
  ///     .where((n) => n % 2 == 0)
  ///     .first();
  /// ```
  /// 
  /// Throws [NoSuchElementException] if no element matches the predicate.
  GenericStream<T> where(bool Function(T) predicate);

  /// Returns a [List] containing the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final list = GenericStream.of([1, 2, 3, 4, 5]).toList();
  /// ```
  List<T> toList();

  /// Returns a [Set] containing the elements of this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final set = GenericStream.of([1, 2, 2, 3, 3]).toSet();
  /// ```
  Set<T> toSet();

  /// Performs a mutable reduction operation on the elements of this stream
  /// using a [Collector].
  /// 
  /// ## Example
  /// ```dart
  /// final joined = GenericStream.of(['a', 'b', 'c'])
  ///     .collect(Collectors.joining(', '));
  /// ```
  R collectFrom<A, R>(Collector<T, A, R> collector);

  /// Performs a reduction on the elements of this stream, using the provided
  /// identity value and an associative accumulation function, and returns
  /// the reduced value.
  /// 
  /// ## Example
  /// ```dart
  /// final sum = GenericStream.of([1, 2, 3, 4, 5])
  ///     .reduce(0, (a, b) => a + b);
  /// ```
  T reduce(T identity, T Function(T, T) accumulator);

  /// Performs a reduction on the elements of this stream, using an
  /// associative accumulation function, and returns an [Optional]
  /// describing the reduced value, if any.
  /// 
  /// ## Example
  /// ```dart
  /// final max = GenericStream.of([1, 2, 3, 4, 5])
  ///     .reduceOptional((a, b) => a > b ? a : b);
  /// ```
  Optional<T> reduceOptional(T Function(T, T) accumulator);

  /// Returns the minimum element of this stream according to the provided
  /// [Comparator].
  /// 
  /// ## Example
  /// ```dart
  /// final min = GenericStream.of([3, 1, 4, 1, 5])
  ///     .min((a, b) => a.compareTo(b));
  /// ```
  Optional<T> min([int Function(T, T)? comparator]);

  /// Returns the maximum element of this stream according to the provided
  /// [Comparator].
  /// 
  /// ## Example
  /// ```dart
  /// final max = GenericStream.of([3, 1, 4, 1, 5])
  ///     .max((a, b) => a.compareTo(b));
  /// ```
  Optional<T> max([int Function(T, T)? comparator]);

  /// Returns the count of elements in this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final count = GenericStream.of([1, 2, 3, 4, 5]).count(); // 5
  /// ```
  int count();

  /// Returns whether any elements of this stream match the provided predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final hasEven = GenericStream.of([1, 2, 3, 4, 5])
  ///     .anyMatch((n) => n % 2 == 0); // true
  /// ```
  bool anyMatch(bool Function(T) predicate);

  /// Returns whether all elements of this stream match the provided predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final allPositive = GenericStream.of([1, 2, 3, 4, 5])
  ///     .allMatch((n) => n > 0); // true
  /// ```
  bool allMatch(bool Function(T) predicate);

  /// Returns whether no elements of this stream match the provided predicate.
  /// 
  /// ## Example
  /// ```dart
  /// final noNegative = GenericStream.of([1, 2, 3, 4, 5])
  ///     .noneMatch((n) => n < 0); // true
  /// ```
  bool noneMatch(bool Function(T) predicate);

  /// Returns an [Optional] describing the first element of this stream,
  /// or an empty [Optional] if the stream is empty.
  /// 
  /// ## Example
  /// ```dart
  /// final first = GenericStream.of([1, 2, 3, 4, 5]).findFirst(); // Optional(1)
  /// ```
  Optional<T> findFirst();

  /// Returns an [Optional] describing some element of the stream, or an
  /// empty [Optional] if the stream is empty.
  /// 
  /// ## Example
  /// ```dart
  /// final any = GenericStream.of([1, 2, 3, 4, 5]).findAny(); // Optional(some element)
  /// ```
  Optional<T> findAny();
}