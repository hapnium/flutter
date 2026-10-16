part of 'zap_client.dart';

/// {@template client_handler_extension}
/// Extension on [ClientHandler] that provides request building, execution,
/// and exception handling logic.
///
/// This extension encapsulates the core HTTP request lifecycle including
/// body processing, header management, response interception, and
/// structured error handling.
/// {@endtemplate}
extension ClientHandlerExtension on ClientHandler {
  /// Returns the controller advice, falling back to a default instance.
  ///
  /// This ensures that exception handling always has a notifier available,
  /// even if no custom [ControllerAdvice] was provided.
  ControllerAdvice get _adviser => controllerAdvice ?? ControllerAdvice();

  /// Creates a request with a body (optimized for async FormData).
  /// 
  /// This method is used to create a request with a body, which is useful for
  /// making HTTP requests with a body, such as POST or PUT requests.
  /// 
  /// ## Parameters
  /// - [url]: The target endpoint (relative or absolute).
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [body]: The body payload for the request.
  /// - [method]: HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress (0.0 to 100.0).
  /// 
  /// ## Returns
  /// A [Request] of type [T] ready to be sent.
  ///
  /// ## Throws
  /// - [ZapException] if the body type is not supported and [errorSafety] is `false`.
  ///
  /// ## Supported body types
  /// - [FormData]: Multipart form data with file uploads.
  /// - [Uint8List], [List<int>], [Iterable<int>]: Binary data.
  /// - [BodyByteStream]: Raw byte stream.
  /// - [Map]: JSON-encoded or form URL-encoded data.
  /// - [List]: JSON-encoded array.
  /// - [String]: Plain text.
  /// - `null`: Empty body.
  ///
  /// ## Example
  /// ```dart
  /// final request = await handler.requestWithBody<User>(
  ///   '/users',
  ///   'application/json',
  ///   {'name': 'John'},
  ///   'POST',
  ///   null,
  ///   User.fromJson,
  ///   null,
  ///   null,
  /// );
  /// ```
  Future<Request<T>> requestWithBody<T>(
    String? url,
    String? contentType,
    RequestBody body,
    String method,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  ) async {
    BodyByteStream? bodyStream;
    int contentLength = 0;
    final Headers headers = {};

    if (sendUserAgent) {
      headers[HttpHeaders.USER_AGENT] = userAgent;
    }

    if (body is FormData) {
      // Get content length first
      contentLength = await body.lengthAsync;
      bodyStream = await _processFormDataStreamWithProgress(body, uploadProgress, contentLength);
      headers[HttpHeaders.CONTENT_TYPE] = HttpContentType.MULTIPARET_FORM_DATA_WITH_BOUNDARY(body.boundary);
    } else if (body is Uint8List || body is List<int> || body is Iterable<int>) {
      final bodyBytes = await _processBinaryAsync(body);
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
      contentLength = bodyBytes.length;
      headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    } else if (body is BodyByteStream) {
      final bodyBytes = await body.toBytes();
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
      contentLength = bodyBytes.length;
      headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    } else if (contentType != null && 
               contentType.toLowerCase() == HttpContentType.APPLICATION_X_WWW_FORM_URLENCODED && 
               body is Map) {
      final bodyBytes = await _processFormUrlEncodedAsync(body as RequestParam);
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
      contentLength = bodyBytes.length;
      headers[HttpHeaders.CONTENT_TYPE] = contentType;
    } else if (body is Map || body is List) {
      final bodyBytes = await _processJsonAsync(body);
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
      contentLength = bodyBytes.length;
      headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    } else if (body is String) {
      final bodyBytes = await _processStringAsync(body);
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
      contentLength = bodyBytes.length;
      headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    } else if (body == null) {
      contentLength = 0;
      headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    } else {
      try {
        final bodyBytes = await _processUnknownBodyAsync(body);
        bodyStream = _trackProgress(bodyBytes, uploadProgress);
        contentLength = bodyBytes.length;
        headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
      } catch (_) {
        if (!errorSafety) {
          throw ZapException.parsing('Request body cannot be ${body.runtimeType}');
        }
      }
    }

    // Set content length
    if (sendContentLength && contentLength > 0) {
      headers[HttpHeaders.CONTENT_LENGTH] = contentLength.toString();
    }

    final uri = createUri(url, query);
    return Request<T>(
      method: method,
      url: uri,
      headers: headers,
      bodyBytes: bodyStream,
      contentLength: contentLength,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      decoder: decoder,
      responseInterceptor: responseInterceptor
    );
  }

