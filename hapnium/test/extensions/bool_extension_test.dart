import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('BoolExtensions', () {
    test('toInt returns 1 for true', () {
      expect(true.toInt(), equals(1));
    });

    test('toInt returns 0 for false', () {
      expect(false.toInt(), equals(0));
    });

    test('isFalse returns true when value is false', () {
      expect(false.isFalse, isTrue);
    });

    test('isFalse returns false when value is true', () {
      expect(true.isFalse, isFalse);
    });

    test('isTrue returns true when value is true', () {
      expect(true.isTrue, isTrue);
    });

    test('isTrue returns false when value is false', () {
      expect(false.isTrue, isFalse);
    });

    test('equals returns true for same values', () {
      expect(true.equals(true), isTrue);
      expect(false.equals(false), isTrue);
    });

    test('equals returns false for different values', () {
      expect(true.equals(false), isFalse);
      expect(false.equals(true), isFalse);
    });

    test('notEquals returns false for same values', () {
      expect(true.notEquals(true), isFalse);
      expect(false.notEquals(false), isFalse);
    });

    test('notEquals returns true for different values', () {
      expect(true.notEquals(false), isTrue);
      expect(false.notEquals(true), isTrue);
    });
  });
}
