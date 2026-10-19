import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  Future<void> writeJson(HttpRequest request, int statusCode, Map<String, dynamic> body) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';

    server.listen((HttpRequest request) async {
      final path = request.uri.path;

      if (path == '/echo-headers') {
        final headers = <String, dynamic>{};
        request.headers.forEach((key, values) {
          headers[key] = values.join(', ');
        });
        await writeJson(request, 200, {
          'status': 'success',
          'code': 200,
          'message': 'ok',
          'data': {'headers': headers},
        });
        return;
      }

      if (path == '/ok') {
        await writeJson(request, 200, {
          'status': 'success',
          'code': 200,
          'message': 'ok',
          'data': {'value': 42},
        });
        return;
      }

      await writeJson(request, 404, {
        'status': 'error',
        'code': 404,
        'message': 'not found',
        'data': null,
      });
    });
  });

  tearDown(() {
    Flux.dispose();
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  group('FluxConfig copyWith with modifiers', () {
    test('copyWith preserves requestModifiers', () {
      final reqMod = <RequestModifier>[];
      final config = FluxConfig(requestModifiers: reqMod);
      final copied = config.copyWith(showRequestLogs: true);
      expect(copied.requestModifiers, same(reqMod));
    });

    test('copyWith preserves responseModifiers', () {
      final resMod = <ResponseModifier>[];
      final config = FluxConfig(responseModifiers: resMod);
      final copied = config.copyWith(showRequestLogs: true);
      expect(copied.responseModifiers, same(resMod));
    });

    test('copyWith updates requestModifiers', () {
      final original = FluxConfig(requestModifiers: []);
      final newReq = <RequestModifier>[];
      final copied = original.copyWith(requestModifiers: newReq);
      expect(copied.requestModifiers, same(newReq));
    });

    test('copyWith updates responseModifiers', () {
      final original = FluxConfig(responseModifiers: []);
      final newRes = <ResponseModifier>[];
      final copied = original.copyWith(responseModifiers: newRes);
      expect(copied.responseModifiers, same(newRes));
    });

    test('copyWith with null modifiers keeps originals', () {
      final reqMod = <RequestModifier>[];
      final resMod = <ResponseModifier>[];
      final config = FluxConfig(requestModifiers: reqMod, responseModifiers: resMod);
      final copied = config.copyWith(showRequestLogs: true);
      expect(copied.requestModifiers, same(reqMod));
      expect(copied.responseModifiers, same(resMod));
    });
  });

  group('FluxConfig constructor defaults', () {
    test('requestModifiers defaults to null', () {
      final config = FluxConfig();
      expect(config.requestModifiers, isNull);
    });

    test('responseModifiers defaults to null', () {
      final config = FluxConfig();
      expect(config.responseModifiers, isNull);
    });
  });

  group('Config-level requestModifiers via _Connect (useSingleInstance: false)', () {
    test('config requestModifiers are applied to request', () async {
      final List<String> headerLog = [];

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          requestModifiers: [
            (request) async {
              request.headers['X-Custom-Modifier'] = 'from-config';
              return request;
            },
            (request) async {
              headerLog.add(request.headers['X-Custom-Modifier'] ?? 'missing');
              return request;
            },
          ],
        ),
      );

      final response = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(response.status.code, 200);
      expect(headerLog, ['from-config']);
    });

    test('config responseModifiers are applied to response', () async {
      final List<int> statusLog = [];

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          responseModifiers: [
            (request, response) async {
              statusLog.add(response.status.code);
              return response;
            },
          ],
        ),
      );

      final response = await flux.get(endpoint: '/ok', useAuth: false);

      expect(response.status.code, 200);
      expect(statusLog, [200]);
    });

    test('config requestModifiers and responseModifiers fire in order', () async {
      final List<String> log = [];

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          requestModifiers: [
            (request) async {
              log.add('request-modifier');
              request.headers['X-Modified'] = 'true';
              return request;
            },
          ],
          responseModifiers: [
            (request, response) async {
              log.add('response-modifier');
              return response;
            },
          ],
        ),
      );

      final response = await flux.get(endpoint: '/ok', useAuth: false);

      expect(response.status.code, 200);
      expect(log, ['request-modifier', 'response-modifier']);
    });

    test('config modifiers work across multiple requests', () async {
      int requestCount = 0;

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          requestModifiers: [
            (request) async {
              requestCount++;
              return request;
            },
          ],
        ),
      );

      await flux.get(endpoint: '/ok', useAuth: false);
      await flux.get(endpoint: '/ok', useAuth: false);
      await flux.get(endpoint: '/ok', useAuth: false);

      expect(requestCount, 3);
    });

    test('config requestModifiers can add headers visible on server', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          requestModifiers: [
            (request) async {
              request.headers['X-From-Config'] = 'yes';
              return request;
            },
          ],
        ),
      );

      final response = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(response.status.code, 200);
      expect(response.body?.data?['headers']?['x-from-config'], 'yes');
    });
  });

  group('Config-level responseModifiers via _Connect (useSingleInstance: false)', () {
    test('config responseModifiers receive request and response', () async {
      String? capturedMethod;

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          responseModifiers: [
            (request, response) async {
              capturedMethod = request.method;
              return response;
            },
          ],
        ),
      );

      await flux.get(endpoint: '/ok', useAuth: false);

      expect(capturedMethod, 'GET');
    });

    test('multiple config responseModifiers fire in order', () async {
      final List<String> log = [];

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          responseModifiers: [
            (request, response) async {
              log.add('first');
              return response;
            },
            (request, response) async {
              log.add('second');
              return response;
            },
          ],
        ),
      );

      await flux.get(endpoint: '/ok', useAuth: false);

      expect(log, ['first', 'second']);
    });

    test('multiple config requestModifiers fire in order', () async {
      final List<String> log = [];

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          requestModifiers: [
            (request) async {
              log.add('first');
              return request;
            },
            (request) async {
              log.add('second');
              return request;
            },
          ],
        ),
      );

      await flux.get(endpoint: '/ok', useAuth: false);

      expect(log, ['first', 'second']);
    });
  });

  group('Flux instance-level modifier API', () {
    test('addRequestModifier does not throw', () {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      expect(
        () => flux.addRequestModifier<void>((request) async => request),
        returnsNormally,
      );
    });

    test('addResponseModifier does not throw', () {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      expect(
        () => flux.addResponseModifier<void>((request, response) async => response),
        returnsNormally,
      );
    });

    test('removeRequestModifier does not throw', () {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      FutureOr<Request<Object?>> modifier(Request<Object?> request) async => request;
      flux.addRequestModifier<void>(modifier);

      expect(() => flux.removeRequestModifier<void>(modifier), returnsNormally);
    });

    test('removeResponseModifier does not throw', () {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      FutureOr<dynamic> modifier(Request<Object?> request, Response<Object?> response) async => response;
      flux.addResponseModifier<void>(modifier);

      expect(() => flux.removeResponseModifier<void>(modifier), returnsNormally);
    });
  });

  group('Config-level modifiers with headers configuration', () {
    test('config headers and requestModifiers both apply', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          headers: {'X-Global': 'global-value'},
          requestModifiers: [
            (request) async {
              request.headers['X-Modifier'] = 'modifier-value';
              return request;
            },
          ],
        ),
      );

      final response = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(response.status.code, 200);
      expect(response.body?.data?['headers']?['x-global'], 'global-value');
      expect(response.body?.data?['headers']?['x-modifier'], 'modifier-value');
    });
  });
}