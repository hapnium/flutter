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

import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_io/io.dart';
import 'package:tracing/tracing.dart';

import 'src/models/device.dart';

/// Function signature for custom IP address fetching.
///
/// By default, [DeviceRuntime] attempts to resolve an IP address on non-web
/// platforms using [NetworkInterface.list]. On Web, it returns an empty string.
///
/// If you want to supply your own IP logic (for example, calling an API that
/// returns the public IP), pass a function of this type into
/// [DeviceRuntime.initialize] via `ipAddressSupplier`.
///
/// Example:
/// ```dart
/// Future<String> fetchPublicIp() async {
///   // e.g. call your backend or an external "what is my ip" endpoint
///   return "203.0.113.10";
/// }
///
/// await DeviceRuntime.initialize(
///   platform: RuntimePlatform.web,
///   ipAddressSupplier: fetchPublicIp,
/// );
/// ```
typedef IpAddressFetcher = Future<String> Function();

/// Describes the runtime platform the application is executing on.
///
/// This enum is intended to be chosen by the caller at startup and supplied to
/// [DeviceRuntime.initialize]. That requirement is deliberate:
/// - It prevents accidental platform probing that can break on Web.
/// - It avoids calling unsupported plugin APIs (common source of Web crashes).
///
/// Common mapping:
/// - Flutter Web: [RuntimePlatform.web]
/// - Android:     [RuntimePlatform.android]
/// - iOS:         [RuntimePlatform.ios]
/// - macOS:       [RuntimePlatform.macos]
/// - Windows:     [RuntimePlatform.windows]
/// - Linux:       [RuntimePlatform.linux]
enum RuntimePlatform {
  web,
  android,
  ios,
  macos,
  windows,
  linux,
  unknown;

  /// ✅ Create from an OS string (e.g. Platform.operatingSystem)
  ///
  /// Examples:
  /// - "android" => RuntimePlatform.android
  /// - "ios" => RuntimePlatform.ios
  /// - "macos" => RuntimePlatform.macos
  /// - "windows" => RuntimePlatform.windows
  /// - "linux" => RuntimePlatform.linux
  /// - anything else => RuntimePlatform.unknown
  factory RuntimePlatform.fromOperatingSystem(String os) {
    final value = os.trim().toLowerCase();

    switch (value) {
      case "android":
        return RuntimePlatform.android;
      case "ios":
        return RuntimePlatform.ios;
      case "macos":
        return RuntimePlatform.macos;
      case "windows":
        return RuntimePlatform.windows;
      case "linux":
        return RuntimePlatform.linux;
      default:
        return RuntimePlatform.unknown;
    }
  }

  /// ✅ Requested API: RuntimePlatform.fromPlatform(Platform platform)
  ///
  /// ⚠️ NOTE:
  /// `Platform` does not behave like a normal instance in Dart.
  /// It’s essentially a static interface (Platform.isAndroid, etc.).
  ///
  /// This factory will still work, but the `platform` parameter isn’t truly used.
  static RuntimePlatform fromCurrentPlatform() {
    if (Platform.isAndroid) return RuntimePlatform.android;
    if (Platform.isIOS) return RuntimePlatform.ios;
    if (Platform.isMacOS) return RuntimePlatform.macos;
    if (Platform.isWindows) return RuntimePlatform.windows;
    if (Platform.isLinux) return RuntimePlatform.linux;

    return RuntimePlatform.unknown;
  }
}

