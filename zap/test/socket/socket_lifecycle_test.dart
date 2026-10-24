import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late HttpServer server;
  late String wsUrl;
  late List<WebSocket> upgraded;
  late Completer<void> serverSideClosed;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    wsUrl = 'ws://${server.address.address}:${server.port}';
    upgraded = [];
    serverSideClosed = Completer<void>();
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      upgraded.add(ws);
      // Drain the server side so close handshakes and frames are
      // processed, and observe the connection going away (either a
      // clean close or a dropped socket).
      ws.listen(
        (_) {},
        onDone: () {
          if (!serverSideClosed.isCompleted) serverSideClosed.complete();
        },
        onError: (_) {
          if (!serverSideClosed.isCompleted) serverSideClosed.complete();
        },
      );
    });
  });

  tearDown(() async {
    for (final ws in upgraded) {
      try {
        await ws.close();
      } catch (_) {
        // Connection may already be closed by the test.
      }
    }
    await server.close(force: true);
  });

  Future<void> waitForOpen(ZapSocket socket) async {
    final opened = Completer<void>();
    socket.onOpen(() {
      if (!opened.isCompleted) opened.complete();
    });
    socket.connect();
    await opened.future.timeout(const Duration(seconds: 5));
  }

  test('ZapSocket validates TLS certificates by default', () {
    final socket = ZapSocket('wss://example.com/ws');

    expect(socket.allowSelfSigned, isFalse);
  });

  test('ZapSocket allows opting into self-signed certificates', () {
    final socket = ZapSocket('wss://example.com/ws', allowSelfSigned: true);

    expect(socket.allowSelfSigned, isTrue);
  });

  test('dispose closes the underlying connection', () async {
    final socket = ZapSocket(wsUrl);
    await waitForOpen(socket);
    expect(upgraded, hasLength(1));

    socket.dispose();

    // The server must observe the connection going away — either as a
    // clean close or as a dropped socket. Before the dispose fix the
    // connection was leaked and neither ever fired.
    await serverSideClosed.future.timeout(const Duration(seconds: 10));
  });

  test('frames arriving after dispose do not crash', () async {
    final socket = ZapSocket(wsUrl);
    await waitForOpen(socket);

    socket.dispose();

    // Push a frame into the connection the client just tore down. Before
    // the dispose fix this hit a null-checked notifier and crashed with an
    // unhandled async TypeError.
    upgraded.first.add('late-frame');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  test('dispose before any connection is a safe no-op', () {
    final socket = ZapSocket(wsUrl);

    expect(socket.dispose, returnsNormally);
  });

  test('close fires close listeners', () async {
    final socket = ZapSocket(wsUrl);
    final closed = Completer();
    socket.onClose((close) {
      if (!closed.isCompleted) closed.complete(close);
    });
    await waitForOpen(socket);

    socket.close(1000, 'bye');

    await closed.future.timeout(const Duration(seconds: 5));
  });
}
