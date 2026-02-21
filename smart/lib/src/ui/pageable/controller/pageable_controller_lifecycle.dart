import 'package:flutter/foundation.dart';

mixin PageableControllerLifecycle on Object {
  bool _didCallPageableInit = false;
  bool _didCallPageableReady = false;
  bool _didCallPageableDispose = false;

  @protected
  void onPageableInit() {}

  @protected
  void onPageableReady() {}

  @protected
  void onPageableDispose() {}

  @protected
  void onPageableRetry(int attempt, Object error, StackTrace stackTrace, Duration delay) {}

  @protected
  void triggerPageableInit() {
    if (_didCallPageableInit) return;
    _didCallPageableInit = true;
    onPageableInit();
  }

  @protected
  void triggerPageableReady() {
    if (_didCallPageableReady) return;
    _didCallPageableReady = true;
    onPageableReady();
  }

  @protected
  void triggerPageableDispose() {
    if (_didCallPageableDispose) return;
    _didCallPageableDispose = true;
    onPageableDispose();
  }

  @protected
  void triggerPageableRetry(int attempt, Object error, StackTrace stackTrace, Duration delay) {
    onPageableRetry(attempt, error, stackTrace, delay);
  }
}