/// {@template device_runtime}
/// A static, process-wide device/runtime information provider for Flutter apps.
///
/// ## Why this exists
/// Flutter apps often need a single place to ask questions like:
/// - “Am I running on Web or Android?”
/// - “What OS and version is this device?”
/// - “What device/browser info can I safely read?”
/// - “What is the current IP address?”
///
/// On Flutter Web, some platform APIs and plugins do not exist (or behave
/// differently). If code tries to call a mobile/desktop-only plugin method while
/// running on Web, you'll get errors like `MissingPluginException` or null
/// type errors. [DeviceRuntime] avoids that by:
///
/// 1) requiring explicit [RuntimePlatform] on initialization  
/// 2) selecting the correct `device_info_plus` branch based on that platform  
/// 3) gating all getters behind [_ensureInitialized]
///
/// ## Initialization contract
/// You **must** call [initialize] before using any getter in this class.
/// If you access a getter first, a [StateError] is thrown with a clear message.
///
/// This design forces correct startup ordering and makes failures obvious.
///
/// ---
///
/// ## Typical usage (recommended)
///
/// ### 1) In `main()`
/// ```dart
/// import 'package:flutter/foundation.dart';
///
/// Future<void> main() async {
///   // Choose platform. On Web, you already know you're Web.
///   // On non-web, you can decide however you prefer.
///   final platform = kIsWeb ? RuntimePlatform.web : RuntimePlatform.android;
///
///   await DeviceRuntime.initialize(
///     platform: platform,
///     debug: true,
///     // set true if you're explicitly running Flutter Web Wasm
///     isWasm: false,
///   );
///
///   runApp(const MyApp());
/// }
/// ```
///
/// ### 2) Anywhere later (after initialization)
/// ```dart
/// if (DeviceRuntime.isWeb) {
///   print("Browser: ${DeviceRuntime.device.name}");
/// }
///
/// print(DeviceRuntime.operatingSystem);
/// print(DeviceRuntime.operatingSystemVersion);
/// print(DeviceRuntime.ipAddress);
/// ```
///
/// ---
///
/// ## What each output means (important context)
///
/// - [platform] (getter): a simplified string view of the chosen
///   [RuntimePlatform] (e.g., "Web", "Android").
///
/// - [operatingSystem]/[operatingSystemVersion]:
///   On Web, these are derived from browser information (like `userAgent`,
///   `appVersion`). It reflects the *host environment* the browser reports.
///   On Android/iOS/desktop, it reflects the device OS information.
///
/// - [deviceInfo]:
///   A human-readable summary. On Web, typically includes the user agent.
///   On native platforms, typically mirrors the OS label.
///
/// - [device]:
///   Your structured [Device] model populated from `device_info_plus` and
///   platform APIs. This is what you store/log/ship as telemetry.
///
/// - [ipAddress]:
///   Web returns "" unless you supply [IpAddressFetcher]. Non-web attempts to
///   resolve using [NetworkInterface.list].
/// {@endtemplate}
abstract final class DeviceRuntime {
  // ---------------------------------------------------------------------------
  // Internal State
  // ---------------------------------------------------------------------------

  /// Whether [initialize] has completed successfully.
  ///
  /// All public getters/methods enforce initialization via [_ensureInitialized].
  /// This prevents partial/invalid reads (e.g., empty OS strings or default
  /// [Device.empty]) before initialization.
  static bool _initialized = false;

  /// The runtime platform chosen by the user at initialization time.
  ///
  /// This is the main switch that determines which `device_info_plus` API
  /// is called and which platform checks should be true.
  static RuntimePlatform _runtimePlatform = RuntimePlatform.unknown;

  /// Indicates whether the app is running Flutter Web in Wasm mode.
  ///
  /// This is only meaningful when the platform is [RuntimePlatform.web].
  static bool _isWasm = false;

  /// Enables verbose logging during initialization and error recovery.
  static bool _debug = false;

  /// Optional IP address supplier override.
  ///
  /// If provided, this is used in preference to the default IP resolution logic.
  static IpAddressFetcher? _customIpAddressFetcher;

  /// Cached OS label populated during initialization.
  static String _operatingSystem = "";

  /// Cached OS version string populated during initialization.
  static String _operatingSystemVersion = "";

  /// Cached device summary string populated during initialization.
  static String _deviceInfo = "";

  /// Cached device IP address populated during initialization.
  static String _ipAddress = "";

