import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/socket/src/socket_close.dart';

void main() {
  group('SocketClose', () {
    test('constructor stores message and reason', () {
      final close = SocketClose('Normal Closure', 1000);
      expect(close.message, 'Normal Closure');
      expect(close.reason, 1000);
    });

    test('toString format', () {
      final close = SocketClose('Normal Closure', 1000);
      expect(close.toString(), 'Closed by server [1000 => Normal Closure]!');
    });

    test('nullable fields', () {
      final close = SocketClose(null, null);
      expect(close.message, isNull);
      expect(close.reason, isNull);
      expect(close.toString(), contains('null'));
    });
  });
}