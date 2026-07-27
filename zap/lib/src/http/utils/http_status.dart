// ignore_for_file: non_constant_identifier_names, constant_identifier_names

/// {@template http_status}
/// A utility class representing HTTP status codes and their interpretation.
///
/// Use this to check common HTTP response conditions like unauthorized access,
/// server errors, or successful responses. It also provides constants for all
/// standard HTTP status codes.
///
/// ## Features
/// - All standard HTTP status codes (1xx through 5xx)
/// - Custom status codes for connection and cancellation errors
/// - Status range checking helpers
/// - JSON serialization support
/// - Equality and hashing based on status code
///
/// ## Example
/// ```dart
/// // Get the status code as a string
/// print(HttpStatus.OK); // Prints "OK"
///
/// // Get the numeric value
/// print(HttpStatus.OK.code); // Prints 200
///
/// // Check if a response has a specific status
/// if (response.statusCode == HttpStatus.OK.code) {
///   // Handle successful response
/// }
/// ```
/// 
/// {@endtemplate}
class HttpStatus {
  /// The HTTP status code. If null, indicates a connection or network error.
  final int code;

  /// The HTTP status name.
  ///
  /// This is a human-readable identifier for the status code.
  final String name;

  /// The HTTP status description.
  ///
  /// This is a detailed description of what the status code means.
  final String description;

  /// Creates a new HTTP status code with the given name, numeric value, and description.
  ///
  /// ## Parameters
  /// - [name]: The status name (e.g., 'OK').
  /// - [code]: The numeric status code (e.g., 200).
  /// - [description]: A human-readable description.
  ///
  /// ## Example
  /// ```dart
  /// final custom = HttpStatus._('CUSTOM', 999, 'Custom status');
  /// ```
  /// 
  /// {@macro http_status}
  const HttpStatus._(this.name, this.code, this.description);

  /// Static map to store all status codes for lookup.
  static final Map<int, HttpStatus> _statusCodes = <int, HttpStatus>{};

  /// Initialize all status codes.
  static void _initializeStatusCodes() {
    if (_statusCodes.isNotEmpty) return;
    
    // Add all predefined status codes to the map
    for (final status in _allStatusCodes) {
      _statusCodes[status.code] = status;
    }
  }

  // --- Informational responses (100–199) ---

  /// 100 Continue – The server has received the request headers and the client should proceed to send the request body.
  /// Used in HTTP/1.1 when the client needs to send a large request body and wants to check if the server will accept it.
  static const HttpStatus CONTINUE = HttpStatus._(
    "CONTINUE",
    100, 
    "The server has received the request headers and the client should proceed to send the request body"
  );

  /// 101 Switching Protocols – The requester has asked the server to switch protocols and the server has agreed to do so.
  /// Commonly used when upgrading from HTTP to WebSocket connections.
  static const HttpStatus SWITCHING_PROTOCOLS = HttpStatus._(
    "SWITCHING_PROTOCOLS",
    101,
    "The requester has asked the server to switch protocols and the server has agreed to do so"
  );

  /// 102 Processing – WebDAV extension indicating that the server has received and is processing the request, but no response is available yet.
  /// This prevents the client from timing out and assuming the request was lost.
  static const HttpStatus PROCESSING = HttpStatus._(
    "PROCESSING",
    102,
    "WebDAV: Server has received and is processing the request, but no response is available yet"
  );

  /// 103 Early Hints – Used to return some response headers before the final HTTP message.
  /// Allows the server to send preliminary response headers while it prepares the full response.
  static const HttpStatus EARLY_HINTS = HttpStatus._(
    "EARLY_HINTS",
    103,
    "Used to return some response headers before the final HTTP message"
  );

  // --- Successful responses (200–299) ---

  /// 200 OK – Standard response for successful HTTP requests. The actual response will depend on the request method used.
  /// GET: The resource has been fetched and transmitted in the message body.
  /// HEAD: The representation headers are included without any message body.
  /// PUT or POST: The resource describing the result of the action is transmitted.
  static const HttpStatus OK = HttpStatus._(
    "OK",
    200,
    "Standard response for successful HTTP requests"
  );

  /// 201 Created – The request has been fulfilled, resulting in the creation of a new resource.
  /// The newly created resource can be referenced by the URI(s) returned in the entity of the response.
  static const HttpStatus CREATED = HttpStatus._(
    "CREATED",
    201,
    "Request has succeeded and a new resource has been created as a result"
  );

  /// 202 Accepted – The request has been accepted for processing, but the processing has not been completed.
  /// The request might or might not be eventually acted upon, and may be disallowed when processing occurs.
  static const HttpStatus ACCEPTED = HttpStatus._(
    "ACCEPTED",
    202,
    "Request accepted for processing, but processing has not been completed"
  );

  /// 203 Non-Authoritative Information – The server is a transforming proxy that received a 200 OK from its origin,
  /// but is returning a modified version of the origin's response.
  static const HttpStatus NON_AUTHORITATIVE_INFORMATION = HttpStatus._(
    "NON_AUTHORITATIVE_INFORMATION",
    203,
    "Server is a transforming proxy returning a modified version of the origin's response"
  );

  /// 204 No Content – The server successfully processed the request and is not returning any content.
  /// This is commonly used for DELETE requests or PUT requests where no response body is needed.
  static const HttpStatus NO_CONTENT = HttpStatus._(
    "NO_CONTENT",
    204,
    "Server successfully processed the request and is not returning any content"
  );

