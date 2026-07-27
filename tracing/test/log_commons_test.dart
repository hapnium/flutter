import 'package:test/test.dart';
import 'package:tracing/src/helpers/commons.dart';
import 'package:tracing/src/helpers/ansi_color.dart';
import 'package:tracing/src/enums/log_level.dart';

void main() {
  group('LogCommons', () {
    group('levelColors', () {
      test('contains all log levels', () {
        expect(LogCommons.levelColors, contains(LogLevel.TRACE));
        expect(LogCommons.levelColors, contains(LogLevel.DEBUG));
        expect(LogCommons.levelColors, contains(LogLevel.INFO));
        expect(LogCommons.levelColors, contains(LogLevel.WARN));
        expect(LogCommons.levelColors, contains(LogLevel.ERROR));
        expect(LogCommons.levelColors, contains(LogLevel.FATAL));
      });

      test('TRACE maps to AnsiColor with fg 8', () {
        expect(LogCommons.levelColors[LogLevel.TRACE], isA<AnsiColor>());
        expect(LogCommons.levelColors[LogLevel.TRACE]!.fg, 8);
      });

      test('DEBUG maps to AnsiColor with fg 12', () {
        expect(LogCommons.levelColors[LogLevel.DEBUG]!.fg, 12);
      });

      test('INFO maps to AnsiColor with fg 10', () {
        expect(LogCommons.levelColors[LogLevel.INFO]!.fg, 10);
      });

      test('WARN maps to AnsiColor with fg 11', () {
        expect(LogCommons.levelColors[LogLevel.WARN]!.fg, 11);
      });

      test('ERROR maps to AnsiColor with fg 9', () {
        expect(LogCommons.levelColors[LogLevel.ERROR]!.fg, 9);
      });

      test('FATAL maps to AnsiColor with fg 196', () {
        expect(LogCommons.levelColors[LogLevel.FATAL]!.fg, 196);
      });
    });

    group('levelEmojis', () {
      test('contains all log levels', () {
        expect(LogCommons.levelEmojis, contains(LogLevel.TRACE));
        expect(LogCommons.levelEmojis, contains(LogLevel.DEBUG));
        expect(LogCommons.levelEmojis, contains(LogLevel.INFO));
        expect(LogCommons.levelEmojis, contains(LogLevel.WARN));
        expect(LogCommons.levelEmojis, contains(LogLevel.ERROR));
        expect(LogCommons.levelEmojis, contains(LogLevel.FATAL));
      });

      test('TRACE maps to magnifying glass emoji', () {
        expect(LogCommons.levelEmojis[LogLevel.TRACE], '🔍');
      });

      test('DEBUG maps to bug emoji', () {
        expect(LogCommons.levelEmojis[LogLevel.DEBUG], '🐛');
      });

      test('INFO maps to lightbulb emoji', () {
        expect(LogCommons.levelEmojis[LogLevel.INFO], '💡');
      });

      test('WARN maps to warning emoji', () {
        expect(LogCommons.levelEmojis[LogLevel.WARN], '⚠️');
      });

      test('ERROR maps to cross emoji', () {
        expect(LogCommons.levelEmojis[LogLevel.ERROR], '❌');
      });

      test('FATAL maps to skull emoji', () {
        expect(LogCommons.levelEmojis[LogLevel.FATAL], '💀');
      });
    });

    group('formatTimestamp', () {
      test('returns ISO 8601 when humanReadable is false', () {
        final time = DateTime(2025, 6, 18, 14, 30, 0);
        final result = LogCommons.formatTimestamp(time, false);
        expect(result, contains('2025'));
        expect(result, contains('T'));
      });

      test('returns human-readable format when humanReadable is true', () {
        final time = DateTime(2025, 6, 18, 14, 30, 0);
        final result = LogCommons.formatTimestamp(time, true);
        expect(result, contains('Wednesday'));
        expect(result, contains('June'));
        expect(result, contains('2025'));
        expect(result, contains('2:30PM'));
      });

      test('formats midnight correctly (12 AM)', () {
        final time = DateTime(2025, 1, 1, 0, 0, 0);
        final result = LogCommons.formatTimestamp(time, true);
        expect(result, contains('12:00AM'));
      });

      test('formats noon correctly (12 PM)', () {
        final time = DateTime(2025, 1, 1, 12, 0, 0);
        final result = LogCommons.formatTimestamp(time, true);
        expect(result, contains('12:00PM'));
      });

      test('formats 11:59 PM correctly', () {
        final time = DateTime(2025, 12, 31, 23, 59, 0);
        final result = LogCommons.formatTimestamp(time, true);
        expect(result, contains('11:59PM'));
      });

      test('formats 1:00 AM correctly', () {
        final time = DateTime(2025, 3, 15, 1, 0, 0);
        final result = LogCommons.formatTimestamp(time, true);
        expect(result, contains('1:00AM'));
      });
    });

    group('formatElapsed', () {
      test('formats duration with + prefix and ms', () {
        final elapsed = Duration(milliseconds: 1234);
        final result = LogCommons.formatElapsed(elapsed);
        expect(result, startsWith('+'));
        expect(result, contains('0:00:01'));
      });

      test('formats zero duration', () {
        final elapsed = Duration.zero;
        final result = LogCommons.formatElapsed(elapsed);
        expect(result, startsWith('+'));
      });

      test('formats large duration', () {
        final elapsed = Duration(hours: 1, minutes: 30);
        final result = LogCommons.formatElapsed(elapsed);
        expect(result, contains('1:30:00'));
      });
    });

    group('extractCallerLocation', () {
      test('returns a location string or null', () {
        // The result depends on the runtime stack; just verify it doesn't throw
        expect(() => LogCommons.extractCallerLocation(), returnsNormally);
      });
    });
  });
}