import '../definitions.dart';
import '../http/certificates/certificates.dart';
import '../http/utils/constants.dart';
import '../http/utils/http_content_type.dart';

/// {@template zap_config}
/// A centralized, highly comprehensive configuration object that dictates the 
/// networking policies, security protocols, and default behaviors for a [ZapClient].
///
/// **Architectural Context:**
/// In enterprise-grade applications, HTTP requests do not exist in a vacuum. They 
/// require a baseline of rules—timeouts, SSL pinning, proxy routing, redirection 
/// limits, and default headers. Rather than passing these parameters into every 
/// individual `GET` or `POST` request, [ZapConfig] encapsulates them into a single 
/// immutable blueprint. When a [ZapClient] is instantiated, it absorbs this blueprint 
/// and applies it universally to all outbound traffic.
///
/// ### Core Responsibilities:
/// * **Security & SSL:** Enforces SSL pinning via [trustedCertificates] or allows 
///   bypassing validation for local development via [allowAutoSignedCert].
/// * **Network Resilience:** Prevents infinite hanging via [timeout], controls 
///   authentication looping via [maxAuthRetries], and dictates redirection limits 
///   via [maxRedirects].
/// * **Routing & Proxies:** Resolves relative paths against a global [baseUrl], 
///   and routes traffic through debugging gateways using [findProxy].
/// * **Headers & Payloads:** Automatically injects structural headers like 
///   [defaultContentType] and device fingerprinting via [userAgent].
/// * **Web/CORS Policies:** Manages cross-origin cookie injection for browser 
///   environments using [withCredentials].
///
/// ### Usage Example:
/// ```dart
/// // 1. Define a strict production configuration
/// final prodConfig = ZapConfig(
///   baseUrl: '[https://api.production.com/v1](https://api.production.com/v1)',
///   timeout: const Duration(seconds: 10),
///   errorSafety: true,
///   trustedCertificates: [myPinnedCert],
///   allowAutoSignedCert: false, // Strict SSL enforcement
///   sendUserAgent: true,
/// );
/// 
/// // 2. Instantiate the client
/// final client = ZapClient(config: prodConfig);
/// 
/// // 3. Spawn a mutated config for a specific heavy-duty task (e.g., video upload)
/// final uploadClient = ZapClient(
///   config: prodConfig.copyWith(timeout: const Duration(minutes: 5)),
/// );
/// ```
/// {@endtemplate}
class ZapConfig {
  /// Determines whether the client will accept self-signed or invalid SSL certificates.
  ///
  /// **Security Warning:** 
  /// Setting this to `true` completely bypasses TLS/SSL verification, making the 
  /// app highly vulnerable to Man-in-the-Middle (MitM) attacks. 
  /// 
  /// **Use Case:** 
  /// Set to `true` *only* during local development when hitting a `localhost` 
  /// server or a staging environment with a self-signed certificate. Must strictly 
  /// be `false` in production.
  bool allowAutoSignedCert;

  /// The string identifier sent to the server in the `User-Agent` HTTP header.
  ///
  /// **Use Case:**
  /// Web Application Firewalls (WAFs) and backend analytics often use this string 
  /// to identify the client platform, OS, and app version. Customizing this allows 
  /// the backend team to monitor traffic sources (e.g., `"MyApp/1.0.0 (iOS 16; iPhone)"`).
  String userAgent;

  /// Acts as a gatekeeper for injecting the [userAgent] into request headers.
  ///
  /// If `false`, the `User-Agent` header is omitted entirely to save bandwidth 
  /// or preserve anonymity. If `true`, the [userAgent] string is automatically 
  /// appended to every outgoing request.
  bool sendUserAgent;

  /// The root URL against which all relative request paths are resolved.
  ///
  /// **Architectural Benefit:**
  /// By defining a `baseUrl` (e.g., `"https://api.example.com/v1"`), your repository 
  /// methods only need to provide the specific endpoint (e.g., `"/users"`). This keeps 
  /// endpoint definitions clean and makes it easy to switch environments (e.g., 
  /// Dev -> Prod) by swapping a single string.
  String? baseUrl;

  /// The default `Content-Type` header injected into requests containing a body.
  ///
  /// Defaults to JSON (`application/json; charset=utf-8`). It informs the server 
  /// how to parse the incoming byte stream. This can be overridden on a per-request 
  /// basis (e.g., when sending `multipart/form-data` for file uploads).
  String defaultContentType;

  /// Dictates how the client reacts to HTTP `3xx` Redirection status codes.
  ///
  /// If `true`, the client automatically follows the `Location` header to fetch 
  /// the final resource. If `false`, the client halts and returns the raw `3xx` 
  /// response to the caller, allowing for manual inspection of the redirect URI.
  bool followRedirects;

  /// The absolute limit on consecutive HTTP redirects the client will follow.
  ///
  /// **Why this matters:** 
  /// Protects the application from infinite redirect loops caused by misconfigured 
  /// servers (e.g., Route A redirects to Route B, which redirects back to Route A), 
  /// which would otherwise hang the request forever and drain battery.
  int maxRedirects;

