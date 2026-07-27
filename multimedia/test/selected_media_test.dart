import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart' show MediaType;

void main() {
  group('SelectedMedia', () {
    group('constructor', () {
      test('creates instance with required path', () {
        final media = SelectedMedia(path: '/test/photo.jpg');

        expect(media.path, equals('/test/photo.jpg'));
        expect(media.size, isEmpty);
        expect(media.duration, equals('00:00'));
        expect(media.data, isNull);
        expect(media.callbackUrl, isNull);
        expect(media.isCamera, isFalse);
        expect(media.media, equals(MediaType.photo));
      });

      test('creates instance with all parameters', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final media = SelectedMedia(
          path: '/test/video.mp4',
          size: '2.5 MB',
          duration: '01:30',
          data: data,
          callbackUrl: 'https://example.com/video.mp4',
          isCamera: true,
          media: MediaType.video,
        );

        expect(media.path, equals('/test/video.mp4'));
        expect(media.size, equals('2.5 MB'));
        expect(media.duration, equals('01:30'));
        expect(media.data, equals(data));
        expect(media.callbackUrl, equals('https://example.com/video.mp4'));
        expect(media.isCamera, isTrue);
        expect(media.media, equals(MediaType.video));
      });
    });

    group('copyWith', () {
      test('copies with no changes preserves all fields', () {
        final original = SelectedMedia(
          path: '/test/photo.jpg',
          size: '1.0 MB',
          duration: '00:30',
          isCamera: true,
          media: MediaType.photo,
        );

        final copy = original.copyWith();

        expect(copy.path, equals(original.path));
        expect(copy.size, equals(original.size));
        expect(copy.duration, equals(original.duration));
        expect(copy.isCamera, equals(original.isCamera));
        expect(copy.media, equals(original.media));
      });

      test('copies with selective overrides', () {
        final original = SelectedMedia(
          path: '/test/photo.jpg',
          size: '1.0 MB',
          media: MediaType.photo,
        );

        final copy = original.copyWith(
          path: '/new/photo.jpg',
          media: MediaType.video,
        );

        expect(copy.path, equals('/new/photo.jpg'));
        expect(copy.size, equals('1.0 MB'));
        expect(copy.media, equals(MediaType.video));
      });

      test('copies with data override', () {
        final original = SelectedMedia(path: '/test.jpg');
        final newData = Uint8List.fromList([4, 5, 6]);

        final copy = original.copyWith(data: newData);

        expect(copy.data, equals(newData));
      });

      test('copies with callbackUrl override', () {
        final original = SelectedMedia(path: '/test.jpg');

        final copy = original.copyWith(callbackUrl: 'https://new.url');

        expect(copy.callbackUrl, equals('https://new.url'));
      });
    });

    group('empty', () {
      test('creates instance with empty path', () {
        final media = SelectedMedia.empty();

        expect(media.path, isEmpty);
        expect(media.size, isEmpty);
        expect(media.duration, equals('00:00'));
        expect(media.isCamera, isFalse);
        expect(media.media, equals(MediaType.photo));
      });
    });

    group('hasContent', () {
      test('returns false for empty path and no data', () {
        final media = SelectedMedia.empty();

        expect(media.hasContent, isFalse);
      });

      test('returns true when path is non-empty', () {
        final media = SelectedMedia(path: '/test/photo.jpg');

        expect(media.hasContent, isTrue);
      });

      test('returns true when data is present even with empty path', () {
        final media = SelectedMedia(
          path: '',
          data: Uint8List.fromList([1, 2, 3]),
        );

        expect(media.hasContent, isTrue);
      });

      test('returns true when both path and data are present', () {
        final media = SelectedMedia(
          path: '/test.jpg',
          data: Uint8List.fromList([1]),
        );

        expect(media.hasContent, isTrue);
      });
    });

    group('toJson', () {
      test('serializes to correct JSON map', () {
        final media = SelectedMedia(
          path: '/test/photo.jpg',
          size: '2.0 MB',
          duration: '01:00',
          isCamera: true,
          media: MediaType.video,
        );

        final json = media.toJson();

        expect(json['path'], equals('/test/photo.jpg'));
        expect(json['size'], equals('2.0 MB'));
        expect(json['duration'], equals('01:00'));
        expect(json['is_camera'], isTrue);
        expect(json['media'], equals('Video'));
        expect(json['data'], isNull);
        expect(json['callback_url'], isNull);
      });

      test('serializes with data and callbackUrl', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final media = SelectedMedia(
          path: '/test.jpg',
          data: data,
          callbackUrl: 'https://example.com',
        );

        final json = media.toJson();

        expect(json['data'], equals(data));
        expect(json['callback_url'], equals('https://example.com'));
      });

      test('serializes photo media type as "photo"', () {
        final media = SelectedMedia(path: '/test.jpg', media: MediaType.photo);

        expect(media.toJson()['media'], equals('Photo'));
      });
    });

    group('fromJson', () {
      test('creates instance from valid JSON map', () {
        final json = {
          'path': '/test/photo.jpg',
          'size': '1.5 MB',
          'duration': '00:45',
          'is_camera': true,
          'media': 'Video',
        };

        final media = SelectedMedia.fromJson(json);

        expect(media.path, equals('/test/photo.jpg'));
        expect(media.size, equals('1.5 MB'));
        expect(media.duration, equals('00:45'));
        expect(media.isCamera, isTrue);
        expect(media.media, equals(MediaType.video));
      });

      test('defaults to empty strings for missing fields', () {
        final media = SelectedMedia.fromJson({});

        expect(media.path, isEmpty);
        expect(media.size, isEmpty);
        expect(media.duration, isEmpty);
        expect(media.isCamera, isFalse);
        expect(media.media, equals(MediaType.photo));
      });

      test('handles null values in JSON', () {
        final json = {
          'path': null,
          'size': null,
          'duration': null,
          'is_camera': null,
          'media': null,
        };

        final media = SelectedMedia.fromJson(json);

        expect(media.path, isEmpty);
        expect(media.size, isEmpty);
        expect(media.duration, isEmpty);
        expect(media.isCamera, isFalse);
        expect(media.media, equals(MediaType.photo));
      });

      test('parses photo media type', () {
        final json = {'media': 'Photo'};

        final media = SelectedMedia.fromJson(json);

        expect(media.media, equals(MediaType.photo));
      });

      test('parses video media type', () {
        final json = {'media': 'Video'};

        final media = SelectedMedia.fromJson(json);

        expect(media.media, equals(MediaType.video));
      });

      test('handles data and callbackUrl fields', () {
        final data = Uint8List.fromList([1, 2]);
        final json = {
          'data': data,
          'callback_url': 'https://example.com',
        };

        final media = SelectedMedia.fromJson(json);

        expect(media.data, equals(data));
        expect(media.callbackUrl, equals('https://example.com'));
      });
    });

    group('round-trip', () {
      test('fromJson(toJson()) preserves data', () {
        final original = SelectedMedia(
          path: '/test/photo.jpg',
          size: '2.0 MB',
          duration: '01:30',
          isCamera: true,
          media: MediaType.video,
        );

        final restored = SelectedMedia.fromJson(original.toJson());

        expect(restored.path, equals(original.path));
        expect(restored.size, equals(original.size));
        expect(restored.duration, equals(original.duration));
        expect(restored.isCamera, equals(original.isCamera));
        expect(restored.media, equals(original.media));
      });

      test('fromJson(toJson()) on empty instance', () {
        final original = SelectedMedia.empty();

        final restored = SelectedMedia.fromJson(original.toJson());

        expect(restored.path, isEmpty);
        expect(restored.isCamera, isFalse);
      });
    });
  });
}