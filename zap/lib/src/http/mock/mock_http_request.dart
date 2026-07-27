import '../interface/http_request_interface.dart';
import '../request/request.dart';
import '../response/helpers.dart';
import '../response/response.dart';
import '../utils/body_decoder.dart';
import '../utils/http_headers.dart';

/// {@template mock_http_request_handler}
/// A handler for [MockHttpRequest].
///
/// This function receives a [Request] and returns a [Response] that will
/// be used as the mock response. It allows customizing the response
/// behavior for testing.
///
/// ## Parameters
/// - [request]: The request being sent.
///
/// ## Returns
/// A [Future<Response>] that will be used as the mock response.
///
/// ## Example
/// ```dart
/// MockHttpRequestHandler handler = (request) async {
///   return Response(
///     status: HttpStatus.OK,
///     body: {'message': 'Hello, World!'},
///     headers: {'content-type': 'application/json'},
///   );
/// };
/// ```
/// {@endtemplate}
typedef MockHttpRequestHandler = Future<Response> Function(Request request);

/// {@template mock_http_request}
/// A mock implementation of [HttpRequestInterface] for testing purposes.
///
/// This class allows you to simulate HTTP responses without making actual
/// network requests. It uses a handler function that receives requests and
/// returns mock responses.
///
/// ## Usage
/// ```dart
/// final mockClient = MockHttpRequest((request) async {
///   if (request.url.path == '/users') {
///     return Response(
///       status: HttpStatus.OK,
///       body: [{'id': 1, 'name': 'John'}],
///     );
///   }
///   return Response(status: HttpStatus.NOT_FOUND);
/// });
///
/// final client = ZapClient(customClient: mockClient);
/// final response = await client.get('/users');
/// ```
///
/// ## Edge cases
/// - The [close] method is a no-op and can be called safely.
/// - The handler is called synchronously for each request.
/// - Response body decoding uses the same logic as real implementations.
/// {@endtemplate}
class MockHttpRequest extends HttpRequestInterface {
  /// The handler that transforms requests into responses.
  final MockHttpRequestHandler _handler;

  /// Creates a [MockHttpRequest] with the given handler.
  ///
  /// ## Parameters
  /// - [handler]: A function that receives requests and returns responses.
  ///
  /// ## Example
  /// ```dart
  /// final mock = MockHttpRequest((request) async {
  ///   return Response(status: HttpStatus.OK, body: 'OK');
  /// });
  /// ```
  /// {@macro mock_http_request}
  MockHttpRequest(this._handler);

  /// Sends a mock request and returns the response.
  ///
  /// The request body bytes are converted to a stream, then the handler
  /// is called with the request. The handler's response is processed
  /// through the standard body decoding pipeline.
  ///
  /// ## Parameters
  /// - [request]: The request to mock.
  ///
  /// ## Returns
  /// A [Response] of type [T] from the handler.
  ///
  /// ## Throws
  /// Any exception thrown by the handler will propagate.
  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    var requestBody = await request.bodyBytes.toBytes();
    var bodyBytes = requestBody.toStream();

    var response = await _handler(request);

    final stringBody = await bodyBytesToString(bodyBytes, response.headers!);

    var mimeType = response.headers!.containsKey(HttpHeaders.CONTENT_TYPE)
        ? response.headers![HttpHeaders.CONTENT_TYPE]
        : '';

    final body = bodyDecoded<T>(request, stringBody, mimeType);

    return Response(
      headers: response.headers,
      request: request,
      status: response.status,
      message: response.message,
      bodyBytes: bodyBytes,
      body: body,
      bodyString: stringBody,
      provider: response.provider,
    );
  }

  /// Closes the mock client. This is a no-op for testing convenience.
  @override
  void close() {}
}