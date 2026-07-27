/// {@template socket_close}
/// Wrapper class encapsulating information about a WebSocket close event.
///
/// `SocketClose` provides structured information when a WebSocket
/// connection is closed or encounters an error. It includes both a
/// human-readable [message] and a numeric [reason] code.
///
/// ### WebSocket close codes
///
/// Common close codes include:
/// - `1000`: Normal closure
/// - `1001`: Going away (page navigating away)
/// - `1002`: Protocol error
/// - `1003`: Unsupported data type
/// - `1006`: Abnormal closure (no close frame received)
/// - `1007`: Invalid data within a message
/// - `1008`: Policy violation
/// - `1009`: Message too large
/// - `1010`: Mandatory extension not supported
/// - `1011`: Internal server error
/// - `1012`: Service restart
/// - `1013`: Try again later
/// - `1014`: Bad gateway
/// - `1015`: TLS handshake failure
///
/// ### Example
///
/// ```dart
/// socket.onClose((SocketClose close) {
///   print(close);
///   // Output: Closed by server [1000 => Normal Closure]!
/// });
/// ```
///
/// ### Usage in error handling
///
/// ```dart
/// socket.onClose((close) {
///   if (close.reason == 1006) {
///     // Abnormal closure -- attempt reconnection
///     _scheduleReconnect();
///   } else if (close.reason == 1000) {
///     // Normal closure -- no action needed
///   }
/// });
/// ```
/// {@endtemplate}
class SocketClose {
  /// {@template socket_close_message}
  /// A textual explanation of the reason for the socket closure.
  ///
  /// This can be provided by the server or constructed internally to
  /// describe why the socket was closed or failed.
  ///
  /// ### Examples
  ///
  /// - `"Normal Closure"`
  /// - `"Connection Closed"`
  /// - `"Protocol Error"`
  /// - `"Bad Certificate"`
  ///
  /// ### Null safety
  ///
  /// This field is nullable. Some close events may not include a
  /// message (e.g., when the connection drops silently).
  /// {@endtemplate}
  final String? message;

  /// {@template socket_close_reason}
  /// A numeric reason code for the closure, typically matching WebSocket
  /// close status codes.
  ///
  /// This helps with debugging and protocol-specific handling. The code
  /// follows the WebSocket close code registry (RFC 6455 Section 7.4).
  ///
  /// ### Common codes
  ///
  /// - `1000`: Normal closure
  /// - `1006`: Abnormal closure
  /// - `1011`: Server error
  /// - `1015`: TLS handshake failure
  ///
  /// ### Null safety
  ///
  /// This field is nullable. Some close events may not include a
  /// numeric code (e.g., when the error is not protocol-level).
  /// {@endtemplate}
  final int? reason;

  /// {@template socket_close_constructor}
  /// Constructs a [SocketClose] object with a [message] and [reason].
  ///
  /// ### Parameters
  ///
  /// - [message]: Human-readable description of the close event.
  /// - [reason]: Numeric close code (WebSocket close status code).
  ///
  /// ### Example
  ///
  /// ```dart
  /// final close = SocketClose('Normal Closure', 1000);
  /// print(close.message); // 'Normal Closure'
  /// print(close.reason);  // 1000
  /// ```
  /// {@endtemplate}
  /// {@macro socket_close}
  SocketClose(this.message, this.reason);

  /// {@template socket_close_toString}
  /// Returns a formatted string representation of the close event.
  ///
  /// The format is:
  /// ```
  /// Closed by server [<reason> => <message>]!
  /// ```
  ///
  /// ### Example
  ///
  /// ```dart
  /// final close = SocketClose('Normal Closure', 1000);
  /// print(close);
  /// // Output: Closed by server [1000 => Normal Closure]!
  /// ```
  ///
  /// ### Usage in logging
  ///
  /// ```dart
  /// socket.onClose((close) {
  ///   Z.info(close.toString());
  /// });
  /// ```
  /// {@endtemplate}
  @override
  String toString() {
    return 'Closed by server [$reason => $message]!';
  }
}