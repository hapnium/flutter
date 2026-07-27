/// {@template exception_type}
/// Classifies network and API failures into structured categories for
/// programmatic error handling.
///
/// `ExceptionType` helps exception handlers distinguish between different
/// failure modes without parsing error messages or HTTP status codes. This
/// enables clean, type-safe error handling:
///
/// ```dart
/// try {
///   final response = await zap.get<User>('/users/1');
/// } on ZapException catch (e) {
///   switch (e.type) {
///     case ExceptionType.network:
///       _showOfflineBanner();
///     case ExceptionType.auth:
///       _navigateToLogin();
///     case ExceptionType.timeout:
///       _showRetryDialog();
///     case ExceptionType.server:
///       _reportServerError(e);
///     default:
///       _showGenericError(e);
///   }
/// }
/// ```
///
/// ### Classification strategy
///
/// The classification is based on HTTP standards, network protocol behavior,
/// and system-level failure patterns. Each value represents a distinct
/// failure category with different retry and recovery strategies:
///
/// | Type       | Retryable? | User action? | Example                          |
/// |------------|------------|--------------|----------------------------------|
/// | [network]  | Yes        | Yes          | No internet connection           |
/// | [timeout]  | Yes        | No           | Request exceeded time limit      |
/// | [server]   | Maybe      | No           | HTTP 500                         |
/// | [client]   | No         | Maybe        | HTTP 400 Bad Request             |
/// | [auth]     | No         | Yes          | HTTP 401 Unauthorized            |
/// | [cancelled]| No         | No           | User cancelled the request       |
/// | [ssl]      | No         | Yes          | Certificate validation failed    |
/// | [connection]| Yes       | No           | TCP connection refused           |
/// | [dns]      | Yes        | Yes          | DNS resolution failed            |
/// | [parsing]  | No         | No           | Invalid JSON response            |
/// | [unknown]  | Maybe      | No           | Unrecognized error               |
/// {@endtemplate}
enum ExceptionType {
  /// {@template exception_type_network}
  /// Network connectivity issues (no internet, airplane mode, socket
  /// disconnection).
  ///
  /// This type covers failures that occur at the transport layer before
  /// any HTTP request can be made. Common causes include:
  /// - Device has no internet connection
  /// - Airplane mode is enabled
  /// - Network interface is down
  /// - VPN or proxy is blocking traffic
  ///
  /// **Retryable**: Yes, with exponential backoff.
  /// **User action**: May need to check connectivity settings.
  ///
  /// ### Example error messages
  /// - `SocketException: Failed host lookup: api.example.com`
  /// - `SocketException: No route to host`
  /// - `SocketException: Connection refused`
  /// {@endtemplate}
  network,

  /// {@template exception_type_timeout}
  /// Request exceeded the configured timeout threshold.
  ///
  /// The server did not respond within the allowed time. This may indicate:
  /// - Slow network connection
  /// - Server under heavy load
  /// - Request too large for server to process quickly
  /// - Server is down but connection was established
  ///
  /// **Retryable**: Yes, with exponential backoff. Consider increasing the
  /// timeout duration if this occurs frequently.
  /// **User action**: None typically needed.
  ///
  /// ### Configuration
  ///
  /// Adjust the timeout via [ZapConfig.timeout]:
  /// ```dart
  /// final zap = Zap(
  ///   zapConfig: ZapConfig(timeout: Duration(seconds: 30)),
  /// );
  /// ```
  /// {@endtemplate}
  timeout,

  /// {@template exception_type_server}
  /// Server-side errors indicated by HTTP 5xx status codes.
  ///
  /// The server received the request but failed to process it. This is
  /// distinct from client errors (4xx) because the request was valid.
  ///
  /// **Retryable**: Yes for transient conditions (502, 503, 504). No for
  /// persistent 500 errors.
  /// **User action**: None typically needed.
  ///
  /// ### Common status codes
  /// - `500 Internal Server Error`: Generic server failure
  /// - `502 Bad Gateway`: Upstream server returned invalid response
  /// - `503 Service Unavailable`: Server temporarily overloaded
  /// - `504 Gateway Timeout`: Upstream server timed out
  /// {@endtemplate}
  server,

  /// {@template exception_type_client}
  /// Client-side errors indicated by HTTP 4xx status codes.
  ///
  /// The server rejected the request because the client made an error.
  /// This typically indicates a bug in the client code or invalid user input.
  ///
  /// **Retryable**: Generally no — fixing the request is required.
  /// **User action**: Sometimes (e.g., re-entering form data).
  ///
  /// ### Common status codes
  /// - `400 Bad Request`: Malformed request syntax
  /// - `403 Forbidden`: Valid credentials but insufficient permissions
  /// - `404 Not Found`: Resource does not exist
  /// - `409 Conflict`: Resource state conflict
  /// - `422 Unprocessable Entity`: Validation error
  /// - `429 Too Many Requests`: Rate limit exceeded (retry after delay)
  /// {@endtemplate}
  client,

  /// {@template exception_type_auth}
  /// Authentication or authorization failures.
  ///
  /// The server requires valid credentials that are missing, expired, or
  /// invalid. This is distinct from [client] errors because it specifically
  /// relates to identity verification.
  ///
  /// **Retryable**: No — requires re-authentication.
  /// **User action**: Yes — login or refresh token flow.
  ///
  /// ### Example scenarios
  /// - Missing `Authorization` header
  /// - Expired JWT token
  /// - Invalid API key
  /// - Account suspended or deactivated
  ///
  /// ### Handling strategy
  /// ```dart
  /// if (e.type == ExceptionType.auth) {
  ///   await refreshTokenOrNavigateToLogin();
  /// }
  /// ```
  /// {@endtemplate}
  auth,

