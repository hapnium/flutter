import 'enums/zync_state.dart';
import 'models/response/session_response.dart';
import 'models/zync_response.dart';

/// {@template realtime_callback}
/// Signature for a callback function that handles real-time socket responses.
///
/// A function that receives a [ZyncResponse] object containing information
/// about the received socket message, including the event type, data
/// payload, and metadata.
///
/// ### Parameters
///
/// - [response]: The [ZyncResponse] containing the socket message data.
///
/// ### Example
///
/// ```dart
/// void onRealtimeMessage(ZyncResponse response) {
///   print('Event: ${response.event}');
///   print('Data: ${response.data}');
/// }
/// ```
/// {@endtemplate}
typedef RealtimeCallback = void Function(ZyncResponse);

/// {@template error_callback}
/// Signature for a callback function that handles errors.
///
/// A function that receives two arguments:
/// 1. `where`: A string representing the location where the error occurred
///    (e.g., class name, method name).
/// 2. `error`: The error object or any other relevant information about
///    the error.
///
/// ### Parameters
///
/// - [where]: Location identifier (e.g., `'ZapClient.get'`).
/// - [error]: The error object (typically an `Exception` or `String`).
///
/// ### Example
///
/// ```dart
/// void onError(String where, dynamic error) {
///   Z.error('Error in $where: $error');
/// }
/// ```
/// {@endtemplate}
typedef ErrorCallback = void Function(String where, dynamic error);

/// {@template state_callback}
/// Signature for a callback function that handles connection state changes.
///
/// A function that receives a [ZyncState] object indicating the current
/// state of the WebSocket connection.
///
/// ### Parameters
///
/// - [state]: The new [ZyncState] value.
///
/// ### Example
///
/// ```dart
/// void onStateChange(ZyncState state) {
///   switch (state) {
///     case ZyncState.connected:
///       _enableMessaging();
///     case ZyncState.disconnected:
///       _showReconnectButton();
///   }
/// }
/// ```
/// {@endtemplate}
typedef StateCallback = void Function(ZyncState state);

/// {@template session_callback}
/// Signature for a synchronous callback that returns a session.
///
/// A function that returns a [SessionResponse] or `null`. Used for
/// providing the current session to the HTTP client on every request.
///
/// ### Return value
///
/// - A [SessionResponse] containing the current session data.
/// - `null` if no session is available.
///
/// ### Example
///
/// ```dart
/// SessionCallback sessionFactory = () {
///   return _currentSession; // synchronous access to stored session
/// };
/// ```
///
/// ### Usage
///
/// This is typically used with [FluxConfig.sessionFactory] to provide
/// the current session without async overhead.
/// {@endtemplate}
typedef SessionCallback = SessionResponse? Function();

/// {@template async_session_callback}
/// Signature for an asynchronous callback that returns a session.
///
/// A function that returns a `Future<SessionResponse?>`. Used for
/// refreshing the session when the current one expires.
///
/// ### Return value
///
/// - A `Future<SessionResponse?>` containing the refreshed session.
/// - `null` if the refresh failed.
///
/// ### Example
///
/// ```dart
/// AsyncSessionCallback onSessionRefreshed = () async {
///   final response = await http.post('/auth/refresh');
///   return SessionResponse.fromJson(response.body);
/// };
/// ```
///
/// ### Usage
///
/// This is typically used with [FluxConfig.onSessionRefreshed] to
/// refresh the session when a 401 Unauthorized response is received.
/// {@endtemplate}
typedef AsyncSessionCallback = Future<SessionResponse?> Function();

/// {@template header_builder}
/// Signature for a function that builds authentication headers from a
/// session.
///
/// A function that receives a [SessionResponse] and returns a [Headers]
/// map containing the authentication headers.
///
/// ### Parameters
///
/// - [session]: The current session containing access tokens.
///
/// ### Return value
///
/// A [Headers] map with authentication headers.
///
/// ### Example
///
/// ```dart
/// HeaderBuilder builder = (session) => {
///   'Authorization': 'Bearer ${session.accessToken}',
///   'X-Tenant-ID': session.userId.toString(),
/// };
/// ```
///
/// ### Usage
///
/// This overrides the default [authHeaderName] and [tokenPrefix] in
/// [FluxConfig] when complex authentication schemes are needed.
/// {@endtemplate}
typedef HeaderBuilder = Headers Function(SessionResponse session);