  /// Cached structured device representation populated during initialization.
  static Device _device = Device.empty();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Initializes runtime/device information.
  ///
  /// This must be called once before reading any getter.
  ///
  /// ### Parameters
  /// - [platform] (**required**):
  ///   Explicit runtime platform. This determines which plugin APIs are used.
  ///
  /// - [debug]:
  ///   If `true`, logs initialization output and certain recovery failures
  ///   using `tracing.console.log`.
  ///
  /// - [isWasm]:
  ///   If `true`, the [isWebWasm] getter becomes true. Useful if your Web build
  ///   uses Wasm and you need feature toggles or analytics labeling.
  ///
  /// - [ipAddressSupplier]:
  ///   Custom function to fetch the IP address. Recommended for Web if you need
  ///   a public IP address (since Web cannot read LAN interfaces directly).
  ///
  /// ### Example: Web with a custom IP supplier
  /// ```dart
  /// await DeviceRuntime.initialize(
  ///   platform: RuntimePlatform.web,
  ///   debug: true,
  ///   ipAddressSupplier: () async {
  ///     // Call your backend or any IP service.
  ///     return "203.0.113.10";
  ///   },
  /// );
  /// ```
  ///
  /// ### Example: Android native
  /// ```dart
  /// await DeviceRuntime.initialize(
  ///   platform: RuntimePlatform.android,
  ///   debug: true,
  /// );
  /// ```
  static Future<void> initialize(RuntimePlatform platform, {
    bool debug = false,
    bool isWasm = false,
    IpAddressFetcher? ipAddressSupplier,
  }) async {
    _runtimePlatform = platform;
    _debug = debug;
    _isWasm = isWasm;
    _customIpAddressFetcher = ipAddressSupplier;

    // Compute network info first, then device info.
    // This ordering ensures `_device` can embed `_ipAddress` immediately.
    _ipAddress = await _fetchDeviceIpAddress();
    await _prepareDevice();

    _initialized = true;

    // Optional startup diagnostics
    if (_debug) {
      console.log("Device Runtime Initialized", tag: "DeviceRuntime");
      console.log("Platform: ${DeviceRuntime.platformOS}", tag: "DeviceRuntime");
      console.log("Operating System: $_operatingSystem", tag: "DeviceRuntime");
      console.log("Operating System Version: $_operatingSystemVersion", tag: "DeviceRuntime");
      console.log("Device Info: $_deviceInfo", tag: "DeviceRuntime");
      console.log("IP Address: $_ipAddress", tag: "DeviceRuntime");
      console.log("Device: ${_device.toJson()}", tag: "DeviceRuntime");
    }
  }

  /// Whether [initialize] has successfully completed.
  ///
  /// You can use this to avoid exceptions in edge cases (e.g. tests),
  /// but in normal application flow you should always initialize once in `main`.
  static bool get isInitialized => _initialized;

  /// `true` if you marked initialization as Web Wasm mode.
  ///
  /// This is a feature flag supplied by the application, not auto-detected.
  /// Access requires [initialize] to have been called.
  static bool get isWebWasm {
    _ensureInitialized();
    return _isWasm;
  }

  /// `true` if the runtime platform is Web.
  ///
  /// Access requires [initialize] to have been called.
  static bool get isWeb {
    _ensureInitialized();
    return _runtimePlatform == RuntimePlatform.web;
  }

  /// `true` if the runtime platform is Android.
  static bool get isAndroid {
    _ensureInitialized();
    return _runtimePlatform == RuntimePlatform.android;
  }

  /// `true` if the runtime platform is iOS.
  static bool get isIOS {
    _ensureInitialized();
    return _runtimePlatform == RuntimePlatform.ios;
  }

  /// `true` if the runtime platform is macOS.
  static bool get isMacOS {
    _ensureInitialized();
    return _runtimePlatform == RuntimePlatform.macos;
  }

  /// `true` if the runtime platform is Linux.
  static bool get isLinux {
    _ensureInitialized();
    return _runtimePlatform == RuntimePlatform.linux;
  }

  /// `true` if the runtime platform is Windows.
  static bool get isWindows {
    _ensureInitialized();
    return _runtimePlatform == RuntimePlatform.windows;
  }

  /// `true` if the runtime platform is Android or iOS.
  static bool get isMobile {
    _ensureInitialized();
    return isAndroid || isIOS;
  }

  /// `true` if the runtime platform is macOS, Windows, or Linux.
  static bool get isDesktop {
    _ensureInitialized();
    return isMacOS || isWindows || isLinux;
  }

