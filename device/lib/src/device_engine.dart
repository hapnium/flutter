import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_io/io.dart';
import 'package:tracing/tracing.dart';

import 'models/device.dart';

/// Function signature for custom IP address fetching
typedef IpAddressFetcher = Future<String> Function();

/// {@template device_engine}
/// A utility class for identifying platform, device, and environment information
/// in a Flutter application. Supports web, mobile, and desktop platforms.
/// 
/// This class is implemented as a singleton. Call [DeviceEngine.initialize] 
/// before accessing any fields or getters.
///
/// You can use this class to gather information such as:
/// - Operating system and version
/// - Device model and host
/// - IP address (optionally via a custom provider)
/// - High-level platform checks (e.g., [isMobile], [isDesktop])
///
/// Example usage:
///
/// ```dart
/// await DeviceEngine.instance.initialize(debug: true);
/// print(DeviceEngine.instance.operatingSystem);
/// print(DeviceEngine.instance.device.toJson());
/// ```
/// {@endtemplate}
class DeviceEngine {
  // Private constructor for singleton pattern
  /// {@macro device_engine}
  DeviceEngine._();

  // The single instance of the Platform
  static final DeviceEngine _instance = DeviceEngine._();

  /// Access the singleton instance of [DeviceEngine].
  static DeviceEngine get instance => _instance;

  // Custom IP address fetcher function (registered once)
  static IpAddressFetcher? _customIpAddressFetcher;

  /// The name of the operating system.
  ///
  /// Default: `""`
  String _operatingSystem = "";

  /// The version of the operating system.
  ///
  /// Default: `""`
  String _operatingSystemVersion = "";

  /// Device details, typically a stringified form such as user agent or OS summary.
  ///
  /// Default: `""`
  String _deviceInfo = "";

  /// The device's IP address, resolved during initialization.
  ///
  /// Default: `""`
  String _ipAddress = "";

  /// A structured representation of the device and platform.
  ///
  /// Default: [Device.empty()]
  Device _device = Device.empty();

  bool _isWasm = false;
  bool _isWeb = false;
  bool _isDebugMode = false;

  /// Initializes the [DeviceEngine] by gathering platform and network details.
  ///
  /// This must be called once before accessing other properties.
  ///
  /// You can optionally provide a [debug] flag to log output and a
  /// [ipAddressSupplier] function to override the default IP fetch logic.
  Future<void> initialize({bool debug = false, IpAddressFetcher? ipAddressSupplier, bool? isWasm, bool? isWeb, bool? isDebugMode}) async {
    _customIpAddressFetcher = ipAddressSupplier;
    _ipAddress = await _fetchDeviceIpAddress();
    _isWasm = isWasm ?? false;
    _isWeb = isWeb ?? false;
    _isDebugMode = isDebugMode ?? false;

    await _prepareDevice();

    if(debug) {
      console.log("Device Engine Initialized", tag: "DeviceEngine");
      console.log("Operating System: $_operatingSystem", tag: "DeviceEngine");
      console.log("Operating System Version: $_operatingSystemVersion", tag: "DeviceEngine");
      console.log("Device Info: $_deviceInfo", tag: "DeviceEngine");
      console.log("IP Address: $_ipAddress", tag: "DeviceEngine");
      console.log("Device: ${_device.toJson()}", tag: "DeviceEngine");
    }
  }

  Future<String> _fetchDeviceIpAddress() async {
    // If a custom IP address fetcher is registered, use it
    if (_customIpAddressFetcher != null) {
      try {
        return await _customIpAddressFetcher!();
      } catch (e) {
        if(debug) {
          console.log("Custom IP address fetcher failed: $e", tag: "DeviceEngine");
        }
      }
    }

    // Default behavior for web platforms
    if(isWeb) {
      // For web, there's no direct API in Flutter/Dart to get IP address
      // without making HTTP requests, so return empty string
      return "";
    }

    // Default behavior for non-web platforms using NetworkInterface
    try {
      var networks = await NetworkInterface.list();
      if(networks.isNotEmpty) {
        var addresses = networks.first.addresses;
        if(addresses.isNotEmpty) {
          return addresses.first.address;
        }
      }
    } catch (e) {
      if(debug) {
        console.log("Failed to fetch IP address via NetworkInterface: $e", tag: "DeviceEngine");
      }
    }

    return "";
  }

