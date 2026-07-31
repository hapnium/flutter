import 'dart:async';
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
  static void dispose() {
    _instance?.disconnect();
    _instance = null;
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
    try {
      ZyncResponse response;
      
      if (message is String) {
        // Try to parse as JSON
        try {
          final data = SocketMessenger.decode(message);
          response = ZyncResponse(
            type: data.type,
            body: message,
            data: data,
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

      // Handle subscriptions
      if (response.type != null && _subscriptions.containsKey(response.type!.name)) {
        _subscriptions[response.type!.name]?.call(response);
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
  void _handleError(String where, dynamic error) {
    final errorResponse = ZyncErrorResponse(where: where, error: error);
    
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

    _reconnectTimer = Timer(config.reconnectDelay, () {
      connect();
    });
  }

  @override
  Future<void> connect() async {
    try {
      _updateConnectionState(ZyncState.connecting);
      
      if (config.showConnectionLogs) {
        Z.log('Zync: Connecting to ${config.url}');
      }

      // Create new socket instance
      _socket = ZapSocket(config.url, ping: config.pingInterval);

      // Set up event handlers
      _socket!.onOpen(() {
        _reconnectAttempts = 0; // Reset reconnection counter
        _updateConnectionState(ZyncState.connected);
        _startPingTimer();
        
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

        // Auto-subscribe to configured subscription
        if (config.subscription != null) {
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
        _handleError('WebSocket Error', error.message);
        _updateConnectionState(ZyncState.disconnected);
        _stopPingTimer();
        
        // Attempt reconnection
        _attemptReconnect();
      });

      _socket!.onClose((close) {
        _updateConnectionState(ZyncState.disconnected);
        _stopPingTimer();
        
        if (config.showConnectionLogs) {
          Z.log('Zync: Connection closed - ${close.message}');
        }

        // Attempt reconnection if not manually disconnected
        if (_connectionState != ZyncState.disconnected) {
          _attemptReconnect();
        }
      });

      // Connect to the WebSocket
      await _socket!.connect();
      
    } catch (e) {
      _handleError('Connection Error', e);
      _updateConnectionState(ZyncState.disconnected);
      _attemptReconnect();
    }
  }

  @override
  void disconnect() {
    _reconnectTimer?.cancel();
    _stopPingTimer();
    
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
    
    _subscriptions.clear();
    _eventListeners.clear();
    _updateConnectionState(ZyncState.disconnected);
    
    // Close stream controllers
    _connectionStateController.close();
    _dataStreamController.close();
    _errorStreamController.close();
    
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