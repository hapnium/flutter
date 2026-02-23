import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late Map<String, List<String?>> authAttempts;

  Future<void> writeJson(HttpRequest request, int statusCode, Map<String, dynamic> body) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  setUpAll(() async {
    authAttempts = <String, List<String?>>{};

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';

    server.listen((HttpRequest request) async {
      final path = request.uri.path;
      final auth = request.headers.value('authorization');
      authAttempts.putIfAbsent(path, () => <String?>[]).add(auth);

      if (path == '/protected') {
        if (auth == 'Bearer refreshed-token') {
          await writeJson(request, 200, {
            'status': 'success',
            'code': 200,
            'message': 'ok',
            'data': {'authorized': true}
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

      if (path == '/always-unauthorized') {
        await writeJson(request, 401, {
          'status': 'error',
          'code': 401,
          'message': 'unauthorized',
          'data': null
        });
        return;
      }

      await writeJson(request, 404, {
        'status': 'error',
        'code': 404,
        'message': 'not found',
        'data': null
      });
    });
  });

  tearDown(() {
    Flux.dispose();
    authAttempts.clear();
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  group('Flux refresh retry', () {
    test('retries unauthorized request after refresh when useSingleInstance is true', () async {
      SessionResponse currentSession = SessionResponse(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
      );

      int refreshCalls = 0;
      bool unauthorizedCalled = false;

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          sessionFactory: () => currentSession,
          onSessionRefreshed: () async {
            refreshCalls += 1;
            currentSession = SessionResponse(
              accessToken: 'refreshed-token',
              refreshToken: 'refresh-token-2',
            );
            return currentSession;
          },
          whenUnauthorized: () {
            unauthorizedCalled = true;
          },
        ),
      );

      final response = await flux.get(endpoint: '/protected', useAuth: true);

      expect(response.status.code, 200);
      expect(response.body?.code, 200);
      expect(response.body?.data?['authorized'], true);
      expect(refreshCalls, 1);
      expect(unauthorizedCalled, false);
      expect(authAttempts['/protected'], [
        'Bearer expired-token',
        'Bearer refreshed-token',
      ]);
    });

    test('retries unauthorized request after refresh when useSingleInstance is false', () async {
      SessionResponse currentSession = SessionResponse(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
      );

      int refreshCalls = 0;
      bool unauthorizedCalled = false;

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: false,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          sessionFactory: () => currentSession,
          onSessionRefreshed: () async {
            refreshCalls += 1;
            currentSession = SessionResponse(
              accessToken: 'refreshed-token',
              refreshToken: 'refresh-token-2',
            );
            return currentSession;
          },
          whenUnauthorized: () {
            unauthorizedCalled = true;
          },
        ),
      );

      final response = await flux.get(endpoint: '/protected', useAuth: true);

      expect(response.status.code, 200);
      expect(response.body?.code, 200);
      expect(response.body?.data?['authorized'], true);
      expect(refreshCalls, 1);
      expect(unauthorizedCalled, false);
      expect(authAttempts['/protected'], [
        'Bearer expired-token',
        'Bearer refreshed-token',
      ]);
    });

    test('returns unauthorized and calls whenUnauthorized when refresh fails', () async {
      SessionResponse currentSession = SessionResponse(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
      );

      int refreshCalls = 0;
      bool unauthorizedCalled = false;

      final flux = Flux(
        config: FluxConfig(
          useSingleInstance: true,
          disposeOnCompleted: false,
          zapConfig: ZapConfig(baseUrl: baseUrl),
          sessionFactory: () => currentSession,
          onSessionRefreshed: () async {
            refreshCalls += 1;
            return null;
          },
          whenUnauthorized: () {
            unauthorizedCalled = true;
          },
        ),
      );

      final response = await flux.get(endpoint: '/always-unauthorized', useAuth: true);

      expect(response.status.code, 401);
      expect(response.body?.code, 401);
      expect(refreshCalls, 1);
      expect(unauthorizedCalled, true);
      expect(authAttempts['/always-unauthorized']?.isNotEmpty, true);
    });
  });
}
