import 'dart:async';

import '../router/smart_route_decoder.dart';

abstract class SmartMiddleware {
  /// Called before entering route to allow redirects
  FutureOr<SmartRouteDecoder?> redirect(SmartRouteDecoder route) async => route;
}