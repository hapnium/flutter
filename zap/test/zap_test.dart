import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late Zap zap;
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
      switch (request.uri.path) {
        case '/get':
          await writeJson(request, 200, {'id': 1, 'title': 'ok'});
          return;
        case '/query':
          await writeJson(request, 200, {'userId': request.uri.queryParameters['userId']});
          return;
        case '/post':
          final payload = jsonDecode(await utf8.decoder.bind(request).join());
          await writeJson(request, 201, payload as Map<String, dynamic>);
          return;
        case '/upload':
          final bytes = await request.fold<List<int>>(<int>[], (acc, chunk) {
            acc.addAll(chunk);
            return acc;
          });
          await writeJson(request, 201, {'size': bytes.length});
          return;
        case '/put':
        case '/patch':
          final payload = jsonDecode(await utf8.decoder.bind(request).join());
          await writeJson(request, 200, payload as Map<String, dynamic>);
          return;
        case '/delete':
          await writeJson(request, 200, {'deleted': true});
          return;
        case '/delay':
          await Future.delayed(const Duration(seconds: 2));
          await writeJson(request, 200, {'delayed': true});
          return;
        case '/404':
          await writeJson(request, 404, {'error': 'not found'});
          return;
        default:
          await writeJson(request, 400, {'error': 'bad request'});
          return;
      }
    });
  });

  setUp(() {
    zap = Zap();
  });

  tearDown(() {
    zap.dispose();
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  group('Zap HTTP Tests', () {
    test('GET request', () async {
      final response = await zap.get<Map<String, dynamic>>('$baseUrl/get');
      expect(response.status.code, 200);
      expect(response.body?['id'], 1);
    });

    test('GET request with query', () async {
      final response = await zap.get<Map<String, dynamic>>(
        '$baseUrl/query',
        query: {'userId': 7},
      );
      expect(response.status.code, 200);
      expect(response.body?['userId'], '7');
    });

    test('POST request', () async {
      final response = await zap.post<Map<String, dynamic>>(
        '$baseUrl/post',
        {'title': 'hello'},
      );
      expect(response.status.code, 201);
      expect(response.body?['title'], 'hello');
    });

    test('POST upload progress callback reports completion', () async {
      final progressUpdates = <double>[];
      final payload = 'x' * 200000; // 200 KB

      final response = await zap.post<Map<String, dynamic>>(
        '$baseUrl/upload',
        payload,
        uploadProgress: (percent) {
          progressUpdates.add(percent);
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(response.status.code, 201);
      expect(response.body?['size'], payload.length);
      expect(progressUpdates.isNotEmpty, true);
      expect(progressUpdates.first, 0.0);
      expect(progressUpdates.last, 100.0);
    });

    test('PUT request', () async {
      final response = await zap.put<Map<String, dynamic>>(
        '$baseUrl/put',
        {'title': 'updated'},
      );
      expect(response.status.code, 200);
      expect(response.body?['title'], 'updated');
    });

    test('PATCH request', () async {
      final response = await zap.patch<Map<String, dynamic>>(
        '$baseUrl/patch',
        {'title': 'patched'},
      );
      expect(response.status.code, 200);
      expect(response.body?['title'], 'patched');
    });

    test('DELETE request', () async {
      final response = await zap.delete<Map<String, dynamic>>('$baseUrl/delete');
      expect(response.status.code, 200);
      expect(response.body?['deleted'], true);
    });

    test('404 response handling', () async {
      final response = await zap.get<Map<String, dynamic>>('$baseUrl/404');
      expect(response.status.code, 404);
      expect(response.hasError, true);
    });

    test('invalid url handling', () async {
      final response = await zap.get<Map<String, dynamic>>('http://invalid-domain-zap-test.local');
      expect(response.hasError, true);
    });

    test('request cancellation works', () async {
      final token = CancelToken();
      final future = zap.get<Map<String, dynamic>>('$baseUrl/delay', cancelToken: token);

      Future.delayed(const Duration(milliseconds: 100), () {
        token.cancel('cancelled by test');
      });

      expect(future, throwsA(isA<Exception>()));
    });

    test('cancel all active requests', () async {
      final token1 = CancelToken();
      final token2 = CancelToken();
      final token3 = CancelToken();

      final futures = <Future<Response<Map<String, dynamic>>>>[
        zap.get<Map<String, dynamic>>('$baseUrl/delay', cancelToken: token1),
        zap.get<Map<String, dynamic>>('$baseUrl/delay', cancelToken: token2),
        zap.get<Map<String, dynamic>>('$baseUrl/delay', cancelToken: token3),
      ];

      Future.delayed(const Duration(milliseconds: 100), () {
        zap.cancelAllRequests('bulk cancel');
      });

      for (final future in futures) {
        expect(future, throwsA(isA<Exception>()));
      }
    });
  });
}
