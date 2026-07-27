import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:secure/secure.dart';

import '../../../utilities/ec_utils.dart';
import '../../../utilities/pem_delimiter.dart';
import '../../../utilities/secure_utils.dart';
import '../secure_messaging_service.dart';

/// {@template ec_secure_messaging}
/// EC (Elliptic Curve) implementation of the [SecureMessagingService].
///
/// This class provides EC-based encryption and decryption functionalities
/// for secure messaging. It extends the [SecureMessaging] class and implements
/// the [SecureMessagingService] interface.
///
/// ### Encryption scheme
///
/// Uses ECIES (Elliptic Curve Integrated Encryption Scheme) with:
/// - **Key agreement**: Ephemeral EC key pair + recipient's public key
///   via [ECUtils.getSharedSecret]
/// - **Key derivation**: HKDF with SHA-256 via [ECUtils.deriveAesKey]
/// - **Symmetric encryption**: AES-256-GCM with a 128-bit MAC tag
/// - **Nonce**: 16-byte cryptographically secure random value
///
/// The encrypted output is a JSON object (base64-encoded) containing:
/// - `message`: The AES-GCM ciphertext (base64)
/// - `metadata.enc`: The ephemeral public key (base64)
/// - `metadata.sign`: The nonce (base64)
/// - `metadata.type`: Always `"EC"`
///
/// ### RSA fallback
///
/// If the provided public key starts with `-----BEGIN RSA PUBLIC KEY-----`,
/// the operation is transparently delegated to [SecureMessaging.rsa]. This
/// allows callers to use the same API for both EC and RSA keys without
/// checking the key type themselves.
///
/// ### Example usage:
/// ```dart
/// final ec = SecureMessaging.ec();
/// final keys = ec.generate();
///
/// final encrypted = ec.encrypt(
///   message: 'Hello, World!',
///   publicKey: keys.publicKey,
/// );
///
/// final response = ec.decrypt(
///   message: encrypted,
///   privateKey: keys.privateKey,
/// );
///
/// print(response.message); // 'Hello, World!'
/// ```
/// {@endtemplate}
class ECSecureMessaging extends SecureMessaging implements SecureMessagingService {
  /// Creates an [ECSecureMessaging] instance.
  ///
  /// Calls the parent constructor with [PemStyle.EC] to indicate
  /// Elliptic Curve key formatting.
  ///
  /// {@macro ec_secure_messaging}
  ECSecureMessaging() : super(PemStyle.EC);

  /// The size of the GCM authentication tag in bits.
  ///
  /// Set to 128 bits (16 bytes) for maximum authentication strength.
  /// This is the standard recommendation for AES-GCM.
  final int macSize = 128;

  /// The additional authenticated data (AAD) for AES-GCM.
  ///
  /// An empty byte array is used because no additional data needs to be
  /// authenticated beyond the ciphertext itself. In a production system,
  /// this could include message headers or routing information that
  /// should be authenticated but not encrypted.
  final Uint8List associatedData = Uint8List(0);

  /// Creates a new AES-GCM block cipher for encryption/decryption.
  ///
  /// Returns a fresh [GCMBlockCipher] wrapping [AESEngine]. Each call
  /// creates a new instance to avoid state conflicts between concurrent
  /// operations.
  GCMBlockCipher _getCipher() => GCMBlockCipher(AESEngine());

  /// Encrypts a [message] using ECIES with the recipient's [publicKey].
  ///
  /// If [publicKey] is an RSA key (starts with `-----BEGIN RSA PUBLIC KEY-----`),
  /// delegates to [SecureMessaging.rsa].encrypt instead.
  ///
  /// The encryption process:
  /// 1. Generates an ephemeral EC key pair
  /// 2. Derives a shared secret via ECDH
  /// 3. Derives an AES-256 key via HKDF
  /// 4. Encrypts the message with AES-256-GCM
  /// 5. Packages ciphertext + ephemeral public key + nonce into a JSON response
  ///
  /// Returns a base64-encoded JSON string containing the encrypted payload.
  ///
  /// Throws [SecureException] if encryption fails for any reason.
  @override
  String encrypt({required String message, required String publicKey}) {
    if (publicKey.startsWith(PemDelimiter.BEGIN_PUBLIC_RSA_KEY)) {
      return SecureMessaging.rsa().encrypt(message: message, publicKey: publicKey);
    }

    try {
      AsymmetricKeyPair<PublicKey, PrivateKey> sharedKey = _generate();
      ECPublicKey receiverPublicKey = ECUtils.decodePublicKey(publicKey);

      // Derive AES key
      Uint8List sharedSecret = ECUtils.getSharedSecret (receiverPublicKey.Q!, (sharedKey.privateKey as ECPrivateKey).d);
      Uint8List sharedPublicKey = (sharedKey.publicKey as ECPublicKey).Q!.getEncoded(false);
      Uint8List aesKey = ECUtils.deriveAesKey(sharedPublicKey, sharedSecret);
      Uint8List nonce = SecureUtils.create().nextBytes(16);

      // Encrypt using AES-256 GCM
      AEADParameters<KeyParameter> params = AEADParameters(KeyParameter(aesKey), macSize, nonce, associatedData);
      GCMBlockCipher cipher = _getCipher()..init(true, params);
      Uint8List encryptedBytes = cipher.process(utf8.encode(message));

      MessagingResponse response = MessagingResponse(
        message: base64Encode(encryptedBytes),
        metadata: MessagingMetadata(enc: base64Encode(sharedPublicKey), sign: base64Encode(nonce), type: "EC")
      );

      return base64Encode(utf8.encode(response.toString()));
    } catch (e) {
      throw SecureException("EC Message encryption failed: $e");
    }
  }

