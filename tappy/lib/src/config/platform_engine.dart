import '../enums/tappy_platform.dart';
import '../core/tappy.dart';

/// Provides platform identification utilities.
class PlatformEngine {
  // Private constructor for singleton pattern
  PlatformEngine._();

  /// Returns `true` if the application is running on a web platform.
  static bool get isWeb => Tappy.platform == TappyPlatform.WEB;

  /// Returns `true` if the application is running on an Android device.
  static bool get isAndroid => Tappy.platform == TappyPlatform.ANDROID;

  /// Returns `true` if the application is running on an iOS device.
  static bool get isIOS => Tappy.platform == TappyPlatform.IOS;

  /// Returns `true` if the application is running on an mobile device.
  static bool get isMobile => !isWeb && (isAndroid || isIOS);
}