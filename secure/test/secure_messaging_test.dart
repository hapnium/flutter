import 'package:secure/secure.dart';
import 'package:test/test.dart';

void main() {
  group('ECSecureMessaging', () {
    late SecureMessaging ec;

    setUp(() {
      ec = SecureMessaging.ec();
    });

    group('generate', () {
      test('returns a SecureKeyResponse with non-empty keys', () {
        final keys = ec.generate();

        expect(keys.publicKey, isNotEmpty);
        expect(keys.privateKey, isNotEmpty);
      });

      test('public key starts with EC PEM header', () {
        final keys = ec.generate();

        expect(keys.publicKey, startsWith('-----BEGIN EC PUBLIC KEY-----'));
      });

      test('private key starts with EC PEM header', () {
        final keys = ec.generate();

        expect(keys.privateKey, startsWith('-----BEGIN EC PRIVATE KEY-----'));
      });

      test('generates unique key pairs on each call', () {
        final keys1 = ec.generate();
        final keys2 = ec.generate();

        expect(keys1.publicKey, isNot(equals(keys2.publicKey)));
        expect(keys1.privateKey, isNot(equals(keys2.privateKey)));
      });

      test('keys are valid PEM format', () {
        final keys = ec.generate();

        expect(keys.publicKey, contains('-----END EC PUBLIC KEY-----'));
        expect(keys.privateKey, contains('-----END EC PRIVATE KEY-----'));
      });
    });

    group('encrypt', () {
      test('returns a non-empty base64-encoded string', () {
        final keys = ec.generate();
        final encrypted = ec.encrypt(
          message: 'Hello, World!',
          publicKey: keys.publicKey,
        );

        expect(encrypted, isNotEmpty);
      });

      test('encrypted output differs from plaintext', () {
        final keys = ec.generate();
        final encrypted = ec.encrypt(
          message: 'Hello, World!',
          publicKey: keys.publicKey,
        );

        expect(encrypted, isNot(equals('Hello, World!')));
      });

      test('encrypts different messages to different ciphertexts', () {
        final keys = ec.generate();
        final enc1 = ec.encrypt(message: 'Message 1', publicKey: keys.publicKey);
        final enc2 = ec.encrypt(message: 'Message 2', publicKey: keys.publicKey);

        expect(enc1, isNot(equals(enc2)));
      });

      test('encrypts same message to different ciphertexts (randomized)', () {
        final keys = ec.generate();
        final enc1 = ec.encrypt(message: 'Same message', publicKey: keys.publicKey);
        final enc2 = ec.encrypt(message: 'Same message', publicKey: keys.publicKey);

        // Due to random nonce, same plaintext produces different ciphertexts
        expect(enc1, isNot(equals(enc2)));
      });

      test('delegates to RSA when public key is RSA', () {
        final rsaKeys = SecureMessaging.rsa().generate();

        // EC encrypt with RSA key should delegate to RSA
        final encrypted = ec.encrypt(
          message: 'RSA fallback',
          publicKey: rsaKeys.publicKey,
        );

        expect(encrypted, isNotEmpty);
      });
    });

    group('decrypt', () {
      test('correctly decrypts an encrypted message', () {
        final keys = ec.generate();
        final plaintext = 'Hello, EC World!';

        final encrypted = ec.encrypt(
          message: plaintext,
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(plaintext));
      });

      test('decrypted metadata has type EC', () {
        final keys = ec.generate();

        final encrypted = ec.encrypt(
          message: 'test',
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.metadata.type, equals('EC'));
        expect(decrypted.metadata.enc, equals('EC'));
      });

      test('decrypted metadata has timestamp in sign field', () {
        final keys = ec.generate();

        final encrypted = ec.encrypt(
          message: 'test',
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        // sign field should be a timestamp string (non-empty)
        expect(decrypted.metadata.sign, isNotEmpty);
      });

      test('round-trip with empty message', () {
        final keys = ec.generate();

        final encrypted = ec.encrypt(
          message: '',
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(''));
      });

      test('round-trip with long message', () {
        final keys = ec.generate();
        final longMessage = 'A' * 1000;

        final encrypted = ec.encrypt(
          message: longMessage,
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(longMessage));
      });

      test('round-trip with special characters', () {
        final keys = ec.generate();
        final special = 'Hello!@#\$%^&*()_+-={}[]|\\:";\'<>?,./~`';

        final encrypted = ec.encrypt(
          message: special,
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(special));
      });

      test('round-trip with unicode characters', () {
        final keys = ec.generate();
        final unicode = 'Hello \u4e16\u754c \u{1F600} \u00e9\u00e8\u00ea';

        final encrypted = ec.encrypt(
          message: unicode,
          publicKey: keys.publicKey,
        );

        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(unicode));
      });

      test('throws SecureException when decrypting with wrong key', () {
        final keys1 = ec.generate();
        final keys2 = ec.generate();

        final encrypted = ec.encrypt(
          message: 'secret',
          publicKey: keys1.publicKey,
        );

        expect(
          () => ec.decrypt(message: encrypted, privateKey: keys2.privateKey),
          throwsA(isA<SecureException>()),
        );
      });

      test('delegates to RSA when private key is RSA', () {
        final rsaKeys = SecureMessaging.rsa().generate();

        final encrypted = SecureMessaging.rsa().encrypt(
          message: 'RSA message',
          publicKey: rsaKeys.publicKey,
        );

        // EC decrypt with RSA key should delegate to RSA
        final decrypted = ec.decrypt(
          message: encrypted,
          privateKey: rsaKeys.privateKey,
        );

        expect(decrypted.message, equals('RSA message'));
      });
    });
  });

  group('RSASecureMessaging', () {
    late SecureMessaging rsa;

    setUp(() {
      rsa = SecureMessaging.rsa();
    });

    group('generate', () {
      test('returns a SecureKeyResponse with non-empty keys', () {
        final keys = rsa.generate();

        expect(keys.publicKey, isNotEmpty);
        expect(keys.privateKey, isNotEmpty);
      });

      test('public key starts with RSA PEM header', () {
        final keys = rsa.generate();

        expect(keys.publicKey, startsWith('-----BEGIN RSA PUBLIC KEY-----'));
      });

      test('private key starts with RSA PEM header', () {
        final keys = rsa.generate();

        expect(keys.privateKey, startsWith('-----BEGIN RSA PRIVATE KEY-----'));
      });

      test('generates unique key pairs on each call', () {
        final keys1 = rsa.generate();
        final keys2 = rsa.generate();

        expect(keys1.publicKey, isNot(equals(keys2.publicKey)));
        expect(keys1.privateKey, isNot(equals(keys2.privateKey)));
      });

      test('keys are valid PEM format', () {
        final keys = rsa.generate();

        expect(keys.publicKey, contains('-----END RSA PUBLIC KEY-----'));
        expect(keys.privateKey, contains('-----END RSA PRIVATE KEY-----'));
      });
    });

    group('encrypt', () {
      test('returns a non-empty base64-encoded string', () {
        final keys = rsa.generate();
        final encrypted = rsa.encrypt(
          message: 'Hello, World!',
          publicKey: keys.publicKey,
        );

        expect(encrypted, isNotEmpty);
      });

      test('encrypted output differs from plaintext', () {
        final keys = rsa.generate();
        final encrypted = rsa.encrypt(
          message: 'Hello, World!',
          publicKey: keys.publicKey,
        );

        expect(encrypted, isNot(equals('Hello, World!')));
      });

      test('encrypts different messages to different ciphertexts', () {
        final keys = rsa.generate();
        final enc1 = rsa.encrypt(message: 'Message 1', publicKey: keys.publicKey);
        final enc2 = rsa.encrypt(message: 'Message 2', publicKey: keys.publicKey);

        expect(enc1, isNot(equals(enc2)));
      });

      test('delegates to EC when public key is EC', () {
        final ecKeys = SecureMessaging.ec().generate();

        final encrypted = rsa.encrypt(
          message: 'EC fallback',
          publicKey: ecKeys.publicKey,
        );

        expect(encrypted, isNotEmpty);
      });
    });

    group('decrypt', () {
      test('correctly decrypts an encrypted message', () {
        final keys = rsa.generate();
        final plaintext = 'Hello, RSA World!';

        final encrypted = rsa.encrypt(
          message: plaintext,
          publicKey: keys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(plaintext));
      });

      test('decrypted metadata has type RSA', () {
        final keys = rsa.generate();

        final encrypted = rsa.encrypt(
          message: 'test',
          publicKey: keys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.metadata.type, equals('RSA'));
        expect(decrypted.metadata.enc, equals('RSA'));
      });

      test('decrypted metadata has timestamp in sign field', () {
        final keys = rsa.generate();

        final encrypted = rsa.encrypt(
          message: 'test',
          publicKey: keys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.metadata.sign, isNotEmpty);
      });

      test('round-trip with empty message', () {
        final keys = rsa.generate();

        final encrypted = rsa.encrypt(
          message: '',
          publicKey: keys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(''));
      });

      test('round-trip with long message', () {
        final keys = rsa.generate();
        final longMessage = 'B' * 100;

        final encrypted = rsa.encrypt(
          message: longMessage,
          publicKey: keys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(longMessage));
      });

      test('round-trip with special characters', () {
        final keys = rsa.generate();
        final special = 'Test!@#\$%^&*()';

        final encrypted = rsa.encrypt(
          message: special,
          publicKey: keys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: keys.privateKey,
        );

        expect(decrypted.message, equals(special));
      });

      test('throws SecureException when decrypting with wrong key', () {
        final keys1 = rsa.generate();
        final keys2 = rsa.generate();

        final encrypted = rsa.encrypt(
          message: 'secret',
          publicKey: keys1.publicKey,
        );

        expect(
          () => rsa.decrypt(message: encrypted, privateKey: keys2.privateKey),
          throwsA(isA<SecureException>()),
        );
      });

      test('delegates to EC when private key is EC', () {
        final ecKeys = SecureMessaging.ec().generate();

        final encrypted = SecureMessaging.ec().encrypt(
          message: 'EC message',
          publicKey: ecKeys.publicKey,
        );

        final decrypted = rsa.decrypt(
          message: encrypted,
          privateKey: ecKeys.privateKey,
        );

        expect(decrypted.message, equals('EC message'));
      });
    });
  });

  group('SecureMessaging factory', () {
    test('SecureMessaging.ec() returns ECSecureMessaging', () {
      final messaging = SecureMessaging.ec();
      expect(messaging.runtimeType.toString(), equals('ECSecureMessaging'));
    });

    test('SecureMessaging.rsa() returns RSASecureMessaging', () {
      final messaging = SecureMessaging.rsa();
      expect(messaging.runtimeType.toString(), equals('RSASecureMessaging'));
    });

    test('cross-algorithm: EC encrypt -> RSA decrypt via delegation', () {
      final ec = SecureMessaging.ec();
      final rsa = SecureMessaging.rsa();

      final rsaKeys = rsa.generate();

      // EC encrypt with RSA key delegates to RSA
      final encrypted = ec.encrypt(
        message: 'cross-test',
        publicKey: rsaKeys.publicKey,
      );

      final decrypted = rsa.decrypt(
        message: encrypted,
        privateKey: rsaKeys.privateKey,
      );

      expect(decrypted.message, equals('cross-test'));
    });
  });
}