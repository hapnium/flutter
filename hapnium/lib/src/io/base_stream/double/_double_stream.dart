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
import '../int/int_stream.dart';
import 'double_stream.dart';
import '../int/_int_stream.dart';

/// Private implementation of [DoubleStream] that wraps an [Iterable] of doubles.
///
/// This implementation provides a way to create a [DoubleStream] from an
/// existing [Iterable] of doubles, and also provides methods for performing
/// operations on the stream.
///
/// [StandardDoubleStream] is designed to be used as a private
/// implementation of [DoubleStream], and should not be used directly.
///
/// See [DoubleStream] for more information on using streams of doubles.
class StandardDoubleStream implements DoubleStream {
  final Iterable<double> _source;
  final bool _parallel;
  final List<void Function()> _closeHandlers;

  StandardDoubleStream(this._source, [this._parallel = false, this._closeHandlers = const []]);

  factory StandardDoubleStream.of(Iterable<double> values) {
    return StandardDoubleStream(values);
  }

  factory StandardDoubleStream.empty() {
    return StandardDoubleStream(<double>[]);
  }

  @override
  Iterator<double> iterator() => _source.iterator;

  @override
  Iterable<double> iterable() => _source;

  @override
  bool isParallel() => _parallel;

  @override
  DoubleStream sequential() => _parallel ? StandardDoubleStream(_source, false, _closeHandlers) : this;

  @override
  DoubleStream parallel() => !_parallel ? StandardDoubleStream(_source, true, _closeHandlers) : this;

  @override
  DoubleStream unordered() => this; // For simplicity, return this

  @override
  DoubleStream onClose(void Function() closeHandler) {
    return StandardDoubleStream(_source, _parallel, [..._closeHandlers, closeHandler]);
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
  DoubleStream filter(bool Function(double) predicate) {
    return StandardDoubleStream(_source.where(predicate), _parallel, _closeHandlers);
  }

  @override
  DoubleStream map(double Function(double) mapper) {
    return StandardDoubleStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  IntStream mapToInt(int Function(double) mapper) {
    return StandardIntStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  DoubleStream flatMap(DoubleStream Function(double) mapper) {
    return StandardDoubleStream(
      _source.expand((element) => mapper(element).iterable()),
      _parallel,
      _closeHandlers,
    );
  }

  @override
  DoubleStream distinct() {
    return StandardDoubleStream(_source.toSet(), _parallel, _closeHandlers);
  }

  @override
  DoubleStream sorted() {
    final list = _source.toList()..sort();
    return StandardDoubleStream(list, _parallel, _closeHandlers);
  }

  @override
  DoubleStream peek(void Function(double) action) {
    return StandardDoubleStream(
      _source.map((element) {
        action(element);
        return element;
      }),
      _parallel,
      _closeHandlers,
    );
  }

  @override
  DoubleStream limit(int maxSize) {
    return StandardDoubleStream(_source.take(maxSize), _parallel, _closeHandlers);
  }

  @override
  DoubleStream skip(int n) {
    return StandardDoubleStream(_source.skip(n), _parallel, _closeHandlers);
  }

  @override
  DoubleStream takeWhile(bool Function(double) predicate) {
    return StandardDoubleStream(_source.takeWhile(predicate), _parallel, _closeHandlers);
  }

  @override
  DoubleStream dropWhile(bool Function(double) predicate) {
    return StandardDoubleStream(_source.skipWhile(predicate), _parallel, _closeHandlers);
  }

  @override
  void forEach(void Function(double) action) {
    _source.forEach(action);
  }

  @override
  void forEachOrdered(void Function(double) action) {
    _source.forEach(action); // In sequential context, same as forEach
  }

  @override
  List<double> toList() {
    return _source.toList();
  }

  @override
  double reduce(double identity, double Function(double, double) op) {
    return _source.fold(identity, op);
  }

  @override
  Optional<double> reduceOptional(double Function(double, double) op) {
    if (_source.isEmpty) {
      return Optional.empty<double>();
    }
    return Optional.of(_source.reduce(op));
  }

  @override
  double sum() {
    return _source.fold(0.0, (a, b) => a + b);
  }

  @override
  Optional<double> min() {
    if (_source.isEmpty) {
      return Optional.empty<double>();
    }
    return Optional.of(_source.reduce((a, b) => a < b ? a : b));
  }

  @override
  Optional<double> max() {
    if (_source.isEmpty) {
      return Optional.empty<double>();
    }
    return Optional.of(_source.reduce((a, b) => a > b ? a : b));
  }

  @override
  int count() {
    return _source.length;
  }

  @override
  Optional<double> average() {
    if (_source.isEmpty) {
      return Optional.empty<double>();
    }
    return Optional.of(sum() / count());
  }

  @override
  bool anyMatch(bool Function(double) predicate) {
    return _source.any(predicate);
  }

  @override
  bool allMatch(bool Function(double) predicate) {
    return _source.every(predicate);
  }

  @override
  bool noneMatch(bool Function(double) predicate) {
    return !_source.any(predicate);
  }

  @override
  Optional<double> findFirst() {
    return _source.isEmpty ? Optional.empty<double>() : Optional.of(_source.first);
  }

  @override
  Optional<double> findAny() {
    return findFirst(); // In sequential context, same as findFirst
  }

  @override
  List<double> collect() {
    return _source.toList();
  }
}