  /// {@template exception_type_cancelled}
  /// The request was intentionally or programmatically cancelled.
  ///
  /// This occurs when a [CancelToken] is used to abort a request before
  /// it completes. It is not an error — it represents expected behavior.
  ///
  /// **Retryable**: No — the cancellation was intentional.
  /// **User action**: None typically needed.
  ///
  /// ### Common scenarios
  /// - User navigated away from a screen mid-request
  /// - A timeout token expired
  /// - Bulk cancellation via [cancelAllRequests]
  ///
  /// ### Handling strategy
  ///
  /// Typically, cancellation exceptions are caught and silently ignored:
  /// ```dart
  /// try {
  ///   final response = await zap.get<User>('/users/1');
  /// } on ZapException catch (e) {
  ///   if (e.type == ExceptionType.cancelled) return;
  ///   rethrow;
  /// }
  /// ```
  /// {@endtemplate}
  cancelled,

  /// {@template exception_type_ssl}
  /// SSL/TLS certificate validation or negotiation failures.
  ///
  /// The connection to the server failed during the TLS handshake. This
  /// is a security-critical failure that should not be silently ignored.
  ///
  /// **Retryable**: No — the issue is with the certificate, not the network.
  /// **User action**: Yes — may need to install a CA certificate or update
  /// the system trust store.
  ///
  /// ### Example scenarios
  /// - Self-signed certificate rejection
  /// - Hostname mismatch (certificate issued for different domain)
  /// - Expired certificate
  /// - Certificate revoked by CA
  /// - Untrusted certificate authority
  ///
  /// ### Configuration
  ///
  /// For development with self-signed certificates:
  /// ```dart
  /// final zap = Zap(
  ///   zapConfig: ZapConfig(allowAutoSignedCert: true),
  /// );
  /// ```
  ///
  /// **Warning**: Only use `allowAutoSignedCert` in development. Never in
  /// production.
  /// {@endtemplate}
  ssl,

  /// {@template exception_type_connection}
  /// Failure to establish a TCP connection to the server.
  ///
  /// The TCP handshake failed, meaning the server could not be reached at
  /// the network level. This is distinct from [network] (no connectivity)
  /// because the device may have internet but the specific server is
  /// unreachable.
  ///
  /// **Retryable**: Yes, with exponential backoff.
  /// **User action**: None typically needed.
  ///
  /// ### Common causes
  /// - Server is down or restarted
  /// - Port is closed or firewalled
  /// - Load balancer is blocking the connection
  /// - Rate limiting at the network level
  ///
  /// ### Example error messages
  /// - `SocketException: Connection refused`
  /// - `SocketException: Connection timed out`
  /// - `SocketException: Network is unreachable`
  /// {@endtemplate}
  connection,

  /// {@template exception_type_dns}
  /// Domain name resolution failure.
  ///
  /// The system could not resolve the hostname to an IP address. This
  /// typically indicates a DNS configuration issue or that the domain
  /// does not exist.
  ///
  /// **Retryable**: Yes, but only if the issue is transient (e.g., DNS
  /// server temporarily unreachable).
  /// **User action**: May need to check DNS settings or verify the URL.
  ///
  /// ### Common causes
  /// - No internet connection
  /// - DNS server is down
  /// - Domain name is misspelled or does not exist
  /// - DNS cache is stale
  /// - VPN or proxy is intercepting DNS queries
  ///
  /// ### Example error messages
  /// - `SocketException: Failed host lookup: api.example.com`
  /// - `SocketException: No such host is known`
  /// {@endtemplate}
  dns,

  /// {@template exception_type_parsing}
  /// Response deserialization, decoding, or data parsing failures.
  ///
  /// The server returned a response, but the client could not parse it into
  /// the expected type. This indicates a contract mismatch between the
  /// server response and the client's data model.
  ///
  /// **Retryable**: No — the issue is with the data format, not the network.
  /// **User action**: None — this is a developer-level error.
  ///
  /// ### Common causes
  /// - Unexpected JSON structure (missing fields, wrong types)
  /// - Server returned HTML instead of JSON (e.g., error page)
  /// - Response encoding mismatch
  /// - Null value where non-null was expected
  /// - Server API changed without client update
  ///
  /// ### Example error messages
  /// - `FormatException: Unexpected character (at line 1, column 2)`
  /// - `NoSuchMethodError: The method 'operator []' was called on null`
  ///
  /// ### Prevention
  ///
  /// Use nullable types and defensive parsing:
  /// ```dart
  /// final response = await zap.get<UserResponse>('/users/1');
  /// final name = response.data?.name ?? 'Unknown';
  /// ```
  /// {@endtemplate}
  parsing,

  /// {@template exception_type_unknown}
  /// Fallback type for uncategorized or unexpected errors.
  ///
  /// Used when no specific type applies. This is the default classification
  /// for errors that do not match any known category.
  ///
  /// **Retryable**: Maybe — depends on the underlying error.
  /// **User action**: Typically none.
  ///
  /// ### When this occurs
  ///
  /// - The error message does not match any known pattern
  /// - An unexpected exception type was thrown
  /// - The classification logic encountered an edge case
  ///
  /// ### Handling strategy
  ///
  /// Log the error details and treat as a generic failure:
  /// ```dart
  /// if (e.type == ExceptionType.unknown) {
  ///   Z.error('Unexpected error: ${e.message}');
  /// }
  /// ```
  ///
  /// If this type occurs frequently for a specific error, consider adding
  /// a new `ExceptionType` value to handle it explicitly.
  /// {@endtemplate}
  unknown,
}