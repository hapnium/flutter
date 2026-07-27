// ignore_for_file: unintended_html_in_doc_comment

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import "../../definitions.dart";
import '../client/zap_client.dart' show ResponseInterceptor;
import '../multipart/form_data.dart';

/// {@template request}
/// Represents a network request sent through the Zap client.
///
/// This class holds all configuration and data associated with an HTTP request,
/// such as method, headers, body, redirect behavior, files, and more. It also
/// supports response decoding and intercepting for flexible response handling.
///
/// ## Features
/// - Immutable request configuration with copy-with support
/// - Generic type parameter for response body decoding
/// - Support for file uploads via [FormData]
/// - Configurable redirect behavior
/// - Response interceptor support
///
/// ## Example
/// ```dart
/// final request = Request(
///   url: Uri.parse("https://api.example.com/v1/data"),
///   method: "GET",
///   headers: {'Content-Type': 'application/json'},
/// );
/// ```
///
/// ## Edge cases
/// - If [bodyBytes] is `null`, an empty stream is used.
/// - If [followRedirects] is `true`, [maxRedirects] must be > 0.
/// - Headers are copied to prevent external mutation.
/// 
/// {@endtemplate}
class Request<T> {
  /// The HTTP headers attached to this request.
  ///
  /// Headers are case-insensitive. Common headers include:
  /// - `'Content-Type'`: The MIME type of the request body.
  /// - `'Authorization'`: Authentication credentials.
  /// - `'Accept'`: The accepted response content types.
  ///
  /// ## Example
  /// ```dart
  /// final request = Request(
  ///   url: Uri.parse('https://api.example.com'),
  ///   method: 'GET',
  ///   headers: {
  ///     'Content-Type': 'application/json',
  ///     'Authorization': 'Bearer token123',
  ///   },
  /// );
  /// ```
  final Headers headers;

  /// The URI (Uniform Resource Identifier) to which the request is sent.
  ///
  /// This can be an absolute URL or a relative path (resolved against
  /// the base URL if configured).
  ///
  /// ## Example
  /// ```dart
  /// final request = Request(
  ///   url: Uri.parse("https://api.example.com/v1/data"),
  ///   method: "GET",
  ///   headers: {},
  /// );
  /// ```
  final Uri url;

  /// A custom decoder to convert the raw response body into a typed object [T].
  ///
  /// This allows structured deserialization of the response into models.
  /// If `null`, the response body is returned as a raw `Map` or `String`.
  ///
  /// ## Example
  /// ```dart
  /// final request = Request<User>(
  ///   url: Uri.parse('https://api.example.com/user'),
  ///   method: 'GET',
  ///   headers: {},
  ///   decoder: (data) => User.fromJson(data as Map<String, dynamic>),
  /// );
  /// ```
  final ResponseDecoder<T>? decoder;

  /// An optional interceptor to inspect or modify the response before it's returned.
  ///
  /// This is useful for adding logging, error handling, or transforming the response.
  /// The interceptor receives the raw [HttpClientResponse] and can return a
  /// custom [Response] or `null` to use the default processing.
  ///
  /// ## Example
  /// ```dart
  /// final request = Request<String>(
  ///   url: Uri.parse('https://api.example.com/data'),
  ///   method: 'GET',
  ///   headers: {},
  ///   responseInterceptor: (request, targetType, response) async {
  ///     // Custom processing
  ///     return null; // Use default processing
  ///   },
  /// );
  /// ```
  final ResponseInterceptor<T>? responseInterceptor;

  /// The HTTP method of the request.
  ///
  /// Common methods include: `'GET'`, `'POST'`, `'PUT'`, `'DELETE'`, `'PATCH'`.
  /// The method is case-sensitive and should be uppercase.
  ///
  /// ## Example
  /// ```dart
  /// final request = Request(
  ///   url: Uri.parse('https://api.example.com/users'),
  ///   method: 'POST',
  ///   headers: {},
  /// );
  /// ```
  final String method;

  /// The length in bytes of the request body, if known.
  ///
  /// This is often used for setting the `Content-Length` header explicitly.
  /// If `null`, the content length is calculated from [bodyBytes].
  ///
  /// ## Edge cases
  /// - Set to `-1` or `null` for chunked transfer encoding.
  final int? contentLength;

  /// The body of the request represented as a byte stream.
  ///
  /// Useful for sending raw data, files, or streaming content.
  /// If `null`, an empty stream is used.
  ///
  /// ## Example
  /// ```dart
  /// final bodyStream = Stream.fromIterable([utf8.encode('Hello')]);
  /// final request = Request(
  ///   url: Uri.parse('https://api.example.com/echo'),
  ///   method: 'POST',
  ///   headers: {},
  ///   bodyBytes: bodyStream,
  /// );
  /// ```
  final BodyByteStream bodyBytes;

