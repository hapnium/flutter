import 'dart:convert';

import '../../core/zap_inst.dart';
import '../request/request.dart';
import 'http_content_type.dart';

/// {@template body_decoded}
/// Decodes the body of a request based on the content type and decoder.
///
/// This function handles the deserialization of HTTP response bodies into
/// typed objects. It supports JSON decoding, custom decoders, and fallback
/// string parsing.
///
/// ## Parameters
/// - [request]: The request (contains the decoder function).
/// - [stringBody]: The response body as a string.
/// - [mimeType]: The MIME type of the body (from Content-Type header).
///
/// ## Returns
/// The decoded body of type [T], or `null` if decoding fails or the body is empty.
///
/// ## Example
/// ```dart
/// final body = bodyDecoded<User>(
///   request,
///   '{"name": "John", "age": 30}',
///   'application/json',
/// );
/// ```
///
/// ## Edge cases
/// - Returns `null` if [stringBody] is empty.
/// - If JSON decoding fails, falls back to raw string.
/// - If the decoder throws, falls back to casting the string directly.
/// - If no decoder is provided, the body is cast directly to [T].
/// {@endtemplate}
T? bodyDecoded<T>(Request<T> request, String stringBody, String? mimeType) {
  T? body;
  dynamic bodyToDecode;

  if (mimeType != null && mimeType.contains(HttpContentType.APPLICATION_JSON)) {
    try {
      bodyToDecode = jsonDecode(stringBody);
    } on FormatException catch (_) {
      Z.log('Cannot decode server response to json');
      bodyToDecode = stringBody;
    }
  } else {
    bodyToDecode = stringBody;
  }

  try {
    if (stringBody == '') {
      body = null;
    } else if (request.decoder == null) {
      body = bodyToDecode as T?;
    } else {
      body = request.decoder!(bodyToDecode);
    }
  } on Exception catch (_) {
    body = stringBody as T;
  }

  return body;
}