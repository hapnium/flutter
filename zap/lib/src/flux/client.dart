import '../http/request/request.dart';
import '../core/zap_interface.dart';
import '../models/flux_config.dart';
import '../core/zap.dart';
import 'extension.dart';

/// [fluxClient] is a factory function that returns a [ZapInterface] instance.
/// 
/// It is used to create a new instance of [Zap] or [_Connect] based on the configuration.
/// 
/// It is used internally by [Flux] to provide a more robust and flexible HTTP client.
ZapInterface fluxClient(FluxConfig config, [bool useAuth = false]) {
  if(config.useSingleInstance) {
    return Zap(zapConfig: config.zapConfig);
  } else {
    return _Connect(config, useAuth);
  }
}

/// {@template connect}
/// [_Connect] is a private class that extends [Zap] and implements the [ZapInterface].
/// 
/// It uses the design system of [Zap] to provide a more robust and flexible HTTP client.
/// 
/// It is used internally by [Flux] to provide a more robust and flexible HTTP client.
/// 
/// {@endtemplate}
class _Connect extends Zap {
  final bool useAuth;
  final FluxConfig fx;

  /// {@macro connect}
  _Connect(this.fx, this.useAuth) : super(zapConfig: fx.zapConfig);

  @override
  void onInit() {
    if(fx.headers != null) {
      client.addRequestModifier<void>((Request request) async {
        request.headers.addAll(fx.buildHeaders());
        
        return request;
      });
    }

    if(useAuth) {
      fx.checkAuth(useAuth);

      client.addRequestModifier<void>((Request request) async {
        if (fx.currentSession != null) {
          request.headers.addAll(fx.buildHeadersWithAuth());
        }
        
        return request;
      });
    }

    super.onInit();
  }
}