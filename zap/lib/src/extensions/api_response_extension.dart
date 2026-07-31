import 'package:hapnium/hapnium.dart';

import '../http/response/response.dart';
import '../models/error.dart';
import '../models/response/api_response.dart';

/// {@template api_response_extension}
/// Extension on `Response<ApiResponse?>` that provides convenient accessors
/// for common properties used in API response handling.
///
/// This extension eliminates the need to manually check multiple levels
/// of the response hierarchy when extracting user-facing messages. It
/// provides a single [detailedMessage] getter that intelligently falls
/// back through the response structure.
///
/// ### Response hierarchy
///
/// ```text
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
extension ApiResponseExtension on Response<ApiResponse?> {
  /// {@template api_response_extension_detailedMessage}
  /// Retrieves the most relevant message from the API response.
  ///
  /// This getter prioritizes the `message` field inside the [ApiResponse]
  /// body. If the body is `null` or the body's message is `null`, it falls
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
  /// // Scenario 1: Body has a non-null message
  /// // Response: { body: { message: "User created" } }
  /// response.detailedMessage; // "User created"
  ///
  /// // Scenario 2: Body is null
  /// // Response: { body: null, message: "OK" }
  /// response.detailedMessage; // "OK"
  /// 
  /// // Scenario 3: Body has an empty string message
  /// // Response: { body: { message: "" }, message: "Success" }
  /// // Note: The ?? operator only checks for null, not emptiness.
  /// response.detailedMessage; // "" 
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
  /// {@endtemplate}
  String get detailedMessage => body?.message ?? message;

  /// Retrieves the most relevant message and capitalizes its first letter.
  ///
  /// This is a convenience wrapper around [detailedMessage] that ensures the 
  /// resulting string is properly formatted for UI presentation (e.g., 
  /// in snackbars or alert dialogs) where sentence-case is typically preferred.
  String getMessage() => (body?.message ?? message).capitalizeFirst;

  /// Evaluates whether the response represents a `403 Forbidden` / Permission Denied error.
  ///
  /// If a [reason] is provided, it additionally checks whether the server's 
  /// error message contains that specific reason string (case-insensitive). 
  /// This is useful for distinguishing between different types of 403 errors 
  /// (e.g., "Account suspended" vs. "Feature locked").
  ///
  /// Returns `true` only if the HTTP code is `403` and the [reason] 
  /// (if provided) matches a substring in the response message.
  bool isPermissionDenied([String? reason]) {
    if (body case ApiResponse apiResponse?) {
      if (apiResponse.code != 403) {
        return false;
      }

      if (reason == null || reason.trim().isEmpty) {
        return true;
      }

      return apiResponse.message.toLowerCase().contains(reason.trim().toLowerCase());
    }

    return false;
  }

  /// Safely proxies to [ApiResponse.retrieveValidationErrors] if the response body exists.
  ///
  /// Returns a list of structured [ValidationError] objects if the server 
  /// returned field-level validation failures (e.g., form submission errors). 
  /// If the body is null, is not an [ApiResponse], or no validation errors exist, 
  /// it safely returns an empty list `[]`.
  List<ValidationError> retrieveValidationErrors() {
    if (body case ApiResponse apiResponse?) {
      return apiResponse.retrieveValidationErrors();
    }

    return const [];
  }

  /// Generates a comprehensive, UI-ready error description.
  ///
  /// This method acts as a smart fallback mechanism to extract the best possible 
  /// error information from the response hierarchy. It is the recommended method 
  /// for grabbing a user-facing error string to display on screen.
  ///
  /// ### Resolution order:
  /// 1. If structured validation errors exist in the body, it returns a formatted, 
  ///    multi-line string of those errors via [ApiResponse.retrieveValidationErrorsPrettyMessage].
  /// 2. If no validation errors exist but a body is present, it returns [getMessage].
  /// 3. If the body is `null`, it returns the provided [fallback] string.
  /// 4. If no [fallback] is provided, it defaults to the top-level [message].
  String getErrorDescription([String? fallback]) {
    if (body case ApiResponse apiResponse?) {
      final validationErrors = retrieveValidationErrors();
      if (validationErrors.isNotEmpty) {
        return apiResponse.retrieveValidationErrorsPrettyMessage();
      }

      return getMessage();
    }

    return fallback ?? message;
  }
}