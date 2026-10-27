import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/utilities/math/uuid_range_builder.dart';

void main() {
  group('MathUuidRangeBuilder', () {
    test('generates 16 bytes reproducibly when seeded', () {
      final first = MathUuidRangeBuilder(seed: 42).generate();
      final second = MathUuidRangeBuilder(seed: 42).generate();

      expect(first, hasLength(16));
      expect(first, second);
      expect(first.every((byte) => byte >= 0 && byte <= 255), isTrue);
    });

    test('generates a valid-length byte array without a seed', () {
      expect(MathUuidRangeBuilder().generate(), hasLength(16));
    });
  });

  group('CryptoUuidRangeBuilder', () {
    test('generates 16 bytes in the byte range', () {
      final bytes = const CryptoUuidRangeBuilder().generate();

      expect(bytes, hasLength(16));
      expect(bytes.every((byte) => byte >= 0 && byte <= 255), isTrue);
    });
  });
}
