/// Re-export of `package:timezone/browser`.
///
/// Provides browser-compatible timezone initialization for Web platforms.
/// Call [initializeTimeZonesBrowser] before using timezone-aware scheduling
/// in web environments. Chime's [ChimePushNotificationBuilder] uses this
/// when the app targets web.
///
/// Import this file when building web-specific notification scheduling
/// that requires timezone data.
library;

export 'package:timezone/browser.dart';