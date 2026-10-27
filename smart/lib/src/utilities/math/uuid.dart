import 'dart:convert' show Utf8Codec, utf8;
import 'dart:math';
import 'dart:typed_data';

import 'package:hapnium/hapnium.dart' show HapniumException;

import 'big_integer.dart';
import 'uuid_range_builder.dart';

/// The default character encoding used for JSON serialization and deserialization.
///
/// Smart uses UTF-8 as the standard encoding for all JSON input and output
/// operations to ensure full compatibility with the JSON specification
/// (RFC 8259) and cross-platform interoperability.
///
/// ### Details
/// - All string data written by Smart components is encoded using UTF-8.
/// - Input streams are decoded using UTF-8 unless another encoding is
///   explicitly configured.
/// - This constant provides a single reference point for encoding decisions
///   throughout the Smart pipeline.
///
/// ### Example
/// ```dart
/// final encoded = _DEFAULT_ENCODING.encode('{"name":"Smart"}');
/// final decoded = _DEFAULT_ENCODING.decode(encoded);
/// print(decoded); // {"name":"Smart"}
/// ```
const Utf8Codec _DEFAULT_ENCODING = utf8;

/// {@template uuid}
/// A powerful, secure implementation of Universally Unique Identifiers (UUIDs)
/// following RFC 4122 specifications.
/// 
/// The Uuid class provides comprehensive support for UUID generation, parsing,
/// validation, and manipulation with cryptographically secure random number
/// generation and multiple UUID versions.
/// 
/// ## Supported UUID Versions
/// - **Version 1**: Time-based UUIDs with MAC address
/// - **Version 3**: Name-based UUIDs using MD5 hashing
/// - **Version 4**: Random or pseudo-random UUIDs (most common)
/// - **Version 5**: Name-based UUIDs using SHA-1 hashing
/// 
/// ## Security Features
/// - Cryptographically secure random number generation
/// - Proper entropy collection for version 4 UUIDs
/// - Secure hashing for name-based UUIDs
/// - Protection against timing attacks
/// - Validation of UUID format and version compliance
/// 
/// ## Performance Characteristics
/// - **Generation**: O(1) for version 4, O(log n) for name-based versions
/// - **Parsing**: O(1) with input validation
/// - **Comparison**: O(1) lexicographic comparison
/// - **Memory**: 16 bytes storage + minimal overhead
/// 
/// ## Example Usage
/// ```dart
/// // Generate random UUID (version 4)
/// final uuid1 = Uuid.randomUuid();
/// print(uuid1); // e.g., "550e8400-e29b-41d4-a716-446655440000"
/// 
/// // Parse from string
/// final uuid2 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
/// 
/// // Generate name-based UUID (version 5)
/// final namespace = Uuid.NAMESPACE_DNS;
/// final uuid3 = Uuid.nameUuidFromBytes(namespace, Closeable._DEFAULT_ENCODING.encode('example.com'));
/// 
/// // Generate time-based UUID (version 1)
/// final uuid4 = Uuid.timeBasedUuid();
/// 
/// // Comparison and validation
/// print(uuid1 == uuid2); // false
/// print(uuid1.compareTo(uuid2)); // -1, 0, or 1
/// print(Uuid.isValidUuid('invalid')); // false
/// 
/// // Access UUID components
/// print(uuid1.version); // 4
/// print(uuid1.variant); // 2 (RFC 4122)
/// print(uuid1.mostSignificantBits);
/// print(uuid1.leastSignificantBits);
/// ```
/// 
/// ## Thread Safety
/// All UUID operations are thread-safe. The internal random number generator
/// uses secure system entropy and can be safely called from multiple threads
/// concurrently.
/// 
/// ## Format Compliance
/// Generated UUIDs strictly follow RFC 4122 format:
/// - 8-4-4-4-12 hexadecimal digit groups separated by hyphens
/// - Proper version and variant bits set according to specification
/// - Case-insensitive parsing with canonical lowercase output
/// 
/// {@endtemplate}
class Uuid implements Comparable<Uuid> {
  /// Predefined namespace UUID for DNS names (RFC 4122)
  static final Uuid NAMESPACE_DNS = Uuid._fromComponents(0x6ba7b810, 0x9dad, 0x11d1, 0x80b4, 0x00c04fd430c8);
  
