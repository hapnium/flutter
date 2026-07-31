import '../../definitions.dart';
import '../response/session_response.dart';

/// {@template zync_config}
/// A comprehensive, centralized configuration blueprint for establishing and 
/// managing persistent WebSocket connections within the Zync ecosystem.
///
/// **Architectural Context:**
/// Unlike stateless HTTP requests, WebSockets are long-lived, stateful TCP connections. 
/// They require robust lifecycle management, including heartbeat monitors (ping/pong) 
/// to prevent load balancers from dropping idle connections, automatic reconnection 
/// strategies for flaky networks, and specialized authentication handling. 
///
/// [ZyncConfig] encapsulates all these rules into a single, immutable object. 
/// When a Zync socket manager is instantiated, it absorbs this blueprint and applies 
/// it to the underlying connection lifecycle.
///
/// ### Core Responsibilities:
/// * **Security & Auth:** Manages JWT injection into the initial handshake or 
///   subsequent frames via [session], [tokenPrefix], and [authHeaderBuilder].
/// * **Resiliency:** Dictates keep-alive behaviors via [pingInterval] and 
///   auto-recovery via [maxReconnectAttempts] and [reconnectDelay].
/// * **Event Delegation:** Provides global listeners ([onReceived], [onError], 
///   [onStateChanged]) for app-wide socket monitoring.
/// * **Observability:** Offers highly granular logging flags for debugging 
///   socket frames in development.
///
/// ### Usage Example:
/// ```dart
/// final socketConfig = ZyncConfig(
///   url: 'wss://[api.production.com/realtime](https://api.production.com/realtime)',
///   session: currentAuthSession,
///   pingInterval: const Duration(seconds: 45), // Keep alive behind AWS load balancers
///   maxReconnectAttempts: 10,
///   onStateChanged: (state) => print('Socket is now: $state'),
///   authHeaderBuilder: (session) => {
///     'Authorization': 'Bearer ${session.accessToken}',
///   },
/// );
/// ```
/// {@endtemplate}
class ZyncConfig {
  /// The absolute URI of the WebSocket server.
  /// 
  /// **Requirements:**
  /// Must use the `ws://` protocol for unencrypted connections (local development) 
  /// or the `wss://` protocol for TLS-encrypted connections (production).
  final String url;
  
  /// An optional default Pub/Sub channel to automatically join upon connection.
  /// 
  /// If provided, the socket manager will immediately dispatch a subscription 
  /// request for this topic as soon as the connection state becomes `connected`.
  final String? subscription;
  
  /// The cryptographic credentials required to authenticate the socket.
  /// 
  /// This [SessionResponse] contains the access tokens that will be injected 
  /// into the connection headers or handshake payload. If the user logs out, 
  /// this config should be updated via [copyWith] to clear the session.
  final SessionResponse? session;
  
  /// Custom HTTP headers applied during the initial WebSocket Upgrade handshake.
  /// 
  /// **Platform Warning:** Standard browser WebSocket APIs do not allow setting 
  /// custom headers. If [isWebPlatform] is true, these headers may be ignored 
  /// or must be passed as query parameters depending on your backend implementation.
  final Headers? headers;
  
  /// Enables console logging for lifecycle events (Connect, Disconnect, Reconnect).
  final bool showConnectionLogs;
  
  /// Enables console logging for caught exceptions and socket closures.
  final bool showErrorLogs;
  
  /// Enables console logging for all outbound frames sent from the client.
  final bool showSendLogs;
  
  /// Enables verbose, low-level debugging logs (e.g., ping/pong frames, raw byte data).
  final bool showDebugLogs;
  
  /// Indicates if the application is compiling to Flutter Web.
  /// 
  /// **Architectural Impact:** 
  /// WebSockets on the web use the browser's native `WebSocket` API, which is 
  /// highly restrictive compared to native `dart:io` sockets. Setting this to `true` 
  /// tells the Zync engine to adapt its header injection and connection strategies 
  /// for web compatibility.
  final bool isWebPlatform;
  
  /// A master switch to enable or disable authentication for this connection.
  /// 
  /// If `false`, the [session], [authHeaderName], and [authHeaderBuilder] will 
  /// be entirely ignored, and the socket will attempt an anonymous connection.
  final bool useToken;

  /// The exact string key used for the authentication header.
  /// 
  /// Defaults to `'Authorization'`. Common alternatives include `'X-API-Key'` 
  /// or `'X-Auth-Token'`. Used in conjunction with [tokenPrefix] for basic auth setups.
  final String authHeaderName;

  /// The string prefix prepended to the raw access token in the header value.
  /// 
  /// Defaults to `'Bearer'`. When combined with the default settings, the resulting 
  /// header will look like: `Authorization: Bearer eyJhbGci...`. 
  /// 
  /// Set to an empty string `''` if your backend expects the raw token without a prefix.
  final String tokenPrefix;

  /// A powerful override for constructing complex, multi-header authentication schemes.
  /// 
  /// If your backend requires more than a simple Bearer token (e.g., requiring both 
  /// the token and a distinct App-ID header), you can provide this builder. 
  /// 
  /// **Note:** If [authHeaderBuilder] is provided, it completely overrides and 
  /// supersedes both [authHeaderName] and [tokenPrefix].
  /// 
  /// **Example:**
  /// ```dart
  /// authHeaderBuilder: (session) => {
  ///   'Authorization': 'Bearer ${session.accessToken}',
  ///   'X-Refresh-Token': session.refreshToken,
  ///   'X-User-ID': session.userId.toString(),
  /// }
  /// ```
  final HeaderBuilder? authHeaderBuilder;

