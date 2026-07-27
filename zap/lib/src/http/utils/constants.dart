// ignore_for_file: constant_identifier_names

import 'http_content_type.dart';

/// {@template constants}
/// This class contains constants used in the HTTP client.
///
/// These constants provide default values for common HTTP configuration
/// options, such as content types and user agent strings.
///
/// ## Example
/// ```dart
/// print(Constants.DEFAULT_CONTENT_TYPE); // 'application/json; charset=utf-8'
/// print(Constants.DEFAULT_USER_AGENT); // 'hapx-client'
/// ```
/// {@endtemplate}
abstract class Constants {
  /// The default content type for HTTP requests.
  ///
  /// Used when no explicit content type is provided. Set to
  /// `'application/json; charset=utf-8'`.
  ///
  /// ## Example
  /// ```dart
  /// final headers = {
  ///   'Content-Type': Constants.DEFAULT_CONTENT_TYPE,
  /// };
  /// ```
  /// 
  /// {@macro constants}
  static const String DEFAULT_CONTENT_TYPE = '${HttpContentType.APPLICATION_JSON}; charset=utf-8';

  /// The default user agent string for HTTP requests.
  ///
  /// Used when `sendUserAgent` is `true` but no custom user agent is set.
  /// Defaults to `'hapx-client'`.
  ///
  /// ## Example
  /// ```dart
  /// final client = ZapClient(
  ///   sendUserAgent: true,
  ///   // Uses Constants.DEFAULT_USER_AGENT unless overridden
  /// );
  /// ```
  /// 
  /// {@macro constants}
  static const String DEFAULT_USER_AGENT = 'hapx-client';
}