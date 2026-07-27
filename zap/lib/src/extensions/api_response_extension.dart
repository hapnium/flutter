import '../http/response/response.dart';
import '../models/response/api_response.dart';

/// {@template api_response_extension}
/// Extension on `Response<ApiResponse>` that provides convenient accessors
/// for common properties used in API response handling.
///
/// This extension eliminates the need to manually check multiple levels
/// of the response hierarchy when extracting user-facing messages. It
/// provides a single [detailedMessage] getter that intelligently falls
/// back through the response structure.
///
/// ### Response hierarchy
///
/// ```
/// Response<ApiResponse>
///   ├── .message          (top-level HTTP message)
///   ├── .status           (HTTP status code)
///   └── .body             (ApiResponse)
///         ├── .status     (business status: "success", "fail", "error")
///         ├── .code       (HTTP status code)
///         ├── .message    (business-level message)
///         └── .data       (raw payload)
/// ```
///
/// ### Example
///
/// ```dart
/// final response = await zap.get<ApiResponse>('/users/1');
///
/// // Get the most relevant message
/// final message = response.detailedMessage;
/// print(message); // "User not found" or "Request successful"
/// ```
///
/// ### When to use
///
/// - Displaying user-facing messages in UI
/// - Logging API responses
/// - Building error handling middleware
/// - Creating notification systems
/// {@endtemplate}
extension ApiResponseExtension on Response<ApiResponse> {
  /// {@template api_response_extension_detailedMessage}
  /// Retrieves the most relevant message from the API response.
  ///
  /// This getter prioritizes the `message` field inside the [ApiResponse]
  /// body. If the body is `null` or does not contain a message, it falls
  /// back to the top-level `message` property of the [Response] object.
  ///
  /// ### Resolution order
  ///
  /// 1. `body?.message` — The business-level message from [ApiResponse]
  /// 2. `message` — The top-level HTTP message from [Response]
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Scenario 1: Body has a message
  /// // Response: { body: { message: "User created" } }
  /// response.detailedMessage; // "User created"
  ///
  /// // Scenario 2: Body is null
  /// // Response: { body: null, message: "OK" }
  /// response.detailedMessage; // "OK"
  ///
  /// // Scenario 3: Body has empty message
  /// // Response: { body: { message: "" }, message: "Success" }
  /// response.detailedMessage; // "Success"
  /// ```
  ///
  /// ### Usage in UI
  ///
  /// ```dart
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(
  ///     content: Text(response.detailedMessage),
  ///     backgroundColor: response.body?.isOk == true ? Colors.green : Colors.red,
  ///   ),
  /// );
  /// ```
  ///
  /// ### Usage in logging
  ///
  /// ```dart
  /// Z.info('API Response: ${response.detailedMessage}');
  /// ```
  ///
  /// ### Null safety
  ///
  /// This getter always returns a non-null string. If both the body
  /// message and response message are null, an empty string is returned.
  /// {@endtemplate}
  String get detailedMessage => body?.message ?? message;
}