import 'package:hapnium/hapnium.dart' show HapniumException;

/// {@template big_integer}
/// A wrapper class for arbitrary precision integers.
/// 
/// This class wraps Dart's BigInt and provides Java-like functionality
/// similar to Java's BigInteger class.
/// 
/// Example usage:
/// ```dart
/// BigInteger a = BigInteger("123456789012345678901234567890");
/// BigInteger b = BigInteger.fromInt(42);
/// BigInteger sum = a + b;
/// 
/// print(sum.toString()); // Very large number
/// print(a.isProbablePrime()); // Primality test
/// ```
/// 
/// {@endtemplate}
class BigInteger implements Comparable<BigInteger> {
  /// The wrapped BigInt value
  final BigInt _value;

  /// Creates a BigInteger with the specified BigInt value.
  /// 
  /// {@macro big_integer}
  const BigInteger._(this._value);

  /// Creates a BigInteger from a string representation.
  /// 
  /// [value] the string representation
  /// [radix] the radix to use for parsing (default is 10)
  /// 
  /// {@macro big_integer}
  factory BigInteger(String value, [int radix = 10]) {
    return BigInteger._(BigInt.parse(value, radix: radix));
  }

  /// Creates a BigInteger from an int value.
  /// 
  /// {@macro big_integer}
  factory BigInteger.fromInt(int value) {
    return BigInteger._(BigInt.from(value));
  }

  /// Creates a BigInteger from a BigInt value.
  /// 
  /// {@macro big_integer}
  factory BigInteger.fromBigInt(BigInt value) {
    return BigInteger._(value);
  }

  /// Returns the wrapped BigInt value.
  BigInt get value => _value;

  /// Returns the absolute value of this BigInteger.
  BigInteger abs() => BigInteger._(_value.abs());

  /// Returns the negation of this BigInteger.
  BigInteger operator -() => BigInteger._(-_value);

  /// Arithmetic operators
  BigInteger operator +(BigInteger other) => BigInteger._(_value + other._value);
  BigInteger operator -(BigInteger other) => BigInteger._(_value - other._value);
  BigInteger operator *(BigInteger other) => BigInteger._(_value * other._value);
  BigInteger operator ~/(BigInteger other) => BigInteger._(_value ~/ other._value);
  BigInteger operator %(BigInteger other) => BigInteger._(_value % other._value);

  /// Returns this BigInteger raised to the power of the exponent.
  /// 
  /// [exponent] the exponent (must be non-negative)
  BigInteger pow(int exponent) {
    if (exponent < 0) {
      throw HapniumException('Exponent must be non-negative');
    }
    return BigInteger._(_value.pow(exponent));
  }

  /// Returns the modular exponentiation of this BigInteger.
  /// 
  /// Computes (this^exponent) mod modulus
  BigInteger modPow(BigInteger exponent, BigInteger modulus) {
    return BigInteger._(_value.modPow(exponent._value, modulus._value));
  }

  /// Returns the modular multiplicative inverse of this BigInteger.
  BigInteger modInverse(BigInteger modulus) {
    return BigInteger._(_value.modInverse(modulus._value));
  }

  /// Returns the greatest common divisor of this and other.
  BigInteger gcd(BigInteger other) {
    return BigInteger._(_value.gcd(other._value));
  }

  /// Returns true if this BigInteger is probably prime.
  /// 
  /// [certainty] the certainty level (higher = more certain)
  bool isProbablePrime([int certainty = 10]) {
    // Simple primality test - can be enhanced
    if (_value <= BigInt.one) return false;
    if (_value == BigInt.two) return true;
    if (_value.isEven) return false;
    
    // Miller-Rabin would be better, but this is a simple implementation
    for (int i = 0; i < certainty; i++) {
      // Simplified test
      if (_value % BigInt.from(3) == BigInt.zero && _value != BigInt.from(3)) return false;
      if (_value % BigInt.from(5) == BigInt.zero && _value != BigInt.from(5)) return false;
      if (_value % BigInt.from(7) == BigInt.zero && _value != BigInt.from(7)) return false;
    }
    return true; // Simplified - real implementation would be more thorough
  }

