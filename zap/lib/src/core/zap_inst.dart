// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:tracing/tracing.dart' show console;

/// {@template log_mode}
/// Defines the severity level for internal Zap logging.
///
/// Each mode maps directly to a corresponding `console` method from the
/// `tracing` package, enabling structured, color-coded log output.
///
/// The levels are ordered from least severe ([TRACE]) to most severe ([FATAL]).
/// This ordering is used by the `tracing` package to filter log output based
/// on a configured minimum level.
///
/// ### Severity hierarchy
/// ```
/// TRACE < DEBUG < INFO < WARN < ERROR < FATAL
/// ```
///
/// ### Example usage
/// ```dart
/// Z.showLog = true;
/// Z.log('Connecting...', mode: LogMode.DEBUG);
/// Z.log('Connection lost', mode: LogMode.ERROR);
/// ```
///
/// See also:
/// - [ZapImpl.log], which accepts a [LogMode] parameter.
/// - The convenience methods [ZapImpl.trace], [ZapImpl.debug], etc., which
///   pre-select a [LogMode].
/// {@endtemplate}
enum LogMode {
  /// Trace-level logging for extremely verbose, internal flow tracing.
  ///
  /// Maps to `console.trace()`. Intended for deep debugging of control flow,
  /// variable values, and step-by-step execution. Typically disabled in
  /// production and even in most development scenarios.
  TRACE,

  /// Debug-level logging for developer-facing diagnostic information.
  ///
  /// Maps to `console.debug()`. Useful during active development to inspect
  /// intermediate state, request parameters, or response bodies. Generally
  /// hidden in production builds.
  DEBUG,

  /// Info-level logging for high-level lifecycle events.
  ///
  /// Maps to `console.info()`. Represents normal, expected events such as
  /// client initialization, connection establishment, or request completion.
  /// Safe to leave enabled in production for operational visibility.
  INFO,

  /// Warn-level logging for recoverable issues.
  ///
  /// Maps to `console.warn()`. Indicates conditions that are not errors but
  /// may require attention, such as automatic retries, fallback responses, or
  /// deprecated API usage. The application continues to function normally.
  WARN,

  /// Error-level logging for failures that affect a single operation.
  ///
  /// Maps to `console.error()`. Represents request-level failures (e.g., HTTP
  /// 500, network timeout) that can be recovered from at the application level.
  /// Each error log should include enough context to diagnose the issue.
  ERROR,

  /// Fatal-level logging for unrecoverable errors.
  ///
  /// Maps to `console.fatal()`. Indicates critical failures that may lead to
  /// application instability, data corruption, or crashes. These errors
  /// typically require immediate attention and may trigger alerting systems.
  FATAL,
}

/// {@template zap_logger}
/// Internal logger that delegates to the `tracing` package's `console` API.
///
/// [_ZapLogger] is a thin wrapper that translates [LogMode] values into the
/// appropriate `console` method call. It is not part of the public API and
/// should only be used by [ZapImpl].
///
/// ### Tag resolution
///
/// The log tag displayed in the console is resolved in the following order:
/// 1. If [from] is non-null, it is used as the tag.
/// 2. Otherwise, if [prefix] is non-null, it is used as the tag.
/// 3. If both are `null`, the tag defaults to the caller's class name
///    (determined by the `tracing` package).
///
/// ### Parameters
///
/// - [message]: The content to log. Can be any type; non-string values are
///   converted to strings via `toString()`.
/// - [prefix]: An optional tag that overrides [from]. Takes lower priority
///   than [from].
/// - [from]: An optional tag identifying the log source class. Takes higher
///   priority than [prefix].
/// - [needHeader]: Reserved for future use; currently unused by the logger.
/// - [mode]: The severity level; defaults to [LogMode.INFO].
/// {@endtemplate}
class _ZapLogger {
  /// {@macro zap_logger}
  void log(
    dynamic message, {
    String? prefix,
    String? from,
    bool needHeader = true,
    LogMode mode = LogMode.INFO,
  }) {
    switch(mode) {
      case LogMode.TRACE:
        console.trace(message, tag: from ?? prefix);
        break;
      case LogMode.DEBUG:
        console.debug(message, tag: from ?? prefix);
        break;
      case LogMode.INFO:
        console.info(message, tag: from ?? prefix);
        break;
      case LogMode.WARN:
        console.warn(message, tag: from ?? prefix);
        break;
      case LogMode.ERROR:
        console.error(message, tag: from ?? prefix);
        break;
      case LogMode.FATAL:
        console.fatal(message, tag: from ?? prefix);
        break;
    }
  }
}

