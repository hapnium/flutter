import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show Uint8List;

import '../../definitions.dart';
import '../../enums/exception_type.dart';
import '../../exceptions/controller_advice.dart';
import '../../exceptions/zap_exception.dart';
import '../certificates/certificates.dart';
import '../interface/http_client_response.dart';
import '../interface/http_request_interface.dart';
import '../modifier/zap_modifier.dart';
import '../multipart/form_data.dart';
import '../request/http_request.dart';
import '../request/request.dart';
import '../response/response.dart';
import '../utils/constants.dart';
import '../utils/http_content_type.dart';
import '../utils/http_headers.dart';
import '../utils/http_method.dart';
import '../utils/http_status.dart';

part 'client_handler.dart';
part 'client_handler_extension.dart';

/// {@template response_interceptor}
/// A function that allows interception and modification of the HTTP response before it is returned.
///
/// Can be used for custom parsing, logging, or authentication flows.
///
/// - [request]: The original request that triggered the response.
/// - [targetType]: The expected type of the response body.
/// - [response]: The raw HTTP response received from the server.
///
/// Returns an optional [Response<T>] that replaces the default response, or `null`
/// to use the default response processing pipeline.
///
/// ## Example
/// ```dart
/// ResponseInterceptor<User> interceptor = (request, targetType, response) async {
///   final body = await response.bodyBytes.toBytes();
///   if (response.statusCode == 401) {
///     // Handle unauthorized
///     return Response(status: HttpStatus.UNAUTHORIZED, request: request);
///   }
///   return null; // Use default processing
/// };
/// ```
/// {@endtemplate}
typedef ResponseInterceptor<T> = Future<Response<T>?> Function(Request<T> request, Type targetType, HttpClientResponse response);

/// {@template zap_client}
/// The core HTTP client used to configure and send HTTP requests.
///
/// [ZapClient] provides a customizable interface for sending HTTP requests
/// with support for default headers, redirects, proxy settings, response
/// interceptors, timeouts, and decoding strategies.
///
/// It's designed to be flexible for various use cases including REST APIs,
/// file downloads, and custom request flows.
///
/// ## Example
/// ```dart
/// final client = ZapClient(
///   baseUrl: 'https://api.example.com',
///   userAgent: 'Zap/1.0',
///   timeout: Duration(seconds: 10),
/// );
/// ```
///
/// ## Usage with modifiers
/// ```dart
/// final client = ZapClient(
///   baseUrl: 'https://api.example.com',
/// );
///
/// client.addRequestModifier((request) {
///   request.headers['Authorization'] = 'Bearer $token';
///   return request;
/// });
/// ```
///
/// ## Edge cases
/// - Setting [errorSafety] to `false` will cause exceptions to propagate
///   instead of being caught and returned as error responses.
/// - If [baseUrl] is provided, relative paths in requests are resolved against it.
/// - The [close] method must be called when the client is no longer needed to
///   release resources.
/// {@endtemplate}
class ZapClient {
  /// The user agent string to send with each request.
  ///
  /// This identifies the client to the server. If [sendUserAgent] is `false`,
  /// this value is ignored.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(userAgent: 'MyApp/1.0');
  /// ```
  String userAgent;

  /// The base URL to prepend to relative request paths.
  ///
  /// If provided, all relative URLs will be resolved against this base.
  /// If `null`, URLs must be absolute.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(baseUrl: 'https://api.example.com/v1');
  /// final response = await client.get('/users'); // GET https://api.example.com/v1/users
  /// ```
  String? baseUrl;

  /// The default content type to include in request headers.
  ///
  /// Typically used for APIs expecting JSON, form-encoded data, etc.
  /// Default is `'application/json; charset=utf-8'`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(defaultContentType: 'application/xml; charset=utf-8');
  /// ```
  String defaultContentType = Constants.DEFAULT_CONTENT_TYPE;

  /// Whether the client should automatically follow HTTP redirects.
  ///
  /// Defaults to `true`. If set to `false`, 3xx responses are returned as-is.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(followRedirects: false);
  /// // 301/302 responses will be returned directly
  /// ```
  bool followRedirects;

  /// The maximum number of redirects the client should follow.
  ///
  /// Only relevant if [followRedirects] is `true`. Defaults to `5`.
  /// If the redirect limit is exceeded, a [ZapException] with type
  /// [ExceptionType.client] will be thrown.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(maxRedirects: 10);
  /// ```
  int maxRedirects;

