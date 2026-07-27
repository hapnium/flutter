/// {@template socket_type}
/// Defines all supported WebSocket operation types that can occur in a
/// real-time connection.
///
/// `SocketType` represents the various lifecycle events, commands, and
/// message types involved in WebSocket communication. It is used to
/// classify outgoing and incoming messages, control socket behavior,
/// and handle connection events.
///
/// ### Categories
///
/// The values can be grouped into four functional categories:
///
/// **Connection management:**
/// [connect], [disconnect], [reconnect], [open], [close]
///
/// **Data transfer:**
/// [send], [receive], [ack], [nack]
///
/// **Keep-alive:**
/// [ping], [pong]
///
/// **Lifecycle:**
/// [subscribe], [unsubscribe], [auth], [timeout], [retry], [error]
///
/// ### Example usage
/// ```dart
/// socket.onEvent((type, data) {
///   switch (type) {
///     case SocketType.open:
///       _onConnected();
///     case SocketType.message:
///       _handleMessage(data);
///     case SocketType.close:
///       _onDisconnected();
///   }
/// });
/// ```
/// {@endtemplate}
enum SocketType {
  /// {@template socket_type_connect}
  /// Initiates a new socket connection to the server.
  ///
  /// This is the first step in establishing WebSocket communication.
  /// Sending a `connect` event triggers the WebSocket handshake with the
  /// server.
  ///
  /// ### Behavior
  /// - Triggers the WebSocket upgrade request
  /// - Sets [SocketStatus.connecting]
  /// - On success, transitions to [SocketType.open]
  /// - On failure, transitions to [SocketType.error]
  ///
  /// ### Example
  /// ```dart
  /// socket.emit(SocketType.connect, {'url': 'wss://example.com'});
  /// ```
  /// {@endtemplate}
  connect,

  /// {@template socket_type_disconnect}
  /// Gracefully closes the existing socket connection.
  ///
  /// Sends a close frame to the server and waits for acknowledgment.
  /// This is the preferred way to terminate a connection, as opposed to
  /// abruptly closing the socket.
  ///
  /// ### Behavior
  /// - Sends a WebSocket close frame with a status code
  /// - Waits for the server to acknowledge the close
  /// - Sets [SocketStatus.closed]
  /// - Triggers cleanup of event listeners
  ///
  /// ### Example
  /// ```dart
  /// socket.emit(SocketType.disconnect, {'reason': 'User logout'});
  /// ```
  ///
  /// ### When to use
  /// - User logs out
  /// - App is being terminated
  /// - Switching to a different WebSocket server
  /// {@endtemplate}
  disconnect,

  /// {@template socket_type_reconnect}
  /// Attempts to re-establish a lost or closed socket connection.
  ///
  /// This event is typically triggered automatically after a connection
  /// drop, or manually by the application. It re-runs the connection
  /// handshake using the original URL and configuration.
  ///
  /// ### Behavior
  /// - Creates a new WebSocket connection using the original URL
  /// - Sets [SocketStatus.connecting]
  /// - May use exponential backoff for retry attempts
  /// - Preserves event listeners from the previous connection
  ///
  /// ### Example
  /// ```dart
  /// socket.emit(SocketType.reconnect, {'attempt': 3});
  /// ```
  ///
  /// ### Retry strategy
  ///
  /// Implement exponential backoff to avoid overwhelming the server:
  /// ```dart
  /// int attempt = 0;
  /// void reconnect() {
  ///   final delay = Duration(seconds: (1 << attempt).clamp(1, 30));
  ///   Future.delayed(delay, () {
  ///     socket.emit(SocketType.reconnect, {'attempt': attempt++});
  ///   });
  /// }
  /// ```
  /// {@endtemplate}
  reconnect,

