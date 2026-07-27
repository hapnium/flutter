/// {@template graphql_error}
/// Represents an error returned by a GraphQL API in the `errors` field
/// of a response.
///
/// In GraphQL, errors can be returned even when the HTTP response has a
/// 200 status code. These errors represent logical or validation failures
/// (e.g., field not found, permission denied, variable validation error)
/// rather than transport-level failures.
///
/// `GraphQLError` encapsulates the structure of a typical GraphQL error
/// object, including the human-readable [message] and optional machine-
/// readable [code].
///
/// ### Example
///
/// ```dart
/// final response = await zap.query<User>('''
///   query GetUser(\$id: ID!) {
///     user(id: \$id) { name email }
///   }
/// ''', variables: {'id': '999'});
///
/// if (response.errors != null && response.errors!.isNotEmpty) {
///   for (final error in response.errors!) {
///     print('Error: ${error.message}');
///     if (error.code == 'NOT_FOUND') {
///       _showNotFoundPage();
///     }
///   }
/// }
/// ```
///
/// ### GraphQL error structure
///
/// A typical GraphQL error response looks like:
/// ```json
/// {
///   "errors": [
///     {
///       "message": "Field 'user' not found on type 'Query'",
///       "extensions": {
///         "code": "FIELD_NOT_FOUND"
///       }
///     }
///   ],
///   "data": null
/// }
/// ```
///
/// This class maps to the error object, with [message] corresponding to
/// the `message` field and [code] corresponding to `extensions.code`.
/// {@endtemplate}
class GraphQLError {
  /// {@template graphql_error_constructor}
  /// Creates a [GraphQLError] with an optional [code] and [message].
  ///
  /// ### Parameters
  ///
  /// - [code]: Optional machine-readable error code. This typically comes
  ///   from the `extensions.code` field in the GraphQL response. Not all
  ///   GraphQL APIs include this field. Examples: `'NOT_FOUND'`,
  ///   `'UNAUTHENTICATED'`, `'VALIDATION_ERROR'`.
  /// - [message]: Optional human-readable error description. This
  ///   typically comes from the `message` field in the GraphQL response.
  ///   Examples: `"Field 'user' not found on type 'Query'"`,
  ///   `"Variable 'id' is required"`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final error = GraphQLError(
  ///   code: 'NOT_FOUND',
  ///   message: 'User with id 999 not found',
  /// );
  /// ```
  ///
  /// ### Null safety
  ///
  /// Both parameters are optional. In practice, at least one of [message]
  /// or [code] should be provided for the error to be useful.
  /// {@endtemplate}
  /// {@macro graphql_error}
  GraphQLError({this.code, this.message});

  /// {@template graphql_error_message}
  /// A descriptive message explaining the GraphQL error.
  ///
  /// This typically comes from the `message` field of a GraphQL error
  /// object. It is human-readable and intended for debugging or
  /// displaying to the user.
  ///
  /// ### Examples
  ///
  /// - `"Field 'user' not found on type 'Query'"`
  /// - `"Variable 'id' is required"`
  /// - `"Cannot query field 'email' on type 'User'"`
  /// - `"Argument 'limit' must be a positive integer"`
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (error.message != null) {
  ///   print('GraphQL error: ${error.message}');
  /// }
  /// ```
  ///
  /// ### Null safety
  ///
  /// This field is nullable because not all GraphQL error objects include
  /// a message. However, in practice, most well-formed GraphQL APIs
  /// always include a message.
  /// {@endtemplate}
  final String? message;

  /// {@template graphql_error_code}
  /// An optional machine-readable code representing the type of error.
  ///
  /// This typically comes from the `extensions.code` field in the GraphQL
  /// response. It is used for programmatic error handling -- you can
  /// switch on the code to perform type-specific recovery logic.
  ///
  /// ### Examples
  ///
  /// - `'NOT_FOUND'`: The requested resource does not exist
  /// - `'UNAUTHENTICATED'`: The user is not logged in
  /// - `'FORBIDDEN'`: The user lacks permission
  /// - `'VALIDATION_ERROR'`: Input validation failed
  /// - `'RATE_LIMITED'`: Too many requests
  ///
  /// ### Usage
  ///
  /// ```dart
  /// switch (error.code) {
  ///   case 'NOT_FOUND':
  ///     _showNotFoundPage();
  ///   case 'UNAUTHENTICATED':
  ///     _navigateToLogin();
  ///   case 'VALIDATION_ERROR':
  ///     _showValidationErrors(error.message);
  ///   default:
  ///     _showGenericError(error.message);
  /// }
  /// ```
  ///
  /// ### Null safety
  ///
  /// This field is nullable because not all GraphQL APIs include error
  /// codes. When it is `null`, you should fall back to the [message]
  /// for error handling.
  ///
  /// ### Custom codes
  ///
  /// Error codes are defined by the GraphQL server. Common conventions
  /// follow the Apollo Server or GraphQL spec recommendations, but
  /// your API may use different codes. Check your server's documentation
  /// for the full list of possible codes.
  /// {@endtemplate}
  final String? code;

  /// {@template graphql_error_toString}
  /// Returns a formatted string representation of the error for logging
  /// or debugging.
  ///
  /// The format is:
  /// ```
  /// ZAP [GraphQLError]:
  ///     code:<code>
  ///     message:<message>
  /// ```
  ///
  /// ### Example
  ///
  /// ```dart
  /// final error = GraphQLError(
  ///   code: 'NOT_FOUND',
  ///   message: 'User not found',
  /// );
  /// print(error);
  /// // Output:
  /// // ZAP [GraphQLError]:
  /// //     code:NOT_FOUND
  /// //     message:User not found
  /// ```
  ///
  /// ### Usage in logging
  ///
  /// ```dart
  /// for (final error in response.errors ?? []) {
  ///   Z.error(error.toString());
  /// }
  /// ```
  /// {@endtemplate}
  @override
  String toString() => 'ZAP [GraphQLError]:\n\tcode:$code\n\tmessage:$message';
}