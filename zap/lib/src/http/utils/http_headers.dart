// ignore_for_file: constant_identifier_names

/// {@template http_headers}
/// Headers for HTTP requests and responses.
///
/// In some situations, headers are immutable:
///
/// * [HttpRequest] and [HttpClientResponse] always have immutable headers.
///
/// * [HttpResponse] and [HttpClientRequest] have immutable headers
///   from the moment the body is written to.
///
/// In these situations, the mutating methods throw exceptions.
///
/// For all operations on HTTP headers the header name is
/// case-insensitive.
///
/// ## Setting headers
/// To set the value of a header use the `set()` method:
///
///     request.headers.set(HttpHeaders.cacheControlHeader,
///                         'max-age=3600, must-revalidate');
///
/// ## Retrieving headers
/// To retrieve the value of a header use the `value()` method:
///
///     print(request.headers.value(HttpHeaders.userAgentHeader));
///
/// An `HttpHeaders` object holds a list of values for each name
/// as the standard allows. In most cases a name holds only a single value.
/// The most common mode of operation is to use `set()` for setting a value,
/// and `value()` for retrieving a value.
///
/// ## Categories
/// Headers are organized into categories:
/// - **General**: Cache-Control, Connection, Date, etc.
/// - **Entity**: Content-Type, Content-Length, etc.
/// - **Request**: Accept, Authorization, User-Agent, etc.
/// - **Response**: ETag, Location, Set-Cookie, etc.
/// - **CORS**: Access-Control-Allow-Origin, etc.
/// - **Custom**: X-Custom headers for application-specific use.
/// 
/// {@endtemplate}
abstract interface class HttpHeaders {
  /// The `accept` header.
  /// 
  /// Used to specify the types of content that the client is able to process.
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.ACCEPT, 'application/json');
  /// ```
  static const String ACCEPT = "accept";

  /// The `accept-charset` header.
  /// 
  /// Used to specify the character encodings that the client is able to process.
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.ACCEPT_CHARSET, 'utf-8');
  /// ```
  static const String ACCEPT_CHARSET = "accept-charset";

  /// The `accept-encoding` header.
  /// 
  /// Used to specify the encoding that the client is able to process.
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.ACCEPT_ENCODING, 'gzip, deflate');
  /// ```
  static const String ACCEPT_ENCODING = "accept-encoding";

  /// The `accept-language` header.
  /// 
  /// Used to specify the language that the client is able to process.
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.ACCEPT_LANGUAGE, 'en-US');
  /// ```
  static const String ACCEPT_LANGUAGE = "accept-language";

  /// The `accept-ranges` header.
  /// 
  /// Used to specify the range that the client is able to process.
  static const String ACCEPT_RANGES = "accept-ranges";

  /// The `access-control-allow-credentials` header.
  /// 
  /// Indicates whether the response to the request can be exposed when the
  /// credentials flag is true.
  static const String ACCESS_CONTROL_ALLOW_CREDENTIALS = 'access-control-allow-credentials';

  /// The `access-control-allow-headers` header.
  /// 
  /// Indicates which HTTP headers can be used during the actual request.
  static const String ACCESS_CONTROL_ALLOW_HEADERS = 'access-control-allow-headers';

  /// The `access-control-allow-methods` header.
  /// 
  /// Indicates which HTTP methods are allowed when accessing the resource.
  static const String ACCESS_CONTROL_ALLOW_METHODS = 'access-control-allow-methods';

  /// The `access-control-allow-origin` header.
  /// 
  /// Indicates whether the response can be shared with the requesting code.
  static const String ACCESS_CONTROL_ALLOW_ORIGIN = 'access-control-allow-origin';

  /// The `access-control-expose-headers` header.
  /// 
  /// Indicates which headers can be read by the response.
  static const String ACCESS_CONTROL_EXPOSE_HEADERS = 'access-control-expose-headers';

  /// The `access-control-max-age` header.
  /// 
  /// Indicates how long the results of a preflight request can be cached.
  static const String ACCESS_CONTROL_MAX_AGE = 'access-control-max-age';

  /// The `access-control-request-headers` header.
  /// 
  /// Indicates which headers may be used during the actual request.
  static const String ACCESS_CONTROL_REQUEST_HEADERS = 'access-control-request-headers';

  /// The `access-control-request-method` header.
  /// 
  /// Indicates which HTTP method will be used in the actual request.
  static const String ACCESS_CONTROL_REQUEST_METHOD = 'access-control-request-method';

  /// The `access-control-allow-private-network` header.
  ///
  /// Indicates whether the response to the request can expose the resource
  /// to a private network (non-publicly routable addresses).
  static const String ACCESS_CONTROL_ALLOW_PRIVATE_NETWORK = 'access-control-allow-private-network';

  /// The `origin` header.
  ///
  /// Used in CORS requests to indicate the origin of the request.
  static const String ORIGIN = 'origin';

  /// The `timing-allow-origin` header.
  ///
  /// Indicates whether the resource supports being accessed by timing APIs.
  static const String TIMING_ALLOW_ORIGIN = 'timing-allow-origin';

  /// The `link` header.
  ///
  /// Used to express relationships between the current resource and other resources (e.g., pagination).
  static const String LINK = 'link';

  /// The `retry-after` header (HTTP-date version).
  ///
  /// Commonly used with `429 Too Many Requests` to indicate when to retry.
  static const String RETRY_AFTER = 'retry-after';

  /// The `age` header.
  /// 
  /// Indicates the age of the cached response in seconds.
  static const String AGE = "age";

  /// The `allow` header.
  /// 
  /// Lists the HTTP methods supported by the resource.
  static const String ALLOW = "allow";

  /// The `authorization` header.
  /// 
  /// Contains credentials for authenticating the user agent with the server.
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.AUTHORIZATION, 'Bearer token123');
  /// ```
  static const String AUTHORIZATION = "authorization";

  /// The `cache-control` header.
  /// 
  /// Directs caching mechanisms for requests and responses.
  ///
  /// ## Example
  /// ```dart
  /// response.headers.set(HttpHeaders.CACHE_CONTROL, 'max-age=3600');
  /// ```
  static const String CACHE_CONTROL = "cache-control";

  /// The `connection` header.
  /// 
  /// Controls whether the network connection stays open after the transaction.
  static const String CONNECTION = "connection";

  /// The `content-encoding` header.
  /// 
  /// Specifies the encoding used to compress the response body.
  static const String CONTENT_ENCODING = "content-encoding";

  /// The `content-language` header.
  /// 
  /// Describes the language(s) intended for the audience.
  static const String CONTENT_LANGUAGE = "content-language";

  /// The `content-length` header.
  /// 
  /// Indicates the size of the entity-body in bytes.
  static const String CONTENT_LENGTH = "content-length";

  /// The `content-location` header.
  /// 
  /// Indicates an alternative location for the returned data.
  static const String CONTENT_LOCATION = "content-location";

  /// The `content-md5` header.
  /// 
  /// A base64-encoded MD5 digest of the response body.
  static const String CONTENT_MD5 = "content-md5";

  /// The `content-transfer-encoding` header.
  /// 
  /// Specifies the encoding used to transfer the body.
  static const String CONTENT_TRANSFER_ENCODING = 'content-transfer-encoding';

  /// The `content-range` header.
  /// 
  /// Indicates where in a full body message a partial response belongs.
  static const String CONTENT_RANGE = "content-range";

  /// The `content-type` header.
  /// 
  /// Indicates the media type of the resource.
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.CONTENT_TYPE, 'application/json');
  /// ```
  static const String CONTENT_TYPE = "content-type";

  /// The `date` header.
  /// 
  /// The date and time at which the message was originated.
  static const String DATE = "date";

  /// The `etag` header.
  /// 
  /// A validator for caching. Tags a specific version of a resource.
  static const String ETAG = "etag";

  /// The `expect` header.
  /// 
  /// Indicates expectations that need to be fulfilled by the server.
  static const String EXPECT = "expect";

  /// The `expires` header.
  /// 
  /// The date/time after which the response is considered stale.
  static const String EXPIRES = "expires";

  /// The `from` header.
  /// 
  /// Contains the email address of the user making the request.
  static const String FROM = "from";

  /// The `host` header.
  /// 
  /// Specifies the domain name and port number of the server.
  static const String HOST = "host";

  /// The `if-match` header.
  /// 
  /// Makes the request conditional on the server having one of the given ETags.
  static const String IF_MATCH = "if-match";

  /// The `if-modified-since` header.
  /// 
  /// Makes the request conditional on the resource being modified after the given date.
  static const String IF_MODIFIED_SINCE = "if-modified-since";

  /// The `if-none-match` header.
  /// 
  /// Makes the request conditional on the server not having any of the given ETags.
  static const String IF_NONE_MATCH = "if-none-match";

  /// The `if-range` header.
  /// 
  /// Makes the request conditional on the resource having a matching ETag or date.
  static const String IF_RANGE = "if-range";

  /// The `if-unmodified-since` header.
  /// 
  /// Makes the request conditional on the resource not being modified since the given date.
  static const String IF_UNMODIFIED_SINCE = "if-unmodified-since";

  /// The `last-modified` header.
  /// 
  /// The date and time at which the resource was last modified.
  static const String LAST_MODIFIED = "last-modified";

  /// The `location` header.
  /// 
  /// Indicates the URL to redirect to.
  static const String LOCATION = "location";

  /// The `max-forwards` header.
  /// 
  /// Limits the number of proxies or gateways that can forward the request.
  static const String MAX_FORWARDS = "max-forwards";

  /// The `pragma` header.
  /// 
  /// Implements application-specific request directives.
  static const String PRAGMA = "pragma";

  /// The `proxy-authenticate` header.
  /// 
  /// Indicates the authentication scheme for the proxy.
  static const String PROXY_AUTHENTICATE = "proxy-authenticate";

  /// The `proxy-authorization` header.
  /// 
  /// Contains credentials for authenticating with a proxy.
  static const String PROXY_AUTHORIZATION = "proxy-authorization";

  /// The `range` header.
  /// 
  /// Requests only part of the resource (byte serving).
  static const String RANGE = "range";

  /// The `referer` header.
  /// 
  /// The address of the previous web page from which the current request originated.
  static const String REFERER = "referer";

  /// The `server` header.
  /// 
  /// Contains information about the server software.
  static const String SERVER = "server";

  /// The `te` header.
  /// 
  /// Specifies the transfer encodings the user agent is willing to accept.
  static const String TE = "te";

  /// The `trailer` header.
  /// 
  /// Indicates which HTTP headers will be present after the trailer.
  static const String TRAILER = "trailer";

  /// The `transfer-encoding` header.
  /// 
  /// Specifies the encoding used to safely transfer the response body.
  static const String TRANSFER_ENCODING = "transfer-encoding";

  /// The `upgrade` header.
  /// 
  /// Allows switching to a different protocol.
  static const String UPGRADE = "upgrade";

  /// The `user-agent` header.
  /// 
  /// Contains information about the user agent (client software).
  ///
  /// ## Example
  /// ```dart
  /// request.headers.set(HttpHeaders.USER_AGENT, 'MyApp/1.0');
  /// ```
  static const String USER_AGENT = "user-agent";

  /// The `vary` header.
  /// 
  /// Tells caching mechanisms how to match requests to cached responses.
  static const String VARY = "vary";

  /// The `via` header.
  /// 
  /// Indicates intermediate proxies or gateways.
  static const String VIA = "via";

  /// The `warning` header.
  /// 
  /// Contains additional information about the response status.
  static const String WARNING = "warning";

  /// The `www-authenticate` header.
  /// 
  /// Indicates the authentication scheme for the resource.
  static const String WWW_AUTHENTICATE = "www-authenticate";

  /// The `content-disposition` header.
  /// 
  /// Indicates how to display the response content (e.g., inline, attachment).
  ///
  /// ## Example
  /// ```dart
  /// response.headers.set(HttpHeaders.CONTENT_DISPOSITION, 'attachment; filename="file.pdf"');
  /// ```
  static const String CONTENT_DISPOSITION = "content-disposition";

  // Cookie headers from RFC 6265.

  /// The `cookie` header.
  /// 
  /// Contains stored HTTP cookies previously sent by the server.
  static const String COOKIE = "cookie";

  /// The `set-cookie` header.
  /// 
  /// Sends cookies from the server to the user agent.
  static const String SET_COOKIE = "set-cookie";

  /// The `x-content-type-options` header.
  ///
  /// Prevents MIME sniffing. Commonly set to `nosniff`.
  static const String X_CONTENT_TYPE_OPTIONS = 'x-content-type-options';

  /// The `x-frame-options` header.
  ///
  /// Indicates whether a browser should be allowed to render a page in a frame,
  /// iframe, embed, or object.
  static const String X_FRAME_OPTIONS = 'x-frame-options';

  /// The `x-xss-protection` header.
  ///
  /// Enables or disables the browser's XSS protection.
  static const String X_XSS_PROTECTION = 'x-xss-protection';

  /// The `x-requested-with` header.
  ///
  /// Commonly used to identify Ajax requests. Most JavaScript frameworks send
  /// this field with value `XMLHttpRequest`.
  static const String X_REQUESTED_WITH = 'x-requested-with';

  /// The `x-forwarded-for` header.
  ///
  /// Identifies the originating IP address of a client connecting through a proxy.
  static const String X_FORWARDED_FOR = 'x-forwarded-for';

  /// The `x-forwarded-host` header.
  ///
  /// Identifies the original host requested by the client in the `Host` header.
  static const String X_FORWARDED_HOST = 'x-forwarded-host';

  /// The `x-forwarded-proto` header.
  ///
  /// Identifies the protocol (HTTP or HTTPS) that a client used to connect.
  static const String X_FORWARDED_PROTO = 'x-forwarded-proto';

  /// The `x-real-ip` header.
  ///
  /// Used to pass the real IP address of the client when behind a reverse proxy.
  static const String X_REAL_IP = 'x-real-ip';

  /// The `x-cancelled` header.
  ///
  /// Indicates that the request was cancelled by the client.
  static const String X_CANCELLED = "x-cancelled";

  /// The `x-unexpected-error` header.
  ///
  /// Indicates an unexpected error occurred during request processing.
  static const String X_UNEXPECTED_ERROR = "x-unexpected-error";

  /// The `x-content-error` header.
  ///
  /// Indicates an error in the request content (e.g., parsing failure).
  static const String X_CONTENT_ERROR = "x-content-error";

  /// The `x-dns-error` header.
  ///
  /// Indicates a DNS resolution error.
  static const String X_DNS_ERROR = "x-dns-error";

  /// The `x-retry-after` header.
  ///
  /// Suggested time to wait before retrying the request.
  static const String X_RETRY_AFTER = "x-retry-after";

  /// The `x-security-error` header.
  ///
  /// Indicates a security-related error (e.g., SSL/TLS failure).
  static const String X_SECURITY_ERROR = "x-security-error";

  /// The `x-auth-required` header.
  ///
  /// Indicates that authentication is required for the request.
  static const String X_AUTH_REQUIRED = "x-auth-required";

  /// The `x-status-code` header.
  ///
  /// Contains the original status code from the upstream response.
  static const String X_STATUS_CODE = "x-status-code";

  /// The `x-error-type` header.
  ///
  /// Categorizes the type of error that occurred.
  static const String X_ERROR_TYPE = "x-error-type";

  /// The general headers.
  ///
  /// General headers are used in both requests and responses.
  /// They apply to the message as a whole, not to the resource.
  static const List<String> GENERAL = [
    CACHE_CONTROL,
    CONNECTION,
    DATE,
    PRAGMA,
    TRAILER,
    TRANSFER_ENCODING,
    UPGRADE,
    VIA,
    WARNING
  ];

  /// The entity headers.
  ///
  /// Entity headers describe the content of the message body.
  static const List<String> ENTITY = [
    ALLOW,
    CONTENT_ENCODING,
    CONTENT_LANGUAGE,
    CONTENT_LENGTH,
    CONTENT_LOCATION,
    CONTENT_MD5,
    CONTENT_RANGE,
    CONTENT_TYPE,
    EXPIRES,
    LAST_MODIFIED
  ];

  /// The response headers.
  ///
  /// Response headers provide additional information about the response.
  static const List<String> RESPONSE = [
    ACCEPT_RANGES,
    AGE,
    ETAG,
    LOCATION,
    PROXY_AUTHENTICATE,
    RETRY_AFTER,
    SERVER,
    VARY,
    WWW_AUTHENTICATE,
    CONTENT_DISPOSITION
  ];

  /// The request headers.
  ///
  /// Request headers provide additional information about the request.
  static const List<String> REQUEST = [
    ACCEPT,
    ACCEPT_CHARSET,
    ACCEPT_ENCODING,
    ACCEPT_LANGUAGE,
    AUTHORIZATION,
    EXPECT,
    FROM,
    HOST,
    IF_MATCH,
    IF_MODIFIED_SINCE,
    IF_NONE_MATCH,
    IF_RANGE,
    IF_UNMODIFIED_SINCE,
    MAX_FORWARDS,
    PROXY_AUTHORIZATION,
    RANGE,
    REFERER,
    TE,
    USER_AGENT
  ];

  /// The date specified by the `Date` header, if any.
  DateTime? date;

  /// The date and time specified by the `Expires` header, if any.
  DateTime? expires;

  /// The date and time specified by the `If-Modified-Since` header, if any.
  DateTime? ifModifiedSince;

  /// The value of the `Host` header, if any.
  String? host;

  /// The value of the port part of the `Host` header, if any.
  int? port;

  /// The value of the `Content-Length` header, if any.
  ///
  /// The value is negative if there is no content length set.
  int contentLength = -1;

  /// Whether the connection is persistent (keep-alive).
  late bool persistentConnection;

  /// Whether the connection uses chunked transfer encoding.
  ///
  /// Reflects and modifies the value of the `Transfer-Encoding` header.
  late bool chunkedTransferEncoding;

  /// The values for the header named [name].
  ///
  /// Returns null if there is no header with the provided name,
  /// otherwise returns a new list containing the current values.
  /// Note that modifying the list does not change the header.
  List<String>? operator [](String name);

  /// Convenience method for the value for a single valued header.
  ///
  /// The value must not have more than one value.
  ///
  /// Returns `null` if there is no header with the provided name.
  String? value(String name);

  /// Adds a header value.
  ///
  /// The header named [name] will have a string value derived from [value]
  /// added to its list of values.
  ///
  /// Some headers are single valued, and for these, adding a value will
  /// replace a previous value. If the [value] is a [DateTime], an
  /// HTTP date format will be applied. If the value is an [Iterable],
  /// each element will be added separately. For all other
  /// types the default [Object.toString] method will be used.
  ///
  /// Header names are converted to lower-case unless
  /// [preserveHeaderCase] is set to true. If two header names are
  /// the same when converted to lower-case, they are considered to be
  /// the same header, with one set of values.
  ///
  /// The current case of the a header name is that of the name used by
  /// the last [set] or [add] call for that header.
  void add(String name, Object value, {bool preserveHeaderCase = false});

  /// Sets the header [name] to [value].
  ///
  /// Removes all existing values for the header named [name] and
  /// then [add]s [value] to it.
  void set(String name, Object value, {bool preserveHeaderCase = false});

  /// Removes a specific value for a header name.
  ///
  /// Some headers have system supplied values which cannot be removed.
  /// For all other headers and values, the [value] is converted to a string
  /// in the same way as for [add], then that string value is removed from the
  /// current values of [name].
  /// If there are no remaining values for [name], the header is no longer
  /// considered present.
  void remove(String name, Object value);

  /// Removes all values for the specified header name.
  ///
  /// Some headers have system supplied values which cannot be removed.
  /// All other values for [name] are removed.
  /// If there are no remaining values for [name], the header is no longer
  /// considered present.
  void removeAll(String name);

  /// Performs the [action] on each header.
  ///
  /// The [action] function is called with each header's name and a list
  /// of the header's values. The casing of the name string is determined by
  /// the last [add] or [set] operation for that particular header,
  /// which defaults to lower-casing the header name unless explicitly
  /// set to preserve the case.
  void forEach(void Function(String name, List<String> values) action);

  /// Disables folding for the header named [name] when sending the HTTP header.
  ///
  /// By default, multiple header values are folded into a
  /// single header line by separating the values with commas.
  ///
  /// The 'set-cookie' header has folding disabled by default.
  void noFolding(String name);

  /// Removes all headers.
  ///
  /// Some headers have system supplied values which cannot be removed.
  /// All other header values are removed, and header names with not
  /// remaining values are no longer considered present.
  void clear();
}