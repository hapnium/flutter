import '../http/client/zap_client.dart';
import '../http/request/request.dart';
import '../http/response/graphql_response.dart';
import '../http/response/response.dart';
import '../models/cancel_token.dart';
import '../models/zap_config.dart';
import 'zap_socket.dart';
import 'zap_lifecycle.dart';
import '../definitions.dart';

/// {@template zap_interface}
/// Abstract contract that defines all HTTP and WebSocket operations for a Zap
/// client, including request cancellation, lifecycle management, and resource
/// disposal.
///
/// `ZapInterface` is the primary abstraction that both the default [Zap]
/// implementation and any custom or test doubles must implement. It mixes in
/// [ZapLifecycle] to provide structured initialization and teardown hooks.
///
/// ### Responsibility
///
/// This interface enforces a consistent API surface across all Zap client
/// implementations. Consumers program against this type rather than a concrete
/// class, enabling dependency injection and testability.
///
/// ### Cancellation model
///
/// Every HTTP method accepts an optional [CancelToken] parameter. When a
/// request is cancelled via [CancelToken.cancel], the method throws a
/// [ZapException] with the cancellation reason. Tokens are tracked in
/// [activeTokens] for bulk cancellation via [cancelAllRequests].
///
/// ### Lifecycle
///
/// Because [ZapInterface] mixes in [ZapLifecycle], implementations gain
/// access to the [onInit], [onReady], [onClose], and [onDelete] hooks.
/// Call [onStart] to trigger initialization or [onDelete] to trigger
/// teardown.
///
/// ### Example
/// ```dart
/// class MyZapClient extends ZapInterface {
///   MyZapClient({required ZapConfig config}) : super(zapConfig: config);
///
///   @override
///   Future<Response<T>> get<T>(String url, { ... }) async { ... }
///   // ... implement remaining abstract members
/// }
/// ```
/// {@endtemplate}
abstract class ZapInterface with ZapLifecycle {
  /// {@template zap_interface_zapConfig}
  /// The configuration object controlling the behavior of this Zap client
  /// instance.
  ///
  /// Contains all client-level settings including base URL, default headers,
  /// timeout duration, SSL options, redirect policies, and proxy configuration.
  ///
  /// This is typically provided once at construction time and should not be
  /// mutated after initialization. If `null`, the client uses a default
  /// [ZapConfig] with no base URL and standard timeouts.
  ///
  /// ### Example
  /// ```dart
  /// final config = ZapConfig(
  ///   baseUrl: 'https://api.example.com',
  ///   timeout: Duration(seconds: 15),
  ///   allowAutoSignedCert: false,
  /// );
  /// final zap = Zap(zapConfig: config);
  /// ```
  /// {@endtemplate}
  /// {@macro zap_interface}
  ZapConfig? zapConfig;

  /// {@template zap_interface_zapClient}
  /// Internal reference to the underlying HTTP client instance.
  ///
  /// This is lazily initialized or injected by the concrete implementation.
  /// The [client] getter provides the canonical accessor; this field stores
  /// the backing reference.
  ///
  /// Implementations should initialize this in the constructor or on first
  /// access. After disposal, this should be set to `null` to release
  /// resources.
  /// {@endtemplate}
  ZapClient? zapClient;

  /// {@template zap_interface_zapSockets}
  /// Internal list of active WebSocket connections managed by this client.
  ///
  /// Populated automatically when [socket] is called. On [dispose], all
  /// sockets in this list are closed and the list is cleared.
  ///
  /// This field is `null` until the first WebSocket is created. Use [sockets]
  /// for the canonical accessor that lazily initializes the list.
  /// {@endtemplate}
  List<ZapSocket>? zapSockets;

  /// {@template zap_interface_constructor}
  /// Creates a new [ZapInterface] instance with optional configuration,
  /// client, and socket list.
  ///
  /// ### Parameters
  ///
  /// - [zapConfig]: Optional configuration for the client. If `null`, a
  ///   default [ZapConfig] is used.
  /// - [zapClient]: Optional pre-configured HTTP client. If `null`, the
  ///   concrete implementation should lazily create one from [zapConfig].
  /// - [zapSockets]: Optional initial list of WebSocket connections. If
  ///   `null`, an empty list is created on first access.
  ///
  /// ### Example
  /// ```dart
  /// final client = ZapInterface(
  ///   zapConfig: ZapConfig(baseUrl: 'https://api.example.com'),
  /// );
  /// ```
  /// {@endtemplate}
  /// {@macro zap_interface}
  ZapInterface({this.zapConfig, this.zapClient, this.zapSockets});

