import 'package:flutter_test/flutter_test.dart';
import 'package:device/src/models/device.dart';

void main() {
  group('Device', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final device = Device(
          name: 'iPhone 14',
          id: 'ABCD1234',
          ipAddress: '192.168.0.101',
          platform: 'iOS',
          sdk: 17,
          host: 'device-host',
          operatingSystem: 'iOS',
          operatingSystemVersion: '17.0',
          localHostName: 'iPhone-14.local',
        );

        expect(device.name, 'iPhone 14');
        expect(device.id, 'ABCD1234');
        expect(device.ipAddress, '192.168.0.101');
        expect(device.platform, 'iOS');
        expect(device.sdk, 17);
        expect(device.host, 'device-host');
        expect(device.operatingSystem, 'iOS');
        expect(device.operatingSystemVersion, '17.0');
        expect(device.localHostName, 'iPhone-14.local');
      });

      test('defaults sdk to 0 when not provided', () {
        final device = Device(
          name: 'Test',
          id: 'id',
          ipAddress: 'ip',
          platform: 'platform',
          host: 'host',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'host',
        );

        expect(device.sdk, 0);
      });
    });

    group('Device.empty', () {
      test('creates instance with empty strings and sdk 0', () {
        final device = Device.empty();

        expect(device.name, '');
        expect(device.id, '');
        expect(device.ipAddress, '');
        expect(device.platform, '');
        expect(device.sdk, 0);
        expect(device.host, '');
        expect(device.operatingSystem, '');
        expect(device.operatingSystemVersion, '');
        expect(device.localHostName, '');
      });
    });

    group('copyWith', () {
      test('copies with no changes returns identical values', () {
        final original = Device(
          name: 'iPhone',
          id: '123',
          ipAddress: '10.0.0.1',
          platform: 'iOS',
          sdk: 17,
          host: 'host',
          operatingSystem: 'iOS',
          operatingSystemVersion: '17.0',
          localHostName: 'local',
        );

        final copy = original.copyWith();

        expect(copy.name, original.name);
        expect(copy.id, original.id);
        expect(copy.ipAddress, original.ipAddress);
        expect(copy.platform, original.platform);
        expect(copy.sdk, original.sdk);
        expect(copy.host, original.host);
        expect(copy.operatingSystem, original.operatingSystem);
        expect(copy.operatingSystemVersion, original.operatingSystemVersion);
        expect(copy.localHostName, original.localHostName);
      });

      test('copies with overridden name', () {
        final device = Device(
          name: 'Old',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(name: 'New');
        expect(copy.name, 'New');
        expect(copy.id, '1');
      });

      test('copies with overridden sdk', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          sdk: 10,
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(sdk: 34);
        expect(copy.sdk, 34);
      });

      test('copies with overridden id', () {
        final device = Device(
          name: 'Test',
          id: 'old-id',
          ipAddress: 'ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
      });

      test('copies with overridden ipAddress', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'old-ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(ipAddress: 'new-ip');
        expect(copy.ipAddress, 'new-ip');
      });

      test('copies with overridden platform', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'ip',
          platform: 'old',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(platform: 'new');
        expect(copy.platform, 'new');
      });

      test('copies with overridden host', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          host: 'old',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(host: 'new');
        expect(copy.host, 'new');
      });

      test('copies with overridden operatingSystem', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'old',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        final copy = device.copyWith(operatingSystem: 'new');
        expect(copy.operatingSystem, 'new');
      });

      test('copies with overridden operatingSystemVersion', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: 'old',
          localHostName: 'local',
        );

        final copy = device.copyWith(operatingSystemVersion: 'new');
        expect(copy.operatingSystemVersion, 'new');
      });

      test('copies with overridden localHostName', () {
        final device = Device(
          name: 'Test',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'old',
        );

        final copy = device.copyWith(localHostName: 'new');
        expect(copy.localHostName, 'new');
      });

      test('copies with all fields overridden', () {
        final original = Device(
          name: 'Old',
          id: '1',
          ipAddress: 'old-ip',
          platform: 'old',
          sdk: 10,
          host: 'old-host',
          operatingSystem: 'old-os',
          operatingSystemVersion: '1.0',
          localHostName: 'old-local',
        );

        final copy = original.copyWith(
          name: 'New',
          id: '2',
          ipAddress: 'new-ip',
          platform: 'new',
          sdk: 34,
          host: 'new-host',
          operatingSystem: 'new-os',
          operatingSystemVersion: '2.0',
          localHostName: 'new-local',
        );

        expect(copy.name, 'New');
        expect(copy.id, '2');
        expect(copy.ipAddress, 'new-ip');
        expect(copy.platform, 'new');
        expect(copy.sdk, 34);
        expect(copy.host, 'new-host');
        expect(copy.operatingSystem, 'new-os');
        expect(copy.operatingSystemVersion, '2.0');
        expect(copy.localHostName, 'new-local');
      });

      test('original is unchanged after copyWith', () {
        final device = Device(
          name: 'Original',
          id: '1',
          ipAddress: 'ip',
          platform: 'p',
          host: 'h',
          operatingSystem: 'os',
          operatingSystemVersion: '1.0',
          localHostName: 'local',
        );

        device.copyWith(name: 'Changed');

        expect(device.name, 'Original');
      });
    });

    group('toJson', () {
      test('returns correct JSON map', () {
        final device = Device(
          name: 'Pixel 7',
          id: 'device-id',
          ipAddress: '10.0.0.5',
          platform: 'Android',
          sdk: 34,
          host: 'host',
          operatingSystem: 'Android',
          operatingSystemVersion: '14',
          localHostName: 'pixel-7',
        );

        final json = device.toJson();

        expect(json['name'], 'Pixel 7');
        expect(json['id'], 'device-id');
        expect(json['ip_address'], '10.0.0.5');
        expect(json['platform'], 'Android');
        expect(json['sdk'], 34);
        expect(json['host'], 'host');
        expect(json['operating_system'], 'Android');
        expect(json['operating_system_version'], '14');
        expect(json['local_host_name'], 'pixel-7');
      });

      test('returns map with correct key count', () {
        final device = Device.empty();
        expect(device.toJson().length, 9);
      });
    });

    group('fromJson', () {
      test('creates device from complete JSON', () {
        final json = {
          'name': 'Galaxy S23',
          'id': 'galaxy-id',
          'ip_address': '192.168.1.1',
          'platform': 'Android',
          'sdk': 33,
          'host': 'samsung',
          'operating_system': 'Android',
          'operating_system_version': '13',
          'local_host_name': 'galaxy',
        };

        final device = Device.fromJson(json);

        expect(device.name, 'Galaxy S23');
        expect(device.id, 'galaxy-id');
        expect(device.ipAddress, '192.168.1.1');
        expect(device.platform, 'Android');
        expect(device.sdk, 33);
        expect(device.host, 'samsung');
        expect(device.operatingSystem, 'Android');
        expect(device.operatingSystemVersion, '13');
        expect(device.localHostName, 'galaxy');
      });

      test('uses defaults for missing fields', () {
        final device = Device.fromJson({});

        expect(device.name, '');
        expect(device.id, '');
        expect(device.ipAddress, '');
        expect(device.platform, '');
        expect(device.sdk, 0);
        expect(device.host, '');
        expect(device.operatingSystem, '');
        expect(device.operatingSystemVersion, '');
        expect(device.localHostName, '');
      });

      test('uses defaults for partial JSON', () {
        final json = {
          'name': 'Partial',
          'platform': 'iOS',
        };

        final device = Device.fromJson(json);

        expect(device.name, 'Partial');
        expect(device.platform, 'iOS');
        expect(device.id, '');
        expect(device.sdk, 0);
      });
    });

    group('round-trip serialization', () {
      test('toJson then fromJson returns equivalent device', () {
        final original = Device(
          name: 'iPhone 15',
          id: 'abc-123',
          ipAddress: '172.16.0.1',
          platform: 'iOS',
          sdk: 17,
          host: 'apple',
          operatingSystem: 'iOS',
          operatingSystemVersion: '17.2',
          localHostName: 'iPhone-15',
        );

        final restored = Device.fromJson(original.toJson());

        expect(restored.name, original.name);
        expect(restored.id, original.id);
        expect(restored.ipAddress, original.ipAddress);
        expect(restored.platform, original.platform);
        expect(restored.sdk, original.sdk);
        expect(restored.host, original.host);
        expect(restored.operatingSystem, original.operatingSystem);
        expect(restored.operatingSystemVersion, original.operatingSystemVersion);
        expect(restored.localHostName, original.localHostName);
      });

      test('empty device round-trips correctly', () {
        final original = Device.empty();
        final restored = Device.fromJson(original.toJson());

        expect(restored.name, '');
        expect(restored.id, '');
        expect(restored.ipAddress, '');
        expect(restored.sdk, 0);
      });
    });
  });
}