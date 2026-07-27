/// {@template log_level}
/// Defines the severity hierarchy for log messages, controlling which
/// messages are processed, displayed, or suppressed.
///
/// `LogLevel` is the primary filtering mechanism in the tracing package.
/// Each level has an integer [value] for comparison — a message is shown
/// only if its level's value is greater than or equal to the configured
/// minimum level.
///
/// ### Severity hierarchy
///
/// ```
/// TRACE(0) < DEBUG(1) < INFO(2) < WARN(3) < ERROR(4) < FATAL(5) < OFF(6)
/// ```
///
/// ### Filtering behavior
///
/// When the current level is set to, say, `INFO`, only messages with
/// level `INFO`, `WARN`, `ERROR`, or `FATAL` are shown. `TRACE` and
/// `DEBUG` messages are suppressed.
///
/// ### Example
/// ```dart
/// // Only show INFO and above
/// LogConfig.currentLevel = LogLevel.INFO;
///
/// // Check before logging
/// if (LogLevel.DEBUG.isEnabledFor(LogConfig.currentLevel)) {
///   Z.debug('Variable value: $x');
/// }
/// ```
///
/// ### Comparison
///
/// Levels are compared by their integer [value]:
/// ```dart
/// print(LogLevel.WARN > LogLevel.INFO); // true
/// print(LogLevel.ERROR >= LogLevel.ERROR); // true
/// ```
/// {@endtemplate}
enum LogLevel {
  /// {@template log_level_trace}
  /// The most fine-grained severity level. Use this for tracing function
  /// calls, loop iterations, variable values, and other low-level details.
  ///
  /// Trace messages are extremely verbose and intended for deep debugging
  /// of internal control flow. They should typically be disabled in
  /// production and even in most development scenarios.
  ///
  /// **Integer value:** 0
  ///
  /// ### When to use
  /// - Tracing function entry/exit
  /// - Logging loop iterations
  /// - Recording variable values at each step
  /// - Profiling internal algorithms
  ///
  /// ### Example
  /// ```dart
  /// Z.trace('Entering _parseJson() with input length: ${input.length}');
  /// ```
  ///
  /// ### Performance note
  ///
  /// Trace messages can significantly impact performance due to their
  /// frequency. Ensure they are filtered out in production by setting
  /// the level to `DEBUG` or higher.
  /// {@endtemplate}
  TRACE(0, 'TRACE'),

  /// {@template log_level_debug}
  /// General debugging information useful during active development.
  ///
  /// Debug messages provide developer-facing diagnostic information that
  /// is valuable during development but should be hidden in production.
  /// They are more structured than trace messages but still verbose.
  ///
  /// **Integer value:** 1
  ///
  /// ### When to use
  /// - Logging variable values
  /// - Recording internal state changes
  /// - Tracking control flow decisions
  /// - Monitoring API request/response details
  ///
  /// ### Example
  /// ```dart
  /// Z.debug('Response status: ${response.statusCode}');
  /// Z.debug('User $userId authenticated via ${authMethod}');
  /// ```
  ///
  /// ### Production behavior
  ///
  /// Debug messages are typically filtered out in production builds.
  /// Use conditional compilation or runtime level checks:
  /// ```dart
  /// if (kDebugMode) {
  ///   Z.debug('Cache hit for key: $cacheKey');
  /// }
  /// ```
  /// {@endtemplate}
  DEBUG(1, 'DEBUG'),

  /// {@template log_level_info}
  /// Informational messages indicating normal application progress.
  ///
  /// Info messages represent expected, noteworthy events that confirm the
  /// application is functioning correctly. They are safe to leave enabled
  /// in production for operational visibility.
  ///
  /// **Integer value:** 2
  ///
  /// ### When to use
  /// - Application startup/shutdown
  /// - User authentication events
  /// - Configuration loaded
  /// - Service connected
  /// - Important business events
  ///
  /// ### Example
  /// ```dart
  /// Z.info('Application started on ${Platform.operatingSystem}');
  /// Z.info('User ${user.id} logged in successfully');
  /// Z.info('Cache warmed: ${cache.keys.length} entries loaded');
  /// ```
  ///
  /// ### Production behavior
  ///
  /// Info messages are the minimum recommended level for production
  /// logging. They provide sufficient visibility for monitoring without
  /// excessive noise.
  /// {@endtemplate}
  INFO(2, 'INFO'),

