import 'package:secure/secure.dart';

/// {@template secure_key_service}
/// Abstract interface for deterministic key generation and encryption operations.
///
/// Unlike [SecureMessagingService] which generates random keys on each call,
/// this service derives keys **deterministically** from a string identifier.
/// The same identifier always produces the same key pair.
///
/// ### Implementations
///
/// - [SecureKeyFactory]: Default EC-based implementation using secp128r1.
///
/// ### Example
///
/// ```dart
/// final service = SecureKey.factory();
/// final keys = service.generate('device-abc');
/// final cipher = service.encrypt(message: 'payload', publicKey: keys.publicKey);
/// final plain = service.decrypt(message: cipher, privateKey: keys.privateKey);
/// ```
/// {@endtemplate}
abstract class SecureKeyService {
  /// Generates a key pair deterministically from [identifier].
  ///
  /// The [identifier] is used as a seed for the key generation process.
  /// Calling this method multiple times with the same identifier will
  /// produce the same key pair.
  ///
  /// **Parameters:**
  ///
  /// * `identifier`: A string used to deterministically derive the key pair.
  ///   Typically a user ID, device ID, or shared secret.
  ///
  /// **Returns:**
  ///
  /// A [SecureKeyResponse] containing the PEM-encoded public and private
  /// keys.
  ///
  /// **Throws:**
  ///
  /// - [SecureException] if key generation fails.
  SecureKeyResponse generate(String identifier);

  /// Encrypts a [message] using the recipient's [publicKey].
  ///
  /// The [publicKey] must be a PEM-encoded public key matching the
  /// algorithm used by the implementation (typically EC).
  ///
  /// **Returns:**
  ///
  /// An opaque ciphertext string.
  ///
  /// **Throws:**
  ///
  /// - [SecureException] if encryption fails.
  String encrypt({required String message, required String publicKey});

  /// Decrypts a ciphertext [message] using the recipient's [privateKey].
  ///
  /// The [privateKey] must be the PEM-encoded private key corresponding
  /// to the public key used during encryption.
  ///
  /// **Returns:**
  ///
  /// The decrypted plaintext string.
  ///
  /// **Throws:**
  ///
  /// - [SecureException] if decryption fails (wrong key, corrupted
  ///   ciphertext, etc.).
  String decrypt({required String message, required String privateKey});
}