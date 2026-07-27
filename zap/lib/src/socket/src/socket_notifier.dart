import 'dart:convert';

import '../../enums/socket_type.dart';
import 'socket_close.dart';

/// {@template close_socket}
/// Signature for a callback that handles socket close events.
///
/// A function that accepts a [SocketClose] object containing information
/// about why the connection was closed.
///
/// ### Parameters
///
/// - [socket]: A [SocketClose] object with the close message and reason
///   code.
///
/// ### Example
///
/// ```dart
/// void onSocketClose(SocketClose close) {
///   print('Disconnected: ${close.message} (code: ${close.reason})');
/// }
/// ```
/// {@endtemplate}
typedef CloseSocket = void Function(SocketClose);

/// {@template message_socket}
/// Signature for a callback that handles socket messages.
///
/// A function that accepts the raw message data. The data type depends
/// on what was sent (String, Map, List, etc.).
///
/// ### Parameters
///
/// - [val]: The received message data.
///
/// ### Example
///
/// ```dart
/// void onSocketMessage(dynamic val) {
///   if (val is String) {
///     print('Text message: $val');
///   } else if (val is Map) {
///     print('JSON message: $val');
///   }
/// }
/// ```
/// {@endtemplate}
typedef MessageSocket = void Function(dynamic val);

/// {@template open_socket}
/// Signature for a callback that handles socket opening.
///
/// A function with no parameters that is called when the WebSocket
/// connection is successfully established.
///
/// ### Example
///
/// ```dart
/// void onSocketOpen() {
///   print('Connected!');
/// }
/// ```
/// {@endtemplate}
typedef OpenSocket = void Function();

/// {@template socket_notifier}
/// Event bus for WebSocket-based applications that manages listener
/// registration and message dispatch.
///
/// `SocketNotifier` allows registering multiple listeners for:
/// - **General messages**: Triggered on every incoming message
/// - **Named events**: Triggered when a message matches a specific
///   [SocketType]
/// - **Close events**: Triggered when the connection closes
/// - **Error events**: Triggered when an error occurs
///
/// ### Architecture
///
/// The notifier acts as an intermediary between the raw WebSocket and
/// the application layer. It decouples event handling from the
/// transport layer, allowing multiple listeners per event type.
///
/// ### Example
///
/// ```dart
/// final notifier = SocketNotifier();
///
/// // Register listeners
/// notifier.addMessages((data) => print('Message: $data'));
/// notifier.addEvents(SocketType.receive, (data) => print('Chat: $data'));
/// notifier.addCloses((close) => print('Closed: ${close.message}'));
///
/// // Dispatch events
/// notifier.notifyData('Hello!');
/// notifier.notifyClose(SocketClose('Normal', 1000));
/// ```
///
/// ### Cleanup
///
/// Call [dispose] to clear all listeners and prevent memory leaks:
/// ```dart
/// notifier.dispose(); // clears all listeners
/// ```
/// {@endtemplate}
class SocketNotifier {
  /// {@macro socket_notifier}
  SocketNotifier() {
    open = () {};
  }

  /// {@template socket_notifier_onMessages}
  /// List of listeners for general messages received over the socket.
  ///
  /// Every listener in this list is invoked when [notifyData] is called,
  /// regardless of the message format or event type.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier._onMessages = [
  ///   (data) => print('Listener 1: $data'),
  ///   (data) => print('Listener 2: $data'),
  /// ];
  /// ```
  /// {@endtemplate}
  List<MessageSocket>? _onMessages = <MessageSocket>[];

  /// {@template socket_notifier_onEvents}
  /// Map of event-specific message listeners, keyed by [SocketType].
  ///
  /// Each entry maps a socket event type to its handler. When a JSON
  /// message with a matching `"type"` field is received, the
  /// corresponding handler is invoked.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier._onEvents = {
  ///   SocketType.receive: (data) => handleChatMessage(data),
  ///   SocketType.send: (data) => handleSentMessage(data),
  /// };
  /// ```
  /// {@endtemplate}
  Map<SocketType, MessageSocket>? _onEvents = <SocketType, MessageSocket>{};

  /// {@template socket_notifier_onCloses}
  /// List of listeners for socket close events.
  ///
  /// Every listener in this list is invoked when [notifyClose] is called.
  /// {@endtemplate}
  List<void Function(SocketClose)>? _onCloses = <CloseSocket>[];

  /// {@template socket_notifier_onErrors}
  /// List of listeners for socket error events.
  ///
  /// Every listener in this list is invoked when [notifyError] is called.
  /// {@endtemplate}
  List<void Function(SocketClose)>? _onErrors = <CloseSocket>[];

  /// {@template socket_notifier_open}
  /// Callback to initiate the opening of the socket connection.
  ///
  /// This must be set externally (usually by the platform-specific
  /// `BaseWebSocket` implementation) to define how the socket is opened.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier.open = () {
  ///   socket = html.WebSocket(url);
  /// };
  /// ```
  /// {@endtemplate}
  late OpenSocket open;

  /// {@template socket_notifier_addCloses}
  /// Adds a listener for socket close events.
  ///
  /// The provided [socket] callback is triggered when the connection
  /// closes.
  ///
  /// ### Parameters
  ///
  /// - [socket]: The callback to invoke on close events.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier.addCloses((close) {
  ///   print('Connection closed: ${close.message}');
  /// });
  /// ```
  /// {@endtemplate}
  void addCloses(CloseSocket socket) {
    _onCloses!.add(socket);
  }

