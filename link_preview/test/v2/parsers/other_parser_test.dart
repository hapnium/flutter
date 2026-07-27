import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:link_preview/src/v2/parsers/other_parser.dart';

void main() {
  group('OtherParser', () {
    test('extracts title from <meta name="title"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="Other Title">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.title, 'Other Title');
    });

    test('extracts description from <meta name="description"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="description" content="Other description text">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.description, 'Other description text');
    });

    test('extracts image from <meta name="image"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="image" content="https://example.com/other.png">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://example.com/other.png');
    });

    test('extracts siteName from <meta name="site_name"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="site_name" content="Other Site">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.siteName, 'Other Site');
    });

    test('extracts url from <meta name="url"> tag', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="url" content="https://example.com/other-page">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.url, 'https://example.com/other-page');
    });

    test('extracts all fields from complete Other meta tags', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="Full Other Title">
          <meta name="description" content="Full other description">
          <meta name="image" content="https://example.com/other-full.png">
          <meta name="site_name" content="FullOtherSite">
          <meta name="url" content="https://example.com/other-full">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.title, 'Full Other Title');
      expect(parser.description, 'Full other description');
      expect(parser.image!.url, 'https://example.com/other-full.png');
      expect(parser.siteName, 'FullOtherSite');
      expect(parser.url, 'https://example.com/other-full');
    });

    test('returns null for missing title', () {
      final document = html_parser.parse('''
        <html><head></head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.title, isNull);
    });

    test('returns null for missing description', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="Title Only">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.description, isNull);
    });

    test('returns null for missing image', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="No Image">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.image, isNull);
    });

    test('returns null for missing site_name', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="No Site">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.siteName, isNull);
    });

    test('returns null for missing url', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="No URL">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.url, isNull);
    });

    test('handles empty document', () {
      final document = html_parser.parse('');
      final parser = OtherParser(document);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
      expect(parser.url, isNull);
    });

    test('handles null document', () {
      final parser = OtherParser(null);
      expect(parser.title, isNull);
      expect(parser.description, isNull);
      expect(parser.image, isNull);
      expect(parser.siteName, isNull);
      expect(parser.url, isNull);
    });

    test('returns null image when image content is null literal string', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="image" content="null">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      expect(parser.image, isNull);
    });

    test('parse returns LinkPreviewData with extracted fields', () {
      final document = html_parser.parse('''
        <html><head>
          <meta name="title" content="Parsed Other Title">
          <meta name="description" content="Parsed other description">
          <meta name="image" content="https://example.com/parsed-other.png">
          <meta name="site_name" content="ParsedOtherSite">
          <meta name="url" content="https://example.com/parsed-other">
        </head><body></body></html>
      ''');
      final parser = OtherParser(document);
      final data = parser.parse();
      expect(data.title, 'Parsed Other Title');
      expect(data.description, 'Parsed other description');
      expect(data.image!.url, 'https://example.com/parsed-other.png');
      expect(data.siteName, 'ParsedOtherSite');
      expect(data.url, 'https://example.com/parsed-other');
    });
  });
}