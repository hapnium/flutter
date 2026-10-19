import '../../../enums/ui/screen_size.dart';

/// Provides convenience methods for checking the current [ScreenSize].
///
/// Example:
/// ```dart
/// if (screenSize.isMobile) {
///   print("Displaying mobile layout.");
/// }
/// ```
extension ScreenSizeExtension on ScreenSize {
  /// Returns `true` if the screen size is set to [ScreenSize.mobile].
  ///
  /// This indicates that the current screen size corresponds to a mobile device.
  bool get isMobile => this == ScreenSize.mobile;

  /// Returns `true` if the screen size is set to [ScreenSize.tablet].
  ///
  /// This indicates that the current screen size corresponds to a tablet device.
  bool get isTablet => this == ScreenSize.tablet;

  /// Returns `true` if the screen size is set to [ScreenSize.desktop].
  ///
  /// This indicates that the current screen size corresponds to a desktop or large screen device.
  bool get isDesktop => this == ScreenSize.desktop;
}