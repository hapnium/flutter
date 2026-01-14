import 'package:hapnium/src/exceptions/hapnium_exception.dart';

import '../../../collectors/collector.dart';
import '../int/int_stream.dart';
import '../double/double_stream.dart';
import 'generic_stream.dart';
import '../../../classes/optional.dart';
import '../int/_int_stream.dart';
import '../double/_double_stream.dart';

/// Implementation of [GenericStream] that wraps an [Iterable] and provides
/// some basic stream operations.
///
/// This class is not intended to be used directly. Instead, use the factory
/// methods in [GenericStream] to create a stream.
///
/// The [GenericStream] class provides a unified API for working with
/// streams of elements. It is the base class for other stream classes, such
/// as [IntStream] and [DoubleStream].
///
/// A stream is a sequence of elements supporting aggregate operations.
/// Streams are created from various data sources, such as collections,
/// arrays, or I/O channels. They are lazily evaluated, meaning that the
/// computation is only performed when the elements of the stream are
/// consumed.
///
/// Streams are consumable, meaning that their elements can only be visited
/// once. After all elements have been consumed, the stream is considered
/// exhausted and no longer usable.
///
/// Streams are auto-closeable, meaning that they can be used as resources in
/// a [try]-[finally] statement. When a stream is closed, all of its
/// resources are released.
class StandardGenericStream<T> implements GenericStream<T> {
  final Iterable<T> _source;
  final bool _parallel;
  final List<void Function()> _closeHandlers;

  StandardGenericStream(this._source, [this._parallel = false, this._closeHandlers = const []]);

  factory StandardGenericStream.of(Iterable<T> values) {
    return StandardGenericStream(values);
  }

  factory StandardGenericStream.empty() {
    return StandardGenericStream(<T>[]);
  }

  factory StandardGenericStream.ofSingle(T value) {
    return StandardGenericStream([value]);
  }

  factory StandardGenericStream.iterate(T seed, T Function(T) f) {
    return StandardGenericStream(_IterateIterable(seed, f));
  }

  factory StandardGenericStream.generate(T Function() supplier) {
    return StandardGenericStream(_GenerateIterable(supplier));
  }

  @override
  Iterator<T> iterator() => _source.iterator;

  @override
  Iterable<T> iterable() => _source;

  @override
  bool isParallel() => _parallel;

  @override
  GenericStream<T> sequential() => _parallel ? StandardGenericStream(_source, false, _closeHandlers) : this;

  @override
  GenericStream<T> parallel() => !_parallel ? StandardGenericStream(_source, true, _closeHandlers) : this;

  @override
  GenericStream<T> unordered() => this; // For simplicity, return this

