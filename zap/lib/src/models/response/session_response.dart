/// {@template session_response}
/// A Data Transfer Object (DTO) representing the cryptographic tokens required 
/// to maintain an authenticated user session.
///
/// **Architectural Context:**
/// This class typically models the payload returned by a successful login, signup, 
/// or token-refresh endpoint in an OAuth 2.0 or JWT-based authentication system. 
/// It strictly separates the short-lived [accessToken] (used for authorizing 
/// immediate API requests) from the long-lived [refreshToken] (used to quietly 
/// negotiate a new access token in the background when the current one expires).
///
/// By keeping these tokens wrapped in a strongly-typed object, you can easily 
/// pass the session state between your authentication repository, HTTP interceptors, 
/// and local secure storage.
///
/// **JSON Structure:**
/// ```json
/// {
///   "access_token": "eyJhbGciOiJIUzI1...",
///   "refresh_token": "def50200543e4..."
/// }
/// ```
/// {@endtemplate}
class SessionResponse {
  /// The primary cryptographic credential used to authorize API requests.
  ///
  /// **Usage:** 
  /// This token should be injected into the `Authorization` header of your HTTP 
  /// requests, typically formatted as `Bearer <accessToken>`. It is usually 
  /// short-lived (e.g., 15 minutes to 1 hour) to minimize the attack window if 
  /// the token is intercepted.
  final String accessToken;

  /// The long-lived credential used to seamlessly negotiate a new [accessToken].
  ///
  /// **Usage:**
  /// When an API request fails with a `401 Unauthorized`, your HTTP interceptor 
  /// should catch the failure, send this [refreshToken] to the backend's refresh 
  /// endpoint, receive a new `SessionResponse`, and seamlessly retry the failed 
  /// request without forcing the user to log in again.
  final String refreshToken;

  /// {@macro session_response}
  ///
  /// Instantiates a fully populated [SessionResponse] object.
  /// 
  /// Both tokens are strictly required. If you are initializing a state where 
  /// the user is not yet logged in, use [SessionResponse.empty] instead of passing 
  /// nulls.
  SessionResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  /// Returns a new instance of [SessionResponse] with selectively updated tokens.
  ///
  /// **Architectural Use Case (Token Rotation):**
  /// Some backends implement "Refresh Token Rotation", where refreshing a session 
  /// returns both a new access token *and* a new refresh token. However, some 
  /// backends only return a new access token. [copyWith] allows you to safely 
  /// update the [accessToken] in your state while keeping the existing 
  /// [refreshToken] perfectly intact.
  ///
  /// Example usage:
  /// ```dart
  /// // Only the access token updated; preserve the old refresh token.
  /// SessionResponse updatedSession = currentSession.copyWith(
  ///   accessToken: newPayload.accessToken,
  /// );
  /// ```
  /// 
  /// {@macro session_response}
  SessionResponse copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return SessionResponse(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  /// Deserializes a raw JSON map into a strictly typed [SessionResponse].
  ///
  /// **Defensive Parsing Strategy:**
  /// This factory utilizes the null-coalescing operator (`?? ""`) to guarantee 
  /// that missing keys result in empty strings rather than throwing a null-pointer 
  /// exception. While an empty string is an invalid token, it ensures the app 
  /// fails gracefully (e.g., triggering a standard `401` logout flow) rather 
  /// than crashing the rendering thread.
  /// 
  /// {@macro session_response}
  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      accessToken: json["access_token"] ?? "",
      refreshToken: json["refresh_token"] ?? "",
    );
  }

  /// Serializes the session object back into a normalized JSON map.
  ///
  /// **Serialization Use Case:**
  /// Highly useful for writing the session state to persistent local storage 
  /// (like `flutter_secure_storage` or Hive). By encoding this object to a JSON 
  /// string, you can save the user's session and re-hydrate it via [fromJson] 
  /// the next time the app launches, keeping the user logged in.
  /// 
  /// {@macro session_response}
  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "refresh_token": refreshToken,
  };

  /// Constructs a safe, unauthenticated fallback state.
  ///
  /// **Architectural Fallback:**
  /// Generates a [SessionResponse] where both tokens are empty strings. 
  /// This is the ideal initial state for authentication managers (like a 
  /// `StateNotifier` or `Bloc`) representing a logged-out user, preventing the 
  /// need for nullable `SessionResponse?` types that force endless null-checks 
  /// throughout your UI logic.
  /// 
  /// {@macro session_response}
  factory SessionResponse.empty() {
    return SessionResponse(
      accessToken: "", 
      refreshToken: "",
    );
  }
}