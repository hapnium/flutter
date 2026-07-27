import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:link_preview/src/v2/parsers/youtube_parser.dart';

void main() {
  group('YoutubeParser', () {
    test('extracts title from YouTube oembed JSON Map', () {
      final document = html_parser.parse('''
        {"title": "Test Video Title", "thumbnail_url": "https://img.youtube.com/vi/abc/0.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.title, 'Test Video Title');
    });

    test('extracts thumbnail_url as image from YouTube oembed JSON Map', () {
      final document = html_parser.parse('''
        {"title": "Video", "thumbnail_url": "https://img.youtube.com/vi/abc/hqdefault.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.image, isNotNull);
      expect(parser.image!.url, 'https://img.youtube.com/vi/abc/hqdefault.jpg');
    });

    test('extracts provider_name as siteName from YouTube oembed JSON Map', () {
      final document = html_parser.parse('''
        {"title": "Video", "thumbnail_url": "https://img.youtube.com/vi/abc/0.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.siteName, 'YouTube');
    });

    test('extracts provider_url as url from YouTube oembed JSON Map', () {
      final document = html_parser.parse('''
        {"title": "Video", "thumbnail_url": "https://img.youtube.com/vi/abc/0.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.url, 'https://www.youtube.com');
    });

    test('extracts fields from YouTube oembed JSON List', () {
      final document = html_parser.parse('''
        [{"title": "List Video", "thumbnail_url": "https://img.youtube.com/vi/xyz/0.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}]
      ''');
      final parser = YoutubeParser(document);
      expect(parser.title, 'List Video');
      expect(parser.image!.url, 'https://img.youtube.com/vi/xyz/0.jpg');
      expect(parser.siteName, 'YouTube');
      expect(parser.url, 'https://www.youtube.com');
    });

    test('extracts all fields from complete YouTube oembed data', () {
      final document = html_parser.parse('''
        {"title": "Complete Video", "thumbnail_url": "https://img.youtube.com/vi/abc/hqdefault.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.title, 'Complete Video');
      expect(parser.image!.url, 'https://img.youtube.com/vi/abc/hqdefault.jpg');
      expect(parser.siteName, 'YouTube');
      expect(parser.url, 'https://www.youtube.com');
    });

    test('returns null for missing title in Map', () {
      final document = html_parser.parse('''
        {"thumbnail_url": "https://img.youtube.com/vi/abc/0.jpg", "provider_name": "YouTube"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.title, isNull);
    });

    test('returns null for missing thumbnail_url in Map', () {
      final document = html_parser.parse('''
        {"title": "Video", "provider_name": "YouTube"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.image, isNull);
    });

    test('returns null for missing provider_name in Map', () {
      final document = html_parser.parse('''
        {"title": "Video", "thumbnail_url": "https://img.youtube.com/vi/abc/0.jpg"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.siteName, isNull);
    });

    test('returns null for missing provider_url in Map', () {
      final document = html_parser.parse('''
        {"title": "Video", "provider_name": "YouTube"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.url, isNull);
    });

    test('returns null image when thumbnail_url is null literal string', () {
      final document = html_parser.parse('''
        {"title": "Video", "thumbnail_url": "null"}
      ''');
      final parser = YoutubeParser(document);
      expect(parser.image, isNull);
    });

    test('handles empty document by throwing FormatException', () {
      final document = html_parser.parse('');
      expect(() => YoutubeParser(document), throwsFormatException);
    });

    test('handles List with empty list by throwing on title access', () {
      final document = html_parser.parse('[]');
      final parser = YoutubeParser(document);
      expect(() => parser.title, throwsStateError);
    });

    test('parse returns LinkPreviewData with extracted fields', () {
      final document = html_parser.parse('''
        {"title": "Parsed Video", "thumbnail_url": "https://img.youtube.com/vi/abc/0.jpg", "provider_name": "YouTube", "provider_url": "https://www.youtube.com"}
      ''');
      final parser = YoutubeParser(document);
      final data = parser.parse();
      expect(data.title, 'Parsed Video');
      expect(data.image!.url, 'https://img.youtube.com/vi/abc/0.jpg');
      expect(data.siteName, 'YouTube');
      expect(data.url, 'https://www.youtube.com');
    });
  });
}