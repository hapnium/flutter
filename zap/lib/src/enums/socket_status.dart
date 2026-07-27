/// {@template socket_status}
/// Represents the current connection state of a WebSocket.
///
/// `SocketStatus` tracks the lifecycle of a WebSocket connection from
/// initiation through disconnection. It is used to update UI state,
/// trigger reconnection logic, and manage connection health.
///
/// ### State machine
///
/// ```
/// connecting ──→ connected ──→ closed
///     │               │
///     └───────────────┘ (error)
/// ```
///
/// A socket starts in [connecting], transitions to [connected] when the
/// handshake completes, and moves to [closed] when the connection is
/// terminated (either gracefully or due to an error).
///
/// ### Example usage
/// ```dart
/// socket.onStatusChanged((status) {
///   switch (status) {
///     case SocketStatus.connecting:
///       _showSpinner();
///     case SocketStatus.connected:
///       _hideSpinner();
///       _enableMessaging();
///     case SocketStatus.closed:
///       _showDisconnectedMessage();
///       _attemptReconnect();
///   }
/// });
/// ```
/// {@endtemplate}
enum SocketStatus {
  /// {@template socket_status_connecting}
  /// The socket is in the process of establishing a connection.
  ///
  /// This status is set immediately after [connect] is called but before
  /// the WebSocket handshake completes. The connection is not yet ready
  /// for sending or receiving data.
  ///
  /// ### Typical UI response
  /// - Show a loading indicator
  /// - Disable send buttons
  /// - Display "Connecting..." message
  ///
  /// ### Duration
  ///
  /// This state is typically brief (milliseconds to seconds) unless:
  /// - The server is slow to respond
  /// - Network latency is high
  /// - The handshake involves authentication
  /// {@endtemplate}
  connecting,

  /// {@template socket_status_connected}
  /// The socket connection is successfully established and ready for use.
  ///
  /// Once in this state, data can be sent via [emit] and received via
  /// [onMessage]. The WebSocket handshake has completed and the connection
  /// is healthy.
  ///
  /// ### Typical UI response
  /// - Hide loading indicators
  /// - Enable send buttons
  /// - Display "Connected" indicator
  /// - Start sending queued messages
  ///
  /// ### Connection health
  ///
  /// This state persists as long as the connection remains open. Ping/pong
  /// messages (controlled by [ZapSocket]'s `ping` parameter) help detect
  /// if the connection drops silently.
  /// {@endtemplate}
  connected,

  /// {@template socket_status_closed}
  /// The socket connection has been closed or encountered a fatal error.
  ///
  /// This is a terminal state — the socket is no longer active and cannot
  /// be reused. A new connection must be established if reconnection is
  /// needed.
  ///
  /// ### Typical UI response
  /// - Display "Disconnected" message
  /// - Show reconnection option
  /// - Disable send buttons
  /// - Clear received data (optional)
  ///
  /// ### Transition causes
  ///
  /// - [close] was called explicitly
  /// - The server closed the connection
  /// - A network error occurred
  /// - The ping timeout expired
  /// - The SSL handshake failed
  ///
  /// ### Reconnection
  ///
  /// To reconnect, create a new [ZapSocket] instance:
  /// ```dart
  /// socket.onStatusChanged((status) {
  ///   if (status == SocketStatus.closed) {
  ///     socket = ZapSocket(url);
  ///     socket.connect();
  ///   }
  /// });
  /// ```
  /// {@endtemplate}
  closed,
}