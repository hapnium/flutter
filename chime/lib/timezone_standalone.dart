/// Re-export of `package:timezone/standalone`.
///
/// Provides standalone timezone initialization for non-web Dart environments
/// (VM, Flutter mobile/desktop). Call [initializeTimeZones] before using
/// timezone-aware scheduling. Chime's [ChimePushNotificationBuilder] uses
/// this for mobile and desktop platforms.
///
/// Import this file when building mobile or desktop notification scheduling
/// that requires timezone data.
library;

export 'package:timezone/standalone.dart';