  /// The maximum number of times to retry authentication challenges (e.g., 401).
  ///
  /// Helps prevent infinite loops during failed auth attempts. Defaults to `1`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(maxAuthRetries: 3);
  /// ```
  int maxAuthRetries;

  /// Whether to include the [userAgent] header in requests.
  ///
  /// If `false`, no `User-Agent` header will be sent.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(sendUserAgent: true, userAgent: 'MyApp');
  /// ```
  bool sendUserAgent;

  /// Whether to automatically calculate and include the `Content-Length` header.
  ///
  /// Some servers require this; enabling it helps with compatibility.
  /// Defaults to `true`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(sendContentLength: true);
  /// ```
  bool sendContentLength;

  /// The default function to decode the response body.
  ///
  /// This is used when no specific decoder is provided per request.
  /// If `null`, the response body is returned as a raw `Map` or `String`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(
  ///   defaultDecoder: (data) => User.fromJson(data as Map<String, dynamic>),
  /// );
  /// ```
  ResponseDecoder? defaultDecoder;

  /// The default function to intercept and optionally modify HTTP responses.
  ///
  /// Can be used for logging, error handling, or data transformation.
  /// Applied to all requests unless overridden by a per-request interceptor.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(
  ///   defaultResponseInterceptor: (request, targetType, response) async {
  ///     print('Response: ${response.statusCode}');
  ///     return null;
  ///   },
  /// );
  /// ```
  ResponseInterceptor? defaultResponseInterceptor;

  /// The maximum duration to wait before a request times out.
  ///
  /// This applies to connection, sending, and receiving phases.
  /// Defaults to `Duration(seconds: 8)`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(timeout: Duration(seconds: 30));
  /// ```
  Duration timeout;

  /// Whether the client should safely handle errors during request execution.
  ///
  /// If `true`, errors are caught and handled internally, returned as
  /// error responses. If `false`, they are allowed to propagate as exceptions.
  /// Defaults to `true`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(errorSafety: false);
  /// // Exceptions will be thrown instead of caught
  /// ```
  bool errorSafety;

  /// The internal low-level HTTP request interface used by the client.
  ///
  /// This is typically injected and not meant for direct use by consumers.
  final HttpRequestInterface _client;

  /// A modifier used to mutate requests and responses globally.
  ///
  /// Can be used to add headers, transform requests, or log responses.
  final ZapModifier _modifier;

  /// A callback that returns a proxy URL for a given request URL.
  ///
  /// If `null`, no proxy is used. Useful for custom proxy logic.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(
  ///   findProxy: (uri) => 'PROXY proxy.example.com:8080',
  /// );
  /// ```
  ProxyFinder? findProxy;

  /// A callback that returns a controller advice for a given request URL.
  ///
  /// If `null`, default controller advice is used. Used for centralized
  /// error handling and exception notification.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(
  ///   controllerAdvice: ControllerAdvice(
  ///     onException: (exception) => print('Error: $exception'),
  ///   ),
  /// );
  /// ```
  ControllerAdvice? controllerAdvice;