  /// 205 Reset Content – The server successfully processed the request, asks that the requester reset its document view,
  /// and is not returning any content.
  static const HttpStatus RESET_CONTENT = HttpStatus._(
    "RESET_CONTENT",
    205,
    "Server successfully processed the request and asks that the client reset its document view"
  );

  /// 206 Partial Content – The server is delivering only part of the resource due to a range header sent by the client.
  /// Used for resumable downloads and streaming media.
  static const HttpStatus PARTIAL_CONTENT = HttpStatus._(
    "PARTIAL_CONTENT",
    206,
    "Server is delivering only part of the resource due to a range header sent by the client"
  );

  /// 207 Multi-Status – WebDAV extension providing status for multiple independent operations.
  /// The message body contains XML with status information about multiple resources.
  static const HttpStatus MULTI_STATUS = HttpStatus._(
    "MULTI_STATUS",
    207,
    "WebDAV: Conveys information about multiple resources in situations where multiple status codes might be appropriate"
  );

  /// 208 Already Reported – WebDAV extension used to avoid repeatedly enumerating the internal members of multiple bindings
  /// to the same collection.
  static const HttpStatus ALREADY_REPORTED = HttpStatus._(
    "ALREADY_REPORTED",
    208,
    "WebDAV: Members of a DAV binding have already been enumerated in a preceding part of the multistatus response"
  );

  /// 226 IM Used – The server has fulfilled a request for the resource, and the response is a representation of the result
  /// of one or more instance-manipulations applied to the current instance.
  static const HttpStatus IM_USED = HttpStatus._(
    "IM_USED",
    226,
    "Server has fulfilled a request and the response is a representation of instance-manipulations applied to the current instance"
  );

  // --- Redirection messages (300–399) ---

  /// 300 Multiple Choices – Indicates multiple options for the resource from which the client may choose.
  /// The client should select one of the provided alternatives.
  static const HttpStatus MULTIPLE_CHOICES = HttpStatus._(
    "MULTIPLE_CHOICES",
    300,
    "Multiple options for the resource from which the client may choose"
  );

  /// 301 Moved Permanently – This and all future requests should be directed to the given URI.
  /// Search engines will update their indexes to the new URI.
  static const HttpStatus MOVED_PERMANENTLY = HttpStatus._(
    "MOVED_PERMANENTLY",
    301,
    "This and all future requests should be directed to the given URI"
  );

  /// 302 Found – Tells the client to look at (browse to) another URL temporarily.
  /// The original URL should be used for future requests.
  static const HttpStatus FOUND = HttpStatus._(
    "FOUND",
    302,
    "Resource temporarily resides under a different URI"
  );

  /// 302 Moved Temporarily – Legacy alias for 302 Found.
  /// This naming was used in HTTP/1.0 but is now deprecated in favor of "Found".
  static const HttpStatus MOVED_TEMPORARILY = HttpStatus._(
    "MOVED_TEMPORARILY",
    302,
    "Legacy alias for 302 Found - resource temporarily resides under a different URI"
  );

  /// 303 See Other – The response to the request can be found under another URI using the GET method.
  /// Used to redirect after a POST request to prevent duplicate submissions.
  static const HttpStatus SEE_OTHER = HttpStatus._(
    "SEE_OTHER",
    303,
    "Response to the request can be found under another URI using a GET method"
  );

  /// 304 Not Modified – Indicates that the resource has not been modified since the version specified by the request headers.
  /// The client can use its cached version of the resource.
  static const HttpStatus NOT_MODIFIED = HttpStatus._(
    "NOT_MODIFIED",
    304,
    "Resource has not been modified since the version specified by the request headers"
  );

  /// 305 Use Proxy – The requested resource is available only through a proxy, the address for which is provided in the response.
  /// This status code is deprecated due to security concerns.
  static const HttpStatus USE_PROXY = HttpStatus._(
    "USE_PROXY",
    305,
    "Requested resource is available only through a proxy (deprecated due to security concerns)"
  );

  /// 306 Switch Proxy – No longer used. Originally meant "Subsequent requests should use the specified proxy."
  /// This status code is no longer used and is reserved.
  static const HttpStatus SWITCH_PROXY = HttpStatus._(
    "SWITCH_PROXY",
    306,
    "No longer used - originally meant subsequent requests should use the specified proxy"
  );

  /// 307 Temporary Redirect – The request should be repeated with another URI; however, future requests should still use the original URI.
  /// Unlike 302, the request method should not be changed when reissuing the request.
  static const HttpStatus TEMPORARY_REDIRECT = HttpStatus._(
    "TEMPORARY_REDIRECT",
    307,
    "Request should be repeated with another URI but future requests should still use the original URI"
  );

  /// 308 Permanent Redirect – The request and all future requests should be repeated using another URI.
  /// Unlike 301, the request method should not be changed when reissuing the request.
  static const HttpStatus PERMANENT_REDIRECT = HttpStatus._(
    "PERMANENT_REDIRECT",
    308,
    "Request and all future requests should be repeated using another URI with the same method"
  );

  // --- Client error responses (400–499) ---

  /// 400 Bad Request – The server cannot or will not process the request due to an apparent client error.
  /// This includes malformed request syntax, invalid request message framing, or deceptive request routing.
  static const HttpStatus BAD_REQUEST = HttpStatus._(
    "BAD_REQUEST",
    400,
    "Server cannot process the request due to malformed syntax or invalid request"
  );

  /// 401 Unauthorized – Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided.
  /// The response must include a WWW-Authenticate header field.
  static const HttpStatus UNAUTHORIZED = HttpStatus._(
    "UNAUTHORIZED",
    401,
    "Authentication is required and has failed or has not been provided"
  );

