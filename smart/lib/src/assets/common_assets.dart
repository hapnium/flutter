/// A class for managing asset paths within the application.
library;

/// This class provides a convenient way to access and manage the paths to
/// various assets used throughout the application.
class SmartCommonAssets {
  /// Returns the base path for assets within the 'assets/anim' directory.
  static String _base(String name) => "packages/smart/assets/common/$name.png";

  /// The path to the "account" asset.
  static String account = _base("account");

  /// The path to the "account_trust" asset.
  static String accountTrust = _base("account_trust");

  /// The path to the "bookmark" asset.
  static String bookmark = _base("bookmark");

  /// The path to the "connect" asset.
  static String connect = _base("connect");

  /// The path to the "drive" asset.
  static String drive = _base("drive");

  /// The path to the "gender" asset.
  static String gender = _base("gender");

  /// The path to the "notLaunched" asset.
  static String notLaunched = _base("notLaunched");

  /// The path to the "onboard1" asset.
  static String onboard1 = _base("onboard1");

  /// The path to the "onboard2" asset.
  static String onboard2 = _base("onboard2");

  /// The path to the "organization" asset.
  static String organization = _base("organization");

  /// The path to the "personal" asset.
  static String personal = _base("personal");

  /// The path to the "referralProgram" asset.
  static String referralProgram = _base("referralProgram");

  /// The path to the "share" asset.
  static String share = _base("share");

  /// The path to the "sharedLink" asset.
  static String sharedLink = _base("sharedLink");

  /// The path to the "shop" asset.
  static String shop = _base("shop");

  /// The path to the "skill" asset.
  static String skill = _base("skill");

  /// The path to the "speak" asset.
  static String speak = _base("speak");
}