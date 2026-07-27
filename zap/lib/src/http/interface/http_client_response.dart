import '../../definitions.dart';
import '../utils/http_headers.dart';
import 'redirect_info.dart';

/// {@template http_client_response}
/// An interface representing a response from an HTTP server.
///
/// This interface extends [BodyByteStream] to provide a stream of bytes
/// which is the response body, along with metadata about the response
/// such as status code, headers, and redirect information.
///
/// Implementations should provide platform-specific behavior for
/// response handling, such as `dart:io`'s [HttpClientResponse] or
/// a web-based equivalent.
///
/// ## Example
/// ```dart
/// Future<void> processResponse(HttpClientResponse response) async {
///   print('Status: ${response.statusCode}');
///   print('Headers: ${response.headers}');
///   await for (final chunk in response) {
///     // Process response body chunks
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class HttpClientResponse implements BodyByteStream {
  /// Returns the status code.
  ///
  /// The status code must be set before the body is written
  /// to. Setting the status code after writing to the body will throw
  /// a `StateError`.
  ///
  /// ## Example
  /// ```dart
  /// if (response.statusCode == 200) {
  ///   print('Success');
  /// }
  /// ```
  int get statusCode;

  /// Returns the reason phrase associated with the status code.
  ///
  /// The reason phrase must be set before the body is written
  /// to. Setting the reason phrase after writing to the body will throw
  /// a `StateError`.
  ///
  /// ## Example
  /// ```dart
  /// print(response.reasonPhrase); // 'OK'
  /// ```
  String get reasonPhrase;

  /// Returns the content length of the response body. Returns -1 if the size of
  /// the response body is not known in advance.
  ///
  /// If the content length needs to be set, it must be set before the
  /// body is written to. Setting the content length after writing to the body
  /// will throw a `StateError`.
  ///
  /// ## Edge cases
  /// - Returns `-1` when the content length is unknown (e.g., chunked transfer encoding).
  int get contentLength;

  /// Gets the persistent connection state returned by the server.
  ///
  /// If the persistent connection state needs to be set, it must be
  /// set before the body is written to. Setting the persistent connection state
  /// after writing to the body will throw a `StateError`.
  ///
  /// ## Example
  /// ```dart
  /// if (response.persistentConnection) {
  ///   print('Connection will be kept alive');
  /// }
  /// ```
  bool get persistentConnection;

  /// Returns whether the status code is one of the normal redirect
  /// codes [HttpStatus.movedPermanently], [HttpStatus.found],
  /// [HttpStatus.movedTemporarily], [HttpStatus.seeOther] and
  /// [HttpStatus.temporaryRedirect].
  ///
  /// ## Example
  /// ```dart
  /// if (response.isRedirect) {
  ///   final newResponse = await response.redirect();
  /// }
  /// ```
  bool get isRedirect;

  /// Returns the series of redirects this connection has been through. The
  /// list will be empty if no redirects were followed. [redirects] will be
  /// updated both in the case of an automatic and a manual redirect.
  ///
  /// ## Example
  /// ```dart
  /// for (final redirect in response.redirects) {
  ///   print('${redirect.statusCode} -> ${redirect.location}');
  /// }
  /// ```
  List<RedirectInfo> get redirects;

  /// Redirects this connection to a new URL.
  ///
  /// The default value for [method] is the method for the current request.
  /// The default value for [url] is the value of the `Location` header of
  /// the current response. All body data must have been read from the
  /// current response before calling [redirect].
  ///
  /// All headers added to the request will be added to the redirection
  /// request. However, any body sent with the request will not be
  /// part of the redirection request.
  ///
  /// ## Parameters
  /// - [method]: The HTTP method for the redirect (defaults to current method).
  /// - [url]: The target URL (defaults to the `Location` header).
  /// - [followLoops]: If `true`, follows redirects even if the URL was already visited.
  ///
  /// ## Returns
  /// A new [HttpClientResponse] from the redirected URL.
  ///
  /// ## Throws
  /// - [StateError] if body data has not been fully read.
  ///
  /// ## Edge cases
  /// - The method ignores [HttpClientRequest.maxRedirects] and always performs
  ///   the redirect.
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]);

  /// Returns the client response headers.
  ///
  /// The client response headers are immutable.
  ///
  /// ## Example
  /// ```dart
  /// final contentType = response.headers.value('content-type');
  /// ```
  HttpHeaders get headers;
}