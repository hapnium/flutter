import 'ansi_color.dart';
import '../enums/log_level.dart';

/// A utility class that provides common styling and symbols for different [LogLevel]s.
///
/// The `LogCommons` class is designed to aid in formatting and visualizing log output
/// in the console or terminal, particularly during development or debugging. It maps
/// log severity levels to ANSI color codes and emoji icons for enhanced readability.
///
/// This class cannot be instantiated and is intended to be used statically.
///
/// ### Example usage:
/// ```dart
/// final emoji = LogCommons.levelEmojis[LogLevel.error]; // ❌
/// final color = LogCommons.levelColors[LogLevel.info];  // Green text color (ANSI)
/// print('${color.wrap("$emoji Info message")}');
/// ```
class LogCommons {
  /// Private constructor to prevent instantiation.
  LogCommons._();

  /// A mapping between [LogLevel]s and their associated ANSI foreground color.
  ///
  /// These colors are used to style log messages with consistent, meaningful
  /// color coding based on severity level:
  /// 
  /// | Level   | Color Code | Description       |
  /// |---------|------------|-------------------|
  /// | trace   | 8          | Dim gray          |
  /// | debug   | 12         | Bright blue       |
  /// | info    | 10         | Bright green      |
  /// | warning | 11         | Bright yellow     |
  /// | error   | 9          | Bright red        |
  /// | fatal   | 196        | Vivid red (alert) |
  ///
  /// Use these to format terminal output for better visual scanning.
  static final levelColors = {
    LogLevel.TRACE: const AnsiColor.fg(8),
    LogLevel.DEBUG: const AnsiColor.fg(12),
    LogLevel.INFO: const AnsiColor.fg(10),
    LogLevel.WARN: const AnsiColor.fg(11),
    LogLevel.ERROR: const AnsiColor.fg(9),
    LogLevel.FATAL: const AnsiColor.fg(196),
  };

  /// A mapping between [LogLevel]s and their associated emoji icon.
  ///
  /// Emojis provide quick visual cues to identify the severity or type of log messages:
  /// 
  /// | Level   | Emoji | Description          |
  /// |---------|--------|----------------------|
  /// | trace   | 🔍     | Fine-grained logs    |
  /// | debug   | 🐛     | Debug messages       |
  /// | info    | 💡     | Informational notes  |
  /// | warning | ⚠️     | Cautionary messages  |
  /// | error   | ❌     | Recoverable issues   |
  /// | fatal   | 💀     | Critical application |
  ///
  /// These are commonly prepended to log statements for extra clarity.
  static final levelEmojis = {
    LogLevel.TRACE: '🔍',
    LogLevel.DEBUG: '🐛',
    LogLevel.INFO: '💡',
    LogLevel.WARN: '⚠️',
    LogLevel.ERROR: '❌',
    LogLevel.FATAL: '💀',
  };

  /// Formats a timestamp based on the specified format.
  /// 
  /// If [humanReadable] is true, the timestamp is formatted as a human-readable string.
  /// Otherwise, it is formatted as an ISO 8601 string.
  /// 
  /// Example usage:
  /// ```dart
  /// final timestamp = LogCommons.formatTimestamp(DateTime.now(), true);
  /// print(timestamp); // e.g., "2025-06-18 14:22:01"
  /// ```
  static String formatTimestamp(DateTime time, bool humanReadable) {
    if (!humanReadable) {
      return time.toIso8601String();
    }

    final local = time.toLocal();

    final weekday = _weekdayName(local.weekday);
    final day = local.day;
    final suffix = _daySuffix(day);
    final month = _monthName(local.month);
    final year = local.year;

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$weekday, $day$suffix $month, $year | $hour:$minute$period';
  }

  /// Returns the name of the weekday for the given weekday number.
  /// 
  /// Example usage:
  /// ```dart
  /// final weekday = LogCommons._weekdayName(1);
  /// print(weekday); // e.g., "Monday"
  /// ```
  static String _weekdayName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return names[weekday - 1];
  }

  /// Returns the name of the month for the given month number.
  /// 
  /// Example usage:
  /// ```dart
  /// final month = LogCommons._monthName(1);
  /// print(month); // e.g., "January"
  /// ```
  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  /// Returns the suffix for the given day number.
  /// 
  /// Example usage:
  /// ```dart
  /// final suffix = LogCommons._daySuffix(1);
  /// print(suffix); // e.g., "st"
  /// ```
  static String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Formats a duration in a human-readable format.
  /// 
  /// The duration is formatted as a string with the format "+Xms" where X is the number of milliseconds.
  /// 
  /// Example usage:
  /// ```dart
  /// final elapsed = Duration(milliseconds: 1234);
  /// final formatted = LogCommons.formatElapsed(elapsed);
  /// print(formatted); // e.g., "+1234ms"
  /// ```
  static String formatElapsed(Duration elapsed) {
    return "+${elapsed.toString().split('.').first}";
  }

  static String? extractCallerLocation([int frameLevel = 2]) {
    try {
      final trace = StackTrace.current.toString().split('\n');
      if (trace.length > frameLevel) {
        final frame = trace[frameLevel].trim(); // Example: '#2   MyClass.myMethod (package:app/main.dart:42:13)'
        final regex = RegExp(r'#\d+\s+(.+?) \((.+?):(\d+):(\d+)\)');
        final match = regex.firstMatch(frame);

        if (match != null) {
          final method = match.group(1);
          final file = match.group(2);
          final line = match.group(3);
          final column = match.group(4);
          return '$method ($file:$line:$column)\n${file?.split('/').last}:$line';
        }
      }
    } catch (_) {}
    return null;
  }
}