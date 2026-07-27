import 'dart:convert';

import '../../definitions.dart';
import '../../http/request/request.dart';
import 'header_value.dart';

/// {@template body_bytes_to_string}
/// Converts a [BodyByteStream] to a [String].
///
/// This function reads the entire byte stream and decodes it using the
/// encoding specified in the response headers.
///
/// ## Parameters
/// - [bodyBytes]: The body bytes to convert.
/// - [headers]: The headers of the response (used to determine encoding).
///
/// ## Returns
/// A [Future<String>] containing the decoded body.
///
/// ## Example
/// ```dart
/// final body = await bodyBytesToString(response.bodyBytes, response.headers);
/// ```
///
/// ## Edge cases
/// - Falls back to UTF-8 if the charset is not specified or unknown.
/// {@endtemplate}
Future<String> bodyBytesToString(BodyByteStream bodyBytes, Headers headers) {
  return bodyBytes.bytesToString(_encodingForHeaders(headers));
}

/// Returns the encoding to use for a response with the given headers.
///
/// Extracts the charset from the `Content-Type` header and maps it to
/// an [Encoding] instance.
///
/// ## Parameters
/// - [headers]: The response headers.
///
/// ## Returns
/// The [Encoding] for the response, defaulting to UTF-8.
Encoding _encodingForHeaders(Headers headers) =>
    _encodingForCharset(_contentTypeForHeaders(headers).parameters!['charset']);

/// Returns the [Encoding] that corresponds to [charset].
///
/// ## Parameters
/// - [charset]: The charset name (e.g., 'utf-8', 'iso-8859-1').
/// - [fallback]: The fallback encoding if charset is null or unknown.
///
/// ## Returns
/// The matching [Encoding], or [fallback].
Encoding _encodingForCharset(String? charset, [Encoding fallback = utf8]) {
  if (charset == null) return fallback;
  return Encoding.getByName(charset) ?? fallback;
}

/// Returns the [HeaderValue] for the given headers' content-type.
///
/// ## Parameters
/// - [headers]: The response headers.
///
/// ## Returns
/// The parsed content-type, defaulting to `application/octet-stream`.
HeaderValue _contentTypeForHeaders(Headers headers) {
  var contentType = headers['content-type'];
  if (contentType != null) return HeaderValue.parse(contentType);
  return HeaderValue('application/octet-stream');
}