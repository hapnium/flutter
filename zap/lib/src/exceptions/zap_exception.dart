import '../enums/exception_type.dart';

/// {@template zap_exception}
/// A comprehensive, structured exception thrown by `ZapClient` during
/// HTTP, WebSocket, and GraphQL operations.
///
/// `ZapException` provides a unified error model for all network and API
/// failures. It encapsulates contextual information including the error
/// message, [ExceptionType], request URI, HTTP status code, and optional
/// diagnostic details.
///
/// ### Key features
///
/// - **Typed exceptions**: Each exception has a strongly-typed [ExceptionType]
///   for programmatic handling
/// - **Convenience constructors**: Factory constructors for each exception
///   type (`.timeout`, `.network`, `.server`, etc.)
/// - **Type checks**: Boolean getters (`.isTimeout`, `.isNetwork`, etc.)
///   for quick type inspection
/// - **Retry detection**: The [isRetryable] getter determines if the
///   exception can be retried
/// - **Serialization**: The [toMap] method converts the exception to a
///   JSON-compatible map for logging or analytics
///
/// ### Example
///
/// ```dart
/// try {
///   final response = await zap.get<User>('/users/1');
/// } on ZapException catch (e) {
///   if (e.isRetryable) {
///     _retryRequest(e.uri);
///   } else if (e.isAuth) {
///     _navigateToLogin();
///   } else {
///     _showError(e.message);
///   }
/// }
/// ```
///
/// ### Exception hierarchy
///
/// `ZapException` implements `Exception` (not `Error`), so it can be
/// caught with `catch` blocks. It does not extend `Error` because most
/// network failures are recoverable and should not crash the application.
/// {@endtemplate}
class ZapException implements Exception {
  /// {@template zap_exception_message}
  /// A human-readable description of the error.
  ///
  /// This is the primary error message and should provide enough context
  /// to diagnose the issue without looking at the stack trace.
  ///
  /// ### Examples
  ///
  /// - `"Request timed out after 30s"`
  /// - `"Connection refused to api.example.com:443"`
  /// - `"HTTP 500: Internal Server Error"`
  /// - `"SSL certificate validation failed"`
  ///
  /// ### Usage
  ///
  /// ```dart
  /// print('Error: ${e.message}');
  /// _showErrorSnackbar(e.message);
  /// ```
  /// {@endtemplate}
  final String message;

