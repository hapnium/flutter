import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as html;

import '../../core/zap_inst.dart';
import '../../enums/socket_type.dart';
import '../../models/socket_messenger.dart';
import 'socket_close.dart';
import 'socket_interface.dart';
import 'socket_notifier.dart';
import '../../enums/socket_status.dart';

/// {@template html_socket}
/// Browser-specific WebSocket implementation using `package:web`.
///
/// `BaseWebSocket` manages a WebSocket connection in a web context,
/// providing lifecycle management, event subscription, and typed message
/// dispatching. It is the platform-specific implementation of
/// [SocketInterface] for web environments.
///
/// ### Architecture
///
/// This class wraps the browser's native `WebSocket` API (via
/// `package:web`) and delegates event handling to [SocketNotifier].
/// It automatically converts HTTP(S) URLs to WS(S) schemes.
///
/// ### Example
///
/// ```dart
/// final ws = BaseWebSocket('wss://example.com/socket');
/// ws.connect();
/// ws.onOpen(() => print('Connected!'));
/// ws.onMessage((msg) => print('Received: $msg'));
/// ws.emit('chat', {'text': 'Hello'});
/// ```
///
/// ### Connection lifecycle
///
/// 1. Constructor converts URL scheme (http->ws, https->wss)
/// 2. [connect] creates the WebSocket and sets up event listeners
/// 3. On open: starts ping timer, triggers [onOpen] callback
/// 4. On message: dispatches to [SocketNotifier]
/// 5. On close/error: cancels ping timer, triggers close/error callbacks
/// 6. [dispose] cleans up all resources
///
/// ### Ping mechanism
///
/// On web, ping is implemented by sending empty strings at regular
/// intervals. This is a workaround because the browser WebSocket API
/// does not have native ping/pong support.
/// {@endtemplate}
class BaseWebSocket extends SocketInterface {
  /// {@template html_socket_socket}
  /// Underlying WebSocket instance from the `web` package.
  ///
  /// This is the browser's native WebSocket object. It is `null` before
  /// [connect] is called and after [dispose].
  /// {@endtemplate}
  html.WebSocket? socket;

  /// {@template html_socket_socketNotifier}
  /// Socket event notifier for managing subscribers and dispatch.
  ///
  /// The notifier handles all event registration and message dispatching.
  /// It is `null` after [dispose] is called.
  /// {@endtemplate}
  SocketNotifier? socketNotifier = SocketNotifier();

  /// {@template html_socket_isDisposed}
  /// Whether this socket has been disposed.
  ///
  /// After disposal, the socket cannot be reused. A new instance must
  /// be created.
  /// {@endtemplate}
  bool isDisposed = false;

  /// {@template html_socket_connectionStatus}
  /// The current connection status.
  ///
  /// Tracks the WebSocket lifecycle through [SocketStatus] values:
  /// - `connecting`: Handshake in progress
  /// - `connected`: Ready for data transfer
  /// - `closed`: Connection terminated
  /// {@endtemplate}
  SocketStatus? connectionStatus;

  /// {@template html_socket_pingTimer}
  /// Timer used for sending periodic ping messages.
  ///
  /// Sends empty strings at the configured [ping] interval to keep the
  /// connection alive. Cancelled on close, error, or disposal.
  /// {@endtemplate}
  Timer? _t;
  Timer? _connectTimeoutTimer;

  /// {@template html_socket_subscriptions}
  /// Subscriptions to the underlying WebSocket event streams.
  ///
  /// All entries are cancelled on re-[connect] and [dispose] so no
  /// events are delivered to a torn-down [SocketNotifier] and no
  /// duplicate listeners accumulate across reconnects.
  /// {@endtemplate}
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// {@template html_socket_constructor}
  /// Creates a new [BaseWebSocket] instance.
  ///
  /// The [url] is automatically converted from HTTP(S) to WS(S):
  /// - `https://example.com` -> `wss://example.com`
  /// - `http://example.com` -> `ws://example.com`
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL.
  /// - [ping]: Ping interval. Defaults to 5 seconds.
  /// - [allowSelfSigned]: Whether to allow self-signed certificates.
  ///   Defaults to `false` (unused on web; the browser handles TLS).
  ///
  /// ### Example
  ///
  /// ```dart
  /// final ws = BaseWebSocket(
  ///   'https://example.com/socket',
  ///   ping: Duration(seconds: 10),
  /// );
  /// // URL is converted to 'wss://example.com/socket'
  /// ```
  /// {@endtemplate}
  /// {@macro html_socket}
  BaseWebSocket(
    super.url, {
    super.ping = const Duration(seconds: 5),
    super.allowSelfSigned = false,
    super.connectTimeout,
  }) {
    url = url.startsWith('https')
        ? url.replaceAll('https:', 'wss:')
        : url.replaceAll('http:', 'ws:');
  }

