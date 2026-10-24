import '../exceptions/zap_exception.dart';
import '../http/client/zap_client.dart';
import '../http/request/request.dart';
import '../http/response/graphql_response.dart';
import '../http/response/response.dart';
import '../models/cancel_token.dart';
import '../models/zap_config.dart';
import 'zap_socket.dart';
import 'zap_interface.dart';
import '../definitions.dart';

/// {@template zap}
/// Core implementation of the Zap network client with full HTTP, WebSocket,
/// and GraphQL support, including request cancellation and lifecycle management.
///
/// `Zap` extends [ZapInterface] and provides the default, production-ready
/// implementation of all network operations. It encapsulates client-level
/// configuration (timeouts, headers, SSL settings, redirect policies) and
/// manages a set of active cancel tokens for request lifecycle control.
///
/// ### Key features
///
/// - **HTTP methods**: GET, POST, PUT, PATCH, DELETE, and custom requests
/// - **WebSocket support**: Platform-agnostic socket connections
/// - **GraphQL**: Query and mutation operations with structured responses
/// - **Cancellation**: Per-request and bulk cancellation via [CancelToken]
/// - **Lifecycle**: Structured initialization and teardown via [ZapLifecycle]
/// - **Configuration**: Centralized [ZapConfig] for all client settings
///
/// ### Quick start
/// ```dart
/// final zap = Zap(
///   zapConfig: ZapConfig(
///     baseUrl: 'https://api.example.com',
///     timeout: Duration(seconds: 15),
///   ),
/// );
///
/// // GET request
/// final users = await zap.get<List<User>>('/users');
///
/// // POST request with cancellation
/// final token = CancelToken();
/// final future = zap.post<User>('/users', {'name': 'John'}, cancelToken: token);
/// token.cancel('User navigated away');
///
/// // WebSocket
/// final socket = zap.socket('wss://example.com/ws');
/// socket.connect();
/// ```
///
/// ### Disposal
///
/// Always call [dispose] when the client is no longer needed to release
/// resources:
/// ```dart
/// zap.dispose(); // cancels requests, closes sockets, releases client
/// ```
///
/// ### Lifecycle hooks
///
/// `Zap` uses [ZapLifecycle] for structured initialization. If
/// `useLifecycle` is `true` (the default), [onStart] is called in the
/// constructor, triggering [onInit] → [onReady].
/// {@endtemplate}
class Zap extends ZapInterface {
  /// {@template zap_constructor}
  /// Creates a new instance of the Zap network client.
  ///
  /// ### Parameters
  ///
  /// - [zapConfig]: Optional configuration for the client. If `null`, a
  ///   default [ZapConfig] is used with no base URL and standard timeouts.
  /// - [zapClient]: Optional pre-configured HTTP client. If `null`, one
  ///   is lazily created from [zapConfig] on first use.
  /// - [zapSockets]: Optional initial list of WebSocket connections. If
  ///   `null`, an empty list is created on first use.
  /// - [useLifecycle]: Whether to trigger the [ZapLifecycle] initialization
  ///   sequence in the constructor. Defaults to `true`. Set to `false` if
  ///   you want to manually control initialization timing.
  ///
  /// ### Example
  /// ```dart
  /// // Default configuration
  /// final zap = Zap();
  ///
  /// // Custom configuration
  /// final zap = Zap(
  ///   zapConfig: ZapConfig(
  ///     baseUrl: 'https://api.example.com',
  ///     timeout: Duration(seconds: 30),
  ///     followRedirects: true,
  ///   ),
  /// );
  ///
  /// // Without lifecycle
  /// final zap = Zap(useLifecycle: false);
  /// // Manually initialize later
  /// zap.onStart();
  /// ```
  ///
  /// ### Lifecycle
  ///
  /// When `useLifecycle` is `true`, the constructor calls [onStart],
  /// which triggers [onInit] and schedules [onReady] for the next frame.
  /// If you need to override [onInit], create a subclass and pass
  /// `useLifecycle: false` to avoid double initialization.
  /// {@endtemplate}
  /// {@macro zap}
  Zap({super.zapConfig, super.zapClient, super.zapSockets, bool useLifecycle = true}) {
    if(useLifecycle) {
      onStart();
    }
  }

  /// Set of active cancel tokens for tracking ongoing requests.
  ///
  /// Tokens are added when a request begins and removed when it completes
  /// (success or failure) or when the token is cancelled.
  final Set<CancelToken> _activeTokens = <CancelToken>{};