  /// 402 Payment Required – Reserved for future use. The original intention was that this code might be used as part of some form of digital cash or micropayment scheme.
  /// Some services use this for rate limiting or subscription requirements.
  static const HttpStatus PAYMENT_REQUIRED = HttpStatus._(
    "PAYMENT_REQUIRED",
    402,
    "Reserved for future use - originally intended for digital cash or micropayment schemes"
  );

  /// 403 Forbidden – The request contained valid data and was understood by the server, but the server is refusing action.
  /// Unlike 401, authenticating will make no difference.
  static const HttpStatus FORBIDDEN = HttpStatus._(
    "FORBIDDEN",
    403,
    "Server understood the request but refuses to authorize it"
  );

  /// 404 Not Found – The requested resource could not be found but may be available in the future.
  /// Subsequent requests by the client are permissible.
  static const HttpStatus NOT_FOUND = HttpStatus._(
    "NOT_FOUND",
    404,
    "Requested resource could not be found but may be available in the future"
  );

  /// 405 Method Not Allowed – A request method is not supported for the requested resource.
  /// The response must include an Allow header containing a list of valid methods.
  static const HttpStatus METHOD_NOT_ALLOWED = HttpStatus._(
    "METHOD_NOT_ALLOWED",
    405,
    "Request method is not supported for the requested resource"
  );

  /// 406 Not Acceptable – The requested resource is capable of generating only content not acceptable according to the Accept headers sent in the request.
  /// The server should generate a list of available representations.
  static const HttpStatus NOT_ACCEPTABLE = HttpStatus._(
    "NOT_ACCEPTABLE",
    406,
    "Requested resource cannot generate content acceptable according to the Accept headers"
  );

  /// 407 Proxy Authentication Required – The client must first authenticate itself with the proxy.
  /// Similar to 401, but authentication is needed with a proxy server.
  static const HttpStatus PROXY_AUTHENTICATION_REQUIRED = HttpStatus._(
    "PROXY_AUTHENTICATION_REQUIRED",
    407,
    "Client must first authenticate itself with the proxy"
  );

  /// 408 Request Timeout – The server timed out waiting for the request.
  /// The client did not produce a request within the time that the server was prepared to wait.
  static const HttpStatus REQUEST_TIMEOUT = HttpStatus._(
    "REQUEST_TIMEOUT",
    408,
    "Server timed out waiting for the request"
  );

  /// 409 Conflict – Indicates that the request could not be processed because of conflict in the current state of the resource.
  /// Often occurs in PUT requests when multiple clients try to update the same resource.
  static const HttpStatus CONFLICT = HttpStatus._(
    "CONFLICT",
    409,
    "Request could not be processed because of conflict in the current state of the resource"
  );

  /// 410 Gone – Indicates that the resource requested is no longer available and will not be available again.
  /// Unlike 404, this condition is expected to be permanent.
  static const HttpStatus GONE = HttpStatus._(
    "GONE",
    410,
    "Resource requested is no longer available and will not be available again"
  );

  /// 411 Length Required – The request did not specify the length of its content, which is required by the requested resource.
  /// The client should add a Content-Length header and resubmit the request.
  static const HttpStatus LENGTH_REQUIRED = HttpStatus._(
    "LENGTH_REQUIRED",
    411,
    "Request did not specify the length of its content, which is required by the requested resource"
  );

  /// 412 Precondition Failed – The server does not meet one of the preconditions that the requester put on the request header fields.
  /// Used with conditional requests using If-Match, If-None-Match, If-Modified-Since, etc.
  static const HttpStatus PRECONDITION_FAILED = HttpStatus._(
    "PRECONDITION_FAILED",
    412,
    "Server does not meet one of the preconditions specified in the request header fields"
  );

  /// 413 Payload Too Large – The request is larger than the server is willing or able to process.
  /// Previously called "Request Entity Too Large".
  static const HttpStatus PAYLOAD_TOO_LARGE = HttpStatus._(
    "PAYLOAD_TOO_LARGE",
    413,
    "Request is larger than the server is willing or able to process"
  );

  /// 414 URI Too Long – The URI provided was too long for the server to process.
  /// Often the result of too much data being encoded as a query-string of a GET request.
  static const HttpStatus URI_TOO_LONG = HttpStatus._(
    "URI_TOO_LONG",
    414,
    "URI provided was too long for the server to process"
  );

  /// 415 Unsupported Media Type – The request entity has a media type which the server or resource does not support.
  /// The client should check the Content-Type header.
  static const HttpStatus UNSUPPORTED_MEDIA_TYPE = HttpStatus._(
    "UNSUPPORTED_MEDIA_TYPE",
    415,
    "Request entity has a media type which the server or resource does not support"
  );

  /// 416 Range Not Satisfiable – The client has asked for a portion of the file (byte serving), but the server cannot supply that portion.
  /// Used when the Range header specifies invalid byte ranges.
  static const HttpStatus RANGE_NOT_SATISFIABLE = HttpStatus._(
    "RANGE_NOT_SATISFIABLE",
    416,
    "Client has asked for a portion of the file that the server cannot supply"
  );

  /// 417 Expectation Failed – The server cannot meet the requirements of the Expect request-header field.
  /// Occurs when the Expect header contains expectations that cannot be met.
  static const HttpStatus EXPECTATION_FAILED = HttpStatus._(
    "EXPECTATION_FAILED",
    417,
    "Server cannot meet the requirements of the Expect request-header field"
  );

