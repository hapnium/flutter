import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:link_preview/src/v2/parsers/twitter_parser.dart';

void main() {
  group('TwitterParser', () {
    test('extracts title from twitter:title meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Twitter Title">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.title, 'Twitter Title');
    });

    test('extracts description from twitter:description meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:description" content="Twitter description text">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.description, 'Twitter description text');
    });

    test('extracts image from twitter:image meta tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:image" content="https://example.com/tweet.png">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://example.com/tweet.png');
    });

    test('falls back to og:site_name for siteName', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Title">
          <meta property="og:site_name" content="OG Site Name">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.siteName, 'OG Site Name');
    });

    test('falls back to og:url for url', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Title">
          <meta property="og:url" content="https://example.com/canonical">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.url, 'https://example.com/canonical');
    });

    test('extracts all Twitter Card fields', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Card Title">
          <meta name="twitter:description" content="Card description">
          <meta name="twitter:image" content="https://example.com/card.jpg">
          <meta property="og:site_name" content="CardSite">
          <meta property="og:url" content="https://example.com/card">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.title, 'Card Title');
      expect(parser.description, 'Card description');
      expect(parser.image!.url, 'https://example.com/card.jpg');
      expect(parser.siteName, 'CardSite');
      expect(parser.url, 'https://example.com/card');
    });

    test('returns null for missing twitter:title', () {
      final document = html_parser.parse('''
        <html><head></head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.title, isNull);
    });

    test('returns null for missing twitter:description', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Title Only">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.description, isNull);
    });

    test('returns null for missing twitter:image', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="No Image">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.image, isNull);
    });

    test('returns null for siteName when og:site_name is missing', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Title">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.siteName, isNull);
    });

    test('returns null for url when og:url is missing', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Title">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.url, isNull);
    });

    test('handles empty document', () {
      final document = html_parser.parse('');
      final parser = TwitterParser(document);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
      expect(parser.url, isNull);
    });

    test('handles null document', () {
      final parser = TwitterParser(null);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
      expect(parser.url, isNull);
    });

    test('returns null image when twitter:image content is null literal string', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:image" content="null">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      expect(parser.image, isNull);
    });

    test('parse returns LinkPreviewData with extracted fields', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="twitter:title" content="Parsed Twitter Title">
          <meta name="twitter:description" content="Parsed Twitter description">
          <meta name="twitter:image" content="https://example.com/parsed.png">
          <meta property="og:site_name" content="ParsedSite">
          <meta property="og:url" content="https://example.com/parsed">
        </head><body></body></html>
      ''');
      final parser = TwitterParser(document);
      final data = parser.parse();
      expect(data.title, 'Parsed Twitter Title');
      expect(data.description, 'Parsed Twitter description');
      expect(data.image!.url, 'https://example.com/parsed.png');
      expect(data.siteName, 'ParsedSite');
      expect(data.url, 'https://example.com/parsed');
    });
  });
}