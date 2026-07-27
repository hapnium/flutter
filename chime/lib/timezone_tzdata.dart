/// Re-export of `package:timezone/tzdata`.
///
/// Provides the built-in IANA timezone database used by the timezone package.
/// Import this file to bundle timezone data into your application binary,
/// ensuring timezone-aware scheduling works without a network connection.
///
/// Import this file alongside [timezone] or [timezone_standalone] when your
/// app needs offline timezone resolution for notification scheduling.
library;

export 'package:timezone/tzdata.dart';