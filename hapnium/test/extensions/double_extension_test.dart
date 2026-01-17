import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('DoubleExtensions', () {
    test('equals and notEquals work correctly', () {
      expect(2.5.equals(2.5), isTrue);
      expect(2.5.notEquals(3.0), isTrue);
    });

    test('equalsAny and equalsAll work correctly', () {
      expect(2.5.equalsAny([1.0, 2.5, 3.0]), isTrue);
      expect(2.5.equalsAll([2.5, 2.5]), isTrue);
      expect(2.5.equalsAll([2.5, 3.0]), isFalse);
    });

    test('notEqualsAny and notEqualsAll work correctly', () {
      expect(2.5.notEqualsAny([3.0, 4.0]), isTrue);
      expect(2.5.notEqualsAll([3.0, 4.0]), isTrue);
      expect(2.5.notEqualsAll([2.5, 3.0]), isTrue);
    });

    test('length calculates correctly', () {
      expect(12.34.length, equals(4)); // "1234"
      expect(0.001.length, greaterThan(1));
    });

    test('comparison methods', () {
      expect(2.0.isLessThan(3.0), isTrue);
      expect(4.0.isGreaterThan(3.0), isTrue);
      expect(3.0.isLessThanOrEqualTo(3.0), isTrue);
      expect(3.0.isGreaterThanOrEqualTo(3.0), isTrue);
    });

    test('length comparison methods', () {
      expect(123.45.isLengthGreaterThan(4), isTrue);
      expect(123.45.isLengthLessThanOrEqualTo(5), isTrue);
      expect(123.4.isLengthEqualTo(5), isFalse);
      expect(12.3.isLengthBetween(2, 4), isTrue);
    });

    test('math operations', () {
      expect(2.5.toPrecision(1), equals(2.5));
      expect(2.555.toPrecision(2), equals(2.56));

      expect(10.0.divideBy(2), equals(5.0));
      expect(3.0.multiplyBy(2), equals(6.0));
      expect(3.0.plus(2), equals(5.0));
      expect(3.0.minus(1), equals(2.0));

      expect(10.0.remainder(4), equals(2.0));
      expect(10.0.iq(3), equals(3));
      expect(5.0.negated(), equals(-5.0));
    });

    test('toDp formats correctly', () {
      expect(3.14159.toDp(2), equals('3.14'));
      expect(3.1.toDp(3), equals('3.100'));
    });

    test('duration conversions', () {
      expect(1.5.milliseconds.inMicroseconds, equals(1500));
      expect(2.0.seconds.inMilliseconds, equals(2000));
      expect(2.0.minutes.inSeconds, equals(120));
      expect(1.0.hours.inMinutes, equals(60));
      expect(1.0.days.inHours, equals(24));
    });

    test('distance formatting', () {
      expect(500.0.distance, equals('500.00 m'));
      expect(1500.0.distance, equals('1.50 km'));
    });

    test('mediaDuration formatting', () {
      expect(45.0.mediaDuration(), equals('00 : 45'));
      expect(125.0.mediaDuration(addSpacing: false), equals('02:05'));
      expect(4000.0.mediaDuration(), equals('01 : 06 : 40'));
      expect(4000.0.mediaDuration(addSpacing: false), equals('01:06:40'));
    });
  });
}