  /// Processes FormData with proper progress tracking.
  ///
  /// If no [uploadProgress] callback is provided, the FormData stream is
  /// returned directly. Otherwise, the FormData is converted to bytes first
  /// to enable accurate progress reporting.
  ///
  /// ## Parameters
  /// - [formData]: The form data to process.
  /// - [uploadProgress]: Optional progress callback.
  /// - [totalLength]: The total expected byte length.
  ///
  /// ## Returns
  /// A [BodyByteStream] containing the encoded form data.
  Future<BodyByteStream> _processFormDataStreamWithProgress(FormData formData, Progress? uploadProgress, int totalLength) async {
    if (uploadProgress == null) {
      return formData.finalize().cast<List<int>>();
    }

    // Convert FormData to bytes first to ensure we can track progress properly
    final formDataBytes = await formData.toBytes();
    
    // Create chunked stream with progress tracking
    return _trackProgress(formDataBytes, uploadProgress);
  }

  /// Wraps a byte stream with progress tracking.
  ///
  /// Splits the data into 8KB chunks and reports progress at ~60fps to avoid
  /// overwhelming the UI thread.
  ///
  /// ## Parameters
  /// - [bodyBytes]: The raw bytes to track.
  /// - [uploadProgress]: Optional progress callback receiving 0.0-100.0.
  ///
  /// ## Returns
  /// A [BodyByteStream] that reports progress as data is consumed.
  ///
  /// ## Edge cases
  /// - If [uploadProgress] is `null`, the bytes are wrapped in a single-value stream.
  /// - Progress is throttled to ~16ms intervals (~60fps) to prevent UI spam.
  /// - The stream can be cancelled, which stops progress reporting.
  BodyByteStream _trackProgress(BodyBytes bodyBytes, Progress? uploadProgress) {
    if (uploadProgress == null) {
      return Stream.value(bodyBytes);
    }

    var total = 0;
    var length = bodyBytes.length;
    var lastProgressTime = DateTime.now();
    var isCancelled = false;

    // Use reasonable chunk size instead of individual bytes
    const chunkSize = 8192; // 8KB chunks
    final chunks = <List<int>>[];
    
    // Split into chunks
    for (var i = 0; i < bodyBytes.length; i += chunkSize) {
      final end = (i + chunkSize < bodyBytes.length) ? i + chunkSize : bodyBytes.length;
      chunks.add(bodyBytes.sublist(i, end));
    }

    // Report initial progress
    scheduleMicrotask(() {
      if (!isCancelled) uploadProgress(0.0);
    });

    late StreamController<List<int>> controller;
    late StreamSubscription subscription;

    controller = StreamController<List<int>>(
      onCancel: () {
        isCancelled = true;
        subscription.cancel();
      },
    );

    // Create stream from chunks with async processing
    subscription = Stream.fromIterable(chunks)
      .asyncMap((chunk) async {
        if (isCancelled) return <int>[];
        // Small delay to prevent UI blocking
        await Future.delayed(Duration.zero);
        return chunk;
      })
      .listen((List<int> data) {
          if (isCancelled) return;
          
          total += data.length;
          
          // Calculate progress percentage
          final percent = length > 0 ? (total / length * 100) : 0.0;
          
          // Throttle progress updates to avoid UI spam
          final now = DateTime.now();
          if (now.difference(lastProgressTime).inMilliseconds > 16) { // ~60fps
            scheduleMicrotask(() {
              if (!isCancelled) uploadProgress(percent.clamp(0.0, 100.0));
            });
            lastProgressTime = now;
          }
          
          if (!controller.isClosed) {
            controller.add(data);
          }
        },
        onDone: () {
          if (!isCancelled) {
            // Ensure 100% progress is reported
            scheduleMicrotask(() {
              if (!isCancelled) uploadProgress(100.0);
            });
          }
          if (!controller.isClosed) {
            controller.close();
          }
        },
        onError: (error, stackTrace) {
          isCancelled = true;
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        },
        cancelOnError: true,
      );

    return controller.stream;
  }

