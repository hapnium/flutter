import 'dart:async';
import 'dart:io' as io;

import '../../definitions.dart';
import '../interface/http_client_response.dart';
import '../utils/http_headers.dart';
import '../interface/redirect_info.dart';
import 'io_http_headers.dart';
import 'io_redirect_info.dart';

/// {@template io_http_response}
/// A `dart:io` implementation of [HttpClientResponse].
///
/// This class wraps [io.HttpClientResponse] to implement the [HttpClientResponse]
/// interface, providing platform-specific HTTP response handling for mobile and
/// desktop platforms.
///
/// ## Features
/// - Full delegation to `dart:io` [io.HttpClientResponse]
/// - Stream operations for processing response body chunks
/// - Redirect information access
/// - Header access via [IoHttpHeaders]
///
/// ## Example
/// ```dart
/// final ioResponse = await httpClient.getUrl(uri);
/// final response = await ioResponse.close();
/// final wrappedResponse = IOHttpResponse(response: response);
/// final body = await wrappedResponse.bodyBytes.toBytes();
/// ```
/// {@endtemplate}
class IOHttpResponse implements HttpClientResponse {
  /// The wrapped [io.HttpClientResponse].
  final io.HttpClientResponse _response;

  /// Creates an [IOHttpResponse] wrapping the given [io.HttpClientResponse].
  ///
  /// ## Parameters
  /// - [response]: The `dart:io` HTTP response to wrap.
  ///
  /// ## Example
  /// ```dart
  /// final wrapped = IOHttpResponse(response: ioResponse);
  /// ```
  /// {@macro io_http_response}
  IOHttpResponse({required io.HttpClientResponse response}) : _response = response;

  /// Checks whether any element satisfies the [test].
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  ///
  /// ## Returns
  /// A [Future<bool>] that completes with `true` if any element passes the test.
  @override
  Future<bool> any(bool Function(BodyBytes element) test) {
    return _response.any(test);
  }

  /// Returns a multi-subscription stream.
  ///
  /// ## Parameters
  /// - [onListen]: Called when the first subscription is added.
  /// - [onCancel]: Called when the last subscription is cancelled.
  ///
  /// ## Returns
  /// A broadcast stream that can be listened to multiple times.
  @override
  BodyByteStream asBroadcastStream({
    void Function(StreamSubscription<BodyBytes> subscription)? onListen,
    void Function(StreamSubscription<BodyBytes> subscription)? onCancel,
  }) {
    return _response.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  /// Transforms each element of this stream using [convert].
  ///
  /// ## Parameters
  /// - [convert]: A function that converts each element asynchronously.
  ///
  /// ## Returns
  /// A new stream with the transformed elements.
  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(BodyBytes event) convert) {
    return _response.asyncExpand(convert);
  }

