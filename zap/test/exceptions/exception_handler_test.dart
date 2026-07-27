import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/enums/exception_type.dart';
import 'package:zap/src/exceptions/controller_advice.dart';
import 'package:zap/src/exceptions/zap_exception.dart';

void main() {
  group('ExceptionHandler', () {
    test('type-specific handler is called', () {
      final handled = <ExceptionType>[];
      final handler = ExceptionHandler();
      handler.registerHandler(ExceptionType.network, (e) {
        handled.add(e.type);
      });

      handler.handle(ZapException.network('no internet'));
      expect(handled, [ExceptionType.network]);
    });

    test('default handler is called for unregistered types', () {
      String? lastMessage;
      final handler = ExceptionHandler(
        defaultHandler: (e) => lastMessage = e.message,
      );

      handler.handle(ZapException.parsing('bad json'));
      expect(lastMessage, 'bad json');
    });

    test('type-specific takes precedence over default', () {
      String? fromSpecific;
      String? fromDefault;
      final handler = ExceptionHandler(
        defaultHandler: (e) => fromDefault = e.message,
      );

      handler.registerHandler(ExceptionType.timeout, (e) {
        fromSpecific = e.message;
      });

      handler.handle(ZapException.timeout('timed out'));
      expect(fromSpecific, 'timed out');
      expect(fromDefault, isNull);
    });

    test('no handler and no default silently ignores', () {
      final handler = ExceptionHandler();
      handler.handle(ZapException('unhandled'));
    });

    test('registerHandlers bulk registers', () {
      final results = <String>[];
      final handler = ExceptionHandler();
      handler.registerHandlers({
        ExceptionType.network: (e) => results.add('network'),
        ExceptionType.auth: (e) => results.add('auth'),
      });

      handler.handle(ZapException.network('n'));
      handler.handle(ZapException.auth('a'));
      expect(results, ['network', 'auth']);
    });

    test('overwriting handler replaces old one', () {
      final results = <String>[];
      final handler = ExceptionHandler();
      handler.registerHandler(ExceptionType.network, (e) => results.add('first'));
      handler.registerHandler(ExceptionType.network, (e) => results.add('second'));

      handler.handle(ZapException.network('n'));
      expect(results, ['second']);
    });
  });

  group('ControllerAdvice', () {
    test('registers type-specific handlers', () {
      final results = <String>[];
      final advice = ControllerAdvice(
        onTimeout: (e) => results.add('timeout'),
        onNetwork: (e) => results.add('network'),
        onServer: (e) => results.add('server'),
        onClient: (e) => results.add('client'),
        onAuth: (e) => results.add('auth'),
        onSSL: (e) => results.add('ssl'),
        onConnection: (e) => results.add('connection'),
        onDNS: (e) => results.add('dns'),
        onParsing: (e) => results.add('parsing'),
        onCancelled: (e) => results.add('cancelled'),
        enableLogging: false,
      );

      advice.handler.handle(ZapException.timeout('t'));
      advice.handler.handle(ZapException.network('n'));
      advice.handler.handle(ZapException.server('s', 500));
      advice.handler.handle(ZapException.client('c', 400));
      advice.handler.handle(ZapException.auth('a'));
      advice.handler.handle(ZapException.ssl('s'));
      advice.handler.handle(ZapException.connection('c'));
      advice.handler.handle(ZapException.dns('d'));
      advice.handler.handle(ZapException.parsing('p'));
      advice.handler.handle(ZapException.cancelled('x'));

      expect(results, containsAll([
        'timeout', 'network', 'server', 'client', 'auth',
        'ssl', 'connection', 'dns', 'parsing', 'cancelled',
      ]));
    });

    test('onUnknown acts as default handler', () {
      String? msg;
      final advice = ControllerAdvice(
        onUnknown: (e) => msg = e.message,
        enableLogging: false,
      );

      advice.handler.handle(ZapException('something'));
      expect(msg, 'something');
    });

    test('onException delegates to handler', () {
      String? msg;
      final advice = ControllerAdvice(
        onTimeout: (e) => msg = e.message,
        enableLogging: false,
      );

      advice.onException(ZapException.timeout('t'));
      expect(msg, 't');
    });

    test('logging enabled does not throw for unhandled', () {
      final advice = ControllerAdvice(enableLogging: true);
      advice.handler.handle(ZapException('unhandled'));
    });

    test('logging disabled silently ignores', () {
      final advice = ControllerAdvice(enableLogging: false);
      advice.handler.handle(ZapException('unhandled'));
    });
  });
}