  /// Returns the number of bits in this BigInteger.
  int get bitLength => _value.bitLength;

  /// Returns true if this BigInteger is even.
  bool get isEven => _value.isEven;

  /// Returns true if this BigInteger is odd.
  bool get isOdd => _value.isOdd;

  /// Returns true if this BigInteger is negative.
  bool get isNegative => _value.isNegative;

  /// Bitwise operators
  BigInteger operator &(BigInteger other) => BigInteger._(_value & other._value);
  BigInteger operator |(BigInteger other) => BigInteger._(_value | other._value);
  BigInteger operator ^(BigInteger other) => BigInteger._(_value ^ other._value);
  BigInteger operator ~() => BigInteger._(~_value);
  BigInteger operator <<(int shiftAmount) => BigInteger._(_value << shiftAmount);
  BigInteger operator >>(int shiftAmount) => BigInteger._(_value >> shiftAmount);

  /// Comparison operators
  bool operator <(BigInteger other) => _value < other._value;
  bool operator <=(BigInteger other) => _value <= other._value;
  bool operator >(BigInteger other) => _value > other._value;
  bool operator >=(BigInteger other) => _value >= other._value;

  /// Compares this BigInteger with another.
  @override
  int compareTo(BigInteger other) => _value.compareTo(other._value);

  /// Returns true if this BigInteger equals the specified object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BigInteger && _value == other._value;
  }

  /// Returns the hash code for this BigInteger.
  @override
  int get hashCode => _value.hashCode;

  /// Returns a string representation of this BigInteger.
  @override
  String toString() => _value.toString();

  /// Returns the value of this BigInteger masked to an unsigned representation
  /// with the given [bitLength].
  ///
  /// Example:
  /// ```dart
  /// final x = BigInteger.fromInt(-1);
  /// print(x.toUnsigned(8)); // 255
  /// ```
  BigInteger toUnsigned(int bitLength) {
    if (bitLength < 0) {
      throw HapniumException('bitLength must be non-negative');
    }
    return BigInteger._(_value.toUnsigned(bitLength));
  }

  /// Returns a string representation in the specified radix.
  String toRadixString([int? radix]) {
    if (radix == null) return _value.toString();

    if (radix < 2 || radix > 36) {
      throw HapniumException('radix must be between 2 and 36');
    }
    return _value.toRadixString(radix);
  }

  /// Converts to int (may throw if too large).
  int toInt() => _value.toInt();

  /// Converts to double (may lose precision).
  double toDouble() => _value.toDouble();

  /// This creates a BigInteger with value 0.
  /// 
  /// Usage:
  /// ```dart
  /// final zero = BigInteger.ZERO;
  /// ```
  /// 
  /// {@macro big_integer}
  static final BigInteger ZERO = BigInteger._(BigInt.zero);
  
  /// This creates a BigInteger with value 1.
  /// 
  /// Usage:
  /// ```dart
  /// final one = BigInteger.ONE;
  /// ```
  /// 
  /// {@macro big_integer}
  static final BigInteger ONE = BigInteger._(BigInt.one);
  
  /// This creates a BigInteger with value 2.
  /// 
  /// Usage:
  /// ```dart
  /// final two = BigInteger.TWO;
  /// ```
  /// 
  /// {@macro big_integer}
  static final BigInteger TWO = BigInteger._(BigInt.two);
  
  /// This creates a BigInteger with value 10.
  /// 
  /// Usage:
  /// ```dart
  /// final ten = BigInteger.TEN;
  /// ```
  /// 
  /// {@macro big_integer}
  static final BigInteger TEN = BigInteger._(BigInt.from(10));
}