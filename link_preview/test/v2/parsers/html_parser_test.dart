import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:link_preview/src/v2/parsers/html_parser.dart';

void main() {
  group('HtmlMetaParser', () {
    test('extracts title from <title> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <title>Test Page Title</title>
        </head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.title, 'Test Page Title');
    });

    test('extracts description from <meta name="description"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="description" content="Page description here">
        </head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.description, 'Page description here');
    });

    test('extracts image from first <img> tag in body', () {
      final document = html_parser.parse('''
        <html><head></head>
          <body>
            <img src="https://example.com/photo.jpg" height="100" width="200">
          </body>
        </html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://example.com/photo.jpg');
    });

    test('extracts siteName from <meta name="site_name"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="site_name" content="My Website">
        </head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.siteName, 'My Website');
    });

    test('extracts all fields from complete HTML document', () {
      final document = html_parser.parse('''
        <html><head>
          <title>Complete Title</title>
          <meta name="description" content="Complete description">
          <meta name="site_name" content="Complete Site">
        </head>
          <body>
            <img src="https://example.com/banner.png" height="300" width="600">
          </body>
        </html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.title, 'Complete Title');
      expect(parser.description, 'Complete description');
      expect(parser.siteName, 'Complete Site');
      expect(parser.image!.url, 'https://example.com/banner.png');
    });

    test('returns null for missing title tag', () {
      final document = html_parser.parse('''
        <html><head></head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.title, isNull);
    });

    test('returns null for missing description meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <title>Title Only</title>
        </head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.description, isNull);
    });

    test('returns null for missing img tag', () {
      final document = html_parser.parse('''
        <html><head>
          <title>No Image</title>
        </head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.image, isNull);
    });

    test('returns null for missing site_name meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <title>No Site Name</title>
        </head><body></body></html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.siteName, isNull);
    });

    test('handles empty document', () {
      final document = html_parser.parse('');
      final parser = HtmlMetaParser(document);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
    });

    test('handles null document', () {
      final parser = HtmlMetaParser(null);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
    });

    test('parses image height and width attributes', () {
      final document = html_parser.parse('''
        <html><head></head>
          <body>
            <img src="https://example.com/sized.jpg" height="150" width="300">
          </body>
        </html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.image!.height, 150.0);
      expect(parser.image!.width, 300.0);
    });

    test('returns null image when img src is null literal string', () {
      final document = html_parser.parse('''
        <html><head></head>
          <body>
            <img src="null">
          </body>
        </html>
      ''');
      final parser = HtmlMetaParser(document);
      expect(parser.image, isNull);
    });

    test('parse returns LinkPreviewData with extracted fields', () {
      final document = html_parser.parse('''
        <html><head>
          <title>Parsed HTML Title</title>
          <meta name="description" content="Parsed HTML description">
        </head>
          <body>
            <img src="https://example.com/parsed.jpg">
          </body>
        </html>
      ''');
      final parser = HtmlMetaParser(document);
      final data = parser.parse();
      expect(data.title, 'Parsed HTML Title');
      expect(data.description, 'Parsed HTML description');
      expect(data.image!.url, 'https://example.com/parsed.jpg');
    });
  });
}