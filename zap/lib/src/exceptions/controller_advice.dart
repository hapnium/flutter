import '../core/zap_inst.dart';
import '../enums/exception_type.dart';
import 'zap_exception.dart';

part 'exception_handler.dart';

/// {@template on_exception}
/// Signature for custom exception handler callbacks.
///
/// A function that accepts a [ZapException] and performs a specific action
/// (e.g., logging, retrying, showing a UI alert, redirecting to login).
///
/// Exception handlers are registered via [ControllerAdvice] or
/// [ExceptionHandler] and invoked when an exception of the matching
/// type is thrown.
///
/// ### Example
///
/// ```dart
/// final handler = OnException((e) {
///   Z.error('Request failed: ${e.message}');
///   _showErrorSnackbar(e.message);
/// });
/// ```
///
/// ### Parameters
///
/// - [exception]: The [ZapException] that was thrown. Contains the error
///   message, type, URI, status code, and other contextual information.
///
/// ### Return value
///
/// This function returns `void`. It is a side-effect callback, not a
/// transformer. If you need to transform exceptions, use a middleware
/// pattern instead.
/// {@endtemplate}
typedef OnException = void Function(ZapException exception);

/// {@template controller_advice}
/// Configuration class for registering centralized exception handlers,
/// inspired by Spring Boot's `@ControllerAdvice`.
///
/// `ControllerAdvice` allows you to register typed exception handlers for
/// each [ExceptionType] in one place, promoting clean separation between
/// business logic and error handling. When an exception is thrown during
/// an HTTP operation, the corresponding handler is invoked automatically.
///
/// ### Handler registration
///
/// Each [ExceptionType] has a corresponding optional callback parameter.
/// If provided, the callback is registered as the handler for that type.
/// If omitted, a default logger is registered when [enableLogging] is
/// `true`.
///
/// ### Example
///
/// ```dart
/// final advice = ControllerAdvice(
///   onTimeout: (e) {
///     Z.warn('Request timed out: ${e.uri}');
///     _showRetryDialog();
///   },
///   onAuth: (e) {
///     _navigateToLogin();
///   },
///   onServer: (e) {
///     _reportToSentry(e);
///   },
///   enableLogging: true, // logs unhandled types
/// );
///
/// // Use the handler
/// final handler = advice.handler;
/// handler.handle(someException);
/// ```
///
/// ### Default logging
///
/// When [enableLogging] is `true` (the default), any exception type
/// without a registered handler gets a default logger that prints the
/// exception with an emoji prefix:
///
/// ```
/// ⏱️  TIMEOUT: Request timed out after 30s
/// 🌐 NETWORK: No internet connection
/// 🔥 SERVER: Internal server error
/// ```
///
/// ### Integration with ZapClient
///
/// `ControllerAdvice` is designed to work with `ZapClient`'s exception
/// handling pipeline:
/// ```dart
/// final zap = Zap(
///   zapConfig: config,
///   controllerAdvice: ControllerAdvice(
///     onAuth: (e) => _refreshToken(),
///   ),
/// );
/// ```
/// {@endtemplate}
class ControllerAdvice {
  /// {@template controller_advice_onTimeout}
  /// Optional custom handler for timeout exceptions.
  ///
  /// Invoked when a request exceeds the configured timeout threshold.
  /// The exception has type [ExceptionType.timeout].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onTimeout: (e) {
  ///   Z.warn('Timeout for ${e.uri}');
  ///   _showRetryDialog();
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Show a retry dialog
  /// - Log the timeout for monitoring
  /// - Increase the timeout for subsequent requests
  /// {@endtemplate}
  final OnException? onTimeout;

  /// {@template controller_advice_onNetwork}
  /// Optional custom handler for network exceptions.
  ///
  /// Invoked when a network-level failure occurs (no internet, DNS
  /// failure, socket error). The exception has type
  /// [ExceptionType.network].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onNetwork: (e) {
  ///   _showOfflineBanner();
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Show an offline indicator
  /// - Queue the request for retry when connectivity returns
  /// - Switch to cached data
  /// {@endtemplate}
  final OnException? onNetwork;

