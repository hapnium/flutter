import 'dart:async';
import 'dart:math';
// import 'dart:convert';

import '../core/zap_inst.dart';
import '../definitions.dart';
import '../enums/socket_type.dart';
import '../enums/zync_state.dart';
import '../exceptions/zap_exception.dart';
import '../http/utils/http_content_type.dart';
import '../http/utils/http_headers.dart';
import '../models/response/session_response.dart';
import '../models/socket_messenger.dart';
import '../models/zync/zync_config.dart';
import '../models/zync/zync_error_response.dart';
import '../models/zync/zync_response.dart';
import '../core/zap_socket.dart';
import '../socket/src/socket_notifier.dart';
import 'zync_interface.dart';

/// ZyncMessage is a callback function that handles incoming messages.
/// 
/// It takes a ZyncResponse object as a parameter and returns void.
typedef ZyncMessage = void Function(ZyncResponse response);

/// {@template zync}
/// Zync is a high-level WebSocket client wrapper that provides real-time
/// communication capabilities with authentication, session management, and
/// standardized message handling.
/// 
/// This class implements a singleton pattern to ensure only one instance exists
/// throughout the application lifecycle. It wraps the underlying ZapSocket client
/// and provides additional features like automatic reconnection, subscription
/// management, event-based messaging, and flexible authentication headers.
/// 
/// Key features:
/// - Singleton pattern implementation
/// - Configurable authentication headers (header name, token prefix, or custom builder)
/// - Automatic connection management and reconnection
/// - Topic-based subscription system
/// - Event-driven messaging
/// - Dynamic session management
/// - Connection state monitoring
/// - Error handling and logging
/// 
/// Example usage:
/// ```dart
/// // Standard Bearer token
/// final config = ZyncConfig(
///   url: 'wss://api.example.com/ws',
///   session: currentSession,
///   authHeaderName: 'Authorization',
///   tokenPrefix: 'Bearer',
/// );
/// 
/// // Google API style
/// final googleConfig = ZyncConfig(
///   url: 'wss://api.google.com/ws',
///   session: currentSession,
///   authHeaderName: 'Authorization',
///   tokenPrefix: 'Goog',
/// );
/// 
/// // Custom authentication headers
/// final customConfig = ZyncConfig(
///   url: 'wss://api.custom.com/ws',
///   session: currentSession,
///   authHeaderBuilder: (session) => {
///     'X-API-Key': session.accessToken,
///     'X-User-ID': session.userId.toString(),
///     'X-Session-Token': session.refreshToken,
///   },
/// );
/// 
/// final realtime = Zync(config: config);
/// await realtime.connect();
/// ```
/// 
/// {@endtemplate}
class Zync implements ZyncInterface {
  /// Configuration object containing all settings for the Zync client.
  final ZyncConfig config;

  /// Private constructor to enforce singleton pattern
  Zync._internal({required this.config});

  /// Static instance holder for singleton pattern
  static Zync? _instance;

  /// Factory constructor that implements singleton pattern.
  /// 
  /// Throws [ZapException] if an instance already exists with different configuration.
  /// 
  /// {@macro zync}
  factory Zync({required ZyncConfig config}) {
    if (_instance != null) {
      throw ZapException(
        "Multiple instances of Zync detected. Only one instance is allowed. "
        "Use Zync.instance to access the existing instance or call Zync.dispose() "
        "before creating a new instance."
      );
    }
    _instance = Zync._internal(config: config);
    return _instance!;
  }

  /// Gets the current singleton instance.
  /// 
  /// Throws [ZapException] if no instance has been created yet.
  /// 
  /// {@macro zync}
  static Zync get instance {
    if (_instance == null) {
      throw ZapException("No Zync instance found. Create an instance first using Zync(config: config).");
    }
    return _instance!;
  }

  /// Disposes the current singleton instance, allowing a new one to be created.
  /// Tears down the [Zync] singleton: disconnects the socket, stops all
  /// timers, and closes the state/data/error streams. A new instance can
  /// be created afterwards via [Zync.new].
  static void dispose() {
    final instance = _instance;
    if (instance != null) {
      instance.disconnect();
      instance._closeControllers();
    }
    _instance = null;
  }