  /// {@template socket_type_error}
  /// An error occurred during socket communication.
  ///
  /// This event is emitted when the socket encounters an error condition,
  /// such as a protocol violation, unexpected message format, or internal
  /// failure. It does not necessarily mean the connection is closed.
  ///
  /// ### Behavior
  /// - The connection may remain open
  /// - Error details are included in the event payload
  /// - Should be logged for debugging
  /// - May trigger reconnection logic depending on severity
  ///
  /// ### Example
  /// ```dart
  /// socket.onError((error) {
  ///   Z.error('Socket error: $error');
  /// });
  /// ```
  ///
  /// ### Distinction from [close]
  ///
  /// - [error]: The connection may still be usable
  /// - [close]: The connection is terminated
  /// {@endtemplate}
  error,

  /// {@template socket_type_send}
  /// Sends a message or payload to the server over the WebSocket.
  ///
  /// This is the primary data-out operation. The payload typically includes
  /// an event name and a data object.
  ///
  /// ### Behavior
  /// - Serializes the payload to JSON
  /// - Sends via the WebSocket's `send` method
  /// - May trigger [SocketType.ack] if the server acknowledges receipt
  /// - Throws if the connection is not in [SocketStatus.connected] state
  ///
  /// ### Example
  /// ```dart
  /// socket.emit('chat:message', {
  ///   'room': 'general',
  ///   'text': 'Hello everyone!',
  ///   'timestamp': DateTime.now().toIso8601String(),
  /// });
  /// ```
  ///
  /// ### Error handling
  ///
  /// If the socket is not connected, the message may be queued or an
  /// error may be thrown depending on the implementation.
  /// {@endtemplate}
  send,

  /// {@template socket_type_receive}
  /// Represents data received from the WebSocket server.
  ///
  /// This event is fired whenever the server sends a message. The payload
  /// contains the deserialized data.
  ///
  /// ### Behavior
  /// - Triggered by the WebSocket's `onMessage` callback
  /// - Payload is automatically deserialized from JSON
  /// - Dispatched to registered event listeners
  /// - Multiple listeners can be registered for the same event type
  ///
  /// ### Example
  /// ```dart
  /// socket.onMessage((data) {
  ///   final message = ChatMessage.fromJson(data);
  ///   _addMessageToUI(message);
  /// });
  /// ```
  ///
  /// ### Data format
  ///
  /// The server typically sends messages in a structured format:
  /// ```json
  /// {
  ///   "event": "chat:message",
  ///   "data": { "text": "Hello!", "sender": "user123" }
  /// }
  /// ```
  /// {@endtemplate}
  receive,

  /// {@template socket_type_ping}
  /// Sends a heartbeat ping to the server to keep the connection alive.
  ///
  /// Ping messages are sent at regular intervals (controlled by the
  /// `ping` parameter of [ZapSocket]) to detect dead connections. If the
  /// server does not respond with a [pong] within the expected timeframe,
  /// the connection is considered dead.
  ///
  /// ### Behavior
  /// - Sent automatically at the configured interval
  /// - Typically a small, fixed payload (e.g., `"ping"` or `{}`)
  /// - Server should respond with [SocketType.pong]
  /// - If no pong is received, the connection is closed
  ///
  /// ### Configuration
  ///
  /// ```dart
  /// final socket = ZapSocket(
  ///   'wss://example.com/ws',
  ///   ping: Duration(seconds: 10), // ping every 10 seconds
  /// );
  /// ```
  ///
  /// ### Why pings matter
  ///
  /// Without pings, a silent connection drop (e.g., network切换) may go
  /// undetected for a long time. Pings ensure the connection is actively
  /// monitored.
  /// {@endtemplate}
  ping,

  /// {@template socket_type_pong}
  /// Acknowledges receipt of a [ping] from the client.
  ///
  /// The server sends a pong in response to each ping. If the client does
  /// not receive a pong within the expected timeframe, it assumes the
  /// connection is dead and closes it.
  ///
  /// ### Behavior
  /// - Sent automatically by the server in response to [ping]
  /// - Received by the client's `onMessage` handler
  /// - Resets the ping timeout timer
  /// - If not received, triggers connection closure
  ///
  /// ### Example
  /// ```dart
  /// socket.onPong(() {
  ///   // Connection is alive — reset timeout
  ///   _resetHeartbeatTimer();
  /// });
  /// ```
  /// {@endtemplate}
  pong,

