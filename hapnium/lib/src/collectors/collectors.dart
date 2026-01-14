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

import '../statistics/double_summary_statistics.dart';
import '../statistics/int_summary_statistics.dart';
import 'collector.dart';
import 'internals.dart';

/// {@template collectors}
/// Implementations of [Collector] that implement various useful reduction
/// operations, such as accumulating elements into collections, summarizing
/// elements according to various criteria, etc.
/// 
/// The following are examples of using the predefined collectors to perform
/// common mutable reduction tasks:
/// 
/// ```dart
/// // Accumulate names into a List
/// final list = people.stream()
///     .map((p) => p.name)
///     .collect(Collectors.toList());
/// 
/// // Accumulate names into a Set
/// final set = people.stream()
///     .map((p) => p.name)
///     .collect(Collectors.toSet());
/// 
/// // Convert elements to strings and concatenate them, separated by commas
/// final joined = things.stream()
///     .map((t) => t.toString())
///     .collect(Collectors.joining(', '));
/// 
/// // Compute sum of salaries of employee
/// final total = employees.stream()
///     .collect(Collectors.summingInt((e) => e.salary));
/// 
/// // Group employees by department
/// final byDept = employees.stream()
///     .collect(Collectors.groupingBy((e) => e.department));
/// 
/// // Compute sum of salaries by department
/// final totalByDept = employees.stream()
///     .collect(Collectors.groupingBy(
///         (e) => e.department,
///         Collectors.summingInt((e) => e.salary)));
/// 
/// // Partition students into passing and failing
/// final passingFailing = students.stream()
///     .collect(Collectors.partitioningBy((s) => s.grade >= 60));
/// ```
/// 
/// {@endtemplate}
class Collectors {
  Collectors._(); // Private constructor to prevent instantiation

  /// Returns a [Collector] that accumulates the input elements into a new [List].
  /// 
  /// ## Example
  /// ```dart
  /// final list = stream.collect(Collectors.toList());
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, List<T>, List<T>> toList<T>() {
    return Collector<T, List<T>, List<T>>(
      supplier: () => <T>[],
      accumulator: (list, element) => list.add(element),
      combiner: (list1, list2) => list1..addAll(list2),
      finisher: (list) => List<T>.from(list),
    );
  }

  /// Returns a [Collector] that accumulates the input elements into a new [Set].
  /// 
  /// ## Example
  /// ```dart
  /// final set = stream.collect(Collectors.toSet());
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, Set<T>, Set<T>> toSet<T>() {
    return Collector<T, Set<T>, Set<T>>(
      supplier: () => <T>{},
      accumulator: (set, element) => set.add(element),
      combiner: (set1, set2) => set1..addAll(set2),
      finisher: (set) => Set<T>.from(set),
    );
  }

