import 'dart:io' as io;

import '../interface/redirect_info.dart';

/// {@template io_redirect_info}
/// A wrapper for [io.RedirectInfo] that implements the [RedirectInfo] interface.
///
/// This class adapts the `dart:io` [io.RedirectInfo] to the Zap redirect
/// interface, providing platform-specific redirect information handling.
///
/// ## Example
/// ```dart
/// final ioRedirect = ioResponse.redirects.first;
/// final redirect = IoRedirectInfo(redirectInfo: ioRedirect);
/// print('${redirect.statusCode} -> ${redirect.location}');
/// ```
/// {@endtemplate}
class IoRedirectInfo implements RedirectInfo {
  /// The wrapped [io.RedirectInfo].
  final io.RedirectInfo _redirectInfo;

  /// Creates an [IoRedirectInfo] wrapping the given [io.RedirectInfo].
  ///
  /// ## Parameters
  /// - [redirectInfo]: The `dart:io` redirect info to wrap.
  ///
  /// ## Example
  /// ```dart
  /// final wrapped = IoRedirectInfo(redirectInfo: ioRedirect);
  /// ```
  /// {@macro io_redirect_info}
  IoRedirectInfo({required io.RedirectInfo redirectInfo}) : _redirectInfo = redirectInfo;

  /// The HTTP status code used for the redirect.
  ///
  /// Typically one of:
  /// - 301 (Moved Permanently)
  /// - 302 (Found)
  /// - 303 (See Other)
  /// - 307 (Temporary Redirect)
  /// - 308 (Permanent Redirect)
  @override
  int get statusCode => _redirectInfo.statusCode;

  /// The HTTP method used for the redirect.
  ///
  /// Usually 'GET', but can be the original method for 307/308 redirects.
  @override
  String get method => _redirectInfo.method;

  /// The target URI for the redirect.
  ///
  /// This is the URL the client should follow.
  @override
  Uri get location => _redirectInfo.location;
}