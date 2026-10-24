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

  Map<String, dynamic> ok(dynamic data) => {'status': 'success', 'code': 200, 'message': 'ok', 'data': data};

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';

    server.listen((HttpRequest request) async {
      switch (request.uri.path) {
        case '/login':
          request.response.headers.add('set-cookie', 'session=abc123; Path=/');
          await writeJson(request, 200, ok(null));
          return;
        case '/admin/login':
          request.response.headers.add('set-cookie', 'adminonly=1; Path=/admin');
          await writeJson(request, 200, ok(null));
          return;
        case '/admin/echo':
        case '/echo-headers':
          final headers = <String, dynamic>{};
          request.headers.forEach((key, values) {
            headers[key] = values.join(', ');
          });
          await writeJson(request, 200, ok({'headers': headers}));
          return;
        default:
          await writeJson(request, 404, {'status': 'error', 'code': 404, 'message': 'not found'});
      }
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  Zap newZap({bool enableCookies = true}) => Zap(
        zapConfig: ZapConfig(baseUrl: baseUrl, enableCookies: enableCookies),
      );

  /// Extracts the server-side request headers from an `/echo-*` response.
  Map<String, dynamic> echoedHeaders(Response<dynamic> echo) {
    final body = echo.body as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return data['headers'] as Map<String, dynamic>;
  }

  test('cookies set by a response are sent on subsequent requests', () async {
    final zap = newZap();

    await zap.get('/login');
    final echo = await zap.get('/echo-headers');

    expect(echoedHeaders(echo)['cookie'], contains('session=abc123'));
  });

  test('enableCookies: false drops Set-Cookie entirely', () async {
    final zap = newZap(enableCookies: false);

    await zap.get('/login');
    final echo = await zap.get('/echo-headers');

    expect(echoedHeaders(echo).containsKey('cookie'), isFalse);
  });

  test('an explicit Cookie header wins over the jar', () async {
    final zap = newZap();

    await zap.get('/login');
    final echo = await zap.get('/echo-headers', headers: {'Cookie': 'manual=1'});

    expect(echoedHeaders(echo)['cookie'], 'manual=1');
  });

  test('cookies are scoped to their Path attribute', () async {
    final zap = newZap();

    await zap.get('/admin/login');

    final inside = await zap.get('/admin/echo');
    expect(echoedHeaders(inside)['cookie'], contains('adminonly=1'));

    final outside = await zap.get('/echo-headers');
    expect(echoedHeaders(outside).containsKey('cookie'), isFalse,
        reason: 'a Path=/admin cookie must not leak to other paths');
  });

  test('cookies persist across many requests in single-instance mode', () async {
    final zap = newZap();

    await zap.get('/login');
    for (var i = 0; i < 3; i++) {
      final echo = await zap.get('/echo-headers');
      expect(echoedHeaders(echo)['cookie'], contains('session=abc123'), reason: 'iteration $i');
    }
  });
}
