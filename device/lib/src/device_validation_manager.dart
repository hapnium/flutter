import 'package:hapnium/hapnium.dart';
import 'package:meta/meta.dart';

import '../device.dart';

/// {@template device_validation_factory}
/// An abstract service class used for validating the authenticity and integrity of a device.
/// 
/// This factory provides a common interface for performing checks such as:
/// - Whether the device is jailbroken or rooted
/// - Whether the app is running on a real device or emulator
/// - Whether developer mode is enabled
/// - Whether location services are being spoofed
///
/// It uses [DeviceValidator] to return the result of each validation, encapsulating both 
/// validity and error messages.
///
/// Subclasses should implement the `isJailBroken`, `isRealDevice`, `isDeveloperMode`, and 
/// `isMockedLocation` methods to provide platform-specific checks.
///
/// ### Example usage:
/// ```dart
/// class MyValidationService extends DeviceValidationFactory {
///   @override
///   Future<DeviceValidator> isJailBroken() async {
///     final isRooted = await MyRootCheckLib.checkRootStatus();
///     return checkRootedOrJailBroken(isRooted);
///   }
///
///   // Implement other checks similarly...
/// }
/// ```
/// {@endtemplate}
abstract class DeviceValidationManager {
  /// Checks if the device is jailbroken (iOS) or rooted (Android).
  ///
  /// Returns a [Future] that completes with a [DeviceValidator] indicating the result.
  Future<DeviceValidator> isJailBroken();

  /// Performs the actual check for rooted or jailbroken state.
  ///
  /// Returns a [DeviceValidator] based on [isRooted].
  ///
  /// This method:
  /// - Returns valid if on web and [validateWeb] is false
  /// - Returns invalid if [isRooted] is true, with a default or provided [message]
  @protected
  @nonVirtual
  DeviceValidator checkRootedOrJailBroken(bool isRooted, {bool validateWeb = false, String? message}) {
    if (DeviceRuntime.isWeb && validateWeb.isFalse) {
      return DeviceValidator.valid();
    }

    if (isRooted) {
      return DeviceValidator.invalid(message ?? [
        "Your device appears to be jail broken or rooted.",
        "This indicates that restrictions imposed by the manufacturer or operating system have been bypassed.",
        "Such modifications compromise the device's security, exposing it to potential malware and attacks.",
        "For security reasons, this application does not allow its use on modified devices."
      ].join(" "));
    }

    return DeviceValidator.valid();
  }

  /// Checks if the application is running on a real device or an emulator.
  ///
  /// Returns a [Future] that completes with a [DeviceValidator] indicating the result.
  Future<DeviceValidator> isRealDevice();

  /// Performs the actual check for real physical device status.
  ///
  /// Returns a [DeviceValidator] based on [isReal].
  ///
  /// This method:
  /// - Returns valid if on web and [validateWeb] is false
  /// - Returns invalid if [isReal] is false, with a default or provided [message]
  @protected
  @nonVirtual
  DeviceValidator checkRealDevice(bool isReal, {bool validateWeb = false, String? message}) {
    if (DeviceRuntime.isWeb && validateWeb.isFalse) {
      return DeviceValidator.valid();
    }

    if (!isReal) {
      return DeviceValidator.invalid(message ?? [
        "It seems like you're using an emulator or virtual device.",
        "This application requires a real physical device for full functionality.",
        "Please switch to a compatible device."
      ].join(" "));
    }

    return DeviceValidator.valid();
  }

  /// Checks if the device's developer mode is enabled.
  ///
  /// Returns a [Future] that completes with a [DeviceValidator] indicating the result.
  Future<DeviceValidator> isDeveloperMode();

  /// Performs the actual check for developer mode.
  ///
  /// Returns a [DeviceValidator] based on [isEnabled].
  ///
  /// This method:
  /// - Returns valid if on web and [validateWeb] is false
  /// - Returns invalid if [isEnabled] is true, with a default or provided [message]
  @protected
  @nonVirtual
  DeviceValidator checkDeveloperMode(bool isEnabled, {bool validateWeb = false, String? message}) {
    if (DeviceRuntime.isWeb && validateWeb.isFalse) {
      return DeviceValidator.valid();
    }

    if (isEnabled) {
      return DeviceValidator.invalid(message ?? [
        "Developer mode is currently enabled on your device, which may expose it to vulnerabilities.",
        "Please disable developer mode to proceed."
      ].join(" "));
    }

    return DeviceValidator.valid();
  }

  /// Checks if the device is reporting mocked/fake location data.
  ///
  /// Returns a [Future] that completes with a [DeviceValidator] indicating the result.
  Future<DeviceValidator> isMockedLocation();

  /// Performs the actual check for mocked location.
  ///
  /// Returns a [DeviceValidator] based on [isMocked].
  ///
  /// This method:
  /// - Returns valid if on web and [validateWeb] is false
  /// - Returns invalid if [isMocked] is true, with a default or provided [message]
  @protected
  @nonVirtual
  DeviceValidator checkMockLocation(bool isMocked, {bool validateWeb = false, String? message}) {
    if (DeviceRuntime.isWeb && validateWeb.isFalse) {
      return DeviceValidator.valid();
    }

    if (isMocked) {
      return DeviceValidator.invalid(message ?? [
        "Your device seems to be using mock locations.",
        "This feature can compromise the integrity of location-based services.",
        "Please disable mock location to continue."
      ].join(" "));
    }

    return DeviceValidator.valid();
  }
}