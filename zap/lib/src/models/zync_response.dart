import '../definitions.dart';
import '../enums/socket_type.dart';

/// {@template zync_response}
/// A standardized Data Transfer Object (DTO) representing an incoming message 
/// or lifecycle event from a Zync WebSocket connection.
///
/// **Architectural Context:**
/// When the raw WebSocket receives a text or binary frame from the server, 
/// the Zync engine intercepts it, attempts to parse any JSON payloads, and 
/// wraps the result in this [ZyncResponse] envelope. 
///
/// This provides a uniform, predictable interface for the rest of your application. 
/// Instead of UI widgets or repositories dealing with raw strings and manual 
/// `jsonDecode` blocks, they simply listen to a stream of [ZyncResponse] objects.
///
/// **Usage Example:**
/// ```dart
/// zyncClient.onReceived = (ZyncResponse response) {
///   if (response.type == SocketType.message && response.hasData) {
///     final chatMessage = ChatMessage.fromJson(response.data);
///     uiState.addMessage(chatMessage);
///   }
/// };
/// ```
/// {@endtemplate}
class ZyncResponse {
  /// The protocol-level event type or command associated with this frame.
  /// 
  /// Usually represents core socket actions like [SocketType.connect], 
  /// [SocketType.message], or [SocketType.ping]. This allows the client to 
  /// easily filter out background keep-alive pings and focus solely on 
  /// actionable data messages.
  final SocketType? type;
  
  /// Metadata or protocol headers injected by the server for this specific frame.
  /// 
  /// While WebSockets don't have per-message HTTP headers natively, advanced 
  /// messaging protocols (like STOMP or proprietary Zync server implementations) 
  /// often multiplex headers into the payload structure.
  final Headers? headers;
  
  /// The exact, unparsed string payload received from the network.
  /// 
  /// **Use Case:**
  /// Kept intact in case the payload is not valid JSON, or if you need to 
  /// perform custom parsing (e.g., XML, CSV, or custom binary-to-string 
  /// encoding) that the default JSON decoder cannot handle.
  final String? body;
  
  /// The deeply parsed JSON payload.
  /// 
  /// Typically a `Map<String, dynamic>` or `List<dynamic>`. This is kept as 
  /// `dynamic` so the socket layer remains completely ignorant of your app's 
  /// specific domain models, shifting the responsibility of strong-typing to 
  /// the feature repositories.
  final dynamic data;
  
  /// A rapid, synchronous convenience flag indicating if [body] contains raw text.
  /// 
  /// Prevents the need for verbose null or empty-string checks like 
  /// `if (response.body != null && response.body!.isNotEmpty)`.
  final bool hasBody;
  
  /// A rapid, synchronous convenience flag indicating if [data] was successfully parsed.
  /// 
  /// Prevents the need for null checks on the dynamic data field before attempting 
  /// to cast it into a domain model.
  final bool hasData;
  
  /// The exact local device time when this frame was received by the client.
  /// 
  /// **Why this matters:**
  /// Due to network latency, the time the server sent the message and the time 
  /// the client received it can differ wildly. This timestamp is crucial for 
  /// correctly ordering incoming chat messages or calculating real-time latency.
  final DateTime timestamp;

  /// {@macro zync_response}
  /// 
  /// Instantiates a new response envelope. The [timestamp] is automatically 
  /// generated at the exact moment this constructor is invoked to ensure 
  /// accurate latency tracking.
  ZyncResponse({
    this.type,
    this.headers,
    this.body,
    this.data,
    this.hasBody = false,
    this.hasData = false,
  }) : timestamp = DateTime.now();

  /// Serializes the response envelope into a JSON map.
  ///
  /// **Architectural Use Case:**
  /// Highly useful for telemetry, structured console logging, or saving a 
  /// history of incoming socket frames to a local SQLite database for offline 
  /// debugging and sync recovery.
  Map<String, dynamic> toJson() => {
    'type': type,
    'headers': headers,
    'body': body,
    'data': data,
    'hasBody': hasBody,
    'hasData': hasData,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Outputs a concise, developer-friendly string representation of the frame.
  /// 
  /// Ideal for terminal output. Format: `ZyncResponse[<type>]: <data>`
  @override
  String toString() => 'ZyncResponse[${type ?? 'unknown'}]: $data';
}