  /// {@macro zap_interface_sockets}
  @override
  List<ZapSocket> get sockets => zapSockets ??= <ZapSocket>[];

  /// {@macro zap_interface_activeTokens}
  @override
  Set<CancelToken> get activeTokens => _activeTokens;

  /// {@macro zap_interface_config}
  @override
  ZapConfig get config => zapConfig ?? ZapConfig();

  /// {@macro zap_interface_client}
  ///
  /// The client is lazily created from [config] on first access. All
  /// configuration fields from [config] are forwarded to the [ZapClient]
  /// constructor.
  @override
  ZapClient get client => zapClient ??= ZapClient(
    userAgent: config.userAgent,
    sendUserAgent: config.sendUserAgent,
    timeout: config.timeout,
    followRedirects: config.followRedirects,
    maxRedirects: config.maxRedirects,
    maxAuthRetries: config.maxAuthRetries,
    allowAutoSignedCert: config.allowAutoSignedCert,
    baseUrl: config.baseUrl,
    trustedCertificates: config.trustedCertificates,
    withCredentials: config.withCredentials,
    findProxy: config.findProxy,
    enableCookies: config.enableCookies,
    errorSafety: config.errorSafety,
  );

  /// Registers a [CancelToken] as active and sets up automatic cleanup.
  ///
  /// When the token is cancelled (via its future completing or throwing),
  /// it is automatically removed from [_activeTokens].
  ///
  /// ### Parameters
  ///
  /// - [token]: The cancel token to register. If `null` or already
  ///   cancelled, this method is a no-op.
  void _registerCancelToken(CancelToken? token) {
    if (token != null && !token.isCancelled) {
      _activeTokens.add(token);
      
      // Remove token from active set when it's cancelled
      token.future.then((_) {
        _activeTokens.remove(token);
      }).catchError((_) {
        _activeTokens.remove(token);
      });
    }
  }

  /// {@macro zap_interface_cancelAllRequests}
  @override
  void cancelAllRequests([String reason = 'All requests cancelled']) {
    for (final token in _activeTokens) {
      token.cancel(reason);
    }
    _activeTokens.clear();
  }

  /// Executes a request with cancellation support.
  ///
  /// This internal method wraps the actual request execution and handles
  /// cancellation at three stages:
  /// 1. **Before execution**: If the token is already cancelled, throws
  ///    immediately.
  /// 2. **During execution**: If the token is cancelled while the request
  ///    is in flight, the request continues but the token is checked again
  ///    after completion.
  /// 3. **After execution**: If the token was cancelled during the request,
  ///    a [ZapException] is thrown.
  ///
  /// ### Parameters
  ///
  /// - [handler]: A closure that performs the actual HTTP request and
  ///   returns a `Future<Response<T>>`.
  /// - [token]: Optional cancel token. If `null`, no cancellation is
  ///   performed.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the response or throws
  /// a [ZapException] if the request is cancelled.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: If the request is cancelled or if the handler
  ///   throws a [ZapException].
  Future<Response<T>> _execute<T>(Future<Response<T>> Function() handler, CancelToken? token) async {
    _checkIfDisposed();
    
    // Register cancel token for tracking
    _registerCancelToken(token);
    
    // Check if cancelled before starting
    token?.throwIfCancelled();

    try {
      // Execute the request
      final response = await handler();
      
      // Check if cancelled after completion
      token?.throwIfCancelled();
      
      return response;
    } on ZapException {
      // Re-throw ZapExceptions (including cancellation exceptions)
      rethrow;
    } catch (_) {
      // Check if cancelled during error handling
      token?.throwIfCancelled();
      rethrow;
    }
  }