  /// {@template log_level_warn}
  /// Warning messages for recoverable issues that may require attention.
  ///
  /// Warning messages indicate conditions that are not errors but may
  /// indicate potential problems. The application continues to function
  /// normally, but the situation should be investigated.
  ///
  /// **Integer value:** 3
  ///
  /// ### When to use
  /// - Deprecated API usage
  /// - Automatic retries
  /// - Fallback responses
  /// - Configuration mismatches
  /// - Performance thresholds exceeded
  ///
  /// ### Example
  /// ```dart
  /// Z.warn('Deprecated method called: use newMethod() instead');
  /// Z.warn('Retry attempt #3 for request to $url');
  /// Z.warn('Response time ${elapsed}ms exceeds threshold');
  /// ```
  ///
  /// ### Production behavior
  ///
  /// Warnings should always be visible in production. They often indicate
  /// issues that could escalate to errors if left unaddressed.
  ///
  /// ### Distinction from errors
  ///
  /// - **Warning:** Something unexpected happened, but the app works fine.
  /// - **Error:** Something failed and affected functionality.
  /// {@endtemplate}
  WARN(3, 'WARNING'),

  /// {@template log_level_error}
  /// Error messages for recoverable failures that impact functionality.
  ///
  /// Error messages indicate that something failed but the application
  /// can still operate. These failures typically affect a single operation
  /// and may be recoverable via retry or alternative logic.
  ///
  /// **Integer value:** 4
  ///
  /// ### When to use
  /// - Failed network requests
  /// - File not found
  /// - Service unavailable
  /// - Validation failures
  /// - Database connection lost
  ///
  /// ### Example
  /// ```dart
  /// Z.error('POST /users failed: ${e.message}');
  /// Z.error('File not found: $path');
  /// Z.error('Database connection lost, attempting reconnect');
  /// ```
  ///
  /// ### Production behavior
  ///
  /// Errors must always be visible in production. They are the primary
  /// signal for monitoring and alerting systems.
  ///
  /// ### Recovery strategy
  ///
  /// Errors should include enough context to diagnose the issue:
  /// - What operation failed
  /// - What the input was
  /// - What the expected behavior was
  /// - What actually happened
  /// {@endtemplate}
  ERROR(4, 'ERROR'),

  /// {@template log_level_fatal}
  /// Fatal messages for critical errors that may cause application failure.
  ///
  /// Fatal messages indicate unrecoverable errors that could lead to
  /// application instability, data corruption, or crashes. These require
  /// immediate attention and may trigger alerting systems.
  ///
  /// **Integer value:** 5
  ///
  /// ### When to use
  /// - Unhandled exceptions during startup
  /// - Data corruption detected
  /// - Security breaches
  /// - Out-of-memory errors
  /// - Critical service failures
  ///
  /// ### Example
  /// ```dart
  /// Z.fatal('TLS handshake failed: $error');
  /// Z.fatal('Database migration failed: $migrationId');
  /// Z.fatal('Out of memory: ${ProcessInfo.currentRss} bytes used');
  /// ```
  ///
  /// ### Production behavior
  ///
  /// Fatal messages should always be visible and typically trigger
  /// immediate alerts (PagerDuty, Slack, email). They should be rare
  /// in a healthy system.
  ///
  /// ### Distinction from errors
  ///
  /// - **Error:** A single operation failed; the app continues.
  /// - **Fatal:** The entire application may be compromised.
  /// {@endtemplate}
  FATAL(5, 'FATAL'),

  /// {@template log_level_off}
  /// Disables all logging output entirely.
  ///
  /// When the current level is set to `OFF`, no log messages are displayed
  /// regardless of their level. This is useful for production environments
  /// where logging is handled externally, or for silent modes during
  /// testing.
  ///
  /// **Integer value:** 6
  ///
  /// ### When to use
  /// - Production environments with external logging
  /// - Silent test modes
  /// - Performance-critical sections
  /// - When logging would interfere with output parsing
  ///
  /// ### Example
  /// ```dart
  /// LogConfig.currentLevel = LogLevel.OFF;
  /// // No log messages will be displayed
  /// ```
  ///
  /// ### Caveats
  ///
  /// - Fatal errors are still suppressed — consider carefully before
  ///   using `OFF` in production
  /// - Use environment-based configuration to allow override
  /// - Some monitoring tools may depend on log output
  /// {@endtemplate}
  OFF(6, 'OFF');

