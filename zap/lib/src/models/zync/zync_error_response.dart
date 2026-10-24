/// {@template zync_error_response}
/// A standardized error wrapper for WebSocket connections within the Zync ecosystem.
///
/// This class encapsulates any exceptions, connection drops, or transmission 
/// failures that occur during WebSocket communication. By wrapping raw Dart 
/// `Exception` or `Error` objects in this class, the system guarantees a uniform 
/// structure for logging, analytics, and UI-level error handling.
///
/// **Use Cases:**
/// * Tracing where an error originated in the socket lifecycle (e.g., connection 
///   handshake, payload decoding, ping/pong timeouts).
/// * Structured logging (via [toJson]) to external monitoring services.
/// * Graceful error bubbling to the UI layer without exposing raw socket exceptions.
/// {@endtemplate}
class ZyncErrorResponse {
  /// The specific subsystem, method, or lifecycle event where the error originated.
  ///
  /// Providing a precise context makes debugging significantly easier. 
  /// 
  /// **Examples:** 
  /// * `"ZyncConnection.connect"`
  /// * `"MessageDispatcher.send"`
  /// * `"HeartbeatMonitor.ping"`
  final String where;
  
  /// The raw error payload caught by the system.
  ///
  /// Typed as `dynamic` to accommodate the wide variety of errors that can occur 
  /// during network communication, including:
  /// * Dart's native `SocketException` or `WebSocketException`.
  /// * Standard `String` error messages.
  /// * Parsed JSON maps representing backend validation errors.
  final dynamic error;

  /// The pub/sub topic this error concerns, when it originates from a
  /// topic-scoped frame (e.g. a server error tagged `topic: 'orders'`).
  ///
  /// Lets apps filter `Zync.errorStream` per channel instead of treating
  /// every error as global. `null` for connection-level errors.
  final String? topic;
  
  /// The exact local time when the error was caught and instantiated.
  ///
  /// This is automatically populated upon creation. It is critical for accurately 
  /// reconstructing the timeline of events when debugging race conditions or 
  /// intermittent network drops.
  final DateTime timestamp;

  /// {@macro zync_error_response}
  ///
  /// Instantiates a new error wrapper. 
  ///
  /// The [timestamp] is automatically captured at the exact moment this 
  /// constructor is called, ensuring precise chronological tracking.
  ZyncErrorResponse({
    required this.where,
    required this.error,
    this.topic,
  }) : timestamp = DateTime.now();

  /// Serializes the error response into a JSON-compatible map.
  ///
  /// This is primarily used for structured logging, telemetry, or forwarding 
  /// the error state to an external monitoring service. 
  ///
  /// **Serialization Details:**
  /// * The dynamic [error] is safely converted using `.toString()` to prevent 
  ///   `JsonUnsupportedObjectError` when passed to `jsonEncode()`.
  /// * The [timestamp] is converted to a standardized ISO 8601 string.
  Map<String, dynamic> toJson() => {
    'where': where,
    'error': error.toString(),
    if (topic != null) 'topic': topic,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Returns a concise, human-readable string representation of the error.
  ///
  /// Ideal for standard console debugging or simple terminal logs.
  /// 
  /// Format: `ZyncError[<where>]: <error.toString()>`
  @override
  String toString() => 'ZyncError[$where${topic != null ? ':$topic' : ''}]: $error';
}