import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('NumExtensions', () {
    test('equals, notEquals', () {
      expect(5.equals(5), isTrue);
      expect(5.notEquals(4), isTrue);
    });

    test('equalsAny & equalsAll', () {
      expect(3.equalsAny([1, 2, 3]), isTrue);
      expect(3.equalsAll([3, 3]), isTrue);
      expect(3.equalsAll([3, 2]), isFalse);
    });

    test('notEqualsAny & notEqualsAll', () {
      expect(3.notEqualsAny([1, 2]), isTrue);
      expect(3.notEqualsAny([1, 3]), isFalse);
      expect(3.notEqualsAll([1, 2]), isTrue);
      expect(3.notEqualsAll([3, 3]), isFalse);
    });

    test('length', () {
      expect(123.length, equals(3));
      expect(123.45.length, equals(5));
    });

    test('comparisons: isLt, isGt, isLtOrEt, isGtOrEt', () {
      expect(4.isLt(5), isTrue);
      expect(6.isGt(5), isTrue);
      expect(5.isLtOrEt(5), isTrue);
      expect(5.isGtOrEt(5), isTrue);
    });

    test('length comparisons', () {
      expect(123.length, equals(3));
      expect(123.isLengthGt(2), isTrue);
      expect(123.isLengthGtOrEt(3), isTrue);
      expect(123.isLengthLt(4), isTrue);
      expect(123.isLengthLtOrEt(3), isTrue);
      expect(123.isLengthEt(3), isTrue);
      expect(123.isLengthBetween(2, 4), isTrue);
    });

    test('math ops: divide, multiply, plus, minus, remainder, iq, negated', () {
      expect(10.divideBy(2), equals(5));
      expect(3.multiplyBy(4), equals(12));
      expect(3.plus(2), equals(5));
      expect(5.minus(3), equals(2));
      expect(10.remainder(3), equals(1));
      expect(10.iq(3), equals(3));
      expect(5.negated(), equals(-5));
    });

    test('toDigits pads correctly', () {
      expect(7.toDigits(3), equals('007'));
      expect(123.toDigits(5), equals('00123'));
    });

    test('toDigits throws if digits <= 0', () {
      expect(() => 123.toDigits(0), throwsA(isA<HapniumException>())); // Optional based on your implementation
    });

    test('prettyFormat works correctly', () {
      expect(500.prettyFormat, equals('500'));
      expect(3300.prettyFormat, equals('3.3k'));
      expect(2300000.prettyFormat, equals('2.3M'));
      expect(1200000000.prettyFormat, equals('1.2B'));
    });
  });
}