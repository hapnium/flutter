/// {@template device}
/// A Dart package for comprehensive device security and integrity validation.
///
/// This package provides a structured framework for checking a device’s trustworthiness,
/// ensuring that the device is not compromised, misconfigured, or running in an insecure environment.
/// It is especially useful in applications where device authenticity and tamper-detection are critical,
/// such as financial, enterprise, or data-sensitive apps.
///
/// ### Features:
/// - Detect if a device is rooted (Android) or jailbroken (iOS)
/// - Determine whether the app is running on a real physical device or emulator
/// - Identify if Developer Mode is enabled
/// - Check for mock location usage
/// - Builds a device model for the current device
///
/// ### Example usage:
/// ```dart
/// import 'package:device/device.dart';
///
/// class MyCustomDeviceValidation extends DeviceValidationFactory {
///   @override
///   Future<DeviceValidator> isJailBroken() async {
///     final result = await MyPlatformCheck.isRooted();
///     return checkRootedOrJailBroken(result);
///   }
///
///   // Implement other validations similarly...
/// }
/// 
/// final device = Device(
///   name: "iPhone 14",
///   id: "ABCD1234",
///   ipAddress: "192.168.0.101",
///   platform: "iOS",
///   sdk: 17,
///   host: "device-host",
///   operatingSystem: "iOS",
///   operatingSystemVersion: "17.0",
///   localHostName: "iPhone-14.local",
/// );
///
/// print(device.toJson());
/// 
/// ```
///
/// This library makes use of the `Device` model to encapsulate relevant device information,
/// and `DeviceValidator` to represent the outcome of each validation.
/// {@endtemplate}
library;

export 'src/models/device.dart';
export 'src/models/device_validator.dart';

export 'src/device_validation_manager.dart';
export 'src/device_engine.dart';