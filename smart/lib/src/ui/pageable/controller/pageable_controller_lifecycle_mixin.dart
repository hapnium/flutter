import 'package:flutter/foundation.dart';
import 'package:smart/exceptions.dart';

/// {@template pageable_controller_lifecycle_mixin}
/// Disposal tracking and use-after-dispose diagnostics for pageable controllers.
///
/// Mixed into `PageableController` to provide:
/// - [mounted]/[isDisposed] guards checked after every async gap.
/// - [trackOperation] recording of the latest controller call for debugging.
/// - [debugAssertNotDisposed], which throws a [SmartException] with creation,
///   disposal, and last-operation stacks when a disposed controller is used
///   in debug builds.
/// {@endtemplate}
mixin PageableControllerLifecycleMixin<PageKey, Item> on Object {
  /// Whether [markDisposed] has run.
  bool _isDisposed = false;

  /// When the controller was constructed.
  final DateTime _createdAt = DateTime.now();

  /// Stack trace captured at construction, used in diagnostics.
  final StackTrace _creationStackTrace = StackTrace.current;

  /// When the controller was disposed, or `null` if still mounted.
  DateTime? _disposedAt;

  /// Stack trace captured at disposal, used in diagnostics.
  StackTrace? _disposeStackTrace;

  /// Name of the most recent tracked operation, if any.
  String? _lastOperation;

  /// When the most recent tracked operation ran, if any.
  DateTime? _lastOperationAt;

  /// Stack trace captured at the most recent tracked operation, if any.
  StackTrace? _lastOperationStackTrace;

  /// Whether the controller is still usable (not disposed).
  bool get mounted => !_isDisposed;

  /// Whether [markDisposed] has run.
  bool get isDisposed => _isDisposed;

  /// One-line summary of the controller lifecycle for logs and error reports.
  ///
  /// Includes creation time, disposal time (or `'not disposed'`), and the
  /// most recent tracked operation.
  String get debugLifecycleSummary {
    final disposedAt = _disposedAt?.toIso8601String() ?? 'not disposed';
    final lastOperation = _lastOperation == null
        ? 'none'
        : '$_lastOperation at ${_lastOperationAt?.toIso8601String()}';
    return 'createdAt=${_createdAt.toIso8601String()}, disposedAt=$disposedAt, lastOperation=$lastOperation';
  }

  /// The [PageKey] type argument, used in diagnostics.
  Type getPageKeyType();

  /// The [Item] type argument, used in diagnostics.
  Type getItemType();

  /// Records [operation] as the latest controller activity.
  ///
  /// Called at the start of every public controller method so
  /// [debugLifecycleSummary] and use-after-dispose errors can point at what
  /// the controller was doing.
  @protected
  void trackOperation(String operation) {
    _lastOperation = operation;
    _lastOperationAt = DateTime.now();
    _lastOperationStackTrace = StackTrace.current;
  }

  /// Marks the controller as disposed, capturing when and where.
  ///
  /// Called from `dispose` before listeners are released.
  @protected
  void markDisposed() {
    _disposedAt = DateTime.now();
    _disposeStackTrace = StackTrace.current;
    _isDisposed = true;
  }

  /// Throws when the controller is used after disposal (debug builds only).
  ///
  /// In debug mode, throws a [SmartException] describing the controller
  /// types plus creation, disposal, last-operation, and offending-call
  /// stacks. In release mode asserts are skipped and this returns `true`
  /// without checking. Always returns `true` so it can be used as a bare
  /// statement.
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

  /// Formats the elapsed time between [from] and [to] for diagnostics.
  String _formatAge(DateTime from, DateTime? to) {
    if (to == null) return 'unknown';
    final diff = to.difference(from);
    return '${diff.inMilliseconds}ms';
  }
}