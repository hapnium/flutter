
import '../../enums/zap_provider.dart';
import '../../exceptions/graphql_error.dart';
import '../utils/http_status.dart';
import 'response.dart';

/// {@template graphql_response}
/// A response object specifically for GraphQL operations.
///
/// Includes both the successful data payload and any GraphQL errors returned.
/// This class extends [Response] to provide GraphQL-specific error handling
/// and response parsing.
///
/// ## Features
/// - Automatic parsing of GraphQL errors from response body
/// - Error extraction with code and message
/// - Factory constructors for common scenarios (from Response, from exception)
/// - Provider set to [ZapProvider.graphql]
///
/// ## Example
/// ```dart
/// final response = await client.post(
///   '/graphql',
///   body: {
///     'query': '{ hello }',
///   },
/// );
/// final graphqlResponse = GraphQLResponse.fromDynamic(response);
/// if (graphqlResponse.graphQLErrors != null) {
///   print('Errors: ${graphqlResponse.graphQLErrors}');
/// }
/// ```
/// 
/// {@endtemplate}
class GraphQLResponse<T> extends Response<T> {
  /// List of GraphQL errors returned by the server.
  ///
  /// This is `null` if the response was successful with no errors.
  /// Each error contains a [GraphQLError] with code and message.
  ///
  /// ## Example
  /// ```dart
  /// if (response.graphQLErrors != null) {
  ///   for (final error in response.graphQLErrors!) {
  ///     print('Error: ${error.message} (${error.code})');
  ///   }
  /// }
  /// ```
  final List<GraphQLError>? graphQLErrors;

  /// Creates a [GraphQLResponse] with the given parameters.
  ///
  /// ## Parameters
  /// - [status]: The HTTP status code.
  /// - [body]: The response body.
  /// - [graphQLErrors]: Optional list of GraphQL errors.
  /// - [provider]: The provider type (defaults to [ZapProvider.graphql]).
  ///
  /// {@macro graphql_response}
  GraphQLResponse({required super.status, super.body, this.graphQLErrors, super.provider = ZapProvider.graphql});

  /// Constructs a [GraphQLResponse] from a standard [Response],
  /// extracting the GraphQL `data` field as the response body.
  ///
  /// ## Parameters
  /// - [res]: The standard response to convert.
  ///
  /// ## Example
  /// ```dart
  /// final standardResponse = await client.post('/graphql', body: query);
  /// final graphqlResponse = GraphQLResponse.fromResponse(standardResponse);
  /// ```
  /// 
  /// {@macro graphql_response}
  GraphQLResponse.fromResponse(Response res) : graphQLErrors = null, super(
    request: res.request,
    status: res.status,
    message: res.message,
    bodyBytes: res.bodyBytes,
    bodyString: res.bodyString,
    headers: res.headers,
    body: res.body['data'] as T?,
    provider: ZapProvider.graphql,
  );

  /// Constructs a [GraphQLResponse] from a dynamic response body.
  ///
  /// This factory constructor parses the response body for GraphQL errors.
  /// If errors are present, they are extracted and returned in [graphQLErrors].
  /// Otherwise, the `data` field is used as the response body.
  ///
  /// ## Parameters
  /// - [res]: The response containing a GraphQL response body.
  ///
  /// ## Example
  /// ```dart
  /// final response = await client.post('/graphql', body: query);
  /// final graphqlResponse = GraphQLResponse.fromDynamic(response);
  /// if (graphqlResponse.graphQLErrors != null) {
  ///   // Handle errors
  /// }
  /// ```
  /// 
  /// {@macro graphql_response}
  factory GraphQLResponse.fromDynamic(Response res) {
    final listError = res.body['errors'];

    if ((listError is List) && listError.isNotEmpty) {
      return GraphQLResponse<T>(
        status: res.status,
        graphQLErrors: listError.map((e) => GraphQLError(
          code: (e['extensions'] != null ? e['extensions']['code'] ?? '' : '').toString(),
          message: (e['message'] ?? '').toString(),
        )).toList()
      );
    }
    return GraphQLResponse<T>.fromResponse(res);
  }

  /// Constructs a [GraphQLResponse] from an exception.
  ///
  /// This factory constructor is useful when an exception occurs during
  /// the request and you want to convert it into a structured response.
  ///
  /// ## Parameters
  /// - [e]: The exception to convert.
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final response = await client.post('/graphql', body: query);
  /// } catch (e) {
  ///   final errorResponse = GraphQLResponse.fromException(e);
  ///   print(errorResponse.graphQLErrors?.first.message);
  /// }
  /// ```
  /// 
  /// {@macro graphql_response}
  factory GraphQLResponse.fromException(Exception e) {
    return GraphQLResponse<T>(
      status: HttpStatus.CONNECTION_NOT_REACHABLE,
      graphQLErrors: [
        GraphQLError(
          code: null,
          message: e.toString(),
        )
      ]
    );
  }
}