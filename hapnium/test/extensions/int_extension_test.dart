import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('IntExtensions', () {
    test('equality and inequality', () {
      expect(5.equals(5), isTrue);
      expect(5.notEquals(4), isTrue);
    });

    test('equalsAny and equalsAll', () {
      expect(5.equalsAny([1, 2, 5]), isTrue);
      expect(5.equalsAll([5, 5]), isTrue);
      expect(5.equalsAll([5, 6]), isFalse);
    });

    test('notEqualsAny and notEqualsAll', () {
      expect(5.notEqualsAny([1, 2, 3]), isTrue);
      expect(5.notEqualsAll([1, 2, 3]), isTrue);
      expect(5.notEqualsAll([5, 5]), isFalse);
    });

    test('increment and decrement', () {
      expect(5.increment, equals(6));
      expect(5.decrement, equals(4));
    });

    test('length and listGenerator', () {
      expect(123.length, equals(3));
      expect(3.listGenerator, equals([0, 1, 2]));
    });

    test('toAudioTimer and toTimeUnit', () {
      expect(12.toTimeUnit(), equals('12'));
      expect(3.toTimeUnit(), equals('03'));
    });

    test('toFileSize returns correct units', () {
      expect(0.toFileSize, equals("0 B"));
      expect(1024.toFileSize, contains("KB"));
      expect((1024 * 1024).toFileSize, contains("MB"));
    });

    test('isOneAKind checks all digits same', () {
      expect(111.isOneAKind, isTrue);
      expect(123.isOneAKind, isFalse);
    });

    test('comparison methods', () {
      expect(3.isLessThan(4), isTrue);
      expect(5.isGreaterThan(4), isTrue);
      expect(5.isLessThanOrEqualTo(5), isTrue);
      expect(5.isGreaterThanOrEqualTo(5), isTrue);
    });

    test('length-based checks', () {
      expect(12345.isLengthGreaterThan(4), isTrue);
      expect(12345.isLengthLessThanOrEqualTo(5), isTrue);
      expect(12345.isLengthEqualTo(5), isTrue);
      expect(12345.isLengthBetween(4, 6), isTrue);
    });

    test('duration getters', () {
      expect(5.seconds.inSeconds, equals(5));
      expect(1.days.inHours, equals(24));
      expect(2.hours.inMinutes, equals(120));
      expect(3.minutes.inSeconds, equals(180));
      expect(500.milliseconds.inMilliseconds, equals(500));
      expect(250.microseconds.inMicroseconds, equals(250));
    });

    test('math operations', () {
      expect(10.divideBy(2), equals(5.0));
      expect(4.multiplyBy(2), equals(8));
      expect(3.plus(2), equals(5));
      expect(5.minus(2), equals(3));
      expect(10.remainder(3), equals(1));
      expect(10.iq(3), equals(3));
      expect(5.negated(), equals(-5));
    });

    test('mediaDuration formatting', () {
      expect(45.mediaDuration(addSpacing: false), equals('00:45'));
      expect(125.mediaDuration(), equals('02 : 05'));
      expect(4000.mediaDuration(), equals('01 : 06 : 40'));
      expect(4000.mediaDuration(addSpacing: false), equals('01:06:40'));
    });

    test('prettyFormat output', () {
      expect(500.prettyFormat, equals('500'));
      expect(3300.prettyFormat, equals('3.3k'));
      expect(2_300_000.prettyFormat, equals('2.3M'));
      expect(1_200_000_000.prettyFormat, equals('1.2B'));
    });

    test('toDigits pads correctly', () {
      expect(7.toDigits(3), equals('007'));
      expect(123.toDigits(5), equals('00123'));
      expect(1234.toDigits(2), equals('1234')); // No truncation
    });
  });
}