  /// {@macro zap_interface_get}
  @override
  Future<Response<T>> get<T>(String url, {
    Headers? headers,
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(
      () => client.get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
      cancelToken,
    );
  }

  /// {@macro zap_interface_post}
  @override
  Future<Response<T>> post<T>(String? url, RequestBody body, {
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(
      () => client.post<T>(
        url,
        body: body,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
      cancelToken,
    );
  }

  /// {@macro zap_interface_put}
  @override
  Future<Response<T>> put<T>(String url, RequestBody body, {
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(
      () => client.put<T>(
        url,
        body: body,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
      cancelToken,
    );
  }

  /// {@macro zap_interface_patch}
  @override
  Future<Response<T>> patch<T>(String url, RequestBody body, {
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(
      () => client.patch<T>(
        url,
        body: body,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
      cancelToken,
    );
  }

  /// {@macro zap_interface_request}
  @override
  Future<Response<T>> request<T>(String url, String method, {
    RequestBody body,
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(
      () => client.request<T>(
        url,
        method,
        body: body,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
      cancelToken,
    );
  }

  /// {@macro zap_interface_delete}
  @override
  Future<Response<T>> delete<T>(String url, {
    Headers? headers,
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(
      () => client.delete(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
      cancelToken,
    );
  }

  /// {@macro zap_interface_send}
  @override
  Future<Response<T>> send<T>(Request<T> request, {CancelToken? cancelToken}) {
    return _execute<T>(() => client.send(request), cancelToken);
  }

  /// {@macro zap_interface_socket}
  ///
  /// The socket URL is resolved against [config]'s `baseUrl` if one is set.
  /// The new socket is added to [sockets] for lifecycle management.
  @override
  ZapSocket socket(String url, { Duration ping = const Duration(seconds: 5)}) {
    _checkIfDisposed(isHttp: false);

    final newSocket = ZapSocket(_concatUrl(url)!, ping: ping);
    sockets.add(newSocket);
    return newSocket;
  }

  /// Resolves a URL against the configured base URL.
  ///
  /// If [url] is `null`, returns the base URL. If [config] has no base URL,
  /// returns [url] as-is. Otherwise, concatenates the base URL and [url].
  ///
  /// ### Parameters
  ///
  /// - [url]: The relative or absolute URL to resolve.
  ///
  /// ### Returns
  ///
  /// The resolved URL string, or `null` if both [url] and the base URL
  /// are `null`.
  String? _concatUrl(String? url) {
    if (url == null) {
      return config.baseUrl;
    }

    return config.baseUrl == null ? url : config.baseUrl! + url;
  }

  /// {@macro zap_interface_query}
  @override
  Future<GraphQLResponse<T>> query<T>(String query, {
    String? url,
    RequestParam? variables,
    Headers? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await post(
        url,
        {'query': query, 'variables': variables},
        headers: headers,
        cancelToken: cancelToken,
      );

      return GraphQLResponse.fromDynamic(res);
    } on Exception catch (err) {
      return GraphQLResponse.fromException(err);
    }
  }

  /// {@macro zap_interface_mutation}
  @override
  Future<GraphQLResponse<T>> mutation<T>(String mutation, {
    String? url,
    RequestParam? variables,
    Headers? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await post(
        url,
        {'query': mutation, 'variables': variables},
        headers: headers,
        cancelToken: cancelToken,
      );

      return GraphQLResponse.fromDynamic(res);
    } on Exception catch (err) {
      return GraphQLResponse.fromException(err);
    }
  }

  bool _isDisposed = false;

  /// {@macro zap_interface_isDisposed}
  @override
  bool get isDisposed => _isDisposed;

  /// Checks if the client has been disposed and throws if so.
  ///
  /// ### Parameters
  ///
  /// - [isHttp]: Whether this check is for an HTTP operation (default
  ///   `true`). The error message differs slightly for WebSocket
  ///   operations.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown with the message
  ///   `'Can not emit events to disposed clients'`.
  void _checkIfDisposed({bool isHttp = true}) {
    if (_isDisposed) {
      throw ZapException('Can not emit events to disposed clients');
    }
  }

  /// {@macro zap_interface_dispose}
  ///
  /// ### Disposal order
  ///
  /// Resources are released in the following order:
  /// 1. All active requests are cancelled via [cancelAllRequests].
  /// 2. All open WebSocket connections are closed.
  /// 3. The socket list is cleared.
  /// 4. The underlying HTTP client is closed.
  /// 5. Configuration references are nullified.
  /// 6. The `isDisposed` flag is set to `true`.
  /// 7. The lifecycle teardown is triggered via [onDelete].
  @override
  void dispose() {
    // Cancel all active requests before disposal
    cancelAllRequests('Zap client disposed');
    
    if (zapSockets != null) {
      for (var socket in zapSockets!) {
        socket.close();
      }
      zapSockets!.clear();
      zapSockets = null;
    }

    if (zapClient != null) {
      zapClient!.close();
      zapClient = null;
    }

    zapConfig = null;
    _isDisposed = true;

    sockets.clear();

    super.onDelete();
  }
}