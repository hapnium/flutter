import '../core/zap_inst.dart';
import '../definitions.dart';
import '../enums/exception_type.dart';
import '../exceptions/controller_advice.dart';
import '../exceptions/zap_exception.dart';
import '../http/utils/http_headers.dart';
import '../models/response/api_response.dart';
import '../http/response/response.dart';
import '../http/utils/http_status.dart';
import '../models/flux_config.dart';
import '../models/response/session_response.dart';
import '../models/cancel_token.dart';

/// {@template request_executor}
/// Type definition for a request executor function with cancellation support.
///
/// A request executor is a closure that performs the actual HTTP request
/// and returns a `Future<Response<ApiResponse>>`. It is passed to
/// [FluxConfigExtension.execute] to abstract the request implementation
/// away from the common flow (auth, logging, error handling).
///
/// ### Parameters
///
/// - [headers]: Optional map of HTTP headers to include. May be `null`
///   when [FluxConfig.useSingleInstance] is `false` (headers are managed
///   by the client).
/// - [cancelToken]: Optional token to cancel the request.
///
/// ### Returns
///
/// A `Future<Response<ApiResponse>>` containing the server response.
///
/// ### Example
///
/// ```dart
/// RequestExecutor execute = (headers, cancelToken) async {
///   return client.get<ApiResponse>(
///     '/users/1',
///     headers: headers,
///     cancelToken: cancelToken,
///     decoder: config.decoder,
///   );
/// };
/// ```
/// {@endtemplate}
typedef RequestExecutor = Future<Response<ApiResponse>> Function(Headers? headers, CancelToken? cancelToken);

/// {@template flux_config_extension}
/// Extension on [FluxConfig] that provides the core execution engine for
/// all Flux HTTP operations.
///
/// This extension adds methods for:
/// - Building authentication headers
/// - Validating authentication requirements
/// - Handling session refresh on 401 errors
/// - Executing requests with full error handling
/// - Converting exceptions to structured [Response] objects
///
/// ### Architecture
///
/// The extension is the bridge between [Flux] (the public API) and
/// [Zap] (the underlying HTTP client). It handles all the cross-cutting
/// concerns (auth, logging, error handling) so that [Flux] methods
/// remain clean and focused.
///
/// ### Request flow
///
/// ```
/// Flux.get()
///   → FluxConfigExtension.execute()
///     → checkAuth()          (validate session)
///     → buildHeaders()       (construct headers)
///     → buildHeadersWithAuth() (add auth token)
///     → execute()            (run the request)
///     → handle 401           (retry with refreshed session)
///     → handleException()    (convert errors to Response)
///     → _log()               (log the response)
/// ```
/// {@endtemplate}
extension FluxConfigExtension on FluxConfig {
  /// {@template flux_config_extension_adviser}
  /// Adviser instance for handling exceptions and logging.
  ///
  /// Returns the configured [ControllerAdvice] if one was provided in
  /// [FluxConfig], otherwise creates a new default instance.
  ///
  /// The adviser is notified of every exception via [handleException]
  /// and can perform custom handling (logging, retrying, alerts).
  /// {@endtemplate}
  ControllerAdvice get _adviser => controllerAdvice ?? ControllerAdvice();
  
  /// {@template flux_config_extension_currentSession}
  /// Gets the current session, always fetching the latest from the
  /// session factory.
  ///
  /// This ensures that the session is always up-to-date by calling the
  /// [FluxConfig.sessionFactory] callback if provided. If no factory
  /// is set, returns `null`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final session = config.currentSession;
  /// if (session != null) {
  ///   print('Current token: ${session.accessToken}');
  /// }
  /// ```
  ///
  /// ### Session freshness
  ///
  /// This getter calls the factory on every access, ensuring you always
  /// get the most recent session. This is important for token rotation
  /// scenarios where the session may change between requests.
  /// {@endtemplate}
  SessionResponse? get currentSession {
    if (sessionFactory != null) {
      return sessionFactory!();
    }
    return null;
  }

