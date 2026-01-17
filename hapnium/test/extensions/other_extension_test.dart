import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:hapnium/hapnium.dart';

import '../models/test_data.dart';

void main() {
  group('DateTimeExtensions', () {
    test('equals returns true for same date', () {
      final date1 = DateTime(2023, 5, 17);
      final date2 = DateTime(2023, 5, 17);
      expect(date1.equals(date2), isTrue);
    });

    test('equals returns false for different date', () {
      final date1 = DateTime(2023, 5, 17);
      final date2 = DateTime(2023, 6, 18);
      expect(date1.equals(date2), isFalse);
    });
  });

  group('DurationExtension', () {
    test('asTime returns MM:SS if less than an hour', () {
      final duration = Duration(minutes: 5, seconds: 7);
      expect(duration.asTime, '05:07');
    });

    test('asTime returns HH:MM:SS if more than an hour', () {
      final duration = Duration(hours: 1, minutes: 4, seconds: 9);
      expect(duration.asTime, '1:04:09');
    });
  });

  group('DynamicExtensions', () {
    test('isNotNull returns true for non-null', () {
      expect('hello'.isNotNull, isTrue);
    });

    test('isNull returns true for null', () {
      TestData? value;
      expect(value.isNull, isTrue);
    });

    test('isNullOrBlank returns true for null', () {
      TestData? value;
      expect(value.isNullOrBlank(), isTrue);
    });

    test('isNullOrBlank returns true for empty string', () {
      expect(''.isNullOrBlank(), isTrue);
    });

    test('isNullOrBlank returns false for non-empty string', () {
      expect('data'.isNullOrBlank(), isFalse);
    });

    test('isBlank returns true for whitespace string', () {
      expect('   '.isBlank(), isTrue);
    });

    test('isBlank returns false for non-empty string', () {
      expect('test'.isBlank(), isFalse);
    });
  });

  group('TExtensions', () {
    test('equals returns true when values match', () {
      String? value = 'test';
      expect(value.equals('test'), isTrue);
    });

    test('notEquals returns true when values differ', () {
      int? value = 5;
      expect(value.notEquals(10), isTrue);
    });

    test('instanceOf returns true for correct type', () {
      int value = 10;
      expect(value.instanceOf<int>(), isTrue);
    });

    test('orElse returns fallback when null', () {
      String? value;
      expect(value.orElse('fallback'), equals('fallback'));
    });

    test('let executes action and returns result if not null', () {
      String? value = 'hi';
      final result = value.let((v) => v.toUpperCase());
      expect(result, 'HI');
    });

    test('also runs action and returns self', () {
      String? value = 'run';
      String? result = value.also((v) => expect(v, equals('run')));
      expect(result, equals('run'));
    });

    test('getOrThrow throws when null', () {
      String? value;
      expect(() => value.getOrThrow('missing'), throwsA(isA<Exception>()));
    });

    test('getOrThrow returns value when not null', () {
      String? value = 'ok';
      expect(value.getOrThrow(), equals('ok'));
    });
  });

  group('TypeExtension', () {
    TestData? testData = TestData(name: 'test', age: 10);

    test('equals returns true for same type', () {
      expect(testData == testData, isTrue);
      expect(testData.equals(testData), isTrue);
    });

    test('isNotNull returns true for non-null', () {
      expect(testData.isNotNull, isTrue);
    });

    test('instanceOf returns true for correct type', () {
      expect(testData.instanceOf<TestData>(), isTrue);
    });

    test('isBool returns true for Bool type', () {
      expect(testData.getOrThrow(), testData);
    });
  });
}