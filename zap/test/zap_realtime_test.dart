import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late SessionResponse session;

  setUp(() {
    session = SessionResponse(
      accessToken: 'token-1',
      refreshToken: 'refresh-1',
    );
  });

  tearDown(() {
    Zync.dispose();
  });

  group('Zync Tests', () {
    test('singleton enforcement works', () {
      Zync(config: ZyncConfig(url: 'ws://localhost:65534', session: session));

      expect(
        () => Zync(config: ZyncConfig(url: 'ws://localhost:65534')),
        throwsA(isA<Exception>()),
      );
    });

    test('emit when disconnected reports an error', () async {
      final errors = <ZyncErrorResponse>[];

      final realtime = Zync(
        config: ZyncConfig(
          url: 'ws://localhost:65534',
          session: session,
        ),
      );

      final sub = realtime.errorStream.listen(errors.add);
      realtime.emit(SocketType.auth, {'message': 'test'});

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(errors.isNotEmpty, true);
      expect(errors.first.where, 'Emit Error');
    });

    test('subscribe and unsubscribe while disconnected do not throw', () {
      final realtime = Zync(
        config: ZyncConfig(
          url: 'ws://localhost:65534',
          session: session,
        ),
      );

      realtime.subscribe(topic: 'updates', onMessage: (_) {});
      realtime.unsubscribe('updates');

      expect(realtime.connectionState, isNot(ZyncState.connected));
    });

    test('disconnect sets state to disconnected', () {
      final realtime = Zync(
        config: ZyncConfig(
          url: 'ws://localhost:65534',
          session: session,
        ),
      );

      realtime.disconnect();
      expect(realtime.connectionState, ZyncState.disconnected);
    });

    test('on/off listener registration works without connection', () {
      final realtime = Zync(
        config: ZyncConfig(
          url: 'ws://localhost:65534',
          session: session,
        ),
      );

      realtime.on(SocketType.ack, (_) {});
      realtime.off(SocketType.ack);

      expect(realtime.isConnected, false);
    });
  });
}
