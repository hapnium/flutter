import 'package:test/test.dart';
import 'package:hapnium/hapnium.dart';

import '../models/person.dart';

const isHapniumException = TypeMatcher<HapniumException>();
Matcher throwsHapniumException = throwsA(isHapniumException);

void main() {
  group('Optional Constructor Tests', () {
    test('empty() creates empty Optional', () {
      final empty = Optional.empty<String>();
      expect(empty.isEmpty(), isTrue);
      expect(empty.isPresent(), isFalse);
    });

    test('empty() returns same type for different calls', () {
      final empty1 = Optional.empty<String>();
      final empty2 = Optional.empty<String>();
      expect(empty1, equals(empty2));
    });

    test('of() creates Optional with non-null value', () {
      final optional = Optional.of('test');
      expect(optional.isPresent(), isTrue);
      expect(optional.get(), equals('test'));
    });

    test('of() throws HapniumException for null value', () {
      expect(() => Optional.of(null), throwsHapniumException);
    });

    test('ofNullable() creates Optional with non-null value', () {
      final optional = Optional.ofNullable('test');
      expect(optional.isPresent(), isTrue);
      expect(optional.get(), equals('test'));
    });

    test('ofNullable() creates empty Optional for null value', () {
      final optional = Optional.ofNullable<String>(null);
      expect(optional.isEmpty(), isTrue);
    });

    test('ofNullable() handles different types', () {
      final stringOpt = Optional.ofNullable<String>('hello');
      final intOpt = Optional.ofNullable<int>(42);
      final nullOpt = Optional.ofNullable<double>(null);

      expect(stringOpt.get(), equals('hello'));
      expect(intOpt.get(), equals(42));
      expect(nullOpt.isEmpty(), isTrue);
    });
  });

  group('Value Retrieval Tests', () {
    test('get() returns value when present', () {
      final optional = Optional.of('value');
      expect(optional.get(), equals('value'));
    });

    test('get() throws HapniumException when empty', () {
      final empty = Optional.empty<String>();
      expect(() => empty.get(), throwsHapniumException);
    });

    test('orElse() returns value when present', () {
      final optional = Optional.of('original');
      expect(optional.orElse('default'), equals('original'));
    });

    test('orElse() returns default when empty', () {
      final empty = Optional.empty<String>();
      expect(empty.orElse('default'), equals('default'));
    });

    test('orElse() can return null as default', () {
      final empty = Optional.empty<String>();
      expect(empty.orElse(null), isNull);
    });

    test('orElseGet() returns value when present', () {
      final optional = Optional.of('original');
      var supplierCalled = false;
      final result = optional.orElseGet(() {
        supplierCalled = true;
        return 'generated';
      });
      expect(result, equals('original'));
      expect(supplierCalled, isFalse);
    });

    test('orElseGet() calls supplier when empty', () {
      final empty = Optional.empty<String>();
      var supplierCalled = false;
      final result = empty.orElseGet(() {
        supplierCalled = true;
        return 'generated';
      });
      expect(result, equals('generated'));
      expect(supplierCalled, isTrue);
    });

    test('orElseGet() throws HapniumException for null supplier', () {
      final empty = Optional.empty<String>();
      expect(() => empty.orElseGet(null), throwsHapniumException);
    });

    test('orElseThrow() returns value when present', () {
      final optional = Optional.of('value');
      expect(optional.orElseThrow(), equals('value'));
    });

    test('orElseThrow() throws HapniumException when empty', () {
      final empty = Optional.empty<String>();
      expect(() => empty.orElseThrow(), throwsHapniumException);
    });

    test('orElseThrow() with supplier returns value when present', () {
      final optional = Optional.of('value');
      var supplierCalled = false;
      final result = optional.orElseThrowWith(() {
        supplierCalled = true;
        return HapniumException('Should not be called');
      });
      expect(result, equals('value'));
      expect(supplierCalled, isFalse);
    });

    test('orElseThrow() with supplier throws custom exception when empty', () {
      final empty = Optional.empty<String>();
      expect(
        () => empty.orElseThrowWith(() => HapniumException('Custom error')),
        throwsA(isA<HapniumException>()),
      );
    });

    test('orElseThrow() throws HapniumException for null supplier', () {
      final empty = Optional.empty<String>();
      expect(() => empty.orElseThrow(), throwsHapniumException);
    });
  });

  group('Conditional Operation Tests', () {
    test('isPresent() returns true for non-empty Optional', () {
      final optional = Optional.of('value');
      expect(optional.isPresent(), isTrue);
    });

    test('isPresent() returns false for empty Optional', () {
      final empty = Optional.empty<String>();
      expect(empty.isPresent(), isFalse);
    });

    test('isEmpty() returns false for non-empty Optional', () {
      final optional = Optional.of('value');
      expect(optional.isEmpty(), isFalse);
    });

    test('isEmpty() returns true for empty Optional', () {
      final empty = Optional.empty<String>();
      expect(empty.isEmpty(), isTrue);
    });

    test('ifPresent() executes action when value present', () {
      final optional = Optional.of('test');
      var actionExecuted = false;
      String? capturedValue;

      optional.ifPresent((value) {
        actionExecuted = true;
        capturedValue = value;
      });

      expect(actionExecuted, isTrue);
      expect(capturedValue, equals('test'));
    });

    test('ifPresent() does not execute action when empty', () {
      final empty = Optional.empty<String>();
      var actionExecuted = false;

      empty.ifPresent((value) {
        actionExecuted = true;
      });

      expect(actionExecuted, isFalse);
    });

    test('ifPresent() throws HapniumException for null action', () {
      final optional = Optional.of('test');
      expect(() => optional.ifPresent(null), throwsHapniumException);
    });

    test('ifPresentOrElse() executes action when value present', () {
      final optional = Optional.of('test');
      var actionExecuted = false;
      var emptyActionExecuted = false;
      String? capturedValue;

      optional.ifPresentOrElse(
        (value) {
          actionExecuted = true;
          capturedValue = value;
        },
        () {
          emptyActionExecuted = true;
        },
      );

      expect(actionExecuted, isTrue);
      expect(emptyActionExecuted, isFalse);
      expect(capturedValue, equals('test'));
    });

    test('ifPresentOrElse() executes empty action when empty', () {
      final empty = Optional.empty<String>();
      var actionExecuted = false;
      var emptyActionExecuted = false;

      empty.ifPresentOrElse(
        (value) {
          actionExecuted = true;
        },
        () {
          emptyActionExecuted = true;
        },
      );

      expect(actionExecuted, isFalse);
      expect(emptyActionExecuted, isTrue);
    });

    test('ifPresentOrElse() throws HapniumException for null action', () {
      final optional = Optional.of('test');
      expect(
        () => optional.ifPresentOrElse(null, () {}),
        throwsHapniumException,
      );
    });

    test('ifPresentOrElse() throws HapniumException for null empty action', () {
      final optional = Optional.of('test');
      expect(
        () => optional.ifPresentOrElse((value) {}, null),
        throwsHapniumException,
      );
    });
  });

  group('Transformation Tests', () {
    test('map() transforms value when present', () {
      final optional = Optional.of('hello');
      final result = optional.map((s) => s.toUpperCase());
      expect(result.get(), equals('HELLO'));
    });

    test('map() returns empty when original is empty', () {
      final empty = Optional.empty<String>();
      final result = empty.map((s) => s.toUpperCase());
      expect(result.isEmpty(), isTrue);
    });

    test('map() returns empty when mapper returns null', () {
      final optional = Optional.of('hello');
      final result = optional.map((s) => null);
      expect(result.isEmpty(), isTrue);
    });

    test('map() can change type', () {
      final optional = Optional.of('hello');
      final result = optional.map((s) => s.length);
      expect(result.get(), equals(5));
    });

    test('map() throws HapniumException for null mapper', () {
      final optional = Optional.of('test');
      expect(() => optional.map(null), throwsHapniumException);
    });

    test('map() chains multiple transformations', () {
      final optional = Optional.of('  hello world  ');
      final result = optional
          .map((s) => s.trim())
          .map((s) => s.toUpperCase())
          .map((s) => s.replaceAll(' ', '_'));
      expect(result.get(), equals('HELLO_WORLD'));
    });

    test('flatMap() flattens nested Optional when present', () {
      final optional = Optional.of('123');
      final result = optional.flatMap((s) {
        try {
          return Optional.of(int.parse(s));
        } catch (e) {
          return Optional.empty<int>();
        }
      });
      expect(result.get(), equals(123));
    });

    test('flatMap() returns empty when original is empty', () {
      final empty = Optional.empty<String>();
      final result = empty.flatMap((s) => Optional.of(s.length));
      expect(result.isEmpty(), isTrue);
    });

    test('flatMap() returns empty when mapper returns empty', () {
      final optional = Optional.of('abc');
      expect(() => optional.flatMap((s) => Optional.empty<int>()), throwsHapniumException);
    });

    test('flatMap() throws HapniumException for null mapper', () {
      final optional = Optional.of('test');
      expect(() => optional.flatMap(null), throwsHapniumException);
    });

    test('flatMap() throws HapniumException when mapper returns null', () {
      final optional = Optional.of('test');
      expect(() => optional.flatMap(), throwsHapniumException);
    });

    test('filter() keeps value when predicate is true', () {
      final optional = Optional.of('hello');
      final result = optional.filter((s) => s.length > 3);
      expect(result.get(), equals('hello'));
    });

    test('filter() returns empty when predicate is false', () {
      final optional = Optional.of('hi');
      final result = optional.filter((s) => s.length > 3);
      expect(result.isEmpty(), isTrue);
    });

    test('filter() returns empty when original is empty', () {
      final empty = Optional.empty<String>();
      final result = empty.filter((s) => s.isNotEmpty);
      expect(result.isEmpty(), isTrue);
    });

    test('filter() throws HapniumException for null predicate', () {
      final optional = Optional.of('test');
      expect(() => optional.filter(null), throwsHapniumException);
    });

    test('filter() chains with other operations', () {
      final optional = Optional.of('hello world');
      final result = optional
          .filter((s) => s.contains('world'))
          .map((s) => s.toUpperCase())
          .filter((s) => s.startsWith('HELLO'));
      expect(result.get(), equals('HELLO WORLD'));
    });
  });

  group('Utility Method Tests', () {
    test('or() returns original when present', () {
      final optional = Optional.of('original');
      var supplierCalled = false;
      final result = optional.or(() {
        supplierCalled = true;
        return Optional.of('alternative');
      });
      expect(result.get(), equals('original'));
      expect(supplierCalled, isFalse);
    });

    test('or() returns supplier result when empty', () {
      final empty = Optional.empty<String>();
      var supplierCalled = false;
      final result = empty.or(() {
        supplierCalled = true;
        return Optional.of('alternative');
      });
      expect(result.get(), equals('alternative'));
      expect(supplierCalled, isTrue);
    });

    test('or() throws HapniumException for null supplier', () {
      final empty = Optional.empty<String>();
      expect(() => empty.or(null), throwsHapniumException);
    });

    test('or() throws HapniumException when supplier returns null', () {
      final empty = Optional.empty<String>();
      expect(() => empty.or(), throwsHapniumException);
    });

    test('or() chains multiple alternatives', () {
      final empty = Optional.empty<String>();
      final result = empty.or(() => Optional.of('final'));
      expect(result.get(), equals('final'));
    });

    test('stream() returns single-element iterable when present', () {
      final optional = Optional.of('value');
      final stream = optional.stream();
      expect(stream.toList(), equals(['value']));
    });

    test('stream() returns empty iterable when empty', () {
      final empty = Optional.empty<String>();
      final stream = empty.stream();
      expect(stream.toList(), isEmpty);
    });

    test('stream() works with functional operations', () {
      final optionals = [
        Optional.of('apple'),
        Optional.empty<String>(),
        Optional.of('banana'),
        Optional.of('cherry'),
      ];

      final fruits = optionals
          .expand((opt) => opt.stream())
          .map((fruit) => fruit.toUpperCase())
          .where((fruit) => fruit.startsWith('A'))
          .toList();

      expect(fruits, equals(['APPLE']));
    });
  });

  group('Object Method Tests', () {
    test('equals() returns true for same values', () {
      final opt1 = Optional.of('test');
      final opt2 = Optional.of('test');
      expect(opt1, equals(opt2));
    });

    test('equals() returns false for different values', () {
      final opt1 = Optional.of('test1');
      final opt2 = Optional.of('test2');
      expect(opt1, isNot(equals(opt2)));
    });

    test('equals() returns true for both empty', () {
      final empty1 = Optional.empty<String>();
      final empty2 = Optional.empty<String>();
      expect(empty1, equals(empty2));
    });

    test('equals() returns false for empty vs non-empty', () {
      final optional = Optional.of('test');
      final empty = Optional.empty<String>();
      expect(optional, isNot(equals(empty)));
    });

    test('equals() returns true for identical instances', () {
      final optional = Optional.of('test');
      expect(optional, equals(optional));
    });

    test('equals() returns false for different types', () {
      final optional = Optional.of('test');
      expect(optional, isNot(equals('test')));
      expect(optional, isNot(equals(null)));
    });

    test('equals() works with complex objects', () {
      final list1 = [1, 2, 3];
      final list2 = [1, 2, 3];
      final list3 = [1, 2, 4];

      final opt1 = Optional.of(list1);
      final opt2 = Optional.of(list2);
      final opt3 = Optional.of(list3);

      expect(opt1, equals(opt1));
      expect(opt2, isNot(equals(opt3)));
    });

    test('hashCode() returns value hashCode when present', () {
      final value = 'test';
      final optional = Optional.of(value);
      expect(optional.hashCode, equals(value.hashCode));
    });

    test('hashCode() returns 0 when empty', () {
      final empty = Optional.empty<String>();
      expect(empty.hashCode, equals(0));
    });

    test('hashCode() is consistent with equals()', () {
      final opt1 = Optional.of('test');
      final opt2 = Optional.of('test');
      final empty1 = Optional.empty<String>();
      final empty2 = Optional.empty<String>();

      expect(opt1.hashCode, equals(opt2.hashCode));
      expect(empty1.hashCode, equals(empty2.hashCode));
    });

    test('toString() shows value when present', () {
      final optional = Optional.of('test');
      expect(optional.toString(), equals('Optional[test]'));
    });

    test('toString() shows empty when empty', () {
      final empty = Optional.empty<String>();
      expect(empty.toString(), equals('Optional.empty'));
    });

    test('toString() works with different types', () {
      final intOpt = Optional.of(42);
      final listOpt = Optional.of([1, 2, 3]);
      final nullOpt = Optional.empty<String>();

      expect(intOpt.toString(), equals('Optional[42]'));
      expect(listOpt.toString(), equals('Optional[[1, 2, 3]]'));
      expect(nullOpt.toString(), equals('Optional.empty'));
    });
  });

  group('Error Handling Tests', () {
    test('all methods handle null arguments appropriately', () {
      final optional = Optional.of('test');
      final empty = Optional.empty<String>();

      // Constructor errors
      expect(() => Optional.of(null), throwsHapniumException);

      // Method errors with null arguments
      expect(() => optional.ifPresent(null), throwsHapniumException);
      expect(() => optional.ifPresentOrElse(null, () {}), throwsHapniumException);
      expect(() => optional.ifPresentOrElse((v) {}, null), throwsHapniumException);
      expect(() => optional.filter(null), throwsHapniumException);
      expect(() => optional.map(null), throwsHapniumException);
      expect(() => optional.flatMap(null), throwsHapniumException);
      expect(() => optional.or(null), throwsHapniumException);
      expect(() => empty.orElseGet(null), throwsHapniumException);
      expect(() => empty.orElseThrow(), throwsHapniumException);
    });

    test('flatMap handles null return from mapper', () {
      final optional = Optional.of('test');
      expect(() => optional.flatMap(), throwsHapniumException);
    });

    test('or handles null return from supplier', () {
      final empty = Optional.empty<String>();
      expect(() => empty.or(), throwsHapniumException);
    });

    test('error messages are descriptive', () {
      final empty = Optional.empty<String>();

      try {
        empty.get();
        fail('Should have thrown HapniumException');
      } catch (e) {
        expect(e.toString(), contains('No value present'));
      }

      try {
        empty.orElseThrow();
        fail('Should have thrown HapniumException');
      } catch (e) {
        expect(e.toString(), contains('No value present'));
      }
    });
  });

  group('Edge Cases and Complex Scenarios', () {
    test('nested Optionals work correctly', () {
      final nested = Optional.of(Optional.of('inner'));
      expect(nested.get().get(), equals('inner'));

      final emptyNested = Optional.of(Optional.empty<String>());
      expect(emptyNested.get().isEmpty(), isTrue);
    });

    test('Optional with null-containing collections', () {
      final listWithNull = <String?>[null, 'value', null];
      final optional = Optional.of(listWithNull);
      expect(optional.isPresent(), isTrue);
      expect(optional.get().length, equals(3));
    });

    test('chaining operations with mixed results', () {
      final input = Optional.of('  123  ');
      final result = input
          .map((s) => s.trim())
          .filter((s) => s.isNotEmpty)
          .flatMap((s) {
            try {
              return Optional.of(int.parse(s));
            } catch (e) {
              return Optional.empty<int>();
            }
          })
          .filter((n) => n > 100)
          .map((n) => 'Number: $n');

      expect(result.get(), equals('Number: 123'));
    });

    test('performance with many operations', () {
      var optional = Optional.of('start');
      
      // Chain many operations
      for (int i = 0; i < 100; i++) {
        optional = optional
            .filter((s) => s.isNotEmpty)
            .map((s) => s + i.toString());
      }
      
      expect(optional.isPresent(), isTrue);
      expect(optional.get(), startsWith('start'));
    });

    test('Optional with custom objects', () {
      final person1 = Person('Alice', 25);
      final person2 = Person('Alice', 25);
      final person3 = Person('Bob', 30);

      final opt1 = Optional.of(person1);
      final opt2 = Optional.of(person2);
      final opt3 = Optional.of(person3);

      expect(opt1, equals(opt2)); // Same content
      expect(opt1, isNot(equals(opt3))); // Different content
      expect(opt1.hashCode, equals(opt2.hashCode));
    });

    test('Optional in collections', () {
      final optionals = <Optional<String>>[
        Optional.of('a'),
        Optional.empty(),
        Optional.of('b'),
        Optional.empty(),
        Optional.of('c'),
      ];

      // Count present values
      final presentCount = optionals.where((opt) => opt.isPresent()).length;
      expect(presentCount, equals(3));

      // Extract all present values
      final values = optionals
          .where((opt) => opt.isPresent())
          .map((opt) => opt.get())
          .toList();
      expect(values, equals(['a', 'b', 'c']));

      // Use stream() for functional processing
      final upperValues = optionals
          .expand((opt) => opt.stream())
          .map((s) => s.toUpperCase())
          .toList();
      expect(upperValues, equals(['A', 'B', 'C']));
    });

    test('Optional as Map values', () {
      final map = <String, Optional<String>>{
        'key1': Optional.of('value1'),
        'key2': Optional.empty(),
        'key3': Optional.of('value3'),
      };

      expect(map['key1']!.get(), equals('value1'));
      expect(map['key2']!.isEmpty(), isTrue);
      expect(map['key3']!.get(), equals('value3'));

      // Safe access pattern
      final safeValue = map['key4']?.orElse('default') ?? 'not found';
      expect(safeValue, equals('not found'));
    });

    test('Optional with Future-like patterns', () {
      // Simulate async-like chaining
      Optional<String> processData(String input) {
        if (input.isEmpty) return Optional.empty();
        return Optional.of(input.toUpperCase());
      }

      Optional<int> parseNumber(String input) {
        try {
          return Optional.of(int.parse(input));
        } catch (e) {
          return Optional.empty();
        }
      }

      final result = Optional.of('42')
          .flatMap(processData)
          .flatMap(parseNumber)
          .filter((n) => n > 0)
          .map((n) => n * 2);

      expect(result.get(), equals(84));
    });
  });

  group('Type Safety Tests', () {
    test('maintains type safety across operations', () {
      Optional<String> stringOpt = Optional.of('hello');
      Optional<int> intOpt = stringOpt.map((s) => s.length);
      Optional<bool> boolOpt = intOpt.map((i) => i > 3);
      
      expect(intOpt.get(), equals(5));
      expect(boolOpt.get(), isTrue);
    });

    test('empty() works with different types', () {
      Optional<String> stringEmpty = Optional.empty();
      Optional<int> intEmpty = Optional.empty();
      Optional<List<String>> listEmpty = Optional.empty();
      
      expect(stringEmpty.isEmpty(), isTrue);
      expect(intEmpty.isEmpty(), isTrue);
      expect(listEmpty.isEmpty(), isTrue);
    });

    test('nullable types work correctly', () {
      String? nullableString;
      Optional<String> opt = Optional.ofNullable(nullableString);
      expect(opt.isEmpty(), isTrue);
      
      nullableString = 'not null';
      opt = Optional.ofNullable(nullableString);
      expect(opt.get(), equals('not null'));
    });
  });
}