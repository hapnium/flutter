import '../request/request.dart';
import '../response/response.dart';

/// {@template http_request_interface}
/// Abstract interface of [HttpRequestImplementation].
///
/// This class defines the contract for HTTP request implementations across
/// different platforms (IO, Web, Mock). All platform-specific HTTP clients
/// must implement this interface.
///
/// ## Implementations
/// - `dart:io` based implementation for mobile/desktop.
/// - `dart:web` based implementation for browser platforms.
/// - Mock implementation for testing.
///
/// ## Example
/// ```dart
/// class MyHttpClient implements HttpRequestInterface {
///   @override
///   Future<Response<T>> send<T>(Request<T> request) async {
///     // Implement HTTP request logic
///   }
///
///   @override
///   void close() {}
///
///   @override
///   Duration? timeout;
/// }
/// ```
/// {@endtemplate}
abstract class HttpRequestInterface {
  /// Sends an HTTP [Request] and returns a [Response].
  /// 
  /// This method sends the configured request to the server and returns
  /// the parsed response. The response includes status code, headers,
  /// body, and any decoded data.
  /// 
  /// ## Parameters
  /// - [request]: The fully configured request to send.
  /// 
  /// ## Returns
  /// A [Future<Response<T>] with the server's response.
  ///
  /// ## Throws
  /// Platform-specific exceptions for network errors, timeouts, etc.
  /// These should be caught and converted to [ZapException] by the caller.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.send<String>(request);
  /// print(response.body);
  /// ```
  Future<Response<T>> send<T>(Request<T> request);

  /// Closes the HTTP client and releases associated resources.
  ///
  /// After calling this method, the client should not be used for further
  /// requests. Any in-flight requests may be aborted depending on the
  /// platform implementation.
  ///
  /// ## Example
  /// ```dart
  /// client.close(); // Release connection pool resources
  /// ```
  void close();

  /// Gets and sets the timeout for HTTP requests.
  ///
  /// For mobile (dart:io), this value will be applied for both connection and
  /// request timeout.
  ///
  /// For web (dart:web), this value will be the request timeout only.
  ///
  /// If `null`, no timeout is enforced.
  ///
  /// ## Example
  /// ```dart
  /// client.timeout = Duration(seconds: 30);
  /// ```
  Duration? timeout;
}