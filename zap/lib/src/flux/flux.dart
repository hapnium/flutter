import '../definitions.dart';
import '../exceptions/zap_exception.dart';
import '../http/modifier/zap_modifier.dart';
import '../http/utils/http_method.dart';
import '../models/response/api_response.dart';
import '../core/zap_interface.dart';
import '../http/response/response.dart';
import '../models/flux_config.dart';
import '../models/cancel_token.dart';
import 'flux_interface.dart';
import 'extension.dart';
import 'client.dart';

/// {@template flux}
/// High-level HTTP client wrapper that provides authentication, session
/// management, and standardized API response handling.
///
/// `Flux` is the primary entry point for making HTTP requests in the
/// Zap ecosystem. It wraps the lower-level [Zap] client with automatic
/// authentication, session refresh, error handling, and logging.
///
/// ### Key features
///
/// - **Singleton pattern**: Only one instance can exist at a time
/// - **Configurable authentication**: Bearer tokens, API keys, custom headers
/// - **Session management**: Automatic token refresh on 401 errors
/// - **Error handling**: All exceptions converted to structured responses
/// - **Logging**: Configurable request, response, and error logging
/// - **Cancellation**: Per-request cancellation via [CancelToken]
/// - **Progress tracking**: Upload/download progress callbacks
/// - **Auto-disposal**: Optional cleanup after each request
///
/// ### Quick start
///
/// ```dart
/// // Initialize once
/// final flux = Flux(
///   config: FluxConfig(
///     zapConfig: ZapConfig(baseUrl: 'https://api.example.com'),
///     sessionFactory: () => getStoredSession(),
///     onSessionRefreshed: () => refreshSession(),
///     whenUnauthorized: () => navigateToLogin(),
///   ),
/// );
///
/// // Make requests
/// final response = await flux.get<User>(
///   endpoint: '/users/profile',
///   parser: (data) => User.fromJson(data),
/// );
/// ```
///
/// ### Response handling
///
/// All methods return `Response<ApiResponse>` which provides:
/// - `status`: HTTP status code
/// - `body`: [ApiResponse] with `isOk`, `message`, `data`
/// - `headers`: Response headers
///
/// ```dart
/// final response = await flux.get(endpoint: '/users/1');
///
/// if (response.body?.isOk == true) {
///   final user = response.body!.data;
/// } else {
///   _showError(response.body?.message);
/// }
/// ```
///
/// ### Cancellation
///
/// ```dart
/// final token = CancelToken();
/// final future = flux.get(endpoint: '/users/1', token: token);
///
/// // Cancel if needed
/// token.cancel('User navigated away');
/// ```
///
/// ### Disposal
///
/// Always dispose when done:
/// ```dart
/// Flux.dispose(); // cleans up resources
/// ```
/// {@endtemplate}
final class Flux implements FluxInterface {
  /// {@template flux_config}
  /// Configuration object containing all settings for the Flux client.
  ///
  /// This includes:
  /// - Authentication settings (header name, token prefix, builder)
  /// - Session management (factory, refresh callback, unauthorized hook)
  /// - Logging preferences (request, response, error logs)
  /// - Memory management (single instance, auto-disposal)
  /// - Underlying HTTP configuration ([ZapConfig])
  ///
  /// The config is immutable after initialization to ensure consistent
  /// behavior across all requests.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final config = FluxConfig(
  ///   zapConfig: ZapConfig(
  ///     baseUrl: 'https://api.example.com',
  ///     timeout: Duration(seconds: 30),
  ///   ),
  ///   authHeaderName: 'Authorization',
  ///   tokenPrefix: 'Bearer',
  ///   showRequestLogs: true,
  ///   showResponseLogs: true,
  /// );
  /// ```
  /// {@endtemplate}
  final FluxConfig config;

  /// Private constructor to enforce singleton pattern.
  ///
  /// Use [Flux] factory constructor or [Flux.instance] instead.
  /// {@macro flux}
  Flux._internal({required this.config});

  /// Static instance holder for singleton pattern.
  static Flux? _instance;

