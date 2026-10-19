import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

/// Waits until [condition] holds, polling every 50ms for up to 10 seconds.
Future<void> waitUntil(bool Function() condition, String description) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for: $description');
}

void main() {
  late HttpServer server;
  late String wsUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    wsUrl = 'ws://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    Zync.dispose();
    await server.close(force: true);
  });

  test('auto-reconnects when the server closes the connection', () async {
    var connections = 0;
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      ws.listen((_) {});
      if (connections == 1) {
        // Simulate a server restart / load-balancer idle kill. dart:io
        // only allows 1000 and 3000-4999 as close codes.
        await ws.close(4000, 'server restart');
      }
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        reconnectDelay: const Duration(milliseconds: 100),
        maxReconnectAttempts: 5,
      ),
    );

    final states = <ZyncState>[];
    zync.connectionStateStream.listen(states.add);

    await zync.connect();

    // First connection is closed by the server; the client must dial again
    // and reach the connected state on the new socket.
    await waitUntil(
      () => connections >= 2 && zync.connectionState == ZyncState.connected,
      'client reconnects after server close',
    );
    expect(zync.connectionState, ZyncState.connected);
    expect(states, contains(ZyncState.disconnected));
  });

  test('does not reconnect after manual disconnect', () async {
    var connections = 0;
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      ws.listen((_) {});
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        reconnectDelay: const Duration(milliseconds: 100),
        maxReconnectAttempts: 5,
      ),
    );

    await zync.connect();
    await waitUntil(() => connections >= 1, 'initial connection is established');

    zync.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(connections, 1, reason: 'manual disconnect must not trigger reconnects');
    expect(zync.connectionState, ZyncState.disconnected);
  });

  test('shouldReconnect policy can veto reconnects on fatal close reasons', () async {
    var connections = 0;
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      ws.listen((_) {});
      if (connections == 1) {
        // Simulate an auth-level rejection the client must not retry.
        await ws.close(4003, 'forbidden');
      }
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        reconnectDelay: const Duration(milliseconds: 50),
        maxReconnectAttempts: 3,
        shouldReconnect: (close) => close.reason != 4003,
      ),
    );

    await zync.connect();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(connections, 1, reason: 'a vetoed close reason must not trigger reconnects');
    expect(zync.connectionState, ZyncState.disconnected);
  });

  test('reconnect attempts are capped by maxReconnectAttempts', () async {
    // Bind a server to grab a free port, then close it so every dial
    // fails with connection refused. (The attempt counter resets on a
    // successful open, so the cap can only be reached while dials fail.)
    final deadServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final deadUrl = 'ws://127.0.0.1:${deadServer.port}';
    await deadServer.close(force: true);

    final zync = Zync(
      config: ZyncConfig(
        url: deadUrl,
        reconnectDelay: const Duration(milliseconds: 50),
        maxReconnectAttempts: 2,
      ),
    );

    final errors = <ZyncErrorResponse>[];
    zync.errorStream.listen(errors.add);

    await zync.connect();

    await waitUntil(
      () => errors.any((e) => e.error.toString().contains('Maximum reconnection attempts')),
      'reconnect cap is reported',
    );
    expect(zync.connectionState, ZyncState.disconnected);

    // Once the cap is reached, no further dials happen.
    final errorCount = errors.length;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(errors.length, errorCount);
  });
}
