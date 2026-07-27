import 'package:flutter_test/flutter_test.dart';
import 'package:device/src/models/device_validator.dart';

void main() {
  group('DeviceValidator', () {
    group('constructor', () {
      test('creates instance with isValid and message', () {
        final validator = DeviceValidator(isValid: true, message: '');

        expect(validator.isValid, isTrue);
        expect(validator.message, '');
      });

      test('creates invalid instance with message', () {
        final validator = DeviceValidator(isValid: false, message: 'Error occurred');

        expect(validator.isValid, isFalse);
        expect(validator.message, 'Error occurred');
      });
    });

    group('valid factory', () {
      test('creates valid validator with empty message', () {
        final validator = DeviceValidator.valid();

        expect(validator.isValid, isTrue);
        expect(validator.message, '');
      });
    });

    group('invalid factory', () {
      test('creates invalid validator with custom message', () {
        final validator = DeviceValidator.invalid('Device is rooted');

        expect(validator.isValid, isFalse);
        expect(validator.message, 'Device is rooted');
      });

      test('stores different messages', () {
        final v1 = DeviceValidator.invalid('First message');
        final v2 = DeviceValidator.invalid('Second message');

        expect(v1.message, 'First message');
        expect(v2.message, 'Second message');
      });
    });

    group('properties', () {
      test('isValid reflects true', () {
        final validator = DeviceValidator(isValid: true, message: 'ok');
        expect(validator.isValid, isTrue);
      });

      test('isValid reflects false', () {
        final validator = DeviceValidator(isValid: false, message: 'fail');
        expect(validator.isValid, isFalse);
      });

      test('message preserves empty string', () {
        final validator = DeviceValidator(isValid: true, message: '');
        expect(validator.message, '');
      });

      test('message preserves whitespace', () {
        final validator = DeviceValidator(isValid: false, message: '  ');
        expect(validator.message, '  ');
      });
    });
  });
}