  /// {@template controller_advice_onServer}
  /// Optional custom handler for server-side exceptions (HTTP 5xx).
  ///
  /// Invoked when the server returns a 5xx status code. The exception
  /// has type [ExceptionType.server] and includes the [statusCode].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onServer: (e) {
  ///   if (e.statusCode == 503) {
  ///     _showMaintenanceMessage();
  ///   } else {
  ///     _reportToSentry(e);
  ///   }
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Report to error tracking (Sentry, Bugsnag)
  /// - Show a "service unavailable" message
  /// - Retry with exponential backoff for transient errors (502, 503, 504)
  /// {@endtemplate}
  final OnException? onServer;

  /// {@template controller_advice_onClient}
  /// Optional custom handler for client-side exceptions (HTTP 4xx).
  ///
  /// Invoked when the server returns a 4xx status code. The exception
  /// has type [ExceptionType.client] and includes the [statusCode].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onClient: (e) {
  ///   if (e.statusCode == 404) {
  ///     _showNotFoundPage();
  ///   } else if (e.statusCode == 422) {
  ///     _showValidationErrors(e.details);
  ///   }
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Show validation errors (422)
  /// - Navigate to a not-found page (404)
  /// - Show a "forbidden" message (403)
  /// - Rate limit warnings (429)
  /// {@endtemplate}
  final OnException? onClient;

  /// {@template controller_advice_onAuth}
  /// Optional custom handler for authentication/authorization exceptions.
  ///
  /// Invoked when credentials are missing, invalid, or expired. The
  /// exception has type [ExceptionType.auth].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onAuth: (e) {
  ///   _clearAuthToken();
  ///   _navigateToLogin();
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Refresh the access token
  /// - Redirect to the login page
  /// - Clear stored credentials
  /// - Show a "session expired" message
  /// {@endtemplate}
  final OnException? onAuth;

  /// {@template controller_advice_onSSL}
  /// Optional custom handler for SSL/certificate exceptions.
  ///
  /// Invoked when the TLS handshake fails or certificate validation
  /// fails. The exception has type [ExceptionType.ssl].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onSSL: (e) {
  ///   Z.fatal('SSL error: ${e.message}');
  ///   _showCertificateErrorDialog();
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Log the certificate details for debugging
  /// - Show a security warning to the user
  /// - In development: allow self-signed certificates
  ///
  /// ### Security note
  ///
  /// Never silently bypass SSL errors in production. This indicates a
  /// potential security issue.
  /// {@endtemplate}
  final OnException? onSSL;

  /// {@template controller_advice_onConnection}
  /// Optional custom handler for TCP connection exceptions.
  ///
  /// Invoked when the TCP connection to the server fails (connection
  /// refused, connection reset, etc.). The exception has type
  /// [ExceptionType.connection].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onConnection: (e) {
  ///   Z.warn('Connection failed: ${e.uri}');
  ///   _scheduleReconnect();
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Retry with exponential backoff
  /// - Check server health
  /// - Switch to a fallback server
  /// {@endtemplate}
  final OnException? onConnection;

  /// {@template controller_advice_onDNS}
  /// Optional custom handler for DNS resolution exceptions.
  ///
  /// Invoked when the system cannot resolve a domain name. The exception
  /// has type [ExceptionType.dns].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onDNS: (e) {
  ///   Z.error('DNS failed for: ${e.uri}');
  ///   _showOfflineMessage();
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Check DNS configuration
  /// - Switch to a backup domain
  /// - Queue for retry when DNS resolves
  /// {@endtemplate}
  final OnException? onDNS;

  /// {@template controller_advice_onParsing}
  /// Optional custom handler for response parsing exceptions.
  ///
  /// Invoked when the response body cannot be deserialized into the
  /// expected type. The exception has type [ExceptionType.parsing].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onParsing: (e) {
  ///   Z.error('Parse error: ${e.message}');
  ///   _reportAPIContractViolation(e);
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Log the raw response for debugging
  /// - Report API contract violations
  /// - Use a fallback/default value
  /// {@endtemplate}
  final OnException? onParsing;

  /// {@template controller_advice_onCancelled}
  /// Optional custom handler for cancelled request exceptions.
  ///
  /// Invoked when a request is cancelled via [CancelToken]. The exception
  /// has type [ExceptionType.cancelled].
  ///
  /// ### Example
  ///
  /// ```dart
  /// onCancelled: (e) {
  ///   Z.debug('Request cancelled: ${e.uri}');
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Log for analytics (how often users cancel)
  /// - Clean up partial state
  /// - Usually a no-op (cancellation is expected)
  ///
  /// ### Note
  ///
  /// Cancellation is typically an expected behavior, not an error. This
  /// handler is provided for completeness but is often left as `null`.
  /// {@endtemplate}
  final OnException? onCancelled;

