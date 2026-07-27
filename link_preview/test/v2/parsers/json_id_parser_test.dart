import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:link_preview/src/v2/parsers/json_id_parser.dart';

void main() {
  group('JsonLdParser', () {
    test('extracts name from JSON-LD Map structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "JSON LD Title", "description": "JSON LD description"}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.title, 'JSON LD Title');
    });

    test('extracts headline as fallback for title in Map structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "Article", "headline": "Article Headline"}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.title, 'Article Headline');
    });

    test('extracts description from JSON-LD Map structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "Page", "description": "A detailed description"}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.description, 'A detailed description');
    });

    test('extracts image from JSON-LD Map structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "Page", "image": "https://example.com/ld-image.png"}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://example.com/ld-image.png');
    });

    test('extracts logo from JSON-LD Map structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "Organization", "name": "Org", "logo": "https://example.com/logo.png"}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://example.com/logo.png');
    });

    test('extracts name from JSON-LD List structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            [{"@type": "WebPage", "name": "List Title", "description": "List description", "image": "https://example.com/list.png"}]
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.title, 'List Title');
      expect(parser.description, 'List description');
      expect(parser.image!.url, 'https://example.com/list.png');
    });

    test('falls back to og:site_name for siteName', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "Page"}
          </script>
          <meta property="og:site_name" content="OG Site">
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.siteName, 'OG Site');
    });

    test('returns null for missing JSON-LD script tag', () {
      final document = html_parser.parse('''
        <html><head></head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
    });

    test('returns null for empty document', () {
      final document = html_parser.parse('');
      final parser = JsonLdParser(document);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
    });

    test('returns null for null document', () {
      final parser = JsonLdParser(null);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
    });

    test('returns null image when image is null literal string', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "Page", "image": "null"}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.image, isNull);
    });

    test('handles JSON-LD with image as list in Map structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "Page", "image": ["https://example.com/img1.png", "https://example.com/img2.png"]}
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.image!.url, 'https://example.com/img1.png');
    });

    test('handles JSON-LD with logo as list in List structure', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            [{"@type": "Organization", "name": "Org", "logo": ["https://example.com/logo1.png"]}]
          </script>
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      expect(parser.image!.url, 'https://example.com/logo1.png');
    });

    test('parse returns LinkPreviewData with extracted fields', () {
      final document = html_parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "WebPage", "name": "Parsed Name", "description": "Parsed desc", "image": "https://example.com/parsed.png"}
          </script>
          <meta property="og:site_name" content="ParsedSite">
        </head><body></body></html>
      ''');
      final parser = JsonLdParser(document);
      final data = parser.parse();
      expect(data.title, 'Parsed Name');
      expect(data.description, 'Parsed desc');
      expect(data.image!.url, 'https://example.com/parsed.png');
      expect(data.siteName, 'ParsedSite');
    });
  });
}