  /// A human-readable operating system label.
  ///
  /// Examples:
  /// - Web: `"Web Netscape"` (browser-reported appName)
  /// - Android: `"Android 14"`
  /// - iOS: `"iOS 17.2"`
  static String get operatingSystem {
    _ensureInitialized();
    return _operatingSystem;
  }

  /// A human-readable operating system version string.
  ///
  /// Examples:
  /// - Web: `"5.0 (Macintosh; Intel Mac OS X ...)"` (from appVersion/user agent)
  /// - Android: `"34"` (SDK int)
  /// - macOS: `"23.1.0"` (osRelease)
  static String get operatingSystemVersion {
    _ensureInitialized();
    return _operatingSystemVersion;
  }

  /// Raw device info summary string.
  ///
  /// On Web, it includes the user agent when available.
  /// On native platforms, it typically mirrors the OS string.
  static String get deviceInfo {
    _ensureInitialized();
    return _deviceInfo;
  }

  /// Resolved IP address.
  ///
  /// - Web: default is `""` unless [IpAddressFetcher] is provided.
  /// - Non-web: tries `NetworkInterface.list`.
  static String get ipAddress {
    _ensureInitialized();
    return _ipAddress;
  }

  /// Structured device representation.
  ///
  /// Populate this into logs/telemetry, or store it in local persistence.
  static Device get device {
    _ensureInitialized();
    return _device;
  }

  /// Whether debug logging was enabled at initialization time.
  static bool get debug {
    _ensureInitialized();
    return _debug;
  }

  /// The runtime platform
  static RuntimePlatform get platform => _runtimePlatform;

  /// A simplified platform label string derived from [_runtimePlatform].
  ///
  /// Examples: `"Web"`, `"Android"`, `"macOS"`, `"Unknown"`.
  static String get platformOS {
    _ensureInitialized();
    return switch (_runtimePlatform) {
      RuntimePlatform.web => "Web",
      RuntimePlatform.android => "Android",
      RuntimePlatform.ios => "iOS",
      RuntimePlatform.macos => "macOS",
      RuntimePlatform.windows => "Windows",
      RuntimePlatform.linux => "Linux",
      RuntimePlatform.unknown => "Unknown",
    };
  }

  // ---------------------------------------------------------------------------
  // Initialization Guards
  // ---------------------------------------------------------------------------

  /// Throws if [initialize] has not been called.
  ///
  /// This ensures all getters are safe, consistent, and never return placeholder
  /// values from initial defaults.
  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        "DeviceRuntime has not been initialized. "
        "Call DeviceRuntime.initialize(platform: ...) before using it.",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Implementation
  // ---------------------------------------------------------------------------

  /// Attempts to resolve an IP address for the current device.
  ///
  /// Resolution order:
  /// 1) If [_customIpAddressFetcher] is provided, try that first.
  /// 2) If running on Web, return `""` (no direct IP resolution in Dart Web).
  /// 3) Otherwise, use [NetworkInterface.list] and return the first address found.
  ///
  /// If anything fails, returns `""`.
  static Future<String> _fetchDeviceIpAddress() async {
    if (_customIpAddressFetcher != null) {
      try {
        return await _customIpAddressFetcher!();
      } catch (e) {
        if (_debug) {
          console.log("Custom IP address fetcher failed: $e", tag: "DeviceRuntime");
        }
      }
    }

    if (isWeb) return "";

    try {
      final networks = await NetworkInterface.list();
      if (networks.isNotEmpty) {
        final addresses = networks.first.addresses;
        if (addresses.isNotEmpty) return addresses.first.address;
      }
    } catch (e) {
      if (_debug) {
        console.log("Failed to fetch IP via NetworkInterface: $e", tag: "DeviceRuntime");
      }
    }

    return "";
  }

