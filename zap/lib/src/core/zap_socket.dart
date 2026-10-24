import '../socket/socket_client.dart';

/// {@template zap_socket}
/// Platform-agnostic WebSocket abstraction that delegates to the correct
/// implementation based on the compilation target.
///
/// `ZapSocket` extends `SocketClient` and automatically selects the
/// appropriate WebSocket backend:
///
/// - **Web** (`dart:html`): Uses `BaseWebSocket` from `html_socket.dart`.
///   This leverages the browser's native WebSocket API.
/// - **Mobile / Desktop / Server** (`dart:io`): Uses `BaseWebSocket` from
///   `io_socket.dart`. This wraps `dart:io`'s `WebSocket` for native
///   platforms.
/// - **Stub**: If neither `dart:io` nor `dart:js_interop` is available,
///   `socket_stub.dart` throws an `UnsupportedError` at runtime.
///
/// This class allows the rest of your app to use a consistent WebSocket API
/// regardless of platform, while the implementation details are handled
/// automatically by conditional imports.
///
/// ### Example usage
/// ```dart
/// final socket = ZapSocket('wss://example.com/socket');
/// socket.connect();
///
/// socket.onOpen(() {
///   print('Connected!');
///   socket.emit('chat', {'message': 'Hello!'});
/// });
///
/// socket.onMessage((data) {
///   print('Received: $data');
/// });
///
/// socket.onClose((reason) {
///   print('Disconnected: $reason');
/// });
/// ```
///
/// ### Connection lifecycle
///
/// 1. Construct with a URL.
/// 2. Call [connect] to initiate the connection.
/// 3. Listen for [onOpen], [onMessage], [onClose], [onError] events.
/// 4. Send data with [emit].
/// 5. Close with [close] when done.
///
/// ### Ping / keep-alive
///
/// The [ping] parameter controls how often a ping message is sent to keep
/// the connection alive. The default is 5 seconds. Set to `Duration.zero`
/// to disable pings.
///
/// ### SSL / TLS
///
/// Set [allowSelfSigned] to `true` to allow connections to servers with
/// self-signed SSL certificates. This is insecure and should only be used
/// in development. Defaults to `false`.
/// {@endtemplate}
class ZapSocket extends SocketClient {
  /// {@template zap_socket_constructor}
  /// Creates a new [ZapSocket] with the given WebSocket [url].
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL. Must use the `ws://` or `wss://`
  ///   scheme. Example: `'wss://example.com/ws'`.
  /// - [ping]: The interval between ping messages used to detect dead
  ///   connections and keep the connection alive. Defaults to
  ///   `Duration(seconds: 5)`. Set to `Duration.zero` to disable pings.
  /// - [allowSelfSigned]: Whether to allow connections to servers with
  ///   self-signed SSL certificates. Defaults to `false`. Only set to
  ///   `true` in development environments.
  ///
  /// ### Example
  /// ```dart
  /// // Standard secure connection
  /// final socket = ZapSocket('wss://example.com/ws');
  ///
  /// // Custom ping interval
  /// final socket = ZapSocket(
  ///   'wss://example.com/ws',
  ///   ping: Duration(seconds: 10),
  /// );
  ///
  /// // Development mode with self-signed certs
  /// final socket = ZapSocket(
  ///   'ws://localhost:8080/ws',
  ///   allowSelfSigned: true,
  /// );
  /// ```
  ///
  /// ### Platform behavior
  ///
  /// The actual behavior of this constructor is determined by the imported
  /// platform-specific `BaseWebSocket` implementation. On web, it creates
  /// an HTML WebSocket. On mobile/desktop, it creates an IO WebSocket.
  /// On unsupported platforms, it throws.
  /// {@endtemplate}
  /// {@macro zap_socket}
  ZapSocket(
    super.url, {
    super.ping,
    super.allowSelfSigned,
    super.connectTimeout,
  });
}