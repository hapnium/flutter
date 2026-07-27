import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:link_preview/src/v2/parsers/og_parser.dart';

void main() {
  group('OpenGraphParser', () {
    test('extracts title from og:title meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:title" content="Test Title">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.title, 'Test Title');
    });

    test('extracts description from og:description meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:description" content="A test description">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.description, 'A test description');
    });

    test('extracts image from og:image meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:image" content="https://example.com/image.png">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://example.com/image.png');
    });

    test('extracts siteName from og:site_name meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:site_name" content="Example Site">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.siteName, 'Example Site');
    });

    test('extracts url from og:url meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:url" content="https://example.com/page">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.url, 'https://example.com/page');
    });

    test('extracts all fields from complete OpenGraph document', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:title" content="Full Title">
          <meta property="og:description" content="Full description">
          <meta property="og:image" content="https://example.com/og.png">
          <meta property="og:site_name" content="MySite">
          <meta property="og:url" content="https://example.com/path">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.title, 'Full Title');
      expect(parser.description, 'Full description');
      expect(parser.image!.url, 'https://example.com/og.png');
      expect(parser.siteName, 'MySite');
      expect(parser.url, 'https://example.com/path');
    });

    test('returns null for missing og:title', () {
      final document = html_parser.parse('''
        <html><head></head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.title, isNull);
    });

    test('returns null for missing og:description', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:title" content="Title Only">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.description, isNull);
    });

    test('returns null for missing og:image', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:title" content="No Image">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.image, isNull);
    });

    test('handles empty document', () {
      final document = html_parser.parse('');
      final parser = OpenGraphParser(document);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
      expect(parser.url, isNull);
    });

    test('handles null document', () {
      final parser = OpenGraphParser(null);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
      expect(parser.url, isNull);
    });

    test('returns null image when og:image content is null literal string', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:image" content="null">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      expect(parser.image, isNull);
    });

    test('parse returns LinkPreviewData with extracted fields', () {
      final document = html_parser.parse('''
        <html><head>
          <meta property="og:title" content="Parsed Title">
          <meta property="og:description" content="Parsed Description">
          <meta property="og:image" content="https://example.com/img.jpg">
          <meta property="og:url" content="https://example.com">
        </head><body></body></html>
      ''');
      final parser = OpenGraphParser(document);
      final data = parser.parse();
      expect(data.title, 'Parsed Title');
      expect(data.description, 'Parsed Description');
      expect(data.image!.url, 'https://example.com/img.jpg');
      expect(data.url, 'https://example.com');
    });
  });
}