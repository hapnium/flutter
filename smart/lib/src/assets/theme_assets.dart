/// A class for managing asset paths within the app.
library;

/// This class provides a convenient way to access and manage the paths to
/// various assets used throughout the app.
class SmartThemeAssets {
  /// Returns the base path for assets within the 'assets/theme' directory.
  static String _base(String name) => "packages/smart/assets/theme/$name.png";

  /// The path to the "dark" asset.
  static String dark = _base("dark");

  /// The path to the "light" asset.
  static String light = _base("light");
}