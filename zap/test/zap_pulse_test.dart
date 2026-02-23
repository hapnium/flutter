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

    server.listen((request) async {
      final path = request.uri.path;
      final auth = request.headers.value('authorization');

      if (path == '/public' && request.method == 'GET') {
        await writeJson(request, 200, {
          'status': 'success',
          'code': 200,
          'message': 'ok',
          'data': {'public': true}
        });
        return;
      }

      if (path == '/protected' && request.method == 'GET') {
        if (auth == 'Bearer valid-token') {
          await writeJson(request, 200, {
            'status': 'success',
            'code': 200,
            'message': 'ok',
            'data': {'protected': true}
          });
        } else {
          await writeJson(request, 401, {
            'status': 'error',
            'code': 401,
            'message': 'unauthorized',
            'data': null
          });
        }
        return;
      }

      if (path == '/echo' && request.method == 'POST') {
        final payload = jsonDecode(await utf8.decoder.bind(request).join());
        await writeJson(request, 201, {
          'status': 'success',
          'code': 201,
          'message': 'created',
          'data': payload,
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

  group('Flux Tests', () {
    test('GET request without authentication', () async {
      final flux = Flux(
        config: FluxConfig(
          zapConfig: ZapConfig(baseUrl: baseUrl),
          disposeOnCompleted: false,
        ),
      );

      final response = await flux.get(endpoint: '/public', useAuth: false);

      expect(response.status.code, 200);
      expect(response.body?.code, 200);
      expect(response.body?.data?['public'], true);
    });

    test('GET request with valid authentication session', () async {
      final flux = Flux(
        config: FluxConfig(
          zapConfig: ZapConfig(baseUrl: baseUrl),
          disposeOnCompleted: false,
          sessionFactory: () => SessionResponse(
            accessToken: 'valid-token',
            refreshToken: 'r1',
          ),
        ),
      );

      final response = await flux.get(endpoint: '/protected', useAuth: true);

      expect(response.status.code, 200);
      expect(response.body?.code, 200);
      expect(response.body?.data?['protected'], true);
    });

    test('POST request sends body', () async {
      final flux = Flux(
        config: FluxConfig(
          zapConfig: ZapConfig(baseUrl: baseUrl),
          disposeOnCompleted: false,
        ),
      );

      final response = await flux.post(
        endpoint: '/echo',
        body: {'name': 'zap'},
        useAuth: false,
      );

      expect(response.status.code, 201);
      expect(response.body?.code, 201);
      expect(response.body?.data?['name'], 'zap');
    });

    test('Throws when auth is required but session is missing', () async {
      final flux = Flux(
        config: FluxConfig(
          zapConfig: ZapConfig(baseUrl: baseUrl),
          disposeOnCompleted: false,
        ),
      );

      expect(
        () => flux.get(endpoint: '/protected', useAuth: true),
        throwsA(isA<Exception>()),
      );
    });

    test('Singleton pattern enforcement', () {
      Flux(config: FluxConfig(zapConfig: ZapConfig(baseUrl: baseUrl), disposeOnCompleted: false));

      expect(
        () => Flux(config: FluxConfig(zapConfig: ZapConfig(baseUrl: baseUrl), disposeOnCompleted: false)),
        throwsA(isA<Exception>()),
      );
    });
  });
}