  /// A global callback triggered whenever the backend forcibly updates the session state.
  /// 
  /// **Use Case:**
  /// If your socket connection stays open for hours, the initial access token will 
  /// expire. Some backends push a new access token down the socket channel. This 
  /// callback allows your app's global state (e.g., Redux, Bloc, Riverpod) to 
  /// intercept that new token and save it to secure storage.
  final SessionCallback? sessionFactory;
  
  /// A global catch-all listener for every incoming message frame.
  /// 
  /// While specific UI widgets might listen to specific Pub/Sub topics, this 
  /// callback is useful for global event monitoring (like intercepting forced 
  /// logout commands or global app notifications).
  final RealtimeCallback? onReceived;
  
  /// A global error boundary for the socket connection.
  /// 
  /// Catches protocol errors, decoding failures, and abrupt connection drops, 
  /// allowing you to pipe socket errors directly into Crashlytics or Sentry.
  final ErrorCallback? onError;
  
  /// A callback that tracks the real-time lifecycle of the connection.
  /// 
  /// Yields states like `connecting`, `connected`, `disconnected`, or `retrying`. 
  /// Crucial for driving global UI indicators (e.g., showing a "Connecting..." 
  /// banner at the top of the app).
  final StateCallback? onStateChanged;
  
  /// The frequency at which Keep-Alive (Ping) frames are sent to the server.
  /// 
  /// **Why this matters:**
  /// Cloud load balancers (like AWS ALB or Nginx) aggressively sever TCP connections 
  /// that are idle for more than 30-60 seconds. By sending a lightweight Ping 
  /// interval, the connection remains active. Defaults to 30 seconds.
  final Duration pingInterval;
  
  /// The absolute limit on automatic reconnection attempts after an unexpected drop.
  /// 
  /// Prevents the app from endlessly draining battery life if the server is permanently 
  /// down or the device has lost cellular service. Defaults to `5`.
  final int maxReconnectAttempts;
  
  /// The pause duration between sequential reconnection attempts.
  /// 
  /// **Best Practice:** In a highly robust system, you might want to implement 
  /// exponential backoff. This setting provides a fixed linear delay (defaults to 
  /// 3 seconds) to prevent the client from aggressively hammering a struggling server.
  final Duration reconnectDelay;

  /// {@macro zync_config}
  /// 
  /// Initializes the WebSocket configuration with sensible defaults for resiliency 
  /// (30s ping, 5 max retries) and standard OAuth 2.0 Bearer token injection.
  ZyncConfig({
    required this.url,
    this.subscription,
    this.session,
    this.headers,
    this.showConnectionLogs = false,
    this.showErrorLogs = false,
    this.showSendLogs = false,
    this.showDebugLogs = false,
    this.isWebPlatform = false,
    this.useToken = true,
    this.authHeaderName = 'Authorization',
    this.tokenPrefix = 'Bearer',
    this.authHeaderBuilder,
    this.sessionFactory,
    this.onReceived,
    this.onError,
    this.onStateChanged,
    this.pingInterval = const Duration(seconds: 30),
    this.maxReconnectAttempts = 5,
    this.reconnectDelay = const Duration(seconds: 3),
  });

  /// Generates a new instance of [ZyncConfig] with selectively updated properties.
  ///
  /// **Architectural Use Case:**
  /// Enforces immutability. If a user logs into your app, you should not mutate 
  /// the existing global configuration object. Instead, use `copyWith` to generate 
  /// a new config featuring the populated [session] while inheriting all existing 
  /// timeouts, ping intervals, and callbacks.
  /// 
  /// ```dart
  /// // User logs in, update the socket config with the new session
  /// currentZyncConfig = currentZyncConfig.copyWith(session: newSession);
  /// ```
  /// 
  /// {@macro zync_config}
  ZyncConfig copyWith({
    String? url,
    String? subscription,
    SessionResponse? session,
    Headers? headers,
    bool? showConnectionLogs,
    bool? showErrorLogs,
    bool? showSendLogs,
    bool? showDebugLogs,
    bool? isWebPlatform,
    bool? useToken,
    String? authHeaderName,
    String? tokenPrefix,
    HeaderBuilder? authHeaderBuilder,
    SessionCallback? sessionFactory,
    RealtimeCallback? onReceived,
    ErrorCallback? onError,
    StateCallback? onStateChanged,
    Duration? pingInterval,
    int? maxReconnectAttempts,
    Duration? reconnectDelay,
  }) {
    return ZyncConfig(
      url: url ?? this.url,
      subscription: subscription ?? this.subscription,
      session: session ?? this.session,
      headers: headers ?? this.headers,
      showConnectionLogs: showConnectionLogs ?? this.showConnectionLogs,
      showErrorLogs: showErrorLogs ?? this.showErrorLogs,
      showSendLogs: showSendLogs ?? this.showSendLogs,
      showDebugLogs: showDebugLogs ?? this.showDebugLogs,
      isWebPlatform: isWebPlatform ?? this.isWebPlatform,
      useToken: useToken ?? this.useToken,
      authHeaderName: authHeaderName ?? this.authHeaderName,
      tokenPrefix: tokenPrefix ?? this.tokenPrefix,
      authHeaderBuilder: authHeaderBuilder ?? this.authHeaderBuilder,
      sessionFactory: sessionFactory ?? this.sessionFactory,
      onReceived: onReceived ?? this.onReceived,
      onError: onError ?? this.onError,
      onStateChanged: onStateChanged ?? this.onStateChanged,
      pingInterval: pingInterval ?? this.pingInterval,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
    );
  }
}