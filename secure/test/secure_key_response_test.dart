import 'package:secure/secure.dart';
import 'package:test/test.dart';

void main() {
  group('SecureKeyResponse', () {
    group('constructor', () {
      test('creates instance with provided keys', () {
        final response = SecureKeyResponse(
          publicKey: 'test-public-key',
          privateKey: 'test-private-key',
        );

        expect(response.publicKey, equals('test-public-key'));
        expect(response.privateKey, equals('test-private-key'));
      });

      test('stores empty strings when provided', () {
        final response = SecureKeyResponse(
          publicKey: '',
          privateKey: '',
        );

        expect(response.publicKey, isEmpty);
        expect(response.privateKey, isEmpty);
      });

      test('stores PEM-formatted keys', () {
        const pubPem = '-----BEGIN RSA PUBLIC KEY-----\nMIIBIjANBgkqhki...\n-----END RSA PUBLIC KEY-----';
        const privPem = '-----BEGIN RSA PRIVATE KEY-----\nMIIEvgIBADANBg...\n-----END RSA PRIVATE KEY-----';

        final response = SecureKeyResponse(
          publicKey: pubPem,
          privateKey: privPem,
        );

        expect(response.publicKey, equals(pubPem));
        expect(response.privateKey, equals(privPem));
      });
    });

    group('fromJson', () {
      test('creates instance from valid JSON map', () {
        final json = {
          'public_key': 'pub-key',
          'private_key': 'priv-key',
        };

        final response = SecureKeyResponse.fromJson(json);

        expect(response.publicKey, equals('pub-key'));
        expect(response.privateKey, equals('priv-key'));
      });

      test('defaults to empty strings for missing fields', () {
        final json = <String, dynamic>{};

        final response = SecureKeyResponse.fromJson(json);

        expect(response.publicKey, isEmpty);
        expect(response.privateKey, isEmpty);
      });

      test('defaults to empty string for null values', () {
        final json = {
          'public_key': null,
          'private_key': null,
        };

        final response = SecureKeyResponse.fromJson(json);

        expect(response.publicKey, isEmpty);
        expect(response.privateKey, isEmpty);
      });

      test('handles partial JSON with only public_key', () {
        final json = {
          'public_key': 'my-pub-key',
        };

        final response = SecureKeyResponse.fromJson(json);

        expect(response.publicKey, equals('my-pub-key'));
        expect(response.privateKey, isEmpty);
      });

      test('handles partial JSON with only private_key', () {
        final json = {
          'private_key': 'my-priv-key',
        };

        final response = SecureKeyResponse.fromJson(json);

        expect(response.publicKey, isEmpty);
        expect(response.privateKey, equals('my-priv-key'));
      });

      test('handles extra fields in JSON gracefully', () {
        final json = {
          'public_key': 'pub',
          'private_key': 'priv',
          'extra_field': 'ignored',
        };

        final response = SecureKeyResponse.fromJson(json);

        expect(response.publicKey, equals('pub'));
        expect(response.privateKey, equals('priv'));
      });
    });

    group('empty', () {
      test('creates instance with both keys as empty strings', () {
        final response = SecureKeyResponse.empty();

        expect(response.publicKey, isEmpty);
        expect(response.privateKey, isEmpty);
      });

      test('empty instance is distinct from constructor with empty strings', () {
        final fromFactory = SecureKeyResponse.empty();
        final fromConstructor = SecureKeyResponse(publicKey: '', privateKey: '');

        expect(fromFactory.publicKey, equals(fromConstructor.publicKey));
        expect(fromFactory.privateKey, equals(fromConstructor.privateKey));
      });
    });

    group('toJson', () {
      test('serializes to correct JSON map', () {
        final response = SecureKeyResponse(
          publicKey: 'pub-key',
          privateKey: 'priv-key',
        );

        final json = response.toJson();

        expect(json, equals({
          'public_key': 'pub-key',
          'private_key': 'priv-key',
        }));
      });

      test('serializes empty keys', () {
        final response = SecureKeyResponse.empty();

        final json = response.toJson();

        expect(json, equals({
          'public_key': '',
          'private_key': '',
        }));
      });

      test('serializes PEM-formatted keys', () {
        const pubPem = '-----BEGIN EC PUBLIC KEY-----\nMFkwEwYHKoZ...\n-----END EC PUBLIC KEY-----';
        const privPem = '-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEI...\n-----END EC PRIVATE KEY-----';

        final response = SecureKeyResponse(
          publicKey: pubPem,
          privateKey: privPem,
        );

        final json = response.toJson();

        expect(json['public_key'], equals(pubPem));
        expect(json['private_key'], equals(privPem));
      });
    });

    group('round-trip', () {
      test('fromJson(toJson()) preserves data', () {
        final original = SecureKeyResponse(
          publicKey: 'round-trip-pub',
          privateKey: 'round-trip-priv',
        );

        final restored = SecureKeyResponse.fromJson(original.toJson());

        expect(restored.publicKey, equals(original.publicKey));
        expect(restored.privateKey, equals(original.privateKey));
      });

      test('fromJson(toJson()) on empty instance', () {
        final original = SecureKeyResponse.empty();

        final restored = SecureKeyResponse.fromJson(original.toJson());

        expect(restored.publicKey, isEmpty);
        expect(restored.privateKey, isEmpty);
      });

      test('fromJson(toJson()) with PEM keys', () {
        final original = SecureKeyResponse(
          publicKey: '-----BEGIN RSA PUBLIC KEY-----\nabc\n-----END RSA PUBLIC KEY-----',
          privateKey: '-----BEGIN RSA PRIVATE KEY-----\ndef\n-----END RSA PRIVATE KEY-----',
        );

        final restored = SecureKeyResponse.fromJson(original.toJson());

        expect(restored.publicKey, equals(original.publicKey));
        expect(restored.privateKey, equals(original.privateKey));
      });
    });
  });
}