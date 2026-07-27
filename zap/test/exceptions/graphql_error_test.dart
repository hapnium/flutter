import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/exceptions/graphql_error.dart';

void main() {
  group('GraphQLError', () {
    test('constructor with code and message', () {
      final e = GraphQLError(code: 'NOT_FOUND', message: 'User not found');
      expect(e.code, 'NOT_FOUND');
      expect(e.message, 'User not found');
    });

    test('constructor with null fields', () {
      final e = GraphQLError();
      expect(e.code, isNull);
      expect(e.message, isNull);
    });

    test('toString format', () {
      final e = GraphQLError(code: 'AUTH', message: 'expired');
      final str = e.toString();
      expect(str, contains('ZAP [GraphQLError]'));
      expect(str, contains('code:AUTH'));
      expect(str, contains('message:expired'));
    });

    test('toString with null fields', () {
      final e = GraphQLError();
      final str = e.toString();
      expect(str, contains('code:null'));
      expect(str, contains('message:null'));
    });
  });
}