  /// Closes the instance's stream controllers (idempotent).
  void _closeControllers() {
    _pingTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    if (!_connectionStateController.isClosed) _connectionStateController.close();
    if (!_dataStreamController.isClosed) _dataStreamController.close();
    if (!_errorStreamController.isClosed) _errorStreamController.close();
  }

  /// Underlying ZapSocket instance
  ZapSocket? _socket;

  /// Current connection state
  ZyncState _connectionState = ZyncState.dormant;

  /// Map of active subscriptions
  final Map<String, ZyncMessage> _subscriptions = {};

  /// Map of event listeners
  final Map<SocketType, MessageSocket> _eventListeners = {};

  /// Reconnection attempt counter
  int _reconnectAttempts = 0;

  /// Whether the last disconnect was initiated by the caller via
  /// [disconnect].
  ///
  /// When `true`, transport close/error events must not trigger an
  /// automatic reconnect. Reset to `false` at the start of every
  /// [connect].
  bool _manualDisconnect = false;

  /// Periodic dead-connection probe, active only when
  /// [ZyncConfig.heartbeatTimeout] is configured.
  Timer? _heartbeatTimer;

  /// The time the last inbound frame was received; drives the heartbeat
  /// timeout. Refreshed on [connect] and on every incoming message.
  DateTime _lastActivityAt = DateTime.now();

  /// In-flight [sendWithAck] calls keyed by the generated `messageId`.
  ///
  /// Completed by an `ack` frame, failed by a `nack` frame, a timeout,
  /// or a disconnect.
  final Map<String, Completer<SocketMessenger>> _pendingAcks = {};

  /// Per-call timeout timers for [sendWithAck], keyed by `messageId`.
  final Map<String, Timer> _ackTimers = {};

  /// Counter for generating unique ack `messageId`s within a process.
  int _ackCounter = 0;

  /// Timer for reconnection attempts
  Timer? _reconnectTimer;

  /// Timer for ping messages
  Timer? _pingTimer;

  /// Send retry counter
  int _sendTrials = 0;
  static const int _maxSendTrials = 5;

  // Stream controllers
  final StreamController<ZyncState> _connectionStateController = StreamController<ZyncState>.broadcast();
  final StreamController<ZyncResponse> _dataStreamController = StreamController<ZyncResponse>.broadcast();
  final StreamController<ZyncErrorResponse> _errorStreamController = StreamController<ZyncErrorResponse>.broadcast();

  @override
  bool get isConnected => _socket != null && _connectionState == ZyncState.connected;

  @override
  ZyncState get connectionState => _connectionState;

  @override
  StreamController<ZyncState> get connectionStateController => _connectionStateController;

  @override
  StreamController<ZyncErrorResponse> get errorController => _errorStreamController;

  @override
  StreamController<ZyncResponse> get dataController => _dataStreamController;

  @override
  Stream<ZyncState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<ZyncResponse> get dataStream => _dataStreamController.stream;

  @override
  Stream<ZyncErrorResponse> get errorStream => _errorStreamController.stream;

  /// Gets the current session, always fetching the latest from the session factory.
  /// 
  /// This ensures that the session is always up-to-date by calling the session
  /// callback function if provided, otherwise returns the static session from config.
  SessionResponse? get _currentSession {
    if (config.sessionFactory != null) {
      return config.sessionFactory!();
    }
    return config.session;
  }

  /// Updates the connection state and notifies listeners.
  void _updateConnectionState(ZyncState state) {
    _connectionState = state;
    
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
    
    config.onStateChanged?.call(state);
    
    if (config.showConnectionLogs) {
      Z.log('Zync: Connection state changed to $state');
    }
  }

  /// Builds authentication headers based on the configuration.
  /// 
  /// This method supports three modes:
  /// 1. Custom header builder function (highest priority)
  /// 2. Configurable header name and token prefix
  /// 3. Default Authorization: Bearer format
  /// 
  /// Examples of generated headers:
  /// - `Authorization: Bearer abc123` (default)
  /// - `Authorization: Goog abc123` (Google style)
  /// - `X-API-Key: abc123` (API key style with empty prefix)
  /// - Multiple custom headers via authHeaderBuilder
  Headers _buildAuthHeaders(SessionResponse session) {
    // Use custom auth header builder if provided
    if (config.authHeaderBuilder != null) {
      return config.authHeaderBuilder!(session);
    }
    
    // Use configurable header name and token prefix
    final token = session.accessToken;
    if (token.isEmpty) {
      return {};
    }
    
    final headerValue = config.tokenPrefix.isEmpty ? token : '${config.tokenPrefix} $token';
    
    return {config.authHeaderName: headerValue};
  }

