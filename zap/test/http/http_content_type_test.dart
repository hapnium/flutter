import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/http/utils/http_content_type.dart';

void main() {
  group('HttpContentType', () {
    test('constants have correct values', () {
      expect(HttpContentType.APPLICATION_JSON, 'application/json');
      expect(HttpContentType.APPLICATION_XML, 'application/xml');
      expect(HttpContentType.TEXT_PLAIN, 'text/plain');
      expect(HttpContentType.TEXT_HTML, 'text/html');
      expect(HttpContentType.IMAGE_PNG, 'image/png');
      expect(HttpContentType.IMAGE_JPEG, 'image/jpeg');
      expect(HttpContentType.APPLICATION_PDF, 'application/pdf');
      expect(HttpContentType.APPLICATION_OCTET_STREAM, 'application/octet-stream');
      expect(HttpContentType.MULTIPART_FORM_DATA, 'multipart/form-data');
    });

    test('MULTIPART_FORM_DATA_WITH_CHARSET default', () {
      final result = HttpContentType.MULTIPART_FORM_DATA_WITH_CHARSET();
      expect(result, 'multipart/form-data; charset=utf-8');
    });

    test('MULTIPART_FORM_DATA_WITH_CHARSET custom', () {
      final result = HttpContentType.MULTIPART_FORM_DATA_WITH_CHARSET('ascii');
      expect(result, 'multipart/form-data; charset=ascii');
    });

    test('MULTIPARET_FORM_DATA_WITH_BOUNDARY default', () {
      final result = HttpContentType.MULTIPARET_FORM_DATA_WITH_BOUNDARY();
      expect(result, 'multipart/form-data; boundary=----ZapClientBoundary');
    });

    test('MULTIPARET_FORM_DATA_WITH_BOUNDARY custom', () {
      final result = HttpContentType.MULTIPARET_FORM_DATA_WITH_BOUNDARY('my-boundary');
      expect(result, 'multipart/form-data; boundary=my-boundary');
    });

    test('CHARSET_UTF_8 value', () {
      expect(HttpContentType.CHARSET_UTF_8, 'charset=utf-8');
    });

    test('application constants', () {
      expect(HttpContentType.APPLICATION_GRAPHQL, 'application/graphql');
      expect(HttpContentType.APPLICATION_ZIP, 'application/zip');
      expect(HttpContentType.APPLICATION_NDJSON, 'application/x-ndjson');
    });
  });
}