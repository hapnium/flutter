import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('ListExtensions', () {
    test('isOneAKind returns true when all values are the same', () {
      expect([1, 1, 1].isOneAKind, isTrue);
      expect(['a', 'a', 'a'].isOneAKind, isTrue);
    });

    test('isOneAKind returns false for empty or mixed lists', () {
      expect(<int>[].isOneAKind, isFalse);
      expect([1, 2, 1].isOneAKind, isFalse);
    });

    test('addIf adds element if condition matches', () {
      final list = [1, 2, 3];
      list.addIf((e) => e == 2, 4);
      expect(list.contains(4), isTrue);
    });

    test('addIf does not add element if no condition matches', () {
      final list = [1, 2, 3];
      final initialLength = list.length;
      list.addIf((e) => e == 10, 5);
      expect(list.length, equals(initialLength));
    });

    test('addAllIf adds elements if all satisfy condition', () {
      final list = [2, 4];
      list.addAllIf((e) => e.isEven, [6, 8]);
      expect(list, containsAll([2, 4, 6, 8]));
    });

    test('addAllIf does not add if condition fails', () {
      final list = [2, 3];
      list.addAllIf((e) => e.isEven, [6, 8]);
      expect(list, equals([2, 3]));
    });

    test('removeIf removes element if condition matches', () {
      final list = [1, 2, 3, 2];
      list.removeIf((e) => e == 2, 2);
      expect(list.where((e) => e == 2).length, lessThan(2));
    });

    test('removeAllIf removes elements only if all match condition', () {
      final list = [2, 4, 6, 7];
      list.removeAllIf((e) => e != 7, [4, 6]);
      expect(list, containsAll([2, 4, 6, 7])); // should not remove, not all pass
      final list2 = [2, 4, 6];
      list2.removeAllIf((e) => e.isEven, [4, 6]);
      expect(list2, equals([2]));
    });

    test('firstWhereOrNull returns first match or null', () {
      final list = [1, 2, 3, 2];
      expect(list.firstWhereOrNull((e) => e == 2), equals(2));
      expect(list.firstWhereOrNull((e) => e == 5), isNull);
    });

    test('lastWhereOrNull returns last match or null', () {
      final list = [1, 2, 3, 2];
      expect(list.lastWhereOrNull((e) => e == 2), equals(2));
      expect(list.lastWhereOrNull((e) => e == 5), isNull);
    });

    test('shift removes and returns the first element', () {
      final list = [1, 2, 3];
      final first = list.shift();
      expect(first, equals(1));
      expect(list, equals([2, 3]));
    });

    test('shift returns null on empty list', () {
      final list = <int>[];
      expect(list.shift(), isNull);
    });

    test('pop removes and returns the last element', () {
      final list = [1, 2, 3];
      final last = list.pop();
      expect(last, equals(3));
      expect(list, equals([1, 2]));
    });

    test('pop returns null on empty list', () {
      final list = <int>[];
      expect(list.pop(), isNull);
    });

    test('reverse returns a new list with the elements in reverse order', () {
      final list = [1, 2, 3, 4, 5];
      final reversed = list.reverse();
      expect(reversed, equals([5, 4, 3, 2, 1]));
      expect(list, equals([1, 2, 3, 4, 5]));
    });
  });
}