  /// {@template zap_exception_uri}
  /// The URI of the HTTP request that caused the exception, if available.
  ///
  /// This is the full URL of the request, including the base URL and path.
  /// It is `null` for exceptions that occur before a request is made
  /// (e.g., client initialization errors).
  ///
  /// ### Examples
  ///
  /// - `https://api.example.com/users/1`
  /// - `wss://example.com/ws`
  /// - `null` (for client-level errors)
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (e.uri != null) {
  ///   Z.error('Failed request to ${e.uri}');
  /// }
  /// ```
  /// {@endtemplate}
  final Uri? uri;

  /// {@template zap_exception_type}
  /// A strongly-typed [ExceptionType] categorizing the nature of the error.
  ///
  /// This is the primary mechanism for programmatic error handling. Each
  /// exception type maps to a specific failure category with different
  /// retry and recovery strategies.
  ///
  /// ### Types
  ///
  /// - [ExceptionType.timeout]: Request exceeded time limit
  /// - [ExceptionType.network]: No internet connection
  /// - [ExceptionType.server]: HTTP 5xx error
  /// - [ExceptionType.client]: HTTP 4xx error
  /// - [ExceptionType.auth]: Authentication failure
  /// - [ExceptionType.cancelled]: Request was cancelled
  /// - [ExceptionType.ssl]: SSL/TLS error
  /// - [ExceptionType.connection]: TCP connection failure
  /// - [ExceptionType.dns]: DNS resolution failure
  /// - [ExceptionType.parsing]: Response parsing error
  /// - [ExceptionType.unknown]: Unclassified error
  ///
  /// ### Usage
  ///
  /// ```dart
  /// switch (e.type) {
  ///   case ExceptionType.network:
  ///     _showOfflineBanner();
  ///   case ExceptionType.auth:
  ///     _navigateToLogin();
  ///   default:
  ///     _showGenericError();
  /// }
  /// ```
  /// {@endtemplate}
  final ExceptionType type;

  /// {@template zap_exception_statusCode}
  /// The HTTP status code returned by the server, if applicable.
  ///
  /// This is `null` for exceptions that occur before a response is received
  /// (e.g., network errors, timeouts) or for non-HTTP operations.
  ///
  /// ### Examples
  ///
  /// - `200` (successful but with GraphQL errors)
  /// - `400` (Bad Request)
  /// - `401` (Unauthorized)
  /// - `404` (Not Found)
  /// - `500` (Internal Server Error)
  /// - `null` (no response received)
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (e.statusCode != null) {
  ///   Z.error('HTTP ${e.statusCode} for ${e.uri}');
  /// }
  /// ```
  /// {@endtemplate}
  final int? statusCode;

  /// {@template zap_exception_details}
  /// Additional metadata or context related to the error.
  ///
  /// This is a flexible map for attaching structured data to the exception.
  /// Common uses include:
  ///
  /// - Validation error details (field-level errors)
  /// - Server-provided error metadata
  /// - Request/response context
  /// - Diagnostic information
  ///
  /// ### Examples
  ///
  /// ```json
  /// {
  ///   "field": "email",
  ///   "constraint": "already_exists",
  ///   "value": "user@example.com"
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (e.details != null) {
  ///   final fieldErrors = e.details!['fields'];
  ///   _showValidationErrors(fieldErrors);
  /// }
  /// ```
  ///
  /// ### Null safety
  ///
  /// This field is nullable. Not all exceptions include details.
  /// {@endtemplate}
  final Map<String, dynamic>? details;

  /// {@template zap_exception_originalException}
  /// The original exception that caused this [ZapException], if applicable.
  ///
  /// This preserves the original error for debugging purposes. It is
  /// useful when you need to inspect the underlying cause or access
  /// platform-specific error information.
  ///
  /// ### Examples
  ///
  /// - `SocketException` (for network errors)
  /// - `TimeoutException` (for timeouts)
  /// - `FormatException` (for parsing errors)
  /// - `HttpException` (for HTTP errors)
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (e.originalException != null) {
  ///   Z.error('Original error: ${e.originalException}');
  /// }
  /// ```
  ///
  /// ### Debugging
  ///
  /// The original exception often contains platform-specific details
  /// that are not captured in the [message]:
  /// ```dart
  /// if (e.originalException is SocketException) {
  ///   final socketError = e.originalException as SocketException;
  ///   print('OS error: ${socketError.osError}');
  /// }
  /// ```
  /// {@endtemplate}
  final Exception? originalException;

  /// {@template zap_exception_originalStackTrace}
  /// The stack trace of the original exception, useful for logging or
  /// debugging.
  ///
  /// This preserves the call stack at the time the original error occurred.
  /// It is invaluable for debugging because it shows the exact sequence
  /// of function calls that led to the error.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Z.error(
  ///   'Request failed: ${e.message}',
  ///   error: e.originalException,
  ///   stackTrace: e.originalStackTrace,
  /// );
  /// ```
  ///
  /// ### Null safety
  ///
  /// This field is nullable. The stack trace is only available when the
  /// exception is created from a caught error.
  /// {@endtemplate}
  final StackTrace? originalStackTrace;

  /// {@template zap_exception_constructor}
  /// Main constructor for [ZapException].
  ///
  /// Use this constructor when creating exceptions directly or from
  /// custom handlers. For convenience, use the named constructors
  /// (`.timeout`, `.network`, etc.) which set the [type] automatically.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description (required).
  /// - [uri]: Request URI that caused the error (optional).
  /// - [type]: Exception category. Defaults to [ExceptionType.unknown].
  /// - [statusCode]: HTTP status code (optional).
  /// - [details]: Additional metadata (optional).
  /// - [originalException]: The underlying exception (optional).
  /// - [originalStackTrace]: Stack trace of the original error (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// final e = ZapException(
  ///   'Request failed',
  ///   Uri.parse('https://api.example.com/users'),
  ///   ExceptionType.server,
  ///   500,
  ///   {'retry_count': 3},
  /// );
  /// ```
  ///
  /// ### Named constructors
  ///
  /// Prefer the named constructors for readability:
  /// ```dart
  /// ZapException.timeout('Timed out', uri);
  /// ZapException.network('No connection', uri);
  /// ZapException.server('Server error', 500, uri);
  /// ```
  /// {@endtemplate}
  /// {@macro zap_exception}
  ZapException(
    this.message, [
    this.uri,
    this.type = ExceptionType.unknown,
    this.statusCode,
    this.details,
    this.originalException,
    this.originalStackTrace,
  ]);

  /// {@template zap_exception_timeout}
  /// Creates a timeout-related exception.
  ///
  /// The exception has type [ExceptionType.timeout]. Timeout exceptions
  /// are typically retryable.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI that timed out (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.timeout(
  ///   'Request timed out after 30s',
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// Yes -- timeouts are typically transient.
  /// {@endtemplate}
  ZapException.timeout(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.timeout, null, details);

  /// {@template zap_exception_network}
  /// Creates a network failure exception (no internet, DNS failure, etc.).
  ///
  /// The exception has type [ExceptionType.network]. Network exceptions
  /// are typically retryable.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI that failed (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.network(
  ///   'No internet connection',
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// Yes -- network issues are typically transient.
  /// {@endtemplate}
  ZapException.network(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.network, null, details);

  /// {@template zap_exception_server}
  /// Creates an exception for server-side errors (HTTP 5xx).
  ///
  /// The exception has type [ExceptionType.server] and includes the
  /// HTTP [statusCode]. Server errors with codes 502, 503, and 504
  /// are typically retryable.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [statusCode]: HTTP status code (e.g., 500, 502, 503, 504).
  /// - [uri]: Request URI (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.server(
  ///   'Internal Server Error',
  ///   500,
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// Depends on the status code:
  /// - 502, 503, 504: Yes (transient)
  /// - 500: No (persistent)
  /// {@endtemplate}
  ZapException.server(String message, int statusCode, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.server, statusCode, details);

  /// {@template zap_exception_client}
  /// Creates an exception for client-side errors (HTTP 4xx).
  ///
  /// The exception has type [ExceptionType.client] and includes the
  /// HTTP [statusCode]. Client errors are generally not retryable
  /// because the issue is with the request, not the server.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [statusCode]: HTTP status code (e.g., 400, 401, 403, 404, 422).
  /// - [uri]: Request URI (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.client(
  ///   'Validation failed',
  ///   422,
  ///   Uri.parse('https://api.example.com/users'),
  ///   {'field': 'email', 'error': 'already_exists'},
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// Generally no -- the request needs to be fixed. Exceptions:
  /// - 408 (Request Timeout): May be retryable
  /// - 429 (Too Many Requests): Retry after delay
  /// {@endtemplate}
  ZapException.client(String message, int statusCode, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.client, statusCode, details);

  /// {@template zap_exception_auth}
  /// Creates an authentication or authorization failure exception.
  ///
  /// The exception has type [ExceptionType.auth]. Authentication errors
  /// are not retryable -- they require re-authentication (token refresh,
  /// login, etc.).
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI (optional).
  /// - [statusCode]: HTTP status code (optional, typically 401 or 403).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.auth(
  ///   'Access token expired',
  ///   Uri.parse('https://api.example.com/users'),
  ///   401,
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- requires re-authentication.
  /// {@endtemplate}
  ZapException.auth(String message, [Uri? uri, int? statusCode, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.auth, statusCode, details);

  /// {@template zap_exception_cancelled}
  /// Creates an exception for cancelled requests.
  ///
  /// The exception has type [ExceptionType.cancelled]. Cancellation is
  /// typically an expected behavior, not an error.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable cancellation reason.
  /// - [uri]: Request URI (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.cancelled(
  ///   'User navigated away',
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- the cancellation was intentional.
  ///
  /// ### Handling
  ///
  /// Cancellation exceptions are typically caught and silently ignored:
  /// ```dart
  /// try {
  ///   final response = await zap.get<User>('/users/1');
  /// } on ZapException catch (e) {
  ///   if (e.isCancelled) return;
  ///   rethrow;
  /// }
  /// ```
  /// {@endtemplate}
  ZapException.cancelled(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.cancelled, null, details);

  /// {@template zap_exception_ssl}
  /// Creates an SSL/TLS handshake or certificate failure exception.
  ///
  /// The exception has type [ExceptionType.ssl]. SSL errors are not
  /// retryable -- they indicate a certificate or configuration issue.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.ssl(
  ///   'Certificate validation failed: hostname mismatch',
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- the certificate issue must be resolved.
  ///
  /// ### Security note
  ///
  /// SSL errors should never be silently bypassed. They indicate a
  /// potential security issue (man-in-the-middle attack, expired
  /// certificate, etc.).
  /// {@endtemplate}
  ZapException.ssl(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.ssl, null, details);

  /// {@template zap_exception_connection}
  /// Creates a TCP connection failure exception.
  ///
  /// The exception has type [ExceptionType.connection]. Connection
  /// exceptions are typically retryable.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.connection(
  ///   'Connection refused to api.example.com:443',
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// Yes -- connection issues are typically transient.
  ///
  /// ### Distinction from [network]
  ///
  /// - [network]: No internet connectivity at all
  /// - [connection]: Internet works, but this specific connection failed
  /// {@endtemplate}
  ZapException.connection(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.connection, null, details);

  /// {@template zap_exception_dns}
  /// Creates a DNS resolution failure exception.
  ///
  /// The exception has type [ExceptionType.dns]. DNS exceptions may be
  /// retryable if the issue is transient (e.g., DNS server temporarily
  /// unreachable).
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI whose hostname could not be resolved (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.dns(
  ///   'Failed to resolve api.example.com',
  ///   Uri.parse('https://api.example.com/users'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// Maybe -- depends on whether the DNS issue is transient.
  /// {@endtemplate}
  ZapException.dns(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.dns, null, details);

  /// {@template zap_exception_parsing}
  /// Creates an exception for response parsing/deserialization failures.
  ///
  /// The exception has type [ExceptionType.parsing]. Parsing errors are
  /// not retryable -- the issue is with the data format, not the network.
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable error description.
  /// - [uri]: Request URI (optional).
  /// - [details]: Additional metadata (optional).
  ///
  /// ### Example
  ///
  /// ```dart
  /// throw ZapException.parsing(
  ///   'Unexpected JSON structure: missing "name" field',
  ///   Uri.parse('https://api.example.com/users/1'),
  /// );
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- the issue is with the data format, not the network.
  ///
  /// ### Common causes
  ///
  /// - Server returned HTML instead of JSON (error page)
  /// - API contract changed without client update
  /// - Unexpected null values
  /// - Encoding mismatches
  /// {@endtemplate}
  ZapException.parsing(String message, [Uri? uri, Map<String, dynamic>? details])
      : this(message, uri, ExceptionType.parsing, null, details);

  // ---------------------------------------------------------------
  // Convenience type checks
  // ---------------------------------------------------------------

  /// {@template zap_exception_isTimeout}
  /// Whether this exception is a timeout error.
  ///
  /// Equivalent to `type == ExceptionType.timeout`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isTimeout) {
  ///   _showRetryDialog();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// Yes.
  /// {@endtemplate}
  bool get isTimeout => type == ExceptionType.timeout;

  /// {@template zap_exception_isNetwork}
  /// Whether this exception is a network connectivity error.
  ///
  /// Equivalent to `type == ExceptionType.network`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isNetwork) {
  ///   _showOfflineBanner();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// Yes.
  /// {@endtemplate}
  bool get isNetwork => type == ExceptionType.network;

  /// {@template zap_exception_isServer}
  /// Whether this exception is a server-side error (HTTP 5xx).
  ///
  /// Equivalent to `type == ExceptionType.server`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isServer) {
  ///   _reportToSentry(e);
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// Depends on [statusCode]: 502, 503, 504 are retryable; 500 is not.
  /// {@endtemplate}
  bool get isServer => type == ExceptionType.server;

  /// {@template zap_exception_isClient}
  /// Whether this exception is a client-side error (HTTP 4xx).
  ///
  /// Equivalent to `type == ExceptionType.client`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isClient && e.statusCode == 404) {
  ///   _showNotFoundPage();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// Generally no.
  /// {@endtemplate}
  bool get isClient => type == ExceptionType.client;

  /// {@template zap_exception_isAuth}
  /// Whether this exception is an authentication/authorization error.
  ///
  /// Equivalent to `type == ExceptionType.auth`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isAuth) {
  ///   _refreshTokenOrLogin();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- requires re-authentication.
  /// {@endtemplate}
  bool get isAuth => type == ExceptionType.auth;

  /// {@template zap_exception_isCancelled}
  /// Whether this exception represents a cancelled request.
  ///
  /// Equivalent to `type == ExceptionType.cancelled`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isCancelled) {
  ///   return; // silently ignore
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- the cancellation was intentional.
  /// {@endtemplate}
  bool get isCancelled => type == ExceptionType.cancelled;

  /// {@template zap_exception_isSSL}
  /// Whether this exception is an SSL/TLS certificate error.
  ///
  /// Equivalent to `type == ExceptionType.ssl`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isSSL) {
  ///   _showCertificateErrorDialog();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- the certificate issue must be resolved.
  /// {@endtemplate}
  bool get isSSL => type == ExceptionType.ssl;

  /// {@template zap_exception_isConnection}
  /// Whether this exception is a TCP connection failure.
  ///
  /// Equivalent to `type == ExceptionType.connection`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isConnection) {
  ///   _scheduleReconnect();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// Yes.
  /// {@endtemplate}
  bool get isConnection => type == ExceptionType.connection;

  /// {@template zap_exception_isDNS}
  /// Whether this exception is a DNS resolution failure.
  ///
  /// Equivalent to `type == ExceptionType.dns`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isDNS) {
  ///   _switchToBackupDomain();
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// Maybe -- depends on whether the DNS issue is transient.
  /// {@endtemplate}
  bool get isDNS => type == ExceptionType.dns;

  /// {@template zap_exception_isParsing}
  /// Whether this exception is a response parsing error.
  ///
  /// Equivalent to `type == ExceptionType.parsing`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isParsing) {
  ///   _reportAPIContractViolation(e);
  /// }
  /// ```
  ///
  /// ### Retryable
  ///
  /// No -- the issue is with the data format.
  /// {@endtemplate}
  bool get isParsing => type == ExceptionType.parsing;

  /// {@template zap_exception_isRetryable}
  /// Whether this exception can be retried.
  ///
  /// Returns `true` for transient failures that may succeed on a
  /// subsequent attempt. Returns `false` for permanent or intentional
  /// failures.
  ///
  /// ### Retryable types
  ///
  /// - [ExceptionType.network]: Always retryable
  /// - [ExceptionType.timeout]: Always retryable
  /// - [ExceptionType.connection]: Always retryable
  /// - [ExceptionType.dns]: Always retryable
  /// - [ExceptionType.server]: Retryable only for codes 502, 503, 504
  ///
  /// ### Non-retryable types
  ///
  /// - [ExceptionType.client]: Generally not retryable
  /// - [ExceptionType.auth]: Requires re-authentication
  /// - [ExceptionType.cancelled]: Cancellation was intentional
  /// - [ExceptionType.ssl]: Certificate issue must be resolved
  /// - [ExceptionType.parsing]: Data format issue
  /// - [ExceptionType.unknown]: Conservative default (not retryable)
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (e.isRetryable) {
  ///   _retryWithBackoff(e.uri);
  /// } else {
  ///   _showError(e.message);
  /// }
  /// ```
  ///
  /// ### Retry strategy
  ///
  /// Even for retryable exceptions, use exponential backoff:
  /// ```dart
  /// int attempt = 0;
  /// Future<void> retryWithBackoff() async {
  ///   try {
  ///     await zap.get('/users');
  ///   } on ZapException catch (e) {
  ///     if (e.isRetryable && attempt < 3) {
  ///       attempt++;
  ///       final delay = Duration(seconds: (1 << attempt));
  ///       await Future.delayed(delay);
  ///       return retryWithBackoff();
  ///     }
  ///     rethrow;
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  bool get isRetryable {
    switch (type) {
      case ExceptionType.network:
      case ExceptionType.timeout:
      case ExceptionType.connection:
      case ExceptionType.dns:
        return true;
      case ExceptionType.server:
        return statusCode == 502 || statusCode == 503 || statusCode == 504;
      default:
        return false;
    }
  }

  /// {@template zap_exception_toString}
  /// Returns a formatted string representation of the exception.
  ///
  /// The format is:
  /// ```
  /// ZapException [<TYPE>]: <message> (URL: <uri>) (Status: <statusCode>) (Details: <details>)
  /// ```
  ///
  /// Only non-null fields are included in the output.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final e = ZapException.server('Error', 500, Uri.parse('https://api.example.com'));
  /// print(e);
  /// // Output: ZapException [SERVER]: Error (URL: https://api.example.com) (Status: 500)
  /// ```
  ///
  /// ### Usage in logging
  ///
  /// ```dart
  /// Z.error(e.toString());
  /// ```
  /// {@endtemplate}
  @override
  String toString() {
    final buffer = StringBuffer('ZapException [${type.name.toUpperCase()}]: $message');
    
    if (uri != null) buffer.write(' (URL: $uri)');
    if (statusCode != null) buffer.write(' (Status: $statusCode)');
    if (details != null && details!.isNotEmpty) buffer.write(' (Details: $details)');
    
    return buffer.toString();
  }

  /// {@template zap_exception_toMap}
  /// Converts this exception into a serializable map format.
  ///
  /// Useful for logging, error reporting, or analytics pipelines. The
  /// returned map contains only non-null fields and is JSON-compatible.
  ///
  /// ### Returned keys
  ///
  /// - `'message'`: The error message (always present)
  /// - `'uri'`: Request URI as string (if present)
  /// - `'type'`: Exception type name (always present)
  /// - `'statusCode'`: HTTP status code (if present)
  /// - `'details'`: Additional metadata (if present)
  /// - `'isRetryable'`: Whether the exception can be retried (always present)
  ///
  /// ### Example
  ///
  /// ```dart
  /// final e = ZapException.timeout('Timed out', Uri.parse('https://api.example.com'));
  /// final map = e.toMap();
  /// // {
  /// //   'message': 'Timed out',
  /// //   'uri': 'https://api.example.com',
  /// //   'type': 'timeout',
  /// //   'statusCode': null,
  /// //   'details': null,
  /// //   'isRetryable': true,
  /// // }
  /// ```
  ///
  /// ### Usage in analytics
  ///
  /// ```dart
  /// analytics.track('api_error', properties: e.toMap());
  /// ```
  ///
  /// ### Usage in error reporting
  ///
  /// ```dart
  /// Sentry.captureException(
  ///   e,
  ///   stackTrace: e.originalStackTrace,
  ///   extra: e.toMap(),
  /// );
  /// ```
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'uri': uri?.toString(),
      'type': type.name,
      'statusCode': statusCode,
      'details': details,
      'isRetryable': isRetryable,
    };
  }
}