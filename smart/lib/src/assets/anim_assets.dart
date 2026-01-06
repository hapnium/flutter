/// A class for managing asset paths within the application.
library;

/// This class provides a convenient way to access and manage the paths to
/// various assets used throughout the application.
class SmartAnimAssets {
  /// Returns the base path for assets within the 'assets/anim' directory.
  static String _base(String name) => "packages/smart/assets/anim/$name.png";

  /// The path to the "darkWallpaper" asset.
  static String darkWallpaper = _base("darkWallpaper");

  /// The path to the "lightWallpaper" asset.
  static String lightWallpaper = _base("lightWallpaper");

  /// The path to the "messages" asset.
  static String messages = _base("messages");

  /// The path to the "notes" asset.
  static String notes = _base("notes");

  /// The path to the "review" asset.
  static String review = _base("review");

  /// The path to the "hapnium_chat" asset.
  static String hapniumChat = _base("hapnium_chat");

  /// The path to the "verified" asset.
  static String verified = _base("verified");

  /// The path to the "wallet" asset.
  static String wallet = _base("wallet");
}