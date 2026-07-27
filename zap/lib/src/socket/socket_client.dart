// Import the correct socket implementation based on platform.
// - On web (with `dart:js_interop`), it imports 'html_socket.dart'.
// - On native platforms (mobile, desktop, server with `dart:io`), it imports 'io_socket.dart'.
// - If neither is available, it falls back to 'socket_stub.dart', which throws errors.
//
// This allows SocketClient to work cross-platform without manually switching imports.
import 'src/stub_socket.dart'
    if (dart.library.js_interop) 'src/html_socket.dart'
    if (dart.library.io) 'src/io_socket.dart';

/// {@template socket_client}
/// Platform-agnostic WebSocket abstraction that delegates to the correct
/// implementation based on where the app is running.
///
/// `SocketClient` extends `BaseWebSocket` (from the appropriate platform
/// file) and provides a consistent WebSocket API across all platforms:
///
/// - **Web** (`dart:js_interop`): Uses `html_socket.dart` with the
///   `package:web` WebSocket API.
/// - **Mobile/Desktop/Server** (`dart:io`): Uses `io_socket.dart` with
///   `dart:io`'s `WebSocket`.
/// - **Stub**: If neither `dart:io` nor `dart:js_interop` is available,
///   `stub_socket.dart` throws `UnimplementedError`.
///
/// ### Example usage
///
/// ```dart
/// final socket = SocketClient('wss://example.com/socket');
/// socket.connect();
///
/// socket.onOpen(() => print('Connected!'));
/// socket.onMessage((msg) => print('Received: $msg'));
/// socket.onClose((close) => print('Disconnected: ${close.message}'));
///
/// socket.emit('chat', {'message': 'Hello!'});
/// ```
///
/// ### Connection lifecycle
///
/// 1. Construct with a URL
/// 2. Call [connect] to initiate the WebSocket handshake
/// 3. Listen for events via [onOpen], [onMessage], [onClose], [onError]
/// 4. Send data with [emit] or [send]
/// 5. Close with [close] when done
///
/// ### Ping/keep-alive
///
/// The [ping] parameter controls how often a ping message is sent to
/// keep the connection alive. Defaults to 5 seconds. Set to
/// `Duration.zero` to disable pings.
///
/// ### SSL/TLS
///
/// Set [allowSelfSigned] to `true` to allow connections to servers with
/// self-signed SSL certificates. This is insecure and should only be
/// used in development.
/// {@endtemplate}
class SocketClient extends BaseWebSocket {
  /// {@template socket_client_constructor}
  /// Creates a new [SocketClient] with the given WebSocket [url].
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL. Must use `ws://` or `wss://`
  ///   scheme. Example: `'wss://example.com/ws'`.
  /// - [ping]: The interval between ping messages to keep the connection
  ///   alive. Defaults to `Duration(seconds: 5)`. Set to `Duration.zero`
  ///   to disable pings.
  /// - [allowSelfSigned]: Whether to allow connections to servers with
  ///   self-signed SSL certificates. Defaults to `true`. Only set to
  ///   `false` in production.
  ///
  /// ### Platform behavior
  ///
  /// The actual behavior is determined by the imported platform-specific
  /// `BaseWebSocket` implementation. On web, it creates an HTML
  /// WebSocket. On mobile/desktop, it creates an IO WebSocket.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Standard secure connection
  /// final socket = SocketClient('wss://example.com/ws');
  ///
  /// // Custom ping interval
  /// final socket = SocketClient(
  ///   'wss://example.com/ws',
  ///   ping: Duration(seconds: 10),
  /// );
  ///
  /// // Development mode with self-signed certs
  /// final socket = SocketClient(
  ///   'ws://localhost:8080/ws',
  ///   allowSelfSigned: true,
  /// );
  /// ```
  /// {@endtemplate}
  /// {@macro socket_client}
  SocketClient(
    super.url, {
    super.ping,
    super.allowSelfSigned,
  });
}