  /// {@template flux_config_extension_buildHeadersWithAuth}
  /// Builds authentication headers based on the configuration.
  ///
  /// This method supports three modes of authentication header generation:
  ///
  /// ### Mode 1: Custom header builder (highest priority)
  ///
  /// If [FluxConfig.authHeaderBuilder] is provided, it is called with
  /// the current session and its result is used directly:
  /// ```dart
  /// FluxConfig(
  ///   authHeaderBuilder: (session) => {
  ///     'Authorization': 'Bearer ${session.accessToken}',
  ///     'X-Tenant-ID': session.userId.toString(),
  ///   },
  /// )
  /// ```
  ///
  /// ### Mode 2: Configurable header name and prefix
  ///
  /// If no custom builder is set, uses [FluxConfig.authHeaderName] and
  /// [FluxConfig.tokenPrefix]:
  /// ```dart
  /// FluxConfig(
  ///   authHeaderName: 'X-API-Key',    // header name
  ///   tokenPrefix: '',                  // no prefix
  /// )
  /// // Generates: X-API-Key: <token>
  /// ```
  ///
  /// ### Mode 3: Default Bearer format
  ///
  /// With default settings:
  /// ```dart
  /// FluxConfig()
  /// // Generates: Authorization: Bearer <token>
  /// ```
  ///
  /// ### Parameters
  ///
  /// - [session]: Optional session to use. If `null`, uses
  ///   [currentSession].
  ///
  /// ### Returns
  ///
  /// A map of header name to header value. Empty if no session is
  /// available or the access token is empty.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final headers = config.buildHeadersWithAuth();
  /// // {'Authorization': 'Bearer eyJhbGci...'}
  /// ```
  /// {@endtemplate}
  Headers buildHeadersWithAuth({SessionResponse? session}) {
    session ??= currentSession;
    Headers headers = {};

    if (session != null) {
      // Use custom auth header builder if provided
      if (authHeaderBuilder != null) {
        headers = authHeaderBuilder!(session);
      } else {
        // Use configurable header name and token prefix
        final token = session.accessToken;
        if (token.isEmpty) {
          headers = {};
        }

        final headerValue = tokenPrefix.isEmpty ? token : '$tokenPrefix $token';

        headers = {authHeaderName: headerValue};
      }
    }

    ___log(headers);
    
    return headers;
  }

  /// {@template flux_config_extension_checkAuth}
  /// Validates authentication requirements for the request.
  ///
  /// Throws a [ZapException] if [useAuth] is `true` but no session is
  /// available. This prevents requests from being sent without required
  /// authentication.
  ///
  /// ### Parameters
  ///
  /// - [useAuth]: Whether authentication is required for this request.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: If `useAuth` is `true` and [currentSession] is
  ///   `null`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// try {
  ///   config.checkAuth(true);
  /// } on ZapException catch (e) {
  ///   _navigateToLogin();
  /// }
  /// ```
  /// {@endtemplate}
  void checkAuth(bool useAuth) {
    if (useAuth && currentSession == null) {
      throw ZapException(
        "Session is required to continue with authenticated requests. "
        "Please provide a valid session in the config or through sessionFactory callback."
      );
    }
  }

