import '../../definitions.dart';
import '../certificates/certificates.dart';
import '../interface/http_request_interface.dart';
import '../request/request.dart';
import '../response/response.dart';

/// {@template stub_http_request}
/// A stub implementation of [HttpRequestInterface] for unsupported platforms.
///
/// This implementation is used for testing and development purposes on platforms
/// that do not support `dart:io` or `dart:web`. The [send] method throws
/// [UnimplementedError] to indicate that HTTP requests are not supported.
///
/// ## Usage
/// This is automatically selected by the conditional import in `http_request.dart`
/// when neither `dart:io` nor `dart:js_interop` is available.
///
/// ## Example
/// ```dart
/// // This would only happen on an unsupported platform
/// final impl = HttpRequestImplementation();
/// await impl.send(request); // Throws UnimplementedError
/// ```
///
/// ## Edge cases
/// - The [close] method is a no-op and can be called safely.
/// - All constructor parameters are accepted but ignored.
/// {@endtemplate}
class HttpRequestImplementation extends HttpRequestInterface {
  /// Creates a [HttpRequestImplementation] stub.
  ///
  /// ## Parameters
  /// - [allowAutoSignedCert]: Whether to allow auto signed certificates (ignored).
  /// - [trustedCertificates]: List of trusted certificates (ignored).
  /// - [withCredentials]: Whether to send credentials (ignored).
  /// - [findProxy]: Proxy finder function (ignored).
  ///
  /// ## Example
  /// ```dart
  /// final impl = HttpRequestImplementation(
  ///   allowAutoSignedCert: false,
  /// );
  /// ```
  /// 
  /// {@macro stub_http_request}
  HttpRequestImplementation({
    bool allowAutoSignedCert = true,
    List<ZapTrustedCertificate>? trustedCertificates,
    bool withCredentials = false,
    ProxyFinder? findProxy,
    bool enableCookies = true, // Ignored: the stub never sends requests.
  });

  /// Closes the stub client. This is a no-op.
  @override
  void close() {}

  /// Sends an HTTP request.
  ///
  /// This method always throws [UnimplementedError] as the stub
  /// implementation does not support actual HTTP requests.
  ///
  /// ## Parameters
  /// - [request]: The request to send (unused).
  ///
  /// ## Throws
  /// [UnimplementedError] always.
  @override
  Future<Response<T>> send<T>(Request<T> request) {
    throw UnimplementedError();
  }
}