import 'package:flutter_test/flutter_test.dart';
import 'package:hapnium/hapnium.dart' show HapniumException;
import 'package:smart/src/utilities/math/uuid.dart';
import 'package:smart/src/utilities/math/uuid_range_builder.dart';

void main() {
  group('Uuid parsing and representation', () {
    const canonical = '550e8400-e29b-41d4-a716-446655440000';
    const compact = '550e8400e29b41d4a716446655440000';

    test('parses canonical and compact strings case-insensitively', () {
      final fromCanonical = Uuid.fromString(canonical);
      final fromCompact = Uuid.fromString(compact.toUpperCase());

      expect(fromCanonical, fromCompact);
      expect(fromCanonical.toString(), canonical);
      expect(fromCanonical.toCompactString(), compact);
      expect(fromCanonical.version, 4);
      expect(fromCanonical.variant, 2);
    });

    test('rejects empty, incorrectly sized, and non-hex strings', () {
      expect(() => Uuid.fromString(''), throwsA(isA<HapniumException>()));
      expect(() => Uuid.fromString('abcd'), throwsA(isA<HapniumException>()));
      expect(
        () => Uuid.fromString('550e8400-e29b-41d4-a716-44665544000z'),
        throwsA(isA<HapniumException>()),
      );
    });

    test('validates canonical and compact UUID strings', () {
      expect(Uuid.isValidUuid(canonical), isTrue);
      expect(Uuid.isValidUuid(compact), isTrue);
      expect(Uuid.isValidUuid(canonical.toUpperCase()), isTrue);
      expect(Uuid.isValidUuid(''), isFalse);
      expect(Uuid.isValidUuid('not-a-uuid'), isFalse);
      expect(Uuid.isValidUuid('550e8400e29b41d4a71644665544000z'), isFalse);
    });

    test('serializes bytes in big-endian order and can be restored', () {
      final uuid = Uuid.fromString(canonical);
      final bytes = uuid.toBytes();

      expect(bytes, [
        0x55,
        0x0e,
        0x84,
        0x00,
        0xe2,
        0x9b,
        0x41,
        0xd4,
        0xa7,
        0x16,
        0x44,
        0x66,
        0x55,
        0x44,
        0x00,
        0x00
      ]);
      expect(
          Uuid.fromString(bytes
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join()),
          uuid);
    });

    test('constructs from bits and compares UUIDs', () {
      final uuid = Uuid.fromBits(0x550e8400e29b41d4, 0x2716446655440000);
      final lower = Uuid.fromString('550e8400-e29b-41d4-2716-446655440000');
      final upper = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');

      expect(uuid.toString(), lower.toString());
      expect(lower.compareTo(upper), lessThan(0));
      expect(upper.compareTo(lower), greaterThan(0));
      expect(lower.compareTo(Uuid.fromString(lower.toString())), 0);
      expect(lower, Uuid.fromString(lower.toString()));
      expect(lower.hashCode, Uuid.fromString(lower.toString()).hashCode);
      expect(lower.mostSignificantBits, isA<int>());
      expect(lower.leastSignificantBits, isA<int>());
    });
  });

  group('Uuid generation', () {
    tearDown(() {
      Uuid.setUuidRangeBuilder(const CryptoUuidRangeBuilder());
    });

    test('generates version 4 UUIDs with RFC variant bits', () {
      Uuid.setUuidRangeBuilder(MathUuidRangeBuilder(seed: 42));
      final uuid = Uuid.randomUuid();

      expect(uuid.version, 4);
      expect(uuid.variant, 2);
      expect(Uuid.isValidUuid(uuid.toString()), isTrue);
    });

    test('generates version 1 UUIDs with usable time fields', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final uuid = Uuid.timeBasedUuid();
      final after = DateTime.now().millisecondsSinceEpoch;
      final uuidEpoch = DateTime(1582, 10, 15).millisecondsSinceEpoch;

      expect(uuid.version, 1);
      expect(uuid.variant, 2);
      expect(
          uuid.timestamp,
          inInclusiveRange(
              (before - uuidEpoch) * 10000, (after - uuidEpoch) * 10000));
      expect(uuid.clockSequence, inInclusiveRange(0, 0x3fff));
      expect(uuid.node.toInt(), inInclusiveRange(0, 0xffffffffffff));
    });

    test('only exposes time fields for version 1 UUIDs', () {
      final uuid = Uuid.randomUuid();

      expect(() => uuid.timestamp, throwsUnsupportedError);
      expect(() => uuid.clockSequence, throwsUnsupportedError);
      expect(() => uuid.node, throwsUnsupportedError);
    });

    test('generates name-based version 5 UUIDs deterministically', () {
      final first = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
      final second =
          Uuid.nameUuidFromBytes(Uuid.NAMESPACE_DNS, 'example.com'.codeUnits);

      expect(first, second);
      expect(first.toString(), 'cfbff0d1-9375-5685-968c-48ce8b15ae17');
      expect(first.version, 5);
      expect(first.variant, 2);
      expect(
        Uuid.nameUuidFromString(Uuid.NAMESPACE_URL, 'example.com'),
        isNot(first),
      );
    });

    test('exposes the RFC namespace constants', () {
      expect(Uuid.NAMESPACE_DNS.toString(),
          '6ba7b810-9dad-11d1-80b4-00c04fd430c8');
      expect(Uuid.NAMESPACE_URL.toString(),
          '6ba7b811-9dad-11d1-80b4-00c04fd430c8');
      expect(Uuid.NAMESPACE_OID.toString(),
          '6ba7b812-9dad-11d1-80b4-00c04fd430c8');
      expect(Uuid.NAMESPACE_X500.toString(),
          '6ba7b814-9dad-11d1-80b4-00c04fd430c8');
    });
  });
}