  /// The maximum number of automatic retry attempts triggered by `401 Unauthorized`.
  ///
  /// **Use Case:** 
  /// Integral to token rotation flows. If an API call fails due to an expired 
  /// access token, an interceptor can silently fetch a new token and retry the 
  /// original request. This caps the number of times that cycle can occur, 
  /// preventing infinite authentication loops if the refresh token is also dead.
  int maxAuthRetries;

  /// A global transformation function applied to raw response data.
  ///
  /// Instead of manually parsing JSON in every repository method, a [ResponseDecoder] 
  /// can automatically convert incoming network bytes into generic maps, lists, 
  /// or even domain models before the response is handed back to the caller.
  ResponseDecoder? defaultDecoder;

  /// The maximum permitted duration for a network request lifecycle.
  ///
  /// If the server does not respond within this window, the client will abort the 
  /// connection and throw a `TimeoutException`. This is critical for UX, preventing 
  /// the app from showing an infinite loading spinner when the network drops silently.
  Duration timeout;

  /// A collection of explicitly trusted SSL/TLS certificates (SSL Pinning).
  ///
  /// **Security Context:** 
  /// Standard HTTPS relies on the device's OS-level trust store. If a device is 
  /// compromised, a malicious root certificate could intercept traffic. By providing 
  /// [trustedCertificates], you instruct the client to *only* trust your specific 
  /// server certificates, effectively neutralizing local device compromises.
  List<ZapTrustedCertificate>? trustedCertificates;

  /// A callback utilized to dynamically route HTTP traffic through a proxy server.
  ///
  /// **Use Case:**
  /// Extremely useful for debugging network traffic via tools like Charles Proxy 
  /// or Proxyman. Also required for applications operating within strict corporate 
  /// intranets that mandate proxy routing.
  ProxyFinder? findProxy;

  /// Dictates cross-origin resource sharing (CORS) credential policies.
  ///
  /// **Web Specific:** 
  /// When running on Flutter Web, setting this to `true` instructs the browser to 
  /// include `HttpOnly` cookies and Authorization headers in cross-origin requests. 
  /// If `false`, the browser will strip cookies from the request.
  bool withCredentials;

  /// Defines the client's internal error propagation philosophy.
  ///
  /// If `true` (Safe Mode), the client aggressively catches underlying `SocketException`, 
  /// `TimeoutException`, and formatting errors, wrapping them in a standardized, 
  /// non-crashing response object (like an `ApiResponse.error`).
  /// 
  /// If `false`, raw Dart exceptions are permitted to bubble up the call stack, 
  /// forcing the caller to use strict `try/catch` blocks.
  bool errorSafety;

  /// {@macro zap_config}
  ///
  /// Initializes the baseline networking configuration. Sensible defaults are 
  /// provided for timeouts (`5 seconds`), redirects (`5 max`), and content-type (`JSON`).
  ZapConfig({
    this.userAgent = Constants.DEFAULT_USER_AGENT,
    this.timeout = const Duration(seconds: 5),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.sendUserAgent = false,
    this.maxAuthRetries = 1,
    this.allowAutoSignedCert = false,
    this.withCredentials = false,
    this.baseUrl,
    this.defaultContentType = '${HttpContentType.APPLICATION_JSON}; ${HttpContentType.CHARSET_UTF_8}',
    this.defaultDecoder,
    this.trustedCertificates,
    this.findProxy,
    this.errorSafety = true,
  });

  /// Generates a new instance of [ZapConfig] with selectively updated properties.
  ///
  /// **Architectural Use Case:**
  /// Enforces immutability. If you need a secondary HTTP client (e.g., for uploading 
  /// a massive video file), you shouldn't mutate the global config. Instead, use 
  /// `copyWith` to inherit all security and base URL settings while extending 
  /// the timeout exclusively for the new client.
  /// 
  /// ```dart
  /// final uploadConfig = globalConfig.copyWith(timeout: Duration(minutes: 5));
  /// final uploadClient = ZapClient(config: uploadConfig);
  /// ```
  /// 
  /// {@macro zap_config}
  ZapConfig copyWith({
    bool? allowAutoSignedCert,
    String? userAgent,
    bool? sendUserAgent,
    String? baseUrl,
    String? defaultContentType,
    bool? followRedirects,
    int? maxRedirects,
    int? maxAuthRetries,
    ResponseDecoder? defaultDecoder,
    Duration? timeout,
    List<ZapTrustedCertificate>? trustedCertificates,
    ProxyFinder? findProxy,
    bool? withCredentials,
    bool? errorSafety,
  }) {
    return ZapConfig(
      userAgent: userAgent ?? this.userAgent,
      allowAutoSignedCert: allowAutoSignedCert ?? this.allowAutoSignedCert,
      sendUserAgent: sendUserAgent ?? this.sendUserAgent,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultContentType: defaultContentType ?? this.defaultContentType,
      followRedirects: followRedirects ?? this.followRedirects,
      maxAuthRetries: maxAuthRetries ?? this.maxAuthRetries,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      defaultDecoder: defaultDecoder ?? this.defaultDecoder,
      timeout: timeout ?? this.timeout,
      trustedCertificates: trustedCertificates ?? this.trustedCertificates,
      findProxy: findProxy ?? this.findProxy,
      withCredentials: withCredentials ?? this.withCredentials,
      errorSafety: errorSafety ?? this.errorSafety,
    );
  }
}