  /// Processes JSON body asynchronously using [compute] to avoid blocking the UI.
  ///
  /// ## Parameters
  /// - [body]: The JSON-encodable body (typically a `Map` or `List`).
  ///
  /// ## Returns
  /// UTF-8 encoded bytes of the JSON string.
  Future<BodyBytes> _processJsonAsync(dynamic body) async {
    return await compute(_encodeJson, body);
  }

  /// Processes binary body payloads without mutation.
  ///
  /// Accepts [Uint8List], [List<int>], or [Iterable<int>] and returns
  /// a [Uint8List] without modifying the original data.
  ///
  /// ## Parameters
  /// - [body]: The binary body data.
  ///
  /// ## Returns
  /// A [Uint8List] containing the binary data.
  ///
  /// ## Edge cases
  /// - Returns an empty [Uint8List] if the input type is not recognized.
  Future<BodyBytes> _processBinaryAsync(dynamic body) async {
    if (body is Uint8List) {
      return body;
    }

    if (body is List<int>) {
      return Uint8List.fromList(body);
    }

    if (body is Iterable<int>) {
      return Uint8List.fromList(body.toList());
    }

    return Uint8List(0);
  }

  /// Processes form URL encoded body asynchronously using [compute].
  ///
  /// ## Parameters
  /// - [body]: The form data as a key-value map.
  ///
  /// ## Returns
  /// UTF-8 encoded bytes of the form URL encoded string.
  ///
  /// ## Example
  /// Input: `{'name': 'John', 'age': '30'}`
  /// Output: `name=John&age=30`
  Future<BodyBytes> _processFormUrlEncodedAsync(RequestParam body) async {
    return await compute(_encodeFormUrlEncoded, body);
  }

  /// Processes string body asynchronously using [compute].
  ///
  /// ## Parameters
  /// - [body]: The string body.
  ///
  /// ## Returns
  /// UTF-8 encoded bytes of the string.
  Future<BodyBytes> _processStringAsync(String body) async {
    return await compute(_encodeString, body);
  }

  /// Fallback serializer for body types outside the standard set.
  ///
  /// Attempts JSON encoding first, then falls back to string conversion.
  ///
  /// ## Parameters
  /// - [body]: The body to serialize.
  ///
  /// ## Returns
  /// UTF-8 encoded bytes of the serialized body.
  ///
  /// ## Throws
  /// [ZapException] if the body cannot be serialized.
  Future<BodyBytes> _processUnknownBodyAsync(dynamic body) async {
    try {
      return await _processJsonAsync(body);
    } catch (_) {
      return await _processStringAsync(body.toString());
    }
  }

  /// Sets simple headers for a request.
  ///
  /// Applies the content type and optionally the user agent header.
  ///
  /// ## Parameters
  /// - [headers]: The headers map to modify.
  /// - [contentType]: The content type to set, or `null` to use the default.
  void _setSimpleHeaders(Headers headers, String? contentType) {
    headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    if (sendUserAgent) {
      headers[HttpHeaders.USER_AGENT] = userAgent;
    }
  }

