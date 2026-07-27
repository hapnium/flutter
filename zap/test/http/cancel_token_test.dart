import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/exceptions/zap_exception.dart';
import 'package:zap/src/models/cancel_token.dart';

void main() {
  group('CancelToken', () {
    test('starts as not cancelled', () {
      final token = CancelToken();
      expect(token.isCancelled, isFalse);
      expect(token.reason, isNull);
    });

    test('cancel sets isCancelled to true', () {
      final token = CancelToken();
      token.cancel('user left');
      expect(token.isCancelled, isTrue);
    });

    test('cancel stores reason', () {
      final token = CancelToken();
      token.cancel('timeout');
      expect(token.reason, 'timeout');
    });

    test('cancel with default reason', () {
      final token = CancelToken();
      token.cancel();
      expect(token.reason, 'Request cancelled');
    });

    test('cancel is idempotent', () {
      final token = CancelToken();
      token.cancel('first');
      token.cancel('second');
      expect(token.reason, 'first');
    });

    test('future completes on cancel', () async {
      final token = CancelToken();
      final future = token.future;
      token.cancel('done');
      final reason = await future;
      expect(reason, 'done');
    });

    test('throwIfCancelled throws when cancelled', () {
      final token = CancelToken();
      token.cancel('oops');
      expect(() => token.throwIfCancelled(), throwsA(isA<ZapException>()));
    });

    test('throwIfCancelled does nothing when not cancelled', () {
      final token = CancelToken();
      token.throwIfCancelled();
    });
  });
}