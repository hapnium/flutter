import 'dart:io' as io;

import '../utils/http_headers.dart';

/// {@template io_http_headers}
/// A wrapper for [io.HttpHeaders] that implements the [HttpHeaders] interface.
///
/// This class adapts the `dart:io` [io.HttpHeaders] to the Zap HTTP headers
/// interface, allowing platform-specific header handling while maintaining
/// a consistent API across platforms.
///
/// ## Features
/// - Full delegation to `dart:io` [io.HttpHeaders]
/// - Support for all standard HTTP header operations
/// - Case-insensitive header name handling
///
/// ## Example
/// ```dart
/// final ioHeaders = io.HttpResponse.headers;
/// final zapHeaders = IoHttpHeaders(headers: ioHeaders);
/// print(zapHeaders.value('content-type'));
/// ```
/// {@endtemplate}
class IoHttpHeaders implements HttpHeaders {
  /// The wrapped [io.HttpHeaders].
  final io.HttpHeaders _headers;

  /// Creates an [IoHttpHeaders] instance wrapping the given [io.HttpHeaders].
  ///
  /// ## Parameters
  /// - [headers]: The `dart:io` HTTP headers to wrap.
  ///
  /// ## Example
  /// ```dart
  /// final wrapped = IoHttpHeaders(headers: ioRequest.headers);
  /// ```
  /// {@macro io_http_headers}
  IoHttpHeaders({required io.HttpHeaders headers}) : _headers = headers;

  /// Whether chunked transfer encoding is enabled.
  ///
  /// Reflects the `Transfer-Encoding: chunked` header value.
  @override
  bool get chunkedTransferEncoding => _headers.chunkedTransferEncoding;

  /// The content length of the response body.
  ///
  /// Returns `-1` if the content length is not known.
  @override
  int get contentLength => _headers.contentLength;

  /// The date specified by the `Date` header, if any.
  @override
  DateTime? get date => _headers.date;

  /// The date and time specified by the `Expires` header, if any.
  @override
  DateTime? get expires => _headers.expires;

  /// The value of the `Host` header, if any.
  @override
  String? get host => _headers.host;

  /// The date and time specified by the `If-Modified-Since` header, if any.
  @override
  DateTime? get ifModifiedSince => _headers.ifModifiedSince;

  /// Whether the connection is persistent (keep-alive).
  @override
  bool get persistentConnection => _headers.persistentConnection;

  /// The port part of the `Host` header, if any.
  @override
  int? get port => _headers.port;

  /// Returns the values for the header named [name].
  ///
  /// Returns `null` if there is no header with the provided name.
  ///
  /// ## Parameters
  /// - [name]: The header name to look up.
  ///
  /// ## Returns
  /// A list of header values, or `null` if the header does not exist.
  ///
  /// ## Example
  /// ```dart
  /// final acceptHeaders = headers['accept'];
  /// ```
  @override
  List<String>? operator [](String name) {
    return _headers[name];
  }

  /// Adds a header value.
  ///
  /// The header named [name] will have a string value derived from [value]
  /// added to its list of values.
  ///
  /// ## Parameters
  /// - [name]: The header name.
  /// - [value]: The header value.
  /// - [preserveHeaderCase]: If `true`, preserves the case of the header name.
  ///
  /// ## Example
  /// ```dart
  /// headers.add('X-Custom', 'value1');
  /// headers.add('X-Custom', 'value2');
  /// // Result: X-Custom: value1, value2
  /// ```
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.add(name, value, preserveHeaderCase: preserveHeaderCase);
  }

  /// Removes all headers.
  @override
  void clear() {
    _headers.clear();
  }

  /// Performs the [action] on each header.
  ///
  /// ## Parameters
  /// - [action]: A function called with each header's name and values.
  ///
  /// ## Example
  /// ```dart
  /// headers.forEach((name, values) {
  ///   print('$name: ${values.join(", ")}');
  /// });
  /// ```
  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  /// Disables folding for the header named [name].
  ///
  /// By default, multiple header values are folded into a single header line.
  /// This method prevents that behavior for the specified header.
  ///
  /// ## Parameters
  /// - [name]: The header name to disable folding for.
  ///
  /// ## Example
  /// ```dart
  /// headers.noFolding('set-cookie');
  /// ```
  @override
  void noFolding(String name) {
    _headers.noFolding(name);
  }

  /// Removes a specific value for a header name.
  ///
  /// ## Parameters
  /// - [name]: The header name.
  /// - [value]: The specific value to remove.
  ///
  /// ## Example
  /// ```dart
  /// headers.remove('X-Custom', 'old-value');
  /// ```
  @override
  void remove(String name, Object value) {
    _headers.remove(name, value);
  }

  /// Removes all values for the specified header name.
  ///
  /// ## Parameters
  /// - [name]: The header name to remove all values for.
  ///
  /// ## Example
  /// ```dart
  /// headers.removeAll('X-Custom');
  /// ```
  @override
  void removeAll(String name) {
    _headers.removeAll(name);
  }

  /// Sets the header [name] to [value].
  ///
  /// Removes all existing values for the header named [name] and
  /// then adds [value] to it.
  ///
  /// ## Parameters
  /// - [name]: The header name.
  /// - [value]: The header value.
  /// - [preserveHeaderCase]: If `true`, preserves the case of the header name.
  ///
  /// ## Example
  /// ```dart
  /// headers.set('Authorization', 'Bearer token123');
  /// ```
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.set(name, value, preserveHeaderCase: preserveHeaderCase);
  }

  /// Convenience method for the value for a single-valued header.
  ///
  /// The value must not have more than one value.
  ///
  /// ## Parameters
  /// - [name]: The header name.
  ///
  /// ## Returns
  /// The header value, or `null` if there is no header with the provided name.
  ///
  /// ## Example
  /// ```dart
  /// final contentType = headers.value('content-type');
  /// ```
  @override
  String? value(String name) {
    return _headers.value(name);
  }

  /// Sets whether chunked transfer encoding is enabled.
  @override
  set chunkedTransferEncoding(bool chunkedTransferEncoding) {
    _headers.chunkedTransferEncoding = chunkedTransferEncoding;
  }

  /// Sets the content length.
  @override
  set contentLength(int contentLength) {
    _headers.contentLength = contentLength;
  }

  /// Sets the date header.
  @override
  set date(DateTime? date) {
    _headers.date = date;
  }

  /// Sets the expires header.
  @override
  set expires(DateTime? expires) {
    _headers.expires = expires;
  }

  /// Sets the host header.
  @override
  set host(String? host) {
    _headers.host = host;
  }

  /// Sets the if-modified-since header.
  @override
  set ifModifiedSince(DateTime? ifModifiedSince) {
    _headers.ifModifiedSince = ifModifiedSince;
  }

  /// Sets whether the connection is persistent.
  @override
  set persistentConnection(bool persistentConnection) {
    _headers.persistentConnection = persistentConnection;
  }

  /// Sets the port part of the host header.
  @override
  set port(int? port) {
    _headers.port = port;
  }
}