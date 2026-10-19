import '../../enums/socket_type.dart';
import '../../exceptions/zap_exception.dart';
import 'socket_notifier.dart';

/// {@template socket_interface}
/// Abstract interface defining the contract for all WebSocket implementations.
///
/// `SocketInterface` provides the base structure that platform-specific
/// WebSocket clients (HTML, IO, Stub) must implement. It defines methods
/// for connecting, sending, receiving, and closing WebSocket connections.
///
/// ### Platform implementations
///
/// - `html_socket.dart`: Browser WebSocket via `package:web`
/// - `io_socket.dart`: Native WebSocket via `dart:io`
/// - `stub_socket.dart`: Fallback that throws on all operations
///
/// ### Method contracts
///
/// All methods in this interface throw [ZapException] by default. Platform
/// implementations must override every method to provide actual functionality.
///
/// ### Example
///
/// ```dart
/// // Never use SocketInterface directly
/// // Use SocketClient instead
/// final socket = SocketClient('wss://example.com/ws');
/// socket.connect();
/// ```
/// {@endtemplate}
abstract class SocketInterface {
  /// {@template socket_interface_url}
  /// The WebSocket server URL to connect to.
  ///
  /// This should use the `ws://` or `wss://` scheme. HTTP(S) URLs are
  /// automatically converted to WS(S) by the platform implementations.
  ///
  /// ### Example
  ///
  /// ```dart
  /// print(socket.url); // 'wss://example.com/ws'
  /// ```
  /// {@endtemplate}
  String url;

  /// {@template socket_interface_ping}
  /// The interval at which ping messages are sent to keep the connection
  /// alive.
  ///
  /// Defaults to `Duration(seconds: 5)`. Set to `Duration.zero` to
  /// disable periodic pings.
  ///
  /// ### Behavior
  ///
  /// - On web: An empty string is sent as a ping
  /// - On IO: Uses `WebSocket.pingInterval`
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Custom ping interval
  /// final socket = SocketClient('wss://example.com/ws', ping: Duration(seconds: 10));
  /// ```
  /// {@endtemplate}
  Duration ping;

  /// {@template socket_interface_allowSelfSigned}
  /// Whether to allow connections to servers with self-signed SSL
  /// certificates.
  ///
  /// Defaults to `false`. Only set to `true` in development environments;
  /// leaving it enabled in production allows man-in-the-middle attacks.
  ///
  /// ### Security note
  ///
  /// Self-signed certificates are insecure and should only be used in
  /// development environments. In production, always validate certificates
  /// to prevent man-in-the-middle attacks.
  ///
  /// ### Platform support
  ///
  /// - On web: Not applicable (browser handles SSL)
  /// - On IO: Creates a custom `SecurityContext` that accepts all
  ///   certificates
  /// {@endtemplate}
  bool allowSelfSigned;

  /// {@template socket_interface_connectTimeout}
  /// The maximum time allowed for the initial connection handshake.
  ///
  /// Defaults to 15 seconds. If the WebSocket is not open within this
  /// window, the connection attempt fails with an error notification
  /// instead of hanging indefinitely (dart:io in particular can stall
  /// for minutes on some networks).
  /// {@endtemplate}
  Duration connectTimeout;

  /// {@template socket_interface_constructor}
  /// Initializes the socket connection parameters.
  ///
  /// This constructor is only intended to be called by platform-specific
  /// subclasses (via `super`). The base implementation of [connect] and
  /// the event-registration methods throw [ZapException] / are no-ops
  /// until a platform subclass provides a real implementation.
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL.
  /// - [ping]: Optional ping interval. Defaults to 5 seconds.
  /// - [allowSelfSigned]: Whether to allow insecure certificates.
  ///   Defaults to `false`.
  /// - [connectTimeout]: Maximum handshake duration. Defaults to 15
  ///   seconds.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Thrown by the base [connect] implementation.
  ///   Use platform-specific implementations instead.
  /// {@endtemplate}
  /// {@macro socket_interface}
  SocketInterface(
    this.url, {
    this.ping = const Duration(seconds: 5),
    this.allowSelfSigned = false,
    this.connectTimeout = const Duration(seconds: 15),
  });

