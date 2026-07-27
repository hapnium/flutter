import 'package:flutter_test/flutter_test.dart';
import 'package:smart/src/core/sx/sx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Sx', () {
    test('holds initial value', () {
      final sx = Sx<int>(42);
      expect(sx.value, 42);
    });

    test('updates value', () {
      final sx = Sx<int>(0);
      sx.value = 10;
      expect(sx.value, 10);
    });

    test('does not notify listeners when value is the same', () {
      final sx = Sx<int>(5);
      var notifyCount = 0;
      sx.listen(() => notifyCount++);
      sx.value = 5;
      expect(notifyCount, 0);
    });

    test('notifies listeners when value changes', () {
      final sx = Sx<int>(0);
      var notified = false;
      sx.listen(() => notified = true);
      sx.value = 1;
      expect(notified, isTrue);
    });

    test('notifies multiple listeners', () {
      final sx = Sx<int>(0);
      var count1 = 0;
      var count2 = 0;
      sx.listen(() => count1++);
      sx.listen(() => count2++);
      sx.value = 1;
      expect(count1, 1);
      expect(count2, 1);
    });

    test('unListen removes listener', () {
      final sx = Sx<int>(0);
      var count = 0;
      void listener() => count++;
      sx.listen(listener);
      sx.value = 1;
      expect(count, 1);
      sx.unListen(listener);
      sx.value = 2;
      expect(count, 1);
    });

    test('ever fires on every change', () {
      final sx = Sx<int>(0);
      final values = <int>[];
      sx.ever((v) => values.add(v));
      sx.value = 1;
      sx.value = 2;
      sx.value = 3;
      expect(values, [1, 2, 3]);
    });

    test('once fires only on first change', () {
      final sx = Sx<int>(0);
      final values = <int>[];
      sx.once((v) => values.add(v));
      sx.value = 1;
      sx.value = 2;
      sx.value = 3;
      expect(values, [1]);
    });

    test('debounce fires after duration', () async {
      final sx = Sx<int>(0);
      final values = <int>[];
      sx.debounce((v) => values.add(v), const Duration(milliseconds: 100));
      sx.value = 1;
      sx.value = 2;
      sx.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(values, [3]);
    });

    test('debounce resets timer on rapid changes', () async {
      final sx = Sx<int>(0);
      final values = <int>[];
      sx.debounce((v) => values.add(v), const Duration(milliseconds: 100));
      sx.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sx.value = 2;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sx.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(values, [3]);
    });

    test('interval limits callback frequency', () async {
      final sx = Sx<int>(0);
      final values = <int>[];
      sx.interval((v) => values.add(v), const Duration(milliseconds: 100));
      sx.value = 1;
      sx.value = 2;
      sx.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(values, [1]);
    });

    test('interval allows callback after duration', () async {
      final sx = Sx<int>(0);
      final values = <int>[];
      sx.interval((v) => values.add(v), const Duration(milliseconds: 100));
      sx.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      sx.value = 2;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(values, [1, 2]);
    });
  });
}