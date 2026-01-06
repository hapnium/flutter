/// {@template secure}
/// # `secure` Library
///
/// The `secure` library is a modular and extensible collection of utilities and
/// abstractions designed to simplify secure communication and cryptographic
/// key handling in Dart applications.
///
/// ## 🚀 Features
/// - **Secure Messaging**: High-level APIs for message encryption, signing, and metadata handling.
/// - **Key Management**: Generate, encode, and decode RSA/EC key pairs using PEM format.
/// - **Cryptographic Standards**: Built on top of the `pointycastle` cryptographic primitives.
/// - **Robust Exception Handling**: Custom exceptions tailored for secure operations.
///
/// ## 📦 Structure
/// This library exposes a clear structure composed of:
///
/// ### 🧱 Core Modules
/// - `SecureKey`: Handles generation and manipulation of cryptographic key pairs.
/// - `SecureMessaging`: Enables secure message encryption, signing, and metadata handling.
///
/// ### 📦 Models
/// Data representations such as responses and metadata related to messaging and key operations.
///
/// ### 🚨 Exceptions
/// Custom exceptions to catch and describe edge cases in secure workflows.
///
/// ### 📚 Enums
/// Representations for internal formats (e.g., RSA/EC PEM styles).
///
/// ## ✅ Example
/// ```dart
/// import 'package:secure/secure.dart';
///
/// void main() {
///   final key = SecureKey.generateKeyPair();
///   final message = SecureMessaging.encrypt("Hello", key.publicKey);
///   print(message);
/// }
/// ```
/// {@endtemplate}
library;

/// {@macro secure}

/// ---------------------------------------------------------------------------
/// EXCEPTIONS
/// ---------------------------------------------------------------------------

/// Custom exception classes thrown throughout the `secure` library.
///
/// Includes:
/// - `SecureException`: Base exception class for all secure operations.
///
/// These exceptions provide contextual error messages that help with debugging
/// and recovery in cryptographic workflows.
export 'src/exceptions/secure_exception.dart';

/// ---------------------------------------------------------------------------
/// CORE
/// ---------------------------------------------------------------------------

/// Core implementation of secure messaging.
///
/// Exposes high-level APIs to:
/// - Encrypt and decrypt messages
/// - Sign and verify payloads
/// - Generate secure metadata for communication
///
/// Built with interoperability and secure defaults in mind.
export 'src/core/messaging/implementations/secure_messaging.dart';

/// Core implementation of cryptographic key management.
///
/// Enables:
/// - RSA/EC key generation
/// - Export/import using PEM format
/// - Integration with secure messaging and encoding systems
export 'src/core/key/implementations/secure_key.dart';

/// ---------------------------------------------------------------------------
/// MODELS
/// ---------------------------------------------------------------------------

/// Model representing the response returned after key generation.
///
/// Contains:
/// - Public and private key data (usually in PEM format)
/// - Associated metadata, if any
export 'src/models/secure_key_response.dart';

/// Model representing metadata for secure messages.
///
/// Contains optional fields like:
/// - Sender/recipient identifiers
/// - Timestamps
/// - Message tags or annotations
export 'src/models/messaging_metadata.dart';

/// Model representing the result of a secure messaging operation.
///
/// Contains:
/// - Encrypted payloads
/// - Signatures
/// - Associated metadata
export 'src/models/messaging_response.dart';

/// ---------------------------------------------------------------------------
/// ENUMS
/// ---------------------------------------------------------------------------

/// Enumeration of supported PEM styles.
///
/// Includes:
/// - `RSA`: RSA public/private key formatting
/// - `EC`: Elliptic Curve key formatting
///
/// Used internally across encoding/decoding utilities.
export 'src/enums/pem_style.dart';