  /// {@template socket_notifier_addErrors}
  /// Adds a listener for socket error events.
  ///
  /// The provided [socket] callback is triggered when an error occurs.
  ///
  /// ### Parameters
  ///
  /// - [socket]: The callback to invoke on error events.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier.addErrors((close) {
  ///   Z.error('Socket error: ${close.message}');
  /// });
  /// ```
  /// {@endtemplate}
  void addErrors(CloseSocket socket) {
    _onErrors!.add((socket));
  }

  /// {@template socket_notifier_addEvents}
  /// Adds a named event listener.
  ///
  /// The [event] is a [SocketType] key to identify the type of message.
  /// The [socket] callback will be triggered if an incoming message
  /// contains the corresponding event type.
  ///
  /// ### Parameters
  ///
  /// - [event]: The [SocketType] to listen for.
  /// - [socket]: The callback to invoke when the event is received.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier.addEvents(SocketType.receive, (data) {
  ///   final message = ChatMessage.fromJson(data);
  ///   _addMessageToUI(message);
  /// });
  /// ```
  ///
  /// ### Overwriting
  ///
  /// Only one listener per event type is supported. Registering a new
  /// listener for the same event overwrites the previous one.
  /// {@endtemplate}
  void addEvents(SocketType event, MessageSocket socket) {
    _onEvents![event] = socket;
  }

  /// {@template socket_notifier_addMessages}
  /// Adds a general message listener.
  ///
  /// The [socket] callback is triggered on every incoming message,
  /// regardless of event type or format.
  ///
  /// ### Parameters
  ///
  /// - [socket]: The callback to invoke for every message.
  ///
  /// ### Example
  ///
  /// ```dart
  /// notifier.addMessages((data) {
  ///   print('Raw message: $data');
  /// });
  /// ```
  ///
  /// ### Multiple listeners
  ///
  /// Multiple general message listeners can be registered. All are
  /// invoked for each message.
  /// {@endtemplate}
  void addMessages(MessageSocket socket) {
    _onMessages!.add((socket));
  }

  /// {@template socket_notifier_dispose}
  /// Clears all listeners for messages, events, closes, and errors.
  ///
  /// After calling this method, no events will be dispatched. This is
  /// useful for cleanup during dispose or logout.
  ///
  /// ### Behavior
  ///
  /// Sets all internal listener collections to `null`. Any subsequent
  /// calls to `addMessages`, `addEvents`, etc. will throw a
  /// `NoSuchMethodError` (calling methods on null).
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Clean up when the socket is no longer needed
  /// notifier.dispose();
  /// ```
  /// {@endtemplate}
  void dispose() {
    _onMessages = null;
    _onEvents = null;
    _onCloses = null;
    _onErrors = null;
  }

  /// {@template socket_notifier_notifyClose}
  /// Notifies all registered close listeners with [err].
  ///
  /// Usually called by the platform-specific WebSocket implementation
  /// when the connection is closed (either gracefully or due to error).
  ///
  /// ### Parameters
  ///
  /// - [err]: A [SocketClose] object with the close reason and code.
  ///
  /// ### Behavior
  ///
  /// Iterates through all listeners in [_onCloses] and invokes each
  /// with [err].
  /// {@endtemplate}
  void notifyClose(SocketClose err) {
    for (var item in _onCloses!) {
      item(err);
    }
  }

  /// {@template socket_notifier_notifyData}
  /// Notifies all registered message listeners with [data].
  ///
  /// If the message is a String, it is also parsed to check for named
  /// event dispatching via [_tryOn].
  ///
  /// ### Parameters
  ///
  /// - [data]: The received message data.
  ///
  /// ### Behavior
  ///
  /// 1. Invokes all listeners in [_onMessages] with [data]
  /// 2. If [data] is a String, attempts to parse it as JSON and
  ///   dispatch to named event listeners
  /// {@endtemplate}
  void notifyData(dynamic data) {
    for (var item in _onMessages!) {
      item(data);
    }
    if (data is String) {
      _tryOn(data);
    }
  }

  /// {@template socket_notifier_notifyError}
  /// Notifies all registered error listeners with [err].
  ///
  /// Should be called when a socket-related error occurs.
  ///
  /// ### Parameters
  ///
  /// - [err]: A [SocketClose] object with the error details.
  ///
  /// ### Behavior
  ///
  /// Iterates through all listeners in [_onErrors] and invokes each
  /// with [err].
  /// {@endtemplate}
  void notifyError(SocketClose err) {
    for (var item in _onErrors!) {
      item(err);
    }
  }

  /// Attempts to decode a JSON [message] and dispatch to a named event.
  ///
  /// The message should be a JSON string with at least `"type"` and
  /// `"data"` fields. If the `"type"` matches a registered event
  /// listener, that listener is invoked.
  ///
  /// ### Parameters
  ///
  /// - [message]: The JSON string to parse.
  ///
  /// ### Behavior
  ///
  /// 1. Attempts to decode the message as JSON
  /// 2. Extracts the `"type"` field
  /// 3. Looks up the corresponding event listener
  /// 4. Invokes the listener with the `"data"` field
  ///
  /// ### Error handling
  ///
  /// Malformed JSON or missing fields are silently ignored. This is
  /// intentional -- not every message is a JSON event.
  void _tryOn(String message) {
    try {
      var msg = jsonDecode(message);
      final event = msg['type'];
      final data = msg['data'];
      if (_onEvents!.containsKey(event)) {
        _onEvents![event]!(data);
      }
    } catch (_) {
      // Ignore malformed JSON or missing fields
      return;
    }
  }
}