// ignore_for_file: constant_identifier_names

/// {@template zync_state}
/// Defines the different states in which a WebSocket platform can operate.
///
/// `ZyncState` is used to manage and track the various phases of the
/// WebSocket lifecycle, including connection, subscription, message
/// sending, and disconnection. It helps configure environment-specific
/// behaviors, API endpoints, and real-time features depending on the
/// current state of the WebSocket connection.
///
/// ### State categories
///
/// The states can be grouped into four functional categories:
///
/// **Connection lifecycle:**
/// [dormant], [connecting], [connected], [disconnected]
///
/// **Subscription lifecycle:**
/// [subscribing], [subscribed]
///
/// **Message lifecycle:**
/// [sending], [sent], [notSent]
///
/// ### State machine
///
/// ```
/// dormant → connecting → connected → disconnected
///                  ↓          ↓
///              subscribing  sending → sent
///                  ↓          ↓
///              subscribed   notSent
/// ```
///
/// ### Example usage
/// ```dart
/// switch (state) {
///   case ZyncState.connected:
///     _enableRealTimeFeatures();
///   case ZyncState.disconnected:
///     _showReconnectOption();
///   case ZyncState.subscribed:
///     _startListeningToChannel();
/// }
/// ```
/// {@endtemplate}
enum ZyncState {
  /// {@template zync_state_dormant}
  /// The WebSocket has not attempted to establish a connection.
  ///
  /// This is the initial state before any connection activity begins.
  /// The socket exists but is not active. No data can be sent or received.
  ///
  /// ### Transition
  /// - → [connecting]: When a connection attempt is initiated
  ///
  /// ### Typical usage
  ///
  /// This state is common at app startup before the user triggers a
  /// connection, or after a deliberate disconnect when the user chooses
  /// not to reconnect.
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.dormant) {
  ///   // Socket is idle — safe to configure or destroy
  /// }
  /// ```
  /// {@endtemplate}
  dormant,

  /// {@template zync_state_connecting}
  /// The WebSocket is in the process of establishing a connection.
  ///
  /// A connection attempt has been initiated but the WebSocket handshake
  /// has not yet completed. No data can be sent or received in this state.
  ///
  /// ### Transition
  /// - → [connected]: Handshake completed successfully
  /// - → [disconnected]: Connection attempt failed
  ///
  /// ### Duration
  ///
  /// This state is typically brief (milliseconds to seconds) unless:
  /// - The server is slow to respond
  /// - Network latency is high
  /// - The handshake involves authentication
  ///
  /// ### UI response
  ///
  /// Show a loading indicator while in this state:
  /// ```dart
  /// if (state == ZyncState.connecting) {
  ///   return CircularProgressIndicator();
  /// }
  /// ```
  /// {@endtemplate}
  connecting,

  /// {@template zync_state_connected}
  /// The WebSocket is successfully connected to the server.
  ///
  /// The connection is live and communication can happen. Data can be
  /// sent via [sending] and received from the server.
  ///
  /// ### Transition
  /// - → [subscribing]: When subscribing to a channel
  /// - → [sending]: When sending a message
  /// - → [disconnected]: When the connection is lost
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.connected) {
  ///   // Ready to send and receive data
  ///   socket.emit('chat:join', {'room': 'general'});
  /// }
  /// ```
  ///
  /// ### Connection health
  ///
  /// This state persists as long as the connection remains open. Ping/pong
  /// messages help detect silent connection drops.
  /// {@endtemplate}
  connected,

  /// {@template zync_state_disconnected}
  /// The WebSocket is disconnected from the server.
  ///
  /// No data can be sent or received until the WebSocket reconnects. This
  /// is a terminal state for the current connection — a new connection
  /// must be established to resume communication.
  ///
  /// ### Transition
  /// - → [connecting]: When reconnection is initiated
  /// - → [dormant]: When reconnection is not attempted
  ///
  /// ### Causes
  /// - Server closed the connection
  /// - Network dropped
  /// - Ping timeout expired
  /// - Client explicitly disconnected
  /// - SSL handshake failure
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.disconnected) {
  ///   _showReconnectButton();
  ///   _attemptAutomaticReconnect();
  /// }
  /// ```
  /// {@endtemplate}
  disconnected,

  /// {@template zync_state_subscribing}
  /// The WebSocket is in the process of subscribing to a channel or topic.
  ///
  /// A subscription request has been sent to the server but the
  /// acknowledgment has not yet been received. Messages on the channel
  /// are not yet being forwarded.
  ///
  /// ### Transition
  /// - → [subscribed]: Subscription confirmed by server
  /// - → [connected]: Subscription failed (back to connected state)
  ///
  /// ### Duration
  ///
  /// This state is typically brief. If it persists, it may indicate:
  /// - Server is slow to process the subscription
  /// - Channel does not exist
  /// - Authentication required for the channel
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.subscribing) {
  ///   return Text('Subscribing to channel...');
  /// }
  /// ```
  /// {@endtemplate}
  subscribing,

  /// {@template zync_state_subscribed}
  /// The WebSocket has successfully subscribed to a channel or topic.
  ///
  /// The WebSocket is actively listening for incoming messages from the
  /// subscribed endpoint. Messages on this channel are now being
  /// forwarded to the client.
  ///
  /// ### Transition
  /// - → [connected]: When unsubscribing
  /// - → [disconnected]: When the connection is lost
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.subscribed) {
  ///   // Listening for messages on this channel
  ///   socket.onMessage('chat:general', (msg) {
  ///     _displayMessage(msg);
  ///   });
  /// }
  /// ```
  ///
  /// ### Multiple subscriptions
  ///
  /// A single WebSocket can be subscribed to multiple channels
  /// simultaneously. Each subscription is tracked independently.
  /// {@endtemplate}
  subscribed,

  /// {@template zync_state_sending}
  /// The WebSocket is in the process of sending a message.
  ///
  /// The message is being serialized and transmitted to the server. The
  /// message has not yet been acknowledged.
  ///
  /// ### Transition
  /// - → [sent]: Message successfully delivered and acknowledged
  /// - → [notSent]: Message delivery failed
  ///
  /// ### Duration
  ///
  /// This state is typically very brief (milliseconds). If it persists,
  /// it may indicate:
  /// - Large message payload
  /// - Slow network connection
  /// - Server is processing slowly
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.sending) {
  ///   return Text('Sending message...');
  /// }
  /// ```
  ///
  /// ### UI response
  ///
  /// Show a "sending" indicator (like the gray checkmarks in messaging
  /// apps) while in this state.
  /// {@endtemplate}
  sending,

  /// {@template zync_state_sent}
  /// The WebSocket has successfully sent a message.
  ///
  /// The message has been transmitted and acknowledged by the WebSocket
  /// client. The server has received the message.
  ///
  /// ### Transition
  /// - → [sending]: When sending another message
  /// - → [disconnected]: When the connection is lost
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.sent) {
  ///   // Show "delivered" indicator
  ///   _showMessageStatus(messageId, 'delivered');
  /// }
  /// ```
  ///
  /// ### Reliability
  ///
  /// This state confirms delivery to the WebSocket layer, not necessarily
  /// that the server has processed the message. For end-to-end
  /// confirmation, use application-level acknowledgments (e.g.,
  /// [SocketType.ack]).
  /// {@endtemplate}
  sent,

  /// {@template zync_state_notSent}
  /// The WebSocket failed to send a message.
  ///
  /// The message was not successfully delivered due to an error or
  /// disconnection. This is an error state that typically requires
  /// retry logic or user notification.
  ///
  /// ### Transition
  /// - → [sending]: When retrying the message
  /// - → [disconnected]: When the connection is lost
  ///
  /// ### Common causes
  /// - Connection was lost during transmission
  /// - Message was too large for the server
  /// - Server rejected the message
  /// - Serialization error
  /// - Rate limiting
  ///
  /// ### Example
  /// ```dart
  /// if (state == ZyncState.notSent) {
  ///   _showRetryOption(message);
  ///   _queueMessageForRetry(message);
  /// }
  /// ```
  ///
  /// ### Retry strategy
  ///
  /// Queue the failed message and retry with exponential backoff:
  /// ```dart
  /// void retryMessage(Message msg, int attempt) {
  ///   final delay = Duration(seconds: (1 << attempt).clamp(1, 30));
  ///   Future.delayed(delay, () {
  ///     socket.sendMessage(msg);
  ///   });
  /// }
  /// ```
  /// {@endtemplate}
  notSent,
}