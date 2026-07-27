import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../core/zap_inst.dart';
import '../../definitions.dart';
import '../../enums/socket_type.dart';
import '../../models/socket_messenger.dart';
import 'socket_close.dart';
import 'socket_interface.dart';
import 'socket_notifier.dart';
import '../../enums/socket_status.dart';

/// {@template io_socket}
/// Native (`dart:io`) WebSocket implementation for mobile, desktop, and
/// server platforms.
///
/// `BaseWebSocket` manages a WebSocket connection using `dart:io`'s
/// `WebSocket` class. It provides lifecycle management, event
/// subscription, and typed message dispatching.
///
/// ### Platform support
///
/// - Android
/// - iOS
/// - macOS
/// - Linux
/// - Windows
/// - Dart server (VM)
///
/// ### Example
///
/// ```dart
/// final ws = BaseWebSocket('wss://example.com/socket');
/// ws.connect();
/// ws.onOpen(() => print('Connected!'));
/// ws.onMessage((msg) => print('Received: $msg'));
/// ws.emit('chat', {'text': 'Hello'});
/// ```
///
/// ### Self-signed certificates
///
/// When [allowSelfSigned] is `true` (the default), the client creates
/// a custom `HttpClient` that accepts all certificates. This is useful
/// for development but should be disabled in production.
///
/// ### Ping mechanism
///
/// Uses `WebSocket.pingInterval` for native ping/pong support. The
/// server responds to pings automatically at the protocol level.
/// {@endtemplate}
class BaseWebSocket extends SocketInterface {
  /// {@template io_socket_socket}
  /// Underlying WebSocket instance from the `dart:io` package.
  ///
  /// This is `null` before [connect] is called and after [dispose].
  /// {@endtemplate}
  WebSocket? socket;

  /// {@template io_socket_socketNotifier}
  /// Socket event notifier for managing subscribers and dispatch.
  ///
  /// Handles all event registration and message dispatching. Set to
  /// `null` after [dispose].
  /// {@endtemplate}
  SocketNotifier? socketNotifier = SocketNotifier();

  /// {@template io_socket_isDisposed}
  /// Whether this socket has been disposed.
  ///
  /// After disposal, the socket cannot be reused.
  /// {@endtemplate}
  bool isDisposed = false;

  /// {@template io_socket_connectionStatus}
  /// The current connection status.
  ///
  /// Tracks the WebSocket lifecycle through [SocketStatus] values.
  /// {@endtemplate}
  SocketStatus? connectionStatus;

  /// {@template io_socket_constructor}
  /// Creates a new [BaseWebSocket] instance.
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL.
  /// - [ping]: Ping interval. Defaults to 5 seconds.
  /// - [allowSelfSigned]: Whether to allow self-signed certificates.
  ///   Defaults to `true`.
  /// {@endtemplate}
  /// {@macro io_socket}
  BaseWebSocket(
    super.url, {
    super.ping = const Duration(seconds: 5),
    super.allowSelfSigned = true,
  });

  /// {@template io_socket_close}
  /// Closes the WebSocket connection.
  ///
  /// ### Parameters
  ///
  /// - [status]: Optional close status code.
  /// - [reason]: Optional close reason string.
  /// {@endtemplate}
  @override
  void close([int? status, String? reason]) {
    socket?.close(status, reason);
  }

  /// {@template io_socket_connect}
  /// Connects to the WebSocket server.
  ///
  /// If [isDisposed] is `true`, creates a new [SocketNotifier]. Then
  /// establishes the WebSocket connection, sets up event listeners, and
  /// starts ping/pong.
  ///
  /// ### Behavior
  ///
  /// 1. Sets status to [SocketStatus.connecting]
  /// 2. If [allowSelfSigned], uses [_connectForSelfSignedCert]
  /// 3. Otherwise, uses `WebSocket.connect`
  /// 4. Sets `pingInterval` on the socket
  /// 5. Triggers [onOpen] callback
  /// 6. Sets status to [SocketStatus.connected]
  /// 7. Listens for data, errors, and done events
  ///
  /// ### Error handling
  ///
  /// - `SocketException`: Notifies error listeners with OS error details
  /// - Other exceptions: Re-thrown to caller
  /// {@endtemplate}
  // ignore: use_setters_to_change_properties
  @override
  Future<void> connect() async {
    if (isDisposed) {
      socketNotifier = SocketNotifier();
    }

    try {
      connectionStatus = SocketStatus.connecting;
      socket = allowSelfSigned ? await _connectForSelfSignedCert(url) : await WebSocket.connect(url);

      socket!.pingInterval = ping;
      socketNotifier?.open();
      connectionStatus = SocketStatus.connected;

      socket!.listen((data) {
        socketNotifier!.notifyData(data);
      }, onError: (err) {
        socketNotifier!.notifyError(SocketClose(err.toString(), 1005));
      }, onDone: () {
        connectionStatus = SocketStatus.closed;
        socketNotifier!.notifyClose(SocketClose('Connection Closed', socket!.closeCode));
      }, cancelOnError: true);

      return;
    } on SocketException catch (e) {
      connectionStatus = SocketStatus.closed;
      socketNotifier!.notifyError(SocketClose(e.osError!.message, e.osError!.errorCode));
      
      return;
    }
  }

