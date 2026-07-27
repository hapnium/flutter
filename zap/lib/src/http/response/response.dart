import '../../definitions.dart';
import '../../enums/zap_provider.dart';
import '../request/request.dart';
import '../utils/http_status.dart';

/// {@template response}
/// A class that encapsulates an HTTP response, including the decoded body,
/// headers, status code, and raw response data.
///
/// This class is generic and can be used to represent the body of any type [T],
/// which allows flexibility in decoding different types of responses.
///
/// ## Features
/// - Generic type parameter for typed response bodies
/// - Multiple status checking methods (isOk, is2xxSuccessful, etc.)
/// - Copy-with support for immutable modifications
/// - JSON serialization support
/// - Provider tracking (io, web, graphql)
///
/// ## Typical usage
/// ```dart
/// final response = Response<User>(
///   status: HttpStatus.ok,
///   body: User.fromJson(json),
///   headers: {...},
/// );
/// if (response.isOk) {
///   // Use response.body
/// }
/// ```
/// 
/// {@endtemplate}
class Response<T> {
  /// The original request that triggered this response.
  ///
  /// This includes request details like the HTTP method, URL, headers, and body.
  /// It may be `null` if the response was not associated with a request.
  ///
  /// ## Example
  /// ```dart
  /// print(response.request?.method); // 'GET'
  /// ```
  final Request? request;

  /// The HTTP response headers returned by the server.
  ///
  /// These might include metadata such as content type, authorization info, etc.
  /// Header names are lowercase.
  ///
  /// ## Example
  /// ```dart
  /// final contentType = response.headers?['content-type'];
  /// ```
  final Headers? headers;

  /// The HTTP status code and description.
  ///
  /// This includes both the numeric status code (e.g., 200, 404)
  /// and a human-readable message (e.g., "OK", "Not Found").
  ///
  /// ## Example
  /// ```dart
  /// print(response.status.code); // 200
  /// print(response.status.name); // 'OK'
  /// ```
  final HttpStatus status;

  /// A human-readable message describing the response.
  ///
  /// Defaults to [status.description] if not explicitly provided.
  ///
  /// ## Example
  /// ```dart
  /// print(response.message); // 'Standard response for successful HTTP requests'
  /// ```
  final String message;

  /// The raw response body as a stream of bytes.
  ///
  /// Useful for downloading binary data such as files or images.
  /// The stream can be listened to multiple times (broadcast).
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await response.bodyBytes?.toBytes();
  /// ```
  final BodyByteStream? bodyBytes;

  /// The raw response body decoded as a UTF-8 string.
  ///
  /// Suitable for logging or fallback access when deserialization fails.
  ///
  /// ## Example
  /// ```dart
  /// print(response.bodyString); // '{"id": 1, "name": "John"}'
  /// ```
  final String? bodyString;

  /// Which client was used to make the request that brought this response.
  ///
  /// Can be [ZapProvider.io], [ZapProvider.web], or [ZapProvider.graphql].
  ///
  /// ## Example
  /// ```dart
  /// if (response.provider == ZapProvider.io) {
  ///   print('Response from IO platform');
  /// }
  /// ```
  final ZapProvider provider;

  /// The parsed/deserialized response body of type [T].
  ///
  /// This is usually the result of applying a response parser on the raw response body.
  /// If no decoder was provided, this may be `null` or the raw body.
  ///
  /// ## Example
  /// ```dart
  /// final User? user = response.body;
  /// if (user != null) {
  ///   print(user.name);
  /// }
  /// ```
  final T? body;

  /// Constructs a new [Response] with the given fields.
  ///
  /// ## Parameters
  /// - [request]: The original request (optional).
  /// - [status]: The HTTP status code.
  /// - [bodyBytes]: The raw response body as bytes (optional).
  /// - [bodyString]: The raw response body as a string (optional).
  /// - [headers]: The response headers (default: empty map).
  /// - [body]: The decoded response body (optional).
  /// - [message]: A human-readable message (defaults to status description).
  /// - [provider]: The provider type (default: [ZapProvider.io]).
  ///
  /// If [message] is not provided, it will default to the status description.
  /// 
  /// {@macro response}
  Response({
    this.request,
    required this.status,
    this.bodyBytes,
    this.bodyString,
    this.headers = const {},
    this.body,
    String? message,
    this.provider = ZapProvider.io,
  }) : message = message ?? status.description;

