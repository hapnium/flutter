/// {@template api_response}
/// A universal Data Transfer Object (DTO) that implements the "Envelope Pattern" 
/// for standardized REST API communication.
///
/// **Architectural Context:**
/// Modern backend APIs typically wrap their raw payloads in a consistent JSON envelope. 
/// Instead of every repository in the app manually checking HTTP status codes and 
/// parsing nested data fields, this class acts as a single, unified boundary between 
/// the raw HTTP client (like Dio or http) and your domain-specific repositories.
///
/// By keeping the [data] field as `dynamic`, a single `ApiResponse` class can represent 
/// the result of *any* endpoint. The specific repositories then use [resolvedAs] or 
/// [resolvedListAs] to strongly type the payload at the exact moment it's needed.
///
/// **Example Usage:**
/// ```dart
/// // 1. Parse the generic envelope
/// final response = ApiResponse.fromJson(jsonDecode(responseBody));
/// 
/// // 2. Check network success
/// if (response.isOk) {
///   // 3. Strongly type the dynamic payload
///   final user = response.resolvedAs<User>((json) => User.fromJson(json));
///   return user;
/// } else {
///   throw Exception(response.message);
/// }
/// ```
/// {@endtemplate}
class ApiResponse {
  /// The business-logic status of the response.
  /// 
  /// Typically conforms to the JSend specification (e.g., `"success"`, `"fail"`, 
  /// or `"error"`). While [code] represents the network-level status, this field 
  /// represents the application-level status.
  final String status;

  /// The standard HTTP status code (e.g., `200` for OK, `404` for Not Found).
  /// 
  /// Used to dictate control flow (e.g., navigating to a login screen on `401`, 
  /// or showing a retry button on `500`).
  final int code;

  /// A human-readable message provided by the server.
  /// 
  /// In a successful response, this might be `"Profile updated successfully"`.
  /// In an error response, this contains the localized error string (e.g., `"Invalid password"`), 
  /// making it safe to directly pipe into a UI Snackbar or Toast.
  final String message;

  /// The raw, unparsed payload returned by the server.
  /// 
  /// This is kept as `dynamic` (usually a `Map<String, dynamic>` or `List<dynamic>`) 
  /// so that the HTTP interceptor doesn't need to know about your domain models. 
  /// It is strongly typed later via [resolvedAs] or [resolvedListAs].
  final dynamic data;

  /// {@macro api_response}
  /// 
  /// Instantiates a completely populated response. Usually called internally by 
  /// the factory constructors.
  ApiResponse({
    required this.status,
    required this.code,
    required this.message,
    this.data,
  });

  /// Evaluates whether the network request was successful.
  /// 
  /// Returns `true` if the HTTP status code is `200` (OK) or `201` (Created). 
  /// This is the primary gatekeeper property used before attempting to parse [data].
  bool get isOk => code == 200 || isCreated;

  /// Evaluates whether a new resource was successfully generated on the server.
  /// 
  /// Returns `true` strictly for HTTP `201`. Useful for POST requests where you 
  /// need to verify creation rather than just a successful read.
  bool get isCreated => code == 201;

  /// Deserializes a raw JSON envelope into an [ApiResponse].
  ///
  /// **Defensive Parsing:**
  /// If the server returns a malformed response (e.g., an HTML error page instead 
  /// of JSON, or missing keys), this factory provides strict fallbacks:
  /// - Status defaults to an empty string.
  /// - Code defaults to `400` (Bad Request).
  /// - Message defaults to `"Couldn't validate request"`.
  /// 
  /// This ensures the app can always gracefully handle the object without throwing 
  /// a late-initialization or null-pointer error.
  /// 
  /// {@macro api_response}
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? "",
      code: json['code'] ?? 400,
      message: json['message'] ?? "Couldn't validate request",
      data: json['data'],
    );
  }

  /// Returns a new instance of [ApiResponse] with selectively updated fields.
  ///
  /// **Architectural Use Case:**
  /// Highly useful in middleware or HTTP interceptors. For example, you might 
  /// intercept a response, mutate the [message] to a localized string based on 
  /// the [code], and pass the copied response down to the repository.
  /// 
  /// {@macro api_response}
  ApiResponse copyWith({
    String? status,
    int? code,
    String? message,
    dynamic data,
  }) {
    return ApiResponse(
      status: status ?? this.status,
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  /// A convenience factory for generating a standardized, local error response.
  ///
  /// **Why mock an API response locally?**
  /// If a request fails *before* reaching the server (e.g., no internet connection, 
  /// or a timeout), you can use this factory to return a uniform [ApiResponse] 
  /// object to your repository. This prevents your repository from having to write 
  /// separate logic for `catch (SocketException)` vs a server-side 400 error.
  /// 
  /// {@macro api_response}
  factory ApiResponse.error(String message) =>
      ApiResponse(status: "error", code: 400, message: message);

  /// A convenience factory for locally generating a `401` Unauthorized response.
  /// 
  /// Typically used by authentication interceptors when a local JWT token is 
  /// verified to be expired before the network request is even sent.
  /// 
  /// {@macro api_response}
  factory ApiResponse.unauthorized(String message) =>
      ApiResponse(status: "unauthorized", code: 401, message: message);

  /// Serializes the envelope back into a JSON map.
  ///
  /// Useful for caching the raw response to local storage (like Hive or SharedPreferences) 
  /// to implement offline-first capabilities, or for unit testing API mocks.
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'code': code,
      'message': message,
      'data': data,
    };
  }

  /// Transforms the `dynamic` [data] payload into a strongly-typed object of type `T`.
  ///
  /// **How it works:**
  /// Instead of making the entire `ApiResponse` generic (which complicates HTTP 
  /// interceptors), you pass a [parser] function that knows how to convert the 
  /// dynamic JSON map into your specific domain model.
  ///
  /// **Example:**
  /// ```dart
  /// final user = response.resolvedAs<User>((json) => User.fromJson(json));
  /// ```
  T resolvedAs<T>(T Function(dynamic) parser) {
    return parser(data);
  }

  /// Transforms a `dynamic` list payload into a strictly typed `List<T>`.
  ///
  /// **Defensive Design:**
  /// If the server promises a list but returns `null` or a Map (due to an API bug), 
  /// this method safely intercepts the type mismatch and returns an empty list `[]`. 
  /// This completely eliminates `type 'String' is not a subtype of type 'List<dynamic>'` 
  /// crashes in production.
  ///
  /// **Example:**
  /// ```dart
  /// final users = response.resolvedListAs<User>((json) => User.fromJson(json));
  /// ```
  List<T> resolvedListAs<T>(T Function(dynamic) parser) {
    if (data is List) {
      return (data as List).map((e) => parser(e)).toList();
    }
    return [];
  }
}