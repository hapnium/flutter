import 'dart:convert';

import '../definitions.dart';
import '../enums/socket_type.dart';

/// {@template socket_messenger}
/// A universal envelope Data Transfer Object (DTO) for standardizing all 
/// WebSocket communication.
///
/// **Architectural Context:**
/// Raw WebSockets simply pass text or binary frames back and forth with no 
/// inherent structure. To build robust features like Pub/Sub channels, 
/// RPC (Remote Procedure Calls) over sockets, or multiplexing, you need a 
/// standardized protocol. [SocketMessenger] acts as that protocol layer.
///
/// By wrapping every incoming and outgoing payload in this envelope, the system 
/// can predictably route messages based on [topic] or [event], handle 
/// protocol-level lifecycles via [type], and correlate request/response pairs 
/// using [messageId].
///
/// **JSON Structure:**
/// ```json
/// {
///   "type": "send",
///   "event": "chat:new_message",
///   "topic": "room_123",
///   "messageId": "req_88291",
///   "data": { "text": "Hello World" }
/// }
/// ```
/// {@endtemplate}
class SocketMessenger {
  /// The protocol-level command or lifecycle state of this message.
  /// 
  /// Usually represents core socket actions like `connect`, `disconnect`, 
  /// `ping`, `pong`, or `send`. This tells the underlying socket manager 
  /// *how* to process the frame before looking at the payload.
  final SocketType type;

  /// An application-level routing key.
  /// 
  /// Used by feature-specific controllers to listen for specific domain events. 
  /// For example, `"user:typing"`, `"post:liked"`, or `"notification:received"`.
  final String? event;

  /// The raw, unparsed payload of the message.
  ///
  /// This is kept as `dynamic` (typically a `Map<String, dynamic>`) so the 
  /// socket layer remains entirely agnostic to your domain models. The specific 
  /// feature listening to the [event] is responsible for strongly typing this data.
  final dynamic data;

  /// A unique identifier used for RPC (Remote Procedure Call) multiplexing.
  ///
  /// **Why this matters:** WebSockets are asynchronous and unordered. If the 
  /// client sends a request and expects a response, the [messageId] is attached. 
  /// When the server responds, it echoes this ID back, allowing the client to 
  /// resolve the exact `Future` that initiated the request.
  final String? messageId;

  /// The exact local or server time when this message was constructed.
  /// 
  /// Highly useful for sorting incoming messages, discarding stale payloads, 
  /// or calculating network latency between the client and server.
  final DateTime? timestamp;

  /// A specific backend microservice or gateway route.
  /// 
  /// If your WebSocket server acts as an API gateway, this field tells the 
  /// gateway which internal service should receive the payload.
  final String? endpoint;

  /// Per-message metadata or authorization tokens.
  /// 
  /// While initial connection headers authenticate the socket, per-message 
  /// [headers] are useful for attaching idempotency keys, trace IDs, or 
  /// localized authorization tokens for specific actions.
  final Headers? headers;

  /// The Pub/Sub channel this message belongs to.
  /// 
  /// If the user is subscribed to multiple rooms or feeds over a single 
  /// socket connection, this identifies the target channel (e.g., `"room_42"`).
  final String? topic;

  /// {@macro socket_messenger}
  /// 
  /// Instantiates a fully-populated socket envelope. Only [type] is strictly 
  /// required; all other routing and payload fields are optional depending 
  /// on the specific socket operation.
  SocketMessenger({
    required this.type,
    this.event,
    this.data,
    this.messageId,
    this.timestamp,
    this.endpoint,
    this.headers,
    this.topic,
  });

  /// Deserializes a raw JSON map into a strictly typed [SocketMessenger].
  /// 
  /// **Defensive Parsing Strategy:**
  /// - The `type` field is safely converted back from a String to the [SocketType] 
  ///   enum using Dart's `.asNameMap()`. If the backend sends an unknown enum 
  ///   value, it safely falls back to the first value (or you can specify a default).
  /// - Dates are parsed using `tryParse` to prevent crashes on malformed timestamps.
  /// 
  /// {@macro socket_messenger}
  factory SocketMessenger.fromJson(Map<String, dynamic> json) {
    return SocketMessenger(
      // Safely map the string back to the enum, preventing hard crashes on unknown types
      type: SocketType.values.asNameMap()[json['type']] ?? SocketType.values.first,
      event: json['event'],
      data: json['data'],
      messageId: json['messageId'],
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
      endpoint: json['endpoint'],
      // Safely cast the dynamic map to your Headers definition
      headers: json['headers'] as Headers?,
      topic: json['topic'],
    );
  }

  /// Serializes the envelope back into a normalized JSON map.
  ///
  /// Uses collection `if` statements to strip out null values. This optimization 
  /// drastically reduces the byte payload size of the frame sent over the network, 
  /// which is critical for real-time WebSocket performance on mobile networks.
  /// 
  /// {@macro socket_messenger}
  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (event != null) 'event': event,
    if (data != null) 'data': data,
    if (messageId != null) 'messageId': messageId,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    if (endpoint != null) 'endpoint': endpoint,
    if (headers != null) 'headers': headers,
    if (topic != null) 'topic': topic,
  };

  /// A convenience method that instantly serializes the object to a JSON string, 
  /// ready to be transmitted over the WebSocket channel.
  /// 
  /// {@macro socket_messenger}
  String encode() => jsonEncode(toJson());

  /// A convenience static method that takes an incoming raw string frame from 
  /// the WebSocket channel and converts it directly into a [SocketMessenger].
  /// 
  /// {@macro socket_messenger} 
  static SocketMessenger decode(String jsonStr) => SocketMessenger.fromJson(jsonDecode(jsonStr));

  /// A lightweight factory for generating minimalist messages.
  /// 
  /// Ideal for simple operations that do not require complex Pub/Sub routing, 
  /// correlation IDs, or headers (e.g., sending a raw ping or simple command).
  /// 
  /// {@macro socket_messenger}
  factory SocketMessenger.simple({required SocketType command, required dynamic data}) {
    return SocketMessenger(
      type: command,
      data: data,
    );
  }

  /// Outputs a developer-friendly representation of the envelope, omitting 
  /// the `topic` in the output for brevity but capturing core routing data.
  @override
  String toString() => 
      'SocketMessenger(type: $type, event: $event, data: $data, messageId: $messageId, timestamp: $timestamp, endpoint: $endpoint, headers: $headers)';
}