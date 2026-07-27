import 'dart:convert';

/// {@template messaging_metadata}
/// Metadata associated with a secure message, containing encryption scheme
/// details, signature information, and message type.
///
/// This class is used internally by [MessagingResponse] to track how a
/// message was encrypted and when it was created. The metadata is serialized
/// alongside the message body in encrypted payloads.
///
/// ### Serialization formats
///
/// - **JSON**: [toJson] / [fromJson] for map-based serialization
/// - **Base64**: [toString] / [fromString] for base64-encoded JSON strings
///   (used in encrypted payload wrappers)
///
/// ### Example
///
/// ```dart
/// final meta = MessagingMetadata(
///   enc: 'RSA',
///   sign: '2024-01-15T10:30:00.000',
///   type: 'RSA',
/// );
///
/// // Serialize to base64
/// final encoded = meta.toString();
///
/// // Deserialize from base64
/// final restored = MessagingMetadata.fromString(encoded);
/// ```
/// {@endtemplate}
class MessagingMetadata {
  /// The encryption scheme or ephemeral public key data.
  ///
  /// For RSA messages, this is the string `"RSA"`. For EC messages,
  /// this is the base64-encoded ephemeral public key used during
  /// ECIES key agreement.
  final String enc;

  /// The message type identifier.
  ///
  /// Indicates which cryptographic algorithm was used:
  /// - `"RSA"` for RSA-OAEP encrypted messages
  /// - `"EC"` for ECIES + AES-256-GCM encrypted messages
  final String type;

  /// The signature, nonce, or timestamp associated with the message.
  ///
  /// For EC messages, this is the base64-encoded nonce (16 bytes).
  /// For RSA messages and decrypted EC messages, this is a timestamp
  /// string indicating when the message was processed.
  final String sign;

  /// Creates a [MessagingMetadata] instance.
  ///
  /// - [enc]: Encryption-related information (scheme or ephemeral key).
  /// - [sign]: Signature, nonce, or timestamp identifier.
  /// - [type]: The cryptographic algorithm type (`"RSA"` or `"EC"`).
  ///
  /// {@macro messaging_metadata}
  MessagingMetadata({
    required this.enc,
    required this.sign,
    required this.type,
  });

  /// Creates a [MessagingMetadata] from a JSON map.
  ///
  /// Missing fields default to empty strings.
  ///
  /// ```dart
  /// final meta = MessagingMetadata.fromJson({
  ///   'enc': 'EC',
  ///   'sign': 'nonce-data',
  ///   'type': 'EC',
  /// });
  /// ```
  factory MessagingMetadata.fromJson(Map<String, dynamic> json) {
    return MessagingMetadata(
      enc: json["enc"] ?? "",
      sign: json["sign"] ?? "",
      type: json["type"] ?? "",
    );
  }

  /// Converts this metadata to a JSON map.
  ///
  /// Returns a `Map<String, dynamic>` with keys `"enc"`, `"sign"`,
  /// and `"type"`.
  Map<String, dynamic> toJson() {
    return {
      "enc": enc,
      "sign": sign,
      "type": type,
    };
  }

  /// Creates a [MessagingMetadata] from a base64-encoded JSON string.
  ///
  /// The [source] is first base64-decoded, then UTF-8-decoded, then
  /// parsed as JSON. The resulting map is passed to [fromJson].
  ///
  /// ```dart
  /// final meta = MessagingMetadata.fromString('eyJlbmMiOiJFQyJ9');
  /// ```
  factory MessagingMetadata.fromString(String source) {
    final decodedJson = json.decode(utf8.decode(base64Decode(source)));
    return MessagingMetadata.fromJson(decodedJson);
  }

  /// Converts this metadata to a base64-encoded JSON string.
  ///
  /// The metadata is first serialized to JSON, then UTF-8-encoded,
  /// then base64-encoded. This format is used in encrypted payload
  /// wrappers.
  ///
  /// ```dart
  /// final meta = MessagingMetadata(enc: 'RSA', sign: 'ts', type: 'RSA');
  /// final encoded = meta.toString(); // base64-encoded JSON
  /// ```
  @override
  String toString() {
    final jsonString = json.encode(toJson());
    return base64Encode(utf8.encode(jsonString));
  }
}