/// {@template callback}
/// Signature for a generic callback function with no arguments.
///
/// A simple void function used for fire-and-forget notifications.
///
/// ### Example
///
/// ```dart
/// Callback whenUnauthorized = () {
///   Navigator.of(context).pushReplacementNamed('/login');
/// };
/// ```
///
/// ### Usage
///
/// Used for event hooks like [FluxConfig.whenUnauthorized].
/// {@endtemplate}
typedef Callback = void Function();

/// {@template headers}
/// Represents a map of HTTP headers.
///
/// Keys are header names (e.g., `'Content-Type'`, `'Authorization'`)
/// and values are their corresponding values.
///
/// ### Example
///
/// ```dart
/// Headers headers = {
///   'Content-Type': 'application/json',
///   'Authorization': 'Bearer eyJhbGci...',
///   'X-Request-ID': 'abc123',
/// };
/// ```
///
/// ### Common headers
///
/// | Header | Value | Purpose |
/// |--------|-------|---------|
/// | Content-Type | application/json | Request body format |
/// | Authorization | Bearer <token> | Authentication |
/// | Accept | application/json | Expected response format |
/// | Cache-Control | no-cache | Disable caching |
/// | X-Request-ID | uuid | Request tracing |
/// {@endtemplate}
typedef Headers = Map<String, String>;

/// {@template body_byte_stream}
/// Represents a stream of bytes as the body of a request or response.
///
/// This is used for streaming large payloads (e.g., file uploads,
/// downloads) without loading the entire content into memory.
///
/// ### Example
///
/// ```dart
/// BodyByteStream stream = file.openRead();
/// // or
/// BodyByteStream stream = response.bodyByteStream;
/// ```
///
/// ### Usage
///
/// - File uploads: `file.openRead()`
/// - Response body streaming
/// - Large payload handling
/// {@endtemplate}
typedef BodyByteStream = Stream<BodyBytes>;

/// {@template body_bytes}
/// Represents a list of bytes as the body of a request or response.
///
/// This is the in-memory representation of binary data. Use
/// [BodyByteStream] for streaming large payloads.
///
/// ### Example
///
/// ```dart
/// BodyBytes bytes = [72, 101, 108, 108, 111]; // "Hello"
/// BodyBytes fileBytes = await file.readAsBytes();
/// ```
///
/// ### Usage
///
/// - Small payloads that fit in memory
/// - File contents after reading
/// - Binary data manipulation
/// {@endtemplate}
typedef BodyBytes = List<int>;

/// {@template payload}
/// Represents a generic message structure for socket or API communication.
///
/// A map where keys are strings and values can be of any type. Used for
/// structured data exchange over WebSockets or HTTP.
///
/// ### Example
///
/// ```dart
/// Payload payload = {
///   'event': 'chat:message',
///   'data': {
///     'text': 'Hello!',
///     'sender': 'user123',
///     'timestamp': 1700000000,
///   },
/// };
/// ```
///
/// ### Usage
///
/// - WebSocket message payloads
/// - API request/response bodies
/// - Event data structures
/// {@endtemplate}
typedef Payload = Map<String, dynamic>;

/// {@template request_param}
/// Signature for representing request parameters as a map.
///
/// A map where keys are strings and values can be of any type. Used for
/// query parameters, URL parameters, and request metadata.
///
/// ### Example
///
/// ```dart
/// RequestParam params = {
///   'page': 1,
///   'limit': 20,
///   'sort': 'created_at',
///   'order': 'desc',
/// };
/// ```
///
/// ### Usage
///
/// - Query parameters for GET requests
/// - URL path parameters
/// - Request metadata
/// {@endtemplate}
typedef RequestParam = Map<String, dynamic>;

