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

import 'int_stream.dart';
import '../double/double_stream.dart';
import '../../../classes/optional.dart';
import '../double/_double_stream.dart';

/// Private implementation of [IntStream].
///
/// This class is a low-level, mutable implementation of [IntStream].
/// It is not intended to be used directly, but rather to support the
/// implementation of [IntStream].
///
/// See the documentation for [IntStream] for the API specification.
class StandardIntStream implements IntStream {
  final Iterable<int> _source;
  final bool _parallel;
  final List<void Function()> _closeHandlers;

  StandardIntStream(this._source, [this._parallel = false, this._closeHandlers = const []]);

  factory StandardIntStream.of(Iterable<int> values) {
    return StandardIntStream(values);
  }

  factory StandardIntStream.range(int startInclusive, int endExclusive) {
    return StandardIntStream(List.generate(
      endExclusive - startInclusive,
      (i) => startInclusive + i,
    ));
  }

  factory StandardIntStream.rangeClosed(int startInclusive, int endInclusive) {
    return StandardIntStream(List.generate(
      endInclusive - startInclusive + 1,
      (i) => startInclusive + i,
    ));
  }

  factory StandardIntStream.empty() {
    return StandardIntStream(<int>[]);
  }

  @override
  Iterator<int> iterator() => _source.iterator;

  @override
  Iterable<int> iterable() => _source;

  @override
  bool isParallel() => _parallel;

  @override
  IntStream sequential() => _parallel ? StandardIntStream(_source, false, _closeHandlers) : this;

  @override
  IntStream parallel() => !_parallel ? StandardIntStream(_source, true, _closeHandlers) : this;

  @override
  IntStream unordered() => this; // For simplicity, return this

  @override
  IntStream onClose(void Function() closeHandler) {
    return StandardIntStream(_source, _parallel, [..._closeHandlers, closeHandler]);
  }

  @override
  void close() {
    for (final handler in _closeHandlers) {
      try {
        handler();
      } catch (e) {
        // Continue executing other handlers even if one fails
      }
    }
  }

  @override
  IntStream filter(bool Function(int) predicate) {
    return StandardIntStream(_source.where(predicate), _parallel, _closeHandlers);
  }

  @override
  IntStream map(int Function(int) mapper) {
    return StandardIntStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  DoubleStream mapToDouble(double Function(int) mapper) {
    return StandardDoubleStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  IntStream flatMap(IntStream Function(int) mapper) {
    return StandardIntStream(
      _source.expand((element) => mapper(element).iterable()),
      _parallel,
      _closeHandlers,
    );
  }

  @override
  IntStream distinct() {
    return StandardIntStream(_source.toSet(), _parallel, _closeHandlers);
  }

  @override
  IntStream sorted() {
    final list = _source.toList()..sort();
    return StandardIntStream(list, _parallel, _closeHandlers);
  }

  @override
  IntStream peek(void Function(int) action) {
    return StandardIntStream(
      _source.map((element) {
        action(element);
        return element;
      }),
      _parallel,
      _closeHandlers,
    );
  }

  @override
  IntStream limit(int maxSize) {
    return StandardIntStream(_source.take(maxSize), _parallel, _closeHandlers);
  }

  @override
  IntStream skip(int n) {
    return StandardIntStream(_source.skip(n), _parallel, _closeHandlers);
  }

  @override
  IntStream takeWhile(bool Function(int) predicate) {
    return StandardIntStream(_source.takeWhile(predicate), _parallel, _closeHandlers);
  }

  @override
  IntStream dropWhile(bool Function(int) predicate) {
    return StandardIntStream(_source.skipWhile(predicate), _parallel, _closeHandlers);
  }

  @override
  void forEach(void Function(int) action) {
    _source.forEach(action);
  }

  @override
  void forEachOrdered(void Function(int) action) {
    _source.forEach(action); // In sequential context, same as forEach
  }

  @override
  List<int> toList() {
    return _source.toList();
  }

  @override
  int reduce(int identity, int Function(int, int) op) {
    return _source.fold(identity, op);
  }

  @override
  Optional<int> reduceOptional(int Function(int, int) op) {
    if (_source.isEmpty) {
      return Optional.empty<int>();
    }
    return Optional.of(_source.reduce(op));
  }

  @override
  int sum() {
    return _source.fold(0, (a, b) => a + b);
  }

  @override
  Optional<int> min() {
    if (_source.isEmpty) {
      return Optional.empty<int>();
    }
    return Optional.of(_source.reduce((a, b) => a < b ? a : b));
  }

  @override
  Optional<int> max() {
    if (_source.isEmpty) {
      return Optional.empty<int>();
    }
    return Optional.of(_source.reduce((a, b) => a > b ? a : b));
  }

  @override
  int count() {
    return _source.length;
  }

  @override
  double average() {
    if (_source.isEmpty) {
      return 0.0;
    }
    return sum() / count();
  }

  @override
  bool anyMatch(bool Function(int) predicate) {
    return _source.any(predicate);
  }

  @override
  bool allMatch(bool Function(int) predicate) {
    return _source.every(predicate);
  }

  @override
  bool noneMatch(bool Function(int) predicate) {
    return !_source.any(predicate);
  }

  @override
  Optional<int> findFirst() {
    return _source.isEmpty ? Optional.empty<int>() : Optional.of(_source.first);
  }

  @override
  Optional<int> findAny() {
    return findFirst(); // In sequential context, same as findFirst
  }

  @override
  DoubleStream asDoubleStream() {
    return mapToDouble((n) => n.toDouble());
  }

  @override
  List<int> collect() {
    return _source.toList();
  }
}