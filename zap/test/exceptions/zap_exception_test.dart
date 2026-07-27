import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/enums/exception_type.dart';
import 'package:zap/src/exceptions/zap_exception.dart';

void main() {
  final testUri = Uri.parse('https://api.example.com/users');

  group('ZapException', () {
    test('main constructor with all parameters', () {
      final e = ZapException(
        'error',
        testUri,
        ExceptionType.server,
        500,
        {'key': 'val'},
        Exception('orig'),
        StackTrace.empty,
      );
      expect(e.message, 'error');
      expect(e.uri, testUri);
      expect(e.type, ExceptionType.server);
      expect(e.statusCode, 500);
      expect(e.details, {'key': 'val'});
      expect(e.originalException, isA<Exception>());
      expect(e.originalStackTrace, StackTrace.empty);
    });

    test('main constructor with defaults', () {
      final e = ZapException('oops');
      expect(e.message, 'oops');
      expect(e.uri, isNull);
      expect(e.type, ExceptionType.unknown);
      expect(e.statusCode, isNull);
      expect(e.details, isNull);
      expect(e.originalException, isNull);
      expect(e.originalStackTrace, isNull);
    });

    group('named constructors set correct type', () {
      test('.timeout', () {
        final e = ZapException.timeout('t', testUri, {'a': 1});
        expect(e.type, ExceptionType.timeout);
        expect(e.message, 't');
        expect(e.uri, testUri);
        expect(e.statusCode, isNull);
        expect(e.details, {'a': 1});
      });

      test('.network', () {
        final e = ZapException.network('n', testUri);
        expect(e.type, ExceptionType.network);
        expect(e.message, 'n');
      });

      test('.server', () {
        final e = ZapException.server('s', 503, testUri);
        expect(e.type, ExceptionType.server);
        expect(e.statusCode, 503);
      });

      test('.client', () {
        final e = ZapException.client('c', 422, testUri, {'field': 'email'});
        expect(e.type, ExceptionType.client);
        expect(e.statusCode, 422);
        expect(e.details, {'field': 'email'});
      });

      test('.auth', () {
        final e = ZapException.auth('a', testUri, 401);
        expect(e.type, ExceptionType.auth);
        expect(e.statusCode, 401);
      });

      test('.cancelled', () {
        final e = ZapException.cancelled('cancelled');
        expect(e.type, ExceptionType.cancelled);
        expect(e.uri, isNull);
      });

      test('.ssl', () {
        final e = ZapException.ssl('ssl err', testUri);
        expect(e.type, ExceptionType.ssl);
      });

      test('.connection', () {
        final e = ZapException.connection('conn', testUri);
        expect(e.type, ExceptionType.connection);
      });

      test('.dns', () {
        final e = ZapException.dns('dns', testUri);
        expect(e.type, ExceptionType.dns);
      });

      test('.parsing', () {
        final e = ZapException.parsing('parse');
        expect(e.type, ExceptionType.parsing);
      });
    });

    group('type checks', () {
      test('isTimeout', () {
        expect(ZapException.timeout('t').isTimeout, isTrue);
        expect(ZapException.network('n').isTimeout, isFalse);
      });

      test('isNetwork', () {
        expect(ZapException.network('n').isNetwork, isTrue);
      });

      test('isServer', () {
        expect(ZapException.server('s', 500).isServer, isTrue);
      });

      test('isClient', () {
        expect(ZapException.client('c', 400).isClient, isTrue);
      });

      test('isAuth', () {
        expect(ZapException.auth('a').isAuth, isTrue);
      });

      test('isCancelled', () {
        expect(ZapException.cancelled('x').isCancelled, isTrue);
      });

      test('isSSL', () {
        expect(ZapException.ssl('x').isSSL, isTrue);
      });

      test('isConnection', () {
        expect(ZapException.connection('x').isConnection, isTrue);
      });

      test('isDNS', () {
        expect(ZapException.dns('x').isDNS, isTrue);
      });

      test('isParsing', () {
        expect(ZapException.parsing('x').isParsing, isTrue);
      });
    });

    group('isRetryable', () {
      test('network is retryable', () {
        expect(ZapException.network('n').isRetryable, isTrue);
      });

      test('timeout is retryable', () {
        expect(ZapException.timeout('t').isRetryable, isTrue);
      });

      test('connection is retryable', () {
        expect(ZapException.connection('c').isRetryable, isTrue);
      });

      test('dns is retryable', () {
        expect(ZapException.dns('d').isRetryable, isTrue);
      });

      test('server 502 is retryable', () {
        expect(ZapException.server('s', 502).isRetryable, isTrue);
      });

      test('server 503 is retryable', () {
        expect(ZapException.server('s', 503).isRetryable, isTrue);
      });

      test('server 504 is retryable', () {
        expect(ZapException.server('s', 504).isRetryable, isTrue);
      });

      test('server 500 is NOT retryable', () {
        expect(ZapException.server('s', 500).isRetryable, isFalse);
      });

      test('client is NOT retryable', () {
        expect(ZapException.client('c', 400).isRetryable, isFalse);
      });

      test('auth is NOT retryable', () {
        expect(ZapException.auth('a').isRetryable, isFalse);
      });

      test('cancelled is NOT retryable', () {
        expect(ZapException.cancelled('x').isRetryable, isFalse);
      });

      test('ssl is NOT retryable', () {
        expect(ZapException.ssl('x').isRetryable, isFalse);
      });

      test('parsing is NOT retryable', () {
        expect(ZapException.parsing('x').isRetryable, isFalse);
      });

      test('unknown is NOT retryable', () {
        expect(ZapException('u').isRetryable, isFalse);
      });
    });

    group('toString', () {
      test('minimal', () {
        final e = ZapException('msg');
        expect(e.toString(), 'ZapException [UNKNOWN]: msg');
      });

      test('with uri and status', () {
        final e = ZapException.server('err', 500, testUri);
        final str = e.toString();
        expect(str, contains('ZapException [SERVER]: err'));
        expect(str, contains('(URL: $testUri)'));
        expect(str, contains('(Status: 500)'));
      });

      test('with details', () {
        final e = ZapException('err', null, ExceptionType.unknown, null, {'k': 'v'});
        expect(e.toString(), contains('(Details: {k: v})'));
      });

      test('empty details are not shown', () {
        final e = ZapException('err', null, ExceptionType.unknown, null, {});
        expect(e.toString().contains('Details'), isFalse);
      });
    });

    group('toMap', () {
      test('contains expected keys', () {
        final e = ZapException.timeout('t', testUri, {'a': 1});
        final map = e.toMap();
        expect(map['message'], 't');
        expect(map['uri'], testUri.toString());
        expect(map['type'], 'timeout');
        expect(map['statusCode'], isNull);
        expect(map['details'], {'a': 1});
        expect(map['isRetryable'], true);
      });

      test('server exception map', () {
        final e = ZapException.server('s', 502, testUri);
        final map = e.toMap();
        expect(map['statusCode'], 502);
        expect(map['isRetryable'], true);
      });

      test('auth exception map', () {
        final e = ZapException.auth('a', testUri, 401);
        final map = e.toMap();
        expect(map['type'], 'auth');
        expect(map['isRetryable'], false);
      });
    });

    test('implements Exception', () {
      expect(ZapException('x'), isA<Exception>());
    });
  });
}