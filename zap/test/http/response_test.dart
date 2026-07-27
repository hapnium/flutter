import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/enums/zap_provider.dart';
import 'package:zap/src/http/utils/http_status.dart';
import 'package:zap/src/http/response/response.dart';

void main() {
  group('Response', () {
    test('constructor with required status', () {
      final r = Response<String>(status: HttpStatus.OK);
      expect(r.status.code, 200);
      expect(r.message, HttpStatus.OK.description);
      expect(r.body, isNull);
      expect(r.headers, isEmpty);
      expect(r.provider, ZapProvider.io);
    });

    test('constructor with all parameters', () {
      final r = Response<int>(
        status: HttpStatus.CREATED,
        body: 42,
        headers: {'x-custom': 'val'},
        message: 'custom msg',
        provider: ZapProvider.web,
      );
      expect(r.status.code, 201);
      expect(r.body, 42);
      expect(r.headers, {'x-custom': 'val'});
      expect(r.message, 'custom msg');
      expect(r.provider, ZapProvider.web);
    });

    test('hasError for error status', () {
      final r = Response<String>(status: HttpStatus.NOT_FOUND);
      expect(r.hasError, isTrue);
    });

    test('hasError is false for success', () {
      final r = Response<String>(status: HttpStatus.OK);
      expect(r.hasError, isFalse);
    });

    test('isOk', () {
      expect(Response<String>(status: HttpStatus.OK).isOk, isTrue);
      expect(Response<String>(status: HttpStatus.BAD_REQUEST).isOk, isFalse);
    });

    test('unauthorized', () {
      expect(
        Response<String>(status: HttpStatus.UNAUTHORIZED).unauthorized,
        isTrue,
      );
      expect(
        Response<String>(status: HttpStatus.OK).unauthorized,
        isFalse,
      );
    });

    test('is2xxSuccessful', () {
      expect(Response<String>(status: HttpStatus.OK).is2xxSuccessful(), isTrue);
      expect(
        Response<String>(status: HttpStatus.CREATED).is2xxSuccessful(),
        isTrue,
      );
      expect(
        Response<String>(status: HttpStatus.BAD_REQUEST).is2xxSuccessful(),
        isFalse,
      );
    });

    test('is3xxRedirection', () {
      expect(
        Response<String>(status: HttpStatus.MOVED_PERMANENTLY)
            .is3xxRedirection(),
        isTrue,
      );
      expect(
        Response<String>(status: HttpStatus.OK).is3xxRedirection(),
        isFalse,
      );
    });

    test('is4xxClientError', () {
      expect(
        Response<String>(status: HttpStatus.NOT_FOUND).is4xxClientError(),
        isTrue,
      );
      expect(
        Response<String>(status: HttpStatus.OK).is4xxClientError(),
        isFalse,
      );
    });

    test('is5xxServerError', () {
      expect(
        Response<String>(status: HttpStatus.INTERNAL_SERVER_ERROR)
            .is5xxServerError(),
        isTrue,
      );
      expect(
        Response<String>(status: HttpStatus.OK).is5xxServerError(),
        isFalse,
      );
    });

    test('copyWith preserves and overrides', () {
      final r = Response<int>(
        status: HttpStatus.OK,
        body: 42,
        headers: {'a': 'b'},
      );
      final copy = r.copyWith(body: 99, status: HttpStatus.CREATED);
      expect(copy.body, 99);
      expect(copy.status.code, 201);
      expect(copy.headers, {'a': 'b'});
    });

    test('toJson', () {
      final r = Response<String>(
        status: HttpStatus.OK,
        body: 'hello',
        headers: {'x': 'y'},
      );
      final json = r.toJson();
      expect(json['body'], 'hello');
      expect(json['headers'], {'x': 'y'});
      expect(json['status'], isA<Map>());
    });
  });
}