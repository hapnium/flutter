import '../http/modifier/zap_modifier.dart';
import '../http/request/request.dart';
import '../core/zap_interface.dart';
import '../models/flux_config.dart';
import '../core/zap.dart';
import 'extension.dart';

/// {@template flux_client}
/// Factory function that returns a [ZapInterface] instance configured for
/// use with the Flux networking layer.
///
/// This function creates either a plain [Zap] instance or a [_Connect]
/// instance depending on the [FluxConfig.useSingleInstance] setting:
///
/// - **Single instance mode** (`useSingleInstance: true`): Returns a
///   standard [Zap] client. Headers and auth are handled at the Flux
///   layer via request modifiers.
/// - **Multi-instance mode** (`useSingleInstance: false`): Returns a
///   [_Connect] client that integrates with [FluxConfig] for header
///   and auth management.
///
/// ### Parameters
///
/// - [config]: The [FluxConfig] containing all configuration for the
///   HTTP client, including base URL, headers, auth settings, and
///   logging preferences.
/// - [useAuth]: Whether to include authentication headers in requests.
///   Defaults to `false`. When `true`, the client validates that a
///   session is available and attaches auth headers to every request.
///
/// ### Returns
///
/// A [ZapInterface] instance ready for making HTTP requests.
///
/// ### Example
///
/// ```dart
/// final config = FluxConfig(
///   zapConfig: ZapConfig(baseUrl: 'https://api.example.com'),
///   authHeaderName: 'Authorization',
///   tokenPrefix: 'Bearer',
/// );
///
/// // Without auth
/// final client = fluxClient(config);
///
/// // With auth
/// final authClient = fluxClient(config, true);
/// ```
///
/// ### Usage
///
/// This function is used internally by [Flux] to create the underlying
/// HTTP client. You should not need to call it directly unless you are
/// building custom Flux integrations.
/// {@endtemplate}
ZapInterface fluxClient(FluxConfig config, [bool useAuth = false]) {
  if (config.useSingleInstance) {
    return Zap(zapConfig: config.zapConfig);
  } else {
    return _Connect(config, useAuth);
  }
}

/// {@template connect}
/// Private class that extends [Zap] and integrates with [FluxConfig]
/// for automatic header and authentication management.
///
/// `_Connect` is used internally by [Flux] when `useSingleInstance` is
/// `false`. It overrides [onInit] to register request modifiers that
/// automatically attach configured headers and authentication tokens
/// to every outgoing request.
///
/// ### Request modifier flow
///
/// 1. If [FluxConfig.headers] is set, a request modifier is registered
///   that adds those headers to every request.
/// 2. If [useAuth] is `true`, a second request modifier is registered
///   that adds authentication headers from the current session.
///
/// ### Example
///
/// This class is not used directly. It is created by [fluxClient]:
/// ```dart
/// final client = fluxClient(config, useAuth: true);
/// // client is a _Connect instance with auto-auth headers
/// ```
///
/// ### Lifecycle
///
/// The client follows the [ZapLifecycle] lifecycle:
/// 1. Constructor creates the client with [FluxConfig.zapConfig]
/// 2. [onInit] registers request modifiers
/// 3. Requests are made with automatic headers
/// 4. [onClose] / [onDelete] cleans up resources
/// {@endtemplate}
class _Connect extends Zap {
  /// Whether to include authentication headers in requests.
  ///
  /// When `true`, the client validates that a session is available and
  /// attaches auth headers to every request. When `false`, no auth
  /// headers are added.
  final bool useAuth;

  /// The Flux configuration containing headers, auth settings, and
  /// session management callbacks.
  final FluxConfig fx;

  /// {@macro connect}
  ///
  /// Creates a new [_Connect] instance with the given [FluxConfig] and
  /// [useAuth] flag. The underlying [Zap] client is configured with
  /// [FluxConfig.zapConfig].
  _Connect(this.fx, this.useAuth) : super(zapConfig: fx.zapConfig);

  /// Registers request modifiers for headers and authentication.
  ///
  /// This method is called once during initialization. It adds two
  /// request modifiers:
  ///
  /// 1. **Header modifier**: Adds [FluxConfig.headers] to every request
  ///   if they are configured.
  /// 2. **Auth modifier**: Adds authentication headers from the current
  ///   session if [useAuth] is `true`.
  ///
  /// ### Header modifier
  ///
  /// The header modifier runs first and adds any global headers
  /// configured in [FluxConfig.headers]:
  /// ```dart
  /// // Config: FluxConfig(headers: {'X-App-Version': '1.0'})
  /// // Request gets: X-App-Version: 1.0
  /// ```
  ///
  /// ### Auth modifier
  ///
  /// The auth modifier runs second and adds authentication headers:
  /// ```dart
  /// // Config: FluxConfig(authHeaderName: 'Authorization', tokenPrefix: 'Bearer')
  /// // Session: SessionResponse(accessToken: 'abc123')
  /// // Request gets: Authorization: Bearer abc123
  /// ```
  ///
  /// ### Modifier order
  ///
  /// Headers are merged in this order:
  /// 1. Request-specific headers (from the individual request)
  /// 2. Global headers (from [FluxConfig.headers])
  /// 3. Auth headers (from session)
  ///
  /// Later modifiers can overwrite earlier ones if keys conflict.
  @override
  void onInit() {
    // Existing header modifier
    if (fx.headers != null) {
      client.addRequestModifier<void>((Request request) async {
        request.headers.addAll(fx.buildHeaders());
        return request;
      });
    }

    // Existing auth modifier
    if (useAuth) {
      fx.checkAuth(useAuth);
      client.addRequestModifier<void>((Request request) async {
        if (fx.currentSession != null) {
          request.headers.addAll(fx.buildHeadersWithAuth());
        }
        return request;
      });
    }

    // Register global request modifiers from config
    if (fx.requestModifiers case List<RequestModifier> modifiers? when modifiers.isNotEmpty) {
      for (final modifier in modifiers) {
        client.addRequestModifier<void>((Request request) async {
          return await modifier(request);
        });
      }
    }

    // Register global response modifiers from config
    if (fx.responseModifiers case List<ResponseModifier> modifiers? when modifiers.isNotEmpty) {
      for (final modifier in modifiers) {
        client.addResponseModifier<void>((request, response) async {
          return await modifier(request, response);
        });
      }
    }

    super.onInit();
  }
}