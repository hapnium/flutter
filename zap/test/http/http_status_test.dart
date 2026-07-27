import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/http/utils/http_status.dart';

void main() {
  group('HttpStatus', () {
    test('OK has correct code and name', () {
      expect(HttpStatus.OK.code, 200);
      expect(HttpStatus.OK.name, 'OK');
    });

    test('NOT_FOUND has correct code', () {
      expect(HttpStatus.NOT_FOUND.code, 404);
    });

    test('UNAUTHORIZED has correct code', () {
      expect(HttpStatus.UNAUTHORIZED.code, 401);
    });

    test('BAD_REQUEST has correct code', () {
      expect(HttpStatus.BAD_REQUEST.code, 400);
    });

    test('INTERNAL_SERVER_ERROR has correct code', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.code, 500);
    });

    test('isOk returns true for 2xx', () {
      expect(HttpStatus.OK.isOk, isTrue);
      expect(HttpStatus.CREATED.isOk, isTrue);
      expect(HttpStatus.NO_CONTENT.isOk, isTrue);
    });

    test('isOk returns false for non-2xx', () {
      expect(HttpStatus.BAD_REQUEST.isOk, isFalse);
      expect(HttpStatus.INTERNAL_SERVER_ERROR.isOk, isFalse);
    });

    test('hasError returns true for non-2xx', () {
      expect(HttpStatus.BAD_REQUEST.hasError, isTrue);
      expect(HttpStatus.INTERNAL_SERVER_ERROR.hasError, isTrue);
    });

    test('hasError returns false for 2xx', () {
      expect(HttpStatus.OK.hasError, isFalse);
    });

    test('isServerError', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.isServerError, isTrue);
      expect(HttpStatus.BAD_GATEWAY.isServerError, isTrue);
      expect(HttpStatus.OK.isServerError, isFalse);
    });

    test('isUnauthorized', () {
      expect(HttpStatus.UNAUTHORIZED.isUnauthorized, isTrue);
      expect(HttpStatus.OK.isUnauthorized, isFalse);
    });

    test('isForbidden', () {
      expect(HttpStatus.FORBIDDEN.isForbidden, isTrue);
      expect(HttpStatus.OK.isForbidden, isFalse);
    });

    test('isNotFound', () {
      expect(HttpStatus.NOT_FOUND.isNotFound, isTrue);
      expect(HttpStatus.OK.isNotFound, isFalse);
    });

    test('connectionError', () {
      expect(HttpStatus.CONNECTION_NOT_REACHABLE.connectionError, isTrue);
      expect(HttpStatus.REQUEST_CANCELLED.connectionError, isTrue);
      expect(HttpStatus.OK.connectionError, isFalse);
    });

    test('between', () {
      expect(HttpStatus.OK.between(200, 299), isTrue);
      expect(HttpStatus.OK.between(300, 400), isFalse);
    });

    test('isInformational', () {
      expect(HttpStatus.CONTINUE.isInformational, isTrue);
      expect(HttpStatus.OK.isInformational, isFalse);
    });

    test('isSuccess', () {
      expect(HttpStatus.OK.isSuccess, isTrue);
      expect(HttpStatus.BAD_REQUEST.isSuccess, isFalse);
    });

    test('isRedirection', () {
      expect(HttpStatus.MOVED_PERMANENTLY.isRedirection, isTrue);
      expect(HttpStatus.OK.isRedirection, isFalse);
    });

    test('isClientError', () {
      expect(HttpStatus.BAD_REQUEST.isClientError, isTrue);
      expect(HttpStatus.OK.isClientError, isFalse);
    });

    test('isError', () {
      expect(HttpStatus.BAD_REQUEST.isError, isTrue);
      expect(HttpStatus.INTERNAL_SERVER_ERROR.isError, isTrue);
      expect(HttpStatus.OK.isError, isFalse);
    });

    group('fromCode', () {
      test('returns known status code', () {
        final s = HttpStatus.fromCode(200);
        expect(s.name, 'OK');
        expect(s.code, 200);
      });

      test('creates unknown 4xx code', () {
        final s = HttpStatus.fromCode(460);
        expect(s.code, 460);
        expect(s.name, contains('460'));
      });

      test('creates unknown 5xx code', () {
        final s = HttpStatus.fromCode(555);
        expect(s.code, 555);
        expect(s.description, contains('Server error'));
      });

      test('creates unknown 1xx code', () {
        final s = HttpStatus.fromCode(199);
        expect(s.code, 199);
        expect(s.description, contains('Informational'));
      });

      test('creates unknown 3xx code', () {
        final s = HttpStatus.fromCode(399);
        expect(s.description, contains('Redirection'));
      });

      test('creates unknown 2xx code', () {
        final s = HttpStatus.fromCode(299);
        expect(s.description, contains('Success'));
      });

      test('caches unknown codes', () {
        final s1 = HttpStatus.fromCode(999);
        final s2 = HttpStatus.fromCode(999);
        expect(identical(s1, s2), isTrue);
      });
    });

    group('getAllStatusCodes', () {
      test('returns a list', () {
        final all = HttpStatus.getAllStatusCodes();
        expect(all, isA<List<HttpStatus>>());
        expect(all.length, greaterThan(50));
      });
    });

    group('getStatusCodesInRange', () {
      test('returns 4xx codes', () {
        final codes = HttpStatus.getStatusCodesInRange(400, 499);
        expect(codes, isNotEmpty);
        expect(codes.every((s) => s.code >= 400 && s.code <= 499), isTrue);
        expect(codes.first.code, lessThanOrEqualTo(codes.last.code));
      });
    });

    test('isPredefined', () {
      expect(HttpStatus.isPredefined(200), isTrue);
      expect(HttpStatus.isPredefined(12345), isFalse);
    });

    test('toString returns name', () {
      expect(HttpStatus.OK.toString(), 'OK');
    });

    test('equality by code', () {
      expect(HttpStatus.OK == HttpStatus.fromCode(200), isTrue);
      expect(HttpStatus.OK == HttpStatus.NOT_FOUND, isFalse);
    });

    test('hashCode by code', () {
      expect(HttpStatus.OK.hashCode, 200.hashCode);
    });

    test('toJson', () {
      final json = HttpStatus.OK.toJson();
      expect(json['code'], 200);
      expect(json['name'], 'OK');
      expect(json['description'], isA<String>());
    });

    test('im_a_teapot exists', () {
      expect(HttpStatus.IM_A_TEAPOT.code, 418);
    });
  });
}