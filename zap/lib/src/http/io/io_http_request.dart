import 'dart:async';
import 'dart:io' as io;

import '../../definitions.dart';
import '../../enums/exception_type.dart';
import '../../enums/zap_provider.dart';
import '../../exceptions/zap_exception.dart';
import '../certificates/certificates.dart';
import '../interface/http_request_interface.dart';
import '../request/request.dart';
import '../response/helpers.dart';
import '../response/response.dart';
import '../utils/body_decoder.dart';
import '../utils/http_status.dart';
import 'io_http_response.dart';

/// {@template io_http_request}
/// A `dart:io` implementation of [HttpRequestInterface] with comprehensive error handling.
///
/// This class provides HTTP request functionality for mobile and desktop platforms
/// using the `dart:io` [io.HttpClient]. It handles SSL/TLS certificates, proxies,
/// timeouts, and various network error conditions.
///
/// ## Features
/// - SSL/TLS certificate pinning and custom trust stores
/// - Proxy configuration
/// - Automatic redirect following
/// - Comprehensive error classification (socket, HTTP, SSL, timeout)
/// - Response interception support
///
/// ## Example
/// ```dart
/// final impl = HttpRequestImplementation(
///   allowAutoSignedCert: false,
///   trustedCertificates: [cert1, cert2],
/// );
/// final response = await impl.send(request);
/// impl.close();
/// ```
/// {@endtemplate}
class HttpRequestImplementation extends HttpRequestInterface {
  /// The HTTP client.
  io.HttpClient? _httpClient;

  /// The security context for custom certificate trust.
  io.SecurityContext? _securityContext;

  /// Creates an [HttpRequestImplementation] for IO platforms.
  ///
  /// ## Parameters
  /// - [allowAutoSignedCert]: Whether to allow self-signed certificates.
  ///   Defaults to `true`. Should be `false` in production.
  /// - [trustedCertificates]: Optional list of certificates to trust explicitly.
  /// - [withCredentials]: Whether to include credentials (unused on IO).
  /// - [findProxy]: Optional function to determine the proxy server.
  ///
  /// ## Example
  /// ```dart
  /// final impl = HttpRequestImplementation(
  ///   allowAutoSignedCert: false,
  ///   findProxy: (uri) => 'PROXY proxy.example.com:8080',
  /// );
  /// ```
  ///
  /// ## Edge cases
  /// - If [trustedCertificates] is provided, a custom [io.SecurityContext] is created.
  /// - The [allowAutoSignedCert] flag is applied via `badCertificateCallback`.
  /// 
  /// {@macro io_http_request}
  HttpRequestImplementation({
    bool allowAutoSignedCert = true,
    List<ZapTrustedCertificate>? trustedCertificates,
    bool withCredentials = false,
    ProxyFinder? findProxy,
  }) {
    _httpClient = io.HttpClient();
    if (trustedCertificates != null) {
      _securityContext = io.SecurityContext();
      for (final trustedCertificate in trustedCertificates) {
        _securityContext!.setTrustedCertificatesBytes(List.from(trustedCertificate.bytes));
      }
    }

    _httpClient = io.HttpClient(context: _securityContext);
    _httpClient!.badCertificateCallback = (_, __, ___) => allowAutoSignedCert;
    _httpClient!.findProxy = findProxy;
  }

  /// Sends an HTTP request and returns the response.
  ///
  /// ## Parameters
  /// - [request]: The configured request to send.
  ///
  /// ## Returns
  /// A [Response] of type [T] with the server's reply.
  ///
  /// ## Throws
  /// - [ZapException] with type [ExceptionType.timeout] for request timeouts.
  /// - [ZapException] with type [ExceptionType.connection] for connection refused.
  /// - [ZapException] with type [ExceptionType.network] for network errors.
  /// - [ZapException] with type [ExceptionType.dns] for DNS resolution failures.
  /// - [ZapException] with type [ExceptionType.ssl] for SSL/TLS errors.
  /// - [ZapException] with type [ExceptionType.parsing] for invalid data formats.
  ///
  /// ## Edge cases
  /// - The request is aborted on timeout to prevent resource leaks.
  /// - Socket errors are classified by their OS error code for specific diagnostics.
  /// - HTTP exceptions are classified based on their message content.
  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    var stream = request.bodyBytes.asBroadcastStream();
    io.HttpClientRequest? ioRequest;