  /// {@template html_socket_close}
  /// Closes the WebSocket connection.
  ///
  /// Optionally provides a [status] code and [reason] message. Handles
  /// quirks in the `web` package regarding optional parameters.
  ///
  /// ### Parameters
  ///
  /// - [status]: Optional close status code.
  /// - [reason]: Optional close reason string.
  ///
  /// ### Behavior
  ///
  /// - If both [status] and [reason] are provided, both are sent
  /// - If only [status] is provided, only the status is sent
  /// - If neither is provided, the connection is closed without a frame
  /// {@endtemplate}
  @override
  void close([int? status, String? reason]) {
    if (status != null && reason != null) {
      socket?.close(status, reason);
    } else if (status != null) {
      socket?.close(status);
    } else {
      socket?.close();
    }
  }

  /// {@template html_socket_connect}
  /// Connects to the WebSocket server.
  ///
  /// Creates the browser WebSocket, sets up event listeners for open,
  /// message, close, and error events, and starts the ping timer.
  ///
  /// ### Behavior
  ///
  /// 1. Sets status to [SocketStatus.connecting]
  /// 2. Creates `html.WebSocket` with the converted URL
  /// 3. Registers `onOpen` listener: starts ping timer, sets status
  ///   to [SocketStatus.connected]
  /// 4. Registers `onMessage` listener: dispatches to [SocketNotifier]
  /// 5. Registers `onClose` listener: cancels ping timer, sets status
  ///   to [SocketStatus.closed]
  /// 6. Registers `onError` listener: cancels ping timer, notifies
  ///   error listeners
  ///
  /// ### Error handling
  ///
  /// If the WebSocket constructor throws, the error is caught and
  /// dispatched to error listeners with status code 500.
  /// {@endtemplate}
  // ignore: use_setters_to_change_properties
  @override
  Future<void> connect() async {
    try {
      connectionStatus = SocketStatus.connecting;

      // Detach from any previous connection before replacing it, so
      // reconnects never deliver events for two sockets at once and
      // ping timers never accumulate.
      _t?.cancel();
      _t = null;
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      socket = html.WebSocket(url);

      // Fail the handshake instead of hanging if the server never opens
      // the connection.
      if (connectTimeout > Duration.zero) {
        _connectTimeoutTimer?.cancel();
        _connectTimeoutTimer = Timer(connectTimeout, () {
          if (connectionStatus == SocketStatus.connecting) {
            socket?.close();
            connectionStatus = SocketStatus.closed;
            socketNotifier?.notifyError(SocketClose('Connection timed out after ${connectTimeout.inMilliseconds}ms', 0));
          }
        });
      }

      _subscriptions.add(socket!.onOpen.listen((e) {
        _connectTimeoutTimer?.cancel();
        connectionStatus = SocketStatus.connected;
        socketNotifier?.open();
        // A zero interval means "disable pings"; Timer.periodic(zero)
        // would otherwise flood the server with empty frames.
        if (ping > Duration.zero) {
          _t = Timer.periodic(ping, (t) {
            socket?.send(''.toJSBox);
          });
        }
      }));

      _subscriptions.add(socket!.onMessage.listen((event) {
        socketNotifier?.notifyData(event.data);
      }));

      _subscriptions.add(socket!.onClose.listen((e) {
        _t?.cancel();
        _connectTimeoutTimer?.cancel();

        connectionStatus = SocketStatus.closed;
        socketNotifier?.notifyClose(SocketClose(e.reason, e.code));
      }));
      _subscriptions.add(socket!.onError.listen((event) {
        _t?.cancel();
        _connectTimeoutTimer?.cancel();
        socketNotifier?.notifyError(SocketClose(event.toString(), 0));
        connectionStatus = SocketStatus.closed;
      }));
    } on Exception catch (e) {
      _t?.cancel();
      socketNotifier?.notifyError(SocketClose(e.toString(), 500));
      connectionStatus = SocketStatus.closed;
      //  close(500, e.toString());
    }
  }