  /// {@template socket_type_open}
  /// Fired when the WebSocket connection is successfully established.
  ///
  /// This event indicates that the WebSocket handshake has completed and
  /// the connection is ready for data transfer. It corresponds to the
  /// `onOpen` callback.
  ///
  /// ### Behavior
  /// - Sets [SocketStatus.connected]
  /// - Connection is now ready for [send] operations
  /// - Initial authentication or subscription may be triggered
  /// - Queued messages can now be sent
  ///
  /// ### Example
  /// ```dart
  /// socket.onOpen(() {
  ///   Z.info('WebSocket connected');
  ///   _sendQueuedMessages();
  ///   _subscribeToChannels();
  /// });
  /// ```
  ///
  /// ### What to do on open
  ///
  /// 1. Send authentication credentials
  /// 2. Subscribe to relevant channels/topics
  /// 3. Send any queued messages
  /// 4. Update UI to show connected state
  /// {@endtemplate}
  open,

  /// {@template socket_type_close}
  /// Fired when the WebSocket connection is closed.
  ///
  /// This event indicates that the connection is no longer active. It may
  /// be triggered by the client (explicit close), the server (graceful
  /// shutdown), or a network error.
  ///
  /// ### Behavior
  /// - Sets [SocketStatus.closed]
  /// - No more messages can be sent or received
  /// - Event listeners may be cleared
  /// - Reconnection logic may be triggered
  ///
  /// ### Example
  /// ```dart
  /// socket.onClose((reason) {
  ///   Z.info('WebSocket closed: $reason');
  ///   _attemptReconnect();
  /// });
  /// ```
  ///
  /// ### Close codes
  ///
  /// The close event may include a status code:
  /// - `1000`: Normal closure
  /// - `1001`: Server going away
  /// - `1002`: Protocol error
  /// - `1003`: Unsupported data type
  /// - `1006`: Abnormal closure (no close frame received)
  /// - `1011`: Server error
  /// {@endtemplate}
  close,

  /// {@template socket_type_timeout}
  /// The connection or request exceeded the expected response time.
  ///
  /// This event is fired when a ping/pong exchange, message acknowledgment,
  /// or connection attempt takes too long. It typically triggers
  /// reconnection logic.
  ///
  /// ### Behavior
  /// - May trigger automatic reconnection
  /// - Should be logged for monitoring
  /// - May cause the connection to be closed
  ///
  /// ### Example
  /// ```dart
  /// socket.onTimeout(() {
  ///   Z.warn('Socket timeout — reconnecting');
  ///   socket.emit(SocketType.reconnect, {});
  /// });
  /// ```
  ///
  /// ### Common causes
  /// - Server is slow to respond
  /// - Network congestion
  /// - Server is overloaded
  /// - Firewall is silently dropping packets
  /// {@endtemplate}
  timeout,

  /// {@template socket_type_retry}
  /// Retries a previously failed message or connection attempt.
  ///
  /// This event supports resiliency mechanisms such as exponential backoff.
  /// It is typically triggered automatically by the socket framework after
  /// a failure.
  ///
  /// ### Behavior
  /// - Re-attempts the failed operation
  /// - May include retry count or delay information
  /// - Supports exponential backoff strategies
  /// - Limits maximum retry attempts
  ///
  /// ### Example
  /// ```dart
  /// socket.onRetry((attempt) {
  ///   Z.info('Retry attempt #$attempt');
  /// });
  /// ```
  ///
  /// ### Retry strategy
  ///
  /// Use exponential backoff to avoid overwhelming the server:
  /// ```
  /// attempt 1: 1 second delay
  /// attempt 2: 2 seconds delay
  /// attempt 3: 4 seconds delay
  /// attempt 4: 8 seconds delay
  /// ... (capped at 30 seconds)
  /// ```
  /// {@endtemplate}
  retry,

