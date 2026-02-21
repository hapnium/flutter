import 'package:flutter/foundation.dart';
import 'package:smart/exceptions.dart';

mixin PageableControllerLifecycleMixin<PageKey, Item> on Object {
  bool _isDisposed = false;

  final DateTime _createdAt = DateTime.now();
  final StackTrace _creationStackTrace = StackTrace.current;

  DateTime? _disposedAt;
  StackTrace? _disposeStackTrace;

  String? _lastOperation;
  DateTime? _lastOperationAt;
  StackTrace? _lastOperationStackTrace;

  bool get mounted => !_isDisposed;

  bool get isDisposed => _isDisposed;

  String get debugLifecycleSummary {
    final disposedAt = _disposedAt?.toIso8601String() ?? 'not disposed';
    final lastOperation = _lastOperation == null
        ? 'none'
        : '$_lastOperation at ${_lastOperationAt?.toIso8601String()}';
    return 'createdAt=${_createdAt.toIso8601String()}, disposedAt=$disposedAt, lastOperation=$lastOperation';
  }

  Type getPageKeyType();

  Type getItemType();

  @protected
  void trackOperation(String operation) {
    _lastOperation = operation;
    _lastOperationAt = DateTime.now();
    _lastOperationStackTrace = StackTrace.current;
  }

  @protected
  void markDisposed() {
    _disposedAt = DateTime.now();
    _disposeStackTrace = StackTrace.current;
    _isDisposed = true;
  }

  @protected
  bool debugAssertNotDisposed() {
    trackOperation('debugAssertNotDisposed');
    assert(() {
      if (_isDisposed) {
        final useAfterDisposeAt = DateTime.now();
        final useAfterDisposeStack = StackTrace.current;
        throw SmartException(
          'The PageableController [$runtimeType] for Item($Item - ${getItemType()}***${getItemType().runtimeType}) '
          'and PageKey($PageKey - ${getPageKeyType()}***${getPageKeyType().runtimeType}) was used after being '
          'disposed.\nOnce you have called dispose() on a PageableController, it can no longer be '
          'used.\nIf you’re using a Future, it probably completed after '
          'the disposal of the owning widget.\nMake sure dispose() has not '
          'been called yet before using the PageableController.\n'
          'Lifecycle details:\n'
          '- Created at: ${_createdAt.toIso8601String()}\n'
          '- Disposed at: ${_disposedAt?.toIso8601String() ?? 'unknown'}\n'
          '- Last operation: ${_lastOperation ?? 'unknown'} at ${_lastOperationAt?.toIso8601String() ?? 'unknown'}\n'
          '- Time from create to dispose: ${_formatAge(_createdAt, _disposedAt)}\n'
          '- Time from dispose to invalid use: ${_formatAge(_disposedAt ?? _createdAt, useAfterDisposeAt)}\n'
          'Creation stack:\n$_creationStackTrace\n'
          'Dispose stack:\n${_disposeStackTrace ?? 'unknown'}\n'
          'Last operation stack:\n${_lastOperationStackTrace ?? 'unknown'}\n'
          'Use-after-dispose stack:\n$useAfterDisposeStack',
        );
      }
      return true;
    }());
    return true;
  }

  String _formatAge(DateTime from, DateTime? to) {
    if (to == null) return 'unknown';
    final diff = to.difference(from);
    return '${diff.inMilliseconds}ms';
  }
}