import 'dart:async' show Completer;

import '../exceptions/zap_exception.dart';

/// {@template cancel_token}
/// A cooperative cancellation mechanism for aborting in-flight asynchronous operations, 
/// primarily HTTP requests within the Zap networking ecosystem.
/// 
/// **Architectural Purpose:**
/// HTTP requests take time. Often, the context that initiated a request (like a UI screen) 
/// is destroyed before the request completes. If the request isn't cancelled, it wastes 
/// device bandwidth, consumes battery, and risks triggering exceptions (e.g., calling 
/// `setState()` on an unmounted Flutter widget). 
/// 
/// The `CancelToken` solves this by acting as a shared signal between the UI layer 
/// and the networking layer. The UI holds the token and can call [cancel], while the 
/// networking client listens to the [future] and safely severs the TCP connection if 
/// the future completes.
/// 
/// **Example usage:**
/// ```dart
/// final cancelToken = CancelToken();
/// 
/// // 1. Pass the token to the network request
/// final future = zap.get<String>(
///   '/api/data',
///   cancelToken: cancelToken,
/// );
/// 
/// // 2. If the user navigates away, trigger the cancellation
/// @override
/// void dispose() {
///   cancelToken.cancel('User navigated away from the screen');
///   super.dispose();
/// }
/// ```
/// {@endtemplate}
class CancelToken {
  /// Internal completer used to broadcast the cancellation event asynchronously.
  final Completer<String> _completer = Completer<String>();
  
  /// Internal state tracking whether the cancellation has already been triggered.
  bool _isCancelled = false;
  
  /// The optional string explaining why the token was cancelled.
  String? _reason;

  /// Synchronously returns `true` if this token has been cancelled.
  /// 
  /// Useful for quick, non-blocking checks in tight loops or right before 
  /// executing expensive data-parsing operations after a network payload arrives.
  bool get isCancelled => _isCancelled;

  /// The human-readable reason provided when [cancel] was invoked.
  /// 
  /// Returns `null` if the token has not been cancelled yet, or if it was 
  /// cancelled without an explicit reason. Useful for logging or displaying 
  /// toast notifications to the user.
  String? get reason => _reason;

  /// The asynchronous signal that the networking layer listens to.
  /// 
  /// Underlying HTTP clients (like `dart:io` HttpClient) attach listeners to 
  /// this Future. When [cancel] is called, this Future completes, signaling 
  /// the network client to immediately abort the socket connection.
  Future<String> get future => _completer.future;

  /// Triggers the cancellation event, aborting any operations bound to this token.
  /// 
  /// This method is **idempotent**. Calling it multiple times is perfectly safe; 
  /// subsequent calls will simply be ignored, preserving the original [reason] 
  /// and preventing `StateError` from the underlying Completer.
  /// 
  /// ---
  /// **Parameters:**
  /// - [reason]: An optional message explaining why the operation is being aborted 
  ///   (e.g., "Timeout", "User manually cancelled"). Defaults to 'Request cancelled'.
  void cancel([String reason = 'Request cancelled']) {
    if (!_isCancelled) {
      _isCancelled = true;
      _reason = reason;
      // Broadcasting the reason signals the network layer to terminate the request.
      _completer.complete(reason);
    }
  }

  /// Acts as a synchronization guard, forcefully throwing a [ZapException] if 
  /// the operation has been cancelled.
  /// 
  /// **Where to use this:**
  /// This should be injected at various execution checkpoints within the request 
  /// pipeline. For example:
  /// 1. Right before dispatching the network payload.
  /// 2. Right after the network payload returns, but before expensive JSON deserialization.
  /// 
  /// By throwing a [ZapException], it immediately halts the current execution context 
  /// and passes control to the caller's `catch` block.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw ZapException('Request cancelled: $_reason');
    }
  }
}