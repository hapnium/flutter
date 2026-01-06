import 'enums/log_level.dart';
import 'tracing_listener.dart';

/// {@template default_log_listener}
/// A default implementation of [TracingListener] that outputs logs to the console.
///
/// [DefaultTracingListener] provides a simple and human-readable logging mechanism
/// by printing log messages to the standard output (`stdout`). Each log entry is timestamped,
/// tagged, and categorized by [LogLevel].
///
/// This listener is ideal for:
/// - Development and debugging environments
/// - Local testing
/// - Simple CLI applications
///
/// ### Output Format
/// Logs are printed in the following format:
///
/// ```text
/// [2025-06-18 14:22:01.534][MyService][info] Service started successfully.
/// [2025-06-18 14:22:05.882][Database][error] Connection failed: Timeout
/// ```
///
/// ### Example Usage
///
/// ```dart
/// final logger = MyCustomLogger('Database');
/// final listener = DefaultApplicationLogListener();
///
/// logger.add(LogLevel.error, 'Connection failed');
/// 
/// // Somewhere internally, the listener gets notified:
/// listener.onLog(LogLevel.error, DateTime.now(), 'Connection failed', 'Database');
/// ```
///
/// ### Integration with Logging System
/// To use this with a custom logger or broadcasting mechanism:
///
/// ```dart
/// final listener = DefaultApplicationLogListener();
///
/// void broadcastLog(LogLevel level, String message, String tag) {
///   final now = DateTime.now();
///   listener.onLog(level, now, message, tag);
///   // other listeners can also be notified here
/// }
/// ```
///
/// {@endtemplate}
class DefaultTracingListener extends TracingListener {
  /// {@macro default_logger_listener}
  DefaultTracingListener({
    super.level,
    super.printer,
    super.type,
    super.output,
    super.name,
    super.config,
  });
}