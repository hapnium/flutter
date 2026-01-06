/// A class for managing asset paths within the application.
library;

/// This class provides a convenient way to access and manage the paths to
/// various assets used throughout the application.
class SmartSocialAssets {
  /// Returns the base path for assets within the 'assets/app' directory.
  static String _base(String name) => "packages/smart/assets/social/$name.png";

  /// The path to the "asterisk" asset.
  static String asterisk = _base("asterisk");

  /// The path to the "instagram" asset.
  static String instagram = _base("instagram");

  /// The path to the "linkedin" asset.
  static String linkedin = _base("linkedin");

  /// The path to the "tiktok" asset.
  static String tiktok = _base("tiktok");

  /// The path to the "whatsapp" asset.
  static String whatsapp = _base("whatsapp");

  /// The path to the "youtube" asset.
  static String youtube = _base("youtube");

  /// The path to the "twitter" asset.
  static String twitter = _base("twitter");
}