// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// {@template http_method}
/// Defines the standard HTTP methods used for network requests.
///
/// Each constant represents an HTTP verb used in RESTful APIs and other
/// HTTP-based communication. These constants provide a type-safe way to
/// reference HTTP methods instead of using raw strings.
///
/// ## Example
/// ```dart
/// final method = HttpMethod.POST;
/// final request = Request(url: uri, method: method, headers: {});
/// ```
///
/// ## Usage notes
/// - All methods are uppercase strings.
/// - Use [FROM] to convert arbitrary method strings to uppercase.
/// - Not all methods are supported by all servers.
/// {@endtemplate}
abstract class HttpMethod {
  /// `GET`
  ///
  /// Retrieves data from the server without modifying it.
  /// - Safe and idempotent.
  /// - Commonly used to fetch lists or individual resources.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.get('/users', query: {'page': '1'});
  /// ```
  static const String GET = 'GET';

  /// `POST`
  ///
  /// Sends data to the server to create a new resource.
  /// - Not idempotent.
  /// - Often used with `application/json` or `multipart/form-data` bodies.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.post('/users', body: {'name': 'John'});
  /// ```
  static const String POST = 'POST';

  /// `PUT`
  ///
  /// Updates or replaces a resource at a specific URI.
  /// - Idempotent (repeating the request has the same effect).
  /// - Usually replaces the entire resource.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.put('/users/123', body: {'name': 'Updated'});
  /// ```
  static const String PUT = 'PUT';

  /// `DELETE`
  ///
  /// Removes a resource identified by a URI.
  /// - Idempotent.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.delete('/users/123');
  /// ```
  static const String DELETE = 'DELETE';

  /// `PATCH`
  ///
  /// Applies partial modifications to a resource.
  /// - Not necessarily idempotent.
  /// - Typically used to update only the changed fields.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.patch('/users/123', body: {'name': 'New Name'});
  /// ```
  static const String PATCH = 'PATCH';

  /// `HEAD`
  ///
  /// Retrieves headers for a resource without the body.
  /// - Safe and idempotent.
  /// - Useful for checking resource availability or metadata.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.request('/users', 'HEAD');
  /// print(response.status.code); // 200 if exists, 404 if not
  /// ```
  static const String HEAD = 'HEAD';

  /// `OPTIONS`
  ///
  /// Retrieves the HTTP methods supported by the server for a specific resource.
  /// - Safe and idempotent.
  /// - Used in CORS preflight requests.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.request('/users', 'OPTIONS');
  /// final allowHeader = response.headers?['allow'];
  /// ```
  static const String OPTIONS = 'OPTIONS';

  /// `TRACE`
  ///
  /// Performs a message loop-back test along the path to the resource.
  /// - Safe and idempotent.
  /// - Useful for debugging proxy connections.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.request('/users', 'TRACE');
  /// ```
  static const String TRACE = 'TRACE';

  /// `CONNECT`
  ///
  /// Establishes a tunnel to the server identified by the resource URI.
  /// - Used for SSL tunneling through proxies.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.request('/proxy', 'CONNECT');
  /// ```
  static const String CONNECT = 'CONNECT';

  /// Converts a string method name to uppercase.
  ///
  /// This is useful when accepting arbitrary method strings and ensuring
  /// they are properly formatted.
  ///
  /// ## Parameters
  /// - [value]: The HTTP method string (e.g., 'get', 'Post').
  ///
  /// ## Returns
  /// The uppercase version of the method string.
  ///
  /// ## Example
  /// ```dart
  /// final method = HttpMethod.FROM('get');
  /// print(method); // 'GET'
  /// ```
  static String FROM(String value) {
    return value.toUpperCase();
  }
}