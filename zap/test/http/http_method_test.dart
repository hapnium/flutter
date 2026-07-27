import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/http/utils/http_method.dart';

void main() {
  group('HttpMethod', () {
    test('constants have correct values', () {
      expect(HttpMethod.GET, 'GET');
      expect(HttpMethod.POST, 'POST');
      expect(HttpMethod.PUT, 'PUT');
      expect(HttpMethod.DELETE, 'DELETE');
      expect(HttpMethod.PATCH, 'PATCH');
      expect(HttpMethod.HEAD, 'HEAD');
      expect(HttpMethod.OPTIONS, 'OPTIONS');
      expect(HttpMethod.TRACE, 'TRACE');
      expect(HttpMethod.CONNECT, 'CONNECT');
    });

    test('FROM converts to uppercase', () {
      expect(HttpMethod.FROM('get'), 'GET');
      expect(HttpMethod.FROM('post'), 'POST');
      expect(HttpMethod.FROM('Get'), 'GET');
      expect(HttpMethod.FROM('post'), 'POST');
    });

    test('FROM already uppercase stays same', () {
      expect(HttpMethod.FROM('GET'), 'GET');
    });
  });
}