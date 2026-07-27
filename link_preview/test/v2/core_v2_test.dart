import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:link_preview/src/v2/core_v2.dart';

void main() {
  group('responseToDocument', () {
    test('returns null for non-200 status code', () {
      final response = http.Response(
        '',
        404,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNull);
    });

    test('returns null for 500 status code', () {
      final response = http.Response(
        '',
        500,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNull);
    });

    test('returns null for 301 redirect status code', () {
      final response = http.Response(
        '',
        301,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNull);
    });

    test('returns null for 403 forbidden status code', () {
      final response = http.Response(
        '',
        403,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNull);
    });

    test('returns Document for 200 status with valid HTML', () {
      final body = utf8.encode('''
        <html><head>
          <title>Test Page</title>
          <meta property="og:title" content="OG Title">
        </head><body></body></html>
      ''');
      final response = http.Response.bytes(
        body,
        200,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNotNull);
      expect(document!.head?.querySelector('title')?.text, 'Test Page');
    });

    test('returns Document for 200 status with empty HTML body', () {
      final body = utf8.encode('<html><head></head><body></body></html>');
      final response = http.Response.bytes(
        body,
        200,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNotNull);
    });

    test('returns Document for 200 status with minimal HTML', () {
      final body = utf8.encode('<html></html>');
      final response = http.Response.bytes(
        body,
        200,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNotNull);
    });

    test('returns Document for 200 status with malformed HTML', () {
      final body = utf8.encode('<html><head><title>Broken</head></body>');
      final response = http.Response.bytes(
        body,
        200,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNotNull);
    });

    test('returns Document for 200 status with incomplete HTML', () {
      final body = utf8.encode('<html><head><meta name="test" content="value">');
      final response = http.Response.bytes(
        body,
        200,
        headers: {'content-type': 'text/html'},
      );
      final document = responseToDocument(response);
      expect(document, isNotNull);
    });

    test('handles UTF-8 encoded content correctly', () {
      final body = utf8.encode('''
        <html><head>
          <title>Unicode: \u00e9\u00e0\u00fc</title>
        </head><body></body></html>
      ''');
      final response = http.Response.bytes(
        body,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
      final document = responseToDocument(response);
      expect(document, isNotNull);
    });
  });
}