  /// Performs a request and returns a response.
  /// 
  /// This method sends the request through the modifier pipeline, handles
  /// authentication retries on 401 responses, and processes exceptions.
  /// 
  /// ## Parameters
  /// - [request]: The request to perform.
  /// - [useAuth]: Whether to apply authentication (default: `false`).
  /// - [requestNumber]: The current retry attempt number (default: `1`).
  /// - [headers]: Additional HTTP headers to merge into the request.
  /// 
  /// ## Returns
  /// A [Response] of type [T] representing the server's reply.
  ///
  /// ## Edge cases
  /// - If [useAuth] is `true` and an authenticator is configured, the
  ///   authenticator is called before sending the request.
  /// - On 401 responses, the request is retried with authentication if
  ///   [requestNumber] <= [maxAuthRetries].
  /// - If [errorSafety] is `false`, authentication errors are thrown.
  Future<Response<T>> perform<T>(Request<T> request, {bool useAuth = false, int requestNumber = 1, Headers? headers}) async {
    headers?.forEach((key, value) {
      request.headers[key] = value;
    });

    if (useAuth) {
      await modifier.authenticator!(request);
    }

    final req = await modifier.modifyRequest<T>(request);
    client.timeout = timeout;

    try {
      var res = await client.send<T>(req);
      var response = await modifier.modifyResponse<T>(req, res);

      if (response.status.isUnauthorized && modifier.authenticator != null && requestNumber <= maxAuthRetries) {
        return await perform<T>(req, useAuth: true, requestNumber: requestNumber + 1, headers: req.headers);
      } else if (response.status.isUnauthorized) {
        if (!errorSafety) {
          throw ZapException.auth('An authentication error occurred. Please try again.');
        } else {
          return Response<T>(
            request: req,
            headers: response.headers,
            status: response.status,
            body: response.body,
            bodyBytes: response.bodyBytes,
            bodyString: response.bodyString,
          );
        }
      }

      return response;
    } on Exception catch (err) {
      return handleException<T>(err, request);
    }
  }

  /// Returns a response interceptor, preferring the provided one over the default.
  ///
  /// If [actual] is non-null, it is returned directly. Otherwise, falls back
  /// to [defaultResponseInterceptor], wrapping it in a typed adapter.
  ///
  /// ## Parameters
  /// - [actual]: The per-request interceptor, if any.
  ///
  /// ## Returns
  /// A [ResponseInterceptor<T>] or `null` if no interceptor is available.
  ResponseInterceptor<T>? _responseInterceptor<T>(ResponseInterceptor<T>? actual) {
    if (actual != null) return actual;

    if (defaultResponseInterceptor != null) {
      return (request, targetType, response) async {
        final result = await defaultResponseInterceptor!(request, targetType, response);
        return result as Response<T>?;
      };
    }

    return null;
  }

  /// Returns a request with body.
  /// 
  /// Creates a [Request] object with the specified body, method, and
  /// configuration. Falls back to [defaultDecoder] and [defaultResponseInterceptor]
  /// if not explicitly provided.
  /// 
  /// ## Parameters
  /// - [url]: The target endpoint.
  /// - [method]: HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [body]: The body payload for the request.
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  /// 
  /// ## Returns
  /// A [Request] of type [T] ready to be sent.
  ///
  /// ## Example
  /// ```dart
  /// final request = await handler.getRequestWithBody<User>(
  ///   '/users',
  ///   'POST',
  ///   body: {'name': 'John'},
  ///   query: null,
  ///   contentType: 'application/json',
  /// );
  /// ```
  Future<Request<T>> getRequestWithBody<T>(String? url, String method, {
    String? contentType,
    required RequestBody body,
    required RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    Progress? uploadProgress,
  }) {
    decoder ??= defaultDecoder as ResponseDecoder<T>?;
    responseInterceptor = _responseInterceptor(responseInterceptor);

    return requestWithBody<T>(url, contentType, body, method, query, decoder, responseInterceptor, uploadProgress);
  }

