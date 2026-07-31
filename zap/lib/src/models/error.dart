/// {@template error_message}
/// Represents a single validation error with a human-readable message.
///
/// Used as a building block within [ValidationError] to describe
/// individual field-level or rule-level failures.
/// {@endtemplate}
final class ErrorMessage {
  /// The human-readable error message describing the validation failure.
  ///
  /// Typically displayed to the user in a form error state or returned
  /// by the API for field-level validation feedback.
  final String value;

  /// {@macro error_message}
  const ErrorMessage(this.value);
}

/// {@template validation_error}
/// Represents a validation failure returned by the API, containing
/// a point-of-contact identifier and a list of [ErrorMessage] entries.
///
/// Used to surface server-side validation feedback to the user, e.g.
/// "Email is required" or "Password must be at least 8 characters".
///
/// ```dart
/// final error = ValidationError.fromJson(json);
/// for (final e in error.errors) {
///   print(e.value); // "Email is required"
/// }
/// ```
/// {@endtemplate}
final class ValidationError {
  /// Identifies the point of contact or context where the validation
  /// error occurred (e.g. a form name, API endpoint, or user-facing
  /// label like "sign-up form").
  final String pointOfContact;

  /// The list of individual validation error messages associated with
  /// this [pointOfContact]. May contain multiple entries when several
  /// rules fail simultaneously.
  final List<ErrorMessage> errors;

  /// {@macro validation_error}
  const ValidationError({
    required this.pointOfContact,
    required this.errors,
  });
}