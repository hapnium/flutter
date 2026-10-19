// ignore_for_file: library_prefixes

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as Math show min;
import 'dart:typed_data';

import 'package:web/web.dart' show XMLHttpRequest, Event;

import '../../core/zap_inst.dart';
import '../../definitions.dart';
import '../../enums/exception_type.dart';
import '../../enums/zap_provider.dart';
import '../../exceptions/zap_exception.dart';
import '../certificates/certificates.dart';
import '../request/request.dart';
import '../response/helpers.dart';
import '../response/response.dart';
import '../interface/http_request_interface.dart';
import '../utils/body_decoder.dart';
import '../utils/http_content_type.dart';
import '../utils/http_headers.dart';
import '../utils/http_status.dart';

/// {@template html_http_request}
/// A `dart:web` implementation of [HttpRequestInterface] with comprehensive error handling.
///
/// This class provides HTTP request functionality for web (browser) platforms
/// using the `XMLHttpRequest` API. It handles CORS, timeouts, authentication,
/// and response parsing.
///
/// ## Features
/// - Full XMLHttpRequest lifecycle management
/// - Comprehensive error classification (CORS, network, auth, timeout)
/// - Automatic response header parsing
/// - Binary and text response handling
/// - Request cancellation support
///
/// ## Limitations
/// - Some headers may be restricted by CORS or browser security policies.
/// - Response interception is not yet implemented for web.
/// - The `withCredentials` flag controls cookie and auth header inclusion.
///
/// ## Example
/// ```dart
/// final impl = HttpRequestImplementation(
///   allowAutoSignedCert: false,
///   withCredentials: true,
/// );
/// final response = await impl.send(request);
/// ```
/// {@endtemplate}
class HttpRequestImplementation implements HttpRequestInterface {
  /// Creates a [HttpRequestImplementation] for web platforms.
  /// 
  /// ## Parameters
  /// - [allowAutoSignedCert]: Whether to allow auto-signed certificates (unused on web).
  /// - [trustedCertificates]: List of trusted certificates (unused on web).
  /// - [withCredentials]: Whether to include credentials in CORS requests.
  /// - [findProxy]: Proxy finder callback (unused on web).
  /// 
  /// ## Example
  /// ```dart
  /// final impl = HttpRequestImplementation(withCredentials: true);
  /// ```
  /// 
  /// {@macro html_http_request}
  HttpRequestImplementation({
    bool allowAutoSignedCert = true,
    List<ZapTrustedCertificate>? trustedCertificates,
    this.withCredentials = false,
    ProxyFinder? findProxy,
    bool enableCookies = true, // Ignored: the browser manages cookies natively.
  });

  /// Set of active XMLHttpRequest instances for cancellation on close.
  final _xhrs = <XMLHttpRequest>{};

  /// Whether to include credentials (cookies, auth headers) in CORS requests.
  ///
  /// When `true`, the browser will include cookies and HTTP auth information
  /// in cross-origin requests. The server must also set appropriate CORS headers.
  final bool withCredentials;

  /// Sends an HTTP request and returns the response.
  ///
  /// ## Parameters
  /// - [request]: The configured request to send.
  ///
  /// ## Returns
  /// A [Response] of type [T] with the server's reply.
  ///
  /// ## Throws
  /// - [ZapException] with type [ExceptionType.connection] if the client is closed.
  /// - [ZapException] with type [ExceptionType.network] for connection failures.
  /// - [ZapException] with type [ExceptionType.timeout] for request timeouts.
  /// - [ZapException] with type [ExceptionType.cancelled] for aborted requests.
  ///
  /// ## Edge cases
  /// - If the client is closed, the request is immediately rejected.
  /// - Headers that cannot be set due to CORS restrictions are logged but not thrown.
  /// - The XHR is removed from the tracking set after completion.
  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    if (_isClosed) {
      throw ZapException.connection('HTTP request failed. Client is already closed.', request.url);
    }

    var bytes = await request.bodyBytes.toBytes();
    XMLHttpRequest xhr = XMLHttpRequest();

    xhr.timeout = (timeout ?? Duration.zero).inMilliseconds;
    
    try {
      // Use absolute URL to avoid CORS issues
      final url = request.url.toString();
      Z.log('Sending ${request.method} request to: $url');
      xhr.open(request.method, url, true);
    } catch (e) {
      Z.log('Failed to open connection: $e');
      throw ZapException.network('Failed to open connection: $e', request.url);
    }

    _xhrs.add(xhr);

    xhr.responseType = 'arraybuffer';
    xhr.withCredentials = withCredentials;

    // Set headers with comprehensive error handling
    request.headers.forEach((key, value) {
      try {
        xhr.setRequestHeader(key, value);
      } catch (e) {
        // Some headers might be restricted by CORS or browser security
        Z.log('Warning: Could not set header $key: $e');
      }
    });

