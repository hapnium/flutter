/// {@template redirect_info}
/// Redirect information.
///
/// This interface stores information about an HTTP redirect, including
/// the status code used for the redirect, the HTTP method used, and
/// the target location URI.
///
/// ## Example
/// ```dart
/// void processRedirect(RedirectInfo redirect) {
///   print('Redirect ${redirect.statusCode} from ${redirect.method} to ${redirect.location}');
/// }
/// ```
/// {@endtemplate}
abstract interface class RedirectInfo {
  /// Returns the status code used for the redirect.
  /// 
  /// This is typically one of:
  /// - 301 (Moved Permanently)
  /// - 302 (Found)
  /// - 303 (See Other)
  /// - 307 (Temporary Redirect)
  /// - 308 (Permanent Redirect)
  ///
  /// ## Example
  /// ```dart
  /// if (redirect.statusCode == 301) {
  ///   print('Permanent redirect');
  /// }
  /// ```
  int get statusCode;

  /// Returns the method used for the redirect.
  /// 
  /// This is the HTTP method used in the redirect request, such as
  /// 'GET' or 'POST'.
  ///
  /// ## Example
  /// ```dart
  /// print(redirect.method); // 'GET'
  /// ```
  String get method;

  /// Returns the location for the redirect.
  /// 
  /// This is the target URI that the client should follow.
  ///
  /// ## Example
  /// ```dart
  /// final newUrl = redirect.location;
  /// ```
  Uri get location;
}