  /// Transforms each element of this stream using [convert].
  ///
  /// ## Parameters
  /// - [convert]: A function that converts each element.
  ///
  /// ## Returns
  /// A new stream with the transformed elements.
  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(BodyBytes event) convert) {
    return _response.asyncMap(convert);
  }

  /// Casts the stream elements to type [R].
  ///
  /// ## Returns
  /// A stream of type [R].
  @override
  Stream<R> cast<R>() {
    return _response.cast<R>();
  }

  /// Checks whether [needle] is contained in the stream.
  ///
  /// ## Parameters
  /// - [needle]: The element to search for.
  ///
  /// ## Returns
  /// A [Future<bool>] that completes with `true` if the element is found.
  @override
  Future<bool> contains(Object? needle) {
    return _response.contains(needle);
  }

  /// The content length of the response body.
  ///
  /// Returns `-1` if the content length is not known.
  @override
  int get contentLength => _response.contentLength;

  /// Returns a new stream with duplicate elements removed.
  ///
  /// ## Parameters
  /// - [equals]: Optional custom equality function.
  ///
  /// ## Returns
  /// A stream with only distinct elements.
  @override
  BodyByteStream distinct([bool Function(BodyBytes previous, BodyBytes next)? equals]) {
    return _response.distinct(equals);
  }

  /// Drains the stream, optionally returning [futureValue] when empty.
  ///
  /// ## Parameters
  /// - [futureValue]: The value to return if the stream is empty.
  ///
  /// ## Returns
  /// A [Future] that completes when the stream is fully drained.
  @override
  Future<E> drain<E>([E? futureValue]) {
    return _response.drain(futureValue);
  }

  /// Returns the element at [index].
  ///
  /// ## Parameters
  /// - [index]: The index of the element to return.
  ///
  /// ## Returns
  /// A [Future<BodyBytes>] with the element at the given index.
  @override
  Future<BodyBytes> elementAt(int index) {
    return _response.elementAt(index);
  }

  /// Checks whether every element satisfies [test].
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  ///
  /// ## Returns
  /// A [Future<bool>] that completes with `true` if all elements pass the test.
  @override
  Future<bool> every(bool Function(BodyBytes element) test) {
    return _response.every(test);
  }

  /// Expands each element to a number of elements.
  ///
  /// ## Parameters
  /// - [convert]: A function that returns an iterable for each element.
  ///
  /// ## Returns
  /// A new stream with the expanded elements.
  @override
  Stream<S> expand<S>(Iterable<S> Function(BodyBytes element) convert) {
    return _response.expand(convert);
  }

  /// The first element of the stream.
  @override
  Future<BodyBytes> get first => _response.first;

  /// Returns the first element that satisfies [test].
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  /// - [orElse]: Optional function to return a default value if no element is found.
  ///
  /// ## Returns
  /// A [Future<BodyBytes>] with the first matching element.
  @override
  Future<BodyBytes> firstWhere(bool Function(BodyBytes element) test, {BodyBytes Function()? orElse}) {
    return _response.firstWhere(test, orElse: orElse);
  }

  /// Reduces the stream to a single value using [combine].
  ///
  /// ## Parameters
  /// - [initialValue]: The initial value for the accumulator.
  /// - [combine]: A function that combines the accumulator with each element.
  ///
  /// ## Returns
  /// A [Future<S>] with the final accumulated value.
  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, BodyBytes element) combine) {
    return _response.fold(initialValue, combine);
  }

  /// Executes [action] on each element of the stream.
  ///
  /// ## Parameters
  /// - [action]: A function to execute on each element.
  @override
  Future<void> forEach(void Function(BodyBytes element) action) {
    return _response.forEach(action);
  }

  /// Handles errors in the stream using [onError].
  ///
  /// ## Parameters
  /// - [onError]: A function to handle errors.
  /// - [test]: Optional function to filter which errors to handle.
  @override
  BodyByteStream handleError(Function onError, {bool Function(dynamic error)? test}) {
    return _response.handleError(onError, test: test);
  }

  /// The response headers.
  ///
  /// Wrapped in [IoHttpHeaders] for platform compatibility.
  @override
  HttpHeaders get headers => IoHttpHeaders(headers: _response.headers);

  /// Whether this is a broadcast stream.
  @override
  bool get isBroadcast => _response.isBroadcast;

  /// Whether the stream is empty.
  @override
  Future<bool> get isEmpty => _response.isEmpty;

  /// Whether this response is a redirect.
  @override
  bool get isRedirect => _response.isRedirect;

  /// Joins all elements of the stream into a string.
  ///
  /// ## Parameters
  /// - [separator]: The separator between elements.
  ///
  /// ## Returns
  /// A [Future<String>] with all elements joined.
  @override
  Future<String> join([String separator = ""]) {
    return _response.join(separator);
  }

  /// The last element of the stream.
  @override
  Future<BodyBytes> get last => _response.last;

  /// Returns the last element that satisfies [test].
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  /// - [orElse]: Optional function to return a default value if no element is found.
  @override
  Future<BodyBytes> lastWhere(bool Function(BodyBytes element) test,
      {BodyBytes Function()? orElse}) {
    return _response.lastWhere(test, orElse: orElse);
  }

  /// The number of elements in the stream.
  @override
  Future<int> get length => _response.length;

  /// Adds a listener to the stream.
  ///
  /// ## Parameters
  /// - [onData]: Called for each data event.
  /// - [onError]: Called for error events.
  /// - [onDone]: Called when the stream closes.
  /// - [cancelOnError]: If `true`, cancels subscription on first error.
  @override
  StreamSubscription<BodyBytes> listen(void Function(BodyBytes event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _response.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Transforms each element using [convert].
  ///
  /// ## Parameters
  /// - [convert]: A function that transforms each element.
  ///
  /// ## Returns
  /// A new stream with the transformed elements.
  @override
  Stream<S> map<S>(S Function(BodyBytes event) convert) {
    return _response.map(convert);
  }

  /// Whether the connection is persistent (keep-alive).
  @override
  bool get persistentConnection => _response.persistentConnection;

  /// Pipes the stream into [streamConsumer].
  ///
  /// ## Parameters
  /// - [streamConsumer]: The consumer to pipe the stream into.
  @override
  Future pipe(StreamConsumer<BodyBytes> streamConsumer) {
    return _response.pipe(streamConsumer);
  }

  /// The reason phrase associated with the status code.
  @override
  String get reasonPhrase => _response.reasonPhrase;

  /// Redirects this connection to a new URL.
  ///
  /// ## Parameters
  /// - [method]: The HTTP method for the redirect.
  /// - [url]: The target URL.
  /// - [followLoops]: Whether to follow redirects even if already visited.
  ///
  /// ## Returns
  /// A new [HttpClientResponse] from the redirected URL.
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) async {
    final data = await _response.redirect(method, url, followLoops);
    return IOHttpResponse(response: data);
  }

  /// The list of redirects this connection has been through.
  @override
  List<RedirectInfo> get redirects => _response.redirects
      .map((item) => IoRedirectInfo(redirectInfo: item))
      .toList();

  /// Reduces the stream to a single value using [combine].
  ///
  /// ## Parameters
  /// - [combine]: A function that combines elements.
  ///
  /// ## Returns
  /// A [Future<BodyBytes>] with the reduced value.
  @override
  Future<BodyBytes> reduce(BodyBytes Function(BodyBytes previous, BodyBytes element) combine) {
    return _response.reduce(combine);
  }

  /// The single element of the stream.
  @override
  Future<BodyBytes> get single => _response.single;

  /// Returns the single element that satisfies [test].
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  /// - [orElse]: Optional function to return a default value if no element is found.
  @override
  Future<BodyBytes> singleWhere(bool Function(BodyBytes element) test, {BodyBytes Function()? orElse}) {
    return _response.singleWhere(test, orElse: orElse);
  }

  /// Returns a sub-stream starting from [count].
  ///
  /// ## Parameters
  /// - [count]: The number of elements to skip.
  @override
  BodyByteStream skip(int count) {
    return _response.skip(count);
  }

  /// Skips elements while [test] returns `true`.
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  @override
  BodyByteStream skipWhile(bool Function(BodyBytes element) test) {
    return _response.skipWhile(test);
  }

  /// The HTTP status code.
  @override
  int get statusCode => _response.statusCode;

  /// Returns the first [count] elements.
  ///
  /// ## Parameters
  /// - [count]: The number of elements to take.
  @override
  BodyByteStream take(int count) {
    return _response.take(count);
  }

  /// Takes elements while [test] returns `true`.
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  @override
  BodyByteStream takeWhile(bool Function(BodyBytes element) test) {
    return _response.takeWhile(test);
  }

  /// Applies a timeout to the stream.
  ///
  /// ## Parameters
  /// - [timeLimit]: The maximum duration to wait for elements.
  /// - [onTimeout]: Called when the timeout expires.
  @override
  BodyByteStream timeout(Duration timeLimit,
      {void Function(EventSink<BodyBytes> sink)? onTimeout}) {
    return _response.timeout(timeLimit, onTimeout: onTimeout);
  }

  /// Collects all elements into a list.
  ///
  /// ## Returns
  /// A [Future<List<BodyBytes>>] with all elements.
  @override
  Future<List<BodyBytes>> toList() {
    return _response.toList();
  }

  /// Collects all elements into a set.
  ///
  /// ## Returns
  /// A [Future<Set<BodyBytes>>] with all unique elements.
  @override
  Future<Set<BodyBytes>> toSet() {
    return _response.toSet();
  }

  /// Transforms the stream using [streamTransformer].
  ///
  /// ## Parameters
  /// - [streamTransformer]: The transformer to apply.
  @override
  Stream<S> transform<S>(StreamTransformer<BodyBytes, S> streamTransformer) {
    return _response.transform(streamTransformer);
  }

  /// Returns a new stream with only the elements that satisfy [test].
  ///
  /// ## Parameters
  /// - [test]: A function to test each element.
  @override
  BodyByteStream where(bool Function(BodyBytes event) test) {
    return _response.where(test);
  }
}