  /// Returns a request without body.
  /// 
  /// Creates a [Request] object for methods that do not include a body,
  /// such as GET or DELETE requests.
  /// 
  /// ## Parameters
  /// - [url]: The target endpoint.
  /// - [method]: HTTP method (e.g., 'GET', 'DELETE').
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [contentLength]: The length of the request body (default: 0).
  /// - [followRedirects]: Whether to follow redirects (default: `true`).
  /// - [maxRedirects]: The maximum number of redirects to follow (default: 5).
  /// 
  /// ## Returns
  /// A [Request] of type [T] ready to be sent.
  ///
  /// ## Example
  /// ```dart
  /// final request = await handler.getRequestWithoutBody<User>(
  ///   '/users',
  ///   'GET',
  ///   query: {'page': '1'},
  /// );
  /// ```
  Future<Request<T>> getRequestWithoutBody<T>(String? url, String method, {
    String? contentType,
    RequestParam? query,
    ResponseDecoder<T>? decoder,
    ResponseInterceptor<T>? responseInterceptor,
    int contentLength = 0,
    bool followRedirects = true,
    int maxRedirects = 5,
  }) {
    final Headers defHeaders = {};
    _setSimpleHeaders(defHeaders, contentType);
    final uri = createUri(url, query);

    final request = Request<T>(
      method: method,
      url: uri,
      headers: defHeaders,
      decoder: decoder ?? defaultDecoder as ResponseDecoder<T>?,
      responseInterceptor: _responseInterceptor(responseInterceptor),
      contentLength: contentLength,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
    );

    return Future.value(request);
  }

  /// Handles exceptions and returns appropriate Response objects based on exception type.
  /// 
  /// Converts exceptions to [ZapException] instances if needed, notifies the
  /// controller adviser, and either rethrows or creates structured error responses
  /// based on [errorSafety].
  /// 
  /// ## Parameters
  /// - [e]: The exception to handle.
  /// - [request]: The request that caused the exception.
  /// 
  /// ## Returns
  /// A [Response] of type [T] with error status and details.
  ///
  /// ## Throws
  /// The exception is rethrown if [errorSafety] is `false`.
  ///
  /// ## Edge cases
  /// - If [e] is already a [ZapException], it is used directly.
  /// - The controller adviser is always notified, regardless of [errorSafety].
  Future<Response<T>> handleException<T>(Exception e, Request<T> request) async {
    ZapException zapException;
    
    // Convert to ZapException if not already
    if (e is ZapException) {
      zapException = e;
    } else {
      zapException = ZapException(e.toString(), request.url);
    }

    // Always notify the adviser about the exception
    _adviser.onException(zapException);

    // If errorSafety is disabled, rethrow the exception
    if (!errorSafety) {
      throw zapException;
    }

    // Return appropriate response based on exception type
    return _createResponseForException<T>(zapException, request);
  }

  /// Creates appropriate Response objects based on ZapException type.
  /// 
  /// Maps each [ExceptionType] to a corresponding [HttpStatus] and error
  /// response with descriptive headers and messages.
  /// 
  /// ## Parameters
  /// - [exception]: The exception to handle.
  /// - [request]: The request that caused the exception.
  /// 
  /// ## Returns
  /// A [Response] of type [T] with appropriate status, headers, and error details.
  ///
  /// ## Supported exception types
  /// - [ExceptionType.timeout]: Returns 408 Request Timeout.
  /// - [ExceptionType.network]: Returns 600 Connection Not Reachable.
  /// - [ExceptionType.server]: Returns the server error status code.
  /// - [ExceptionType.client]: Returns the client error status code.
  /// - [ExceptionType.auth]: Returns 401 Unauthorized.
  /// - [ExceptionType.ssl]: Returns 600 Connection Not Reachable.
  /// - [ExceptionType.connection]: Returns 600 Connection Not Reachable.
  /// - [ExceptionType.dns]: Returns 600 Connection Not Reachable.
  /// - [ExceptionType.parsing]: Returns 422 Unprocessable Entity.
  /// - [ExceptionType.cancelled]: Returns 601 Request Cancelled.
  /// - Default: Returns 500 Internal Server Error.
  Response<T> _createResponseForException<T>(ZapException exception, Request<T> request) {
    switch (exception.type) {
      case ExceptionType.timeout:
        return Response<T>(
          status: HttpStatus.REQUEST_TIMEOUT,
          message: 'Request timed out. Please try again.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'timeout'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Request timeout: ${exception.message}',
        );

      case ExceptionType.network:
        return Response<T>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Network connection unavailable. Check your internet connection.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'network'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Network error: ${exception.message}',
        );

      case ExceptionType.server:
        return Response<T>(
          status: HttpStatus.fromCode(exception.statusCode ?? 500),
          message: 'Server error occurred. Please try again later.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'server',
            HttpHeaders.X_STATUS_CODE: '${exception.statusCode ?? 500}'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Server error: ${exception.message}',
        );

      case ExceptionType.client:
        return Response<T>(
          status: HttpStatus.fromCode(exception.statusCode ?? 400),
          message: 'Client request error. Please check your request.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'client',
            HttpHeaders.X_STATUS_CODE: '${exception.statusCode ?? 400}'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Client error: ${exception.message}',
        );

      case ExceptionType.auth:
        return Response<T>(
          status: HttpStatus.UNAUTHORIZED,
          message: 'Authentication required. Please login again.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'auth',
            HttpHeaders.X_AUTH_REQUIRED: 'true'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Authentication error: ${exception.message}',
        );

      case ExceptionType.ssl:
        return Response<T>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Secure connection failed. Certificate or SSL error.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'ssl',
            HttpHeaders.X_SECURITY_ERROR: 'true'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'SSL error: ${exception.message}',
        );