  /// 418 I'm a teapot – This code was defined in 1998 as one of the traditional IETF April Fools' jokes.
  /// It is not expected to be implemented by actual HTTP servers, but some do for fun.
  static const HttpStatus IM_A_TEAPOT = HttpStatus._(
    "IM_A_TEAPOT",
    418,
    "This code was defined as an April Fools' joke and indicates the server is a teapot"
  );

  /// 421 Misdirected Request – The request was directed at a server that is not able to produce a response.
  /// Can be sent when a server is not configured to produce responses for the combination of scheme and authority.
  static const HttpStatus MISDIRECTED_REQUEST = HttpStatus._(
    "MISDIRECTED_REQUEST",
    421,
    "Request was directed at a server that is not able to produce a response"
  );

  /// 422 Unprocessable Entity – The request was well-formed but was unable to be followed due to semantic errors.
  /// WebDAV extension indicating that the server understands the content type but cannot process the instructions.
  static const HttpStatus UNPROCESSABLE_ENTITY = HttpStatus._(
    "UNPROCESSABLE_ENTITY",
    422,
    "Request was well-formed but unable to be followed due to semantic errors"
  );

  /// 423 Locked – The resource that is being accessed is locked.
  /// WebDAV extension indicating that the source or destination resource is locked.
  static const HttpStatus LOCKED = HttpStatus._(
    "LOCKED",
    423,
    "WebDAV: Resource that is being accessed is locked"
  );

  /// 424 Failed Dependency – The request failed because it depended on another request and that request failed.
  /// WebDAV extension used when a method could not be performed because it depended on another action that failed.
  static const HttpStatus FAILED_DEPENDENCY = HttpStatus._(
    "FAILED_DEPENDENCY",
    424,
    "WebDAV: Request failed because it depended on another request that failed"
  );

  /// 425 Too Early – Indicates that the server is unwilling to risk processing a request that might be replayed.
  /// Used to prevent replay attacks in early data scenarios.
  static const HttpStatus TOO_EARLY = HttpStatus._(
    "TOO_EARLY",
    425,
    "Server is unwilling to risk processing a request that might be replayed"
  );

  /// 426 Upgrade Required – The client should switch to a different protocol such as TLS/1.3.
  /// The server refuses to perform the request using the current protocol but might be willing to do so after the client upgrades.
  static const HttpStatus UPGRADE_REQUIRED = HttpStatus._(
    "UPGRADE_REQUIRED",
    426,
    "Client should switch to a different protocol such as TLS/1.3"
  );

  /// 428 Precondition Required – The origin server requires the request to be conditional.
  /// Intended to prevent the 'lost update' problem where multiple clients update a resource simultaneously.
  static const HttpStatus PRECONDITION_REQUIRED = HttpStatus._(
    "PRECONDITION_REQUIRED",
    428,
    "Origin server requires the request to be conditional"
  );

  /// 429 Too Many Requests – The user has sent too many requests in a given amount of time ("rate limiting").
  /// The response should include details explaining the condition and may include a Retry-After header.
  static const HttpStatus TOO_MANY_REQUESTS = HttpStatus._(
    "TOO_MANY_REQUESTS",
    429,
    "User has sent too many requests in a given amount of time (rate limiting)"
  );

  /// 431 Request Header Fields Too Large – The server is unwilling to process the request because either an individual header field,
  /// or all the header fields collectively, are too large.
  static const HttpStatus REQUEST_HEADER_FIELDS_TOO_LARGE = HttpStatus._(
    "REQUEST_HEADER_FIELDS_TOO_LARGE",
    431,
    "Server is unwilling to process the request because header fields are too large"
  );

  /// 444 Connection Closed Without Response – A non-standard status code used to instruct nginx to close the connection without sending a response.
  /// Used to close connections from clients sending malicious requests.
  static const HttpStatus CONNECTION_CLOSED_WITHOUT_RESPONSE = HttpStatus._(
    "CONNECTION_CLOSED_WITHOUT_RESPONSE",
    444,
    "Non-standard: Connection closed without sending a response to the client"
  );

  /// 449 Retry With – A Microsoft extension indicating that the request should be retried after performing the appropriate action.
  /// Used by Microsoft's Internet Information Services (IIS).
  static const HttpStatus RETRY_WITH = HttpStatus._(
    "RETRY_WITH",
    449,
    "Microsoft extension: Request should be retried after performing the appropriate action"
  );

  /// 450 Blocked by Windows Parental Controls – A Microsoft extension indicating that Windows Parental Controls are turned on and are blocking access.
  /// Used by Microsoft's family safety features.
  static const HttpStatus BLOCKED_BY_WINDOWS_PARENTAL_CONTROLS = HttpStatus._(
    "BLOCKED_BY_WINDOWS_PARENTAL_CONTROLS",
    450,
    "Microsoft extension: Windows Parental Controls are blocking access to the requested resource"
  );

  /// 451 Unavailable For Legal Reasons – A server operator has received a legal demand to deny access to a resource or to a set of resources.
  /// Named after the novel Fahrenheit 451 by Ray Bradbury.
  static const HttpStatus UNAVAILABLE_FOR_LEGAL_REASONS = HttpStatus._(
    "UNAVAILABLE_FOR_LEGAL_REASONS",
    451,
    "Server operator has received a legal demand to deny access to the resource"
  );

  /// 494 Request Header Too Large – Nginx extension indicating that the client sent too large of a request or too long of a header line.
  /// Similar to 431 but specific to Nginx servers.
  static const HttpStatus REQUEST_HEADER_TOO_LARGE = HttpStatus._(
    "REQUEST_HEADER_TOO_LARGE",
    494,
    "Nginx extension: Client sent too large of a request or too long of a header line"
  );