    var completer = Completer<Response<T>>();

    // Handle successful response
    xhr.onload = (Event event) {
      Z.log('XHR onload fired with status: ${xhr.status}');
      _handleResponse(xhr, request, completer);
    }.toJS;

    // Handle network errors
    xhr.onerror = (Event event) {
      Z.log('XHR onerror fired');
      if (!completer.isCompleted) {
        _handleError(xhr, request, completer);
      }
    }.toJS;

    // Handle timeout
    xhr.ontimeout = (Event event) {
      Z.log('XHR ontimeout fired');
      if (!completer.isCompleted) {
        final timeoutDuration = timeout?.inMilliseconds ?? xhr.timeout;
        completer.completeError(
          ZapException.timeout(
            'Request timeout after ${timeoutDuration}ms',
            request.url,
            {'timeoutMs': timeoutDuration}
          ),
          StackTrace.current,
        );
      }
    }.toJS;

    // Handle abort
    xhr.onabort = (Event event) {
      Z.log('XHR onabort fired');
      if (!completer.isCompleted) {
        completer.completeError(
          ZapException.cancelled('Request aborted', request.url),
          StackTrace.current,
        );
      }
    }.toJS;

    // Send the request with error handling
    try {
      Z.log('Sending request with ${bytes.length} bytes of data');
      if (bytes.isNotEmpty) {
        xhr.send(bytes.toJS);
      } else {
        xhr.send();
      }
    } catch (e) {
      Z.log('Error sending request: $e');
      if (!completer.isCompleted) {
        completer.completeError(
          ZapException.network('Failed to send request: $e', request.url),
          StackTrace.current,
        );
      }
    }

