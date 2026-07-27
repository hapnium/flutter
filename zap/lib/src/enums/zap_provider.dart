/// {@template zap_provider}
/// Identifies the underlying HTTP transport implementation used by a
/// [ZapClient].
///
/// The provider determines which platform-specific HTTP stack is invoked
/// for network operations. The appropriate provider is selected automatically
/// based on the compilation target:
///
/// | Provider  | Platform            | Transport             |
/// |-----------|---------------------|-----------------------|
/// | [io]      | Mobile / Desktop    | `dart:io` HttpClient  |
/// | [http]    | Mobile / Desktop    | `http` package        |
/// | [web]     | Browser             | `dart:html` / fetch   |
/// | [graphql] | Any                 | GraphQL over HTTP     |
///
/// Most consumers never need to reference this enum directly. It is used
/// internally by the client factory to select the correct implementation
/// based on the current platform.
///
/// ### Platform selection
///
/// The selection is done via conditional imports:
/// ```dart
/// if (kIsWeb) {
///   // Use web provider
/// } else {
///   // Use io or http provider
/// }
/// ```
///
/// ### Custom providers
///
/// To add a custom transport, implement the appropriate interface and
/// register it with the client factory. The provider enum is primarily
/// for internal dispatch — custom providers may use their own enum values.
/// {@endtemplate}
enum ZapProvider {
  /// {@template zap_provider_io}
  /// The default provider for **native** platforms (Android, iOS, macOS,
  /// Linux, Windows) using `dart:io` `HttpClient`.
  ///
  /// This provider offers full control over:
  /// - Socket options (keep-alive, timeouts)
  /// - Proxy configuration
  /// - TLS/SSL settings
  /// - Certificate validation
  /// - Connection pooling
  ///
  /// It is the most feature-complete provider and is recommended for
  /// native applications.
  ///
  /// ### When to use
  ///
  /// Use [io] when:
  /// - Building a mobile, desktop, or server application
  /// - You need fine-grained control over HTTP behavior
  /// - You require proxy or custom certificate support
  /// - You need connection pooling for performance
  ///
  /// ### Limitations
  ///
  /// - Not available on web (does not compile with `dart:html`)
  /// - Requires `dart:io` which is not available in all environments
  /// {@endtemplate}
  io,

  /// {@template zap_provider_http}
  /// An alternative native provider backed by the `http` package.
  ///
  /// This provider uses the `http` package's `Client` interface, which
  /// provides a simpler API surface than `dart:io` `HttpClient`. It is
  /// useful when:
  /// - You want compatibility with packages that depend on the `http`
  ///   client interface
  /// - You prefer a simpler API for basic HTTP operations
  /// - You need a consistent interface across platforms (the `http`
  ///   package has web support via `BrowserClient`)
  ///
  /// ### When to use
  ///
  /// Use [http] when:
  /// - You don't need the advanced features of `dart:io` `HttpClient`
  /// - You want a simpler, more declarative API
  /// - You're building a package that should work on multiple platforms
  ///
  /// ### Limitations
  ///
  /// - Less control over low-level HTTP behavior
  /// - No direct access to socket options
  /// - May have slightly higher overhead than [io]
  /// {@endtemplate}
  http,

  /// {@template zap_provider_web}
  /// The provider for **web** platforms using `dart:html` or `fetch`.
  ///
  /// Automatically selected when compiling to JavaScript. This provider
  /// leverages the browser's native HTTP capabilities via `dart:html`
  /// `HttpRequest` or the `fetch` API.
  ///
  /// ### When to use
  ///
  /// Use [web] when:
  /// - Building a Flutter web application
  /// - Running in a browser environment
  /// - The target is JavaScript compilation
  ///
  /// ### Limitations
  ///
  /// - Does not support `dart:io`-specific features (custom socket options,
  ///   proxy configuration, certificate pinning)
  /// - CORS restrictions apply — the server must include appropriate
  ///   `Access-Control-Allow-*` headers
  /// - Cookie handling differs from native platforms
  /// - No direct access to the underlying TCP connection
  ///
  /// ### CORS
  ///
  /// The browser enforces same-origin policy. To make cross-origin requests,
  /// configure your server to include:
  /// ```
  /// Access-Control-Allow-Origin: https://your-app.com
  /// Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
  /// Access-Control-Allow-Headers: Content-Type, Authorization
  /// ```
  /// {@endtemplate}
  web,

  /// {@template zap_provider_graphql}
  /// A specialized provider for **GraphQL** operations.
  ///
  /// Wraps the standard HTTP provider with GraphQL-specific request
  /// formatting, response parsing, and error handling. This provider
  /// handles:
  /// - Query and mutation serialization
  /// - Variable encoding
  /// - Response normalization
  /// - GraphQL error extraction
  /// - Subscription support (via WebSocket)
  ///
  /// ### When to use
  ///
  /// Use [graphql] when:
  /// - Your API is GraphQL-based
  /// - You need structured query/mutation handling
  /// - You want automatic response parsing
  ///
  /// ### Behavior
  ///
  /// The GraphQL provider:
  /// 1. Serializes the query/mutation and variables into a JSON payload
  /// 2. Sends a POST request to the GraphQL endpoint
  /// 3. Parses the response into a [GraphQLResponse] with `data` and
  ///    `errors` fields
  /// 4. Handles partial responses (data + errors)
  ///
  /// ### Example
  /// ```dart
  /// final response = await zap.query<User>('''
  ///   query GetUser(\$id: ID!) {
  ///     user(id: \$id) { name email }
  ///   }
  /// ''', variables: {'id': '1'});
  ///
  /// // Response contains both data and errors
  /// if (response.data != null) {
  ///   print(response.data!.name);
  /// }
  /// if (response.errors != null) {
  ///   print(response.errors);
  /// }
  /// ```
  /// {@endtemplate}
  graphql,
}