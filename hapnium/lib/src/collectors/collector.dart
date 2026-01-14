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

/// {@template collector}
/// A mutable reduction operation that accumulates input elements into a mutable
/// result container, optionally transforming the accumulated result into a final
/// representation after all input elements have been processed.
/// 
/// Reduction operations can be performed either sequentially or in parallel.
/// 
/// Examples of mutable reduction operations include: accumulating elements into
/// a [List]; concatenating strings using a [StringBuffer]; computing summary
/// information about elements such as sum, min, max, or average; computing
/// "pivot table" summaries such as "maximum valued transaction by seller", etc.
/// 
/// ## Example
/// ```dart
/// final collector = Collector<String, StringBuffer, String>(
///   supplier: () => StringBuffer(),
///   accumulator: (buffer, element) => buffer.write(element),
///   combiner: (buffer1, buffer2) => buffer1..write(buffer2.toString()),
///   finisher: (buffer) => buffer.toString(),
/// );
/// ```
/// 
/// {@endtemplate}
class Collector<T, A, R> {
  /// A function that creates and returns a new mutable result container.
  final A Function() supplier;

  /// A function that folds a value into a mutable result container.
  final void Function(A, T) accumulator;

  /// A function that accepts two partial results and merges them.
  final A Function(A, A) combiner;

  /// A function that transforms the intermediate accumulation result into the
  /// final result type.
  final R Function(A) finisher;

  /// Creates a new [Collector] with the specified functions.
  /// 
  /// {@macro collector}
  const Collector({
    required this.supplier,
    required this.accumulator,
    required this.combiner,
    required this.finisher,
  });
}