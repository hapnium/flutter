import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';

import '../../../exceptions/secure_exception.dart';
import '../../../models/secure_key_response.dart';
import '../../../utilities/ec_utils.dart';
import '../../messaging/implementations/secure_messaging.dart';
import '../secure_key_service.dart';
import 'secure_key.dart';

/// {@template secure_key_factory}
/// Default implementation of [SecureKeyService] that provides deterministic
/// EC key generation from a string identifier, plus EC-based encrypt/decrypt.
///
/// Unlike [SecureMessaging.generate] which produces random keys on each call,
/// [generate] derives keys **deterministically** from the [identifier] string.
/// The same identifier always produces the same key pair. This is useful for:
///
/// - Generating keys from a user ID or device ID
/// - Reproducing keys without storing them
/// - Key derivation from a shared secret
///
/// ### Key derivation process
///
/// 1. The [identifier] is UTF-8 encoded to bytes
/// 2. The bytes are expanded to 32 bytes by cycling
/// 3. Each byte is XORed with a shifted neighbor for diffusion
/// 4. The result seeds a [FortunaRandom] PRNG
/// 5. An EC key pair is generated on the secp128r1 curve
///
/// ### Encryption/decryption
///
/// Delegates to [SecureMessaging.ec] for actual encryption and decryption,
/// using the standard ECIES + AES-256-GCM scheme.
///
/// ### Example
///
/// ```dart
/// final factory = SecureKeyFactory();
/// final keys = factory.generate('user-123');
/// // Same identifier always produces the same keys
/// final keys2 = factory.generate('user-123');
/// assert(keys.publicKey == keys2.publicKey);
/// ```
/// {@endtemplate}
class SecureKeyFactory extends SecureKey implements SecureKeyService {
  /// Decrypts an EC-encrypted [message] using the recipient's [privateKey].
  ///
  /// Delegates to [SecureMessaging.ec] and returns only the plaintext
  /// message string (discarding the metadata).
  ///
  /// Throws [SecureException] if decryption fails.
  @override
  String decrypt({required String message, required String privateKey}) {
    return SecureMessaging.ec().decrypt(message: message, privateKey: privateKey).message;
  }

  /// Encrypts a [message] using the recipient's EC [publicKey].
  ///
  /// Delegates to [SecureMessaging.ec].encrypt. The returned ciphertext
  /// is a base64-encoded JSON wrapper containing the ECIES-encrypted
  /// payload, ephemeral public key, and nonce.
  ///
  /// Throws [SecureException] if encryption fails.
  @override
  String encrypt({required String message, required String publicKey}) {
    return SecureMessaging.ec().encrypt(message: message, publicKey: publicKey);
  }

  /// Generates an EC key pair deterministically from [identifier].
  ///
  /// The same [identifier] always produces the same key pair because
  /// the PRNG seed is derived deterministically from the identifier
  /// bytes. The identifier can be any string (user ID, device ID,
  /// passphrase, etc.).
  ///
  /// Returns a [SecureKeyResponse] with PEM-encoded EC public and
  /// private keys.
  ///
  /// Throws [SecureException] if key generation fails.
  @override
  SecureKeyResponse generate(String identifier) {
    try {
      final passwordBytes = utf8.encode(identifier);

      // Ensure we have at least 32 bytes by repeating or cycling
      final expandedBytes = List<int>.generate(32, (i) => passwordBytes[i % passwordBytes.length]);

      // Perform a simple transformation (XOR with shifted values)
      for (int i = 0; i < 32; i++) {
        expandedBytes[i] ^= (expandedBytes[(i + 1) % 32] << 3) & 0xFF;
      }

      final seed = Uint8List.fromList(expandedBytes);

      // Generate EC key pair
      final secureRandom = _createSecureRandom(Uint8List.fromList(seed));
      ECKeyGeneratorParameters genParams = ECKeyGeneratorParameters(ECUtils.parameters);
      ParametersWithRandom<ECKeyGeneratorParameters> params = ParametersWithRandom(genParams, secureRandom,);

      ECKeyGenerator keyGen = ECKeyGenerator()..init(params);

      AsymmetricKeyPair<PublicKey, PrivateKey> keyPair = keyGen.generateKeyPair();

      ECPrivateKey privateKey = keyPair.privateKey as ECPrivateKey;
      ECPublicKey publicKey = keyPair.publicKey as ECPublicKey;

      return SecureKeyResponse(publicKey: ECUtils.encodePublicKey(publicKey), privateKey: ECUtils.encodePrivateKey(privateKey));
    } catch (e) {
      throw SecureException("Key pair generation failed: $e");
    }
  }

  /// Creates a [FortunaRandom] PRNG seeded with the given [seed].
  ///
  /// The seed is used as a [KeyParameter] to initialize the Fortuna
  /// generator. The resulting PRNG produces cryptographically secure
  /// random bytes suitable for key generation.
  SecureRandom _createSecureRandom(Uint8List seed) {
    final secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }
}