  /// {@template html_socket_dispose}
  /// Disposes of the socket, removing all listeners and closing the
  /// connection.
  ///
  /// After calling this method:
  /// - All event subscriptions are cancelled and the socket is closed
  /// - The ping timer is cancelled
  /// - The [socketNotifier] is set to `null`
  /// - [isDisposed] is set to `true`
  /// - The socket cannot be reused
  /// {@endtemplate}
  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _t?.cancel();
    _t = null;
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
    socket?.close();
    socket = null;
    connectionStatus = SocketStatus.closed;
    socketNotifier?.dispose();
    socketNotifier = null;
    isDisposed = true;
  }

  /// {@template html_socket_emit}
  /// Emits a named event to the server with optional payload data.
  ///
  /// Wraps the data in a [SocketMessenger] and sends it as a JSON string.
  ///
  /// ### Parameters
  ///
  /// - [command]: The [SocketType] event to emit.
  /// - [data]: The payload data.
  ///
  /// ### Message format
  ///
  /// ```json
  /// {"type": "send", "data": {"message": "Hello!"}}
  /// ```
  /// {@endtemplate}
  @override
  void emit(SocketType command, dynamic data) {
    send(SocketMessenger.simple(command: command, data: data).encode());
  }

  /// {@template html_socket_on}
  /// Registers a named event listener.
  ///
  /// ### Parameters
  ///
  /// - [command]: The [SocketType] to listen for.
  /// - [message]: The callback to invoke when the event is received.
  /// {@endtemplate}
  @override
  void on(SocketType command, MessageSocket message) {
    socketNotifier?.addEvents(command, message);
  }

  /// {@template html_socket_onClose}
  /// Registers a callback for when the socket is closed.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with [SocketClose] details.
  /// {@endtemplate}
  @override
  void onClose(CloseSocket fn) {
    socketNotifier?.addCloses(fn);
  }

  /// {@template html_socket_onError}
  /// Registers a callback for socket error events.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with [SocketClose] error details.
  /// {@endtemplate}
  @override
  void onError(CloseSocket fn) {
    socketNotifier?.addErrors(fn);
  }

  /// {@template html_socket_onMessage}
  /// Registers a callback for incoming messages.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with each message.
  /// {@endtemplate}
  @override
  void onMessage(MessageSocket fn) {
    socketNotifier?.addMessages(fn);
  }

  /// {@template html_socket_onOpen}
  /// Registers a callback for when the socket connection is opened.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke when connected.
  /// {@endtemplate}
  @override
  void onOpen(OpenSocket fn) {
    socketNotifier?.open = fn;
  }
  
  /// {@template html_socket_send}
  /// Sends data over the WebSocket connection.
  ///
  /// If the connection is closed, attempts to reconnect. If the socket
  /// is open, sends the data immediately. If the socket is not open,
  /// logs a warning.
  ///
  /// ### Parameters
  ///
  /// - [data]: The data to send.
  ///
  /// ### Behavior
  ///
  /// 1. If [connectionStatus] is [SocketStatus.closed], calls [connect]
  /// 2. If socket is open (`readyState == OPEN`), sends the data
  /// 3. Otherwise, logs a warning via [Z.log]
  /// {@endtemplate}
  @override
  void send(Object data) {
    if (connectionStatus == SocketStatus.closed) {
      connect();
    }

    if (socket != null && socket!.readyState == html.WebSocket.OPEN) {
      socket!.send(data.toJSBox);
    } else {
      Z.log('WebSocket not connected, message $data not sent');
    }
  }
}