/// {@template zap_impl}
/// Concrete logging implementation for the Zap package.
///
/// `ZapImpl` wraps the internal [_ZapLogger] and provides a set of
/// convenience methods ([trace], [debug], [info], [warn], [error], [fatal])
/// that forward to the generic [log] method with the appropriate [LogMode].
///
/// ### Gating
///
/// Logging is gated by the [showLog] flag. When `false` (the default), all
/// log calls are no-ops, ensuring zero overhead in production. When `true`,
/// every call to [log] (and its convenience wrappers) is forwarded to the
/// underlying [_ZapLogger].
///
/// ### Global instance
///
/// A pre-configured global instance is exposed as the top-level constant [Z]:
/// ```dart
/// Z.showLog = true; // enable logging
/// Z.info('Zap client initialized');
/// Z.error('Request failed: $error');
/// Z.showLog = false; // disable logging
/// ```
///
/// ### Custom logging
///
/// To redirect Zap logs to a custom destination, subclass or replace the
/// internal [_ZapLogger] and override the [log] method.
/// {@endtemplate}
class ZapImpl {
  bool _showLog = false;
  final _logger = _ZapLogger();

  /// Whether logging is enabled.
  ///
  /// When `true`, every call to [log] (and its convenience wrappers) is
  /// forwarded to the underlying [_ZapLogger]. When `false`, all log calls
  /// are silently ignored.
  ///
  /// Defaults to `false` to avoid noise in production. Set to `true` during
  /// development or when debugging network issues:
  /// ```dart
  /// Z.showLog = true;
  /// ```
  // ignore: unnecessary_getters_setters
  bool get showLog => _showLog;

  set showLog(bool value) {
    _showLog = value;
  }

  /// Logs a message to the console with the specified options.
  ///
  /// If [showLog] is `false`, the message will not be logged and this method
  /// returns immediately.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log. Can be any type; non-string values are
  ///   converted to strings via `toString()`.
  /// - [mode]: The severity level; defaults to [LogMode.INFO]. Determines
  ///   which `console` method is invoked.
  /// - [prefix]: An optional tag that overrides [from] in the log output.
  ///   Useful for categorizing logs by feature or module.
  /// - [from]: An optional tag identifying the log source class. Typically
  ///   the class name of the caller.
  /// - [needHeader]: Reserved for future use; currently unused.
  ///
  /// ### Example
  /// ```dart
  /// Z.log('Request sent', mode: LogMode.DEBUG, from: 'ZapClient');
  /// Z.log('Retry attempt #3', mode: LogMode.WARN, prefix: 'Retry');
  /// ```
  void log(
    dynamic message, {
    LogMode mode = LogMode.INFO,
    String? prefix,
    String? from,
    bool needHeader = true,
  }) {
    if (showLog) {
      _logger.log(
        message,
        prefix: prefix,
        from: from,
        needHeader: needHeader,
        mode: mode,
      );
    }
  }

  /// Logs a trace-level message to the console.
  ///
  /// Trace messages are extremely verbose and intended for deep debugging
  /// of internal control flow. Maps to `console.trace()`.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log.
  /// - [prefix]: Optional tag override.
  /// - [from]: Optional source class tag.
  /// - [needHeader]: Reserved for future use.
  ///
  /// ### Example
  /// ```dart
  /// Z.trace('Entering _buildRequestHeaders()');
  /// ```
  void trace(dynamic message, {String? prefix, String? from, bool needHeader = true}) {
    log(message, mode: LogMode.TRACE, prefix: prefix, from: from, needHeader: needHeader);
  }

