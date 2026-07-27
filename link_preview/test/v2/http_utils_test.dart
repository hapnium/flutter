import 'package:flutter_test/flutter_test.dart';
import 'package:link_preview/src/v2/http_utils.dart';

void main() {
  group('getYouTubeVideoId', () {
    test('extracts video ID from standard youtube.com/watch?v= URL', () {
      final id = getYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from short youtu.be URL', () {
      final id = getYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from embed URL', () {
      final id = getYouTubeVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from mobile URL', () {
      final id = getYouTubeVideoId('https://m.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from URL with additional query parameters', () {
      final id = getYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10&list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from youtu.be URL with query parameters', () {
      final id = getYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ?si=abc123');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from URL with http scheme', () {
      final id = getYouTubeVideoId('http://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from URL without scheme', () {
      final id = getYouTubeVideoId('www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from v/ URL format', () {
      final id = getYouTubeVideoId('https://www.youtube.com/v/dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('returns null for non-YouTube URL', () {
      final id = getYouTubeVideoId('https://www.google.com');
      expect(id, isNull);
    });

    test('returns null for completely invalid URL', () {
      final id = getYouTubeVideoId('not-a-url');
      expect(id, isNull);
    });

    test('returns null for empty string', () {
      final id = getYouTubeVideoId('');
      expect(id, isNull);
    });

    test('returns null for URL with no video ID', () {
      final id = getYouTubeVideoId('https://www.youtube.com/watch?');
      expect(id, isNull);
    });

    test('extracts video ID from URL with proxy prefix', () {
      final id = getYouTubeVideoId('https://proxy.example.com/youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts video ID from URL with extra path segments before youtube.com', () {
      final id = getYouTubeVideoId('https://example.com/youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, 'dQw4w9WgXcQ');
    });
  });
}