  /// 495 SSL Certificate Error – Nginx extension indicating an error with the client's SSL certificate.
  /// Used when client certificate verification fails.
  static const HttpStatus SSL_CERTIFICATE_ERROR = HttpStatus._(
    "SSL_CERTIFICATE_ERROR",
    495,
    "Nginx extension: Error with the client's SSL certificate"
  );

  /// 496 SSL Certificate Required – Nginx extension indicating that a client certificate is required but not provided.
  /// Used when client certificate authentication is mandatory.
  static const HttpStatus SSL_CERTIFICATE_REQUIRED = HttpStatus._(
    "SSL_CERTIFICATE_REQUIRED",
    496,
    "Nginx extension: Client certificate is required but not provided"
  );

  /// 497 HTTP Request Sent to HTTPS Port – Nginx extension indicating that a plain HTTP request was sent to an HTTPS port.
  /// Occurs when clients mistakenly use HTTP instead of HTTPS.
  static const HttpStatus HTTP_REQUEST_SENT_TO_HTTPS_PORT = HttpStatus._(
    "HTTP_REQUEST_SENT_TO_HTTPS_PORT",
    497,
    "Nginx extension: Plain HTTP request was sent to an HTTPS port"
  );

  /// 498 Invalid Token – Esri extension indicating that the provided token is invalid or expired.
  /// Used by ArcGIS services for authentication errors.
  static const HttpStatus INVALID_TOKEN = HttpStatus._(
    "INVALID_TOKEN",
    498,
    "Esri extension: Provided token is invalid or expired"
  );

  /// 499 Client Closed Request – Nginx extension indicating that the client closed the connection before the server could send a response.
  /// Used when clients cancel requests before completion.
  static const HttpStatus CLIENT_CLOSED_REQUEST = HttpStatus._(
    "CLIENT_CLOSED_REQUEST",
    499,
    "Nginx extension: Client closed the connection before the server could send a response"
  );

  // --- Server error responses (500–599) ---

  /// 500 Internal Server Error – A generic error message when an unexpected condition was encountered and no more specific message is suitable.
  /// The most common server error, indicating something went wrong on the server side.
  static const HttpStatus INTERNAL_SERVER_ERROR = HttpStatus._(
    "INTERNAL_SERVER_ERROR",
    500,
    "Generic error message when an unexpected condition was encountered on the server"
  );

  /// 501 Not Implemented – The server either does not recognize the request method, or it lacks the ability to fulfil the request.
  /// Usually implies future availability (e.g., a new feature of a web-service API).
  static const HttpStatus NOT_IMPLEMENTED = HttpStatus._(
    "NOT_IMPLEMENTED",
    501,
    "Server does not recognize the request method or lacks the ability to fulfill the request"
  );

  /// 502 Bad Gateway – The server was acting as a gateway or proxy and received an invalid response from the upstream server.
  /// Common when a reverse proxy cannot reach the backend server.
  static const HttpStatus BAD_GATEWAY = HttpStatus._(
    "BAD_GATEWAY",
    502,
    "Server acting as a gateway or proxy received an invalid response from the upstream server"
  );

  /// 503 Service Unavailable – The server cannot handle the request (because it is overloaded or down for maintenance).
  /// Generally, this is a temporary state and should include a Retry-After header.
  static const HttpStatus SERVICE_UNAVAILABLE = HttpStatus._(
    "SERVICE_UNAVAILABLE",
    503,
    "Server cannot handle the request due to temporary overload or maintenance"
  );

  /// 504 Gateway Timeout – The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.
  /// Occurs when a proxy server times out waiting for a response from an upstream server.
  static const HttpStatus GATEWAY_TIMEOUT = HttpStatus._(
    "GATEWAY_TIMEOUT",
    504,
    "Server acting as a gateway or proxy did not receive a timely response from the upstream server"
  );

  /// 505 HTTP Version Not Supported – The server does not support the HTTP protocol version used in the request.
  /// The server should indicate which protocols it supports in the response.
  static const HttpStatus HTTP_VERSION_NOT_SUPPORTED = HttpStatus._(
    "HTTP_VERSION_NOT_SUPPORTED",
    505,
    "Server does not support the HTTP protocol version used in the request"
  );

  /// 506 Variant Also Negotiates – Transparent content negotiation for the request results in a circular reference.
  /// Indicates a configuration error in the server's content negotiation setup.
  static const HttpStatus VARIANT_ALSO_NEGOTIATES = HttpStatus._(
    "VARIANT_ALSO_NEGOTIATES",
    506,
    "Transparent content negotiation for the request results in a circular reference"
  );

  /// 507 Insufficient Storage – The server is unable to store the representation needed to complete the request.
  /// WebDAV extension indicating that the server cannot complete the request due to insufficient storage space.
  static const HttpStatus INSUFFICIENT_STORAGE = HttpStatus._(
    "INSUFFICIENT_STORAGE",
    507,
    "WebDAV: Server is unable to store the representation needed to complete the request"
  );

  /// 508 Loop Detected – The server detected an infinite loop while processing the request.
  /// WebDAV extension used when the server terminates an operation because it encounters an infinite loop.
  static const HttpStatus LOOP_DETECTED = HttpStatus._(
    "LOOP_DETECTED",
    508,
    "WebDAV: Server detected an infinite loop while processing the request"
  );

