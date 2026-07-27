import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/http/modifier/zap_modifier.dart';
import 'package:zap/src/http/request/request.dart';
import 'package:zap/src/http/response/response.dart';
import 'package:zap/src/http/utils/http_method.dart';
import 'package:zap/src/http/utils/http_status.dart';

void main() {
  Request makeRequest([String? url]) {
    return Request(
      url: Uri.parse(url ?? 'https://api.example.com/test'),
      method: HttpMethod.GET,
      headers: {},
    );
  }

  Response makeResponse() {
    return Response(status: HttpStatus.OK);
  }

  group('ZapModifier', () {
    test('modifyRequest with no modifiers returns original', () async {
      final mod = ZapModifier();
      final req = makeRequest();
      final result = await mod.modifyRequest(req);
      expect(identical(result, req), isTrue);
    });

    test('modifyResponse with no modifiers returns original', () async {
      final mod = ZapModifier();
      final req = makeRequest();
      final res = makeResponse();
      final result = await mod.modifyResponse(req, res);
      expect(identical(result, res), isTrue);
    });

    test('request modifier chain is applied in order', () async {
      final mod = ZapModifier();
      final results = <String>[];

      mod.addRequestModifier<dynamic>((request) {
        results.add('first');
        return Request.from(request);
      });
      mod.addRequestModifier<dynamic>((request) {
        results.add('second');
        return request;
      });

      await mod.modifyRequest(makeRequest());
      expect(results, ['first', 'second']);
    });

    test('response modifier chain is applied in order', () async {
      final mod = ZapModifier();
      final results = <String>[];

      mod.addResponseModifier<dynamic>((req, res) {
        results.add('first');
        return res;
      });
      mod.addResponseModifier<dynamic>((req, res) {
        results.add('second');
        return res;
      });

      await mod.modifyResponse(makeRequest(), makeResponse());
      expect(results, ['first', 'second']);
    });

    test('removeRequestModifier removes the modifier', () async {
      final mod = ZapModifier();
      var called = false;

      FutureOr<Request<Object?>> modifier(Request<Object?> request) async {
        called = true;
        return Request.from(request);
      }

      mod.addRequestModifier<dynamic>(modifier);
      mod.removeRequestModifier<dynamic>(modifier);

      await mod.modifyRequest(makeRequest());
      expect(called, isFalse);
    });

    test('removeResponseModifier removes the modifier', () async {
      final mod = ZapModifier();
      var called = false;

      FutureOr<dynamic> modifier(Request<Object?> req, Response<Object?> res) async {
        called = true;
        return res;
      }

      mod.addResponseModifier<dynamic>(modifier);
      mod.removeResponseModifier<dynamic>(modifier);

      await mod.modifyResponse(makeRequest(), makeResponse());
      expect(called, isFalse);
    });

    test('authenticator can be set', () {
      final mod = ZapModifier();
      mod.authenticator = (request) async {
        return request.copyWith(headers: {'Authorization': 'Bearer token'});
      };

      expect(mod.authenticator, isNotNull);
    });

    test('request modifier can transform request', () async {
      final mod = ZapModifier();
      mod.addRequestModifier<dynamic>((request) async {
        return request.copyWith(headers: {'X-Custom': 'value'});
      });

      final result = await mod.modifyRequest(makeRequest());
      expect(result.headers['X-Custom'], 'value');
    });

    test('response modifier can transform response', () async {
      final mod = ZapModifier();
      mod.addResponseModifier<dynamic>((request, response) async {
        return response.copyWith(headers: {'X-Modified': 'true'});
      });

      final result = await mod.modifyResponse(makeRequest(), makeResponse());
      expect(result.headers!['X-Modified'], 'true');
    });
  });
}
