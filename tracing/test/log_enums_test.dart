import 'package:test/test.dart';
import 'package:tracing/src/enums/log_step.dart';
import 'package:tracing/src/enums/log_type.dart';
import 'package:tracing/src/enums/log_level.dart';

void main() {
  group('LogStep', () {
    test('has all expected values', () {
      expect(LogStep.values.length, 9);
      expect(LogStep.values, contains(LogStep.TIMESTAMP));
      expect(LogStep.values, contains(LogStep.DATE));
      expect(LogStep.values, contains(LogStep.LEVEL));
      expect(LogStep.values, contains(LogStep.TAG));
      expect(LogStep.values, contains(LogStep.THREAD));
      expect(LogStep.values, contains(LogStep.LOCATION));
      expect(LogStep.values, contains(LogStep.MESSAGE));
      expect(LogStep.values, contains(LogStep.ERROR));
      expect(LogStep.values, contains(LogStep.STACKTRACE));
    });

    group('defaultSteps', () {
      test('contains all steps', () {
        expect(LogStep.defaultSteps.length, 9);
      });

      test('starts with DATE', () {
        expect(LogStep.defaultSteps.first, LogStep.DATE);
      });

      test('ends with STACKTRACE', () {
        expect(LogStep.defaultSteps.last, LogStep.STACKTRACE);
      });

      test('has MESSAGE in the middle', () {
        expect(LogStep.defaultSteps, contains(LogStep.MESSAGE));
      });

      test('has TAG before LEVEL', () {
        final tagIndex = LogStep.defaultSteps.indexOf(LogStep.TAG);
        final levelIndex = LogStep.defaultSteps.indexOf(LogStep.LEVEL);
        expect(tagIndex, lessThan(levelIndex));
      });
    });
  });

  group('LogType', () {
    test('has all expected values', () {
      expect(LogType.values.length, 8);
      expect(LogType.values, contains(LogType.FLAT));
      expect(LogType.values, contains(LogType.FLAT_STRUCTURED));
      expect(LogType.values, contains(LogType.PRETTY));
      expect(LogType.values, contains(LogType.PRETTY_STRUCTURED));
      expect(LogType.values, contains(LogType.PREFIX));
      expect(LogType.values, contains(LogType.FMT));
      expect(LogType.values, contains(LogType.SIMPLE));
      expect(LogType.values, contains(LogType.HYBRID));
    });
  });

  group('LogLevel', () {
    test('has all expected values', () {
      expect(LogLevel.values.length, 7);
      expect(LogLevel.values, contains(LogLevel.TRACE));
      expect(LogLevel.values, contains(LogLevel.DEBUG));
      expect(LogLevel.values, contains(LogLevel.INFO));
      expect(LogLevel.values, contains(LogLevel.WARN));
      expect(LogLevel.values, contains(LogLevel.ERROR));
      expect(LogLevel.values, contains(LogLevel.FATAL));
      expect(LogLevel.values, contains(LogLevel.OFF));
    });

    test('values are ordered by severity', () {
      expect(LogLevel.TRACE.value, 0);
      expect(LogLevel.DEBUG.value, 1);
      expect(LogLevel.INFO.value, 2);
      expect(LogLevel.WARN.value, 3);
      expect(LogLevel.ERROR.value, 4);
      expect(LogLevel.FATAL.value, 5);
      expect(LogLevel.OFF.value, 6);
    });

    test('isEnabledFor returns true when level is at or below current', () {
      expect(LogLevel.INFO.isEnabledFor(LogLevel.TRACE), isTrue);
      expect(LogLevel.INFO.isEnabledFor(LogLevel.DEBUG), isTrue);
      expect(LogLevel.INFO.isEnabledFor(LogLevel.INFO), isTrue);
      expect(LogLevel.INFO.isEnabledFor(LogLevel.WARN), isFalse);
      expect(LogLevel.INFO.isEnabledFor(LogLevel.ERROR), isFalse);
      expect(LogLevel.INFO.isEnabledFor(LogLevel.FATAL), isFalse);
    });

    test('toString returns the name', () {
      expect(LogLevel.TRACE.toString(), 'TRACE');
      expect(LogLevel.DEBUG.toString(), 'DEBUG');
      expect(LogLevel.INFO.toString(), 'INFO');
      expect(LogLevel.WARN.toString(), 'WARNING');
      expect(LogLevel.ERROR.toString(), 'ERROR');
      expect(LogLevel.FATAL.toString(), 'FATAL');
      expect(LogLevel.OFF.toString(), 'OFF');
    });
  });
}