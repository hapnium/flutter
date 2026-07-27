import 'dart:async';

import '../request/request.dart';
import '../response/response.dart';

/// {@template request_modifier}
/// A request modifier is a function that will be called before the request is sent.
///
/// It receives the current [Request] and returns a modified [Request].
/// This can be used to inject headers, transform URLs, log request data, etc.
///
/// ## Parameters
/// - [request]: The current request to modify.
///
/// ## Returns
/// The modified request, or the original request if no changes are needed.
///
/// ## Example
/// ```dart
/// RequestModifier<String> addAuth = (request) async {
///   final token = await getAuthToken();
///   request.headers['Authorization'] = 'Bearer $token';
///   return request;
/// };
/// ```
/// {@endtemplate}
typedef RequestModifier<T> = FutureOr<Request<T>> Function(Request<T?> request);

/// {@template response_modifier}
/// A response modifier is a function that will be called after the response is received.
///
/// It receives the original [Request] and the received [Response], and returns
/// a modified response. This can be used for logging, response transformation,
/// or centralized error handling.
///
/// ## Parameters
/// - [request]: The request that triggered the response.
/// - [response]: The received response.
///
/// ## Returns
/// The modified response, or the original response if no changes are needed.
///
/// ## Example
/// ```dart
/// ResponseModifier<String> logResponse = (request, response) async {
///   print('${request.method} ${request.url} -> ${response.status}');
///   return response;
/// };
/// ```
/// {@endtemplate}
typedef ResponseModifier<T> = FutureOr Function(Request<T?> request, Response<T?> response);

/// {@template zap_modifier}
/// A class to modify the request and response in the HTTP pipeline.
///
/// [ZapModifier] manages a list of request and response modifiers that are
/// applied in sequence. It also supports an authenticator that is called
/// specifically for authentication retries.
///
/// ## Type Parameters
/// - [S]: The type of the request and response (unused, kept for compatibility).
///
/// ## Example
/// ```dart
/// final modifier = ZapModifier<String>();
/// modifier.addRequestModifier((request) {
///   return request.copyWith(headers: {'Authorization': 'Bearer token'});
/// });
/// modifier.addResponseModifier((request, response) {
///   print('Response: ${response.status}');
///   return response;
/// });
/// ```
///
/// ## Usage notes
/// - Modifiers are applied in the order they are added.
/// - The authenticator is called separately, only on authentication retries.
/// - Removing a modifier that was not added is a no-op.
/// {@endtemplate}
class ZapModifier<S> {
  final _requestModifiers = <RequestModifier>[];
  final _responseModifiers = <ResponseModifier>[];

  /// The authenticator is a request modifier that will be called to authenticate the request.
  ///
  /// This is invoked specifically when a 401 response is received and the
  /// client retries the request with authentication.
  ///
  /// ## Example
  /// ```dart
  /// modifier.authenticator = (request) async {
  ///   final token = await refreshAuthToken();
  ///   request.headers['Authorization'] = 'Bearer $token';
  ///   return request;
  /// };
  /// ```
  RequestModifier? authenticator;

  /// Creates a new [ZapModifier] instance.
  ///
  /// ## Example
  /// ```dart
  /// final modifier = ZapModifier();
  /// ```
  /// {@macro zap_modifier}
  ZapModifier();

  /// Adds a request modifier to the modifier chain.
  ///
  /// Request modifiers are applied in the order they are added.
  ///
  /// ## Type Parameters
  /// - [T]: The type parameter for the modifier.
  ///
  /// ## Parameters
  /// - [interceptor]: The request modifier to add.
  ///
  /// ## Example
  /// ```dart
  /// modifier.addRequestModifier<String>((request) {
  ///   request.headers['X-Custom'] = 'value';
  ///   return request;
  /// });
  /// ```
  void addRequestModifier<T>(RequestModifier<T> interceptor) {
    _requestModifiers.add(interceptor as RequestModifier);
  }

  /// Removes a request modifier from the modifier chain.
  ///
  /// ## Type Parameters
  /// - [T]: The type parameter for the modifier.
  ///
  /// ## Parameters
  /// - [interceptor]: The request modifier to remove.
  ///
  /// ## Example
  /// ```dart
  /// final myModifier = (request) { /* ... */ };
  /// modifier.addRequestModifier(myModifier);
  /// // Later...
  /// modifier.removeRequestModifier(myModifier);
  /// ```
  void removeRequestModifier<T>(RequestModifier<T> interceptor) {
    _requestModifiers.remove(interceptor);
  }

  /// Adds a response modifier to the modifier chain.
  ///
  /// Response modifiers are applied in the order they are added.
  ///
  /// ## Type Parameters
  /// - [T]: The type parameter for the modifier.
  ///
  /// ## Parameters
  /// - [interceptor]: The response modifier to add.
  ///
  /// ## Example
  /// ```dart
  /// modifier.addResponseModifier<String>((request, response) {
  ///   print('Response status: ${response.status}');
  ///   return response;
  /// });
  /// ```
  void addResponseModifier<T>(ResponseModifier<T> interceptor) {
    _responseModifiers.add(interceptor as ResponseModifier);
  }

  /// Removes a response modifier from the modifier chain.
  ///
  /// ## Type Parameters
  /// - [T]: The type parameter for the modifier.
  ///
  /// ## Parameters
  /// - [interceptor]: The response modifier to remove.
  ///
  /// ## Example
  /// ```dart
  /// modifier.removeResponseModifier(myModifier);
  /// ```
  void removeResponseModifier<T>(ResponseModifier<T> interceptor) {
    _responseModifiers.remove(interceptor);
  }

  /// Applies all request modifiers to the given [request].
  ///
  /// Each modifier is called sequentially with the result of the previous one.
  ///
  /// ## Type Parameters
  /// - [T]: The type of the request body.
  ///
  /// ## Parameters
  /// - [request]: The request to modify.
  ///
  /// ## Returns
  /// The fully modified request.
  ///
  /// ## Example
  /// ```dart
  /// final modifiedRequest = await modifier.modifyRequest(originalRequest);
  /// ```
  Future<Request<T>> modifyRequest<T>(Request<T> request) async {
    var newRequest = request;
    if (_requestModifiers.isNotEmpty) {
      for (var interceptor in _requestModifiers) {
        newRequest = await interceptor(newRequest) as Request<T>;
      }
    }

    return newRequest;
  }

  /// Applies all response modifiers to the given [response].
  ///
  /// Each modifier is called sequentially with the result of the previous one.
  ///
  /// ## Type Parameters
  /// - [T]: The type of the response body.
  ///
  /// ## Parameters
  /// - [request]: The request that triggered the response.
  /// - [response]: The response to modify.
  ///
  /// ## Returns
  /// The fully modified response.
  ///
  /// ## Example
  /// ```dart
  /// final modifiedResponse = await modifier.modifyResponse(request, response);
  /// ```
  Future<Response<T>> modifyResponse<T>(Request<T> request, Response<T> response) async {
    var newResponse = response;
    if (_responseModifiers.isNotEmpty) {
      for (var interceptor in _responseModifiers) {
        newResponse = await interceptor(request, newResponse) as Response<T>;
      }
    }

    return newResponse;
  }
}