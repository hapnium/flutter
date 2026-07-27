import '../../definitions.dart';
import '../certificates/certificates.dart';
import '../stub/stub_http_request.dart'
    if (dart.library.js_interop) '../html/html_http_request.dart'
    if (dart.library.io) '../io/io_http_request.dart';

/// {@template create_http}
/// Factory function to create a platform-specific [HttpRequestImplementation].
///
/// This function uses conditional imports to select the appropriate HTTP
/// implementation based on the target platform:
/// - **IO (dart:io)**: For mobile and desktop platforms.
/// - **Web (dart:js_interop)**: For browser platforms.
/// - **Stub**: For unsupported platforms (throws when used).
///
/// ## Parameters
/// - [allowAutoSignedCert]: When `true`, the client will allow auto-signed certificates.
///   Defaults to `true`. Should be `false` in production.
/// - [trustedCertificates]: Optional list of certificates to trust explicitly.
/// - [withCredentials]: When `true`, the client will send credentials in CORS requests.
/// - [findProxy]: Optional function to determine the proxy server for each request.
///
/// ## Returns
/// A platform-specific [HttpRequestImplementation] instance.
///
/// ## Example
/// ```dart
/// final http = createHttp();
/// // For web:
/// final http = createHttp(withCredentials: true);
/// // For IO:
/// final http = createHttp(
///   allowAutoSignedCert: false,
///   trustedCertificates: [ZapTrustedCertificate(certBytes)],
/// );
/// ```
///
/// ## Edge cases
/// - On unsupported platforms, the stub implementation throws
///   [UnimplementedError] when [send] is called.
/// - The [withCredentials] parameter is only effective on web platforms.
/// {@endtemplate}
HttpRequestImplementation createHttp({
  bool allowAutoSignedCert = true,
  List<ZapTrustedCertificate>? trustedCertificates,
  bool withCredentials = false,
  ProxyFinder? findProxy,
}) {
  return HttpRequestImplementation(
    allowAutoSignedCert: allowAutoSignedCert,
    trustedCertificates: trustedCertificates,
    withCredentials: withCredentials,
    findProxy: findProxy,
  );
}