  /// 509 Bandwidth Limit Exceeded – Apache extension indicating that the bandwidth limit has been exceeded.
  /// Used by some servers to indicate that the site has exceeded its allocated bandwidth.
  static const HttpStatus BANDWIDTH_LIMIT_EXCEEDED = HttpStatus._(
    "BANDWIDTH_LIMIT_EXCEEDED",
    509,
    "Apache extension: Bandwidth limit has been exceeded"
  );

  /// 510 Not Extended – Further extensions to the request are required for the server to fulfil it.
  /// The client should send additional information or use a different approach.
  static const HttpStatus NOT_EXTENDED = HttpStatus._(
    "NOT_EXTENDED",
    510,
    "Further extensions to the request are required for the server to fulfill it"
  );

  /// 511 Network Authentication Required – The client needs to authenticate to gain network access.
  /// Intended for use by intercepting proxies to control access to the network.
  static const HttpStatus NETWORK_AUTHENTICATION_REQUIRED = HttpStatus._(
    "NETWORK_AUTHENTICATION_REQUIRED",
    511,
    "Client needs to authenticate to gain network access"
  );

  /// 520 Web Server Returned an Unknown Error – Cloudflare extension indicating that the origin server returned an empty, unknown, or unexpected response.
  /// Used when Cloudflare cannot determine what went wrong with the origin server.
  static const HttpStatus WEB_SERVER_RETURNED_UNKNOWN_ERROR = HttpStatus._(
    "WEB_SERVER_RETURNED_UNKNOWN_ERROR",
    520,
    "Cloudflare extension: Origin server returned an empty, unknown, or unexpected response"
  );

  /// 521 Web Server Is Down – Cloudflare extension indicating that the origin server has refused the connection from Cloudflare.
  /// The origin web server is not reachable.
  static const HttpStatus WEB_SERVER_IS_DOWN = HttpStatus._(
    "WEB_SERVER_IS_DOWN",
    521,
    "Cloudflare extension: Origin server has refused the connection"
  );

  /// 522 Connection Timed Out – Cloudflare extension indicating that Cloudflare could not negotiate a TCP handshake with the origin server.
  /// The origin server is not responding to requests.
  static const HttpStatus CONNECTION_TIMED_OUT = HttpStatus._(
    "CONNECTION_TIMED_OUT",
    522,
    "Cloudflare extension: Could not negotiate a TCP handshake with the origin server"
  );

  /// 523 Origin Is Unreachable – Cloudflare extension indicating that Cloudflare could not reach the origin server.
  /// Usually occurs when DNS resolution fails or the server is unreachable.
  static const HttpStatus ORIGIN_IS_UNREACHABLE = HttpStatus._(
    "ORIGIN_IS_UNREACHABLE",
    523,
    "Cloudflare extension: Could not reach the origin server"
  );

  /// 524 A Timeout Occurred – Cloudflare extension indicating that Cloudflare was able to complete a TCP connection to the origin server,
  /// but did not receive a timely HTTP response.
  static const HttpStatus A_TIMEOUT_OCCURRED = HttpStatus._(
    "A_TIMEOUT_OCCURRED",
    524,
    "Cloudflare extension: Able to connect to origin server but did not receive a timely HTTP response"
  );

  /// 525 SSL Handshake Failed – Cloudflare extension indicating that Cloudflare could not negotiate a SSL/TLS handshake with the origin server.
  /// SSL certificate or configuration issues on the origin server.
  static const HttpStatus SSL_HANDSHAKE_FAILED = HttpStatus._(
    "SSL_HANDSHAKE_FAILED",
    525,
    "Cloudflare extension: Could not negotiate a SSL/TLS handshake with the origin server"
  );

  /// 526 Invalid SSL Certificate – Cloudflare extension indicating that Cloudflare could not validate the SSL certificate on the origin web server.
  /// The SSL certificate is invalid, expired, or not trusted.
  static const HttpStatus INVALID_SSL_CERTIFICATE = HttpStatus._(
    "INVALID_SSL_CERTIFICATE",
    526,
    "Cloudflare extension: Could not validate the SSL certificate on the origin web server"
  );

  /// 527 Railgun Error – Cloudflare extension indicating an error with Cloudflare's Railgun service.
  /// Railgun is a Cloudflare technology that speeds up non-cached pages.
  static const HttpStatus RAILGUN_ERROR = HttpStatus._(
    "RAILGUN_ERROR",
    527,
    "Cloudflare extension: Error with Cloudflare's Railgun service"
  );

  /// 530 Site Frozen – Pantheon extension indicating that the site is frozen due to inactivity.
  /// Used by Pantheon hosting platform when a site is temporarily suspended.
  static const HttpStatus SITE_FROZEN = HttpStatus._(
    "SITE_FROZEN",
    530,
    "Pantheon extension: Site is frozen due to inactivity"
  );

  /// 598 Network Read Timeout Error – Non-standard status code used by some proxies to indicate a network read timeout.
  /// Used when a proxy times out reading from the client or upstream server.
  static const HttpStatus NETWORK_READ_TIMEOUT_ERROR = HttpStatus._(
    "NETWORK_READ_TIMEOUT_ERROR",
    598,
    "Non-standard: Network read timeout error"
  );

  /// 599 Network Connect Timeout Error – Non-standard status code used by some proxies to indicate a network connect timeout.
  /// Used when a proxy times out connecting to the upstream server.
  static const HttpStatus NETWORK_CONNECT_TIMEOUT_ERROR = HttpStatus._(
    "NETWORK_CONNECT_TIMEOUT_ERROR",
    599,
    "Non-standard: Network connect timeout error"
  );

