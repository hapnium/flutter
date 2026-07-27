import 'package:test/test.dart';
import 'package:tracing/src/models/log_config.dart';
import 'package:tracing/src/enums/log_step.dart';

void main() {
  group('LogConfig', () {
    test('default constructor enables all options', () {
      final config = LogConfig();
      expect(config.showTimestamp, isTrue);
      expect(config.showTimeOnly, isTrue);
      expect(config.showDateOnly, isTrue);
      expect(config.showLevel, isTrue);
      expect(config.showTag, isTrue);
      expect(config.showThread, isTrue);
      expect(config.useHumanReadableTime, isTrue);
      expect(config.showEmoji, isTrue);
      expect(config.showLocation, isTrue);
    });

    test('default steps equals LogStep.defaultSteps', () {
      final config = LogConfig();
      expect(config.steps, equals(LogStep.defaultSteps));
    });

    test('custom steps are preserved', () {
      final customSteps = [LogStep.LEVEL, LogStep.MESSAGE];
      final config = LogConfig(steps: customSteps);
      expect(config.steps, equals(customSteps));
    });

    test('can disable individual options', () {
      final config = LogConfig(
        showTimestamp: false,
        showLevel: false,
        showEmoji: false,
      );
      expect(config.showTimestamp, isFalse);
      expect(config.showLevel, isFalse);
      expect(config.showEmoji, isFalse);
      // Others remain default
      expect(config.showTag, isTrue);
      expect(config.showThread, isTrue);
      expect(config.showLocation, isTrue);
    });

    test('all options can be disabled simultaneously', () {
      final config = LogConfig(
        showTimestamp: false,
        showTimeOnly: false,
        showDateOnly: false,
        showLevel: false,
        showTag: false,
        showThread: false,
        useHumanReadableTime: false,
        showEmoji: false,
        showLocation: false,
      );
      expect(config.showTimestamp, isFalse);
      expect(config.showTimeOnly, isFalse);
      expect(config.showDateOnly, isFalse);
      expect(config.showLevel, isFalse);
      expect(config.showTag, isFalse);
      expect(config.showThread, isFalse);
      expect(config.useHumanReadableTime, isFalse);
      expect(config.showEmoji, isFalse);
      expect(config.showLocation, isFalse);
    });

    test('steps list is mutable reference from caller', () {
      final steps = [LogStep.MESSAGE];
      final config = LogConfig(steps: steps);
      steps.add(LogStep.LEVEL);
      // Config holds the same reference
      expect(config.steps.length, 2);
    });
  });
}