  /// Builds headers for WebSocket connection including authentication.
  /// 
  /// This method fetches the current session and builds the appropriate auth headers
  /// based on the configuration. It also includes any additional headers from config.
  Headers _buildHeaders([Headers? additionalHeaders]) {
    final headers = <String, String>{
      HttpHeaders.ACCEPT: HttpContentType.APPLICATION_JSON,
    };

    // Add base headers from config
    if (config.headers != null) {
      headers.addAll(config.headers!);
    }

    // Add authentication headers if needed
    if (config.useToken) {
      final session = _currentSession;
      if (session != null) {
        final authHeaders = _buildAuthHeaders(session);
        headers.addAll(authHeaders);
        
        if (config.showConnectionLogs && authHeaders.isNotEmpty) {
          Z.log('Zync: Added auth headers: ${authHeaders.keys.join(', ')}');
        }
      }
    }

    // Add content type for non-web platforms
    if (!config.isWebPlatform) {
      headers[HttpHeaders.CONTENT_TYPE] = HttpContentType.APPLICATION_JSON;
    }

    // Add any additional headers passed to the method
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handles incoming WebSocket messages.
  void _handleMessage(dynamic message) {
    // Any inbound frame proves the connection is alive.
    _lastActivityAt = DateTime.now();

    try {
      ZyncResponse response;
      
      if (message is String) {
        // Try to parse as JSON
        try {
          final data = SocketMessenger.decode(message);

          // Acknowledgement frames complete a pending [sendWithAck] call.
          // They are transport-level plumbing and never reach app streams.
          if ((data.type == SocketType.ack || data.type == SocketType.nack) &&
              data.messageId != null &&
              _pendingAcks.containsKey(data.messageId)) {
            _completeAck(data);
            return;
          }

          response = ZyncResponse(
            type: data.type,
            body: message,
            data: data,
            topic: data.topic,
            event: data.event,
            messageId: data.messageId,
            hasBody: true,
            hasData: true,
          );
        } catch (_) {
          // Not JSON, treat as plain text
          response = ZyncResponse(
            body: message,
            data: message,
            hasBody: true,
            hasData: true,
          );
        }
      } else {
        // Handle non-string messages
        response = ZyncResponse(
          data: message,
          hasData: true,
        );
      }

      // Tappy data stream
      if (!_dataStreamController.isClosed) {
        _dataStreamController.add(response);
      }

      // Call config callback
      config.onReceived?.call(response);

      // Surface topic-scoped error frames into the global error stream
      // with topic context, so apps can handle channel failures locally
      // (e.g. show "orders channel rejected the message" on that screen).
      if (response.type == SocketType.error && response.topic != null) {
        _handleError('Topic ${response.topic}', response.data, topic: response.topic);
      }

      // Handle subscriptions: route by the frame's topic first (pub/sub
      // servers tag channels explicitly), falling back to the type name
      // for servers that only send SocketType-tagged frames.
      final topicKey = response.topic ?? response.type?.name;
      if (topicKey != null && _subscriptions.containsKey(topicKey)) {
        _subscriptions[topicKey]?.call(response);
      }

      // Handle event listeners
      if (response.type != null && _eventListeners.containsKey(response.type)) {
        _eventListeners[response.type]?.call(response.data);
      }

      if (config.showDebugLogs) {
        Z.log('Zync: Message received - ${response.type ?? 'unknown'}');
      }
    } catch (e) {
      _handleError('Message Processing Error', e);
    }
  }

  /// Handles WebSocket errors.
  void _handleError(String where, dynamic error, {String? topic}) {
    final errorResponse = ZyncErrorResponse(where: where, error: error, topic: topic);
    
    if (!_errorStreamController.isClosed) {
      _errorStreamController.add(errorResponse);
    }
    
    config.onError?.call(where, error);
    
    if (config.showErrorLogs) {
      Z.error('Zync Error [$where]: $error');
    }
  }

  /// Starts the ping timer to keep the connection alive.
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(config.pingInterval, (timer) {
      if (isConnected) {
        _socket?.send(
          SocketMessenger(
            type: SocketType.ping,
            timestamp: DateTime.now(),
            headers: _buildHeaders(),
          ).encode(),
        );
      }
    });
  }