    try {
      _httpClient!.connectionTimeout = timeout;
      ioRequest = (await _httpClient!.openUrl(request.method, request.url))
        ..followRedirects = request.followRedirects
        ..persistentConnection = request.persistentConnection
        ..maxRedirects = request.maxRedirects
        ..contentLength = request.contentLength ?? -1;
      request.headers.forEach(ioRequest.headers.set);

      var response = timeout == null
          ? await stream.pipe(ioRequest) as io.HttpClientResponse
          : await stream.pipe(ioRequest).timeout(timeout!) as io.HttpClientResponse;

      var headers = <String, String>{};
      response.headers.forEach((key, values) {
        headers[key] = values.join(',');
      });

      final bodyBytes = (response);

      final interceptionResponse = await request.responseInterceptor?.call(request, T, IOHttpResponse(response: response));
      if (interceptionResponse != null) return interceptionResponse;

      final stringBody = await bodyBytesToString(bodyBytes, headers);

      final body = bodyDecoded<T>(request, stringBody, response.headers.contentType?.mimeType);

      return Response(
        headers: headers,
        request: request,
        status: HttpStatus.fromCode(response.statusCode),
        message: response.reasonPhrase,
        bodyBytes: bodyBytes,
        body: body,
        bodyString: stringBody,
        provider: ZapProvider.io,
      );
    } on TimeoutException catch (_) {
      ioRequest?.abort();
      throw ZapException.timeout(
        'Request timed out after ${timeout?.inMilliseconds ?? 'unknown'}ms',
        request.url,
        {'timeoutMs': timeout?.inMilliseconds}
      );
    } on io.SocketException catch (e) {
      throw _handleSocketException(e, request.url);
    } on io.HttpException catch (e) {
      throw _handleHttpException(e, request.url);
    } on io.HandshakeException catch (e) {
      throw ZapException.ssl('SSL handshake failed: ${e.message}', request.url);
    } on io.CertificateException catch (e) {
      throw ZapException.ssl('Certificate error: ${e.message}', request.url);
    } on FormatException catch (e) {
      throw ZapException.parsing('Invalid URL or data format: ${e.message}', request.url);
    } catch (e, stackTrace) {
      throw ZapException(
        'Unexpected error: $e',
        request.url,
        ExceptionType.unknown,
        null,
        {'originalError': e.toString()},
        e is Exception ? e : null,
        stackTrace,
      );
    }
  }

  /// Handles socket exceptions by classifying them based on OS error codes.
  ///
  /// Provides specific error types for common scenarios like connection refused,
  /// host unreachable, DNS failure, and connection timeout.
  ///
  /// ## Parameters
  /// - [e]: The socket exception to handle.
  /// - [uri]: The request URI.
  ///
  /// ## Returns
  /// A [ZapException] with the appropriate error type.
  ///
  /// ## Supported error codes
  /// - 61/10061: Connection refused
  /// - 64/10064: Host unreachable
  /// - 65/10065: No route to host
  /// - 8/11001: DNS resolution failed
  /// - 60/10060: Connection timed out
  Exception _handleSocketException(io.SocketException e, Uri? uri) {
    Map<String, dynamic> details = {
      'osError': e.osError?.toString(),
      'address': e.address?.toString(),
      'port': e.port,
    };

    switch (e.osError?.errorCode) {
      case 61: // Connection refused (macOS/Linux)
      case 10061: // Connection refused (Windows)
        return ZapException.connection('Connection refused - server may be down', uri, details);
      case 64: // Host is down (macOS/Linux)
      case 10064: // Host is down (Windows)
        return ZapException.network('Host is unreachable or down', uri, details);
      case 65: // No route to host (macOS/Linux)
      case 10065: // No route to host (Windows)
        return ZapException.network('No route to host', uri, details);
      case 8: // Name resolution failed (macOS/Linux)
      case 11001: // Host not found (Windows)
        return ZapException.dns('DNS resolution failed - host not found', uri, details);
      case 60: // Operation timed out (macOS/Linux)
      case 10060: // Connection timed out (Windows)
        return ZapException.timeout('Connection timed out', uri, details);
      default:
        return ZapException.network('Network error: ${e.message}', uri, details);
    }
  }

  /// Handles HTTP exceptions by classifying them based on message content.
  ///
  /// ## Parameters
  /// - [e]: The HTTP exception to handle.
  /// - [uri]: The request URI.
  ///
  /// ## Returns
  /// A [ZapException] with the appropriate error type.
  Exception _handleHttpException(io.HttpException e, Uri? uri) {
    Map<String, dynamic> details = {'originalMessage': e.message};
    
    if (e.message.contains('Connection closed')) {
      return ZapException.connection('Connection closed by server', uri, details);
    } else if (e.message.contains('redirect')) {
      return ZapException.client('Too many redirects or redirect loop', 0, uri, details);
    } else {
      return ZapException.network('HTTP protocol error: ${e.message}', uri, details);
    }
  }

  /// Closes the HttpClient and releases resources.
  ///
  /// Forces all connections to be closed. After calling this method,
  /// the client should not be used for further requests.
  ///
  /// ## Example
  /// ```dart
  /// impl.close(); // Forces connection closure
  /// ```
  @override
  void close() {
    if (_httpClient != null) {
      _httpClient!.close(force: true);
      _httpClient = null;
    }
  }
}