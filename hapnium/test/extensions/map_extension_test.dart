import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('MapExtensions', () {
    test('asJson formats keys to snake_case by default', () {
      final map = {'firstName': 'John', 'lastName': 'Doe'};
      final result = map.asJson();
      expect(result, equals({'first_name': 'John', 'last_name': 'Doe'}));
    });

    test('asJson formats keys to kebab-case with delimiter "-"', () {
      final map = {'firstName': 'John', 'lastName': 'Doe'};
      final result = map.asJson(delimiter: '-');
      expect(result, equals({'first-name': 'John', 'last-name': 'Doe'}));
    });

    test('asJson keeps key as is for unknown delimiter', () {
      final map = {'firstName': 'John'};
      final result = map.asJson(delimiter: '|');
      expect(result, equals({'firstName': 'John'}));
    });

    test('formatKeys formats camelCase to snake_case and kebab-case', () {
      expect(MapExtensions.formatKeys('firstName', '_'), equals('first_name'));
      expect(MapExtensions.formatKeys('firstName', '-'), equals('first-name'));
      expect(MapExtensions.formatKeys('firstName', '|'), equals('firstName'));
    });

    test('merge overrides existing keys', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'b': 3, 'c': 4};
      final result = map1.merge(map2);
      expect(result, equals({'a': 1, 'b': 3, 'c': 4}));
    });

    test('mapKeys transforms keys correctly', () {
      final map = {'one': 1, 'two': 2};
      final result = map.mapKeys((key) => key.toUpperCase());
      expect(result, equals({'ONE': 1, 'TWO': 2}));
    });

    test('add inserts new key or updates with new value if different', () {
      final map = {'a': 1};
      map.add('b', 2);
      map.add('a', 3);
      expect(map, equals({'a': 3, 'b': 2}));
    });

    test('add does not update if value is the same (notEquals false)', () {
      final map = {'a': 1};
      map.add('a', 1); // Should not change
      expect(map, equals({'a': 1}));
    });
  });
}