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

/// {@template base_stream}
/// Base interface for streams, which are sequences of elements supporting
/// sequential and parallel aggregate operations.
/// 
/// This is the Dart equivalent of Java's BaseStream interface, adapted for
/// Dart's language features and conventions.
/// 
/// ## Example Usage
/// ```dart
/// // Basic stream operations
/// final numbers = [1, 2, 3, 4, 5];
/// final stream = DartStream.of(numbers);
/// 
/// final result = stream
///     .filter((n) => n > 2)
///     .map((n) => n * 2)
///     .toList();
/// print(result); // [6, 8, 10]
/// ```
/// 
/// See the documentation for [DartStream] and related classes for additional
/// specification of streams, stream operations, and stream pipelines.
/// 
/// {@endtemplate}
abstract class BaseStream<T, S extends BaseStream<T, S>> {
  /// {@macro base_stream}
  BaseStream();

  /// Returns an iterator for the elements of this stream.
  /// 
  /// This is a terminal operation.
  /// 
  /// ## API Note
  /// This operation is provided as an "escape hatch" to enable
  /// arbitrary client-controlled pipeline traversals in the event that the
  /// existing operations are not sufficient to the task.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5]);
  /// final iterator = stream.iterator();
  /// 
  /// while (iterator.moveNext()) {
  ///   print(iterator.current);
  /// }
  /// ```
  Iterator<T> iterator();

  /// Returns an iterable for the elements of this stream.
  /// 
  /// This is a terminal operation.
  /// 
  /// ## API Note
  /// This operation is provided as an "escape hatch" to enable
  /// arbitrary client-controlled pipeline traversals in the event that the
  /// existing operations are not sufficient to the task.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5]);
  /// final iterable = stream.iterable();
  /// 
  /// for (final element in iterable) {
  ///   print(element);
  /// }
  /// ```
  Iterable<T> iterable();

  /// Returns whether this stream, if a terminal operation were to be executed,
  /// would execute in parallel.
  /// 
  /// Calling this method after invoking a terminal stream operation method 
  /// may yield unpredictable results.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5]);
  /// print(stream.isParallel()); // false
  /// 
  /// final parallelStream = stream.parallel();
  /// print(parallelStream.isParallel()); // true
  /// ```
  bool isParallel();

  /// Returns an equivalent stream that is sequential.
  /// 
  /// May return itself, either because the stream was already sequential, 
  /// or because the underlying stream state was modified to be sequential.
  /// 
  /// This is an intermediate operation.
  /// 
  /// ## Example
  /// ```dart
  /// final parallelStream = DartStream.of([1, 2, 3, 4, 5]).parallel();
  /// final sequentialStream = parallelStream.sequential();
  /// print(sequentialStream.isParallel()); // false
  /// ```
  S sequential();

  /// Returns an equivalent stream that is parallel.
  /// 
  /// May return itself, either because the stream was already parallel, 
  /// or because the underlying stream state was modified to be parallel.
  /// 
  /// This is an intermediate operation.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5]);
  /// final parallelStream = stream.parallel();
  /// print(parallelStream.isParallel()); // true
  /// ```
  S parallel();

  /// Returns an equivalent stream that is unordered.
  /// 
  /// May return itself, either because the stream was already unordered, 
  /// or because the underlying stream state was modified to be unordered.
  /// 
  /// This is an intermediate operation.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5]);
  /// final unorderedStream = stream.unordered();
  /// // Order is no longer guaranteed in parallel operations
  /// ```
  S unordered();

  /// Returns an equivalent stream with an additional close handler.
  /// 
  /// Close handlers are run when the [close] method is called on the stream, 
  /// and are executed in the order they were added. All close handlers are run, 
  /// even if earlier close handlers throw exceptions.
  /// 
  /// This is an intermediate operation.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5])
  ///     .onClose(() => print('First handler'))
  ///     .onClose(() => print('Second handler'));
  /// 
  /// stream.close(); // Prints both messages
  /// ```
  S onClose(void Function() closeHandler);

  /// Returns a list containing the elements of this stream.
  /// 
  /// This is a terminal operation.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5]);
  /// final list = stream.collect();
  /// print(list); // [1, 2, 3, 4, 5]
  /// ```
  List<T> collect();

  /// Closes this stream, causing all close handlers for this stream pipeline
  /// to be called.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = DartStream.of([1, 2, 3, 4, 5])
  ///     .onClose(() => print('Stream closed'));
  /// 
  /// stream.close(); // Prints "Stream closed"
  /// ```
  void close();
}