import 'package:flutter/foundation.dart';

/// {@template pageable_controller_lifecycle}
/// One-shot lifecycle events for pageable controllers.
///
/// Mixed into `PageableController` to expose init/ready/dispose hooks with
/// exactly-once semantics: each trigger fires at most once per controller
/// instance, so callbacks run a single time even if a trigger is invoked
/// again.
///
/// Event order is [onPageableInit] → [onPageableReady] → [onPageableDispose].
/// Retry notifications ([onPageableRetry]) are not one-shot and fire on
/// every scheduled retry attempt.
/// {@endtemplate}
mixin PageableControllerLifecycle on Object {
  /// Whether [onPageableInit] has already run.
  bool _didCallPageableInit = false;

  /// Whether [onPageableReady] has already run.
  bool _didCallPageableReady = false;

  /// Whether [onPageableDispose] has already run.
  bool _didCallPageableDispose = false;

  /// Invoked once after the controller is constructed.
  ///
  /// Override to run setup logic, or pass `onPageableInitCallback` to the
  /// controller constructor.
  @protected
  void onPageableInit() {}

  /// Invoked once when the controller is ready to load.
  ///
  /// The controller triggers this on the first post-frame callback, right
  /// before the initial fetch. Override to run logic that must wait until
  /// the owning widget is laid out, or pass `onPageableReadyCallback`.
  @protected
  void onPageableReady() {}

  /// Invoked once when the controller is disposed.
  ///
  /// Override to release resources acquired in [onPageableInit], or pass
  /// `onPageableDisposeCallback`.
  @protected
  void onPageableDispose() {}

  /// Invoked every time a fetch retry is scheduled.
  ///
  /// Unlike the other hooks this is not one-shot: it fires per attempt with
  /// the attempt number, the error, its stack trace, and the delay before
  /// the retry runs. Override or pass `onRetryAttempt`.
  @protected
  void onPageableRetry(int attempt, Object error, StackTrace stackTrace, Duration delay) {}

  /// Runs [onPageableInit] unless it already ran.
  @protected
  void triggerPageableInit() {
    if (_didCallPageableInit) return;
    _didCallPageableInit = true;
    onPageableInit();
  }

  /// Runs [onPageableReady] unless it already ran.
  @protected
  void triggerPageableReady() {
    if (_didCallPageableReady) return;
    _didCallPageableReady = true;
    onPageableReady();
  }

  /// Runs [onPageableDispose] unless it already ran.
  @protected
  void triggerPageableDispose() {
    if (_didCallPageableDispose) return;
    _didCallPageableDispose = true;
    onPageableDispose();
  }

  /// Forwards a scheduled retry to [onPageableRetry].
  @protected
  void triggerPageableRetry(int attempt, Object error, StackTrace stackTrace, Duration delay) {
    onPageableRetry(attempt, error, stackTrace, delay);
  }
}