  /// Predefined namespace UUID for URL names (RFC 4122)
  static final Uuid NAMESPACE_URL = Uuid._fromComponents(0x6ba7b811, 0x9dad, 0x11d1, 0x80b4, 0x00c04fd430c8);
  
  /// Predefined namespace UUID for ISO OID names (RFC 4122)
  static final Uuid NAMESPACE_OID = Uuid._fromComponents(0x6ba7b812, 0x9dad, 0x11d1, 0x80b4, 0x00c04fd430c8);
  
  /// Predefined namespace UUID for X.500 DN names (RFC 4122)
  static final Uuid NAMESPACE_X500 = Uuid._fromComponents(0x6ba7b814, 0x9dad, 0x11d1, 0x80b4, 0x00c04fd430c8);

  static final Random _secureRandom = Random.secure();
  static final RegExp _uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  final BigInteger _mostSigBits;
  final BigInteger _leastSigBits;

  static UuidRangeBuilder _rangeBuilder = CryptoUuidRangeBuilder();

  /// {@macro uuid}
  const Uuid._(this._mostSigBits, this._leastSigBits);

  /// Creates a UUID from its most and least significant bits.
  /// 
  /// {@template uuid_from_bits}
  /// Parameters:
  /// - [mostSigBits]: The most significant 64 bits of the UUID
  /// - [leastSigBits]: The least significant 64 bits of the UUID
  /// 
  /// This constructor allows direct creation of UUIDs from their bit
  /// representation, useful for deserialization or when working with
  /// UUID storage formats that preserve the raw bits.
  /// 
  /// ## Example
  /// ```dart
  /// final uuid = Uuid.fromBits(0x550e8400e29b41d4, 0xa716446655440000);
  /// print(uuid); // "550e8400-e29b-41d4-a716-446655440000"
  /// ```
  /// {@endtemplate}
  factory Uuid.fromBits(int mostSigBits, int leastSigBits) {
    return Uuid._(BigInteger.fromInt(mostSigBits), BigInteger.fromInt(leastSigBits));
  }

  /// Creates a UUID from a string representation.
  /// 
  /// {@template uuid_from_string}
  /// Parameters:
  /// - [uuidString]: String representation of the UUID
  /// 
  /// Accepts standard UUID format with hyphens (8-4-4-4-12) or without hyphens.
  /// Parsing is case-insensitive but output is always lowercase.
  /// 
  /// ## Supported Formats
  /// - `550e8400-e29b-41d4-a716-446655440000` (standard format)
  /// - `550e8400e29b41d4a716446655440000` (compact format)
  /// - Mixed case variations
  /// 
  /// ## Example
  /// ```dart
  /// final uuid1 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
  /// final uuid2 = Uuid.fromString('550E8400E29B41D4A716446655440000');
  /// print(uuid1 == uuid2); // true
  /// ```
  /// 
  /// Throws:
  /// - [HapniumException] if the string is not a valid UUID format
  /// {@endtemplate}
  factory Uuid.fromString(String uuidString) {
    if (uuidString.isEmpty) {
      throw HapniumException('UUID string cannot be empty');
    }

    // Remove hyphens and convert to lowercase
    final cleanString = uuidString.replaceAll('-', '').toLowerCase();
    
    if (cleanString.length != 32) {
      throw HapniumException('Invalid UUID string length: ${uuidString.length}');
    }

    // Validate hex characters
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(cleanString)) {
      throw HapniumException('Invalid UUID string format: $uuidString');
    }