  /// Whether this request should follow HTTP redirects automatically.
  ///
  /// If `true`, the client will attempt to follow redirects like 301, 302.
  /// Defaults to `true`.
  ///
  /// ## Example
  /// ```dart
  /// final request = Request(
  ///   url: Uri.parse('https://api.example.com'),
  ///   method: 'GET',
  ///   headers: {},
  ///   followRedirects: false,
  /// );
  /// ```
  final bool followRedirects;

  /// The maximum number of redirects the client should follow, if [followRedirects] is `true`.
  ///
  /// Must be greater than zero if redirects are enabled. Defaults to `4`.
  ///
  /// ## Edge cases
  /// - If the redirect limit is exceeded, a [ZapException] is thrown.
  final int maxRedirects;

  /// Whether the client should keep the TCP connection alive for reuse.
  ///
  /// This is useful for performance when making multiple requests to the same host.
  /// Defaults to `true`.
  final bool persistentConnection;

  /// Optional form data (e.g., files) to be included in the request body.
  ///
  /// Used for `multipart/form-data` uploads. If provided, the request
  /// will be sent as multipart form data.
  ///
  /// ## Example
  /// ```dart
  /// final formData = FormData();
  /// formData.fields.add(MapEntry('name', 'John'));
  /// formData.files.add(MapEntry('avatar', await MultipartFile.fromFile('/path/to/file.jpg', filename: 'avatar.jpg')));
  /// final request = Request(
  ///   url: Uri.parse('https://api.example.com/upload'),
  ///   method: 'POST',
  ///   headers: {},
  ///   files: formData,
  /// );
  /// ```
  final FormData? files;

  /// Internal constructor for initializing a [Request].
  ///
  /// Use the factory constructor for external instantiation.
  /// 
  /// {@macro request}
  const Request._({
    required this.method,
    required this.bodyBytes,
    required this.url,
    required this.headers,
    required this.contentLength,
    required this.followRedirects,
    required this.maxRedirects,
    required this.files,
    required this.persistentConnection,
    required this.decoder,
    this.responseInterceptor,
  });

  /// Creates a new instance of [Request].
  ///
  /// This factory constructor simplifies request creation with default behavior and
  /// allows configuration of redirection, persistent connections, file uploads, etc.
  ///
  /// ## Parameters
  /// - [url]: The destination URI of the request.
  /// - [method]: The HTTP method to use (e.g., `'GET'`, `'POST'`).
  /// - [headers]: HTTP headers to send with the request.
  /// - [bodyBytes]: The request body as a byte stream (optional).
  /// - [followRedirects]: Whether to automatically follow redirects (default: `true`).
  /// - [maxRedirects]: The maximum redirects to follow (default: `4`).
  /// - [contentLength]: Explicit content length for the request body (optional).
  /// - [files]: Optional files to upload with the request (optional).
  /// - [persistentConnection]: Whether to reuse TCP connection (default: `true`).
  /// - [decoder]: A custom response decoder to parse the response into [T].
  /// - [responseInterceptor]: Optional interceptor to modify/inspect the response.
  /// 
  /// ## Example
  /// ```dart
  /// final request = Request(
  ///   url: Uri.parse("https://api.example.com/v1/data"),
  ///   method: "GET",
  ///   headers: {'Content-Type': 'application/json'},
  /// );
  /// ```
  /// 
  /// {@macro request}
  factory Request({
    required Uri url,
    required String method,
    required Map<String, String> headers,
    BodyByteStream? bodyBytes,
    bool followRedirects = true,
    int maxRedirects = 4,
    int? contentLength,
    FormData? files,
    bool persistentConnection = true,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) {
    if (followRedirects) {
      assert(maxRedirects > 0, "maxRedirects must be > 0 when followRedirects is true.");
    }
    return Request._(
      url: url,
      method: method,
      bodyBytes: bodyBytes ??= <int>[].toStream(),
      headers: Map.from(headers),
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      contentLength: contentLength,
      files: files,
      persistentConnection: persistentConnection,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
    );
  }

  /// Creates a new [Request] from an existing [Request] of any generic type.
  ///
  /// This accepts a loosely typed request (e.g., `Request<dynamic>` or `Request<Object?>`) 
  /// and ignores its decoders/interceptors to the new type [T]. It also creates 
  /// a decoupled copy of the headers map to prevent unintended mutation.
  ///
  /// ## Example
  /// ```dart
  /// final genericReq = Request<Object?>(url: Uri.parse('...'), method: 'GET', headers: {});
  /// 
  /// // Perfectly valid: Upgrades the generic request to a strictly typed one
  /// final userReq = Request<User>.from(genericReq); 
  /// ```
  /// 
  /// {@macro request}
  factory Request.from(Request<dynamic> request, {
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) {
    return Request._(
      url: request.url,
      method: request.method,
      headers: Map.from(request.headers),
      bodyBytes: request.bodyBytes,
      followRedirects: request.followRedirects,
      maxRedirects: request.maxRedirects,
      contentLength: request.contentLength,
      files: request.files,
      persistentConnection: request.persistentConnection,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
    );
  }

  /// Creates a copy of this [Request] with modified fields.
  ///
  /// You can override any field. If [appendHeader] is `true`, the new [headers]
  /// will be merged with the existing headers.
  ///
  /// ## Parameters
  /// - [url]: Override for the request URL.
  /// - [method]: Override for the HTTP method.
  /// - [headers]: New headers to replace or merge.
  /// - [bodyBytes]: New byte stream for the request body.
  /// - [followRedirects]: Override for redirect behavior.
  /// - [maxRedirects]: Override for max redirects.
  /// - [contentLength]: Override for body content length.
  /// - [files]: Override for file data.
  /// - [persistentConnection]: Override for connection behavior.
  /// - [decoder]: Override for response decoder.
  /// - [responseInterceptor]: Override for response interceptor.
  /// - [appendHeader]: If `true`, new headers are merged into the original headers.
  ///
  /// ## Returns
  /// A new [Request] with the specified modifications.
  ///
  /// ## Example
  /// ```dart
  /// final original = Request(
  ///   url: Uri.parse('https://api.example.com/users'),
  ///   method: 'GET',
  ///   headers: {'Accept': 'application/json'},
  /// );
  /// final modified = original.copyWith(
  ///   headers: {'Authorization': 'Bearer token'},
  /// );
  /// ```
  Request<T> copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    BodyByteStream? bodyBytes,
    bool? followRedirects,
    int? maxRedirects,
    int? contentLength,
    FormData? files,
    bool? persistentConnection,
    ResponseDecoder<T>? decoder,
    bool appendHeader = true,
    ResponseInterceptor<T>? responseInterceptor,
  }) {
    // Merge headers if required
    if (appendHeader && headers != null) {
      headers.addAll(this.headers);
    }

    return Request<T>._(
      url: url ?? this.url,
      method: method ?? this.method,
      bodyBytes: bodyBytes ?? this.bodyBytes,
      headers: headers == null ? this.headers : Map.from(headers),
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      contentLength: contentLength ?? this.contentLength,
      files: files ?? this.files,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      decoder: decoder ?? this.decoder,
      responseInterceptor: responseInterceptor ?? this.responseInterceptor,
    );
  }

