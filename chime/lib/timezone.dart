/// Re-export of `package:timezone`.
///
/// Provides timezone data structures including [TZDateTime], [Location], and
/// [TZDateTime.now]. Chime uses this for scheduling notifications at specific
/// times across different timezones, particularly on Android where
/// `zonedSchedule` requires [TZDateTime] parameters.
///
/// Import this file when you need timezone-aware date handling in your
/// notification scheduling code.
library;

export 'package:timezone/timezone.dart';