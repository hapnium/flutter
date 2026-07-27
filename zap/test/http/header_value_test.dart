import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/http/response/header_value.dart';

void main() {
  group('HeaderValue', () {
    test('parse simple value', () {
      final hv = HeaderValue.parse('text/html');
      expect(hv.value, 'text/html');
      expect(hv.parameters, isEmpty);
    });

    test('parse value with parameters', () {
      final hv = HeaderValue.parse('text/html; charset=utf-8');
      expect(hv.value, 'text/html');
      expect(hv.parameters!['charset'], 'utf-8');
    });

    test('parse multiple parameters', () {
      final hv = HeaderValue.parse('text/html; charset=utf-8; boundary=abc');
      expect(hv.value, 'text/html');
      expect(hv.parameters!['charset'], 'utf-8');
      expect(hv.parameters!['boundary'], 'abc');
    });

    test('charset is lowercased', () {
      final hv = HeaderValue.parse('text/html; charset=UTF-8');
      expect(hv.parameters!['charset'], 'utf-8');
    });

    test('quoted parameter values', () {
      final hv = HeaderValue.parse('text/html; charset="utf-8"');
      expect(hv.parameters!['charset'], 'utf-8');
    });

    test('toString reconstructs value', () {
      final hv = HeaderValue.parse('text/html; charset=utf-8');
      expect(hv.toString(), 'text/html; charset=utf-8');
    });

    test('constructor with explicit parameters', () {
      final hv = HeaderValue('text/plain', {'charset': 'ascii'});
      expect(hv.value, 'text/plain');
    });

    test('empty parameters', () {
      final hv = HeaderValue.parse('application/json');
      expect(hv.parameters, isEmpty);
    });

    test('parameter with no value', () {
      final hv = HeaderValue.parse('text/html; foo');
      expect(hv.value, 'text/html');
    });

    test('empty string returns empty value', () {
      final hv = HeaderValue.parse('');
      expect(hv.value, isEmpty);
    });
  });
}