  /// Stops the ping timer.
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Starts the dead-connection probe when [ZyncConfig.heartbeatTimeout]
  /// is configured.
  ///
  /// If no inbound frame arrives for the timeout window while connected,
  /// the socket is force-closed and the normal reconnect path recovers
  /// the session.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final timeout = config.heartbeatTimeout;
    if (timeout == null || timeout <= Duration.zero) {
      return;
    }

    _lastActivityAt = DateTime.now();
    var period = timeout ~/ 2;
    if (period <= Duration.zero) period = timeout;
    _heartbeatTimer = Timer.periodic(period, (_) {
      if (!isConnected) return;
      if (DateTime.now().difference(_lastActivityAt) < timeout) return;

      if (config.showConnectionLogs) {
        Z.log('Zync: No inbound frames for ${timeout.inMilliseconds}ms; forcing reconnect');
      }
      // Force-close the presumed-dead socket; the close handler runs the
      // normal reconnect path.
      _socket?.close(4000, 'heartbeat timeout');
    });
  }

  /// Stops the dead-connection probe.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Attempts to reconnect to the WebSocket server.
  void _attemptReconnect() {
    if (_reconnectAttempts >= config.maxReconnectAttempts) {
      _handleError('Reconnection Failed', 'Maximum reconnection attempts reached');
      _updateConnectionState(ZyncState.disconnected);
      return;
    }

    _reconnectAttempts++;
    
    if (config.showConnectionLogs) {
      Z.log('Zync: Attempting reconnection $_reconnectAttempts/${config.maxReconnectAttempts}');
    }

    // Exponential backoff with jitter: the configured [ZyncConfig.reconnectDelay]
    // is the base, doubling per attempt and capped at 30 seconds. Jitter
    // (±25%) prevents a fleet of clients that lost the same server from
    // stampeding it with synchronized reconnects.
    _reconnectTimer?.cancel();
    final exponent = (_reconnectAttempts - 1).clamp(0, 6).toInt();
    var delayMs = config.reconnectDelay.inMilliseconds * (1 << exponent);
    if (delayMs > 30000) delayMs = 30000;
    final jitteredMs = (delayMs * (0.75 + Random().nextDouble() * 0.5)).round();
    _reconnectTimer = Timer(Duration(milliseconds: jitteredMs), () {
      connect();
    });
  }

  @override
  Future<void> connect() async {
    try {
      _manualDisconnect = false;
      _reconnectTimer?.cancel();
      _updateConnectionState(ZyncState.connecting);
      
      if (config.showConnectionLogs) {
        Z.log('Zync: Connecting to ${config.url}');
      }

      // Tear down any previous socket so a reconnect never leaves two
      // live sockets (and their handlers) behind.
      final previous = _socket;
      _socket = null;
      previous?.dispose();

      // Create new socket instance
      _socket = ZapSocket(config.url, ping: config.pingInterval);

      // Set up event handlers
      _socket!.onOpen(() {
        _reconnectAttempts = 0; // Reset reconnection counter
        _updateConnectionState(ZyncState.connected);
        _startPingTimer();
        _startHeartbeat();
        
        if (config.showConnectionLogs) {
          Z.log('Zync: Connected to ${config.url}');
        }

        // Send connection headers with authentication
        _socket!.send(
          SocketMessenger(
            type: SocketType.connect,
            headers: _buildHeaders(),
            timestamp: DateTime.now(),
          ).encode(),
        );

        // Re-subscribe channels registered before this (re)connect:
        // handlers survive reconnects, the server-side subscriptions do
        // not.
        for (final entry in _subscriptions.entries.toList()) {
          _socket!.send(
            SocketMessenger(
              type: SocketType.subscribe,
              topic: entry.key,
              headers: _buildHeaders(),
              timestamp: DateTime.now(),
            ).encode(),
          );
        }

        // Auto-subscribe to configured subscription
        if (config.subscription != null && !_subscriptions.containsKey(config.subscription)) {
          subscribe(
            topic: config.subscription!,
            onMessage: (response) {
              // Default subscription handler - already handled in _handleMessage
            },
          );
        }
      });

      _socket!.onMessage(_handleMessage);

      _socket!.onError((error) {
        _handleError('WebSocket Error', '${error.message} (reason ${error.reason})');
        _updateConnectionState(ZyncState.disconnected);
        _stopPingTimer();
        _stopHeartbeat();
        
        // Attempt reconnection unless the caller disconnected manually
        // or the policy rejects this close.
        if (!_manualDisconnect && (config.shouldReconnect?.call(error) ?? true)) {
          _attemptReconnect();
        }
      });

      _socket!.onClose((close) {
        _stopPingTimer();
        _stopHeartbeat();
        
        if (config.showConnectionLogs) {
          Z.log('Zync: Connection closed - ${close.message} (reason ${close.reason})');
        }

        _updateConnectionState(ZyncState.disconnected);

        // A close is the most common trigger for reconnection (server
        // restart, load-balancer idle kill). Skip it when the caller
        // disconnected intentionally via [disconnect], or when the
        // configured policy rejects this close (e.g. fatal auth codes).
        if (!_manualDisconnect && (config.shouldReconnect?.call(close) ?? true)) {
          _attemptReconnect();
        }
      });

      // Connect to the WebSocket
      await _socket!.connect();
      
    } catch (e) {
      _handleError('Connection Error', e);
      _updateConnectionState(ZyncState.disconnected);
      if (!_manualDisconnect) {
        _attemptReconnect();
      }
    }
  }

  @override
  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _stopPingTimer();
    _stopHeartbeat();
    
    if (_socket != null) {
      _socket!.close();
      _socket!.dispose();
      _socket = null;
    }

    // Fail acknowledgement waiters: their replies cannot arrive on a
    // closed connection.
    for (final pending in _pendingAcks.values) {
      pending.completeError(ZapException.connection('Zync: connection closed before acknowledgement', null));
    }
    _pendingAcks.clear();
    for (final timer in _ackTimers.values) {
      timer.cancel();
    }
    _ackTimers.clear();
    
    // Stream controllers and registered handlers are intentionally kept
    // alive: [disconnect] is reversible — a later [connect] (or an
    // automatic reconnect) must keep delivering to existing listeners.
    // Controllers are closed only when the singleton is torn down via
    // [Zync.dispose].
    _updateConnectionState(ZyncState.disconnected);
    
    if (config.showConnectionLogs) {
      Z.log('Zync: Disconnected');
    }
  }

  @override
  void send({required String endpoint, required dynamic data, Headers? headers}) {
    if (!isConnected) {
      if (_sendTrials >= _maxSendTrials) {
        _handleError('Send Error', 'WebSocket not connected after $_maxSendTrials attempts');
        _resetSendTrial();
        return;
      }
      
      _sendTrials++;
      // Retry after a short delay
      Timer(const Duration(milliseconds: 500), () {
        send(endpoint: endpoint, data: data, headers: headers);
      });
      return;
    }

    try {
      _updateConnectionState(ZyncState.sending);
      
      _socket!.send(
        SocketMessenger(
          type: SocketType.send,
          endpoint: endpoint,
          data: data,
          headers: headers,
          timestamp: DateTime.now(),
        ).encode(),
      );
      
      _updateConnectionState(ZyncState.sent);
      _resetSendTrial();
      
      if (config.showSendLogs) {
        Z.info('Zync: Message sent to $endpoint');
      }
      
    } catch (e) {
      _updateConnectionState(ZyncState.notSent);
      _handleError('Send Error', e);
      _resetSendTrial();
    }
  }

  /// Sends a message and waits for the server to acknowledge it.
  ///
  /// [send] is fire-and-forget; this variant stamps the envelope with a
  /// generated `messageId` and completes when the server replies with a
  /// matching [SocketType.ack] (success — the ack envelope is returned)
  /// or [SocketType.nack] (failure — a [ZapException] is thrown). If no
  /// reply arrives within [timeout], or the connection drops first, the
  /// returned future fails with a [ZapException].
  ///
  /// ### Example
  /// ```dart
  /// final ack = await zync.sendWithAck(endpoint: '/orders', data: {'id': 42});
  /// print(ack.data); // server payload
  /// ```
  ///
  /// ### Edge cases
  /// - Throws immediately when the socket is not connected.
  /// - On reconnect, waiters from the previous connection are failed —
  ///   their replies cannot arrive.
  Future<SocketMessenger> sendWithAck({
    required String endpoint,
    required dynamic data,
    Headers? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isConnected) {
      throw ZapException.connection('Zync: cannot sendWithAck while disconnected', null);
    }

    final messageId = 'zap-ack-${DateTime.now().microsecondsSinceEpoch}-${++_ackCounter}';
    final completer = Completer<SocketMessenger>();
    _pendingAcks[messageId] = completer;

    _ackTimers[messageId] = Timer(timeout, () {
      final pending = _pendingAcks.remove(messageId);
      _ackTimers.remove(messageId);
      pending?.completeError(
        ZapException.timeout(
          'Zync: no acknowledgement for message $messageId after ${timeout.inMilliseconds}ms',
          null,
        ),
      );
    });

    final envelopeHeaders = _buildHeaders();
    if (headers != null) {
      envelopeHeaders.addAll(headers);
    }

    _socket!.send(
      SocketMessenger(
        type: SocketType.send,
        endpoint: endpoint,
        data: data,
        messageId: messageId,
        headers: envelopeHeaders,
        timestamp: DateTime.now(),
      ).encode(),
    );

    if (config.showSendLogs) {
      Z.info('Zync: Sent with ack ($messageId) to $endpoint');
    }

    return completer.future;
  }

  /// Completes the [sendWithAck] call registered for [envelope].
  void _completeAck(SocketMessenger envelope) {
    final messageId = envelope.messageId!;
    final pending = _pendingAcks.remove(messageId);
    _ackTimers.remove(messageId)?.cancel();

    if (pending == null) return;

    if (envelope.type == SocketType.ack) {
      pending.complete(envelope);
    } else {
      pending.completeError(
        ZapException.connection(
          'Zync: server nacked message $messageId: ${envelope.data}',
          null,
          {'envelope': envelope.toJson()},
        ),
      );
    }
  }

  @override
  void subscribe({required String topic, required ZyncMessage onMessage}) {
    _subscriptions[topic] = onMessage;
    
    if (isConnected) {
      _updateConnectionState(ZyncState.subscribing);
      
      _socket!.send(
        SocketMessenger(
          type: SocketType.subscribe,
          topic: topic,
          headers: _buildHeaders(),
          timestamp: DateTime.now(),
        ).encode(),
      );
      
      _updateConnectionState(ZyncState.subscribed);
      
      if (config.showConnectionLogs) {
        Z.log('Zync: Subscribed to $topic');
      }
    }
  }

  @override
  void unsubscribe(String topic) {
    _subscriptions.remove(topic);
    
    if (isConnected) {
      _socket!.send(
        SocketMessenger(
          type: SocketType.unsubscribe,
          topic: topic,
          headers: _buildHeaders(),
          timestamp: DateTime.now(),
        ).encode(),
      );
      
      if (config.showConnectionLogs) {
        Z.log('Zync: Unsubscribed from $topic');
      }
    }
  }

  @override
  void on(SocketType event, void Function(dynamic data) callback) {
    _eventListeners[event] = callback;
  }

  @override
  void off(SocketType event) {
    _eventListeners.remove(event);
  }

  @override
  void emit(SocketType event, dynamic data) {
    if (isConnected) {
      _socket!.send(
        SocketMessenger(
          type: event,
          data: data,
          headers: _buildHeaders(),
          timestamp: DateTime.now(),
        ).encode(),
      );
      
      if (config.showSendLogs) {
        Z.info('Zync: Event emitted - $event');
      }
    } else {
      _handleError('Emit Error', 'WebSocket not connected');
    }
  }

  /// Resets the send trial counter and updates connection state after delay.
  void _resetSendTrial() {
    _sendTrials = 0;
    
    Timer(const Duration(seconds: 2), () {
      if (isConnected) {
        _updateConnectionState(ZyncState.connected);
      }
    });
  }
}