  /// Converts this request to a JSON-compatible map.
  ///
  /// Useful for logging or debugging. Note that some fields (like streams)
  /// cannot be properly serialized.
  ///
  /// ## Returns
  /// A [Map<String, dynamic>] containing request metadata.
  Map<String, dynamic> toJson() {
    return {
      'url': url.toString(),
      'method': method,
      'bodyBytes': bodyBytes,
      'headers': headers,
      'followRedirects': followRedirects,
      'maxRedirects': maxRedirects,
      'contentLength': contentLength,
      'files': files,
      'persistentConnection': persistentConnection,
      'decoder': decoder,
      'responseInterceptor': responseInterceptor,
    };
  }
}

/// Extension on BodyBytes to convert it to a BodyByteStream.
///
/// This provides a convenient way to wrap a byte list as a broadcast stream
/// for use in request bodies.
///
/// ## Example
/// ```dart
/// final bodyBytes = utf8.encode('{"name": "John"}');
/// final stream = bodyBytes.toStream();
/// final request = Request(
///   url: Uri.parse('https://api.example.com/users'),
///   method: 'POST',
///   headers: {},
///   bodyBytes: stream,
/// );
/// ```
extension StreamExt on BodyBytes {
  /// Converts this byte list to a broadcast stream.
  ///
  /// The resulting stream emits the entire byte list as a single chunk.
  BodyByteStream toStream() => Stream.value(this).asBroadcastStream();
}

/// Extension on BodyByteStream for byte and string utilities.
///
/// Provides methods to collect the stream into bytes or decode it as a string.
///
/// ## Example
/// ```dart
/// final bytes = await response.bodyBytes.toBytes();
/// final string = await response.bodyBytes.bytesToString();
/// ```
extension BodyByteStreamStream on BodyByteStream {
  /// Collects all emitted chunks into a single byte array.
  ///
  /// This consumes the stream and returns the complete byte content.
  ///
  /// ## Returns
  /// A [Future<Uint8List>] containing all bytes from the stream.
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await stream.toBytes();
  /// print('Received ${bytes.length} bytes');
  /// ```
  Future<Uint8List> toBytes() {
    var completer = Completer<Uint8List>();
    var sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)),
    );
    listen(sink.add, onError: completer.completeError, onDone: sink.close, cancelOnError: true);
    return completer.future;
  }

  /// Converts the byte stream to a string using UTF-8 or the given [encoding].
  ///
  /// ## Parameters
  /// - [encoding]: The character encoding to use (default: UTF-8).
  ///
  /// ## Returns
  /// A [Future<String>] containing the decoded string.
  ///
  /// ## Example
  /// ```dart
  /// final text = await stream.bytesToString();
  /// print(text);
  /// ```
  Future<String> bytesToString([Encoding encoding = utf8]) => encoding.decodeStream(this);
}