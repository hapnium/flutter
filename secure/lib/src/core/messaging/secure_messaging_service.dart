import 'package:secure/secure.dart';

/// {@template secure_messaging_service}
/// Abstract interface for end-to-end encryption (E2EE) messaging operations.
///
/// Defines the contract that all secure messaging implementations must
/// follow. Concrete implementations ([ECSecureMessaging], [RSASecureMessaging])
/// provide the actual cryptographic logic.
///
/// ### Lifecycle
///
/// 1. **Generate keys**: Call [generate] to create a public/private key pair.
/// 2. **Encrypt**: Call [encrypt] with the recipient's public key and a plaintext
///    message to produce ciphertext.
/// 3. **Decrypt**: Call [decrypt] with the ciphertext and your private key to
///    recover the original plaintext.
///
/// ### Example
///
/// ```dart
/// final service = SecureMessaging.ec();
/// final keys = service.generate();
/// final cipher = service.encrypt(message: 'secret', publicKey: keys.publicKey);
/// final plain = service.decrypt(message: cipher, privateKey: keys.privateKey);
/// print(plain.message); // 'secret'
/// ```
/// {@endtemplate}
abstract class SecureMessagingService {
  /// Generates a new asymmetric key pair (public and private).
  ///
  /// The generated keys are returned as PEM-formatted strings inside a
  /// [SecureKeyResponse]. The public key can be shared freely; the
  /// private key must be kept secret.
  ///
  /// **Returns:**
  ///
  /// A [SecureKeyResponse] containing the PEM-encoded public and
  /// private keys.
  SecureKeyResponse generate();

  /// Encrypts a plaintext [message] using the recipient's [publicKey].
  ///
  /// The [publicKey] must be a PEM-encoded public key matching the
  /// algorithm used by this implementation (RSA or EC).
  ///
  /// **Returns:**
  ///
  /// An opaque string containing the ciphertext. The format varies
  /// by implementation (base64-encoded RSA-OAEP ciphertext for RSA,
  /// base64-encoded JSON with ECIES wrapper for EC).
  ///
  /// **Throws:**
  ///
  /// - [SecureException] if encryption fails (invalid key, message
  ///   too long, etc.).
  String encrypt({required String message, required String publicKey});

  /// Decrypts a ciphertext [message] using the recipient's [privateKey].
  ///
  /// The [privateKey] must be the PEM-encoded private key corresponding
  /// to the public key used during encryption.
  ///
  /// **Returns:**
  ///
  /// A [MessagingResponse] containing the decrypted plaintext message
  /// and metadata (encryption type, timestamp).
  ///
  /// **Throws:**
  ///
  /// - [SecureException] if decryption fails (wrong key, corrupted
  ///   ciphertext, tampered GCM tag, etc.).
  MessagingResponse decrypt({required String message, required String privateKey});
}