  /// {@template socket_interface_connect}
  /// Connects to the WebSocket server.
  ///
  /// Initiates the WebSocket handshake and sets up event listeners for
  /// messages, errors, and close events.
  ///
  /// ### Behavior
  ///
  /// - Sets connection status to `connecting`
  /// - Performs WebSocket handshake
  /// - On success: triggers [onOpen] callback and sets status to `connected`
  /// - On failure: triggers [onError] callback and sets status to `closed`
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  Future connect() async {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_onOpen}
  /// Registers a callback for when the socket connection is successfully
  /// opened.
  ///
  /// The callback is invoked once the WebSocket handshake completes and
  /// the connection is ready for data transfer.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke when the connection opens.
  ///
  /// ### Example
  ///
  /// ```dart
  /// socket.onOpen(() {
  ///   print('Connected!');
  ///   socket.emit('auth', {'token': 'abc123'});
  /// });
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void onOpen(OpenSocket fn) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_onClose}
  /// Registers a callback for when the socket is closed.
  ///
  /// The callback receives a [SocketClose] object with the close reason
  /// and status code.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke when the connection closes.
  ///
  /// ### Example
  ///
  /// ```dart
  /// socket.onClose((close) {
  ///   print('Disconnected: ${close.message} (code: ${close.reason})');
  /// });
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void onClose(CloseSocket fn) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_onError}
  /// Registers a callback for socket error events.
  ///
  /// The callback receives a [SocketClose] object with error details.
  /// Errors do not necessarily close the connection -- the socket may
  /// still be usable after an error.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke when an error occurs.
  ///
  /// ### Example
  ///
  /// ```dart
  /// socket.onError((close) {
  ///   Z.error('Socket error: ${close.message}');
  /// });
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void onError(CloseSocket fn) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_onMessage}
  /// Registers a callback for incoming messages.
  ///
  /// The callback is triggered for every message received on the socket,
  /// regardless of event type or format.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with each message.
  ///
  /// ### Example
  ///
  /// ```dart
  /// socket.onMessage((data) {
  ///   print('Received: $data');
  /// });
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void onMessage(MessageSocket fn) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_on}
  /// Registers a named event listener.
  ///
  /// If a message contains a `"type"` field that matches [command], the
  /// [message] callback is invoked with the corresponding `"data"` value.
  ///
  /// ### Parameters
  ///
  /// - [command]: The [SocketType] event to listen for.
  /// - [message]: The callback to invoke when the event is received.
  ///
  /// ### Example
  ///
  /// ```dart
  /// socket.on(SocketType.receive, (data) {
  ///   print('Chat message: $data');
  /// });
  /// ```
  ///
  /// ### Message format
  ///
  /// Expected JSON format:
  /// ```json
  /// {"type": "receive", "data": {"text": "Hello!"}}
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void on(SocketType command, MessageSocket message) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_close}
  /// Closes the WebSocket connection.
  ///
  /// Optionally provides a [status] code and [reason] message following
  /// the WebSocket close protocol.
  ///
  /// ### Parameters
  ///
  /// - [status]: Optional close status code (e.g., 1000 for normal
  ///   closure).
  /// - [reason]: Optional human-readable close reason.
  ///
  /// ### Common close codes
  ///
  /// - `1000`: Normal closure
  /// - `1001`: Going away
  /// - `1002`: Protocol error
  /// - `1003`: Unsupported data
  /// - `1006`: Abnormal closure (no close frame)
  /// - `1011`: Server error
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void close([int? status, String? reason]) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_send}
  /// Sends data over the WebSocket connection.
  ///
  /// The [data] can be a String or any serializable object. The data is
  /// sent as-is without additional encoding.
  ///
  /// ### Parameters
  ///
  /// - [data]: The data to send. Can be a String, Map, List, or any
  ///   object that can be serialized.
  ///
  /// ### Behavior
  ///
  /// - If the connection is closed, attempts to reconnect
  /// - If the socket is open, sends the data immediately
  /// - If the socket is not open, logs a warning
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void send(Object data) async {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_dispose}
  /// Disposes of the socket, removing all listeners and closing the
  /// connection.
  ///
  /// After calling this method, the socket should not be used. All
  /// registered event listeners are cleared and the underlying connection
  /// is closed.
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void dispose() {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }

  /// {@template socket_interface_emit}
  /// Emits a named event to the server with optional payload data.
  ///
  /// This sends a JSON message with fields `"type"` and `"data"`. The
  /// server can listen for these events using the corresponding event
  /// name.
  ///
  /// ### Parameters
  ///
  /// - [command]: The [SocketType] event to emit.
  /// - [data]: The payload data to send with the event.
  ///
  /// ### Example
  ///
  /// ```dart
  /// socket.emit(SocketType.send, {'message': 'Hello!'});
  /// socket.emit(SocketType.subscribe, {'channel': 'chat'});
  /// ```
  ///
  /// ### Message format
  ///
  /// The sent message is formatted as:
  /// ```json
  /// {"type": "send", "data": {"message": "Hello!"}}
  /// ```
  ///
  /// ### Throws
  ///
  /// - [ZapException]: Always thrown by the base class.
  /// {@endtemplate}
  void emit(SocketType command, dynamic data) {
    throw ZapException('To use sockets you need dart:io or dart:html');
  }
}