  /// {@template controller_advice_onUnknown}
  /// Optional fallback handler for unclassified exceptions.
  ///
  /// Invoked when an exception does not match any registered type-specific
  /// handler. This serves as the catch-all for unexpected error types.
  ///
  /// ### Example
  ///
  /// ```dart
  /// onUnknown: (e) {
  ///   Z.fatal('Unexpected error: ${e.toString()}');
  ///   _reportToSentry(e);
  /// },
  /// ```
  ///
  /// ### Common actions
  /// - Log the full exception details
  /// - Report to error tracking
  /// - Show a generic error message
  ///
  /// ### Priority
  ///
  /// If both [onUnknown] and [enableLogging] are set, [onUnknown] takes
  /// precedence. The default logger is only used when [onUnknown] is
  /// `null` and [enableLogging] is `true`.
  /// {@endtemplate}
  final OnException? onUnknown;

  /// {@template controller_advice_enableLogging}
  /// Whether to enable default console logging for all exception types
  /// that do not have a registered handler.
  ///
  /// When `true`, any exception type without a specific handler gets a
  /// default logger that prints the exception with an emoji prefix:
  ///
  /// ```
  /// ⏱️  TIMEOUT: Request timed out
  /// 🌐 NETWORK: Connection refused
  /// ```
  ///
  /// When `false`, unhandled exceptions are silently ignored (unless
  /// [onUnknown] is set).
  ///
  /// Defaults to `true`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Disable all default logging
  /// ControllerAdvice(enableLogging: false);
  ///
  /// // Enable default logging (default behavior)
  /// ControllerAdvice(enableLogging: true);
  /// ```
  /// {@endtemplate}
  final bool enableLogging;

  /// {@template controller_advice_handler}
  /// The internal [ExceptionHandler] instance configured with all
  /// registered callbacks.
  ///
  /// Use this to access the handler for integration with `ZapClient`
  /// or for manual exception handling:
  ///
  /// ```dart
  /// final advice = ControllerAdvice(...);
  /// advice.handler.handle(someException);
  /// ```
  ///
  /// This field is initialized during construction and should not be
  /// modified afterwards.
  /// {@endtemplate}
  late final ExceptionHandler handler;

  /// {@template controller_advice_constructor}
  /// Constructs a [ControllerAdvice] and registers all provided handlers.
  ///
  /// ### Parameters
  ///
  /// - [onTimeout]: Handler for [ExceptionType.timeout] exceptions.
  /// - [onNetwork]: Handler for [ExceptionType.network] exceptions.
  /// - [onServer]: Handler for [ExceptionType.server] exceptions.
  /// - [onClient]: Handler for [ExceptionType.client] exceptions.
  /// - [onAuth]: Handler for [ExceptionType.auth] exceptions.
  /// - [onSSL]: Handler for [ExceptionType.ssl] exceptions.
  /// - [onConnection]: Handler for [ExceptionType.connection] exceptions.
  /// - [onDNS]: Handler for [ExceptionType.dns] exceptions.
  /// - [onParsing]: Handler for [ExceptionType.parsing] exceptions.
  /// - [onCancelled]: Handler for [ExceptionType.cancelled] exceptions.
  /// - [onUnknown]: Fallback handler for unclassified exceptions.
  /// - [enableLogging]: Whether to register default loggers for
  ///   unhandled types. Defaults to `true`.
  ///
  /// ### Behavior
  ///
  /// 1. An [ExceptionHandler] is created with [onUnknown] as the default
  ///    handler (or a default logger if [enableLogging] is `true`).
  /// 2. All non-null type-specific handlers are registered.
  /// 3. If [enableLogging] is `true`, default loggers are registered for
  ///   any types that still lack a handler.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final advice = ControllerAdvice(
  ///   onTimeout: (e) => _retryRequest(e.uri),
  ///   onAuth: (e) => _navigateToLogin(),
  ///   enableLogging: true,
  /// );
  /// ```
  /// {@endtemplate}
  /// {@macro controller_advice}
  ControllerAdvice({
    this.onTimeout,
    this.onNetwork,
    this.onServer,
    this.onClient,
    this.onAuth,
    this.onSSL,
    this.onConnection,
    this.onDNS,
    this.onParsing,
    this.onCancelled,
    this.onUnknown,
    this.enableLogging = true,
  }) {
    handler = ExceptionHandler(
      defaultHandler: onUnknown ?? (enableLogging ? _defaultLogger : null),
    );

    _registerAllHandlers();
    if (enableLogging) _registerDefaultLoggersIfMissing();
  }

