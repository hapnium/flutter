import 'package:flutter_test/flutter_test.dart';
import 'package:hapnium/hapnium.dart' show HapniumException;
import 'package:smart/src/utilities/math/big_integer.dart';

void main() {
  group('BigInteger construction and conversion', () {
    test('constructs from strings, ints, and BigInts', () {
      expect(BigInteger('12345678901234567890').value,
          BigInt.parse('12345678901234567890'));
      expect(BigInteger('ff', 16).toInt(), 255);
      expect(BigInteger.fromInt(-42).value, BigInt.from(-42));
      expect(BigInteger.fromBigInt(BigInt.from(42)).toString(), '42');
    });

    test('exposes constants and numeric properties', () {
      expect(BigInteger.ZERO.value, BigInt.zero);
      expect(BigInteger.ONE.value, BigInt.one);
      expect(BigInteger.TWO.value, BigInt.two);
      expect(BigInteger.TEN.value, BigInt.from(10));
      expect(BigInteger.fromInt(-8).isNegative, isTrue);
      expect(BigInteger.fromInt(-8).isEven, isTrue);
      expect(BigInteger.fromInt(7).isOdd, isTrue);
      expect(BigInteger.fromInt(8).bitLength, 4);
    });

    test('converts to unsigned and radix strings', () {
      expect(BigInteger.fromInt(-1).toUnsigned(8).toInt(), 255);
      expect(BigInteger.fromInt(255).toRadixString(16), 'ff');
      expect(BigInteger.fromInt(255).toRadixString(), '255');
      expect(() => BigInteger.fromInt(1).toUnsigned(-1),
          throwsA(isA<HapniumException>()));
      expect(() => BigInteger.fromInt(1).toRadixString(1),
          throwsA(isA<HapniumException>()));
      expect(() => BigInteger.fromInt(1).toRadixString(37),
          throwsA(isA<HapniumException>()));
    });

    test('preserves value equality and conversion behavior', () {
      final first = BigInteger('12345678901234567890');
      final second =
          BigInteger.fromBigInt(BigInt.parse('12345678901234567890'));

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(BigInteger.fromInt(10).toDouble(), 10.0);
    });
  });

  group('BigInteger arithmetic', () {
    final a = BigInteger('12345678901234567890');
    final b = BigInteger('9876543210');

    test('supports arithmetic operators', () {
      expect((a + b).toString(), '12345678911111111100');
      expect((a - b).toString(), '12345678891358024680');
      expect((BigInteger.fromInt(123) * BigInteger.fromInt(45)).toInt(), 5535);
      expect((BigInteger.fromInt(100) ~/ BigInteger.fromInt(9)).toInt(), 11);
      expect((BigInteger.fromInt(100) % BigInteger.fromInt(9)).toInt(), 1);
      expect((-BigInteger.fromInt(5)).toInt(), -5);
      expect(BigInteger.fromInt(-5).abs().toInt(), 5);
    });

    test('supports powers, modular operations, and gcd', () {
      expect(BigInteger.fromInt(3).pow(4).toInt(), 81);
      expect(BigInteger.fromInt(3).pow(0), BigInteger.ONE);
      expect(
        BigInteger.fromInt(4)
            .modPow(BigInteger.fromInt(13), BigInteger.fromInt(497))
            .toInt(),
        445,
      );
      expect(
          BigInteger.fromInt(3).modInverse(BigInteger.fromInt(11)).toInt(), 4);
      expect(BigInteger.fromInt(54).gcd(BigInteger.fromInt(24)).toInt(), 6);
      expect(() => BigInteger.fromInt(2).pow(-1),
          throwsA(isA<HapniumException>()));
    });

    test('supports bitwise operations and comparisons', () {
      final six = BigInteger.fromInt(6);
      final three = BigInteger.fromInt(3);

      expect((six & three).toInt(), 2);
      expect((six | three).toInt(), 7);
      expect((six ^ three).toInt(), 5);
      expect((~BigInteger.fromInt(0)).toInt(), -1);
      expect((three << 2).toInt(), 12);
      expect((BigInteger.fromInt(-8) >> 1).toInt(), -4);
      expect(three < six, isTrue);
      expect(three <= BigInteger.fromInt(3), isTrue);
      expect(six > three, isTrue);
      expect(six >= BigInteger.fromInt(6), isTrue);
      expect(three.compareTo(six), lessThan(0));
      expect(six.compareTo(three), greaterThan(0));
      expect(six.compareTo(BigInteger.fromInt(6)), 0);
    });

    test('performs the supported probable-prime checks', () {
      expect(BigInteger.fromInt(-1).isProbablePrime(), isFalse);
      expect(BigInteger.ONE.isProbablePrime(), isFalse);
      expect(BigInteger.TWO.isProbablePrime(), isTrue);
      expect(BigInteger.fromInt(9).isProbablePrime(), isFalse);
      expect(BigInteger.fromInt(11).isProbablePrime(), isTrue);
    });
  });
}
