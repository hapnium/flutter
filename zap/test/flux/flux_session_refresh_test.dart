import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late int refreshCount;

  Future<void> writeJson(HttpRequest request, int statusCode, Map<String, dynamic> body) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  Map<String, dynamic> ok(dynamic data) => {'status': 'success', 'code': 200, 'message': 'ok', 'data': data};

  setUp(() {
    refreshCount = 0;
  });

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';

    server.listen((HttpRequest request) async {
      switch (request.uri.path) {
        case '/protected':
          final auth = request.headers.value('authorization');
          if (auth == 'Bearer fresh') {
            await writeJson(request, 200, ok({'who': 'you'}));
          } else {
            await writeJson(request, 401, {'status': 'error', 'code': 401, 'message': 'token expired'});
          }
          return;
        case '/echo-headers':
          final headers = <String, dynamic>{};
          request.headers.forEach((key, values) {
            headers[key] = values.join(', ');
          });
          await writeJson(request, 200, ok({'headers': headers}));
          return;
        default:
          await writeJson(request, 200, ok(null));
      }
    });
  });

  tearDown(() {
    Flux.dispose();
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  Flux newFlux({
    required SessionResponse? Function() sessionFactory,
    AsyncSessionCallback? onSessionRefreshed,
  }) {
    return Flux(
      config: FluxConfig(
        useSingleInstance: true,
        disposeOnCompleted: false,
        zapConfig: ZapConfig(baseUrl: baseUrl),
        sessionFactory: sessionFactory,
        onSessionRefreshed: onSessionRefreshed,
      ),
    );
  }

  test('concurrent 401s coalesce into a single session refresh', () async {
    SessionResponse? session = SessionResponse(accessToken: 'stale', refreshToken: 'r1');

    final flux = newFlux(
      sessionFactory: () => session,
      onSessionRefreshed: () async {
        refreshCount++;
        // Keep the refresh in flight long enough for the other two
        // requests to arrive and coalesce onto it.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        session = SessionResponse(accessToken: 'fresh', refreshToken: 'r2');
        return session;
      },
    );

      final results = await Future.wait(List.generate(
      3,
      (_) => flux.get(endpoint: '/protected', useAuth: true),
    ));

    for (final response in results) {
      expect(response.status.code, 200);
    }
    // Before coalescing, three parallel refreshes raced here (and
    // invalidated single-use refresh tokens).
    expect(refreshCount, 1);
  });

  test('a fresh session prevents further refreshes on later requests', () async {
    SessionResponse? session = SessionResponse(accessToken: 'stale', refreshToken: 'r1');

    final flux = newFlux(
      sessionFactory: () => session,
      onSessionRefreshed: () async {
        refreshCount++;
        session = SessionResponse(accessToken: 'fresh', refreshToken: 'r2');
        return session;
      },
    );

    final first = await flux.get(endpoint: '/protected', useAuth: true);
    expect(first.status.code, 200);
    expect(refreshCount, 1);

    final second = await flux.get(endpoint: '/protected', useAuth: true);
    expect(second.status.code, 200);
    expect(refreshCount, 1, reason: 'the refreshed session must satisfy later requests');
  });

  test('a failed refresh reports no session instead of throwing', () async {
    final session = SessionResponse(accessToken: 'stale', refreshToken: 'r1');

    final flux = newFlux(
      sessionFactory: () => session,
      onSessionRefreshed: () async {
        refreshCount++;
        throw Exception('refresh endpoint down');
      },
    );

    final response = await flux.get(endpoint: '/protected', useAuth: true);

    expect(response.status.code, 401);
    expect(refreshCount, 1);
  });

  test('an empty access token produces no Authorization header', () async {
    final session = SessionResponse(accessToken: '', refreshToken: 'r1');

    final flux = newFlux(sessionFactory: () => session);

    final response = await flux.get(endpoint: '/echo-headers', useAuth: true);

    expect(response.status.code, 200);
    final headers = response.body?.data?['headers'] as Map<String, dynamic>?;
    expect(headers, isNotNull);
    expect(headers!.containsKey('authorization'), isFalse,
        reason: 'must not send `Authorization: Bearer ` for an empty token');
  });
}