  /// {@template io_socket_dispose}
  /// Disposes of the socket, removing all listeners and closing the
  /// connection.
  /// {@endtemplate}
  @override
  void dispose() {
    socketNotifier!.dispose();
    socketNotifier = null;
    isDisposed = true;
  }

  /// {@template io_socket_emit}
  /// Emits a named event to the server with optional payload data.
  ///
  /// ### Parameters
  ///
  /// - [command]: The [SocketType] event to emit.
  /// - [data]: The payload data.
  /// {@endtemplate}
  @override
  void emit(SocketType command, dynamic data) {
    send(SocketMessenger.simple(command: command, data: data).encode());
  }

  /// {@template io_socket_on}
  /// Registers a named event listener.
  ///
  /// ### Parameters
  ///
  /// - [command]: The [SocketType] to listen for.
  /// - [message]: The callback to invoke when the event is received.
  /// {@endtemplate}
  @override
  void on(SocketType command, MessageSocket message) {
    socketNotifier!.addEvents(command, message);
  }

  /// {@template io_socket_onClose}
  /// Registers a callback for when the socket is closed.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with [SocketClose] details.
  /// {@endtemplate}
  @override
  void onClose(CloseSocket fn) {
    socketNotifier!.addCloses(fn);
  }

  /// {@template io_socket_onError}
  /// Registers a callback for socket error events.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with [SocketClose] error details.
  /// {@endtemplate}
  @override
  void onError(CloseSocket fn) {
    socketNotifier!.addErrors(fn);
  }

  /// {@template io_socket_onMessage}
  /// Registers a callback for incoming messages.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke with each message.
  /// {@endtemplate}
  @override
  void onMessage(MessageSocket fn) {
    socketNotifier!.addMessages(fn);
  }

  /// {@template io_socket_onOpen}
  /// Registers a callback for when the socket connection is opened.
  ///
  /// ### Parameters
  ///
  /// - [fn]: The callback to invoke when connected.
  /// {@endtemplate}
  // ignore: use_setters_to_change_properties
  @override
  void onOpen(OpenSocket fn) {
    socketNotifier!.open = fn;
  }

  /// {@template io_socket_send}
  /// Sends data over the WebSocket connection.
  ///
  /// If the connection is closed, attempts to reconnect. If the socket
  /// exists, adds the data to the socket's stream.
  ///
  /// ### Parameters
  ///
  /// - [data]: The data to send.
  ///
  /// ### Behavior
  ///
  /// 1. If [connectionStatus] is [SocketStatus.closed], calls [connect]
  /// 2. If socket is not null, adds data to the stream
  /// {@endtemplate}
  @override
  void send(dynamic data) async {
    if (connectionStatus == SocketStatus.closed) {
      await connect();
    }

    if (socket != null) {
      socket!.add(data);
    }
  }

  /// Connects to the WebSocket server using a custom `HttpClient` that
  /// accepts self-signed certificates.
  ///
  /// This method creates an `HttpClient` with `badCertificateCallback`
  /// set to always return `true`, then performs the WebSocket upgrade
  /// handshake manually.
  ///
  /// ### Security note
  ///
  /// This method bypasses certificate validation. Only use in
  /// development environments.
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket server URL.
  ///
  /// ### Returns
  ///
  /// A `Future<WebSocket>` connected to the server.
  ///
  /// ### Throws
  ///
  /// - Any exception from the HTTP upgrade process.
  Future<WebSocket> _connectForSelfSignedCert(String url) async {
    try {
      var r = Random();
      var key = base64.encode(BodyBytes.generate(8, (_) => r.nextInt(255)));
      var client = HttpClient(context: SecurityContext());
      client.badCertificateCallback = (cert, host, port) {
        Z.log('BaseWebSocket: Allow self-signed certificate => $host:$port. ');
        return true;
      };

      var request = await client.getUrl(Uri.parse(url))
        ..headers.add('Connection', 'Upgrade')
        ..headers.add('Upgrade', 'websocket')
        ..headers.add('Cache-Control', 'no-cache')
        ..headers.add('Sec-WebSocket-Version', '13')
        ..headers.add('Sec-WebSocket-Key', key.toLowerCase());

      var response = await request.close();
      // ignore: close_sinks
      var socket = await response.detachSocket();
      var webSocket = WebSocket.fromUpgradedSocket(
        socket,
        serverSide: false,
      );

      return webSocket;
    } on Exception catch (_) {
      rethrow;
    }
  }
}