  /// Returns a [Collector] that accumulates the input elements into a new [Map]
  /// whose keys and values are the result of applying the provided mapping
  /// functions to the input elements.
  /// 
  /// ## Example
  /// ```dart
  /// final map = people.stream()
  ///     .collect(Collectors.toMap(
  ///         (p) => p.id,
  ///         (p) => p.name));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, Map<K, U>, Map<K, U>> toMap<T, K, U>(
    K Function(T) keyMapper,
    U Function(T) valueMapper, [
    U Function(U, U)? mergeFunction,
  ]) {
    return Collector<T, Map<K, U>, Map<K, U>>(
      supplier: () => <K, U>{},
      accumulator: (map, element) {
        final key = keyMapper(element);
        final value = valueMapper(element);
        if (map.containsKey(key) && mergeFunction != null) {
          map[key] = mergeFunction(map[key] as U, value);
        } else {
          map[key] = value;
        }
      },
      combiner: (map1, map2) {
        for (final entry in map2.entries) {
          if (map1.containsKey(entry.key) && mergeFunction != null) {
            map1[entry.key] = mergeFunction(map1[entry.key] as U, entry.value);
          } else {
            map1[entry.key] = entry.value;
          }
        }
        return map1;
      },
      finisher: (map) => Map<K, U>.from(map),
    );
  }

  /// Returns a [Collector] that concatenates the input elements into a [String],
  /// in encounter order.
  /// 
  /// ## Example
  /// ```dart
  /// final joined = stream.collect(Collectors.joining());
  /// final withDelimiter = stream.collect(Collectors.joining(', '));
  /// final withPrefixSuffix = stream.collect(Collectors.joining(', ', '[', ']'));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, StringBuffer, String> joining<T>([
    String delimiter = '',
    String prefix = '',
    String suffix = '',
  ]) {
    return Collector<T, StringBuffer, String>(
      supplier: () => StringBuffer(prefix),
      accumulator: (buffer, element) {
        if (buffer.length > prefix.length) {
          buffer.write(delimiter);
        }
        buffer.write(element.toString());
      },
      combiner: (buffer1, buffer2) {
        final content2 = buffer2.toString().substring(prefix.length);
        if (content2.isNotEmpty) {
          if (buffer1.length > prefix.length) {
            buffer1.write(delimiter);
          }
          buffer1.write(content2);
        }
        return buffer1;
      },
      finisher: (buffer) => buffer.toString() + suffix,
    );
  }

  /// Returns a [Collector] that produces the sum of integer-valued functions
  /// applied to the input elements.
  /// 
  /// ## Example
  /// ```dart
  /// final totalSalary = employees.stream()
  ///     .collect(Collectors.summingInt((e) => e.salary));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, InternalIntSummaryStatistics, int> summingInt<T>(int Function(T) mapper) {
    return Collector<T, InternalIntSummaryStatistics, int>(
      supplier: () => InternalIntSummaryStatistics(),
      accumulator: (stats, element) => stats.accept(mapper(element)),
      combiner: (stats1, stats2) => stats1.combine(stats2),
      finisher: (stats) => stats.sum,
    );
  }

  /// Returns a [Collector] that produces the sum of double-valued functions
  /// applied to the input elements.
  /// 
  /// ## Example
  /// ```dart
  /// final totalAmount = transactions.stream()
  ///     .collect(Collectors.summingDouble((t) => t.amount));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, InternalDoubleSummaryStatistics, double> summingDouble<T>(double Function(T) mapper) {
    return Collector<T, InternalDoubleSummaryStatistics, double>(
      supplier: () => InternalDoubleSummaryStatistics(),
      accumulator: (stats, element) => stats.accept(mapper(element)),
      combiner: (stats1, stats2) => stats1.combine(stats2),
      finisher: (stats) => stats.sum,
    );
  }

  /// Returns a [Collector] implementing a "group by" operation on input elements,
  /// grouping elements according to a classification function, and returning the
  /// results in a [Map].
  /// 
  /// ## Example
  /// ```dart
  /// final byDepartment = employees.stream()
  ///     .collect(Collectors.groupingBy((e) => e.department));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, Map<K, List<T>>, Map<K, List<T>>> groupingBy<T, K>(
    K Function(T) classifier, [
    Collector<T, dynamic, dynamic>? downstream,
  ]) {
    downstream ??= toList<T>();
    
    return Collector<T, Map<K, List<T>>, Map<K, List<T>>>(
      supplier: () => <K, List<T>>{},
      accumulator: (map, element) {
        final key = classifier(element);
        map.putIfAbsent(key, () => <T>[]).add(element);
      },
      combiner: (map1, map2) {
        for (final entry in map2.entries) {
          map1.putIfAbsent(entry.key, () => <T>[]).addAll(entry.value);
        }
        return map1;
      },
      finisher: (map) => Map<K, List<T>>.from(map),
    );
  }

  /// Returns a [Collector] which partitions the input elements according to a
  /// [Predicate], and organizes them into a [Map] with [bool] keys.
  /// 
  /// ## Example
  /// ```dart
  /// final passingFailing = students.stream()
  ///     .collect(Collectors.partitioningBy((s) => s.grade >= 60));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, Map<bool, List<T>>, Map<bool, List<T>>> partitioningBy<T>(
    bool Function(T) predicate, [
    Collector<T, dynamic, dynamic>? downstream,
  ]) {
    downstream ??= toList<T>();
    
    return Collector<T, Map<bool, List<T>>, Map<bool, List<T>>>(
      supplier: () => <bool, List<T>>{true: <T>[], false: <T>[]},
      accumulator: (map, element) {
        final key = predicate(element);
        map[key]!.add(element);
      },
      combiner: (map1, map2) {
        map1[true]!.addAll(map2[true]!);
        map1[false]!.addAll(map2[false]!);
        return map1;
      },
      finisher: (map) => Map<bool, List<T>>.from(map),
    );
  }

  /// Returns a [Collector] that produces the arithmetic mean of integer-valued
  /// functions applied to the input elements.
  /// 
  /// ## Example
  /// ```dart
  /// final averageAge = people.stream()
  ///     .collect(Collectors.averagingInt((p) => p.age));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, InternalIntSummaryStatistics, double> averagingInt<T>(int Function(T) mapper) {
    return Collector<T, InternalIntSummaryStatistics, double>(
      supplier: () => InternalIntSummaryStatistics(),
      accumulator: (stats, element) => stats.accept(mapper(element)),
      combiner: (stats1, stats2) => stats1.combine(stats2),
      finisher: (stats) => stats.average,
    );
  }

  /// Returns a [Collector] that produces the arithmetic mean of double-valued
  /// functions applied to the input elements.
  /// 
  /// ## Example
  /// ```dart
  /// final averageAmount = transactions.stream()
  ///     .collect(Collectors.averagingDouble((t) => t.amount));
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, InternalDoubleSummaryStatistics, double> averagingDouble<T>(double Function(T) mapper) {
    return Collector<T, InternalDoubleSummaryStatistics, double>(
      supplier: () => InternalDoubleSummaryStatistics(),
      accumulator: (stats, element) => stats.accept(mapper(element)),
      combiner: (stats1, stats2) => stats1.combine(stats2),
      finisher: (stats) => stats.average,
    );
  }

  /// Returns a [Collector] which applies an [int]-producing mapping function to
  /// each input element, and returns summary statistics for the resulting values.
  /// 
  /// ## Example
  /// ```dart
  /// final stats = employees.stream()
  ///     .collect(Collectors.summarizingInt((e) => e.salary));
  /// print('Average salary: ${stats.average}');
  /// print('Max salary: ${stats.max}');
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, InternalIntSummaryStatistics, IntSummaryStatistics> summarizingInt<T>(int Function(T) mapper) {
    return Collector<T, InternalIntSummaryStatistics, IntSummaryStatistics>(
      supplier: () => InternalIntSummaryStatistics(),
      accumulator: (stats, element) => stats.accept(mapper(element)),
      combiner: (stats1, stats2) => stats1.combine(stats2),
      finisher: (stats) => IntSummaryStatistics(
        stats.count,
        stats.sum,
        stats.min,
        stats.max,
        stats.average,
      ),
    );
  }

  /// Returns a [Collector] which applies a [double]-producing mapping function to
  /// each input element, and returns summary statistics for the resulting values.
  /// 
  /// ## Example
  /// ```dart
  /// final stats = transactions.stream()
  ///     .collect(Collectors.summarizingDouble((t) => t.amount));
  /// print('Average amount: ${stats.average}');
  /// print('Total amount: ${stats.sum}');
  /// ```
  /// 
  /// {@macro collectors}
  static Collector<T, InternalDoubleSummaryStatistics, DoubleSummaryStatistics> summarizingDouble<T>(double Function(T) mapper) {
    return Collector<T, InternalDoubleSummaryStatistics, DoubleSummaryStatistics>(
      supplier: () => InternalDoubleSummaryStatistics(),
      accumulator: (stats, element) => stats.accept(mapper(element)),
      combiner: (stats1, stats2) => stats1.combine(stats2),
      finisher: (stats) => DoubleSummaryStatistics(
        stats.count,
        stats.sum,
        stats.min,
        stats.max,
        stats.average,
      ),
    );
  }
}