  /// {@template flux_factory}
  /// Factory constructor that implements singleton pattern.
  ///
  /// Creates a new [Flux] instance or throws if one already exists.
  /// This ensures that only one Flux client exists throughout the
  /// application lifecycle.
  ///
  /// ### Parameters
  ///
  /// - [config]: The [FluxConfig] containing all client settings.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: If an instance already exists. Use
  ///   [Flux.instance] to access the existing instance, or call
  ///   [Flux.dispose] first to create a new one.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final flux = Flux(
  ///   config: FluxConfig(
  ///     zapConfig: ZapConfig(baseUrl: 'https://api.example.com'),
  ///   ),
  /// );
  /// ```
  ///
  /// ### Singleton behavior
  ///
  /// ```dart
  /// final a = Flux(config: config); // creates instance
  /// final b = Flux(config: config); // throws ZapException
  ///
  /// Flux.dispose();
  /// final c = Flux(config: config); // creates new instance
  /// ```
  /// {@endtemplate}
  /// {@macro flux}
  factory Flux({required FluxConfig config}) {
    if (_instance != null) {
      throw ZapException(
        "Multiple instances of Flux detected. Only one instance is allowed. "
        "Use Flux.instance to access the existing instance or call Flux.dispose() "
        "before creating a new instance."
      );
    }
    _instance = Flux._internal(config: config);
    return _instance!;
  }

  /// {@template flux_instance}
  /// Gets the current singleton instance.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: If no instance has been created yet.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await Flux.instance.get(endpoint: '/users/1');
  /// ```
  ///
  /// ### Usage
  ///
  /// Use this to access the Flux client after initial creation:
  /// ```dart
  /// // In main.dart
  /// Flux(config: myConfig);
  ///
  /// // In any other file
  /// final response = await Flux.instance.get(endpoint: '/users');
  /// ```
  /// {@endtemplate}
  /// {@macro flux}
  static Flux get instance {
    if (_instance == null) {
      throw ZapException("No Flux instance found. Create an instance first using Flux(config: config).");
    }
    return _instance!;
  }

  /// {@template flux_dispose}
  /// Disposes the current singleton instance, allowing a new one to be
  /// created.
  ///
  /// This method:
  /// 1. Calls [onDelete] on the underlying client (triggers lifecycle
  ///   teardown)
  /// 2. Calls [dispose] on the underlying client (closes connections,
  ///   releases resources)
  /// 3. Sets the singleton instance to `null`
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Clean up when the app is shutting down
  /// Flux.dispose();
  /// ```
  ///
  /// ### When to call
  ///
  /// - App shutdown
  /// - Testing (to reset singleton state)
  /// - When you need to create a new instance with different config
  ///
  /// ### Idempotency
  ///
  /// Calling [dispose] when no instance exists is safe (no-op).
  /// {@endtemplate}
  static void dispose() {
    _instance?._client().onDelete();
    _instance?._client().dispose();
    _instance = null;
  }

  /// {@template flux_cancelAllRequests}
  /// Cancels all active requests using Zap's cancellation mechanism.
  ///
  /// This method cancels every in-flight request and clears the active
  /// token set. Useful for:
  /// - User logout (cancel all pending requests)
  /// - App backgrounding
  /// - Global abort scenarios
  ///
  /// ### Parameters
  ///
  /// - [reason]: A human-readable string describing why requests were
  ///   cancelled. Defaults to `'All requests cancelled'`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Cancel on user logout
  /// Flux.cancelAllRequests('User logged out');
  ///
  /// // Cancel on app backgrounding
  /// Flux.cancelAllRequests('App backgrounded');
  /// ```
  /// {@endtemplate}
  static void cancelAllRequests([String reason = 'All requests cancelled']) {
    _instance?._client().cancelAllRequests(reason);
  }

  /// Registers a global request modifier that applies to every request.
  ///
  /// This modifier is added to the underlying ZapClient and will be
  /// called before each request is sent.
  ///
  /// ## Example
  /// ```dart
  /// Flux.instance.addRequestModifier<void>((request) async {
  ///   request.headers['X-Request-ID'] = uuid();
  ///   return request;
  /// });
  /// ```
  void addRequestModifier<T>(RequestModifier<T> modifier) {
    _client().client.addRequestModifier<T>(modifier);
  }

  /// Registers a global response modifier that applies to every response.
  ///
  /// This modifier is added to the underlying ZapClient and will be
  /// called after each response is received.
  ///
  /// ## Example
  /// ```dart
  /// Flux.instance.addResponseModifier<void>((request, response) async {
  ///   final newToken = response.headers?['x-new-access-token'];
  ///   if (newToken != null && newToken.isNotEmpty) {
  ///     // Update stored token
  ///   }
  ///   return response;
  /// });
  /// ```
  void addResponseModifier<T>(ResponseModifier<T> modifier) {
    _client().client.addResponseModifier<T>(modifier);
  }

