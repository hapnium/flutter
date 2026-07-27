import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';

void main() {
  group('ChimeSound', () {
    test('CONNECT returns correct key', () {
      expect(ChimeSound.CONNECT.getKey(), 'connect');
    });

    test('INCOMING returns correct key', () {
      expect(ChimeSound.INCOMING.getKey(), 'incoming');
    });

    test('MESSAGE returns correct key', () {
      expect(ChimeSound.MESSAGE.getKey(), 'message');
    });

    test('NOTIFY returns correct key', () {
      expect(ChimeSound.NOTIFY.getKey(), 'notify');
    });

    test('SCHEDULE returns correct key', () {
      expect(ChimeSound.SCHEDULE.getKey(), 'schedule');
    });

    test('CUSTOM returns custom key', () {
      final sound = ChimeSound.CUSTOM('doorbell');
      expect(sound.getKey(), 'doorbell');
    });

    test('CUSTOM with empty string', () {
      final sound = ChimeSound.CUSTOM('');
      expect(sound.getKey(), '');
    });

    test('all constants are ChimeSound instances', () {
      expect(ChimeSound.CONNECT, isA<ChimeSound>());
      expect(ChimeSound.INCOMING, isA<ChimeSound>());
      expect(ChimeSound.MESSAGE, isA<ChimeSound>());
      expect(ChimeSound.NOTIFY, isA<ChimeSound>());
      expect(ChimeSound.SCHEDULE, isA<ChimeSound>());
    });

    test('different constants have different keys', () {
      final keys = {
        ChimeSound.CONNECT.getKey(),
        ChimeSound.INCOMING.getKey(),
        ChimeSound.MESSAGE.getKey(),
        ChimeSound.NOTIFY.getKey(),
        ChimeSound.SCHEDULE.getKey(),
      };
      expect(keys.length, 5);
    });

    test('CUSTOM creates new instance each time', () {
      final s1 = ChimeSound.CUSTOM('a');
      final s2 = ChimeSound.CUSTOM('a');
      expect(s1.getKey(), s2.getKey());
    });
  });
}