import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

/// Waits until [condition] holds, polling every 50ms for up to [timeout].
Future<void> waitUntil(bool Function() condition, String description, {Duration timeout = const Duration(seconds: 10)}) async {
  final iterations = timeout.inMilliseconds ~/ 50;
  for (var i = 0; i < iterations && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for: $description');
}

void main() {
  late HttpServer server;
  late String wsUrl;
  late int connections;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    wsUrl = 'ws://${server.address.address}:${server.port}';
    connections = 0;
  });

  tearDown(() async {
    Zync.dispose();
    await server.close(force: true);
  });

  test('a server that answers ping with pong keeps its connection', () async {
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      ws.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] == 'ping') {
          ws.add(jsonEncode({'type': 'pong', 'timestamp': DateTime.now().toIso8601String()}));
        }
      });
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        pingInterval: const Duration(milliseconds: 100),
        heartbeatTimeout: const Duration(milliseconds: 400),
        reconnectDelay: const Duration(milliseconds: 50),
        maxReconnectAttempts: 3,
      ),
    );

    await zync.connect();
    // Run through several heartbeat cycles with the pong flowing.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(connections, 1, reason: 'a ponging server must never be treated as dead');
    expect(zync.connectionState, ZyncState.connected);
  });

  test('a silent server is force-closed and reconnected by the heartbeat', () async {
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      // Drain but never answer: the heartbeat must detect the silence.
      ws.listen((_) {});
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        pingInterval: const Duration(milliseconds: 100),
        heartbeatTimeout: const Duration(milliseconds: 400),
        reconnectDelay: const Duration(milliseconds: 50),
        maxReconnectAttempts: 5,
      ),
    );

    await zync.connect();

    await waitUntil(
      () => connections >= 2,
      'heartbeat force-closes a silent connection and reconnects',
    );
  });

  test('heartbeatTimeout defaults to disabled (no forced reconnects)', () async {
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      ws.listen((_) {}); // Silent, but no heartbeat configured.
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        pingInterval: const Duration(milliseconds: 100),
        reconnectDelay: const Duration(milliseconds: 50),
      ),
    );

    await zync.connect();
    await Future<void>.delayed(const Duration(milliseconds: 800));

    expect(connections, 1);
    expect(zync.connectionState, ZyncState.connected);
  });
}