  /// {@template socket_type_subscribe}
  /// Subscribes to a channel, room, or topic for scoped messages.
  ///
  /// This is common in pub-sub systems like Socket.IO where clients
  /// subscribe to specific channels to receive only relevant messages.
  ///
  /// ### Behavior
  /// - Sends a subscription request to the server
  /// - Server adds the client to the specified channel
  /// - Subsequent messages on that channel are forwarded to this client
  /// - May require authentication
  ///
  /// ### Example
  /// ```dart
  /// socket.emit('subscribe', {'channel': 'chat:general'});
  /// socket.emit('subscribe', {'channel': 'notifications:user123'});
  /// ```
  ///
  /// ### Use cases
  /// - Chat rooms
  /// - Live notifications
  /// - Real-time data feeds (stock prices, sports scores)
  /// - Collaborative editing channels
  /// {@endtemplate}
  subscribe,

  /// {@template socket_type_unsubscribe}
  /// Unsubscribes from a channel, room, or topic.
  ///
  /// Stops receiving messages from the specified channel. This is the
  /// counterpart to [subscribe].
  ///
  /// ### Behavior
  /// - Sends an unsubscription request to the server
  /// - Server removes the client from the channel
  /// - Messages on that channel are no longer forwarded
  /// - Resources are freed on both client and server
  ///
  /// ### Example
  /// ```dart
  /// socket.emit('unsubscribe', {'channel': 'chat:general'});
  /// ```
  ///
  /// ### When to use
  /// - User leaves a chat room
  /// - Navigating away from a real-time screen
  /// - Cleaning up on dispose
  /// - Switching to a different subscription set
  /// {@endtemplate}
  unsubscribe,

  /// {@template socket_type_auth}
  /// Handles socket-level authentication via tokens.
  ///
  /// This event is used to verify and authorize a user on connection.
  /// The client sends authentication credentials (typically a JWT or
  /// session token) and the server validates them.
  ///
  /// ### Behavior
  /// - Sent after [SocketType.open] (or as part of the handshake)
  /// - Server validates the token and responds with success/failure
  /// - On failure, the connection may be closed
  /// - On success, the client is fully authenticated
  ///
  /// ### Example
  /// ```dart
  /// socket.onOpen(() {
  ///   socket.emit('auth', {
  ///     'token': 'eyJhbGciOiJIUzI1NiIs...',
  ///   });
  /// });
  /// ```
  ///
  /// ### Token refresh
  ///
  /// If the token expires during the session, the server may send an
  /// auth error, requiring the client to refresh the token and re-auth.
  /// {@endtemplate}
  auth,

  /// {@template socket_type_ack}
  /// Acknowledgment received for a previously sent message.
  ///
  /// This confirms that the server received and processed the message.
  /// It is the positive counterpart to [nack].
  ///
  /// ### Behavior
  /// - Server sends an ack after successfully processing a message
  /// - Includes the message ID or correlation ID
  /// - Used for reliable delivery guarantees
  /// - May trigger queued message processing
  ///
  /// ### Example
  /// ```dart
  /// socket.onAck((messageId) {
  ///   Z.info('Message $messageId acknowledged');
  ///   _removeFromPendingQueue(messageId);
  /// });
  /// ```
  ///
  /// ### Use cases
  /// - Confirming message delivery
  /// - Triggering next message in a queue
  /// - Updating UI to show "delivered" status
  /// {@endtemplate}
  ack,

  /// {@template socket_type_nack}
  /// Negative acknowledgment indicating an error or failure.
  ///
  /// The server could not process the message. This is the negative
  /// counterpart to [ack].
  ///
  /// ### Behavior
  /// - Server sends a nack when message processing fails
  /// - Includes the message ID and error details
  /// - The message may be retried or discarded
  /// - Should be logged for debugging
  ///
  /// ### Example
  /// ```dart
  /// socket.onNack((messageId, error) {
  ///   Z.error('Message $messageId rejected: $error');
  ///   _retryMessage(messageId);
  /// });
  /// ```
  ///
  /// ### Common causes
  /// - Invalid message format
  /// - Authentication expired
  /// - Rate limiting
  /// - Server-side validation failure
  /// {@endtemplate}
  nack,
}