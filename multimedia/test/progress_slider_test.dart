import 'package:flutter_test/flutter_test.dart';
import 'package:multimedia/multimedia.dart';

void main() {
  group('ThumbDragDetails', () {
    test('creates instance with default values', () {
      const details = ThumbDragDetails();

      expect(details.timeStamp, equals(Duration.zero));
      expect(details.globalPosition, equals(Offset.zero));
      expect(details.localPosition, equals(Offset.zero));
    });

    test('creates instance with custom values', () {
      const details = ThumbDragDetails(
        timeStamp: Duration(seconds: 30),
        globalPosition: Offset(100, 200),
        localPosition: Offset(50, 75),
      );

      expect(details.timeStamp, equals(const Duration(seconds: 30)));
      expect(details.globalPosition, equals(const Offset(100, 200)));
      expect(details.localPosition, equals(const Offset(50, 75)));
    });

    test('toString includes all fields', () {
      const details = ThumbDragDetails(
        timeStamp: Duration(seconds: 10),
        globalPosition: Offset(100, 200),
        localPosition: Offset(50, 75),
      );

      final str = details.toString();

      expect(str, contains('ThumbDragDetails'));
      expect(str, contains('10'));
      expect(str, contains('100.0'));
      expect(str, contains('200.0'));
      expect(str, contains('50.0'));
      expect(str, contains('75.0'));
    });

    test('equality works correctly', () {
      const details1 = ThumbDragDetails(
        timeStamp: Duration(seconds: 5),
        globalPosition: Offset(10, 20),
        localPosition: Offset(5, 10),
      );
      const details2 = ThumbDragDetails(
        timeStamp: Duration(seconds: 5),
        globalPosition: Offset(10, 20),
        localPosition: Offset(5, 10),
      );
      const details3 = ThumbDragDetails(
        timeStamp: Duration(seconds: 10),
        globalPosition: Offset(10, 20),
        localPosition: Offset(5, 10),
      );

      expect(details1, equals(details2));
      expect(details1, isNot(equals(details3)));
    });
  });

  group('BarCapShape', () {
    test('has round value', () {
      expect(BarCapShape.round, equals(BarCapShape.round));
    });

    test('has square value', () {
      expect(BarCapShape.square, equals(BarCapShape.square));
    });

    test('has exactly two values', () {
      expect(BarCapShape.values.length, equals(2));
    });

    test('values contain round and square', () {
      expect(BarCapShape.values, contains(BarCapShape.round));
      expect(BarCapShape.values, contains(BarCapShape.square));
    });
  });

  group('TimeLabelLocation', () {
    test('has above value', () {
      expect(TimeLabelLocation.above, equals(TimeLabelLocation.above));
    });

    test('has below value', () {
      expect(TimeLabelLocation.below, equals(TimeLabelLocation.below));
    });

    test('has sides value', () {
      expect(TimeLabelLocation.sides, equals(TimeLabelLocation.sides));
    });

    test('has none value', () {
      expect(TimeLabelLocation.none, equals(TimeLabelLocation.none));
    });

    test('has exactly four values', () {
      expect(TimeLabelLocation.values.length, equals(4));
    });

    test('values contain all expected entries', () {
      expect(TimeLabelLocation.values, contains(TimeLabelLocation.above));
      expect(TimeLabelLocation.values, contains(TimeLabelLocation.below));
      expect(TimeLabelLocation.values, contains(TimeLabelLocation.sides));
      expect(TimeLabelLocation.values, contains(TimeLabelLocation.none));
    });
  });

  group('TimeLabelType', () {
    test('has totalTime value', () {
      expect(TimeLabelType.totalTime, equals(TimeLabelType.totalTime));
    });

    test('has remainingTime value', () {
      expect(TimeLabelType.remainingTime, equals(TimeLabelType.remainingTime));
    });

    test('has exactly two values', () {
      expect(TimeLabelType.values.length, equals(2));
    });

    test('values contain both entries', () {
      expect(TimeLabelType.values, contains(TimeLabelType.totalTime));
      expect(TimeLabelType.values, contains(TimeLabelType.remainingTime));
    });
  });
}