  Future<void> _prepareDevice() async {
    final plugin = DeviceInfoPlugin();

    if (isWeb) {
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
        ipAddress: await _fetchDeviceIpAddress()
      );
    } else if (isAndroid) {
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
        ipAddress: await _fetchDeviceIpAddress(),
        localHostName: Platform.localHostname
      );
    } else if (isIOS) {
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
        ipAddress: await _fetchDeviceIpAddress(),
        localHostName: Platform.localHostname
      );
    } else if (isMacOS) {
      final info = await plugin.macOsInfo;

      _operatingSystem = 'macOS ${info.osRelease}';
      _operatingSystemVersion = info.osRelease;
      _deviceInfo = _operatingSystem;

      _device = _device.copyWith(
        id: info.kernelVersion,
        name: info.model,
        host: info.hostName,
        platform: "MacOs",
        operatingSystemVersion: Platform.operatingSystemVersion,
        operatingSystem: Platform.operatingSystem,
        ipAddress: await _fetchDeviceIpAddress(),
        localHostName: Platform.localHostname
      );
    } else if (isWindows) {
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
        ipAddress: await _fetchDeviceIpAddress(),
        localHostName: Platform.localHostname
      );
    } else if (isLinux) {
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
        ipAddress: await _fetchDeviceIpAddress(),
        localHostName: Platform.localHostname
      );
    } else {
      _operatingSystem = "Unknown OS";
      _operatingSystemVersion = "Unknown Version";
      _deviceInfo = "Unknown Device";
    }
  }

  /// Returns `true` if the application is running on a web platform for `wasm`.
  bool get isWebWasm => _isWasm;

  /// Returns `true` if the application is running on a web platform.
  bool get isWeb => _isWeb || isWebWasm;

  /// Returns `true` if the application is running on an Android device.
  bool get isAndroid => !isWeb && Platform.isAndroid;

  /// Returns `true` if the application is running on an iOS device.
  bool get isIOS => !isWeb && Platform.isIOS;

  /// Returns `true` if the application is running on a macOS device.
  bool get isMacOS => !isWeb && Platform.isMacOS;

  /// Returns `true` if the application is running on a Linux device.
  bool get isLinux => !isWeb && Platform.isLinux;

  /// Returns `true` if the application is running on a Windows device.
  bool get isWindows => !isWeb && Platform.isWindows;

  /// Returns `true` if the application is running on a mobile platform (Android or iOS).
  bool get isMobile => !isWeb && (isAndroid || isIOS);

  /// Returns `true` if the application is running on a desktop platform (Windows, Linux, or macOS).
  bool get isDesktop => !isWeb && (isLinux || isMacOS || isWindows);

  /// Gets the name of the current operating system.
  ///
  /// Example: `"Android"`, `"iOS"`, `"Web Chrome"`
  String get operatingSystem => _operatingSystem;

  /// Gets the current operating system version.
  ///
  /// Example: `"13"`, `"10.15.7"`, `"110.0.5481.77"`
  String get operatingSystemVersion => _operatingSystemVersion;

  /// Returns raw device info such as a summary or user agent string.
  ///
  /// Typically populated by `_prepareDevice()`.
  String get deviceInfo => _deviceInfo;

  /// Returns the current IP address of the device.
  ///
  /// This is either computed internally or provided via a custom IP supplier.
  String get ipAddress => _ipAddress;

  /// Returns a structured representation of the current device.
  ///
  /// Includes fields such as platform, host, local hostname, etc.
  Device get device => _device;

  /// Returns whether the application is running in debug mode.
  bool get debug => _isDebugMode;

  /// Returns the name of the current platform.
  ///
  /// Can return values like `"Web"`, `"Android"`, `"iOS"`, or `"Unknown"`.
  String get platform => isWeb ? "Web" : isAndroid ? "Android" : isIOS ? "iOS" : "Unknown";
}