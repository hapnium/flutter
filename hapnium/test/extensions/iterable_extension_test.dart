import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('IterableExtension', () {
    test('flatMap flattens and transforms correctly', () {
      final list = [1, 2, 3];
      final result = list.flatMap((e) => [e, e * 2]);
      expect(result, equals([1, 2, 2, 4, 3, 6]));
    });

    test('flatten returns non-null transformed elements', () {
      final list = [1, 2, 3];
      final result = list.flatten((e) => e.isEven ? e * 2 : null);
      expect(result, equals([4]));
    });

    test('all returns true only if all match', () {
      expect([2, 4, 6].all((e) => e.isEven), isTrue);
      expect([2, 3, 6].all((e) => e.isEven), isFalse);
    });

    test('findIndex returns correct index', () {
      expect([1, 2, 3].findIndex((e) => e == 2), equals(1));
      expect([1, 2, 3].findIndex((e) => e == 4), equals(-1));
    });

    test('find returns matching element or null', () {
      expect([1, 2, 3].find((e) => e == 2), equals(2));
      expect([1, 2, 3].find((e) => e == 4), isNull);
    });

    test('length comparison utilities', () {
      final list = [1, 2, 3];
      expect(list.isLengthGt(2), isTrue);
      expect(list.isLengthGtEt(3), isTrue);
      expect(list.isLengthLt(4), isTrue);
      expect(list.isLengthLtEt(3), isTrue);
      expect(list.isLengthEt(3), isTrue);
      expect(list.isLengthBetween(2, 4), isTrue);
    });

    test('none and noneMatch return true only when no match', () {
      expect([1, 2, 3].none((e) => e == 5), isTrue);
      expect([1, 2, 3].none((e) => e == 2), isFalse);
      expect([1, 2, 3].noneMatch((e) => e > 10), isTrue);
    });

    test('stream emits all items', () async {
      final stream = [1, 2, 3].stream();
      final result = await stream.toList();
      expect(result, equals([1, 2, 3]));
    });

    test('indexWhereOrNull returns correct index or null', () {
      expect([1, 2, 3].indexWhereOrNull((e) => e == 2), equals(1));
      expect([1, 2, 3].indexWhereOrNull((e) => e == 5), isNull);
    });

    test('whereType filters elements by type', () {
      final list = [1, 'a', 2, 'b'];
      expect(list.whereType<String>(), equals(['a', 'b']));
    });

    test('whereOrNull returns null if no matches', () {
      expect([1, 2, 3].whereOrNull((e) => e > 5), isNull);
      expect([1, 2, 3].whereOrNull((e) => e > 1), isNotNull);
    });

    test('filterWhere and filter act like where', () {
      final list = [1, 2, 3, 4];
      expect(list.filterWhere((e) => e.isEven), equals([2, 4]));
      expect(list.filter((e) => e.isEven), equals([2, 4]));
    });

    test('group groups by key correctly', () {
      final items = ['apple', 'banana', 'avocado'];
      final grouped = items.group((item) => item[0]);
      expect(grouped['a'], equals(['apple', 'avocado']));
      expect(grouped['b'], equals(['banana']));
    });

    test('groupBy is alias for group', () {
      final items = ['cat', 'car', 'bat'];
      final grouped = items.groupBy((e) => e[0]);
      expect(grouped['c'], equals(['cat', 'car']));
      expect(grouped['b'], equals(['bat']));
    });

    test('groupByAndMap maps values per group', () {
      final data = [
        {'name': 'Alice', 'dept': 'HR'},
        {'name': 'Bob', 'dept': 'Engineering'},
        {'name': 'Carol', 'dept': 'HR'},
      ];
      final grouped = data.groupByAndMap(
        (e) => e['dept'],
        (e) => e['name'],
      );
      expect(grouped['HR'], equals(['Alice', 'Carol']));
      expect(grouped['Engineering'], equals(['Bob']));
    });
  });
}