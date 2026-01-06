/// A class for managing asset paths within the application.
library;

/// This class provides a convenient way to access and manage the paths to
/// various assets used throughout the application.
class SmartDriveAssets {
  /// Returns the base path for assets within the 'assets/anim' directory.
  static String _base(String name) => "packages/smart/assets/drive/$name.png";

  /// The path to the "driveBlack" asset.
  static String driveBlack = _base("driveBlack");

  /// The path to the "driveBlackReverse" asset.
  static String driveBlackReverse = _base("driveBlackReverse");

  /// The path to the "driveCarBlack" asset.
  static String driveCarBlack = _base("driveCarBlack");

  /// The path to the "driveCarBlackReverse" asset.
  static String driveCarBlackReverse = _base("driveCarBlackReverse");

  /// The path to the "driveTo" asset.
  static String driveTo = _base("driveTo");

  /// The path to the "driveWhite" asset.
  static String driveWhite = _base("driveWhite");

  /// The path to the "driveWhiteReverse" asset.
  static String driveWhiteReverse = _base("driveWhiteReverse");

  /// The path to the "driveCarWhite" asset.
  static String driveCarWhite = _base("driveCarWhite");

  /// The path to the "driveCarWhiteReverse" asset.
  static String driveCarWhiteReverse = _base("driveCarWhiteReverse");
}