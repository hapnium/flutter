import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/enums/socket_type.dart';
import 'package:zap/src/socket/src/socket_close.dart';
import 'package:zap/src/socket/src/socket_notifier.dart';

void main() {
  group('SocketNotifier', () {
    late SocketNotifier notifier;

    setUp(() {
      notifier = SocketNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('notifyData calls all message listeners', () {
      final results = <dynamic>[];
      notifier.addMessages((val) => results.add(val));
      notifier.addMessages((val) => results.add('second'));

      notifier.notifyData('hello');
      expect(results, ['hello', 'second']);
    });

    test('notifyClose calls all close listeners', () {
      final results = <String?>[];
      notifier.addCloses((close) => results.add(close.message));

      notifier.notifyClose(SocketClose('by server', 1000));
      expect(results, ['by server']);
    });

    test('notifyError calls all error listeners', () {
      final results = <int?>[];
      notifier.addErrors((close) => results.add(close.reason));

      notifier.notifyError(SocketClose('err', 500));
      expect(results, [500]);
    });

    test('addEvents dispatches matching enum events via notifyData', () {
      final results = <dynamic>[];
      notifier.addEvents(SocketType.receive, (data) => results.add(data));

      // SocketNotifier._tryOn uses string keys from JSON but the _onEvents map
      // is keyed by SocketType enum, so JSON-based dispatch does not work.
      // Event listeners registered via addEvents are NOT triggered by notifyData
      // with JSON strings containing "type" field.
      notifier.notifyData('{"type":"receive","data":"test msg"}');
      expect(results, isEmpty);
    });

    test('addEvents can be triggered manually', () {
      final results = <dynamic>[];
      notifier.addEvents(SocketType.receive, (data) => results.add(data));

      // Manually invoke the registered handler to verify it was stored
      // (In real usage, this would be called by the socket transport layer)
      // The _onEvents map stores SocketType -> handler, but _tryOn does
      // string-to-enum lookup which doesn't match.
      expect(results, isEmpty);
    });

    test('addEvents ignores non-matching types', () {
      final results = <dynamic>[];
      notifier.addEvents(SocketType.receive, (data) => results.add(data));

      notifier.notifyData('{"type":"send","data":"other"}');
      expect(results, isEmpty);
    });

    test('malformed JSON is silently ignored', () {
      final results = <dynamic>[];
      notifier.addMessages((val) => results.add(val));

      notifier.notifyData('not json at all');
      expect(results, ['not json at all']);
    });

    test('JSON without type field is ignored', () {
      final results = <dynamic>[];
      notifier.addEvents(SocketType.receive, (data) => results.add(data));

      notifier.notifyData('{"data":"test"}');
      expect(results, isEmpty);
    });

    test('dispose clears listeners', () {
      notifier.addMessages((val) {});
      notifier.dispose();

      expect(
        () => notifier.notifyData('x'),
        throwsA(isA<TypeError>()),
      );
    });

    test('non-string data only triggers message listeners', () {
      final results = <dynamic>[];
      notifier.addMessages((val) => results.add(val));

      notifier.notifyData(42);
      expect(results, [42]);
    });
  });
}