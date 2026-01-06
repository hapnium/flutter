/// A class for managing asset paths within the application.
library;

/// This class provides a convenient way to access and manage the paths to
/// various assets used throughout the application.
class SmartMapAssets {
  /// Returns the base path for assets within the 'assets/anim' directory.
  static String _base(String name) => "packages/smart/assets/map/$name.png";

  /// The path to the "bing" asset.
  static String bing = _base("bing");

  /// The path to the "current" asset.
  static String current = _base("current");

  /// The path to the "destination" asset.
  static String destination = _base("destination");

  /// The path to the "drive" asset.
  static String drive = _base("drive");

  /// The path to the "fly" asset.
  static String fly = _base("fly");

  /// The path to the "googleMap" asset.
  static String googleMap = _base("googleMap");

  /// The path to the "location" asset.
  static String location = _base("location");

  /// The path to the "mapRight" asset.
  static String mapRight = _base("mapRight");

  /// The path to the "openStreetMap" asset.
  static String openStreetMap = _base("openStreetMap");

  /// The path to the "upRight" asset.
  static String upRight = _base("upRight");

  /// The path to the "world" asset.
  static String world = _base("world");
}