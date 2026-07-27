import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/exceptions/smart_exception.dart';

void main() {
  group('SmartException', () {
    test('implements Exception', () {
      expect(SmartException('test'), isA<Exception>());
    });

    test('stores message', () {
      final exception = SmartException('Something went wrong');
      expect(exception.message, 'Something went wrong');
    });

    test('stores optional code', () {
      final exception = SmartException('Error', code: 404);
      expect(exception.code, 404);
    });

    test('code is null when not provided', () {
      final exception = SmartException('Error');
      expect(exception.code, isNull);
    });

    test('toString without code', () {
      final exception = SmartException('Something failed');
      expect(exception.toString(), 'Smart Exception: Something failed');
    });

    test('toString with code', () {
      final exception = SmartException('Not found', code: 404);
      expect(exception.toString(), 'Smart Exception: Not found. Code: 404');
    });

    test('message is mutable', () {
      final exception = SmartException('Original');
      exception.message = 'Updated';
      expect(exception.message, 'Updated');
    });

    test('code is mutable', () {
      final exception = SmartException('Error');
      exception.code = 500;
      expect(exception.code, 500);
    });
  });
}