  /// {@template flux_config_extension_buildHeaders}
  /// Builds a complete header map by merging configuration headers with
  /// any additional headers passed to the method.
  ///
  /// Headers are merged in this order:
  /// 1. [FluxConfig.headers] (global configuration headers)
  /// 2. [additionalHeaders] (request-specific headers)
  ///
  /// Later headers overwrite earlier ones if keys conflict.
  ///
  /// ### Parameters
  ///
  /// - [additionalHeaders]: Optional headers to merge with the
  ///   configured headers.
  ///
  /// ### Returns
  ///
  /// A merged map of all headers.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Config: FluxConfig(headers: {'X-App-Version': '1.0'})
  /// final headers = config.buildHeaders({'X-Request-ID': 'abc'});
  /// // {'X-App-Version': '1.0', 'X-Request-ID': 'abc'}
  /// ```
  /// {@endtemplate}
  Headers buildHeaders([Headers? additionalHeaders]) {
    final headers = <String, String>{};
    
    // Add base headers from config
    if (this.headers != null) {
      headers.addAll(this.headers!);
    }
    
    // Add any additional headers passed to the method
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  /// {@template flux_config_extension_handleSessionRefresh}
  /// Handles session refresh when authentication fails.
  ///
  /// This method is called when a request returns HTTP 401 Unauthorized.
  /// It attempts to refresh the session using the [FluxConfig.onSessionRefreshed]
  /// callback.
  ///
  /// ### Flow
  ///
  /// 1. Check if [onSessionRefreshed] is configured
  /// 2. Call the callback to get a new session
  /// 3. Log the result if logging is enabled
  /// 4. Return the new session (or `null` on failure)
  ///
  /// ### Returns
  ///
  /// A `Future<SessionResponse?>` containing the refreshed session, or
  /// `null` if the refresh failed or is not configured.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final newSession = await config.handleSessionRefresh();
  /// if (newSession != null) {
  ///   // Retry the request with new session
  /// } else {
  ///   // Refresh failed, redirect to login
  /// }
  /// ```
  ///
  /// ### Error handling
  ///
  /// If the refresh callback throws, the error is caught and logged.
  /// The method returns `null` in this case, allowing the caller to
  /// handle the failure gracefully.
  /// {@endtemplate}
  Future<SessionResponse?> handleSessionRefresh() async {
    if (onSessionRefreshed != null) {
      try {
        final session = await onSessionRefreshed!();
        if(session != null) {
          if (showResponseLogs) {
            Z.log('Flux: Session refreshed successfully');
          }

          return session;
        }
      } catch (e) {
        if (showErrorLogs) {
          Z.log('Flux: Session refresh failed: $e');
        }

        return null;
      }
    }
    return null;
  }

  /// Logs request information if request logging is enabled.
  ///
  /// ### Parameters
  ///
  /// - [method]: The HTTP method (e.g., `'GET'`, `'POST'`).
  /// - [endpoint]: The API endpoint path.
  /// - [query]: Optional query parameters.
  void __log(String method, String endpoint, RequestParam? query) {
    if (showRequestLogs) {
      Z.log('Flux Request: $method $endpoint');
      if (query != null && query.isNotEmpty) {
        Z.log('Flux Query: $query');
      }
    }
  }

  /// Logs header information if header logging is enabled.
  ///
  /// ### Parameters
  ///
  /// - [headers]: The headers to log.
  void ___log(Headers headers) {
    if (showRequestLogs) {
      Z.log('Flux Headers: $headers');
    }
  }

  /// Logs response information if response logging is enabled.
  ///
  /// ### Parameters
  ///
  /// - [response]: The response to log.
  void _log<T>(Response<ApiResponse> response) {
    if (showResponseLogs) {
      Z.log('Flux Response: ${response.status} - ${response.body?.status} - ${response.body?.message}');
    }
  }

  /// {@template flux_config_extension_handleException}
  /// Handles an [Exception] and returns a structured [Response<ApiResponse>]
  /// based on the exception type.
  ///
  /// This method converts any exception into a standardized response
  /// object, ensuring that the caller always receives a consistent
  /// response format regardless of the error type.
  ///
  /// ### Flow
  ///
  /// 1. Convert to [ZapException] if not already
  /// 2. Log the exception if [showErrorLogs] is `true`
  /// 3. Notify the [ControllerAdvice] adviser
  /// 4. Create an appropriate [Response] based on exception type
  ///
  /// ### Parameters
  ///
  /// - [e]: The exception to handle.
  ///
  /// ### Returns
  ///
  /// A [Response<ApiResponse>] with appropriate status code, message,
  /// and error body.
  ///
  /// ### Exception to response mapping
  ///
  /// | Exception type | HTTP status | Message |
  /// |----------------|-------------|---------|
  /// | timeout        | 408         | Request timed out |
  /// | network        | 0           | Network unavailable |
  /// | server         | 5xx         | Server error |
  /// | client         | 4xx         | Client error |
  /// | auth           | 401         | Authentication required |
  /// | ssl            | 0           | SSL error |
  /// | connection     | 0           | Connection failed |
  /// | dns            | 0           | DNS resolution failed |
  /// | parsing        | 422         | Parsing error |
  /// | cancelled      | 0           | Request cancelled |
  /// | unknown        | 500         | Unexpected error |
  /// {@endtemplate}
  Response<ApiResponse> handleException(Exception e) {
    ZapException zapException;
    
    // Convert to ZapException if not already
    if (e is ZapException) {
      zapException = e;
    } else {
      zapException = ZapException(e.toString());
    }

    // Log if enabled
    if (showErrorLogs) {
      Z.log('[ZAP PULSE] Exception: $zapException');
    }

    // Always notify the adviser about the exception
    _adviser.onException(zapException);

    // Return appropriate response based on exception type
    return _createApiResponseForException(zapException);
  }

  /// Creates an appropriate [Response<ApiResponse>] for each [ExceptionType].
  ///
  /// Each exception type is mapped to a specific HTTP status code, user-
  /// friendly message, and diagnostic headers.
  ///
  /// ### Parameters
  ///
  /// - [exception]: The [ZapException] to convert.
  ///
  /// ### Returns
  ///
  /// A [Response<ApiResponse>] with:
  /// - `status`: Mapped HTTP status code
  /// - `message`: User-friendly error description
  /// - `body`: [ApiResponse.error] with the original error message
  /// - `headers`: Diagnostic headers (X-Error-Type, X-Status-Code, etc.)
  Response<ApiResponse> _createApiResponseForException(ZapException exception) {
    switch (exception.type) {
      case ExceptionType.timeout:
        return Response<ApiResponse>(
          status: HttpStatus.REQUEST_TIMEOUT,
          message: 'Request timed out. Please try again.',
          body: ApiResponse.error('Request timeout: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'timeout'
          },
        );

      case ExceptionType.network:
        return Response<ApiResponse>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Network connection unavailable. Check your internet connection.',
          body: ApiResponse.error('Network error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'network'
          },
        );

      case ExceptionType.server:
        return Response<ApiResponse>(
          status: HttpStatus.fromCode(exception.statusCode ?? 500),
          message: 'Server error occurred. Please try again later.',
          body: ApiResponse.error('Server error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'server',
            HttpHeaders.X_STATUS_CODE: '${exception.statusCode ?? 500}'
          },
        );

      case ExceptionType.client:
        return Response<ApiResponse>(
          status: HttpStatus.fromCode(exception.statusCode ?? 400),
          message: 'Client request error. Please check your request.',
          body: ApiResponse.error('Client error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'client',
            HttpHeaders.X_STATUS_CODE: '${exception.statusCode ?? 400}'
          },
        );

      case ExceptionType.auth:
        return Response<ApiResponse>(
          status: HttpStatus.UNAUTHORIZED,
          message: 'Authentication required. Please login again.',
          body: ApiResponse.error('Authentication error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'auth',
            HttpHeaders.X_AUTH_REQUIRED: 'true'
          },
        );

      case ExceptionType.ssl:
        return Response<ApiResponse>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Secure connection failed. Certificate or SSL error.',
          body: ApiResponse.error('SSL error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'ssl',
            HttpHeaders.X_SECURITY_ERROR: 'true'
          },
        );

      case ExceptionType.connection:
        return Response<ApiResponse>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Cannot connect to server. Server may be down.',
          body: ApiResponse.error('Connection error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'connection',
            HttpHeaders.X_RETRY_AFTER: '30'
          },
        );