      case ExceptionType.connection:
        return Response<T>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Cannot connect to server. Server may be down.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'connection',
            HttpHeaders.X_RETRY_AFTER: '30'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Connection error: ${exception.message}',
        );

      case ExceptionType.dns:
        return Response<T>(
          status: HttpStatus.CONNECTION_NOT_REACHABLE,
          message: 'Cannot resolve server address. Check your DNS settings.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'dns',
            HttpHeaders.X_DNS_ERROR: 'true'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'DNS error: ${exception.message}',
        );

      case ExceptionType.parsing:
        return Response<T>(
          status: HttpStatus.UNPROCESSABLE_ENTITY,
          message: 'Cannot parse server response. Invalid data format.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'parsing',
            HttpHeaders.X_CONTENT_ERROR: 'true'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Parsing error: ${exception.message}',
        );

      case ExceptionType.cancelled:
        return Response<T>(
          status: HttpStatus.REQUEST_CANCELLED,
          message: 'Request was cancelled.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'cancelled',
            HttpHeaders.X_CANCELLED: 'true'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Request cancelled: ${exception.message}',
        );
      default:
        return Response<T>(
          status: HttpStatus.INTERNAL_SERVER_ERROR,
          message: 'An unexpected error occurred. Please try again.',
          request: request,
          headers: {
            HttpHeaders.X_ERROR_TYPE: 'unknown',
            HttpHeaders.X_UNEXPECTED_ERROR: 'true'
          },
          body: null,
          bodyBytes: null,
          bodyString: 'Unknown error: ${exception.message}',
        );
    }
  }
}

/// Encodes a dynamic value to JSON bytes.
///
/// This is a top-level function to allow execution via [compute] isolate.
///
/// ## Parameters
/// - [body]: The JSON-encodable value.
///
/// ## Returns
/// UTF-8 encoded bytes of the JSON string.
BodyBytes _encodeJson(dynamic body) {
  final jsonString = json.encode(body);
  return Uint8List.fromList(utf8.encode(jsonString));
}

/// Encodes a map to form URL encoded bytes.
///
/// This is a top-level function to allow execution via [compute] isolate.
///
/// ## Parameters
/// - [body]: The form data as a key-value map.
///
/// ## Returns
/// UTF-8 encoded bytes of the form URL encoded string.
///
/// ## Example
/// Input: `{'name': 'John', 'age': '30'}`
/// Output: `name=John&age=30`
BodyBytes _encodeFormUrlEncoded(RequestParam body) {
  final parts = <String>[];
  body.forEach((key, value) {
    parts.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}');
  });
  final formData = parts.join('&');
  return Uint8List.fromList(utf8.encode(formData));
}

/// Encodes a string to UTF-8 bytes.
///
/// This is a top-level function to allow execution via [compute] isolate.
///
/// ## Parameters
/// - [body]: The string to encode.
///
/// ## Returns
/// UTF-8 encoded bytes.
BodyBytes _encodeString(String body) {
  return Uint8List.fromList(utf8.encode(body));
}