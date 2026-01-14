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

/// {@template double_summary_statistics}
/// A state object for collecting statistics such as count, min, max, sum,
/// and average for a stream of `double` values.
///
/// This class is typically used in analytics, reporting, or data stream
/// summarization where aggregate statistics are needed.
///
/// All fields are final and computed externally, making this class ideal for
/// read-only snapshot use.
///
/// ---
///
/// ### 📌 Example Usage
///
/// ```dart
/// final stats = DoubleSummaryStatistics(
///   5, // count
///   123.4, // sum
///   10.0, // min
///   45.2, // max
///   24.68, // average
/// );
///
/// print(stats.average); // 24.68
/// print(stats); // DoubleSummaryStatistics{count=5, sum=123.4, min=10.0, max=45.2, average=24.68}
/// ```
/// {@endtemplate}
class DoubleSummaryStatistics {
  /// The total number of values processed.
  final int count;

  /// The sum of all double values.
  final double sum;

  /// The minimum value encountered.
  final double min;

  /// The maximum value encountered.
  final double max;

  /// The average of all values (i.e., `sum / count`).
  final double average;

  /// {@macro double_summary_statistics}
  const DoubleSummaryStatistics(
    this.count,
    this.sum,
    this.min,
    this.max,
    this.average,
  );

  @override
  String toString() {
    return 'DoubleSummaryStatistics{count=$count, sum=$sum, min=$min, max=$max, average=$average}';
  }
}