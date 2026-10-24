import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  group('SocketMessenger.fromJson', () {
    test('parses headers delivered as a plain JSON map', () {
      final messenger = SocketMessenger.fromJson({
        'type': 'message',
        'headers': {'X-Token': 'abc'},
        'topic': 'orders',
        'event': 'order.created',
        'messageId': 'm1',
      });

      expect(messenger.headers, {'X-Token': 'abc'});
      expect(messenger.topic, 'orders');
      expect(messenger.event, 'order.created');
      expect(messenger.messageId, 'm1');
    });

    test('tolerates missing or non-map headers', () {
      expect(SocketMessenger.fromJson({'type': 'pong'}).headers, isNull);
      expect(SocketMessenger.fromJson({'type': 'pong', 'headers': 'junk'}).headers, isNull);
    });

    test('unknown type falls back instead of crashing', () {
      final messenger = SocketMessenger.fromJson({'type': 'totally-unknown'});

      expect(messenger.type, SocketType.values.first);
    });

    test('encode/decode roundtrip preserves routing fields', () {
      final original = SocketMessenger(
        type: SocketType.subscribe,
        topic: 'orders',
        event: 'e',
        messageId: '1',
        headers: {'a': 'b'},
        data: {'id': 42},
      );

      final decoded = SocketMessenger.decode(original.encode());

      expect(decoded.type, SocketType.subscribe);
      expect(decoded.topic, 'orders');
      expect(decoded.event, 'e');
      expect(decoded.messageId, '1');
      expect(decoded.headers, {'a': 'b'});
      expect((decoded.data as Map)['id'], 42);
    });
  });
}