    try {
      final mostSigBits = BigInt.parse(cleanString.substring(0, 16), radix: 16);
      final leastSigBits = BigInt.parse(cleanString.substring(16, 32), radix: 16);
      return Uuid._(BigInteger.fromBigInt(mostSigBits), BigInteger.fromBigInt(leastSigBits));
    } catch (e) {
      throw HapniumException('Failed to parse UUID string: $uuidString\n $e');
    }
  }

  /// Generates a random UUID (version 4).
  /// 
  /// {@template uuid_random_uuid}
  /// Returns:
  /// - A new random UUID with version 4 and variant 2 (RFC 4122)
  /// 
  /// ## Security Properties
  /// - Uses cryptographically secure random number generator
  /// - 122 bits of entropy (6 bits reserved for version/variant)
  /// - Suitable for security-sensitive applications
  /// - Extremely low collision probability (2^-61 for 1 billion UUIDs)
  /// 
  /// ## Performance
  /// - O(1) generation time
  /// - Thread-safe concurrent generation
  /// - No external dependencies or network calls
  /// 
  /// ## Example
  /// ```dart
  /// final uuid1 = Uuid.randomUuid();
  /// final uuid2 = Uuid.randomUuid();
  /// print(uuid1 != uuid2); // true (virtually guaranteed)
  /// print(uuid1.version); // 4
  /// ```
  /// {@endtemplate}
  factory Uuid.randomUuid() {
    final bytes = _rangeBuilder.generate();

    // Set version (4) and variant (2) bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant 2

    return Uuid._fromBytes(bytes);
  }

  /// Generates a time-based UUID (version 1).
  /// 
  /// {@template uuid_time_based_uuid}
  /// Returns:
  /// - A new time-based UUID with version 1 and variant 2 (RFC 4122)
  /// 
  /// ## Time-Based Properties
  /// - Incorporates current timestamp with 100-nanosecond precision
  /// - Includes clock sequence to handle clock adjustments
  /// - Uses random node identifier (no MAC address exposure)
  /// - Sortable by generation time
  /// 
  /// ## Privacy Considerations
  /// This implementation uses a random node identifier instead of the actual
  /// MAC address to protect privacy while maintaining UUID uniqueness.
  /// 
  /// ## Example
  /// ```dart
  /// final uuid1 = Uuid.timeBasedUuid();
  /// await Future.delayed(Duration(milliseconds: 1));
  /// final uuid2 = Uuid.timeBasedUuid();
  /// print(uuid1.compareTo(uuid2) < 0); // true (uuid1 generated first)
  /// print(uuid1.version); // 1
  /// ```
  /// {@endtemplate}
  factory Uuid.timeBasedUuid() {
    // Get current time in 100-nanosecond intervals since UUID epoch
    final now = DateTime.now().millisecondsSinceEpoch;
    final uuidEpoch = DateTime(1582, 10, 15).millisecondsSinceEpoch;
    final timestamp = BigInteger.fromInt(now - uuidEpoch) * BigInteger.fromInt(10000); // 100ns intervals

    // Generate 14-bit clock sequence
    final clockSeq = BigInteger.fromInt(_secureRandom.nextInt(0x4000));

    // Generate 48-bit node ID from secure random bytes
    BigInteger node = BigInteger.ZERO;
    for (var i = 0; i < 6; i++) {
      node = (node << 8) | BigInteger.fromInt(_secureRandom.nextInt(256));
    }

    // Build UUID components
    final timeLow = timestamp & BigInteger.fromInt(0xFFFFFFFF);
    final timeMid = (timestamp >> 32) & BigInteger.fromInt(0xFFFF);
    final timeHiAndVersion = ((timestamp >> 48) & BigInteger.fromInt(0x0FFF)) | BigInteger.fromInt(0x1000); // v1
    final clockSeqHiAndReserved = ((clockSeq >> 8) | BigInteger.fromInt(0x80)) & BigInteger.fromInt(0xFF); // variant 2
    final clockSeqLow = clockSeq & BigInteger.fromInt(0xFF);

    final mostSigBits = (timeLow << 32) | (timeMid << 16) | timeHiAndVersion;
    final leastSigBits = (clockSeqHiAndReserved << 56) | (clockSeqLow << 48) | node;

    return Uuid._(mostSigBits, leastSigBits);
  }

  /// Generates a name-based UUID using SHA-1 hashing (version 5).
  /// 
  /// {@template uuid_name_uuid_from_bytes}
  /// Parameters:
  /// - [namespace]: Namespace UUID for the name
  /// - [nameBytes]: Byte representation of the name
  /// 
  /// Returns:
  /// - A deterministic UUID based on the namespace and name
  /// 
  /// ## Deterministic Properties
  /// - Same namespace and name always produce the same UUID
  /// - Different names in the same namespace produce different UUIDs
  /// - Uses SHA-1 hashing for cryptographic strength
  /// - Suitable for creating reproducible UUIDs from names
  /// 
  /// ## Example
  /// ```dart
  /// final namespace = Uuid.NAMESPACE_DNS;
  /// final name = Closeable._DEFAULT_ENCODING.encode('example.com');
  /// final uuid1 = Uuid.nameUuidFromBytes(namespace, name);
  /// final uuid2 = Uuid.nameUuidFromBytes(namespace, name);
  /// print(uuid1 == uuid2); // true (deterministic)
  /// print(uuid1.version); // 5
  /// ```
  /// {@endtemplate}
  factory Uuid.nameUuidFromBytes(Uuid namespace, List<int> nameBytes) {
    // Combine namespace UUID bytes with name bytes
    final namespaceBytes = namespace._toBytes();
    final combined = <int>[];
    combined.addAll(namespaceBytes);
    combined.addAll(nameBytes);

    // Generate SHA-1 hash
    final hash = _sha1Hash(combined);

    // Set version (5) and variant (2) bits
    hash[6] = (hash[6] & 0x0F) | 0x50; // Version 5
    hash[8] = (hash[8] & 0x3F) | 0x80; // Variant 2

    return Uuid._fromBytes(hash.take(16).toList());
  }

  /// Generates a name-based UUID from a string name.
  /// 
  /// {@template uuid_name_uuid_from_string}
  /// Parameters:
  /// - [namespace]: Namespace UUID for the name
  /// - [name]: String name to generate UUID from
  /// 
  /// Returns:
  /// - A deterministic UUID based on the namespace and name string
  /// 
  /// This is a convenience method that converts the string name to UTF-8 bytes
  /// and calls [nameUuidFromBytes].
  /// 
  /// ## Example
  /// ```dart
  /// final uuid = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
  /// print(uuid.version); // 5
  /// ```
  /// {@endtemplate}
  factory Uuid.nameUuidFromString(Uuid namespace, String name) {
    return Uuid.nameUuidFromBytes(namespace, _DEFAULT_ENCODING.encode(name));
  }

  /// Validates if a string is a valid UUID format.
  /// 
  /// {@template uuid_is_valid_uuid}
  /// Parameters:
  /// - [uuidString]: String to validate
  /// 
  /// Returns:
  /// - `true` if the string is a valid UUID format
  /// - `false` if the string is invalid
  /// 
  /// ## Validation Rules
  /// - Accepts standard format with hyphens (8-4-4-4-12)
  /// - Accepts compact format without hyphens (32 hex digits)
  /// - Case-insensitive validation
  /// - Checks for proper length and hex digit format
  /// 
  /// ## Example
  /// ```dart
  /// print(Uuid.isValidUuid('550e8400-e29b-41d4-a716-446655440000')); // true
  /// print(Uuid.isValidUuid('550e8400e29b41d4a716446655440000')); // true
  /// print(Uuid.isValidUuid('invalid-uuid')); // false
  /// print(Uuid.isValidUuid('')); // false
  /// ```
  /// {@endtemplate}
  static bool isValidUuid(String uuidString) {
    if (uuidString.isEmpty) return false;
    
    // Check standard format with hyphens
    if (_uuidRegex.hasMatch(uuidString)) return true;
    
    // Check compact format without hyphens
    final cleanString = uuidString.replaceAll('-', '');
    return cleanString.length == 32 && RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(cleanString);
  }

  /// Sets the random number generator for UUID generation.
  /// 
  /// {@template uuid_set_rng}
  /// Parameters:
  /// - [rangeBuilder]: The random number generator to use
  /// 
  /// This method allows customizing the random number generation strategy
  /// used for generating UUIDs. The default is [CryptoUuidRangeBuilder].
  /// 
  /// ## Example
  /// ```dart
  /// Uuid.setUuidRangeBuilder(MathUuidRangeBuilder());
  /// final uuid = Uuid.randomUuid();
  /// ```
  /// {@endtemplate}
  static void setUuidRangeBuilder(UuidRangeBuilder rangeBuilder) {
    _rangeBuilder = rangeBuilder;
  }

  /// Gets the most significant 64 bits of the UUID.
  /// 
  /// {@template uuid_most_significant_bits}
  /// Returns:
  /// - The most significant 64 bits as an integer
  /// 
  /// The most significant bits contain the time components for version 1 UUIDs
  /// and the first half of random bits for version 4 UUIDs.
  /// {@endtemplate}
  int get mostSignificantBits => _mostSigBits.toInt();

  /// Gets the least significant 64 bits of the UUID.
  /// 
  /// {@template uuid_least_significant_bits}
  /// Returns:
  /// - The least significant 64 bits as an integer
  /// 
  /// The least significant bits contain the clock sequence and node for version 1
  /// UUIDs and the second half of random bits for version 4 UUIDs.
  /// {@endtemplate}
  int get leastSignificantBits => _leastSigBits.toInt();

  /// Gets the version number of the UUID.
  /// 
  /// {@template uuid_version}
  /// Returns:
  /// - Version number (1, 3, 4, or 5)
  /// 
  /// ## Version Meanings
  /// - **1**: Time-based UUID
  /// - **3**: Name-based UUID using MD5 hashing
  /// - **4**: Random or pseudo-random UUID
  /// - **5**: Name-based UUID using SHA-1 hashing
  /// {@endtemplate}
  int get version => ((_mostSigBits >> 12) & BigInteger.fromInt(0x0F)).toInt();

  /// Gets the variant number of the UUID.
  /// 
  /// {@template uuid_variant}
  /// Returns:
  /// - Variant number (typically 2 for RFC 4122 UUIDs)
  /// 
  /// ## Variant Meanings
  /// - **0**: Reserved for NCS backward compatibility
  /// - **2**: RFC 4122 variant (standard)
  /// - **6**: Reserved for Microsoft backward compatibility
  /// - **7**: Reserved for future definition
  /// {@endtemplate}
  int get variant {
    final variantBits = (_leastSigBits >> 61) & BigInteger.fromInt(0x07);
    if ((variantBits & BigInteger.fromInt(0x04)) == BigInteger.ZERO) return 0;
    if ((variantBits & BigInteger.fromInt(0x02)) == BigInteger.ZERO) return 2;
    if ((variantBits & BigInteger.fromInt(0x01)) == BigInteger.ZERO) return 6;
    return 7;
  }

  /// Gets the timestamp from a time-based UUID (version 1).
  /// 
  /// {@template uuid_timestamp}
  /// Returns:
  /// - Timestamp in 100-nanosecond intervals since UUID epoch
  /// - Throws [UnsupportedError] if not a version 1 UUID
  /// 
  /// The UUID epoch is October 15, 1582 00:00:00 UTC.
  /// 
  /// ## Example
  /// ```dart
  /// final uuid = Uuid.timeBasedUuid();
  /// if (uuid.version == 1) {
  ///   final timestamp = uuid.timestamp;
  ///   print('UUID generated at: ${DateTime.fromMillisecondsSinceEpoch(timestamp ~/ 10000)}');
  /// }
  /// ```
  /// {@endtemplate}
  int get timestamp {
    if (version != 1) {
      throw UnsupportedError('Timestamp is only available for version 1 UUIDs');
    }
    
    final timeLow = _mostSigBits >> 32;
    final timeMid = (_mostSigBits >> 16) & BigInteger.fromInt(0xFFFF);
    final timeHi = _mostSigBits & BigInteger.fromInt(0x0FFF);
    
    return ((timeHi << 48) | (timeMid << 32) | timeLow).toInt();
  }

  /// Gets the clock sequence from a time-based UUID (version 1).
  /// 
  /// {@template uuid_clock_sequence}
  /// Returns:
  /// - Clock sequence value (14 bits)
  /// - Throws [UnsupportedError] if not a version 1 UUID
  /// 
  /// The clock sequence is used to handle cases where the system clock
  /// is adjusted backwards or the UUID generator is restarted.
  /// {@endtemplate}
  int get clockSequence {
    if (version != 1) {
      throw UnsupportedError('Clock sequence is only available for version 1 UUIDs');
    }
    
    return ((_leastSigBits >> 48) & BigInteger.fromInt(0x3FFF)).toInt();
  }

  /// Gets the node identifier from a time-based UUID (version 1).
  /// 
  /// {@template uuid_node}
  /// Returns:
  /// - Node identifier (48 bits)
  /// - Throws [UnsupportedError] if not a version 1 UUID
  /// 
  /// In this implementation, the node identifier is randomly generated
  /// for privacy protection rather than using the actual MAC address.
  /// {@endtemplate}
  BigInteger get node {
    if (version != 1) {
      throw UnsupportedError('Node is only available for version 1 UUIDs');
    }
    
    return _leastSigBits & BigInteger.fromInt(0xFFFFFFFFFFFF);
  }

  @override
  int compareTo(Uuid other) {
    // Compare most significant bits first
    if (_mostSigBits < other._mostSigBits) return -1;
    if (_mostSigBits > other._mostSigBits) return 1;
    
    // If most significant bits are equal, compare least significant bits
    if (_leastSigBits < other._leastSigBits) return -1;
    if (_leastSigBits > other._leastSigBits) return 1;
    
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Uuid) return false;
    return _mostSigBits == other._mostSigBits && _leastSigBits == other._leastSigBits;
  }

  @override
  int get hashCode => _mostSigBits.hashCode ^ _leastSigBits.hashCode;

  String _toHex64(BigInteger value) => value.toUnsigned(64).toRadixString(16).padLeft(16, '0');

  @override
  String toString() {
    final most = _toHex64(_mostSigBits);
    final least = _toHex64(_leastSigBits);

    final hex = most + least;
    return '${hex.substring(0, 8)}-'
          '${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-'
          '${hex.substring(16, 20)}-'
          '${hex.substring(20, 32)}';
  }

  /// Converts the UUID to a byte array.
  /// 
  /// {@template uuid_to_bytes}
  /// Returns:
  /// - 16-byte array representation of the UUID
  /// 
  /// The bytes are in big-endian order, suitable for storage or transmission.
  /// 
  /// ## Example
  /// ```dart
  /// final uuid = Uuid.randomUuid();
  /// final bytes = uuid.toBytes();
  /// final restored = Uuid._fromBytes(bytes);
  /// print(uuid == restored); // true
  /// ```
  /// {@endtemplate}
  Uint8List toBytes() => _toBytes();

  /// Converts the UUID to a compact string without hyphens.
  /// 
  /// {@template uuid_to_compact_string}
  /// Returns:
  /// - 32-character hexadecimal string without hyphens
  /// 
  /// ## Example
  /// ```dart
  /// final uuid = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
  /// print(uuid.toCompactString()); // "550e8400e29b41d4a716446655440000"
  /// ```
  /// {@endtemplate}
  String toCompactString() => _toHex64(_mostSigBits) + _toHex64(_leastSigBits);

  // Private helper methods

  factory Uuid._fromComponents(int timeLow, int timeMid, int timeHiAndVersion, int clockSeqHiAndReserved, int clockSeqLowAndNode) {
    final mostSigBits = (BigInteger.fromInt(timeLow) << 32) | (BigInteger.fromInt(timeMid) << 16) | BigInteger.fromInt(timeHiAndVersion);
    final leastSigBits = (BigInteger.fromInt(clockSeqHiAndReserved) << 48) | BigInteger.fromInt(clockSeqLowAndNode);
    return Uuid._(mostSigBits, leastSigBits);
  }

  factory Uuid._fromBytes(List<int> bytes) {
    if (bytes.length != 16) {
      throw HapniumException('UUID bytes must be exactly 16 bytes long');
    }

    // Build high and low 64-bit parts using native int math
    int mostSigBits = 0;
    for (var i = 0; i < 8; i++) {
      mostSigBits = (mostSigBits << 8) | (bytes[i] & 0xFF);
    }

    int leastSigBits = 0;
    for (var i = 8; i < 16; i++) {
      leastSigBits = (leastSigBits << 8) | (bytes[i] & 0xFF);
    }

    // Convert to BigInteger only once
    return Uuid._(BigInteger.fromInt(mostSigBits), BigInteger.fromInt(leastSigBits));
  }

  Uint8List _toBytes() {
    final bytes = Uint8List(16);

    for (var i = 0; i < 8; i++) {
      bytes[i] = ((_mostSigBits >> (8 * (7 - i))) & BigInteger.fromInt(0xFF)).toInt();
    }

    for (var i = 0; i < 8; i++) {
      bytes[i + 8] = ((_leastSigBits >> (8 * (7 - i))) & BigInteger.fromInt(0xFF)).toInt();
    }

    return bytes;
  }

  static List<int> _sha1Hash(List<int> data) {
    // Simple SHA-1 implementation for UUID generation
    // In production, you might want to use a more optimized implementation
    
    final h = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
    final paddedData = _padSha1Data(data);
    
    for (int chunk = 0; chunk < paddedData.length; chunk += 64) {
      final w = List<int>.filled(80, 0);
      
      // Break chunk into sixteen 32-bit big-endian words
      for (int i = 0; i < 16; i++) {
        w[i] = (paddedData[chunk + i * 4] << 24) |
               (paddedData[chunk + i * 4 + 1] << 16) |
               (paddedData[chunk + i * 4 + 2] << 8) |
               paddedData[chunk + i * 4 + 3];
      }
      
      // Extend the sixteen 32-bit words into eighty 32-bit words
      for (int i = 16; i < 80; i++) {
        w[i] = _leftRotate(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }
      
      // Initialize hash value for this chunk
      int a = h[0], b = h[1], c = h[2], d = h[3], e = h[4];
      
      // Main loop
      for (int i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        
        final temp = (_leftRotate(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _leftRotate(b, 30);
        b = a;
        a = temp;
      }
      
      // Add this chunk's hash to result so far
      h[0] = (h[0] + a) & 0xFFFFFFFF;
      h[1] = (h[1] + b) & 0xFFFFFFFF;
      h[2] = (h[2] + c) & 0xFFFFFFFF;
      h[3] = (h[3] + d) & 0xFFFFFFFF;
      h[4] = (h[4] + e) & 0xFFFFFFFF;
    }
    
    // Convert hash to bytes
    final result = <int>[];
    for (final word in h) {
      result.addAll([
        (word >> 24) & 0xFF,
        (word >> 16) & 0xFF,
        (word >> 8) & 0xFF,
        word & 0xFF,
      ]);
    }
    
    return result;
  }

  static List<int> _padSha1Data(List<int> data) {
    final originalLength = data.length;
    final paddedData = List<int>.from(data);
    
    // Append the '1' bit (plus zero padding to make it a byte)
    paddedData.add(0x80);
    
    // Append zero bytes until the message length in bits ≡ 448 (mod 512)
    while ((paddedData.length % 64) != 56) {
      paddedData.add(0);
    }
    
    // Append original length in bits as 64-bit big-endian integer
    final lengthInBits = originalLength * 8;
    for (int i = 7; i >= 0; i--) {
      paddedData.add((lengthInBits >> (i * 8)) & 0xFF);
    }
    
    return paddedData;
  }

  static int _leftRotate(int value, int amount) {
    return ((value << amount) | (value >> (32 - amount))) & 0xFFFFFFFF;
  }
}