      case ExceptionType.dns:
        return Response<ApiResponse>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Cannot resolve server address. Check your DNS settings.',
          body: ApiResponse.error('DNS error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'dns',
            HttpHeaders.X_DNS_ERROR: 'true'
          },
        );

      case ExceptionType.parsing:
        return Response<ApiResponse>(
          status: HttpStatus.UNPROCESSABLE_ENTITY,
          message: 'Cannot parse server response. Invalid data format.',
          body: ApiResponse.error('Parsing error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'parsing',
            HttpHeaders.X_CONTENT_ERROR: 'true'
          },
        );

      case ExceptionType.cancelled:
        return Response<ApiResponse>(
          status: HttpStatus.REQUEST_CANCELLED,
          message: 'Request was cancelled.',
          body: ApiResponse.error('Request cancelled: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'cancelled',
            HttpHeaders.X_CANCELLED: 'true'
          },
        );

      default:
        return Response<ApiResponse>(
          status: HttpStatus.INTERNAL_SERVER_ERROR,
          message: 'An unexpected error occurred. Please try again.',
          body: ApiResponse.error('Unknown error: ${exception.message}'),
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'unknown',
            HttpHeaders.X_UNEXPECTED_ERROR: 'true'
          },
        );
    }
  }

  /// {@template flux_config_extension_unauthorized}
  /// Creates an unauthorized response.
  ///
  /// This method is used to create a standardized 401 Unauthorized
  /// response when authentication fails and cannot be recovered.
  ///
  /// ### Returns
  ///
  /// A [Response<ApiResponse>] with status 401 and an unauthorized
  /// error body.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (session == null) {
  ///   return config.unauthorized();
  /// }
  /// ```
  /// {@endtemplate}
  Response<ApiResponse> unauthorized() {
    return Response<ApiResponse>(
      status: HttpStatus.UNAUTHORIZED,
      headers: {},
      body: ApiResponse.unauthorized('Unable to complete request due to authentication failure'),
    );
  }

  /// Retries a request after session refresh.
  ///
  /// This method is called when a request returns 401 Unauthorized and
  /// a session refresh is attempted. It builds new headers with the
  /// refreshed session and re-executes the request.
  ///
  /// ### Parameters
  ///
  /// - [execute]: The request executor to retry.
  /// - [cancelToken]: Optional cancellation token.
  /// - [useAuth]: Whether to include auth headers. Defaults to `true`.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing the retried response.
  ///
  /// ### Behavior
  ///
  /// 1. Call [handleSessionRefresh] to get a new session
  /// 2. If successful, rebuild headers and retry the request
  /// 3. If failed, return an unauthorized response
  /// 4. If the retry also returns 401, call [FluxConfig.whenUnauthorized]
  Future<Response<ApiResponse>> _retryRequest(RequestExecutor execute, CancelToken? cancelToken, {bool useAuth = true}) async {
    final newSession = await handleSessionRefresh();
    Response<ApiResponse> response;

    if (newSession != null) {
      // Retry the request with new session
      final headers = buildHeaders();
      if (useAuth) {
        headers.addAll(buildHeadersWithAuth(session: newSession));
      }
      response = await execute(headers, cancelToken);
    } else {
      response = unauthorized();
    }

    _log(response);

    if(response.status == HttpStatus.UNAUTHORIZED) {
      whenUnauthorized?.call();
    }

    return response;
  }

  /// {@template flux_config_extension_execute}
  /// Executes an HTTP request with authentication, error handling, and
  /// logging.
  ///
  /// This is the core execution engine for all Flux HTTP operations.
  /// It handles the common flow:
  ///
  /// 1. Validates authentication requirements
  /// 2. Builds headers with configurable authentication
  /// 3. Executes the request
  /// 4. Handles 401 errors with session refresh
  /// 5. Logs request/response if enabled
  /// 6. Converts exceptions to structured responses
  ///
  /// ### Parameters
  ///
  /// - [execute]: The request executor that performs the actual HTTP call.
  /// - [method]: The HTTP method name (e.g., `'GET'`, `'POST'`).
  /// - [endpoint]: The API endpoint path.
  /// - [useAuth]: Whether to include authentication headers.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing the server response.
  ///
  /// ### Behavior by mode
  ///
  /// **Single instance mode** (`useSingleInstance: true`):
  /// - Headers are built from [buildHeaders] and [buildHeadersWithAuth]
  /// - Request is executed with the built headers
  /// - 401 errors trigger session refresh and retry
  ///
  /// **Multi-instance mode** (`useSingleInstance: false`):
  /// - Headers are `null` (managed by the client's request modifiers)
  /// - Request is executed directly
  /// - 401 errors trigger session refresh and retry
  ///
  /// ### Error handling
  ///
  /// All exceptions ([ZapException] and general [Exception]) are caught
  /// and converted to structured responses via [handleException].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await config.execute(
  ///   (headers, cancelToken) => client.get<ApiResponse>(
  ///     '/users/1',
  ///     headers: headers,
  ///     cancelToken: cancelToken,
  ///   ),
  ///   'GET',
  ///   '/users/1',
  ///   true,
  ///   null,
  /// );
  /// ```
  /// {@endtemplate}
  Future<Response<ApiResponse>> execute(RequestExecutor execute, String method, String endpoint, bool useAuth, CancelToken? cancelToken) async {
    __log(method, endpoint, null);
    Response<ApiResponse> response;

    if(useSingleInstance) {
      checkAuth(useAuth);

      try {
        final headers = buildHeaders();

        if(useAuth) {
          headers.addAll(buildHeadersWithAuth());
        }

        response = await execute(headers, cancelToken);
        
        // Handle HttpStatus.UNAUTHORIZED Unauthorized - attempt session refresh
        if (response.status == HttpStatus.UNAUTHORIZED && useAuth) {
          response = await _retryRequest(execute, cancelToken, useAuth: useAuth);
        }
      } on ZapException catch (e) {
        response = handleException(e);
      } on Exception catch (e) {
        response = handleException(e);
      }
    } else {
      try {
        response = await execute(null, cancelToken);

        if (response.status == HttpStatus.UNAUTHORIZED && useAuth) {
          response = await _retryRequest(execute, cancelToken, useAuth: useAuth);
        }
      } on ZapException catch (e) {
        response = handleException(e);
      } on Exception catch (e) {
        response = handleException(e);
      }
    }

    _log(response);
    return response;
  }

  /// {@template flux_config_extension_decoder}
  /// Creates a decoder function for [ApiResponse] with custom data parsing.
  ///
  /// This getter returns a [ResponseDecoder] that deserializes JSON data
  /// into an [ApiResponse] object. It is used internally by [Flux] to
  /// ensure consistent response parsing.
  ///
  /// ### Returns
  ///
  /// A [ResponseDecoder<ApiResponse>] that parses dynamic JSON into
  /// [ApiResponse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final decoder = config.decoder;
  /// final apiResponse = decoder(jsonData);
  /// ```
  /// {@endtemplate}
  ResponseDecoder<ApiResponse> get decoder => (dynamic data) => ApiResponse.fromJson(data);
}