  /// Populates device and OS information based on the declared runtime platform.
  ///
  /// This method calls the appropriate `device_info_plus` getter:
  /// - Web     -> `webBrowserInfo`
  /// - Android -> `androidInfo`
  /// - iOS     -> `iosInfo`
  /// - macOS   -> `macOsInfo`
  /// - Windows -> `windowsInfo`
  /// - Linux   -> `linuxInfo`
  ///
  /// If [RuntimePlatform.unknown] is provided, it falls back to `"Unknown"`.
  static Future<void> _prepareDevice() async {
    final plugin = DeviceInfoPlugin();

    switch (_runtimePlatform) {
      case RuntimePlatform.web:
        final info = await plugin.webBrowserInfo;

        _operatingSystem = "Web ${info.appName}";
        _operatingSystemVersion = info.appVersion ?? info.appCodeName ?? "";
        _deviceInfo = "Web: ${info.userAgent ?? "Unknown"}";

        _device = _device.copyWith(
          id: info.userAgent,
          name: info.browserName.name,
          host: info.appCodeName,
          platform: "Web | ${info.platform}",
          operatingSystem: "${info.appName} | ${info.userAgent}",
          operatingSystemVersion: info.appVersion,
          localHostName: info.appName,
          ipAddress: _ipAddress,
        );
        break;

      case RuntimePlatform.android:
        final info = await plugin.androidInfo;

        _operatingSystem = 'Android ${info.version.release}';
        _operatingSystemVersion = info.version.sdkInt.toString();
        _deviceInfo = _operatingSystem;

        _device = _device.copyWith(
          sdk: info.version.sdkInt,
          id: info.id,
          name: info.model,
          host: info.host,
          platform: "Android",
          operatingSystemVersion: Platform.operatingSystemVersion,
          operatingSystem: Platform.operatingSystem,
          ipAddress: _ipAddress,
          localHostName: Platform.localHostname,
        );
        break;

      case RuntimePlatform.ios:
        final info = await plugin.iosInfo;

        _operatingSystem = 'iOS ${info.systemVersion}';
        _operatingSystemVersion = info.systemVersion;
        _deviceInfo = _operatingSystem;

        _device = _device.copyWith(
          id: info.identifierForVendor,
          name: info.utsname.machine,
          host: info.utsname.nodename,
          platform: "iOS",
          operatingSystemVersion: Platform.operatingSystemVersion,
          operatingSystem: Platform.operatingSystem,
          ipAddress: _ipAddress,
          localHostName: Platform.localHostname,
        );
        break;

      case RuntimePlatform.macos:
        final info = await plugin.macOsInfo;

        _operatingSystem = 'macOS ${info.osRelease}';
        _operatingSystemVersion = info.osRelease;
        _deviceInfo = _operatingSystem;

        _device = _device.copyWith(
          id: info.kernelVersion,
          name: info.model,
          host: info.hostName,
          platform: "macOS",
          operatingSystemVersion: Platform.operatingSystemVersion,
          operatingSystem: Platform.operatingSystem,
          ipAddress: _ipAddress,
          localHostName: Platform.localHostname,
        );
        break;

      case RuntimePlatform.windows:
        final info = await plugin.windowsInfo;

        _operatingSystem = 'Windows ${info.releaseId}';
        _operatingSystemVersion = info.releaseId;
        _deviceInfo = _operatingSystem;

        _device = _device.copyWith(
          id: info.deviceId,
          name: info.productName,
          host: info.computerName,
          platform: "Windows",
          operatingSystemVersion: Platform.operatingSystemVersion,
          operatingSystem: Platform.operatingSystem,
          ipAddress: _ipAddress,
          localHostName: Platform.localHostname,
        );
        break;

      case RuntimePlatform.linux:
        final info = await plugin.linuxInfo;

        _operatingSystem = 'Linux ${info.versionCodename}';
        _operatingSystemVersion = info.versionId ?? "Unknown";
        _deviceInfo = _operatingSystem;

        _device = _device.copyWith(
          id: info.id,
          name: info.prettyName,
          host: info.versionCodename,
          platform: "Linux",
          operatingSystemVersion: Platform.operatingSystemVersion,
          operatingSystem: Platform.operatingSystem,
          ipAddress: _ipAddress,
          localHostName: Platform.localHostname,
        );
        break;

      case RuntimePlatform.unknown:
        _operatingSystem = "Unknown OS";
        _operatingSystemVersion = "Unknown Version";
        _deviceInfo = "Unknown Device";
        _device = Device.empty();
        break;
    }
  }
}