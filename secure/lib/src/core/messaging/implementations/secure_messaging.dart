import 'package:secure/secure.dart';

import 'ec_secure_messaging.dart';
import 'rsa_secure_messaging.dart';
import '../secure_messaging_service.dart';

/// {@template secure_messaging}
/// Abstract base class providing a unified interface for secure messaging.
///
/// Acts as a facade that delegates cryptographic operations to either
/// [RSASecureMessaging] or [ECSecureMessaging] based on the key type.
///
/// ### Usage
///
/// ```dart
/// // Create an EC-based messaging instance
/// final ec = SecureMessaging.ec();
/// final ecKeys = ec.generate();
/// final encrypted = ec.encrypt(message: 'hello', publicKey: ecKeys.publicKey);
/// final decrypted = ec.decrypt(message: encrypted, privateKey: ecKeys.privateKey);
///
/// // Create an RSA-based messaging instance
/// final rsa = SecureMessaging.rsa();
/// final rsaKeys = rsa.generate();
/// final encrypted = rsa.encrypt(message: 'hello', publicKey: rsaKeys.publicKey);
/// final decrypted = rsa.decrypt(message: encrypted, privateKey: rsaKeys.privateKey);
/// ```
///
/// ### Cross-algorithm transparency
///
/// Both [encrypt] and [decrypt] automatically detect the key type and
/// delegate to the correct implementation. For example, calling
/// `SecureMessaging.ec().encrypt(...)` with an RSA public key will
/// transparently use RSA encryption instead.
/// {@endtemplate}
abstract class SecureMessaging implements SecureMessagingService {
  /// The PEM style (RSA or EC) that this messaging instance uses.
  ///
  /// This value is set by the subclass constructor and determines
  /// which cryptographic algorithm is used for key generation,
  /// encryption, and decryption.
  final PemStyle style;

  /// Creates a [SecureMessaging] instance with the given [style].
  ///
  /// This constructor is protected — callers should use the
  /// [SecureMessaging.ec] or [SecureMessaging.rsa] factory constructors
  /// instead of subclassing directly.
  ///
  /// {@macro secure_messaging}
  SecureMessaging(this.style);

  /// Factory method to dynamically resolve the appropriate implementation.
  ///
  /// This method is **deprecated**. Use [SecureMessaging.ec] or
  /// [SecureMessaging.rsa] instead.
  ///
  /// Returns an [ECSecureMessaging] when [style] is [PemStyle.EC],
  /// or an [RSASecureMessaging] when [style] is [PemStyle.RSA].
  ///
  /// {@macro secure_messaging}
  @Deprecated("`resolve` is now deprecated and will be removed. Use `SecureMessaging.ec or SecureMessaging.rsa")
  static SecureMessaging resolve(PemStyle style) {
    if (style == PemStyle.RSA) {
      return SecureMessaging.rsa();
    } else {
      return SecureMessaging.ec();
    }
  }

  /// Creates an EC (Elliptic Curve) messaging instance.
  ///
  /// Returns an [ECSecureMessaging] that uses ECIES with AES-256-GCM
  /// for encryption and ECDH + HKDF for key agreement.
  ///
  /// {@macro ec_secure_messaging}
  factory SecureMessaging.ec() {
    return ECSecureMessaging();
  }

  /// Creates an RSA messaging instance.
  ///
  /// Returns an [RSASecureMessaging] that uses RSA-OAEP with SHA-256
  /// for encryption.
  ///
  /// {@macro rsa_secure_messaging}
  factory SecureMessaging.rsa() {
    return RSASecureMessaging();
  }
}