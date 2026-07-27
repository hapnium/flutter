import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/enums/socket_status.dart';
import 'package:zap/src/enums/socket_type.dart';
import 'package:zap/src/enums/zap_provider.dart';
import 'package:zap/src/enums/zync_state.dart';
import 'package:zap/src/enums/exception_type.dart';

void main() {
  group('ExceptionType enum', () {
    test('has all expected values', () {
      expect(ExceptionType.values, hasLength(11));
      expect(ExceptionType.values, contains(ExceptionType.network));
      expect(ExceptionType.values, contains(ExceptionType.timeout));
      expect(ExceptionType.values, contains(ExceptionType.server));
      expect(ExceptionType.values, contains(ExceptionType.client));
      expect(ExceptionType.values, contains(ExceptionType.auth));
      expect(ExceptionType.values, contains(ExceptionType.cancelled));
      expect(ExceptionType.values, contains(ExceptionType.ssl));
      expect(ExceptionType.values, contains(ExceptionType.connection));
      expect(ExceptionType.values, contains(ExceptionType.dns));
      expect(ExceptionType.values, contains(ExceptionType.parsing));
      expect(ExceptionType.values, contains(ExceptionType.unknown));
    });
  });

  group('SocketStatus enum', () {
    test('has all expected values', () {
      expect(SocketStatus.values, hasLength(3));
      expect(SocketStatus.values, contains(SocketStatus.connecting));
      expect(SocketStatus.values, contains(SocketStatus.connected));
      expect(SocketStatus.values, contains(SocketStatus.closed));
    });
  });

  group('SocketType enum', () {
    test('has all expected values', () {
      expect(SocketType.values.length, greaterThanOrEqualTo(16));
      expect(SocketType.values, contains(SocketType.receive));
      expect(SocketType.values, contains(SocketType.send));
      expect(SocketType.values, contains(SocketType.connect));
      expect(SocketType.values, contains(SocketType.disconnect));
      expect(SocketType.values, contains(SocketType.error));
      expect(SocketType.values, contains(SocketType.close));
      expect(SocketType.values, contains(SocketType.open));
      expect(SocketType.values, contains(SocketType.ping));
      expect(SocketType.values, contains(SocketType.pong));
      expect(SocketType.values, contains(SocketType.subscribe));
      expect(SocketType.values, contains(SocketType.unsubscribe));
      expect(SocketType.values, contains(SocketType.auth));
      expect(SocketType.values, contains(SocketType.ack));
      expect(SocketType.values, contains(SocketType.nack));
      expect(SocketType.values, contains(SocketType.reconnect));
      expect(SocketType.values, contains(SocketType.timeout));
      expect(SocketType.values, contains(SocketType.retry));
    });
  });

  group('ZapProvider enum', () {
    test('has all expected values', () {
      expect(ZapProvider.values, hasLength(4));
      expect(ZapProvider.values, contains(ZapProvider.io));
      expect(ZapProvider.values, contains(ZapProvider.web));
      expect(ZapProvider.values, contains(ZapProvider.graphql));
    });
  });

  group('ZyncState enum', () {
    test('has all expected values', () {
      expect(ZyncState.values, hasLength(9));
      expect(ZyncState.values, contains(ZyncState.dormant));
      expect(ZyncState.values, contains(ZyncState.connecting));
      expect(ZyncState.values, contains(ZyncState.connected));
      expect(ZyncState.values, contains(ZyncState.disconnected));
      expect(ZyncState.values, contains(ZyncState.subscribing));
      expect(ZyncState.values, contains(ZyncState.subscribed));
      expect(ZyncState.values, contains(ZyncState.sending));
      expect(ZyncState.values, contains(ZyncState.sent));
      expect(ZyncState.values, contains(ZyncState.notSent));
    });
  });

  group('ExceptionType name', () {
    test('all values have names', () {
      for (final type in ExceptionType.values) {
        expect(type.name, isNotEmpty);
      }
    });
  });
}