/// {@template request_body}
/// Signature for representing the request body.
///
/// Can represent any type of data that can be sent as the request body:
/// - `Map<String, dynamic>`: JSON objects
/// - `List<dynamic>`: JSON arrays
/// - `String`: Text content
/// - `Uint8List` / `BodyBytes`: Binary data
/// - `FormData`: Multipart form data
/// - Custom objects: Serialized by the client
///
/// ### Example
///
/// ```dart
/// // JSON body
/// RequestBody body = {'name': 'John', 'email': 'john@example.com'};
///
/// // String body
/// RequestBody body = 'plain text content';
///
/// // Binary body
/// RequestBody body = file.readAsBytesSync();
/// ```
///
/// ### Usage
///
/// The body type determines how the request is serialized:
/// - `Map` / `List`: Serialized as JSON
/// - `String`: Sent as plain text
/// - `Uint8List`: Sent as binary
/// - `FormData`: Sent as multipart/form-data
/// {@endtemplate}
typedef RequestBody = dynamic;

/// {@template response_decoder}
/// A function that decodes the response body into a specific type [T].
///
/// The decoder receives the raw response data (usually a `Map` or `List`)
/// and converts it into the desired type.
///
/// ### Type parameters
///
/// - [T]: The target type to decode into.
///
/// ### Parameters
///
/// - [data]: The raw response data (dynamic).
///
/// ### Return value
///
/// An instance of [T] decoded from [data].
///
/// ### Example
///
/// ```dart
/// ResponseDecoder<User> decoder = (data) => User.fromJson(data);
/// ResponseDecoder<List<User>> decoder = (data) =>
///     (data as List).map((e) => User.fromJson(e)).toList();
/// ```
///
/// ### Usage
///
/// ```dart
/// final response = await client.get<User>(
///   '/users/1',
///   decoder: (data) => User.fromJson(data),
/// );
/// ```
/// {@endtemplate}
typedef ResponseDecoder<T> = T Function(dynamic data);

/// {@template progress}
/// A function used to track upload/download progress.
///
/// The function receives a progress value between 0.0 and 100.0
/// representing the percentage complete.
///
/// ### Parameters
///
/// - [percent]: Progress percentage (0.0 to 100.0).
///
/// ### Example
///
/// ```dart
/// Progress onProgress = (percent) {
///   setState(() => _uploadProgress = percent);
///   print('Upload: ${percent.toStringAsFixed(1)}%');
/// };
/// ```
///
/// ### Usage
///
/// ```dart
/// await client.post(
///   '/upload',
///   body: fileBytes,
///   uploadProgress: (percent) {
///     progressBar.value = percent / 100;
///   },
/// );
/// ```
///
/// ### Chunking
///
/// Progress is tracked in 8KB chunks, throttled at ~60fps to avoid
/// overwhelming the UI with updates.
/// {@endtemplate}
typedef Progress = Function(double percent);

/// {@template proxy_finder}
/// A function used to find the proxy server to use for a given request URL.
///
/// The function receives the request [Uri] and returns a proxy address
/// string.
///
/// ### Parameters
///
/// - [url]: The request URL.
///
/// ### Return value
///
/// A string representing the proxy address (e.g.,
/// `'http://proxy.example.com:8080'`).
///
/// ### Example
///
/// ```dart
/// ProxyFinder proxyFinder = (url) {
///   if (url.host.endsWith('.internal')) {
///     return 'http://proxy.internal:8080';
///   }
///   return 'DIRECT'; // no proxy
/// };
/// ```
///
/// ### Usage
///
/// ```dart
/// final client = ZapClient(
///   baseUrl: 'https://api.example.com',
///   findProxy: (uri) {
///     if (uri.host == 'api.example.com') {
///       return 'PROXY proxy.example.com:8080';
///     }
///     return 'DIRECT';
///   },
/// );
/// ```
///
/// ### PAC file support
///
/// Some implementations support PAC (Proxy Auto-Configuration) files.
/// The return value format depends on the platform.
/// {@endtemplate}
typedef ProxyFinder = String Function(Uri url);