  /// 600 Connection Not Reachable – H-Standard status code used by some proxies to indicate a connection not reachable.
  /// Used when a proxy cannot reach the upstream server.
  static const HttpStatus CONNECTION_NOT_REACHABLE = HttpStatus._(
    "CONNECTION_NOT_REACHABLE",
    600,
    "H-Standard: Connection not reachable"
  );

  /// 601 Request Cancelled – H-Standard status code used by some proxies to indicate a request cancellation.
  /// Used when a request is cancelled by the user or due to a timeout.
  static const HttpStatus REQUEST_CANCELLED = HttpStatus._(
    "REQUEST_CANCELLED",
    601,
    "H-Standard: Request was cancelled"
  );

  /// List of all predefined status codes for initialization.
  static const List<HttpStatus> _allStatusCodes = [
    // 1xx Informational
    CONTINUE, SWITCHING_PROTOCOLS, PROCESSING, EARLY_HINTS,
    
    // 2xx Success
    OK, CREATED, ACCEPTED, NON_AUTHORITATIVE_INFORMATION, NO_CONTENT, 
    RESET_CONTENT, PARTIAL_CONTENT, MULTI_STATUS, ALREADY_REPORTED, IM_USED,
    
    // 3xx Redirection
    MULTIPLE_CHOICES, MOVED_PERMANENTLY, FOUND, MOVED_TEMPORARILY, SEE_OTHER,
    NOT_MODIFIED, USE_PROXY, SWITCH_PROXY, TEMPORARY_REDIRECT, PERMANENT_REDIRECT,
    
    // 4xx Client Error
    BAD_REQUEST, UNAUTHORIZED, PAYMENT_REQUIRED, FORBIDDEN, NOT_FOUND,
    METHOD_NOT_ALLOWED, NOT_ACCEPTABLE, PROXY_AUTHENTICATION_REQUIRED, REQUEST_TIMEOUT,
    CONFLICT, GONE, LENGTH_REQUIRED, PRECONDITION_FAILED, PAYLOAD_TOO_LARGE,
    URI_TOO_LONG, UNSUPPORTED_MEDIA_TYPE, RANGE_NOT_SATISFIABLE, EXPECTATION_FAILED,
    IM_A_TEAPOT, MISDIRECTED_REQUEST, UNPROCESSABLE_ENTITY, LOCKED, FAILED_DEPENDENCY,
    TOO_EARLY, UPGRADE_REQUIRED, PRECONDITION_REQUIRED, TOO_MANY_REQUESTS,
    REQUEST_HEADER_FIELDS_TOO_LARGE, CONNECTION_CLOSED_WITHOUT_RESPONSE, RETRY_WITH,
    BLOCKED_BY_WINDOWS_PARENTAL_CONTROLS, UNAVAILABLE_FOR_LEGAL_REASONS,
    REQUEST_HEADER_TOO_LARGE, SSL_CERTIFICATE_ERROR, SSL_CERTIFICATE_REQUIRED,
    HTTP_REQUEST_SENT_TO_HTTPS_PORT, INVALID_TOKEN, CLIENT_CLOSED_REQUEST,
    
    // 5xx Server Error
    INTERNAL_SERVER_ERROR, NOT_IMPLEMENTED, BAD_GATEWAY, SERVICE_UNAVAILABLE,
    GATEWAY_TIMEOUT, HTTP_VERSION_NOT_SUPPORTED, VARIANT_ALSO_NEGOTIATES,
    INSUFFICIENT_STORAGE, LOOP_DETECTED, BANDWIDTH_LIMIT_EXCEEDED, NOT_EXTENDED,
    NETWORK_AUTHENTICATION_REQUIRED, WEB_SERVER_RETURNED_UNKNOWN_ERROR,
    WEB_SERVER_IS_DOWN, CONNECTION_TIMED_OUT, ORIGIN_IS_UNREACHABLE,
    A_TIMEOUT_OCCURRED, SSL_HANDSHAKE_FAILED, INVALID_SSL_CERTIFICATE,
    RAILGUN_ERROR, SITE_FROZEN, NETWORK_READ_TIMEOUT_ERROR, NETWORK_CONNECT_TIMEOUT_ERROR,

    // 6xx Custom
    CONNECTION_NOT_REACHABLE,
    REQUEST_CANCELLED,
  ];

  // --- Custom helpers ---

  /// True if this represents a connection error (no valid HTTP status code).
  ///
  /// Status codes in the 600-699 range represent custom connection errors.
  bool get connectionError => between(600, 699);

  /// True if [code] is 401 Unauthorized.
  ///
  /// ## Example
  /// ```dart
  /// if (response.status.isUnauthorized) {
  ///   // Redirect to login
  /// }
  /// ```
  bool get isUnauthorized => code == UNAUTHORIZED.code;

  /// True if [code] is 403 Forbidden.
  ///
  /// ## Example
  /// ```dart
  /// if (response.status.isForbidden) {
  ///   print('Access denied');
  /// }
  /// ```
  bool get isForbidden => code == FORBIDDEN.code;

  /// True if [code] is 404 Not Found.
  ///
  /// ## Example
  /// ```dart
  /// if (response.status.isNotFound) {
  ///   print('Resource not found');
  /// }
  /// ```
  bool get isNotFound => code == NOT_FOUND.code;

  /// True if [code] is between 500 and 599, indicating server-side error.
  bool get isServerError => between(500, 599);

  /// Checks if [code] falls inclusively between [begin] and [end].
  ///
  /// ## Parameters
  /// - [begin]: The start of the range (inclusive).
  /// - [end]: The end of the range (inclusive).
  ///
  /// ## Returns
  /// `true` if the status code is within the range.
  bool between(int begin, int end) {
    return code >= begin && code <= end;
  }

