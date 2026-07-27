import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/http/utils/http_status.dart';

void main() {
  group('HttpStatus enum coverage', () {
    test('CONTINUE', () {
      expect(HttpStatus.CONTINUE.code, 100);
    });

    test('SWITCHING_PROTOCOLS', () {
      expect(HttpStatus.SWITCHING_PROTOCOLS.code, 101);
    });

    test('CREATED', () {
      expect(HttpStatus.CREATED.code, 201);
    });

    test('ACCEPTED', () {
      expect(HttpStatus.ACCEPTED.code, 202);
    });

    test('NO_CONTENT', () {
      expect(HttpStatus.NO_CONTENT.code, 204);
    });

    test('RESET_CONTENT', () {
      expect(HttpStatus.RESET_CONTENT.code, 205);
    });

    test('PARTIAL_CONTENT', () {
      expect(HttpStatus.PARTIAL_CONTENT.code, 206);
    });

    test('MULTI_STATUS', () {
      expect(HttpStatus.MULTI_STATUS.code, 207);
    });

    test('ALREADY_REPORTED', () {
      expect(HttpStatus.ALREADY_REPORTED.code, 208);
    });

    test('IM_USED', () {
      expect(HttpStatus.IM_USED.code, 226);
    });

    test('MULTIPLE_CHOICES', () {
      expect(HttpStatus.MULTIPLE_CHOICES.code, 300);
    });

    test('MOVED_PERMANENTLY', () {
      expect(HttpStatus.MOVED_PERMANENTLY.code, 301);
    });

    test('FOUND', () {
      expect(HttpStatus.FOUND.code, 302);
    });

    test('SEE_OTHER', () {
      expect(HttpStatus.SEE_OTHER.code, 303);
    });

    test('NOT_MODIFIED', () {
      expect(HttpStatus.NOT_MODIFIED.code, 304);
    });

    test('TEMPORARY_REDIRECT', () {
      expect(HttpStatus.TEMPORARY_REDIRECT.code, 307);
    });

    test('PERMANENT_REDIRECT', () {
      expect(HttpStatus.PERMANENT_REDIRECT.code, 308);
    });

    test('PAYMENT_REQUIRED', () {
      expect(HttpStatus.PAYMENT_REQUIRED.code, 402);
    });

    test('METHOD_NOT_ALLOWED', () {
      expect(HttpStatus.METHOD_NOT_ALLOWED.code, 405);
    });

    test('NOT_ACCEPTABLE', () {
      expect(HttpStatus.NOT_ACCEPTABLE.code, 406);
    });

    test('REQUEST_TIMEOUT', () {
      expect(HttpStatus.REQUEST_TIMEOUT.code, 408);
    });

    test('CONFLICT', () {
      expect(HttpStatus.CONFLICT.code, 409);
    });

    test('GONE', () {
      expect(HttpStatus.GONE.code, 410);
    });

    test('LENGTH_REQUIRED', () {
      expect(HttpStatus.LENGTH_REQUIRED.code, 411);
    });

    test('PRECONDITION_FAILED', () {
      expect(HttpStatus.PRECONDITION_FAILED.code, 412);
    });

    test('PAYLOAD_TOO_LARGE', () {
      expect(HttpStatus.PAYLOAD_TOO_LARGE.code, 413);
    });

    test('URI_TOO_LONG', () {
      expect(HttpStatus.URI_TOO_LONG.code, 414);
    });

    test('UNSUPPORTED_MEDIA_TYPE', () {
      expect(HttpStatus.UNSUPPORTED_MEDIA_TYPE.code, 415);
    });

    test('RANGE_NOT_SATISFIABLE', () {
      expect(HttpStatus.RANGE_NOT_SATISFIABLE.code, 416);
    });

    test('EXPECTATION_FAILED', () {
      expect(HttpStatus.EXPECTATION_FAILED.code, 417);
    });

    test('MISDIRECTED_REQUEST', () {
      expect(HttpStatus.MISDIRECTED_REQUEST.code, 421);
    });

    test('UNPROCESSABLE_ENTITY', () {
      expect(HttpStatus.UNPROCESSABLE_ENTITY.code, 422);
    });

    test('LOCKED', () {
      expect(HttpStatus.LOCKED.code, 423);
    });

    test('FAILED_DEPENDENCY', () {
      expect(HttpStatus.FAILED_DEPENDENCY.code, 424);
    });

    test('TOO_EARLY', () {
      expect(HttpStatus.TOO_EARLY.code, 425);
    });

    test('UPGRADE_REQUIRED', () {
      expect(HttpStatus.UPGRADE_REQUIRED.code, 426);
    });

    test('PRECONDITION_REQUIRED', () {
      expect(HttpStatus.PRECONDITION_REQUIRED.code, 428);
    });

    test('TOO_MANY_REQUESTS', () {
      expect(HttpStatus.TOO_MANY_REQUESTS.code, 429);
    });

    test('REQUEST_HEADER_FIELDS_TOO_LARGE', () {
      expect(HttpStatus.REQUEST_HEADER_FIELDS_TOO_LARGE.code, 431);
    });

    test('UNAVAILABLE_FOR_LEGAL_REASONS', () {
      expect(HttpStatus.UNAVAILABLE_FOR_LEGAL_REASONS.code, 451);
    });

    test('NOT_IMPLEMENTED', () {
      expect(HttpStatus.NOT_IMPLEMENTED.code, 501);
    });

    test('BAD_GATEWAY', () {
      expect(HttpStatus.BAD_GATEWAY.code, 502);
    });

    test('SERVICE_UNAVAILABLE', () {
      expect(HttpStatus.SERVICE_UNAVAILABLE.code, 503);
    });

    test('GATEWAY_TIMEOUT', () {
      expect(HttpStatus.GATEWAY_TIMEOUT.code, 504);
    });

    test('HTTP_VERSION_NOT_SUPPORTED', () {
      expect(HttpStatus.HTTP_VERSION_NOT_SUPPORTED.code, 505);
    });

    test('VARIANT_ALSO_NEGOTIATES', () {
      expect(HttpStatus.VARIANT_ALSO_NEGOTIATES.code, 506);
    });

    test('INSUFFICIENT_STORAGE', () {
      expect(HttpStatus.INSUFFICIENT_STORAGE.code, 507);
    });

    test('LOOP_DETECTED', () {
      expect(HttpStatus.LOOP_DETECTED.code, 508);
    });

    test('BANDWIDTH_LIMIT_EXCEEDED', () {
      expect(HttpStatus.BANDWIDTH_LIMIT_EXCEEDED.code, 509);
    });

    test('NOT_EXTENDED', () {
      expect(HttpStatus.NOT_EXTENDED.code, 510);
    });

    test('NETWORK_AUTHENTICATION_REQUIRED', () {
      expect(HttpStatus.NETWORK_AUTHENTICATION_REQUIRED.code, 511);
    });

    test('CONNECTION_NOT_REACHABLE', () {
      expect(HttpStatus.CONNECTION_NOT_REACHABLE.code, 600);
    });

    test('REQUEST_CANCELLED', () {
      expect(HttpStatus.REQUEST_CANCELLED.code, 601);
    });

    test('NETWORK_READ_TIMEOUT_ERROR', () {
      expect(HttpStatus.NETWORK_READ_TIMEOUT_ERROR.code, 598);
    });

    test('NETWORK_CONNECT_TIMEOUT_ERROR', () {
      expect(HttpStatus.NETWORK_CONNECT_TIMEOUT_ERROR.code, 599);
    });

    test('SITE_FROZEN', () {
      expect(HttpStatus.SITE_FROZEN.code, 530);
    });
  });
}