    try {
      return await completer.future;
    } finally {
      _xhrs.remove(xhr);
    }
  }

  /// Handles XMLHttpRequest error events.
  ///
  /// Classifies errors based on the XHR state and status code, providing
  /// more specific error types for common scenarios like CORS issues,
  /// authentication failures, and server errors.
  ///
  /// ## Parameters
  /// - [xhr]: The XMLHttpRequest that encountered an error.
  /// - [request]: The original request.
  /// - [completer]: The completer to resolve with the error.
  void _handleError(XMLHttpRequest xhr, Request request, Completer completer) {
    String errorMessage;
    ExceptionType errorType;
    Map<String, dynamic> details = {
      'readyState': xhr.readyState,
      'status': xhr.status,
      'statusText': xhr.statusText,
    };

    Z.log('Handling error: readyState=${xhr.readyState}, status=${xhr.status}');

    if (xhr.status == 0) {
      // Status 0 usually indicates network issues or CORS problems
      if (xhr.readyState == 4) {
        // Request completed but with network error
        errorMessage = 'Network error - unable to connect to server';
        errorType = ExceptionType.network;
        Z.log('Network error detected - readyState=4, status=0');
      } else {
        // CORS or other browser security restriction
        errorMessage = 'CORS error or network connectivity issue';
        errorType = ExceptionType.network;
        details['corsIssue'] = true;
        Z.log('CORS issue detected - readyState=${xhr.readyState}, status=0');
        Z.log('Check that the server allows cross-origin requests and has proper CORS headers');
      }
    } else if (xhr.status >= 400 && xhr.status < 500) {
      // Client errors
      errorMessage = 'Client error ${xhr.status}: ${xhr.statusText}';
      errorType = xhr.status == 401 || xhr.status == 403 
          ? ExceptionType.auth 
          : ExceptionType.client;
    } else if (xhr.status >= 500) {
      // Server errors
      errorMessage = 'Server error ${xhr.status}: ${xhr.statusText}';
      errorType = ExceptionType.server;
    } else {
      // Unknown error
      errorMessage = 'Unknown XMLHttpRequest error';
      errorType = ExceptionType.unknown;
    }

    completer.completeError(
      ZapException(errorMessage, request.url, errorType, xhr.status, details),
      StackTrace.current,
    );
  }

  /// Handles successful XMLHttpRequest onload events.
  ///
  /// Processes the response body (binary or text), parses headers,
  /// decodes the response, and completes the completer with a [Response].
  ///
  /// ## Parameters
  /// - [xhr]: The completed XMLHttpRequest.
  /// - [request]: The original request.
  /// - [completer]: The completer to resolve with the response.
  ///
  /// ## Edge cases
  /// - If the status code is >= 400, the error handler is invoked instead.
  /// - If no response data is received, an empty byte list is used.
  /// - Response interception is not yet implemented for web.
  void _handleResponse<T>(XMLHttpRequest xhr, Request<T> request, Completer<Response<T>> completer) async {
    try {
      // Check for HTTP error status codes even in onload
      if (xhr.status >= 400) {
        Z.log('Error status code detected in onload: ${xhr.status}');
        _handleError(xhr, request, completer);
        return;
      }

      // Handle response data
      Uint8List bodyBytes;
      if (xhr.response != null) {
        if (xhr.responseType == 'arraybuffer') {
          try {
            final jsArrayBuffer = xhr.response as JSArrayBuffer;
            bodyBytes = jsArrayBuffer.toDart.asUint8List();
            Z.log('Successfully parsed arraybuffer response: ${bodyBytes.length} bytes');
          } catch (e) {
            Z.log('Failed to parse arraybuffer response: $e');
            throw ZapException.parsing('Failed to parse arraybuffer response: $e', request.url);
          }
        } else {
          // Fallback to responseText
          try {
            final responseText = xhr.responseText;
            bodyBytes = Uint8List.fromList(responseText.codeUnits);
            Z.log('Using responseText fallback: ${bodyBytes.length} bytes');
          } catch (e) {
            Z.log('Failed to parse text response: $e');
            throw ZapException.parsing('Failed to parse text response: $e', request.url);
          }
        }
      } else {
        Z.log('No response data received');
        bodyBytes = Uint8List(0);
      }

      final bodyStream = Stream.fromIterable([bodyBytes]);

      if (request.responseInterceptor != null) {
        throw ZapException('Response interception not implemented for web yet!', request.url);
      }

      final responseHeaders = _parseResponseHeaders(xhr);
      final stringBody = await bodyBytesToString(bodyStream, responseHeaders);
      final contentType = responseHeaders[HttpHeaders.CONTENT_TYPE] ?? HttpContentType.APPLICATION_JSON;
      
      Z.log('Response body: ${stringBody.substring(0, Math.min(100, stringBody.length))}...');

      final body = bodyDecoded<T>(request, stringBody, contentType);

      final response = Response<T>(
        bodyBytes: bodyStream,
        status: HttpStatus.fromCode(xhr.status),
        message: xhr.statusText,
        request: request,
        headers: responseHeaders,
        body: body,
        bodyString: stringBody,
        provider: ZapProvider.web,
      );

      if (!completer.isCompleted) {
        Z.log('Completing request with successful response');
        completer.complete(response);
      }
    } catch (e, stackTrace) {
      Z.log('Error in _handleResponse: $e');
      if (!completer.isCompleted) {
        if (e is ZapException) {
          completer.completeError(e, stackTrace);
        } else {
          completer.completeError(
            ZapException.parsing('Error processing response: $e', request.url),
            stackTrace,
          );
        }
      }
    }
  }

  /// Parses response headers from the XMLHttpRequest.
  ///
  /// Splits the raw header string by CRLF and extracts key-value pairs.
  /// Duplicate header names are combined with commas.
  ///
  /// ## Parameters
  /// - [xhr]: The XMLHttpRequest to parse headers from.
  ///
  /// ## Returns
  /// A map of lowercase header names to their values.
  ///
  /// ## Edge cases
  /// - Empty header lines are skipped.
  /// - Headers without a colon separator are skipped.
  /// - Duplicate headers are combined with ', '.
  Headers _parseResponseHeaders(XMLHttpRequest xhr) {
    var headers = <String, String>{};
    try {
      var headersString = xhr.getAllResponseHeaders();
      if (headersString.isNotEmpty) {
        var headersList = headersString.split('\r\n');
        for (var header in headersList) {
          if (header.isEmpty) continue;

          var splitIdx = header.indexOf(': ');
          if (splitIdx == -1) continue;

          var key = header.substring(0, splitIdx).toLowerCase();
          var value = header.substring(splitIdx + 2);
          if (headers.containsKey(key)) {
            headers[key] = '${headers[key]}, $value';
          } else {
            headers[key] = value;
          }
        }
      }
      Z.log('Parsed response headers: $headers');
    } catch (e) {
      Z.log('Warning: Could not parse response headers: $e');
    }
    return headers;
  }

  /// Closes the HTTP client and aborts all in-flight requests.
  ///
  /// After calling this method, the client should not be used for further requests.
  /// All pending XMLHttpRequests are aborted and removed from tracking.
  ///
  /// ## Example
  /// ```dart
  /// impl.close(); // Aborts all pending requests
  /// ```
  @override
  void close() {
    _isClosed = true;
    for (var xhr in _xhrs) {
      xhr.abort();
    }
    _xhrs.clear();
  }

  /// The timeout duration for HTTP requests.
  ///
  /// If `null`, no timeout is enforced. On web, this sets the
  /// XMLHttpRequest timeout property in milliseconds.
  @override
  Duration? timeout;

  /// Whether the client has been closed.
  ///
  /// Once `true`, no further requests can be sent.
  bool _isClosed = false;
}