  /// Removes a previously registered global request modifier.
  void removeRequestModifier<T>(RequestModifier<T> modifier) {
    _client().client.removeRequestModifier<T>(modifier);
  }

  /// Removes a previously registered global response modifier.
  void removeResponseModifier<T>(ResponseModifier<T> modifier) {
    _client().client.removeResponseModifier<T>(modifier);
  }

  /// Gets the underlying Zap HTTP client.
  ///
  /// ### Parameters
  ///
  /// - [useAuth]: Whether to configure the client for authenticated
  ///   requests. Defaults to `false`.
  ///
  /// ### Returns
  ///
  /// A [ZapInterface] instance configured with [FluxConfig.zapConfig].
  ///
  /// ### Behavior
  ///
  /// If [FluxConfig.useSingleInstance] is `true`, returns a standard
  /// [Zap] client. If `false`, returns a [_Connect] client with
  /// integrated header and auth management.
  /// {@macro zap_interface}
  ZapInterface _client([bool useAuth = false]) => fluxClient(config, useAuth);

  /// {@macro flux_interface_delete}
  @override
  Future<Response<ApiResponse>> delete({required String endpoint, RequestParam? query, dynamic body, bool useAuth = true, CancelToken? token}) async {
    try {
      return config.execute((Headers? headers, CancelToken? cancelToken) => _client(useAuth).delete<ApiResponse>(
        endpoint,
        headers: headers, 
        query: query,
        cancelToken: cancelToken,
        decoder: config.decoder
      ), HttpMethod.DELETE, endpoint, useAuth, token);
    } finally {
      if(config.disposeOnCompleted) {
        dispose();
      }
    }
  }

  /// {@macro flux_interface_get}
  @override
  Future<Response<ApiResponse>> get({required String endpoint, RequestParam? query, bool useAuth = true, CancelToken? token}) async {
    try {
      return config.execute((Headers? headers, CancelToken? cancelToken) => _client(useAuth).get<ApiResponse>(
        endpoint,
        headers: headers, 
        query: query,
        cancelToken: cancelToken,
        decoder: config.decoder
      ), HttpMethod.GET, endpoint, useAuth, token);
    } finally {
      if(config.disposeOnCompleted) {
        dispose();
      }
    }
  }

  /// {@macro flux_interface_patch}
  @override
  Future<Response<ApiResponse>> patch({required String endpoint, dynamic body, RequestParam? query, Progress? onProgress, bool useAuth = true, CancelToken? token}) async {
    try {
      return config.execute((Headers? headers, CancelToken? cancelToken) => _client(useAuth).patch<ApiResponse>(
        endpoint, 
        body, 
        headers: headers, 
        query: query, 
        uploadProgress: onProgress, 
        cancelToken: cancelToken,
        decoder: config.decoder
      ), HttpMethod.PATCH, endpoint, useAuth, token);
    } finally {
      if(config.disposeOnCompleted) {
        dispose();
      }
    }
  }

  /// {@macro flux_interface_post}
  @override
  Future<Response<ApiResponse>> post({required String endpoint, dynamic body, RequestParam? query, Progress? onProgress, bool useAuth = true, CancelToken? token}) async {
    try {
      return config.execute((Headers? headers, CancelToken? cancelToken) => _client(useAuth).post<ApiResponse>(
        endpoint, 
        body, 
        headers: headers, 
        query: query, 
        uploadProgress: onProgress, 
        cancelToken: cancelToken,
        decoder: config.decoder
      ), HttpMethod.POST, endpoint, useAuth, token);
    } finally {
      if(config.disposeOnCompleted) {
        dispose();
      }
    }
  }

  /// {@macro flux_interface_put}
  @override
  Future<Response<ApiResponse>> put({required String endpoint, dynamic body, RequestParam? query, Progress? onProgress, bool useAuth = true, CancelToken? token}) async {
    try {
      return config.execute((Headers? headers, CancelToken? cancelToken) => _client(useAuth).put<ApiResponse>(
        endpoint, 
        body, 
        headers: headers, 
        query: query, 
        uploadProgress: onProgress, 
        cancelToken: cancelToken,
        decoder: config.decoder
      ), HttpMethod.PUT, endpoint, useAuth, token);
    } finally {
      if(config.disposeOnCompleted) {
        dispose();
      }
    }
  }
}