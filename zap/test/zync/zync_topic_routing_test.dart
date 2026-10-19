import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

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

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    wsUrl = 'ws://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    Zync.dispose();
    await server.close(force: true);
  });

  test('frames route to the handler registered for their topic', () async {
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] == 'subscribe' && msg['topic'] == 'orders') {
          // Topic-tagged frame: must reach the 'orders' handler.
          ws.add(jsonEncode({
            'type': 'receive',
            'topic': 'orders',
            'event': 'order.created',
            'messageId': 'm1',
            'data': {'id': 42},
          }));
          // Untagged frame: must NOT leak into the 'orders' handler.
          ws.add(jsonEncode({
            'type': 'receive',
            'data': {'id': 7},
          }));
        }
      });
    });

    final zync = Zync(config: ZyncConfig(url: wsUrl));
    await zync.connect();

    final received = <ZyncResponse>[];
    zync.subscribe(topic: 'orders', onMessage: received.add);

    await waitUntil(() => received.isNotEmpty, 'topic frame is delivered');

    expect(received, hasLength(1), reason: 'untagged frames must not reach topic handlers');
    expect(received.single.topic, 'orders');
    expect(received.single.type, SocketType.receive);
    expect(received.single.event, 'order.created');
    expect(received.single.messageId, 'm1');
    final payload = (received.single.data as SocketMessenger).data as Map<String, dynamic>;
    expect(payload['id'], 42);
  });

  test('frames without a topic still route by type name (back-compat)', () async {
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] == 'subscribe' && msg['topic'] == 'receive') {
          ws.add(jsonEncode({
            'type': 'receive',
            'data': {'id': 9},
          }));
        }
      });
    });

    final zync = Zync(config: ZyncConfig(url: wsUrl));
    await zync.connect();

    final received = <ZyncResponse>[];
    // Registering under the type name is the legacy routing contract.
    zync.subscribe(topic: 'receive', onMessage: received.add);

    await waitUntil(() => received.isNotEmpty, 'type-name routed frame is delivered');

    expect(received.single.topic, isNull);
    final payload = (received.single.data as SocketMessenger).data as Map<String, dynamic>;
    expect(payload['id'], 9);
  });

  test('topic error frames surface on the error stream with topic context', () async {
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] == 'subscribe' && msg['topic'] == 'orders') {
          ws.add(jsonEncode({
            'type': 'error',
            'topic': 'orders',
            'data': {'reason': 'quota exceeded'},
          }));
        }
      });
    });

    final zync = Zync(config: ZyncConfig(url: wsUrl));
    final errors = <ZyncErrorResponse>[];
    zync.errorStream.listen(errors.add);
    final received = <ZyncResponse>[];

    await zync.connect();
    zync.subscribe(topic: 'orders', onMessage: received.add);

    await waitUntil(() => errors.isNotEmpty, 'topic error reaches the error stream');

    expect(errors.single.topic, 'orders');
    expect(received.single.topic, 'orders',
        reason: 'topic handlers also receive the error frame directly');
  });

  test('handlers survive disconnect and the wire subscription is re-sent on reconnect', () async {
    var connections = 0;
    final subscribeFrames = <Map<String, dynamic>>[];
    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      connections += 1;
      final current = connections;
      ws.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] == 'subscribe') {
          subscribeFrames.add(msg);
        }
      });
      if (current == 1) {
        await ws.close(4000, 'server restart');
      }
    });

    final zync = Zync(
      config: ZyncConfig(
        url: wsUrl,
        reconnectDelay: const Duration(milliseconds: 50),
        maxReconnectAttempts: 5,
      ),
    );
    await zync.connect();

    final received = <ZyncResponse>[];
    zync.subscribe(topic: 'orders', onMessage: received.add);
    await waitUntil(() => subscribeFrames.isNotEmpty, 'initial subscribe is sent');

    // Server closes the first connection; the client reconnects.
    await waitUntil(
      () => connections >= 2 && zync.connectionState == ZyncState.connected,
      'client reconnects',
    );
    await waitUntil(
      () => subscribeFrames.length >= 2,
      'subscribe is re-sent on the new connection',
    );

    expect(subscribeFrames.every((f) => f['topic'] == 'orders'), isTrue);
    expect(received, isEmpty, reason: 'no frames pushed yet — this checks wire re-subscription only');
  });
}
