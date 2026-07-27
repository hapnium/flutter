import 'package:flutter_test/flutter_test.dart';
import 'package:zap/src/enums/zap_provider.dart';
import 'package:zap/src/exceptions/graphql_error.dart';
import 'package:zap/src/http/utils/http_status.dart';
import 'package:zap/src/http/response/graphql_response.dart';
import 'package:zap/src/http/response/response.dart';

void main() {
  Response<dynamic> makeResponse(Map<String, dynamic> body) {
    return Response<Map<String, dynamic>>(
      status: HttpStatus.OK,
      body: body,
      provider: ZapProvider.graphql,
    );
  }

  group('GraphQLResponse', () {
    test('constructor sets graphQLErrors', () {
      final r = GraphQLResponse<String>(
        status: HttpStatus.OK,
        graphQLErrors: [GraphQLError(code: 'ERR', message: 'bad')],
      );
      expect(r.graphQLErrors, hasLength(1));
      expect(r.graphQLErrors!.first.code, 'ERR');
    });

    test('fromResponse extracts data field', () {
      final res = makeResponse({
        'data': {'name': 'John'},
        'errors': null,
      });
      final gql = GraphQLResponse.fromResponse(res);
      expect(gql.body, {'name': 'John'});
      expect(gql.graphQLErrors, isNull);
    });

    test('fromDynamic with errors parses them', () {
      final res = makeResponse({
        'data': null,
        'errors': [
          {
            'message': 'Field not found',
            'extensions': {'code': 'NOT_FOUND'},
          },
        ],
      });
      final gql = GraphQLResponse.fromDynamic(res);
      expect(gql.graphQLErrors, hasLength(1));
      expect(gql.graphQLErrors!.first.message, 'Field not found');
      expect(gql.graphQLErrors!.first.code, 'NOT_FOUND');
    });

    test('fromDynamic without errors extracts data', () {
      final res = makeResponse({
        'data': {'id': 1},
      });
      final gql = GraphQLResponse.fromDynamic(res);
      expect(gql.body, {'id': 1});
      expect(gql.graphQLErrors, isNull);
    });

    test('fromDynamic with empty errors list extracts data', () {
      final res = makeResponse({
        'data': {'id': 1},
        'errors': [],
      });
      final gql = GraphQLResponse.fromDynamic(res);
      expect(gql.body, {'id': 1});
    });

    test('fromException wraps exception as error', () {
      final gql = GraphQLResponse.fromException(Exception('connection failed'));
      expect(gql.status, HttpStatus.CONNECTION_NOT_REACHABLE);
      expect(gql.graphQLErrors, hasLength(1));
      expect(gql.graphQLErrors!.first.message, contains('connection failed'));
      expect(gql.graphQLErrors!.first.code, isNull);
    });

    test('fromDynamic with error missing extensions', () {
      final res = makeResponse({
        'data': null,
        'errors': [
          {'message': 'Simple error'},
        ],
      });
      final gql = GraphQLResponse.fromDynamic(res);
      expect(gql.graphQLErrors!.first.code, '');
    });
  });
}