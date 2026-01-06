/// A flexible and extensible structured logging library for Dart and Flutter.
///
/// The `logger` library provides a pluggable, highly customizable logging solution
/// for applications that require clarity, consistency, and control over how logs are
/// captured, formatted, and displayed.
///
/// ---
///
/// ### 🔧 Features:
/// - Multiple log levels: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`
/// - Structured, human-readable, and colorized output
/// - Supports tagging, timestamps, error handling, stack traces, and more
/// - Easily switch or create custom log output styles via `LogPrinter`
/// - Customizable logging steps (`LogStep`) to include/exclude parts of a log
///
/// ---
///
/// ### 🖨️ Built-in Printer Types (via `LogType`)
///
/// | Type                | Description                                                                 | Output Style         | Structured | Colorized |
/// |---------------------|-----------------------------------------------------------------------------|----------------------|------------|-----------|
/// | `SIMPLE`            | Concise single-line output with optional emoji and tags                     | Minimal              | ❌          | ✔️         |
/// | `FLAT`              | Flat, raw output of the message only                                         | Plain                | ❌          | ❌         |
/// | `FLAT_STRUCTURED`   | Flat output with structured fields like level, timestamp, etc.               | One-line Structured  | ✔️          | ❌         |
/// | `PRETTY`            | Formatted and aligned multi-line logs                                       | Multi-line           | ❌          | ✔️         |
/// | `PRETTY_STRUCTURED` | Verbose, pretty-printed logs with section headers and stack traces          | Multi-line Structured| ✔️          | ✔️         |
/// | `PREFIX`            | Logs prefixed with info like `[T:main]` or `[INFO]`                          | Prefixed             | ✔️          | ❌         |
/// | `FMT`               | C-style formatted string logger                                              | Formatted Strings    | ❌          | ❌         |
/// | `HYBRID`            | Combines pretty and structured logging for detailed yet readable output     | Mixed Style          | ✔️          | ✔️         |
///
/// ---
///
/// ### 🛠️ Creating a Custom Printer
///
/// To define a custom log printer, extend the [LogPrinter] abstract class:
///
/// ```dart
/// class MyCustomPrinter extends LogPrinter {
///   @override
///   List<String> log(LogRecord record) {
///     return ['[${record.level.name}] ${record.message}'];
///   }
/// }
/// ```
///
/// Then attach your printer to a custom tracing listener:
///
/// ```dart
/// final myLogger = Tracing();
/// myLogger.addListener(TracingListener.withPrinter(MyCustomPrinter()));
/// myLogger.info('Hello from custom logger!');
/// ```
///
/// ---
///
/// ### 🧪 Quick Usage Example
///
/// ```dart
/// import 'package:tracing/logger.dart';
///
/// void main() {
///   console.debug('Initializing system...');
///   console.error('Failed to connect', error: Exception('Timeout'));
/// }
/// ```
///
/// ---
///
/// ### 📦 Exports:
/// This library exports core types and interfaces:
///
/// - [LogLevel] — log severity levels
/// - [LogStep] — defines log components like timestamp, message, error, etc.
/// - [LogType] — enum for built-in printer styles
/// - [LogPrinter] — base class for custom printer implementations
/// - [TracingListener] — interface for log event listening
library;

import 'src/default_tracing_listener.dart';
import 'src/enums/log_level.dart';
import 'src/enums/log_type.dart';
import 'src/log_printer.dart';
import 'src/tracing_listener.dart';
import 'src/models/log_config.dart';

/// ENUMS & Interfaces exported for external use.
export 'src/enums/log_level.dart';
export 'src/enums/log_step.dart';
export 'src/enums/log_type.dart';
export 'src/log_printer.dart';
export 'src/tracing_listener.dart';
export 'src/models/log_config.dart';

/// {@template tracing}
/// A flexible and extensible logging interface.
///
/// The [Tracing] class provides structured and leveled logging functionality
/// across your application. It wraps a [TracingListener] that handles
/// how logs are processed and output—making it customizable through the strategy pattern.
///
/// This class offers six common logging levels:
/// - [info] – General operational messages.
/// - [debug] – Development and debugging messages.
/// - [trace] – Fine-grained, low-level application traces.
/// - [warning] – Warning messages about unexpected conditions.
/// - [error] – Errors that occurred during execution.
/// - [fatal] – Critical errors that may require immediate attention.
///
/// ### Example:
/// ```dart
/// console.info('Server started');
/// console.error('Unexpected error occurred', error: e, stackTrace: s);
/// ```
///
/// {@endtemplate}
class Tracing {
  /// The current log listener responsible for handling the log output logic.
  ///
  /// You can override this with a custom [TracingListener] via [addListener()]
  /// to modify how logs are formatted or where they are sent (e.g., file, console, remote server).
  late TracingListener listener;

  /// {@macro tracing}
  Tracing({
    LogLevel level = LogLevel.INFO,
    LogPrinter? printer,
    LogType type = LogType.SIMPLE,
    void Function(String)? output,
    String name = "",
    LogConfig? config,
  }) : listener = DefaultTracingListener(
    level: level,
    printer: printer,
    type: type,
    output: output,
    name: name,
    config: config,
  );

  /// Replaces the current [TracingListener] with a custom implementation.
  ///
  /// Useful if you want to change the output format, destination,
  /// or add logic like filtering or buffering logs.
  ///
  /// Example:
  /// ```dart
  /// console.addListener(MyCustomListener());
  /// ```
  void addListener(TracingListener listener) {
    this.listener = listener;
  }

  /// Logs a message with [LogLevel.INFO].
  ///
  /// Use this for standard log messages that confirm normal application behavior.
  void info(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.INFO, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with a specified log level.
  ///
  /// Use this for logging messages with a specific log level.
  void log(dynamic message, {String? tag, Object? error, StackTrace? stackTrace, LogLevel level = LogLevel.INFO}) {
    listener.onLog(level, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with [LogLevel.ERROR].
  ///
  /// Use this when something has gone wrong and requires investigation,
  /// but may not crash the application.
  void error(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.ERROR, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with [LogLevel.WARN].
  ///
  /// Use this when something unexpected occurred or is about to fail.
  /// Warnings may not be errors but are worthy of attention.
  void warn(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.WARN, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with [LogLevel.DEBUG].
  ///
  /// Intended for debugging purposes. These logs are verbose and usually
  /// not shown in production environments.
  void debug(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.DEBUG, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with [LogLevel.TRACE].
  ///
  /// Use this for deep tracing information such as lifecycle details,
  /// low-level diagnostics, or fine-grained application flow.
  void trace(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.TRACE, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with [LogLevel.FATAL].
  ///
  /// Use this to log critical application failures.
  /// These logs should alert developers/operators immediately.
  void fatal(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.FATAL, message, error: error, stackTrace: stackTrace, tag: tag);
  }
}

/// Global singleton logger instance for convenience.
///
/// Use `console` for quick access without instantiating [Tracing] manually.
///
/// Example:
/// ```dart
/// console.debug('Hello from global logger');
/// ```
final console = Tracing();