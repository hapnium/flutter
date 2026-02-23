part of 'zap_client.dart';

extension ClientHandlerExtension on ClientHandler {
  ControllerAdvice get _adviser => controllerAdvice ?? ControllerAdvice();

  /// Create a request with body (optimized for async FormData)
  /// 
  /// This method is used to create a request with a body, which is useful for
  /// making HTTP requests with a body, such as POST or PUT requests.
  /// 
  /// Parameters:
  /// - [url]: The target endpoint.
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [body]: The body payload for the request.
  /// - [method]: HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  /// 
  /// Returns:
  ///   A [Request] of type [T] representing the server's reply.
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
      if (!errorSafety) {
        throw ZapException.parsing('Request body cannot be ${body.runtimeType}');
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

  /// Process FormData with proper progress tracking
  Future<BodyByteStream> _processFormDataStreamWithProgress(FormData formData, Progress? uploadProgress, int totalLength) async {
    if (uploadProgress == null) {
      return formData.finalize().cast<List<int>>();
    }

    // Convert FormData to bytes first to ensure we can track progress properly
    final formDataBytes = await formData.toBytes();
    
    // Create chunked stream with progress tracking
    return _trackProgress(formDataBytes, uploadProgress);
  }

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

  /// Process JSON without blocking UI
  Future<BodyBytes> _processJsonAsync(dynamic body) async {
    return await compute(_encodeJson, body);
  }

  /// Process form URL encoded without blocking UI
  Future<BodyBytes> _processFormUrlEncodedAsync(RequestParam body) async {
    return await compute(_encodeFormUrlEncoded, body);
  }

  /// Process string without blocking UI
  Future<BodyBytes> _processStringAsync(String body) async {
    return await compute(_encodeString, body);
  }

  /// Sets simple headers for a request.
  void _setSimpleHeaders(Headers headers, String? contentType) {
    headers[HttpHeaders.CONTENT_TYPE] = contentType ?? defaultContentType;
    if (sendUserAgent) {
      headers[HttpHeaders.USER_AGENT] = userAgent;
    }
  }

  /// Performs a request and returns a response.
  /// 
  /// This method is used to perform a request and returns a response.
  /// 
  /// Parameters:
  /// - [request]: The request to perform.
  /// - [useAuth]: Whether to use authentication.
  /// - [requestNumber]: The number of requests made.
  /// - [headers]: Additional HTTP headers.
  /// 
  /// Returns:
  ///   A [Response] of type [T] representing the server's reply.
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
        return perform<T>(req, useAuth: true, requestNumber: requestNumber + 1, headers: req.headers);
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

  /// Returns a response interceptor.
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
  /// This method is used to create a request with a body, which is useful for
  /// making HTTP requests with a body, such as POST or PUT requests.
  /// 
  /// Parameters:
  /// - [url]: The target endpoint.
  /// - [method]: HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [body]: The body payload for the request.
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [uploadProgress]: Callback for monitoring upload progress.
  /// 
  /// Returns:
  ///   A [Request] of type [T] representing the server's reply.
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
  /// This method is used to create a request without a body, which is useful for
  /// making HTTP requests without a body, such as GET or DELETE requests.
  /// 
  /// Parameters:
  /// - [url]: The target endpoint.
  /// - [method]: HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  /// - [contentType]: MIME type of the request body (defaults to JSON).
  /// - [query]: Query parameters appended to the URL.
  /// - [decoder]: Optional function to parse the response body.
  /// - [responseInterceptor]: Optional hook for inspecting or altering the response.
  /// - [contentLength]: The length of the request body.
  /// - [followRedirects]: Whether to follow redirects.
  /// - [maxRedirects]: The maximum number of redirects to follow.
  /// 
  /// Returns:
  ///   A [Request] of type [T] representing the server's reply.
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
  /// This method is used to handle exceptions and returns appropriate Response objects based on exception type.
  /// 
  /// Parameters:
  /// - [e]: The exception to handle.
  /// - [request]: The request that caused the exception.
  /// 
  /// Returns:
  ///   A [Response] of type [T] representing the server's reply.
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
  /// This method is used to create appropriate Response objects based on ZapException type.
  /// 
  /// Parameters:
  /// - [exception]: The exception to handle.
  /// - [request]: The request that caused the exception.
  /// 
  /// Returns:
  ///   A [Response] of type [T] representing the server's reply.
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

// Isolate functions for compute()
BodyBytes _encodeJson(dynamic body) {
  final jsonString = json.encode(body);
  return Uint8List.fromList(utf8.encode(jsonString));
}

BodyBytes _encodeFormUrlEncoded(RequestParam body) {
  final parts = <String>[];
  body.forEach((key, value) {
    parts.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}');
  });
  final formData = parts.join('&');
  return Uint8List.fromList(utf8.encode(formData));
}

BodyBytes _encodeString(String body) {
  return Uint8List.fromList(utf8.encode(body));
}