  /// {@template log_level_constructor}
  /// Constructs a [LogLevel] with an associated integer [value] and
  /// human-readable [name].
  ///
  /// ### Parameters
  ///
  /// - [value]: Integer used for comparison. Lower values mean lower
  ///   severity. Must be unique across all levels.
  /// - [name]: Display name for the level (e.g., `'INFO'`, `'ERROR'`).
  ///   Used in formatted output and `toString()`.
  ///
  /// ### Example
  /// ```dart
  /// // Custom level (if extended)
  /// const LogLevel CUSTOM = LogLevel(7, 'CUSTOM');
  /// ```
  ///
  /// ### Constraints
  ///
  /// This constructor is `const` and can only be used with compile-time
  /// constant values.
  /// {@endtemplate}
  /// {@macro log_level}
  const LogLevel(this.value, this.name);

  /// {@template log_level_value}
  /// Integer value used for severity comparison.
  ///
  /// Lower values indicate lower severity. The value determines whether
  /// a message passes the current level filter:
  ///
  /// ```
  /// message passes if: messageLevel.value >= currentLevel.value
  /// ```
  ///
  /// ### Values
  ///
  /// | Level   | Value |
  /// |---------|-------|
  /// | TRACE   | 0     |
  /// | DEBUG   | 1     |
  /// | INFO    | 2     |
  /// | WARN    | 3     |
  /// | ERROR   | 4     |
  /// | FATAL   | 5     |
  /// | OFF     | 6     |
  ///
  /// ### Comparison
  ///
  /// ```dart
  /// LogLevel.WARN.value > LogLevel.INFO.value; // true
  /// LogLevel.DEBUG.value < LogLevel.ERROR.value; // true
  /// ```
  /// {@endtemplate}
  final int value;

  /// {@template log_level_name}
  /// Human-readable display name for the log level.
  ///
  /// Used in formatted log output and returned by [toString]. The name
  /// is typically uppercase (e.g., `'INFO'`, `'ERROR'`).
  ///
  /// ### Example
  /// ```dart
  /// print(LogLevel.WARN.name); // 'WARNING'
  /// print(LogLevel.FATAL.name); // 'FATAL'
  /// ```
  ///
  /// ### Custom formatting
  ///
  /// For custom formatting, use the name directly:
  /// ```dart
  /// print('[${level.name}] $message');
  /// ```
  /// {@endtemplate}
  final String name;

  /// {@template log_level_isEnabledFor}
  /// Determines whether this log level is enabled given a minimum
  /// threshold [level].
  ///
  /// Returns `true` if this level's [value] is greater than or equal to
  /// [level]'s value. This is the primary mechanism for filtering log
  /// messages.
  ///
  /// ### Parameters
  ///
  /// - [level]: The minimum severity threshold. Messages at or above
  ///   this level are shown.
  ///
  /// ### Returns
  ///
  /// `true` if this level passes the filter; `false` otherwise.
  ///
  /// ### Example
  /// ```dart
  /// final currentLevel = LogLevel.INFO;
  ///
  /// LogLevel.TRACE.isEnabledFor(currentLevel); // false
  /// LogLevel.DEBUG.isEnabledFor(currentLevel); // false
  /// LogLevel.INFO.isEnabledFor(currentLevel);  // true
  /// LogLevel.WARN.isEnabledFor(currentLevel);  // true
  /// LogLevel.ERROR.isEnabledFor(currentLevel); // true
  /// LogLevel.FATAL.isEnabledFor(currentLevel); // true
  /// ```
  ///
  /// ### Usage in logging
  ///
  /// ```dart
  /// void logMessage(String message, LogLevel level) {
  ///   if (level.isEnabledFor(LogConfig.currentLevel)) {
  ///     print('[${level.name}] $message');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  bool isEnabledFor(LogLevel level) => value >= level.value;

  /// {@template log_level_toString}
  /// Returns the [name] of this log level as a string.
  ///
  /// This is useful for formatting log output and debugging:
  /// ```dart
  /// print(LogLevel.INFO); // 'INFO'
  /// print(LogLevel.FATAL); // 'FATAL'
  /// ```
  ///
  /// The returned string is the same as the [name] field.
  /// {@endtemplate}
  @override
  String toString() => name;
}