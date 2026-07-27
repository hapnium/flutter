import 'package:flutter_test/flutter_test.dart';
import 'package:device/device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceRuntime', () {
    group('before initialization', () {
      test('isInitialized returns false', () {
        expect(DeviceRuntime.isInitialized, isFalse);
      });

      test('throws StateError when accessing platform', () {
        expect(() => DeviceRuntime.platform, throwsStateError);
      });

      test('throws StateError when accessing platformOS', () {
        expect(() => DeviceRuntime.platformOS, throwsStateError);
      });

      test('throws StateError when accessing isWeb', () {
        expect(() => DeviceRuntime.isWeb, throwsStateError);
      });

      test('throws StateError when accessing isAndroid', () {
        expect(() => DeviceRuntime.isAndroid, throwsStateError);
      });

      test('throws StateError when accessing isIOS', () {
        expect(() => DeviceRuntime.isIOS, throwsStateError);
      });

      test('throws StateError when accessing isMacOS', () {
        expect(() => DeviceRuntime.isMacOS, throwsStateError);
      });

      test('throws StateError when accessing isWindows', () {
        expect(() => DeviceRuntime.isWindows, throwsStateError);
      });

      test('throws StateError when accessing isLinux', () {
        expect(() => DeviceRuntime.isLinux, throwsStateError);
      });

      test('throws StateError when accessing isMobile', () {
        expect(() => DeviceRuntime.isMobile, throwsStateError);
      });

      test('throws StateError when accessing isDesktop', () {
        expect(() => DeviceRuntime.isDesktop, throwsStateError);
      });

      test('throws StateError when accessing isWebWasm', () {
        expect(() => DeviceRuntime.isWebWasm, throwsStateError);
      });

      test('throws StateError when accessing operatingSystem', () {
        expect(() => DeviceRuntime.operatingSystem, throwsStateError);
      });

      test('throws StateError when accessing operatingSystemVersion', () {
        expect(() => DeviceRuntime.operatingSystemVersion, throwsStateError);
      });

      test('throws StateError when accessing deviceInfo', () {
        expect(() => DeviceRuntime.deviceInfo, throwsStateError);
      });

      test('throws StateError when accessing ipAddress', () {
        expect(() => DeviceRuntime.ipAddress, throwsStateError);
      });

      test('throws StateError when accessing device', () {
        expect(() => DeviceRuntime.device, throwsStateError);
      });

      test('throws StateError when accessing debug', () {
        expect(() => DeviceRuntime.debug, throwsStateError);
      });
    });

    group('after initialization with unknown platform', () {
      setUp(() async {
        await DeviceRuntime.initialize(RuntimePlatform.unknown);
      });

      test('isInitialized returns true', () {
        expect(DeviceRuntime.isInitialized, isTrue);
      });

      test('platform returns RuntimePlatform.unknown', () {
        expect(DeviceRuntime.platform, RuntimePlatform.unknown);
      });

      test('platformOS returns "Unknown"', () {
        expect(DeviceRuntime.platformOS, 'Unknown');
      });

      test('isWeb returns false', () {
        expect(DeviceRuntime.isWeb, isFalse);
      });

      test('isAndroid returns false', () {
        expect(DeviceRuntime.isAndroid, isFalse);
      });

      test('isIOS returns false', () {
        expect(DeviceRuntime.isIOS, isFalse);
      });

      test('isMacOS returns false', () {
        expect(DeviceRuntime.isMacOS, isFalse);
      });

      test('isWindows returns false', () {
        expect(DeviceRuntime.isWindows, isFalse);
      });

      test('isLinux returns false', () {
        expect(DeviceRuntime.isLinux, isFalse);
      });

      test('isMobile returns false', () {
        expect(DeviceRuntime.isMobile, isFalse);
      });

      test('isDesktop returns false', () {
        expect(DeviceRuntime.isDesktop, isFalse);
      });

      test('isWebWasm returns false', () {
        expect(DeviceRuntime.isWebWasm, isFalse);
      });

      test('debug returns false by default', () {
        expect(DeviceRuntime.debug, isFalse);
      });

      test('operatingSystem returns "Unknown OS"', () {
        expect(DeviceRuntime.operatingSystem, 'Unknown OS');
      });

      test('operatingSystemVersion returns "Unknown Version"', () {
        expect(DeviceRuntime.operatingSystemVersion, 'Unknown Version');
      });

      test('deviceInfo returns "Unknown Device"', () {
        expect(DeviceRuntime.deviceInfo, 'Unknown Device');
      });

      test('device returns empty Device', () {
        final device = DeviceRuntime.device;
        expect(device.name, '');
        expect(device.id, '');
        expect(device.platform, '');
      });
    });

    group('initialization with debug enabled', () {
      setUp(() async {
        await DeviceRuntime.initialize(RuntimePlatform.unknown, debug: true);
      });

      test('debug returns true', () {
        expect(DeviceRuntime.debug, isTrue);
      });
    });

    group('platformOS for all platforms', () {
      test('returns correct strings for each platform', () async {
        await DeviceRuntime.initialize(RuntimePlatform.unknown);
        expect(DeviceRuntime.platformOS, 'Unknown');
      });
    });

    group('platform category getters', () {
      test('isMobile and isDesktop are false for unknown platform', () async {
        await DeviceRuntime.initialize(RuntimePlatform.unknown);
        expect(DeviceRuntime.isMobile, isFalse);
        expect(DeviceRuntime.isDesktop, isFalse);
      });
    });

    group('custom ipAddressSupplier', () {
      test('uses custom supplier for IP address', () async {
        await DeviceRuntime.initialize(
          RuntimePlatform.unknown,
          ipAddressSupplier: () async => '203.0.113.10',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(DeviceRuntime.ipAddress, '203.0.113.10');
      });

      test('falls back to NetworkInterface when supplier throws', () async {
        await DeviceRuntime.initialize(
          RuntimePlatform.unknown,
          debug: true,
          ipAddressSupplier: () async => throw Exception('Network error'),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(DeviceRuntime.ipAddress, isA<String>());
      });
    });

    group('isWebWasm', () {
      test('defaults to false', () async {
        await DeviceRuntime.initialize(RuntimePlatform.unknown);
        expect(DeviceRuntime.isWebWasm, isFalse);
      });
    });
  });
}
