import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:secure/secure.dart';

import '../../../utilities/pem_delimiter.dart';
import '../../../utilities/rsa_utils.dart';
import '../../../utilities/secure_utils.dart';
import '../secure_messaging_service.dart';

/// {@template rsa_secure_messaging}
/// RSA implementation of the [SecureMessagingService].
///
/// This class provides RSA-based encryption and decryption functionalities
/// for secure messaging. It extends the [SecureMessaging] class and implements
/// the [SecureMessagingService] interface.
///
/// ### Encryption scheme
///
/// Uses RSA-OAEP (Optimal Asymmetric Encryption Padding) with:
/// - **Key size**: 2048-bit RSA modulus
/// - **Padding**: OAEP with SHA-256 (via [OAEPEncoding] wrapping [RSAEngine])
/// - **Encoding**: The message is wrapped in a [MessagingResponse] JSON
///   structure before encryption, which includes metadata (encryption type
///   and timestamp)
///
/// The encrypted output is a single base64-encoded string containing the
/// RSA-OAEP ciphertext.
///
/// ### EC fallback
///
/// If the provided public key starts with `-----BEGIN EC PUBLIC KEY-----`,
/// the operation is transparently delegated to [SecureMessaging.ec]. This
/// allows callers to use the same API for both RSA and EC keys without
/// checking the key type themselves.
///
/// ### Example usage:
/// ```dart
/// final rsa = SecureMessaging.rsa();
/// final keys = rsa.generate();
///
/// final encrypted = rsa.encrypt(
///   message: 'Hello, World!',
///   publicKey: keys.publicKey,
/// );
///
/// final response = rsa.decrypt(
///   message: encrypted,
///   privateKey: keys.privateKey,
/// );
///
/// print(response.message); // 'Hello, World!'
/// ```
/// {@endtemplate}
class RSASecureMessaging extends SecureMessaging implements SecureMessagingService {
  /// Creates an [RSASecureMessaging] instance.
  ///
  /// Calls the parent constructor with [PemStyle.RSA] to indicate
  /// RSA key formatting.
  ///
  /// {@macro rsa_secure_messaging}
  RSASecureMessaging() : super(PemStyle.RSA);

  /// Creates an RSA-OAEP encoding instance for encryption/decryption.
  ///
  /// Returns a fresh [OAEPEncoding] wrapping [RSAEngine]. OAEP provides
  /// semantic security (IND-CCA2) unlike raw RSA or PKCS#1 v1.5 padding.
  OAEPEncoding _getEncoding() => OAEPEncoding(RSAEngine());

  /// Encrypts a [message] using RSA-OAEP with the recipient's [publicKey].
  ///
  /// If [publicKey] is an EC key (starts with `-----BEGIN EC PUBLIC KEY-----`),
  /// delegates to [SecureMessaging.ec].encrypt instead.
  ///
  /// The encryption process:
  /// 1. Decodes the PEM public key into an [RSAPublicKey]
  /// 2. Wraps the message in a [MessagingResponse] with RSA metadata
  /// 3. Encrypts the JSON string with RSA-OAEP
  /// 4. Returns the ciphertext as a base64-encoded string
  ///
  /// Throws [SecureException] if encryption fails (invalid key, message
  /// too long for RSA modulus, etc.).
  @override
  String encrypt({required String message, required String publicKey}) {
    if (publicKey.startsWith(PemDelimiter.BEGIN_PUBLIC_EC_KEY)) {
      return SecureMessaging.ec().encrypt(message: message, publicKey: publicKey);
    }

    try {
      PublicKeyParameter<RSAPublicKey> params = PublicKeyParameter<RSAPublicKey>(RSAUtils.decodePublicKey(publicKey));
      OAEPEncoding encoding = _getEncoding()..init(true, params);

      MessagingResponse response = MessagingResponse(
        message: message,
        metadata: MessagingMetadata(enc: "RSA", sign: "${DateTime.timestamp()}", type: "RSA")
      );
      Uint8List encryptedBytes = encoding.process(utf8.encode(response.toString()));

      return base64Encode(encryptedBytes);
    } catch (e) {
      throw SecureException("RSA Message encryption failed: $e");
    }
  }

  /// Decrypts an RSA-OAEP encrypted [message] using the recipient's [privateKey].
  ///
  /// If [privateKey] is an EC key (starts with `-----BEGIN EC PRIVATE KEY-----`),
  /// delegates to [SecureMessaging.ec].decrypt instead.
  ///
  /// The decryption process:
  /// 1. Decodes the PEM private key into an [RSAPrivateKey]
  /// 2. Base64-decodes the ciphertext
  /// 3. Decrypts with RSA-OAEP
  /// 4. Parses the JSON into a [MessagingResponse]
  ///
  /// Returns a [MessagingResponse] with the plaintext message and metadata.
  ///
  /// Throws [SecureException] if decryption fails (wrong key, corrupted
  /// ciphertext, padding oracle, etc.).
  @override
  MessagingResponse decrypt({required String message, required String privateKey}) {
    if (privateKey.startsWith(PemDelimiter.BEGIN_PRIVATE_EC_KEY)) {
      return SecureMessaging.ec().decrypt(message: message, privateKey: privateKey);
    }

    try {
      PrivateKeyParameter<RSAPrivateKey> params = PrivateKeyParameter<RSAPrivateKey>(RSAUtils.decodePrivateKey(privateKey));
      OAEPEncoding encoding = _getEncoding()..init(false, params);

      Uint8List decryptedBytes = encoding.process(base64Decode(message));
      String source = utf8.decode(decryptedBytes);

      return MessagingResponse.fromString(source);
    } catch (e) {
      throw SecureException("RSA Message decryption failed: $e");
    }
  }

  /// Generates a new RSA key pair and returns PEM-encoded public and private keys.
  ///
  /// The key pair is generated with:
  /// - Public exponent: 65537 (standard)
  /// - Modulus size: 2048 bits
  /// - Certainty: 64 (probability of composite modulus ~2^-64)
  ///
  /// The keys are encoded to PEM format using [RSAUtils.encodePublicKey]
  /// and [RSAUtils.encodePrivateKey].
  ///
  /// Returns a [SecureKeyResponse] containing the PEM-encoded keys.
  ///
  /// Throws [SecureException] if key generation fails.
  @override
  SecureKeyResponse generate() {
    try {
      SecureRandom secureRandom = SecureUtils.create();

      RSAKeyGeneratorParameters genParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
      ParametersWithRandom<RSAKeyGeneratorParameters> params = ParametersWithRandom(genParams, secureRandom,);

      RSAKeyGenerator keyGen = RSAKeyGenerator()..init(params);
      AsymmetricKeyPair<PublicKey, PrivateKey> pair = keyGen.generateKeyPair();

      RSAPrivateKey privateKey = pair.privateKey as RSAPrivateKey;
      RSAPublicKey publicKey = pair.publicKey as RSAPublicKey;

      return SecureKeyResponse(publicKey: RSAUtils.encodePublicKey(publicKey), privateKey: RSAUtils.encodePrivateKey(privateKey));
    } catch (e) {
      throw SecureException("RSA Key pair generation failed: $e");
    }
  }
}