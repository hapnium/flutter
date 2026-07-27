import 'dart:convert';

import 'package:secure/secure.dart';

/// {@template messaging_response}
/// A message-and-metadata pair returned by [SecureMessagingService.decrypt].
///
/// Contains the decrypted plaintext [message] and [metadata] describing
/// how the message was encrypted (algorithm type, timestamp, etc.).
///
/// ### Serialization
///
/// - **JSON string**: [toString] / [fromString] for the full response
/// - **JSON map**: [toJson] for map-based access
///
/// ### Legacy format support
///
/// [fromString] gracefully handles pre-v1 messages that were stored as
/// plain text (no JSON wrapping). In that case, the entire string is
/// treated as the message body, and the metadata is populated with
/// defaults (`"legacy"` for sign, algorithm type for enc/type).
///
/// ### Example
///
/// ```dart
/// final response = MessagingResponse(
///   message: 'decrypted text',
///   metadata: MessagingMetadata(enc: 'RSA', sign: 'ts', type: 'RSA'),
/// );
///
/// // Serialize to JSON string
/// final jsonStr = response.toString();
///
/// // Deserialize from JSON string
/// final restored = MessagingResponse.fromString(jsonStr);
/// ```
/// {@endtemplate}
class MessagingResponse {
  /// The plaintext message content.
  ///
  /// After decryption, this contains the original message that was
  /// encrypted by the sender. May be an empty string for empty messages.
  final String message;

  /// Metadata describing the encryption scheme and context.
  ///
  /// Contains the algorithm type (`"RSA"` or `"EC"`), encryption
  /// details, and a timestamp or nonce.
  final MessagingMetadata metadata;

  /// Creates a [MessagingResponse] instance.
  ///
  /// - [message]: The plaintext message content.
  /// - [metadata]: Encryption metadata (algorithm, timestamp, etc.).
  ///
  /// {@macro messaging_response}
  MessagingResponse({
    required this.message,
    required this.metadata,
  });

  /// Creates a [MessagingResponse] from a JSON or plain-text string.
  ///
  /// If [source] is valid JSON, it is parsed as a JSON object with
  /// `"message"` and `"metadata"` keys. If JSON parsing fails, the
  /// entire string is treated as the message body with legacy metadata
  /// defaults.
  ///
  /// The [type] parameter controls which legacy metadata defaults are
  /// used when JSON parsing fails:
  /// - [PemStyle.RSA] (default): enc=`"RSA"`, type=`"RSA"`
  /// - [PemStyle.EC]: enc=`"EC"`, type=`"EC"`
  ///
  /// ```dart
  /// // From JSON
  /// final r1 = MessagingResponse.fromString('{"message":"hi","metadata":{...}}');
  ///
  /// // From legacy plain text
  /// final r2 = MessagingResponse.fromString('plain text message');
  /// ```
  factory MessagingResponse.fromString(String source, {PemStyle type = PemStyle.RSA}) {
    return type == PemStyle.EC ? _fromEC(source) : _fromRSA(source);
  }

  /// Converts this response to a JSON map.
  ///
  /// Returns a `Map<String, dynamic>` with keys `"message"` (String)
  /// and `"metadata"` (Map from [MessagingMetadata.toJson]).
  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "metadata": metadata.toJson(),
    };
  }

  /// Converts this response to a JSON string.
  ///
  /// The output of [toJson] is passed through [json.encode] to produce
  /// a compact JSON string suitable for storage or transmission.
  @override
  String toString() => json.encode(toJson());

  /// Parses an RSA-style response from [source].
  ///
  /// Attempts JSON decode first. On failure, wraps the raw string as
  /// a legacy message with RSA metadata defaults.
  static MessagingResponse _fromRSA(String source) {
    try {
      final decodedJson = json.decode(source) as Map<String, dynamic>;
      return _fromJson(decodedJson);
    } catch (e) {
      return MessagingResponse(
        message: source,
        metadata: MessagingMetadata(
          enc: "RSA",
          sign: "legacy",
          type: "RSA",
        ),
      );
    }
  }

  /// Parses an EC-style response from [source].
  ///
  /// Attempts JSON decode first. On failure, wraps the raw string as
  /// a legacy message with EC metadata defaults.
  static MessagingResponse _fromEC(String source) {
    try {
      final decodedJson = json.decode(source) as Map<String, dynamic>;
      return _fromJson(decodedJson);
    } catch (e) {
      return MessagingResponse(
        message: source,
        metadata: MessagingMetadata(
          enc: "EC",
          sign: "legacy",
          type: "EC",
        ),
      );
    }
  }

  /// Parses a response from a JSON map.
  ///
  /// Extracts `"message"` (defaulting to `""`) and `"metadata"`
  /// (defaulting to an empty map, which further defaults all fields
  /// to `""` via [MessagingMetadata.fromJson]).
  static MessagingResponse _fromJson(Map<String, dynamic> json) {
    return MessagingResponse(
      message: json["message"] ?? "",
      metadata: MessagingMetadata.fromJson(json["metadata"] ?? {}),
    );
  }
}