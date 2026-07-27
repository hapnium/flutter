import '../definitions.dart';
import '../models/response/api_response.dart';
import '../models/cancel_token.dart';
import '../http/response/response.dart';

/// {@template flux_interface}
/// Abstract interface defining the contract for Flux HTTP operations.
///
/// `FluxInterface` ensures consistent method signatures across different
/// implementations of the Flux client. It provides a unified API for
/// making HTTP requests with built-in authentication, session management,
/// and standardized response handling.
///
/// ### Key differences from ZapInterface
///
/// While [ZapInterface] provides raw HTTP operations, `FluxInterface`
/// operates at a higher level:
///
/// | Feature | ZapInterface | FluxInterface |
/// |---------|--------------|---------------|
/// | Response type | `Response<T>` | `Response<ApiResponse>` |
/// | Authentication | Manual | Automatic (configurable) |
/// | Error handling | Throws exceptions | Returns structured responses |
/// | Session management | None | Built-in refresh and rotation |
/// | Endpoint style | Full URL | Relative path |
///
/// ### Example
///
/// ```dart
/// class MyApiService implements FluxInterface {
///   @override
///   Future<Response<ApiResponse>> get({
///     required String endpoint,
///     RequestParam? query,
///     bool useAuth = true,
///     CancelToken? token,
///   }) async {
///     // Implementation
///   }
///   // ... implement other methods
/// }
/// ```
///
/// ### Usage
///
/// Most consumers use the [Flux] class which implements this interface.
/// You would only implement this interface directly if you need a
/// custom Flux-like client with different behavior.
/// {@endtemplate}
abstract class FluxInterface {
  /// {@template flux_interface_get}
  /// Performs an HTTP GET request.
  ///
  /// Sends a GET request to the specified [endpoint] and returns a
  /// standardized [Response<ApiResponse]> containing the parsed result.
  ///
  /// ### Parameters
  ///
  /// - [endpoint]: The API endpoint path (e.g., `'/users/1'`). This is
  ///   resolved against the base URL from [FluxConfig.zapConfig].
  /// - [query]: Optional query parameters appended to the URL.
  /// - [useAuth]: Whether to include authentication headers. Defaults
  ///   to `true`. Set to `false` for public endpoints.
  /// - [token]: Optional [CancelToken] to cancel the request.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing:
  /// - `status`: HTTP status code
  /// - `body`: [ApiResponse] with status, code, message, and data
  /// - `headers`: Response headers
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await flux.get(
  ///   endpoint: '/users/profile',
  ///   query: {'fields': 'name,email'},
  /// );
  ///
  /// if (response.body?.isOk == true) {
  ///   final user = response.body!.data;
  /// }
  /// ```
  ///
  /// ### Authentication
  ///
  /// By default, authentication headers are included. To make an
  /// unauthenticated request:
  /// ```dart
  /// final response = await flux.get(
  ///   endpoint: '/public/data',
  ///   useAuth: false,
  /// );
  /// ```
  /// {@endtemplate}
  Future<Response<ApiResponse>> get({required String endpoint, RequestParam? query, bool useAuth = true, CancelToken? token});

  /// {@template flux_interface_post}
  /// Performs an HTTP POST request.
  ///
  /// Sends a POST request to the specified [endpoint] with the given
  /// [body] and returns a standardized [Response<ApiResponse]>.
  ///
  /// ### Parameters
  ///
  /// - [endpoint]: The API endpoint path.
  /// - [body]: The request body data. Can be a `Map`, `String`, `List`,
  ///   or any serializable object.
  /// - [query]: Optional query parameters.
  /// - [onProgress]: Optional callback for upload progress tracking.
  ///   Called periodically with the number of bytes uploaded.
  /// - [useAuth]: Whether to include authentication headers. Defaults
  ///   to `true`.
  /// - [token]: Optional [CancelToken] to cancel the request.
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing the server response.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await flux.post(
  ///   endpoint: '/users',
  ///   body: {
  ///     'name': 'John Doe',
  ///     'email': 'john@example.com',
  ///   },
  /// );
  ///
  /// if (response.body?.isCreated == true) {
  ///   _showSuccess('User created');
  /// }
  /// ```
  ///
  /// ### File upload with progress
  ///
  /// ```dart
  /// final response = await flux.post(
  ///   endpoint: '/upload',
  ///   body: fileBytes,
  ///   onProgress: (uploaded) {
  ///     setState(() => _progress = uploaded);
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  Future<Response<ApiResponse>> post({
    required String endpoint,
    RequestBody body,
    RequestParam? query,
    Progress? onProgress,
    bool useAuth = true,
    CancelToken? token,
  });

  /// {@template flux_interface_put}
  /// Performs an HTTP PUT request.
  ///
  /// Sends a PUT request to the specified [endpoint] with the given
  /// [body]. PUT is typically used for full resource replacement.
  ///
  /// ### Parameters
  ///
  /// - [endpoint]: The API endpoint path.
  /// - [body]: The request body (entire resource representation).
  /// - [query]: Optional query parameters.
  /// - [onProgress]: Optional upload progress callback.
  /// - [useAuth]: Whether to include authentication headers. Defaults
  ///   to `true`.
  /// - [token]: Optional [CancelToken].
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing the server response.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await flux.put(
  ///   endpoint: '/users/1',
  ///   body: {
  ///     'name': 'Jane Doe',
  ///     'email': 'jane@example.com',
  ///   },
  /// );
  /// ```
  ///
  /// ### PUT vs PATCH
  ///
  /// - **PUT**: Replaces the entire resource. All fields must be provided.
  /// - **PATCH**: Partially updates the resource. Only changed fields.
  /// {@endtemplate}
  Future<Response<ApiResponse>> put({
    required String endpoint,
    RequestBody body,
    RequestParam? query,
    Progress? onProgress,
    bool useAuth = true,
    CancelToken? token,
  });

  /// {@template flux_interface_patch}
  /// Performs an HTTP PATCH request.
  ///
  /// Sends a PATCH request to the specified [endpoint] with the given
  /// [body]. PATCH is typically used for partial resource updates.
  ///
  /// ### Parameters
  ///
  /// - [endpoint]: The API endpoint path.
  /// - [body]: The partial update data (only changed fields).
  /// - [query]: Optional query parameters.
  /// - [onProgress]: Optional upload progress callback.
  /// - [useAuth]: Whether to include authentication headers. Defaults
  ///   to `true`.
  /// - [token]: Optional [CancelToken].
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing the server response.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await flux.patch(
  ///   endpoint: '/users/1',
  ///   body: {'email': 'newemail@example.com'},
  /// );
  /// ```
  ///
  /// ### PUT vs PATCH
  ///
  /// - **PUT**: Replaces the entire resource.
  /// - **PATCH**: Partially updates (only changed fields).
  /// {@endtemplate}
  Future<Response<ApiResponse>> patch({
    required String endpoint,
    RequestBody body,
    RequestParam? query,
    Progress? onProgress,
    bool useAuth = true,
    CancelToken? token,
  });

  /// {@template flux_interface_delete}
  /// Performs an HTTP DELETE request.
  ///
  /// Sends a DELETE request to the specified [endpoint] to remove a
  /// resource.
  ///
  /// ### Parameters
  ///
  /// - [endpoint]: The API endpoint path of the resource to delete.
  /// - [query]: Optional query parameters.
  /// - [body]: Optional request body. Some APIs accept a body for
  ///   delete operations (e.g., bulk delete).
  /// - [useAuth]: Whether to include authentication headers. Defaults
  ///   to `true`.
  /// - [token]: Optional [CancelToken].
  ///
  /// ### Returns
  ///
  /// A `Future<Response<ApiResponse>>` containing the server response.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final response = await flux.delete(
  ///   endpoint: '/users/1',
  /// );
  ///
  /// if (response.body?.isOk == true) {
  ///   _showSuccess('User deleted');
  /// }
  /// ```
  ///
  /// ### Soft delete
  ///
  /// Some APIs implement soft delete (marking as deleted without
  /// removing). In that case, use PATCH instead:
  /// ```dart
  /// await flux.patch(
  ///   endpoint: '/users/1',
  ///   body: {'deleted': true},
  /// );
  /// ```
  /// {@endtemplate}
  Future<Response<ApiResponse>> delete({required String endpoint, RequestParam? query, RequestBody body, bool useAuth = true, CancelToken? token});
}