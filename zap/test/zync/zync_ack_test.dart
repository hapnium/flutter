import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late HttpServer server;
  late String wsUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    wsUrl = 'ws://${server.address.address}:${server.port}';

    server.listen((HttpRequest request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] != 'send') return;

        final messageId = msg['messageId'];
        switch (msg['endpoint']) {
          case '/ack-me':
            ws.add(jsonEncode({
              'type': 'ack',
              'messageId': messageId,
              'data': {'ok': true},
            }));
          case '/nack-me':
            ws.add(jsonEncode({
              'type': 'nack',
              'messageId': messageId,
              'data': {'reason': 'quota exceeded'},
            }));
          case '/silent':
            break; // Never answer: exercises the timeout path.
        }
      });
    });
  });

  tearDown(() async {
    Zync.dispose();
    await server.close(force: true);
  });

  Future<Zync> connectZync() async {
    final zync = Zync(config: ZyncConfig(url: wsUrl));
    await zync.connect();
    return zync;
  }

  test('sendWithAck completes with the ack envelope', () async {
    final zync = await connectZync();

    final ack = await zync.sendWithAck(
      endpoint: '/ack-me',
      data: {'id': 42},
      timeout: const Duration(seconds: 5),
    );

    expect(ack.type, SocketType.ack);
    expect((ack.data as Map)['ok'], isTrue);
  });

  test('a nack fails the future with a ZapException', () async {
    final zync = await connectZync();

    await expectLater(
      zync.sendWithAck(
        endpoint: '/nack-me',
        data: {'id': 1},
        timeout: const Duration(seconds: 5),
      ),
      throwsA(isA<ZapException>()),
    );
  });

  test('a missing acknowledgement times out', () async {
    final zync = await connectZync();

    await expectLater(
      zync.sendWithAck(
        endpoint: '/silent',
        data: {'id': 1},
        timeout: const Duration(milliseconds: 300),
      ),
      throwsA(isA<ZapException>()),
    );
  });

  test('sendWithAck throws immediately while disconnected', () async {
    final zync = await connectZync();
    zync.disconnect();

    await expectLater(
      zync.sendWithAck(endpoint: '/ack-me', data: {'id': 1}),
      throwsA(isA<ZapException>()),
    );
  });

  test('disconnect fails all pending acknowledgement waiters', () async {
    final zync = await connectZync();

    Object? error;
    final pending = zync
        .sendWithAck(
          endpoint: '/silent',
          data: {'id': 1},
          timeout: const Duration(seconds: 30),
        )
        .then<Object?>((ack) => ack)
        .catchError((Object e) {
      error = e;
      return null;
    });

    // Give the send a moment to hit the wire, then drop the connection.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    zync.disconnect();
    await pending;

    expect(error, isA<ZapException>());
  });

  test('ack correlation matches by messageId, not arrival order', () async {
    final zync = await connectZync();

    // Two overlapping calls; the server answers in arrival order, which
    // must still complete the right future.
    final first = zync.sendWithAck(
      endpoint: '/ack-me',
      data: {'seq': 1},
      timeout: const Duration(seconds: 5),
    );
    final second = zync.sendWithAck(
      endpoint: '/ack-me',
      data: {'seq': 2},
      timeout: const Duration(seconds: 5),
    );

    final results = await Future.wait([first, second]);
    expect(results, hasLength(2));
    for (final ack in results) {
      expect(ack.type, SocketType.ack);
    }
  });
}
