import 'secure_key_factory.dart';
import '../secure_key_service.dart';

/// {@template secure_key_abstract}
/// Abstract base class for secure key operations.
///
/// Provides a factory constructor that returns the default [SecureKeyService]
/// implementation ([SecureKeyFactory]). This class serves as the primary
/// entry point for key generation, encryption, and decryption in the
/// `secure` library.
///
/// ### Usage
///
/// ```dart
/// // Get the default factory implementation
/// final keyService = SecureKey.factory();
///
/// // Generate deterministic keys from an identifier
/// final keys = keyService.generate('user-123');
///
/// // Encrypt with the generated public key
/// final cipher = keyService.encrypt(
///   message: 'secret data',
///   publicKey: keys.publicKey,
/// );
///
/// // Decrypt with the generated private key
/// final plain = keyService.decrypt(
///   message: cipher,
///   privateKey: keys.privateKey,
/// );
/// ```
///
/// ### When to use [SecureKey] vs [SecureMessaging]
///
/// - Use [SecureKey] (via [SecureKey.factory]) when you need **deterministic**
///   key generation from an identifier string.
/// - Use [SecureMessaging] (via [SecureMessaging.ec] or [SecureMessaging.rsa])
///   when you need **random** key generation on each call.
/// {@endtemplate}
abstract class SecureKey implements SecureKeyService {
  /// Creates a [SecureKey] instance.
  ///
  /// This constructor is protected. Use [SecureKey.factory] to obtain
  /// the default implementation.
  ///
  /// {@macro secure_key_abstract}
  SecureKey();

  /// Creates the default [SecureKeyService] implementation.
  ///
  /// Returns a [SecureKeyFactory] instance that provides deterministic
  /// EC key generation and EC-based encryption/decryption.
  ///
  /// {@macro secure_key_factory}
  factory SecureKey.factory() {
    return SecureKeyFactory();
  }
}