  /// Creates a new instance of [ZapClient] with customizable networking behavior.
  ///
  /// This constructor allows configuring HTTP settings such as timeouts,
  /// redirection, certificate trust, and proxy handling. It is intended for use
  /// in applications that require fine-grained control over how HTTP requests are
  /// made and how responses are processed.
  ///
  /// ## Parameters
  /// - [userAgent]: The User-Agent string sent with requests (if [sendUserAgent] is true).
  /// - [timeout]: The maximum duration to wait before a request times out.
  /// - [followRedirects]: Whether the client should automatically follow HTTP 3xx redirects.
  /// - [maxRedirects]: Maximum number of redirects to follow before failing the request.
  /// - [sendUserAgent]: Whether to include the User-Agent header in requests.
  /// - [sendContentLength]: Whether to automatically set the `Content-Length` header.
  /// - [maxAuthRetries]: Maximum number of retries for authentication challenges (e.g., HTTP 401).
  /// - [allowAutoSignedCert]: Whether to allow self-signed certificates. Useful for testing.
  /// - [baseUrl]: Optional base URL that will be prepended to relative request paths.
  /// - [trustedCertificates]: A list of [ZapTrustedCertificate] instances to trust explicitly.
  /// - [withCredentials]: Whether to include credentials (like cookies) in CORS requests.
  /// - [findProxy]: A function to determine the proxy server for a given request URL.
  /// - [customClient]: A custom low-level HTTP implementation to use instead of the default.
  /// - [errorSafety]: Whether to catch errors internally and return error responses.
  /// - [controllerAdvice]: A callback for centralized error handling.
  ///
  /// ## Returns
  /// A new, fully configured instance of [ZapClient].
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(
  ///   baseUrl: 'https://api.example.com',
  ///   timeout: Duration(seconds: 15),
  ///   followRedirects: true,
  ///   maxRedirects: 10,
  ///   sendUserAgent: true,
  ///   userAgent: 'MyApp/1.0',
  /// );
  /// ```
  /// 
  /// {@macro zap_client}
  ZapClient({
    this.userAgent = Constants.DEFAULT_USER_AGENT,
    this.timeout = const Duration(seconds: 8),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.sendUserAgent = false,
    this.sendContentLength = true,
    this.maxAuthRetries = 1,
    bool allowAutoSignedCert = false,
    this.baseUrl,
    List<ZapTrustedCertificate>? trustedCertificates,
    bool withCredentials = false,
    ProxyFinder? findProxy,
    bool enableCookies = true,
    HttpRequestInterface? customClient,
    this.errorSafety = true,
    this.controllerAdvice,
  })  : _client = customClient ?? createHttp(
      allowAutoSignedCert: allowAutoSignedCert,
      trustedCertificates: trustedCertificates,
      withCredentials: withCredentials,
      findProxy: findProxy,
      enableCookies: enableCookies,
    ),
    _modifier = ZapModifier();

  /// Adds an authenticator function that modifies requests before sending.
  ///
  /// Authenticator functions are commonly used to inject credentials, tokens,
  /// or headers before a request is dispatched. The authenticator is called
  /// only when a 401 response is received and a retry is attempted.
  ///
  /// ## Parameters
  /// - [auth]: A [RequestModifier] function that takes a request and modifies it.
  ///
  /// ## Example
  /// ```dart
  /// client.addAuthenticator<String>((request) async {
  ///   final token = await getAuthToken();
  ///   request.headers['Authorization'] = 'Bearer $token';
  ///   return request;
  /// });
  /// ```
  void addAuthenticator<T>(RequestModifier<T> auth) {
    _modifier.authenticator = auth as RequestModifier;
  }

  /// Adds a request modifier function that intercepts and alters outgoing requests.
  ///
  /// This can be used to inject headers, transform URLs, log request data, etc.
  /// Request modifiers are applied in the order they are added.
  ///
  /// ## Parameters
  /// - [interceptor]: A [RequestModifier] that transforms the request before sending.
  ///
  /// ## Example
  /// ```dart
  /// client.addRequestModifier<String>((request) {
  ///   request.headers['X-Custom-Header'] = 'value';
  ///   return request;
  /// });
  /// ```
  void addRequestModifier<T>(RequestModifier<T> interceptor) {
    _modifier.addRequestModifier<T>(interceptor);
  }

  /// Removes a previously added request modifier.
  ///
  /// ## Parameters
  /// - [interceptor]: The [RequestModifier] to be removed.
  ///
  /// ## Example
  /// ```dart
  /// final modifier = (request) { /* ... */ };
  /// client.addRequestModifier(modifier);
  /// // Later...
  /// client.removeRequestModifier(modifier);
  /// ```
  void removeRequestModifier<T>(RequestModifier<T> interceptor) {
    _modifier.removeRequestModifier(interceptor);
  }

  /// Adds a response modifier function that intercepts responses after they are received.
  ///
  /// Useful for tasks like logging, response transformation, or centralized error handling.
  /// Response modifiers are applied in the order they are added.
  ///
  /// ## Parameters
  /// - [interceptor]: A [ResponseModifier] that operates on the response.
  ///
  /// ## Example
  /// ```dart
  /// client.addResponseModifier<String>((request, response) {
  ///   print('Response status: ${response.status}');
  ///   return response;
  /// });
  /// ```
  void addResponseModifier<T>(ResponseModifier<T> interceptor) {
    _modifier.addResponseModifier(interceptor);
  }

  /// Removes a previously added response modifier.
  ///
  /// ## Parameters
  /// - [interceptor]: The [ResponseModifier] to remove from the modifier stack.
  ///
  /// ## Example
  /// ```dart
  /// client.removeResponseModifier(modifier);
  /// ```
  void removeResponseModifier<T>(ResponseModifier<T> interceptor) {
    _modifier.removeResponseModifier<T>(interceptor);
  }

  /// Lazily constructs a [ClientHandler] with the current client configuration.
  ///
  /// The handler is recreated on each access to ensure configuration changes
  /// are reflected. This is an internal getter and should not be used directly.
  ClientHandler get _handler => ClientHandler(
    modifier: _modifier,
    client: _client,
    errorSafety: errorSafety,
    maxAuthRetries: maxAuthRetries,
    maxRedirects: maxRedirects,
    controllerAdvice: controllerAdvice,
    followRedirects: followRedirects,
    findProxy: findProxy,
    baseUrl: baseUrl,
    sendUserAgent: sendUserAgent,
    sendContentLength: sendContentLength,
    userAgent: userAgent,
    defaultContentType: defaultContentType,
    timeout: timeout,
    defaultDecoder: defaultDecoder,
    defaultResponseInterceptor: defaultResponseInterceptor,
  );

  /// Builds a fully qualified [Uri] from a path and optional query parameters.
  ///
  /// If [baseUrl] is set, the path will be appended to it. Otherwise,
  /// the path must be a full URL.
  ///
  /// ## Parameters
  /// - [url]: A relative or absolute URL string.
  /// - [query]: An optional map of query parameters.
  ///
  /// ## Returns
  /// A fully resolved [Uri].
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(baseUrl: 'https://api.example.com');
  /// final uri = client.createUri('/users', {'page': '1'});
  /// // uri = Uri.parse('https://api.example.com/users?page=1')
  /// ```
  Uri createUri(String? url, RequestParam? query) => _handler.createUri(url, query);

  /// Sends a custom [Request] through the client pipeline.
  ///
  /// This method can be used when a prebuilt [Request] object is available,
  /// offering more control over the request's lifecycle.
  ///
  /// ## Parameters
  /// - [request]: The fully configured request to send.
  ///
  /// ## Returns
  /// A [Response] of type [T] representing the result of the request.
  ///
  /// ## Throws
  /// A [ZapException] if the request fails and [errorSafety] is disabled.
  ///
  /// ## Example
  /// ```dart
  /// final request = Request(
  ///   url: Uri.parse('https://api.example.com/users'),
  ///   method: 'GET',
  ///   headers: {'Accept': 'application/json'},
  /// );
  /// final response = await client.send<User>(request);
  /// ```
  Future<Response<T>> send<T>(Request<T> request) async {
    try {
      var response = await _handler.perform<T>(request);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Sends an HTTP PATCH request to the given [url].
  ///
  /// Useful for making partial updates to a resource.
  ///
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [body]: Optional body payload for the request.
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [headers]: Additional HTTP headers.
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  ///
  /// ## Returns
  /// A [Response] of type [T] representing the server's reply.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.patch<User>(
  ///   '/users/123',
  ///   body: {'name': 'Updated Name'},
  /// );
  /// ```
  Future<Response<T>> patch<T>(String url, {
    RequestBody body,
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
    // List<MultipartFile> files,
  }) async {
    final request = await _handler.getRequestWithBody<T>(
      url,
      HttpMethod.PATCH,
      contentType: contentType,
      body: body,
      query: query,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
      uploadProgress: uploadProgress,
    );

    try {
      var response = await _handler.perform<T>(request, headers: headers);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Sends an HTTP POST request to the given [url].
  ///
  /// Useful for submitting data to a server to create a new resource.
  ///
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [body]: Optional body payload for the request.
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [headers]: Additional HTTP headers.
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  ///
  /// ## Returns
  /// A [Response] of type [T] representing the server's reply.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.post<User>(
  ///   '/users',
  ///   body: {'name': 'John', 'email': 'john@example.com'},
  /// );
  /// ```
  Future<Response<T>> post<T>(String? url, {
    RequestBody body,
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
    // List<MultipartFile> files,
  }) async {
    final request = await _handler.getRequestWithBody<T>(
      url,
      HttpMethod.POST,
      contentType: contentType,
      body: body,
      query: query,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
      uploadProgress: uploadProgress,
    );

    try {
      var response = await _handler.perform<T>(request, headers: headers);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Sends an HTTP request to the given [url] using the specified [method].
  ///
  /// Useful for making custom HTTP requests when the built-in methods are insufficient.
  /// This method supports all HTTP methods (e.g., GET, POST, PUT, PATCH, DELETE).
  ///
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [method]: HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  /// - [body]: Optional body payload for the request.
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [headers]: Additional HTTP headers.
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  ///
  /// ## Returns
  /// A [Response] of type [T] representing the server's reply.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.request<User>(
  ///   '/users',
  ///   'CUSTOM_METHOD',
  ///   body: {'key': 'value'},
  /// );
  /// ```
  Future<Response<T>> request<T>(String url, String method, {
    RequestBody body,
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) async {
    final request = await _handler.getRequestWithBody<T>(
      url,
      HttpMethod.FROM(method),
      contentType: contentType,
      body: body,
      query: query,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
      uploadProgress: uploadProgress,
    );

    try {
      var response = await _handler.perform<T>(request, headers: headers);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Sends an HTTP PUT request to the given [url].
  ///
  /// Useful for updating resources on the server. PUT typically replaces
  /// the entire resource at the specified URL.
  ///
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [body]: Optional body payload for the request.
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [headers]: Additional HTTP headers.
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  ///
  /// ## Returns
  /// A [Response] of type [T] representing the server's reply.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.put<User>(
  ///   '/users/123',
  ///   body: {'name': 'Updated Name', 'email': 'new@example.com'},
  /// );
  /// ```
  Future<Response<T>> put<T>(String url, {
    RequestBody body,
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) async {
    final request = await _handler.getRequestWithBody<T>(
      url,
      HttpMethod.PUT,
      contentType: contentType,
      query: query,
      body: body,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
      uploadProgress: uploadProgress,
    );

    try {
      var response = await _handler.perform<T>(request, headers: headers);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Sends an HTTP GET request to the specified [url].
  ///
  /// Use this to retrieve data from a server without modifying it.
  ///
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [headers]: Additional request headers.
  /// - [contentType]: Expected MIME type of the response.
  /// - [query]: Query parameters to append to the request URL.
  /// - [decoder]: Optional function to decode the response body.
  /// - [responseInterceptor]: Optional hook for modifying the received response.
  ///
  /// ## Returns
  /// A [Response] of type [T] with the requested resource.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.get<List<User>>(
  ///   '/users',
  ///   query: {'page': '1', 'limit': '20'},
  /// );
  /// final users = response.body;
  /// ```
  Future<Response<T>> get<T>(String url, {
    Headers? headers,
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) async {
    final request = await _handler.getRequestWithoutBody<T>(
      url,
      HttpMethod.GET,
      contentType: contentType,
      query: query,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
      contentLength: 0,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
    );

    try {
      var response = await _handler.perform<T>(request, headers: headers);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Sends an HTTP DELETE request to the specified [url].
  ///
  /// Use this to remove resources from a server.
  ///
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [headers]: Additional HTTP headers.
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  ///
  /// ## Returns
  /// A [Response] of type [T] representing the server's reply.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.delete('/users/123');
  /// if (response.isOk) {
  ///   print('User deleted successfully');
  /// }
  /// ```
  Future<Response<T>> delete<T>(String url, {
    Headers? headers,
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
  }) async {
    final request = await _handler.getRequestWithoutBody<T>(
      url,
      HttpMethod.DELETE,
      decoder: decoder,
      responseInterceptor: responseInterceptor,
    );

    try {
      var response = await _handler.perform<T>(request, headers: headers);
      return response;
    } on Exception catch (e) {
      return _handler.handleException<T>(e, request);
    }
  }

  /// Closes the underlying HTTP client and releases resources.
  ///
  /// After calling this method, the [ZapClient] instance should not be used
  /// to make further requests. Any in-flight requests may be aborted.
  ///
  /// This is especially important for applications that maintain persistent
  /// connections or run in long-lived environments to prevent resource leaks.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(baseUrl: 'https://api.example.com');
  /// // ... use client ...
  /// client.close(); // Release resources
  /// ```
  void close() {
    _client.close();
  }
}