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

import 'base_stream/generic/generic_stream.dart';
import 'base_stream/int/int_stream.dart';
import 'base_stream/double/double_stream.dart';

/// {@template stream_support}
/// Low-level utility methods for creating and manipulating streams.
/// 
/// This class is primarily intended for library writers presenting stream views
/// of data structures; most static stream methods intended for end users are in
/// the various stream classes.
/// 
/// ## Example Usage
/// ```dart
/// // Create a stream from an iterable
/// final stream = StreamSupport.stream(someIterable);
/// 
/// // Create a parallel stream
/// final parallelStream = StreamSupport.stream(someIterable, parallel: true);
/// 
/// // Create streams from various sources
/// final intStream = StreamSupport.intStream([1, 2, 3, 4, 5]);
/// final doubleStream = StreamSupport.doubleStream([1.1, 2.2, 3.3]);
/// ```
/// 
/// {@endtemplate}
class StreamSupport {
  /// {@macro stream_support}
  StreamSupport._(); // Private constructor to prevent instantiation

  /// Creates a new sequential or parallel [GenericStream] from an [Iterable].
  /// 
  /// ## Parameters
  /// - [source]: The iterable to create a stream from
  /// - [parallel]: Whether the stream should be parallel (default: false)
  /// 
  /// ## Example
  /// ```dart
  /// final list = [1, 2, 3, 4, 5];
  /// final stream = StreamSupport.stream(list);
  /// final parallelStream = StreamSupport.stream(list, parallel: true);
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> stream<T>(Iterable<T> source, {bool parallel = false}) {
    final stream = GenericStream.of(source);
    return parallel ? stream.parallel() : stream;
  }

  /// Creates a new sequential or parallel [IntStream] from an [Iterable] of integers.
  /// 
  /// ## Parameters
  /// - [source]: The iterable of integers to create a stream from
  /// - [parallel]: Whether the stream should be parallel (default: false)
  /// 
  /// ## Example
  /// ```dart
  /// final numbers = [1, 2, 3, 4, 5];
  /// final intStream = StreamSupport.intStream(numbers);
  /// final parallelIntStream = StreamSupport.intStream(numbers, parallel: true);
  /// ```
  /// 
  /// {@macro int_stream}
  static IntStream intStream(Iterable<int> source, {bool parallel = false}) {
    final stream = IntStream.of(source);
    return parallel ? stream.parallel() : stream;
  }

  /// Creates a new sequential or parallel [DoubleStream] from an [Iterable] of doubles.
  /// 
  /// ## Parameters
  /// - [source]: The iterable of doubles to create a stream from
  /// - [parallel]: Whether the stream should be parallel (default: false)
  /// 
  /// ## Example
  /// ```dart
  /// final values = [1.1, 2.2, 3.3, 4.4, 5.5];
  /// final doubleStream = StreamSupport.doubleStream(values);
  /// final parallelDoubleStream = StreamSupport.doubleStream(values, parallel: true);
  /// ```
  /// 
  /// {@macro double_stream}
  static DoubleStream doubleStream(Iterable<double> source, {bool parallel = false}) {
    final stream = DoubleStream.of(source);
    return parallel ? stream.parallel() : stream;
  }

  /// Creates an empty [GenericStream].
  /// 
  /// ## Example
  /// ```dart
  /// final emptyStream = StreamSupport.empty<String>();
  /// print(emptyStream.count()); // 0
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> empty<T>() {
    return GenericStream.empty();
  }

  /// Creates an empty [IntStream].
  /// 
  /// ## Example
  /// ```dart
  /// final emptyIntStream = StreamSupport.emptyIntStream();
  /// print(emptyIntStream.count()); // 0
  /// ```
  /// 
  /// {@macro int_stream}
  static IntStream emptyIntStream() {
    return IntStream.empty();
  }

  /// Creates an empty [DoubleStream].
  /// 
  /// ## Example
  /// ```dart
  /// final emptyDoubleStream = StreamSupport.emptyDoubleStream();
  /// print(emptyDoubleStream.count()); // 0
  /// ```
  /// 
  /// {@macro double_stream}
  static DoubleStream emptyDoubleStream() {
    return DoubleStream.empty();
  }

  /// Creates a [GenericStream] containing a single element.
  /// 
  /// ## Example
  /// ```dart
  /// final singleStream = StreamSupport.ofSingle('Hello');
  /// print(singleStream.toList()); // ['Hello']
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> ofSingle<T>(T value) {
    return GenericStream.ofSingle(value);
  }

  /// Creates an infinite sequential unordered stream where each element is
  /// generated by the provided supplier function.
  /// 
  /// This is suitable for generating constant streams, streams of random elements, etc.
  /// 
  /// ## Example
  /// ```dart
  /// final randomStream = StreamSupport.generate(() => Random().nextInt(100))
  ///     .limit(10);
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> generate<T>(T Function() supplier) {
    return GenericStream.generate(supplier);
  }

  /// Creates an infinite sequential ordered stream produced by iterative
  /// application of a function to an initial element.
  /// 
  /// The first element (position 0) in the stream will be the provided seed.
  /// For n > 0, the element at position n, will be the result of applying
  /// the function to the element at position n - 1.
  /// 
  /// ## Example
  /// ```dart
  /// final powers = StreamSupport.iterate(1, (n) => n * 2)
  ///     .limit(10); // 1, 2, 4, 8, 16, 32, 64, 128, 256, 512
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> iterate<T>(T seed, T Function(T) f) {
    return GenericStream.iterate(seed, f);
  }

  /// Creates a lazily concatenated stream whose elements are all the elements
  /// of the first stream followed by all the elements of the second stream.
  /// 
  /// ## Example
  /// ```dart
  /// final stream1 = GenericStream.of([1, 2, 3]);
  /// final stream2 = GenericStream.of([4, 5, 6]);
  /// final concatenated = StreamSupport.concat(stream1, stream2);
  /// print(concatenated.toList()); // [1, 2, 3, 4, 5, 6]
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> concat<T>(GenericStream<T> a, GenericStream<T> b) {
    return GenericStream.of([...a.iterable(), ...b.iterable()]);
  }

  /// Creates a stream whose elements are the specified values.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = StreamSupport.of('a', 'b', 'c', 'd');
  /// print(stream.toList()); // ['a', 'b', 'c', 'd']
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> of<T>(T first, [T? second, T? third, T? fourth, T? fifth]) {
    final values = <T>[first];
    if (second != null) values.add(second);
    if (third != null) values.add(third);
    if (fourth != null) values.add(fourth);
    if (fifth != null) values.add(fifth);
    return GenericStream.of(values);
  }

  /// Creates a stream from a variable number of arguments.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = StreamSupport.ofAll([1, 2, 3, 4, 5]);
  /// print(stream.toList()); // [1, 2, 3, 4, 5]
  /// ```
  /// 
  /// {@macro generic_stream}
  static GenericStream<T> ofAll<T>(List<T> values) {
    return GenericStream.of(values);
  }
}