  /// Creates a copy of this response with optional overrides.
  ///
  /// This is useful for modifying or updating specific fields without
  /// reconstructing the entire response object.
  ///
  /// ## Parameters
  /// - [request]: Override for the original request.
  /// - [status]: Override for the HTTP status code.
  /// - [bodyBytes]: Override for the raw response body.
  /// - [bodyString]: Override for the string response body.
  /// - [headers]: Override for the response headers.
  /// - [body]: Override for the decoded response body.
  /// - [provider]: Override for the provider type.
  ///
  /// ## Returns
  /// A new [Response] with the specified modifications.
  ///
  /// ## Example
  /// ```dart
  /// final updated = response.copyWith(
  ///   body: newUser,
  ///   status: HttpStatus.OK,
  /// );
  /// ```
  Response<T> copyWith({
    Request? request,
    HttpStatus? status,
    BodyByteStream? bodyBytes,
    String? bodyString,
    Map<String, String>? headers,
    T? body,
    ZapProvider? provider,
  }) {
    return Response<T>(
      request: request ?? this.request,
      status: status ?? this.status,
      bodyBytes: bodyBytes ?? this.bodyBytes,
      bodyString: bodyString ?? this.bodyString,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      provider: provider ?? this.provider,
    );
  }

  /// Returns `true` if the response indicates an error.
  ///
  /// Error responses typically have status codes outside the 200–299 range.
  ///
  /// ## Example
  /// ```dart
  /// if (response.hasError) {
  ///   print('Error: ${response.status}');
  /// }
  /// ```
  bool get hasError => status.hasError;

  /// Returns `true` if the response indicates a successful request.
  ///
  /// Equivalent to `!hasError`, covering status codes 200–299.
  ///
  /// ## Example
  /// ```dart
  /// if (response.isOk) {
  ///   final data = response.body;
  /// }
  /// ```
  bool get isOk => !hasError;

  /// Returns `true` if the response status code is 401 (Unauthorized).
  ///
  /// This is useful for detecting authentication failures.
  ///
  /// ## Example
  /// ```dart
  /// if (response.unauthorized) {
  ///   // Redirect to login
  /// }
  /// ```
  bool get unauthorized => status.isUnauthorized;

  /// Returns `true` if the status code is in the 2xx range (200–299).
  ///
  /// This typically indicates success.
  ///
  /// ## Example
  /// ```dart
  /// if (response.is2xxSuccessful()) {
  ///   print('Success!');
  /// }
  /// ```
  bool is2xxSuccessful() {
    return status.code >= 200 && status.code < 300;
  }

  /// Returns `true` if the status code is in the 3xx range (300–399).
  ///
  /// This indicates a redirection response.
  ///
  /// ## Example
  /// ```dart
  /// if (response.is3xxRedirection()) {
  ///   final location = response.headers?['location'];
  /// }
  /// ```
  bool is3xxRedirection() {
    return status.code >= 300 && status.code < 400;
  }

  /// Returns `true` if the status code is in the 4xx range (400–499).
  ///
  /// This indicates a client error such as bad request or unauthorized access.
  ///
  /// ## Example
  /// ```dart
  /// if (response.is4xxClientError()) {
  ///   print('Client error: ${response.status}');
  /// }
  /// ```
  bool is4xxClientError() {
    return status.code >= 400 && status.code < 500;
  }

  /// Returns `true` if the status code is in the 5xx range (500–599).
  ///
  /// This indicates a server-side error.
  ///
  /// ## Example
  /// ```dart
  /// if (response.is5xxServerError()) {
  ///   print('Server error, try again later');
  /// }
  /// ```
  bool is5xxServerError() {
    return status.code >= 500 && status.code < 600;
  }

  /// Converts this response to a JSON-compatible map.
  ///
  /// Useful for logging, debugging, or serialization. Note that some fields
  /// (like streams) cannot be properly serialized.
  ///
  /// ## Returns
  /// A [Map<String, dynamic>] containing response metadata.
  Map<String, dynamic> toJson() {
    return {
      'request': request?.toJson(),
      'headers': headers,
      'status': status.toJson(),
      'bodyBytes': bodyBytes,
      'bodyString': bodyString,
      'body': body,
      'provider': provider,
    };
  }
}