part of 'zap_client.dart';

/// {@template client_handler}
/// This class is used to handle HTTP requests and responses.
/// It provides a high-level interface for making HTTP requests and handling responses.
///
/// [ClientHandler] is an internal class that orchestrates request building,
/// response processing, authentication retries, and exception handling.
/// It is not intended to be used directly by consumers of the library.
///
/// ## Responsibilities
/// - Building [Uri] objects from base URLs and paths
/// - Constructing [Request] objects with appropriate headers and body
/// - Performing requests with authentication retry logic
/// - Converting exceptions to structured error responses
///
/// ## Edge cases
/// - If [baseUrl] is set and the provided URL is absolute, the absolute URL takes precedence.
/// - If [sendContentLength] is `true`, the `Content-Length` header is set automatically.
/// - If [errorSafety] is `true`, exceptions are caught and returned as error responses.
/// {@endtemplate}
class ClientHandler {
  /// The base URL for all requests.
  ///
  /// If non-null, all relative URLs passed to [createUri] will be resolved
  /// against this base. If `null`, URLs must be absolute.
  ///
  /// ## Example
  /// ```dart
  /// // baseUrl = 'https://api.example.com'
  /// // url = '/users' -> 'https://api.example.com/users'
  /// ```
  final String? baseUrl;
  
  /// Whether to send the user agent in the request headers.
  ///
  /// If `true`, the [userAgent] string will be included as the `User-Agent`
  /// header in all outgoing requests.
  final bool sendUserAgent;
  
  /// Whether to send the content length in the request headers.
  ///
  /// If `true`, the `Content-Length` header will be automatically calculated
  /// and included in requests with a body.
  final bool sendContentLength;
  
  /// The user agent to send in the request headers.
  ///
  /// Only sent if [sendUserAgent] is `true`. Defaults to `'hapx-client'`.
  final String userAgent;
  
  /// The default content type to send in the request headers.
  ///
  /// Used when no explicit content type is provided in the request.
  /// Defaults to `'application/json; charset=utf-8'`.
  final String defaultContentType;
  
  /// The timeout for the request.
  ///
  /// Applied to both connection and request phases. If `null`, no timeout
  /// is enforced.
  final Duration timeout;
  
  /// Whether to enable error safety.
  ///
  /// If `true`, exceptions are caught and returned as error responses.
  /// If `false`, exceptions are rethrown to the caller.
  final bool errorSafety;
  
  /// The maximum number of authentication retries.
  ///
  /// When a 401 response is received and an authenticator is configured,
  /// the request is retried up to this many times.
  final int maxAuthRetries;
  
  /// The maximum number of redirects to follow.
  ///
  /// If the redirect limit is exceeded, a [ZapException] is thrown.
  final int maxRedirects;
  
  /// Whether to follow redirects.
  ///
  /// If `false`, 3xx responses are returned as-is.
  final bool followRedirects;
  
  /// The proxy finder callback.
  ///
  /// If non-null, used to determine the proxy server for each request.
  final ProxyFinder? findProxy;
  
  /// The modifier for request and response transformations.
  ///
  /// Applied to all requests and responses passing through this handler.
  final ZapModifier modifier;
  
  /// The controller advice callback.
  ///
  /// If non-null, exceptions are reported to this callback before being
  /// converted to error responses.
  final ControllerAdvice? controllerAdvice;
  
  /// The HTTP client interface used to send requests.
  final HttpRequestInterface client;
  
  /// The default decoder for response bodies.
  ///
  /// Used when no per-request decoder is provided.
  final ResponseDecoder? defaultDecoder;
  
  /// The default response interceptor.
  ///
  /// Applied to all responses unless a per-request interceptor overrides it.
  final ResponseInterceptor? defaultResponseInterceptor;

  /// Creates a new [ClientHandler] with the specified configuration.
  ///
  /// ## Parameters
  /// - [baseUrl]: Optional base URL for resolving relative paths.
  /// - [sendUserAgent]: Whether to include the User-Agent header.
  /// - [sendContentLength]: Whether to include the Content-Length header.
  /// - [userAgent]: The User-Agent string to send.
  /// - [defaultContentType]: The default Content-Type for requests.
  /// - [timeout]: The request timeout duration.
  /// - [errorSafety]: Whether to catch errors internally.
  /// - [maxAuthRetries]: Maximum authentication retry attempts.
  /// - [maxRedirects]: Maximum redirect attempts.
  /// - [followRedirects]: Whether to follow HTTP redirects.
  /// - [findProxy]: Optional proxy finder callback.
  /// - [modifier]: The request/response modifier.
  /// - [controllerAdvice]: Optional controller advice callback.
  /// - [client]: The HTTP client interface.
  /// - [defaultDecoder]: Optional default response decoder.
  /// - [defaultResponseInterceptor]: Optional default response interceptor.
  ///
  /// {@macro client_handler}
  ClientHandler({
    this.baseUrl,
    this.sendUserAgent = false,
    this.sendContentLength = true,
    this.userAgent = Constants.DEFAULT_USER_AGENT,
    this.defaultContentType = Constants.DEFAULT_CONTENT_TYPE,
    this.timeout = const Duration(seconds: 8),
    this.errorSafety = true,
    this.maxAuthRetries = 1,
    this.maxRedirects = 5,
    this.followRedirects = true,
    this.findProxy,
    required this.modifier,
    this.controllerAdvice,
    required this.client,
    this.defaultDecoder,
    this.defaultResponseInterceptor,
  });
  
  /// Builds a fully qualified [Uri] from a path and optional query parameters.
  ///
  /// If [baseUrl] is set, the path will be appended to it. Otherwise,
  /// the path must be a full URL.
  ///
  /// ## Parameters
  /// - [url]: A relative or absolute URL string.
  /// - [query]: An optional map of query parameters. Values are converted
  ///   to strings. If a value is a `List`, elements are joined with commas.
  ///
  /// ## Returns
  /// A fully resolved [Uri].
  ///
  /// ## Throws
  /// - [FormatException] if [url] is not a valid URI.
  ///
  /// ## Example
  /// ```dart
  /// final handler = ClientHandler(baseUrl: 'https://api.example.com');
  /// final uri = handler.createUri('/users', {'page': '1', 'sort': 'name'});
  /// // uri = Uri.parse('https://api.example.com/users?page=1&sort=name')
  /// ```
  ///
  /// ## Edge cases
  /// - If [query] is `null`, no query parameters are added.
  /// - List values in [query] are joined with commas by default.
  Uri createUri(String? url, RequestParam? query) {
    if (baseUrl != null) {
      url = baseUrl! + url!;
    }
    
    final uri = Uri.parse(url!);
    if (query != null) {
      // Convert all query parameter values to strings
      final stringQuery = query.map((key, value) {
        if (value is List) {
          // Convert list to comma-separated string or bracket notation
          return MapEntry(key, value.map((e) => e.toString()).join(','));
          // Alternative bracket notation: return MapEntry(key, '[${value.map((e) => e.toString()).join(',')}]');
        } else {
          return MapEntry(key, value.toString());
        }
      });
      return uri.replace(queryParameters: stringQuery);
    }

    return uri;
  }
}