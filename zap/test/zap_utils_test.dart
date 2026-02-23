import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zap/zap.dart';

void main() {
  late ZapUtils zapUtils;

  setUp(() {
    zapUtils = ZapUtils.instance;
  });

  group('ZapUtils Tests', () {
    test('fetchIpAddress returns a string', () async {
      final ipAddress = await zapUtils.fetchIpAddress(false);
      expect(ipAddress, isA<String>());
    });

    test('fetchImageData reports error for invalid host', () async {
      Uint8List? imageData;
      String? errorMessage;

      await zapUtils.fetchImageData(
        url: 'https://invalid-domain-zap-test.local/image.png',
        onSuccess: (data) => imageData = data,
        onError: (error) => errorMessage = error,
        log: false,
      );

      expect(imageData, isNull);
      expect(errorMessage, isNotNull);
    });

    test('fetchImageDataAsync returns null for invalid host', () async {
      final imageData = await zapUtils.fetchImageDataAsync(
        'https://invalid-domain-zap-test.local/image.png',
        false,
      );

      expect(imageData, isNull);
    });

    test('getLocationInformation always returns a model', () async {
      final location = await zapUtils.getLocationInformation(999.0, 999.0, false);

      expect(location, isA<LocationInformation>());
      expect(location.displayName, isA<String>());
    });

    test('concurrent utility calls complete without crashing', () async {
      final results = await Future.wait<dynamic>([
        zapUtils.fetchIpAddress(false),
        zapUtils.fetchImageDataAsync('https://invalid-domain-zap-test.local/image.png', false),
        zapUtils.getLocationInformation(999.0, 999.0, false),
      ]);

      expect(results[0], isA<String>());
      expect(results[1], anyOf(isNull, isA<Uint8List>()));
      expect(results[2], isA<LocationInformation>());
    });
  });
}
