import 'package:flutter_test/flutter_test.dart';
import 'package:device/device.dart';

void main() {
  group('RuntimePlatform', () {
    group('fromOperatingSystem', () {
      test('returns android for "android"', () {
        expect(RuntimePlatform.fromOperatingSystem('android'), RuntimePlatform.android);
      });

      test('returns ios for "ios"', () {
        expect(RuntimePlatform.fromOperatingSystem('ios'), RuntimePlatform.ios);
      });

      test('returns macos for "macos"', () {
        expect(RuntimePlatform.fromOperatingSystem('macos'), RuntimePlatform.macos);
      });

      test('returns windows for "windows"', () {
        expect(RuntimePlatform.fromOperatingSystem('windows'), RuntimePlatform.windows);
      });

      test('returns linux for "linux"', () {
        expect(RuntimePlatform.fromOperatingSystem('linux'), RuntimePlatform.linux);
      });

      test('returns unknown for empty string', () {
        expect(RuntimePlatform.fromOperatingSystem(''), RuntimePlatform.unknown);
      });

      test('returns unknown for unrecognized value', () {
        expect(RuntimePlatform.fromOperatingSystem('freebsd'), RuntimePlatform.unknown);
      });

      test('is case-insensitive', () {
        expect(RuntimePlatform.fromOperatingSystem('Android'), RuntimePlatform.android);
        expect(RuntimePlatform.fromOperatingSystem('IOS'), RuntimePlatform.ios);
        expect(RuntimePlatform.fromOperatingSystem('MacOS'), RuntimePlatform.macos);
        expect(RuntimePlatform.fromOperatingSystem('WINDOWS'), RuntimePlatform.windows);
        expect(RuntimePlatform.fromOperatingSystem('Linux'), RuntimePlatform.linux);
      });

      test('trims whitespace', () {
        expect(RuntimePlatform.fromOperatingSystem('  android  '), RuntimePlatform.android);
        expect(RuntimePlatform.fromOperatingSystem(' ios '), RuntimePlatform.ios);
      });

      test('handles mixed case with whitespace', () {
        expect(RuntimePlatform.fromOperatingSystem('  MacOs  '), RuntimePlatform.macos);
      });
    });

    group('fromCurrentPlatform', () {
      test('returns a valid RuntimePlatform value', () {
        final platform = RuntimePlatform.fromCurrentPlatform();
        expect(platform, isA<RuntimePlatform>());
        expect(platform, isNot(RuntimePlatform.unknown));
      });
    });

    group('values', () {
      test('has all expected values', () {
        expect(RuntimePlatform.values.length, 7);
        expect(RuntimePlatform.values, contains(RuntimePlatform.web));
        expect(RuntimePlatform.values, contains(RuntimePlatform.android));
        expect(RuntimePlatform.values, contains(RuntimePlatform.ios));
        expect(RuntimePlatform.values, contains(RuntimePlatform.macos));
        expect(RuntimePlatform.values, contains(RuntimePlatform.windows));
        expect(RuntimePlatform.values, contains(RuntimePlatform.linux));
        expect(RuntimePlatform.values, contains(RuntimePlatform.unknown));
      });
    });
  });
}