  /// Logs a debug-level message to the console.
  ///
  /// Debug messages provide developer-facing diagnostic information that
  /// is useful during development but typically hidden in production.
  /// Maps to `console.debug()`.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log.
  /// - [prefix]: Optional tag override.
  /// - [from]: Optional source class tag.
  /// - [needHeader]: Reserved for future use.
  ///
  /// ### Example
  /// ```dart
  /// Z.debug('Response status: ${response.statusCode}');
  /// ```
  void debug(dynamic message, {String? prefix, String? from, bool needHeader = true}) {
    log(message, mode: LogMode.DEBUG, prefix: prefix, from: from, needHeader: needHeader);
  }

  /// Logs an info-level message to the console.
  ///
  /// Info messages represent high-level lifecycle events such as
  /// connection establishment or request completion. Maps to `console.info()`.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log.
  /// - [prefix]: Optional tag override.
  /// - [from]: Optional source class tag.
  /// - [needHeader]: Reserved for future use.
  ///
  /// ### Example
  /// ```dart
  /// Z.info('Zap client initialized with baseUrl: $baseUrl');
  /// ```
  void info(dynamic message, {String? prefix, String? from, bool needHeader = true}) {
    log(message, mode: LogMode.INFO, prefix: prefix, from: from, needHeader: needHeader);
  }

  /// Logs a warning-level message to the console.
  ///
  /// Warning messages indicate recoverable issues that may require
  /// attention but do not prevent the application from functioning.
  /// Maps to `console.warn()`.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log.
  /// - [prefix]: Optional tag override.
  /// - [from]: Optional source class tag.
  /// - [needHeader]: Reserved for future use.
  ///
  /// ### Example
  /// ```dart
  /// Z.warn('Retry attempt #2 for $url');
  /// ```
  void warn(dynamic message, {String? prefix, String? from, bool needHeader = true}) {
    log(message, mode: LogMode.WARN, prefix: prefix, from: from, needHeader: needHeader);
  }

  /// Logs an error-level message to the console.
  ///
  /// Error messages indicate failures that affect a single operation
  /// but can be recovered from at the application level. Maps to
  /// `console.error()`.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log.
  /// - [prefix]: Optional tag override.
  /// - [from]: Optional source class tag.
  /// - [needHeader]: Reserved for future use.
  ///
  /// ### Example
  /// ```dart
  /// Z.error('POST /users failed: ${e.message}');
  /// ```
  void error(dynamic message, {String? prefix, String? from, bool needHeader = true}) {
    log(message, mode: LogMode.ERROR, prefix: prefix, from: from, needHeader: needHeader);
  }

  /// Logs a fatal-level message to the console.
  ///
  /// Fatal messages indicate unrecoverable errors that may lead to
  /// application instability or crashes. Maps to `console.fatal()`.
  ///
  /// ### Parameters
  ///
  /// - [message]: The content to log.
  /// - [prefix]: Optional tag override.
  /// - [from]: Optional source class tag.
  /// - [needHeader]: Reserved for future use.
  ///
  /// ### Example
  /// ```dart
  /// Z.fatal('TLS handshake failed: $error');
  /// ```
  void fatal(dynamic message, {String? prefix, String? from, bool needHeader = true}) {
    log(message, mode: LogMode.FATAL, prefix: prefix, from: from, needHeader: needHeader);
  }
}

/// Global Zap logging instance.
///
/// Use this constant to log messages throughout the Zap package. All logging
/// is disabled by default; set [ZapImpl.showLog] to `true` to enable output.
///
/// ### Example
/// ```dart
/// // Enable logging (typically once at app startup)
/// Z.showLog = true;
///
/// // Log at different levels
/// Z.trace('Entering _parseResponse()');
/// Z.debug('Headers: $headers');
/// Z.info('WebSocket connected to $url');
/// Z.warn('Response time exceeded threshold');
/// Z.error('Request failed: ${e.message}');
/// Z.fatal('Certificate validation failed');
///
/// // Disable logging
/// Z.showLog = false;
/// ```
///
/// ### Tag customization
///
/// Use [prefix] or [from] to categorize logs:
/// ```dart
/// Z.info('Connected', from: 'ZapClient');
/// Z.warn('Retrying', prefix: 'RetryPolicy');
/// ```
final Z = ZapImpl();