import 'dart:convert';

import 'package:secure/secure.dart';
import 'package:test/test.dart';

void main() {
  group('MessagingMetadata', () {
    group('constructor', () {
      test('creates instance with provided values', () {
        final metadata = MessagingMetadata(
          enc: 'RSA',
          sign: '12345',
          type: 'RSA',
        );

        expect(metadata.enc, equals('RSA'));
        expect(metadata.sign, equals('12345'));
        expect(metadata.type, equals('RSA'));
      });

      test('stores empty strings', () {
        final metadata = MessagingMetadata(
          enc: '',
          sign: '',
          type: '',
        );

        expect(metadata.enc, isEmpty);
        expect(metadata.sign, isEmpty);
        expect(metadata.type, isEmpty);
      });
    });

    group('fromJson', () {
      test('creates instance from valid JSON', () {
        final json = {
          'enc': 'EC',
          'sign': 'timestamp',
          'type': 'EC',
        };

        final metadata = MessagingMetadata.fromJson(json);

        expect(metadata.enc, equals('EC'));
        expect(metadata.sign, equals('timestamp'));
        expect(metadata.type, equals('EC'));
      });

      test('defaults to empty strings for missing fields', () {
        final metadata = MessagingMetadata.fromJson({});

        expect(metadata.enc, isEmpty);
        expect(metadata.sign, isEmpty);
        expect(metadata.type, isEmpty);
      });

      test('defaults to empty strings for null values', () {
        final metadata = MessagingMetadata.fromJson({
          'enc': null,
          'sign': null,
          'type': null,
        });

        expect(metadata.enc, isEmpty);
        expect(metadata.sign, isEmpty);
        expect(metadata.type, isEmpty);
      });

      test('handles extra fields', () {
        final metadata = MessagingMetadata.fromJson({
          'enc': 'RSA',
          'sign': 'sig',
          'type': 'RSA',
          'extra': 'ignored',
        });

        expect(metadata.enc, equals('RSA'));
        expect(metadata.sign, equals('sig'));
        expect(metadata.type, equals('RSA'));
      });
    });

    group('toJson', () {
      test('serializes to correct JSON', () {
        final metadata = MessagingMetadata(
          enc: 'RSA',
          sign: 'sig',
          type: 'RSA',
        );

        final json = metadata.toJson();

        expect(json, equals({
          'enc': 'RSA',
          'sign': 'sig',
          'type': 'RSA',
        }));
      });

      test('serializes empty values', () {
        final metadata = MessagingMetadata(enc: '', sign: '', type: '');

        expect(metadata.toJson(), equals({
          'enc': '',
          'sign': '',
          'type': '',
        }));
      });
    });

    group('toString / fromString', () {
      test('round-trips through base64 encoding', () {
        final original = MessagingMetadata(
          enc: 'RSA',
          sign: 'signature-data',
          type: 'RSA',
        );

        final encoded = original.toString();
        final restored = MessagingMetadata.fromString(encoded);

        expect(restored.enc, equals(original.enc));
        expect(restored.sign, equals(original.sign));
        expect(restored.type, equals(original.type));
      });

      test('toString produces base64-encoded JSON', () {
        final metadata = MessagingMetadata(
          enc: 'EC',
          sign: 'test',
          type: 'EC',
        );

        final encoded = metadata.toString();

        // Should be valid base64
        expect(() => base64Decode(encoded), returnsNormally);

        // Decoded should be valid JSON
        final decoded = json.decode(utf8.decode(base64Decode(encoded)));
        expect(decoded, isA<Map>());
      });

      test('handles special characters in values', () {
        final metadata = MessagingMetadata(
          enc: 'RSA-with-special:chars!',
          sign: 'base64+encoded/data=',
          type: 'test/type',
        );

        final restored = MessagingMetadata.fromString(metadata.toString());

        expect(restored.enc, equals(metadata.enc));
        expect(restored.sign, equals(metadata.sign));
        expect(restored.type, equals(metadata.type));
      });
    });
  });

  group('MessagingResponse', () {
    group('constructor', () {
      test('creates instance with message and metadata', () {
        final metadata = MessagingMetadata(enc: 'RSA', sign: 'sig', type: 'RSA');
        final response = MessagingResponse(
          message: 'Hello, World!',
          metadata: metadata,
        );

        expect(response.message, equals('Hello, World!'));
        expect(response.metadata.enc, equals('RSA'));
      });

      test('stores empty message', () {
        final metadata = MessagingMetadata(enc: '', sign: '', type: '');
        final response = MessagingResponse(message: '', metadata: metadata);

        expect(response.message, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes to correct JSON structure', () {
        final metadata = MessagingMetadata(enc: 'EC', sign: 'ts', type: 'EC');
        final response = MessagingResponse(
          message: 'encrypted-data',
          metadata: metadata,
        );

        final json = response.toJson();

        expect(json['message'], equals('encrypted-data'));
        expect(json['metadata'], isA<Map>());
        expect(json['metadata']['enc'], equals('EC'));
        expect(json['metadata']['sign'], equals('ts'));
        expect(json['metadata']['type'], equals('EC'));
      });
    });

    group('toString', () {
      test('produces valid JSON string', () {
        final metadata = MessagingMetadata(enc: 'RSA', sign: 'sig', type: 'RSA');
        final response = MessagingResponse(
          message: 'test-message',
          metadata: metadata,
        );

        final str = response.toString();
        final decoded = json.decode(str) as Map<String, dynamic>;

        expect(decoded['message'], equals('test-message'));
        expect(decoded['metadata'], isA<Map>());
      });
    });

    group('fromString - RSA', () {
      test('parses valid JSON string', () {
        final jsonStr = json.encode({
          'message': 'encrypted-text',
          'metadata': {
            'enc': 'RSA',
            'sign': '2024-01-01',
            'type': 'RSA',
          },
        });

        final response = MessagingResponse.fromString(jsonStr);

        expect(response.message, equals('encrypted-text'));
        expect(response.metadata.enc, equals('RSA'));
        expect(response.metadata.type, equals('RSA'));
      });

      test('handles legacy plain text (non-JSON)', () {
        final response = MessagingResponse.fromString('plain-text-message');

        expect(response.message, equals('plain-text-message'));
        expect(response.metadata.enc, equals('RSA'));
        expect(response.metadata.sign, equals('legacy'));
        expect(response.metadata.type, equals('RSA'));
      });

      test('handles empty JSON object', () {
        final response = MessagingResponse.fromString('{}');

        expect(response.message, isEmpty);
        expect(response.metadata.enc, isEmpty);
      });
    });

    group('fromString - EC', () {
      test('parses valid JSON string for EC', () {
        final jsonStr = json.encode({
          'message': 'ec-encrypted',
          'metadata': {
            'enc': 'EC',
            'sign': 'nonce',
            'type': 'EC',
          },
        });

        final response = MessagingResponse.fromString(jsonStr, type: PemStyle.EC);

        expect(response.message, equals('ec-encrypted'));
        expect(response.metadata.type, equals('EC'));
      });

      test('handles legacy plain text for EC', () {
        final response = MessagingResponse.fromString('legacy-ec', type: PemStyle.EC);

        expect(response.message, equals('legacy-ec'));
        expect(response.metadata.enc, equals('EC'));
        expect(response.metadata.sign, equals('legacy'));
        expect(response.metadata.type, equals('EC'));
      });
    });

    group('round-trip', () {
      test('toJson -> fromString preserves data', () {
        final original = MessagingResponse(
          message: 'round-trip-test',
          metadata: MessagingMetadata(enc: 'RSA', sign: 'ts', type: 'RSA'),
        );

        final restored = MessagingResponse.fromString(original.toString());

        expect(restored.message, equals(original.message));
        expect(restored.metadata.enc, equals(original.metadata.enc));
        expect(restored.metadata.sign, equals(original.metadata.sign));
        expect(restored.metadata.type, equals(original.metadata.type));
      });

      test('round-trip for EC type', () {
        final original = MessagingResponse(
          message: 'ec-round-trip',
          metadata: MessagingMetadata(enc: 'EC', sign: 'nonce', type: 'EC'),
        );

        final restored = MessagingResponse.fromString(
          original.toString(),
          type: PemStyle.EC,
        );

        expect(restored.message, equals(original.message));
        expect(restored.metadata.type, equals('EC'));
      });
    });
  });
}