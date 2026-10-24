import '../../enums/socket_type.dart';
import 'socket_notifier.dart';
import 'socket_interface.dart';

/// {@template stub_socket}
/// Stub WebSocket implementation used as a fallback when neither `dart:io`
/// nor `dart:js_interop` is available.
///
/// All methods in this class are either no-ops or throw
/// `UnimplementedError`. This class exists to satisfy the conditional
/// import chain and provide a compile-time valid implementation for
/// unsupported platforms.
///
/// ### Platform support
///
/// This class is used on platforms where WebSocket connections are not
/// supported, such as:
/// - Flutter test environment (without platform mocks)
/// - Server-side Dart on unsupported platforms
/// - Custom build environments
///
/// ### Behavior
///
/// - [connect]: Throws `UnimplementedError`
/// - All other methods: No-op (do nothing)
///
/// ### Example
///
/// This class is never instantiated directly. It is selected via
/// conditional imports:
///
/// ```dart
/// import 'stub_socket.dart'
///     if (dart.library.js_interop) 'html_socket.dart'
///     if (dart.library.io) 'io_socket.dart';
/// ```
/// {@endtemplate}
class BaseWebSocket extends SocketInterface {
  /// {@template stub_socket_constructor}
  /// Creates a new stub [BaseWebSocket] instance.
  ///
  /// All parameters are accepted but ignored. The stub does not
  /// establish any connections.
  ///
  /// ### Parameters
  ///
  /// - [url]: The WebSocket URL (ignored).
  /// - [ping]: The ping interval (ignored).
  /// - [allowSelfSigned]: Whether to allow self-signed certs (ignored).
  /// {@endtemplate}
  /// {@macro stub_socket}
  BaseWebSocket(super.url, {super.ping, super.allowSelfSigned, super.connectTimeout});

  /// {@template stub_socket_close}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void close([int? status, String? reason]) { }

  /// {@template stub_socket_connect}
  /// Always throws `UnimplementedError`.
  ///
  /// ### Throws
  ///
  /// - `UnimplementedError`: Always thrown.
  /// {@endtemplate}
  @override
  Future connect() {
    throw UnimplementedError();
  }

  /// {@template stub_socket_dispose}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void dispose() { }

  /// {@template stub_socket_emit}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void emit(SocketType command, dynamic data) { }

  /// {@template stub_socket_on}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void on(SocketType command, MessageSocket message) { }

  /// {@template stub_socket_onClose}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void onClose(CloseSocket fn) { }

  /// {@template stub_socket_onError}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void onError(CloseSocket fn) { }

  /// {@template stub_socket_onMessage}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void onMessage(MessageSocket fn) { }

  /// {@template stub_socket_onOpen}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void onOpen(OpenSocket fn) { }

  /// {@template stub_socket_send}
  /// No-op implementation. Does nothing.
  /// {@endtemplate}
  @override
  void send(Object data) { }
}