  /// {@template zap_interface_sockets}
  /// Canonical accessor for the list of active WebSocket connections.
  ///
  /// Lazily initializes [zapSockets] if it is `null`. This list is managed
  /// internally and should not be modified directly by consumers.
  ///
  /// ### Example
  /// ```dart
  /// final socketCount = client.sockets.length;
  /// ```
  /// {@endtemplate}
  List<ZapSocket>? sockets;

  /// {@template zap_interface_client}
  /// Returns the underlying [ZapClient] instance used for HTTP operations.
  ///
  /// This getter is the canonical way to access the HTTP client. It should
  /// return the same instance that [get], [post], [put], [patch], [delete],
  /// [request], and [send] delegate to.
  ///
  /// The returned client is configured from [config] and should be reusable
  /// across multiple requests. After [dispose], this getter should throw or
  /// return a closed client.
  ///
  /// ### Example
  /// ```dart
  /// final response = await client.client.get('/health');
  /// ```
  ///
  /// ### Implementation notes
  ///
  /// - The client should be lazily initialized from [config] on first access.
  /// - The client should share a single connection pool across all requests.
  /// - Subclasses should override this getter to provide a custom [ZapClient].
  /// {@endtemplate}
  ZapClient get client;

  /// {@template zap_interface_activeTokens}
  /// Set of [CancelToken] instances for all currently active (in-flight)
  /// requests.
  ///
  /// Tokens are added when a request begins and removed when the request
  /// completes (success or failure). This set enables bulk cancellation
  /// via [cancelAllRequests].
  ///
  /// ### Example
  /// ```dart
  /// print('Active requests: ${client.activeTokens.length}');
  /// ```
  ///
  /// ### Thread safety
  ///
  /// This set is not thread-safe. In a single-threaded Dart isolate, this
  /// is not a concern, but be aware of this if extending to concurrent
  /// environments.
  /// {@endtemplate}
  Set<CancelToken> get activeTokens;

  /// {@template zap_interface_config}
  /// Returns the resolved [ZapConfig] for this client instance.
  ///
  /// If no configuration was provided at construction, returns a default
  /// [ZapConfig] with standard timeouts and no base URL.
  ///
  /// This is the canonical configuration accessor used by the client
  /// internally. It should never return `null`.
  ///
  /// ### Example
  /// ```dart
  /// final timeout = client.config.timeout;
  /// ```
  /// {@endtemplate}
  ZapConfig get config;

  /// {@template zap_interface_cancelAllRequests}
  /// Cancels all currently active requests and clears the token set.
  ///
  /// Each token in [activeTokens] is cancelled with the given [reason]
  /// string. After cancellation, the token set is cleared.
  ///
  /// This is typically called during client disposal or when a global
  /// abort is needed (e.g., user navigating away from a screen).
  ///
  /// ### Parameters
  ///
  /// - [reason]: A human-readable string describing why the requests
  ///   were cancelled. Defaults to `'All requests cancelled'`.
  ///
  /// ### Example
  /// ```dart
  /// // Cancel on user action
  /// client.cancelAllRequests('User navigated away');
  ///
  /// // Cancel on dispose
  /// client.cancelAllRequests('Client shutting down');
  /// ```
  ///
  /// ### Behavior
  ///
  /// - If [activeTokens] is empty, this method is a no-op.
  /// - Each token's cancellation propagates a [ZapException] to the
  ///   corresponding `Future`.
  /// - Tokens that are already cancelled are skipped silently.
  /// {@endtemplate}
  void cancelAllRequests([String reason = 'All requests cancelled']);