  @override
  GenericStream<T> onClose(void Function() closeHandler) {
    return StandardGenericStream(_source, _parallel, [..._closeHandlers, closeHandler]);
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
  GenericStream<T> filter(bool Function(T) predicate) {
    return StandardGenericStream(_source.where(predicate), _parallel, _closeHandlers);
  }

  @override
  GenericStream<R> map<R>(R Function(T) mapper) {
    return StandardGenericStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  IntStream mapToInt(int Function(T) mapper) {
    return StandardIntStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  DoubleStream mapToDouble(double Function(T) mapper) {
    return StandardDoubleStream(_source.map(mapper), _parallel, _closeHandlers);
  }

  @override
  GenericStream<R> flatMap<R>(GenericStream<R> Function(T) mapper) {
    return StandardGenericStream(
      _source.expand((element) => mapper(element).iterable()),
      _parallel,
      _closeHandlers,
    );
  }

  @override
  GenericStream<T> distinct() {
    return StandardGenericStream(_source.toSet(), _parallel, _closeHandlers);
  }

  @override
  GenericStream<T> sorted([int Function(T, T)? comparator]) {
    final list = _source.toList();
    if (comparator != null) {
      list.sort(comparator);
    } else {
      list.sort();
    }
    return StandardGenericStream(list, _parallel, _closeHandlers);
  }

  @override
  GenericStream<T> peek(void Function(T) action) {
    return StandardGenericStream(
      _source.map((element) {
        action(element);
        return element;
      }),
      _parallel,
      _closeHandlers,
    );
  }

  @override
  GenericStream<T> limit(int maxSize) {
    return StandardGenericStream(_source.take(maxSize), _parallel, _closeHandlers);
  }

  @override
  GenericStream<T> skip(int n) {
    return StandardGenericStream(_source.skip(n), _parallel, _closeHandlers);
  }

  @override
  GenericStream<T> takeWhile(bool Function(T) predicate) {
    return StandardGenericStream(_source.takeWhile(predicate), _parallel, _closeHandlers);
  }

  @override
  GenericStream<T> dropWhile(bool Function(T) predicate) {
    return StandardGenericStream(_source.skipWhile(predicate), _parallel, _closeHandlers);
  }

  @override
  void forEach(void Function(T) action) {
    _source.forEach(action);
  }

  @override
  void forEachOrdered(void Function(T) action) {
    _source.forEach(action); // In sequential context, same as forEach
  }

  @override
  List<T> toList() {
    return _source.toList();
  }

  @override
  Set<T> toSet() {
    return _source.toSet();
  }

  @override
  R collectFrom<A, R>(Collector<T, A, R> collector) {
    final container = collector.supplier();
    for (final element in _source) {
      collector.accumulator(container, element);
    }
    return collector.finisher(container);
  }

  @override
  T reduce(T identity, T Function(T, T) accumulator) {
    return _source.fold(identity, accumulator);
  }

  @override
  Optional<T> reduceOptional(T Function(T, T) accumulator) {
    if (_source.isEmpty) {
      return Optional.empty<T>();
    }
    return Optional.of(_source.reduce(accumulator));
  }

  @override
  Optional<T> min([int Function(T, T)? comparator]) {
    if (_source.isEmpty) {
      return Optional.empty<T>();
    }
    
    if (comparator != null) {
      return Optional.of(_source.reduce((a, b) => comparator(a, b) <= 0 ? a : b));
    } else {
      return Optional.of(_source.reduce((a, b) => (a as Comparable).compareTo(b) <= 0 ? a : b));
    }
  }

  @override
  Optional<T> max([int Function(T, T)? comparator]) {
    if (_source.isEmpty) {
      return Optional.empty<T>();
    }
    
    if (comparator != null) {
      return Optional.of(_source.reduce((a, b) => comparator(a, b) >= 0 ? a : b));
    } else {
      return Optional.of(_source.reduce((a, b) => (a as Comparable).compareTo(b) >= 0 ? a : b));
    }
  }

  @override
  int count() {
    return _source.length;
  }

  @override
  bool anyMatch(bool Function(T) predicate) {
    return _source.any(predicate);
  }

  @override
  bool allMatch(bool Function(T) predicate) {
    return _source.every(predicate);
  }

  @override
  bool noneMatch(bool Function(T) predicate) {
    return !_source.any(predicate);
  }

  @override
  Optional<T> findFirst() {
    return _source.isEmpty ? Optional.empty<T>() : Optional.of(_source.first);
  }

  @override
  Optional<T> findAny() {
    return findFirst(); // In sequential context, same as findFirst
  }

  @override
  GenericStream<T> where(bool Function(T value) predicate) {
    final it = iterator();
    if (!it.moveNext()) {
      throw HapniumException("No such element");
    }
    final result = it.current;
    if (!predicate(result)) {
      throw HapniumException("No such element");
    }
    return GenericStream.of([result]);
  }

  @override
  List<T> collect() {
    return _source.toList();
  }
}

// Helper classes for infinite streams
class _IterateIterable<T> extends Iterable<T> {
  final T _seed;
  final T Function(T) _f;

  _IterateIterable(this._seed, this._f);

  @override
  Iterator<T> get iterator => _IterateIterator(_seed, _f);
}

class _IterateIterator<T> implements Iterator<T> {
  T _current;
  final T Function(T) _f;
  bool _isFirst = true;

  _IterateIterator(T seed, this._f) : _current = seed;

  @override
  T get current => _current;

  @override
  bool moveNext() {
    if (_isFirst) {
      _isFirst = false;
      return true; // emit seed
    }
    _current = _f(_current);
    return true;
  }
}

class _GenerateIterable<T> extends Iterable<T> {
  final T Function() _supplier;

  _GenerateIterable(this._supplier);

  @override
  Iterator<T> get iterator => _GenerateIterator(_supplier);
}

class _GenerateIterator<T> implements Iterator<T> {
  final T Function() _supplier;
  late T _current;

  _GenerateIterator(this._supplier);

  @override
  T get current => _current;

  @override
  bool moveNext() {
    _current = _supplier();
    return true;
  }
}