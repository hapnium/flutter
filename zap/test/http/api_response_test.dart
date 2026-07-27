import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/models/response/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('constructor sets all fields', () {
      final r = ApiResponse(
        status: 'success',
        code: 200,
        message: 'ok',
        data: {'id': 1},
      );
      expect(r.status, 'success');
      expect(r.code, 200);
      expect(r.message, 'ok');
      expect(r.data, {'id': 1});
    });

    test('fromJson parses valid JSON', () {
      final r = ApiResponse.fromJson({
        'status': 'success',
        'code': 200,
        'message': 'ok',
        'data': {'id': 1},
      });
      expect(r.status, 'success');
      expect(r.code, 200);
      expect(r.data, {'id': 1});
    });

    test('fromJson defaults on missing fields', () {
      final r = ApiResponse.fromJson({});
      expect(r.status, '');
      expect(r.code, 400);
      expect(r.message, "Couldn't validate request");
      expect(r.data, isNull);
    });

    test('isOk for 200', () {
      expect(ApiResponse(status: 's', code: 200, message: 'm').isOk, isTrue);
    });

    test('isOk for 201', () {
      expect(ApiResponse(status: 's', code: 201, message: 'm').isOk, isTrue);
    });

    test('isOk is false for 400', () {
      expect(ApiResponse(status: 's', code: 400, message: 'm').isOk, isFalse);
    });

    test('isCreated for 201', () {
      expect(ApiResponse(status: 's', code: 201, message: 'm').isCreated, isTrue);
    });

    test('isCreated is false for 200', () {
      expect(ApiResponse(status: 's', code: 200, message: 'm').isCreated, isFalse);
    });

    test('copyWith overrides specified fields', () {
      final r = ApiResponse(status: 's', code: 200, message: 'ok', data: 'd');
      final copy = r.copyWith(code: 201, message: 'created');
      expect(copy.code, 201);
      expect(copy.message, 'created');
      expect(copy.status, 's');
      expect(copy.data, 'd');
    });

    test('copyWith preserves original', () {
      final r = ApiResponse(status: 's', code: 200, message: 'ok');
      r.copyWith(code: 201);
      expect(r.code, 200);
    });

    test('error factory', () {
      final r = ApiResponse.error('bad');
      expect(r.status, 'error');
      expect(r.code, 400);
      expect(r.message, 'bad');
    });

    test('unauthorized factory', () {
      final r = ApiResponse.unauthorized('no access');
      expect(r.status, 'unauthorized');
      expect(r.code, 401);
      expect(r.message, 'no access');
    });

    test('toJson round-trips', () {
      final r = ApiResponse(
        status: 'success',
        code: 200,
        message: 'ok',
        data: {'key': 'val'},
      );
      final json = r.toJson();
      final r2 = ApiResponse.fromJson(json);
      expect(r2.status, r.status);
      expect(r2.code, r.code);
      expect(r2.message, r.message);
      expect(r2.data, r.data);
    });

    test('resolvedAs parses data', () {
      final r = ApiResponse(status: 's', code: 200, message: 'm', data: 42);
      final result = r.resolvedAs<int>((d) => (d as int) * 2);
      expect(result, 84);
    });

    test('resolvedListAs parses list', () {
      final r = ApiResponse(
        status: 's',
        code: 200,
        message: 'm',
        data: [1, 2, 3],
      );
      final result = r.resolvedListAs<int>((d) => (d as int) * 10);
      expect(result, [10, 20, 30]);
    });

    test('resolvedListAs returns empty for non-list', () {
      final r = ApiResponse(status: 's', code: 200, message: 'm', data: 'not a list');
      final result = r.resolvedListAs<int>((d) => d as int);
      expect(result, isEmpty);
    });

    test('resolvedListAs returns empty for null data', () {
      final r = ApiResponse(status: 's', code: 200, message: 'm');
      final result = r.resolvedListAs<int>((d) => d as int);
      expect(result, isEmpty);
    });
  });
}