  /// {@template zap_interface_get}
  /// Performs an HTTP GET request with optional cancellation support.
  ///
  /// Sends a GET request to the specified [url] and returns a [Response]
  /// containing the decoded result of type [T].
  ///
  /// ### Parameters
  ///
  /// - [url]: The target URL. If a relative path, it is resolved against
  ///   [config]'s `baseUrl`.
  /// - [headers]: Optional map of HTTP headers to include. Merged with
  ///   any default headers from [config].
  /// - [contentType]: Optional `Content-Type` header value. Overrides the
  ///   default for this request only.
  /// - [query]: Optional query parameters appended to the URL as a
  ///   query string (e.g., `{'page': '1', 'limit': '20'}`).
  /// - [decoder]: Optional function to decode the response body into [T].
  ///   If `null`, the raw response is returned.
  /// - [cancelToken]: Optional token to cancel this request. If the token
  ///   is already cancelled when this method is called, a [ZapException]
  ///   is thrown immediately.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response or
  /// throws a [ZapException] on failure or cancellation.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.get<User>('/users/1');
  /// print(response.data?.name);
  /// ```
  ///
  /// ### Cancellation
  /// ```dart
  /// final token = CancelToken();
  /// final future = zap.get<User>('/users/1', cancelToken: token);
  /// token.cancel('User navigated away');
  /// // future throws ZapException
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: If the request is cancelled, times out, or the
  ///   server returns a non-2xx status.
  /// {@endtemplate}
  Future<Response<T>> get<T>(String url, {
    Headers? headers,
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_post}
  /// Performs an HTTP POST request with optional cancellation support.
  ///
  /// Sends a POST request to the specified [url] with the given [body]
  /// and returns a [Response] containing the decoded result of type [T].
  ///
  /// ### Parameters
  ///
  /// - [url]: The target URL. Can be `null` if a default URL is configured.
  /// - [body]: The request body. Can be a `Map`, `String`, `List`, or any
  ///   object that the client serializes to the request payload.
  /// - [contentType]: Optional `Content-Type` header value. If not specified,
  ///   defaults to `'application/json'`.
  /// - [headers]: Optional map of HTTP headers to include.
  /// - [query]: Optional query parameters appended to the URL.
  /// - [decoder]: Optional function to decode the response body into [T].
  /// - [uploadProgress]: Optional callback invoked periodically with the
  ///   number of bytes uploaded and the total bytes. Useful for file uploads.
  /// - [cancelToken]: Optional token to cancel this request.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response or
  /// throws a [ZapException] on failure or cancellation.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.post<User>('/users', {
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  /// });
  /// ```
  ///
  /// ### File upload with progress
  /// ```dart
  /// final response = await zap.post<String>(
  ///   '/upload',
  ///   fileBytes,
  ///   uploadProgress: (sent, total) {
  ///     print('${(sent / total * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: If the request is cancelled, times out, or the
  ///   server returns a non-2xx status.
  /// {@endtemplate}
  Future<Response<T>> post<T>(String? url, RequestBody body, {
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_put}
  /// Performs an HTTP PUT request with optional cancellation support.
  ///
  /// Sends a PUT request to the specified [url] with the given [body]
  /// and returns a [Response] containing the decoded result of type [T].
  ///
  /// PUT is typically used for full resource replacement. The entire [body]
  /// replaces the resource at the target URL.
  ///
  /// ### Parameters
  ///
  /// - [url]: The target URL.
  /// - [body]: The request body.
  /// - [contentType]: Optional `Content-Type` header value.
  /// - [headers]: Optional map of HTTP headers.
  /// - [query]: Optional query parameters.
  /// - [decoder]: Optional response decoder.
  /// - [uploadProgress]: Optional upload progress callback.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.put<User>('/users/1', {
  ///   'name': 'Jane Doe',
  ///   'email': 'jane@example.com',
  /// });
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: On cancellation, timeout, or server error.
  /// {@endtemplate}
  Future<Response<T>> put<T>(String url, RequestBody body, {
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_patch}
  /// Performs an HTTP PATCH request with optional cancellation support.
  ///
  /// Sends a PATCH request to the specified [url] with the given [body]
  /// and returns a [Response] containing the decoded result of type [T].
  ///
  /// PATCH is typically used for partial resource updates. Only the fields
  /// included in [body] are modified.
  ///
  /// ### Parameters
  ///
  /// - [url]: The target URL.
  /// - [body]: The request body containing the partial update.
  /// - [contentType]: Optional `Content-Type` header value.
  /// - [headers]: Optional map of HTTP headers.
  /// - [query]: Optional query parameters.
  /// - [decoder]: Optional response decoder.
  /// - [uploadProgress]: Optional upload progress callback.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.patch<User>('/users/1', {
  ///   'email': 'newemail@example.com',
  /// });
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: On cancellation, timeout, or server error.
  /// {@endtemplate}
  Future<Response<T>> patch<T>(String url, RequestBody body, {
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_delete}
  /// Performs an HTTP DELETE request with optional cancellation support.
  ///
  /// Sends a DELETE request to the specified [url] and returns a [Response]
  /// containing the decoded result of type [T].
  ///
  /// ### Parameters
  ///
  /// - [url]: The target URL of the resource to delete.
  /// - [headers]: Optional map of HTTP headers.
  /// - [contentType]: Optional `Content-Type` header value.
  /// - [query]: Optional query parameters.
  /// - [decoder]: Optional response decoder.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.delete('/users/1');
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: On cancellation, timeout, or server error.
  /// {@endtemplate}
  Future<Response<T>> delete<T>(String url, {
    Headers? headers,
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_request}
  /// Performs a custom HTTP request with a specified [method] and optional
  /// cancellation support.
  ///
  /// This is the most flexible HTTP method, allowing any HTTP verb to be
  /// used (e.g., `OPTIONS`, `HEAD`, `TRACE`). For standard methods, prefer
  /// the dedicated [get], [post], [put], [patch], or [delete] methods.
  ///
  /// ### Parameters
  ///
  /// - [url]: The target URL.
  /// - [method]: The HTTP method string (e.g., `'GET'`, `'POST'`, `'OPTIONS'`).
  /// - [body]: Optional request body. Required for methods like POST and PUT.
  /// - [contentType]: Optional `Content-Type` header value.
  /// - [headers]: Optional map of HTTP headers.
  /// - [query]: Optional query parameters.
  /// - [decoder]: Optional response decoder.
  /// - [uploadProgress]: Optional upload progress callback.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.request<User>(
  ///   '/users/1',
  ///   'PATCH',
  ///   body: {'status': 'active'},
  /// );
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: On cancellation, timeout, or server error.
  /// {@endtemplate}
  Future<Response<T>> request<T>(String url, String method, {
    RequestBody body,
    String? contentType,
    Headers? headers,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    Progress? uploadProgress,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_send}
  /// Sends a pre-built [Request] object with optional cancellation support.
  ///
  /// Use this method when you need full control over the request object,
  /// including headers, body, timeout, and encoding. The [Request] object
  /// is typically created via [ZapClient] or a builder pattern.
  ///
  /// ### Parameters
  ///
  /// - [request]: The fully constructed [Request] to send.
  /// - [cancelToken]: Optional token to cancel this request.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<T>>` that completes with the server response.
  ///
  /// ### Example
  /// ```dart
  /// final request = Request<User>(
  ///   method: 'POST',
  ///   url: '/users',
  ///   body: {'name': 'John'},
  /// );
  /// final response = await zap.send<User>(request);
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: On cancellation, timeout, or server error.
  /// {@endtemplate}
  Future<Response<T>> send<T>(Request<T> request, {CancelToken? cancelToken});

  /// {@template zap_interface_socket}
  /// Creates a new WebSocket connection to the specified [url].
  ///
  /// Returns a [ZapSocket] instance that can be used to send and receive
  /// messages over the WebSocket. The socket is automatically added to
  /// the [sockets] list for lifecycle management.
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL (e.g., `'wss://example.com/ws'`).
  ///   If [config] has a `baseUrl` set, a relative path is resolved
  ///   against it.
  /// - [ping]: The interval between ping messages used to keep the
  ///   connection alive. Defaults to `Duration(seconds: 5)`.
  ///
  /// ### Returns
  ///
  /// A [ZapSocket] instance. The socket is not yet connected; call
  /// [ZapSocket.connect] to establish the connection.
  ///
  /// ### Example
  /// ```dart
  /// final socket = zap.socket('wss://example.com/chat');
  /// socket.connect();
  /// socket.onOpen(() => print('Connected!'));
  /// socket.onMessage((msg) => print('Received: $msg'));
  /// ```
  ///
  /// ### Lifecycle
  ///
  /// - The socket is tracked in [sockets] and closed on [dispose].
  /// - If the client is already disposed, a [ZapException] is thrown.
  /// {@endtemplate}
  ZapSocket socket(String url, {Duration ping = const Duration(seconds: 5)});

  /// {@template zap_interface_query}
  /// Performs a GraphQL query with optional cancellation support.
  ///
  /// Sends the given GraphQL [query] string as a POST request and returns
  /// a [GraphQLResponse] containing the parsed result of type [T].
  ///
  /// ### Parameters
  ///
  /// - [query]: The GraphQL query string.
  /// - [url]: Optional URL override for the GraphQL endpoint. If `null`,
  ///   uses the default endpoint from [config].
  /// - [variables]: Optional map of GraphQL variables to include in the
  ///   request body.
  /// - [headers]: Optional map of HTTP headers.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<GraphQLResponse<T>>` that wraps the query result, errors,
  /// and any network-level failures.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.query<User>('''
  ///   query GetUser(\$id: ID!) {
  ///     user(id: \$id) { name email }
  ///   }
  /// ''', variables: {'id': '1'});
  ///
  /// if (response.data != null) {
  ///   print(response.data!.name);
  /// }
  /// ```
  ///
  /// ### Error handling
  ///
  /// - Network errors are wrapped in [GraphQLResponse.fromException].
  /// - GraphQL-level errors (in the `errors` field) are included in the
  ///   response but do not throw.
  /// - Cancellation throws a [ZapException].
  /// {@endtemplate}
  Future<GraphQLResponse<T>> query<T>(
    String query, {
    String? url,
    RequestParam? variables,
    Headers? headers,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_mutation}
  /// Performs a GraphQL mutation with optional cancellation support.
  ///
  /// Sends the given GraphQL [mutation] string as a POST request and returns
  /// a [GraphQLResponse] containing the parsed result of type [T].
  ///
  /// ### Parameters
  ///
  /// - [mutation]: The GraphQL mutation string.
  /// - [url]: Optional URL override for the GraphQL endpoint. If `null`,
  ///   uses the default endpoint from [config].
  /// - [variables]: Optional map of GraphQL variables.
  /// - [headers]: Optional map of HTTP headers.
  /// - [cancelToken]: Optional cancellation token.
  ///
  /// ### Returns
  ///
  /// A `Future<GraphQLResponse<T>>` that wraps the mutation result.
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.mutation<User>('''
  ///   mutation CreateUser(\$input: UserInput!) {
  ///     createUser(input: \$input) { id name }
  ///   }
  /// ''', variables: {'input': {'name': 'John'}});
  /// ```
  ///
  /// ### Error handling
  ///
  /// Same as [query]: network errors are wrapped, GraphQL errors are
  /// included in the response, and cancellation throws.
  /// {@endtemplate}
  Future<GraphQLResponse<T>> mutation<T>(
    String mutation, {
    String? url,
    RequestParam? variables,
    Headers? headers,
    CancelToken? cancelToken,
  });

  /// {@template zap_interface_dispose}
  /// Releases all resources held by this client instance.
  ///
  /// This method performs the following cleanup steps:
  /// 1. Cancels all active requests via [cancelAllRequests].
  /// 2. Closes all open WebSocket connections in [sockets].
  /// 3. Clears the socket list.
  /// 4. Closes the underlying [client].
  /// 5. Nullifies configuration references.
  /// 6. Calls [onDelete] to trigger the lifecycle teardown.
  ///
  /// After calling [dispose], the instance should not be used. Any
  /// subsequent calls to HTTP or WebSocket methods should throw a
  /// [ZapException].
  ///
  /// ### Example
  /// ```dart
  /// final zap = Zap(zapConfig: config);
  /// // ... use the client ...
  /// zap.dispose(); // clean up
  /// ```
  ///
  /// ### Idempotency
  ///
  /// Calling [dispose] multiple times is safe. The second and subsequent
  /// calls are no-ops.
  ///
  /// ### Throws
  ///
  /// This method itself does not throw, but it may trigger exceptions
  /// in in-flight requests via [cancelAllRequests].
  /// {@endtemplate}
  void dispose();

  /// {@template zap_interface_isDisposed}
  /// Whether this client instance has been disposed.
  ///
  /// Returns `true` after [dispose] has been called. This flag is used
  /// internally to guard against operations on a disposed client.
  ///
  /// ### Example
  /// ```dart
  /// if (client.isDisposed) {
  ///   throw StateError('Client has been disposed');
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// This is primarily used internally. Consumers should generally
  /// assume the client is valid unless they explicitly called [dispose].
  /// {@endtemplate}
  bool get isDisposed;
}