  /// Registers all provided type-specific handlers with the internal
  /// [ExceptionHandler].
  ///
  /// Each non-null callback is registered for its corresponding
  /// [ExceptionType]. Null callbacks are skipped.
  void _registerAllHandlers() {
    if (onTimeout != null) handler.registerHandler(ExceptionType.timeout, onTimeout!);
    if (onNetwork != null) handler.registerHandler(ExceptionType.network, onNetwork!);
    if (onServer != null) handler.registerHandler(ExceptionType.server, onServer!);
    if (onClient != null) handler.registerHandler(ExceptionType.client, onClient!);
    if (onAuth != null) handler.registerHandler(ExceptionType.auth, onAuth!);
    if (onSSL != null) handler.registerHandler(ExceptionType.ssl, onSSL!);
    if (onConnection != null) handler.registerHandler(ExceptionType.connection, onConnection!);
    if (onDNS != null) handler.registerHandler(ExceptionType.dns, onDNS!);
    if (onParsing != null) handler.registerHandler(ExceptionType.parsing, onParsing!);
    if (onCancelled != null) handler.registerHandler(ExceptionType.cancelled, onCancelled!);
  }

  /// Registers default emoji-prefixed loggers for any exception types
  /// that do not already have a handler registered.
  ///
  /// Each default logger calls [Z.log] with an emoji prefix and the
  /// exception message:
  /// ```
  /// ⏱️  TIMEOUT: Request timed out
  /// 🌐 NETWORK: Connection refused
  /// ```
  void _registerDefaultLoggersIfMissing() {
    final defaultHandlers = <ExceptionType, OnException>{
      ExceptionType.timeout: (e) => Z.log('⏱️  TIMEOUT: ${e.message}'),
      ExceptionType.network: (e) => Z.log('🌐 NETWORK: ${e.message}'),
      ExceptionType.server: (e) => Z.log('🔥 SERVER: ${e.message}'),
      ExceptionType.client: (e) => Z.log('❌ CLIENT: ${e.message}'),
      ExceptionType.auth: (e) => Z.log('🔐 AUTH: ${e.message}'),
      ExceptionType.ssl: (e) => Z.log('🔒 SSL: ${e.message}'),
      ExceptionType.connection: (e) => Z.log('🔌 CONNECTION: ${e.message}'),
      ExceptionType.dns: (e) => Z.log('🌍 DNS: ${e.message}'),
      ExceptionType.parsing: (e) => Z.log('📝 PARSING: ${e.message}'),
      ExceptionType.cancelled: (e) => Z.log('🚫 CANCELLED: ${e.message}'),
    };

    for (final entry in defaultHandlers.entries) {
      if (!handler._handlers.containsKey(entry.key)) {
        handler.registerHandler(entry.key, entry.value);
      }
    }
  }

  /// Default logger used as the fallback handler when [onUnknown] is
  /// `null` and [enableLogging] is `true`.
  ///
  /// Logs the full exception string with a magnifying glass emoji prefix.
  static void _defaultLogger(ZapException e) {
    Z.log('🔍 ZAP EXCEPTION: ${e.toString()}');
  }

  /// Dispatches the given [ZapException] to the appropriate handler.
  ///
  /// This is a convenience method that delegates to [handler].handle].
  ///
  /// ### Parameters
  ///
  /// - [e]: The exception to handle. The handler is selected based on
  ///   [e.type].
  ///
  /// ### Example
  ///
  /// ```dart
  /// try {
  ///   await zap.get('/users');
  /// } on ZapException catch (e) {
  ///   advice.onException(e);
  /// }
  /// ```
  void onException(ZapException e) {
    handler.handle(e);
  }
}