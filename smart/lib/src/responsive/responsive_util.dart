import 'package:flutter/widgets.dart';
import 'package:smart/smart.dart';

ResponsiveConfig _config = ResponsiveConfig();

/// {@template responsive_util}
/// A utility class for managing responsive breakpoints and screen properties.
///
/// This class provides a convenient way to determine whether the current screen size
/// is categorized as mobile, tablet, or desktop based on predefined breakpoints.
/// Additionally, it provides access to other screen-related properties such as width,
/// height, padding, and text scaling factor.
/// 
/// ## Example Usage
/// ```dart
/// final responsive = ResponsiveUtil(context);
/// 
/// if (responsive.isMobile) {
///   return MobileLayout();
/// } else if (responsive.isTablet) {
///   return TabletLayout();
/// } else {
///   return DesktopLayout();
/// }
/// ```
/// 
/// {@endtemplate}
class ResponsiveUtil {
  late Size _size;
  ResponsiveConfig _responsive = ResponsiveConfig();

  /// Private constructor to prevent direct instantiation.
  ResponsiveUtil._();

  /// Sets a new global responsive configuration.
  ///
  /// ## Parameters
  /// - [config]: The new [ResponsiveConfig] to use globally.
  /// 
  /// ## Example
  /// ```dart
  /// ResponsiveUtil.setConfig(CustomResponsiveConfig());
  /// ```
  static void setConfig(ResponsiveConfig config) => _config = config;

  /// Creates a responsive utility instance for the given [BuildContext].
  ///
  /// ## Parameters
  /// - [context]: The build context used to determine screen size.
  /// - [config]: Optional local configuration override. If provided,
  ///   temporarily uses this config instead of the global one.
  /// 
  /// ## Returns
  /// A [ResponsiveUtil] instance configured for the current screen.
  /// 
  /// ## Example
  /// ```dart
  /// // With global configuration
  /// final responsive = ResponsiveUtil(context);
  /// 
  /// // With local configuration override
  /// final responsive = ResponsiveUtil(
  ///   context,
  ///   config: CustomResponsiveConfig(),
  /// );
  /// ```
  /// 
  /// {@macro responsive_util}
  factory ResponsiveUtil(BuildContext context, {ResponsiveConfig? config}) {
    final instance = ResponsiveUtil._();
    instance._size = MediaQuery.sizeOf(context);

    if(config case final config?) {
      instance._responsive = config;
    } else {
      instance._responsive = _config;
    }

    return instance;
  }

  /// Returns `true` if the screen width is less than the mobile breakpoint.
  ///
  /// Typically used for phones and small handheld devices.
  /// Example: Smartphones, small tablets in portrait mode.
  bool get isMobile => _size.width < _responsive.mobile;

  /// Returns `true` if the screen width is between the mobile and tablet breakpoints.
  ///
  /// Typically used for tablets and medium-sized devices.
  /// Example: iPads, Android tablets, small laptops.
  bool get isTablet => _size.width >= _responsive.mobile && _size.width < _responsive.tablet;

  /// Returns `true` if the screen width is greater than or equal to the tablet breakpoint.
  ///
  /// Typically used for desktop computers and large screens.
  /// Example: Desktop monitors, large tablets in landscape mode.
  bool get isDesktop => _size.width >= _responsive.tablet;

  /// The current screen width in logical pixels.
  /// Useful for custom responsive calculations beyond simple breakpoints.
  double get screenWidth => _size.width;

  /// The current screen height in logical pixels.
  /// Useful for vertical layout decisions and aspect ratio calculations.
  double get screenHeight => _size.height;
}