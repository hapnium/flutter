import 'dart:async';

import '../definitions.dart';
import '../enums/socket_type.dart';
import '../enums/zync_state.dart';
import '../models/zync/zync_error_response.dart';
import '../models/zync/zync_response.dart';

/// {@template zync_interface}
/// A foundational contract defining the architecture for real-time WebSocket 
/// communication within the Zync ecosystem.
///
/// **Architectural Context:**
/// By programming against this abstract interface rather than a concrete WebSocket 
/// implementation, your application achieves inversion of control. This allows you to:
/// 1. Seamlessly swap out the underlying transport layer (e.g., swapping a mobile 
///    `dart:io` socket for a `dart:html` web socket) without changing your UI or Repositories.
/// 2. Easily mock the entire real-time layer for unit testing by creating a 
///    `MockZyncClient implements ZyncInterface`.
/// 3. Standardize the Pub/Sub and Event-Emitter patterns across the entire codebase.
/// {@endtemplate}
abstract class ZyncInterface {
  /// A rapid, synchronous gatekeeper to verify connection viability.
  /// 
  /// Returns `true` strictly when the socket is fully authenticated and open. 
  /// Useful for quick guard clauses before attempting to dispatch an event 
  /// (e.g., `if (!zync.isConnected) return;`).
  bool get isConnected;

  /// The current lifecycle phase of the socket connection.
  /// 
  /// Allows synchronous inspection of the internal state machine (e.g., 
  /// `connecting`, `connected`, `disconnected`, `retrying`).
  ZyncState get connectionState;

  /// The internal sink for broadcasting state transitions.
  /// 
  /// **Architectural Note:** 
  /// While this exposes the raw controller, it is primarily intended for use 
  /// by the concrete implementation class to push state changes. UI widgets and 
  /// external consumers should exclusively listen to [connectionStateStream].
  StreamController<ZyncState> get connectionStateController;

  /// The internal sink for broadcasting global protocol errors and exceptions.
  /// 
  /// Intended for the concrete implementation to push caught errors. Consumers 
  /// should listen to [errorStream].
  StreamController<ZyncErrorResponse> get errorController;

  /// The internal sink for broadcasting validated, incoming network frames.
  /// 
  /// Intended for the concrete implementation to push parsed messages. Consumers 
  /// should listen to [dataStream].
  StreamController<ZyncResponse> get dataController;

  /// The reactive stream of connection lifecycle changes.
  /// 
  /// **Use Case:**
  /// Perfect for driving global UI indicators (like a red "Offline" banner or 
  /// a spinning "Reconnecting..." indicator). Typically consumed via a `StreamBuilder` 
  /// or mapped into a Riverpod/Bloc state.
  Stream<ZyncState> get connectionStateStream;

  /// The primary reactive artery of the socket connection.
  /// 
  /// Emits every valid, parsed [ZyncResponse] received from the server. 
  /// Global message handlers should subscribe to this stream to intercept 
  /// incoming data before routing it to specific domain repositories.
  Stream<ZyncResponse> get dataStream;

  /// The global boundary for asynchronous socket failures.
  /// 
  /// Emits a [ZyncErrorResponse] whenever a network drop, payload decoding 
  /// failure, or protocol violation occurs. Highly useful for piping real-time 
  /// network errors directly into Crashlytics or Sentry.
  Stream<ZyncErrorResponse> get errorStream;

  /// Initializes the TCP/TLS handshake and upgrades the connection to a WebSocket.
  /// 
  /// **Lifecycle:**
  /// 1. Updates state to `connecting`.
  /// 2. Performs the network handshake (injecting JWT headers if configured).
  /// 3. Updates state to `connected` upon success, or `error`/`retrying` on failure.
  /// 
  /// Returns a `Future` that resolves only when the connection is fully established.
  Future<void> connect();

  /// Gracefully tears down the socket connection and flushes all internal resources.
  /// 
  /// **Cleanup:**
  /// - Transmits a close frame to the server.
  /// - Destroys internal Keep-Alive (Ping/Pong) timers.
  /// - Updates state to `disconnected`.
  /// - Clears all active Pub/Sub subscriptions.
  void disconnect();

  /// Transmits a directed payload to a specific backend routing endpoint.
  /// 
  /// **Architectural Difference:**
  /// Unlike [emit], which broadcasts a general event, [send] is typically used 
  /// for RPC (Remote Procedure Call) patterns where the payload is sent to a 
  /// specific microservice or message broker queue defined by the [endpoint].
  /// 
  /// - [endpoint]: The destination route (e.g., `/app/chat/message`).
  /// - [data]: The JSON-serializable payload (usually a Map).
  /// - [headers]: Optional, per-message metadata (like idempotency keys).
  void send({required String endpoint, required dynamic data, Headers? headers});

  /// Registers the client to a specific Pub/Sub multiplexing channel.
  /// 
  /// **Use Case:**
  /// Allows a single WebSocket connection to receive data for multiple distinct 
  /// features (e.g., joining `"chat_room_42"` and `"user_notifications_88"` simultaneously).
  /// 
  /// - [topic]: The strict string identifier of the channel.
  /// - [onMessage]: A dedicated callback triggered exclusively when a [ZyncResponse] 
  ///   matching this topic arrives.
  void subscribe({required String topic, required void Function(ZyncResponse) onMessage});

  /// Unregisters the client from a specific Pub/Sub channel.
  /// 
  /// Instructs the server to stop sending frames for this [topic] and removes 
  /// the localized [onMessage] callback from memory. Crucial to call when a 
  /// user leaves a specific screen to prevent memory leaks and wasted bandwidth.
  void unsubscribe(String topic);

  /// Registers a targeted listener for a protocol-level or domain-level event.
  /// 
  /// **Event-Driven Architecture:**
  /// Rather than parsing the entire [dataStream] manually, this allows specific 
  /// services to listen only for events they care about (e.g., listening for 
  /// [SocketType.ping] to update a latency metric).
  /// 
  /// - [event]: The specific enum state or command to listen for.
  /// - [callback]: The function executed when the event occurs.
  void on(SocketType event, void Function(dynamic data) callback);

  /// Destroys the listener previously registered via [on].
  /// 
  /// Must be called during widget/controller disposal to prevent memory leaks 
  /// and "calling setState on unmounted widget" errors.
  void off(SocketType event);

  /// Broadcasts an event and its associated payload to the server.
  /// 
  /// **Architectural Difference:**
  /// Unlike [send], which targets a hardcoded endpoint, [emit] relies on the 
  /// standard Event-Emitter pattern. The server must have an active `.on(event)` 
  /// listener to catch and process this payload.
  /// 
  /// - [event]: The command or action type (e.g., [SocketType.message]).
  /// - [data]: The JSON-serializable body attached to the event.
  void emit(SocketType event, dynamic data);
}