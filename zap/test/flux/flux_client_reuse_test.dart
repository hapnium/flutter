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
          'data': {
            'headers': headers,
            'remotePort': request.connectionInfo?.remotePort,
          },
        });
        return;
      }

      await writeJson(request, 200, {
        'status': 'success',
        'code': 200,
        'message': 'ok',
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

  group('Flux single-instance client reuse', () {
    test('sequential requests share one keep-alive connection', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      final first = await flux.get(endpoint: '/echo-headers', useAuth: false);
      final second = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(first.status.code, 200);
      expect(second.status.code, 200);

      final firstPort = first.body?.data?['remotePort'];
      final secondPort = second.body?.data?['remotePort'];
      expect(firstPort, isNotNull);
      // Same TCP connection on the server side proves the underlying
      // HttpClient is memoized and reuses its connection pool.
      expect(secondPort, firstPort);
    });

    test('config requestModifiers fire in single-instance mode', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          requestModifiers: [
            (request) async {
              request.headers['X-Config-Modifier'] = 'applied';
              return request;
            },
          ],
        ),
      );

      final response = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(response.status.code, 200);
      expect(response.body?.data?['headers']?['x-config-modifier'], 'applied');
    });

    test('config responseModifiers fire in single-instance mode', () async {
      final statusLog = <int>[];

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
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

      await flux.get(endpoint: '/ok', useAuth: false);

      expect(statusLog, [200]);
    });

    test('Flux.addRequestModifier applies to subsequent requests in single-instance mode', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      flux.addRequestModifier<void>((request) async {
        request.headers['X-Runtime-Modifier'] = 'applied';
        return request;
      });

      final first = await flux.get(endpoint: '/echo-headers', useAuth: false);
      final second = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(first.body?.data?['headers']?['x-runtime-modifier'], 'applied');
      expect(second.body?.data?['headers']?['x-runtime-modifier'], 'applied');
    });

    test('Flux.addResponseModifier applies in single-instance mode', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      final statusLog = <int>[];
      flux.addResponseModifier<void>((request, response) async {
        statusLog.add(response.status.code);
        return response;
      });

      await flux.get(endpoint: '/ok', useAuth: false);

      expect(statusLog, [200]);
    });

    test('Flux.addRequestModifier applies per-request in multi-instance mode', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      flux.addRequestModifier<void>((request) async {
        request.headers['X-Runtime-Modifier'] = 'multi';
        return request;
      });

      final response = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(response.status.code, 200);
      expect(response.body?.data?['headers']?['x-runtime-modifier'], 'multi');
    });

    test('removeRequestModifier stops future requests from being modified', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      FutureOr<Request<Object?>> modifier(Request<Object?> request) async {
        request.headers['X-Removed'] = 'yes';
        return request;
      }

      flux.addRequestModifier<void>(modifier);
      flux.removeRequestModifier<void>(modifier);

      final response = await flux.get(endpoint: '/echo-headers', useAuth: false);

      expect(response.status.code, 200);
      expect(response.body?.data?['headers']?['x-removed'], isNull);
    });
  });

  group('Flux disposal', () {
    test('dispose closes the cached client and releases the singleton', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      final response = await flux.get(endpoint: '/ok', useAuth: false);
      expect(response.status.code, 200);

      Flux.dispose();

      expect(() => Flux.instance, throwsA(isA<ZapException>()));
    });

    test('dispose without any request is a safe no-op', () {
      Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      expect(Flux.dispose, returnsNormally);
      expect(() => Flux.instance, throwsA(isA<ZapException>()));
    });

    test('disposeOnCompleted disposes the singleton after the request', () async {
      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: true,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );

      final response = await flux.get(endpoint: '/ok', useAuth: false);

      expect(response.status.code, 200);
      expect(() => Flux.instance, throwsA(isA<ZapException>()));
    });

    test('a new Flux can be created after dispose', () async {
      Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );
      final first = await Flux.instance.get(endpoint: '/ok', useAuth: false);
      expect(first.status.code, 200);

      Flux.dispose();

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
        ),
      );
      final second = await flux.get(endpoint: '/ok', useAuth: false);
      expect(second.status.code, 200);
    });
  });
}
