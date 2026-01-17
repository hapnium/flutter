import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:hapnium/hapnium.dart';

void main() {
  group('Instance', () {
    group('of<T>', () {
      test('should return true when value is of type T', () {
        expect(Instance.of<String>("Hello"), isTrue);
        expect(Instance.of<int>(42), isTrue);
        expect(Instance.of<double>(3.14), isTrue);
        expect(Instance.of<bool>(true), isTrue);
        expect(Instance.of<List<int>>([1, 2, 3]), isTrue);
        expect(Instance.of<Map<String, dynamic>>({"key": "value"}), isTrue);
      });

      test('should return true when value is of type T', () {
        expect(Instance.isType("Hello", String), isTrue);
        expect(Instance.isType(42, int), isTrue);
        expect(Instance.isType(3.14, double), isTrue);
        expect(Instance.isType(true, Map), isFalse);
        expect(Instance.isType([1, 2, 3], List<int>), isTrue);
        expect(Instance.isType({"key": "value"}, Map<String, String>), isTrue);
      });

      test('should return false when value is not of type T', () {
        expect(Instance.of<String>(42), isFalse);
        expect(Instance.of<int>(3.14), isFalse);
        expect(Instance.of<double>("Hello"), isFalse);
        expect(Instance.of<bool>(1), isFalse);
        expect(Instance.of<List<int>>([1, "2", 3]), isFalse); // Mixed list
        expect(Instance.of<Map<String, dynamic>>(123), isFalse); // Mixed map
      });

      test('should handle null values correctly', () {
        expect(Instance.of<String>(null), isFalse); // null is not a String
        expect(Instance.of<int>(null), isFalse);
      });
    });

    group('isNumeric', () {
      test('should return true for int and double', () {
        expect(Instance.isNumeric(42), isTrue);
        expect(Instance.isNumeric(3.14), isTrue);
      });

      test('should return false for other types', () {
        expect(Instance.isNumeric("Hello"), isFalse);
        expect(Instance.isNumeric(true), isFalse);
        expect(Instance.isNumeric([1, 2, 3]), isFalse);
        expect(Instance.isNumeric({"key": "value"}), isFalse);
      });
    });

    group('isList', () {
      test('should return true for lists', () {
        expect(Instance.isList([1, 2, 3]), isTrue);
        expect(Instance.isList([]), isTrue); // Empty list
      });

      test('should return false for other types', () {
        expect(Instance.isList("Hello"), isFalse);
        expect(Instance.isList(42), isFalse);
        expect(Instance.isList({"key": "value"}), isFalse);
      });
    });

    group('isMap', () {
      test('should return true for maps', () {
        expect(Instance.isMap({"key": "value"}), isTrue);
        expect(Instance.isMap({}), isTrue); // Empty map
      });

      test('should return false for other types', () {
        expect(Instance.isMap("Hello"), isFalse);
        expect(Instance.isMap(42), isFalse);
        expect(Instance.isMap([1, 2, 3]), isFalse);
      });
    });

    group('ambiguate', () {
      test('should return the value as T?', () {
        String? nullableString = "Hello";
        String? result = Instance.ambiguate<String>(nullableString);
        expect(result, "Hello");

        int? nullableInt;
        int? resultInt = Instance.ambiguate<int>(nullableInt);
        expect(resultInt, null);
      });
    });

    group('nullable', () {
      test('should return true for null values', () {
        expect(Instance.nullable<String>(null), isTrue);
        expect(Instance.nullable<int>(null), isTrue);
      });

      test('should return false for non-null values', () {
        expect(Instance.nullable<String>("Hello"), isFalse);
        expect(Instance.nullable<int>(42), isFalse);
      });
    });
  });
  group('valueOf', () {
    test('should convert various types to strings', () {
      expect(Instance.valueOf(100), '100');
      expect(Instance.valueOf(3.14), '3.14');
      expect(Instance.valueOf(true), 'true');
      expect(Instance.valueOf(false), 'false');
      expect(Instance.valueOf([1, 2, 3]), '[1, 2, 3]');
      expect(Instance.valueOf({'a': 1, 'b': 2}), '{a: 1, b: 2}');
      expect(Instance.valueOf(null), 'null');
    });
  });

  group('toBoolean', () {
    test('should convert strings to booleans', () {
      expect(Instance.toBoolean("true"), isTrue);
      expect(Instance.toBoolean("TRUE"), isTrue); // Case-insensitive
      expect(Instance.toBoolean("  true  "), isTrue); // Trimmed
      expect(Instance.toBoolean("false"), isFalse);
      expect(Instance.toBoolean("FALSE"), isFalse); // Case-insensitive
      expect(Instance.toBoolean("  false  "), isFalse); // Trimmed
      expect(Instance.toBoolean("anything else"), isFalse); // Invalid string
    });

    test('should convert integers to booleans', () {
      expect(Instance.toBoolean(1), isTrue);
      expect(Instance.toBoolean(0), isFalse);
      expect(Instance.toBoolean(-1), isFalse); // Anything other than 1 is false
      expect(Instance.toBoolean(2), isFalse);
    });

    test('should return the boolean value itself', () {
      expect(Instance.toBoolean(true), isTrue);
      expect(Instance.toBoolean(false), isFalse);
    });

    test('should return false for other types', () {
      expect(Instance.toBoolean(3.14), isFalse);
      expect(Instance.toBoolean([1, 2, 3]), isFalse);
      expect(Instance.toBoolean({'a': 1}), isFalse);
    });

    test('should handle null values', () {
      expect(Instance.toBoolean(null), isFalse);
    });
  });
}