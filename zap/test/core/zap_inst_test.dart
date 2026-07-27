import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/core/zap_inst.dart';

void main() {
  group('ZapImpl', () {
    test('showLog defaults to false', () {
      final zap = ZapImpl();
      expect(zap.showLog, isFalse);
    });

    test('showLog can be set', () {
      final zap = ZapImpl();
      zap.showLog = true;
      expect(zap.showLog, isTrue);
      zap.showLog = false;
      expect(zap.showLog, isFalse);
    });

    test('log does not throw when showLog is false', () {
      final zap = ZapImpl();
      zap.showLog = false;
      zap.log('test message');
      zap.trace('trace');
      zap.debug('debug');
      zap.info('info');
      zap.warn('warn');
      zap.error('error');
      zap.fatal('fatal');
    });

    test('log does not throw when showLog is true', () {
      final zap = ZapImpl();
      zap.showLog = true;
      zap.log('test', mode: LogMode.INFO);
      zap.trace('trace');
      zap.debug('debug');
      zap.info('info');
      zap.warn('warn');
      zap.error('error');
      zap.fatal('fatal');
      zap.showLog = false;
    });

    test('convenience methods accept parameters', () {
      final zap = ZapImpl();
      zap.showLog = true;
      zap.info('msg', prefix: 'tag', from: 'cls');
      zap.debug('msg', prefix: 'tag', from: 'cls');
      zap.warn('msg', prefix: 'tag', from: 'cls');
      zap.error('msg', prefix: 'tag', from: 'cls');
      zap.fatal('msg', prefix: 'tag', from: 'cls');
      zap.trace('msg', prefix: 'tag', from: 'cls');
      zap.showLog = false;
    });
  });

  group('LogMode enum', () {
    test('has all values', () {
      expect(LogMode.values, hasLength(6));
      expect(LogMode.values, contains(LogMode.TRACE));
      expect(LogMode.values, contains(LogMode.DEBUG));
      expect(LogMode.values, contains(LogMode.INFO));
      expect(LogMode.values, contains(LogMode.WARN));
      expect(LogMode.values, contains(LogMode.ERROR));
      expect(LogMode.values, contains(LogMode.FATAL));
    });
  });
}