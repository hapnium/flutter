/// Re-export of `package:universal_io/io.dart`.
///
/// Provides a cross-platform `dart:io` that works on Web without throwing
/// errors. On native platforms (Android, iOS, macOS, Windows, Linux), it
/// behaves identically to `dart:io`. On Web, it provides stub implementations
/// that return default values.
///
/// Import this file when you need `Platform`, `NetworkInterface`, or other
/// `dart:io` types in code that must compile for all platforms.
library;

export 'package:universal_io/io.dart';