  /// True if [code] is a 2xx success status.
  ///
  /// ## Example
  /// ```dart
  /// if (response.status.isOk) {
  ///   // Process successful response
  /// }
  /// ```
  bool get isOk => between(200, 299);

  /// True if [code] is not successful (i.e., not 2xx).
  ///
  /// ## Example
  /// ```dart
  /// if (response.status.hasError) {
  ///   print('Error: ${response.status.description}');
  /// }
  /// ```
  bool get hasError => !isOk;

  /// Returns true if this status code is in the 1xx range (Informational).
  bool get isInformational => between(100, 199);

  /// Returns true if this status code is in the 2xx range (Success).
  bool get isSuccess => between(200, 299);

  /// Returns true if this status code is in the 3xx range (Redirection).
  bool get isRedirection => between(300, 399);

  /// Returns true if this status code is in the 4xx range (Client Error).
  bool get isClientError => between(400, 499);

  /// Returns true if this status code is an error (4xx or 5xx).
  bool get isError => isClientError || isServerError;

  /// Get a [HttpStatus] instance from a status code.
  ///
  /// If the status code exists in the predefined list, returns that instance.
  /// Otherwise, creates a new instance with a generic name and description
  /// and caches it for future use.
  ///
  /// ## Parameters
  /// - [statusCode]: The HTTP status code.
  ///
  /// ## Returns
  /// The [HttpStatus] instance for the given code.
  ///
  /// ## Example
  /// ```dart
  /// final status = HttpStatus.fromCode(200);
  /// print(status.name); // 'OK'
  /// ```
  static HttpStatus fromCode(int statusCode) {
    _initializeStatusCodes();
    
    // Return existing status code if found
    if (_statusCodes.containsKey(statusCode)) {
      return _statusCodes[statusCode]!;
    }
    
    // Create a new status code for unknown codes
    String name = "UNKNOWN_$statusCode";
    String description = "Unknown HTTP status code $statusCode";
    
    // Try to provide better generic descriptions based on ranges
    if (statusCode >= 100 && statusCode < 200) {
      description = "Informational response - status code $statusCode";
    } else if (statusCode >= 200 && statusCode < 300) {
      description = "Success response - status code $statusCode";
    } else if (statusCode >= 300 && statusCode < 400) {
      description = "Redirection response - status code $statusCode";
    } else if (statusCode >= 400 && statusCode < 500) {
      description = "Client error response - status code $statusCode";
    } else if (statusCode >= 500 && statusCode < 600) {
      description = "Server error response - status code $statusCode";
    }
    
    final newStatus = HttpStatus._(name, statusCode, description);
    _statusCodes[statusCode] = newStatus; // Cache for future use
    return newStatus;
  }

  /// Get all predefined status codes as a list.
  ///
  /// ## Returns
  /// An unmodifiable list of all predefined [HttpStatus] instances.
  ///
  /// ## Example
  /// ```dart
  /// final allStatuses = HttpStatus.getAllStatusCodes();
  /// print('Total status codes: ${allStatuses.length}');
  /// ```
  static List<HttpStatus> getAllStatusCodes() {
    _initializeStatusCodes();
    return List.unmodifiable(_statusCodes.values);
  }

  /// Get all status codes in a specific range.
  ///
  /// ## Parameters
  /// - [start]: The start of the range (inclusive).
  /// - [end]: The end of the range (inclusive).
  ///
  /// ## Returns
  /// A list of [HttpStatus] instances within the specified range, sorted by code.
  ///
  /// ## Example
  /// ```dart
  /// final clientErrors = HttpStatus.getStatusCodesInRange(400, 499);
  /// print('Client error codes: ${clientErrors.map((s) => s.code).toList()}');
  /// ```
  static List<HttpStatus> getStatusCodesInRange(int start, int end) {
    _initializeStatusCodes();
    return _statusCodes.values
        .where((status) => status.code >= start && status.code <= end)
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  /// Check if a status code is predefined.
  ///
  /// ## Parameters
  /// - [statusCode]: The status code to check.
  ///
  /// ## Returns
  /// `true` if the status code has a predefined [HttpStatus] instance.
  ///
  /// ## Example
  /// ```dart
  /// if (HttpStatus.isPredefined(200)) {
  ///   print('Standard status code');
  /// }
  /// ```
  static bool isPredefined(int statusCode) {
    _initializeStatusCodes();
    return _statusCodes.containsKey(statusCode);
  }

  /// Returns the string representation of this status (the status name).
  ///
  /// ## Example
  /// ```dart
  /// print(HttpStatus.OK.toString()); // 'OK'
  /// ```
  @override
  String toString() => name;

  /// Equality is based on the status code.
  ///
  /// Two [HttpStatus] instances are equal if they have the same [code].
  ///
  /// ## Example
  /// ```dart
  /// final a = HttpStatus.fromCode(200);
  /// final b = HttpStatus.fromCode(200);
  /// print(a == b); // true
  /// ```
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HttpStatus && other.code == code;
  }

  /// Hash code based on the status code.
  @override
  int get hashCode => code.hashCode;

  /// Converts this status to a JSON-compatible map.
  ///
  /// ## Returns
  /// A [Map<String, dynamic>] with code, name, and description.
  ///
  /// ## Example
  /// ```dart
  /// final json = HttpStatus.OK.toJson();
  /// // {'code': 200, 'name': 'OK', 'description': '...'}
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
    };
  }
}