  /// Decrypts an EC-encrypted [message] using the recipient's [privateKey].
  ///
  /// If [privateKey] is an RSA key (starts with `-----BEGIN RSA PRIVATE KEY-----`),
  /// delegates to [SecureMessaging.rsa].decrypt instead.
  ///
  /// The decryption process:
  /// 1. Decodes the base64 outer wrapper and parses the JSON
  /// 2. Extracts the ephemeral public key and nonce from metadata
  /// 3. Derives the same AES-256 key via ECDH + HKDF
  /// 4. Decrypts the ciphertext with AES-256-GCM
  ///
  /// Returns a [MessagingResponse] with the plaintext message and metadata
  /// containing the encryption type and timestamp.
  ///
  /// Throws [SecureException] if decryption fails (wrong key, corrupted
  /// ciphertext, or tampered GCM tag).
  @override
  MessagingResponse decrypt({required String message, required String privateKey}) {
    if (privateKey.startsWith(PemDelimiter.BEGIN_PRIVATE_RSA_KEY)) {
      return SecureMessaging.rsa().decrypt(message: message, privateKey: privateKey);
    }

    try {
      ECPrivateKey decodedPrivateKey = ECUtils.decodePrivateKey(privateKey);
      String source = utf8.decode(base64Decode(message));

      MessagingResponse response = MessagingResponse.fromString(source, type: PemStyle.EC);

      // Extract ephemeral public key and nonce from metadata
      Uint8List ephPublicKeyBytes = base64Decode(response.metadata.enc);
      Uint8List nonce = base64Decode(response.metadata.sign);
      ECPoint ephPublicKey = ECUtils.parameters.curve.decodePoint(ephPublicKeyBytes)!;

      // 3. Derive AES key
      Uint8List sharedSecret = ECUtils.getSharedSecret(ephPublicKey, decodedPrivateKey.d);
      Uint8List aesKey = ECUtils.deriveAesKey(ephPublicKeyBytes, sharedSecret);

      // 4. Decrypt using AES-256 GCM
      Uint8List ciphertextTag = base64Decode(response.message);
      AEADParameters<KeyParameter> params = AEADParameters(KeyParameter(aesKey), macSize, nonce, associatedData);
      GCMBlockCipher gcmCipher = _getCipher()..init(false, params);

      Uint8List plaintext = gcmCipher.process(ciphertextTag);

      return MessagingResponse(
        message: utf8.decode(plaintext),
        metadata: MessagingMetadata(enc: "EC", sign: "${DateTime.timestamp()}", type: "EC")
      );
    } catch (e) {
      throw SecureException("EC Message decryption failed: $e");
    }
  }

  /// Generates a new EC key pair and returns PEM-encoded public and private keys.
  ///
  /// The key pair is generated on the secp128r1 curve (as defined by
  /// [ECUtils.parameters]). The keys are encoded to PEM format using
  /// [ECUtils.encodePublicKey] and [ECUtils.encodePrivateKey].
  ///
  /// Returns a [SecureKeyResponse] containing the PEM-encoded keys.
  ///
  /// Throws [SecureException] if key generation fails.
  @override
  SecureKeyResponse generate() {
    try {
      AsymmetricKeyPair<PublicKey, PrivateKey> pair = _generate();

      ECPrivateKey privateKey = pair.privateKey as ECPrivateKey;
      ECPublicKey publicKey = pair.publicKey as ECPublicKey;

      return SecureKeyResponse(publicKey: ECUtils.encodePublicKey(publicKey), privateKey: ECUtils.encodePrivateKey(privateKey));
    } catch (e) {
      throw SecureException("EC Key pair generation failed: $e");
    }
  }

  /// Generates a raw [AsymmetricKeyPair] for internal use.
  ///
  /// Uses [SecureUtils.create] to obtain a cryptographically secure random
  /// number generator, then initializes [ECKeyGenerator] with
  /// [ECKeyGeneratorParameters] on [ECUtils.parameters] (secp128r1).
  ///
  /// Returns the raw key pair containing [ECPublicKey] and [ECPrivateKey].
  AsymmetricKeyPair<PublicKey, PrivateKey> _generate() {
    SecureRandom secureRandom = SecureUtils.create();

    ECKeyGeneratorParameters genParams = ECKeyGeneratorParameters(ECUtils.parameters);
    ParametersWithRandom<ECKeyGeneratorParameters> params = ParametersWithRandom(genParams, secureRandom,);

    ECKeyGenerator keyGen = ECKeyGenerator()..init(params);
    return keyGen.generateKeyPair();
  }
}