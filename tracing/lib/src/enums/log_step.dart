/// {@template log_step}
/// Defines individual components (steps) that can be included in formatted
/// log output.
///
/// `LogStep` controls the composition of each log message. By selecting
/// which steps to include and in what order, you can customize the
/// appearance of log output to suit your needs.
///
/// ### Default ordering
///
/// The [defaultSteps] getter provides a sensible ordering:
/// ```
/// DATE → TIMESTAMP → TAG → LEVEL → MESSAGE → THREAD → LOCATION → ERROR → STACKTRACE
/// ```
///
/// ### Custom ordering
///
/// Pass a custom list of steps to a printer:
/// ```dart
/// ConsolePrinter(
///   steps: [LogStep.LEVEL, LogStep.MESSAGE],
/// );
/// // Output: [INFO] User logged in
/// ```
///
/// ### Step categories
///
/// The steps can be grouped into three categories:
///
/// **Temporal:** [DATE], [TIMESTAMP]
/// **Contextual:** [TAG], [LEVEL], [THREAD], [LOCATION]
/// **Content:** [MESSAGE], [ERROR], [STACKTRACE]
/// {@endtemplate}
enum LogStep {
  /// {@template log_step_timestamp}
  /// Timestamp of the log, including both date and time.
  ///
  /// This step provides the full date-time string (e.g.,
  /// `'2026-07-26 14:30:45.123'`). The format depends on the
  /// configured date format in `LogConfig`.
  ///
  /// ### Example output
  /// ```
  /// 2026-07-26 14:30:45.123
  /// ```
  ///
  /// ### When to use
  ///
  /// Include this step when you need precise timing for debugging
  /// or when logs need to be correlated with external systems.
  ///
  /// ### Relationship with [DATE]
  ///
  /// - [TIMESTAMP]: Full date and time
  /// - [DATE]: Date portion only (no time)
  ///
  /// Use one or the other, not both, to avoid redundancy.
  /// {@endtemplate}
  TIMESTAMP,

  /// {@template log_step_date}
  /// Only the date portion of the timestamp (no time).
  ///
  /// This step provides just the date string (e.g., `'2026-07-26'`).
  /// Useful when the time is less important than the date, or when
  /// grouping logs by day.
  ///
  /// ### Example output
  /// ```
  /// 2026-07-26
  /// ```
  ///
  /// ### When to use
  ///
  /// - When logs are already timestamped elsewhere
  /// - When grouping by day is sufficient
  /// - When minimal log output is desired
  ///
  /// ### Relationship with [TIMESTAMP]
  ///
  /// - [DATE]: Date only
  /// - [TIMESTAMP]: Full date and time
  ///
  /// Use one or the other to avoid redundancy.
  /// {@endtemplate}
  DATE,

  /// {@template log_step_level}
  /// Log level indicator (e.g., INFO, ERROR), optionally with emoji.
  ///
  /// This step displays the severity level of the log message. The
  /// format depends on the printer configuration — some printers
  /// include emoji prefixes (e.g., `ℹ️ INFO`, `❌ ERROR`).
  ///
  /// ### Example output
  /// ```
  /// INFO
  /// [INFO]
  /// ℹ️ INFO
  /// ```
  ///
  /// ### When to use
  ///
  /// This is one of the most important steps and should almost always
  /// be included. It allows quick visual scanning of log output.
  ///
  /// ### Customization
  ///
  /// The display format can be customized via `LogConfig.levelFormat`:
  /// - `LevelFormat.name`: Just the name (`INFO`)
  /// - `LevelFormat.nameWithEmoji`: Name with emoji (`ℹ️ INFO`)
  /// - `LevelFormat.value`: Numeric value (`2`)
  /// {@endtemplate}
  LEVEL,

  /// {@template log_step_tag}
  /// Optional user-defined tag or logger name to identify the log source.
  ///
  /// Tags help categorize logs by source class, feature, or module. They
  /// are especially useful in applications with multiple log producers.
  ///
  /// ### Example output
  /// ```
  /// [ZapClient] INFO Request sent
  /// [AuthService] DEBUG Token refreshed
  /// ```
  ///
  /// ### When to use
  ///
  /// - When multiple classes produce logs
  /// - When filtering logs by feature/module
  /// - When correlating logs with specific components
  ///
  /// ### Setting a tag
  ///
  /// ```dart
  /// Z.info('Connected', from: 'ZapClient');
  /// console.info('Token refreshed', tag: 'AuthService');
  /// ```
  ///
  /// ### Filtering by tag
  ///
  /// Some printers support tag-based filtering:
  /// ```dart
  /// ConsolePrinter(
  ///   filterTags: {'ZapClient', 'AuthService'},
  /// );
  /// ```
  /// {@endtemplate}
  TAG,

  /// {@template log_step_thread}
  /// Indicates the thread or isolate where the log originated.
  ///
  /// This step displays the isolate ID or thread name, which is useful
  /// for debugging concurrent operations and multi-isolate applications.
  ///
  /// ### Example output
  /// ```
  /// [main] INFO App started
  /// [isolate-1] DEBUG Background task completed
  /// ```
  ///
  /// ### When to use
  ///
  /// - Debugging concurrent operations
  /// - Monitoring background isolates
  /// - Diagnosing race conditions
  /// - Multi-threaded server applications
  ///
  /// ### Dart isolate context
  ///
  /// In Dart, each isolate has its own memory and event loop. This step
  /// helps identify which isolate produced a log message, which is
  /// critical for debugging isolate-based architectures.
  /// {@endtemplate}
  THREAD,

  /// {@template log_step_location}
  /// Represents the code location where the log was triggered.
  ///
  /// This step displays the file name, line number, and optionally the
  /// function name where the log call was made. The location is
  /// automatically extracted from the stack trace.
  ///
  /// ### Example output
  /// ```
  /// main.dart:42 User logged in
  /// services/api.dart:128 Request failed
  /// ```
  ///
  /// ### When to use
  ///
  /// - When you need to know exactly where a log was generated
  /// - When debugging complex call stacks
  /// - When correlating logs with source code
  ///
  /// ### Performance note
  ///
  /// Extracting location information requires inspecting the stack trace,
  /// which has a small performance cost. Consider disabling this step in
  /// performance-critical code paths.
  ///
  /// ### Configuration
  ///
  /// The location format can be customized via `LogConfig.locationFormat`:
  /// - `LocationFormat.fileAndLine`: `main.dart:42`
  /// - `LocationFormat.full`: `main.dart:42 in _buildRequestHeaders`
  /// {@endtemplate}
  LOCATION,

  /// {@template log_step_message}
  /// The main log message or content.
  ///
  /// This is the primary content of the log entry — the actual information
  /// being communicated. It is typically a string, but can be any object
  /// that is converted to a string for display.
  ///
  /// ### Example output
  /// ```
  /// User logged in successfully
  /// Request to /users returned 200
  /// Cache hit for key: user_123
  /// ```
  ///
  /// ### When to use
  ///
  /// This step should almost always be included. It is the core of every
  /// log message.
  ///
  /// ### Best practices
  ///
  /// - Be concise but descriptive
  /// - Include relevant context (IDs, counts, durations)
  /// - Use structured data when possible
  /// - Avoid sensitive information (passwords, tokens)
  ///
  /// ### Example
  /// ```dart
  /// Z.info('User ${user.id} logged in from ${user.ip}');
  /// Z.warn('Response time ${elapsed}ms exceeds threshold of ${threshold}ms');
  /// ```
  /// {@endtemplate}
  MESSAGE,

  /// {@template log_step_error}
  /// Any error object attached to the log event.
  ///
  /// This step displays the error that was caught or reported. It includes
  /// the error type and message, providing context for the failure.
  ///
  /// ### Example output
  /// ```
  /// SocketException: Connection refused
  /// FormatException: Unexpected character
  /// ```
  ///
  /// ### When to use
  ///
  /// Include this step when logging caught exceptions or error conditions:
  /// ```dart
  /// try {
  ///   await apiCall();
  /// } catch (e) {
  ///   Z.error('API call failed', error: e);
  /// }
  /// ```
  ///
  /// ### Relationship with [STACKTRACE]
  ///
  /// - [ERROR]: The error object itself
  /// - [STACKTRACE]: The call stack at the time of the error
  ///
  /// Include both for complete error context.
  /// {@endtemplate}
  ERROR,

  /// {@template log_step_stacktrace}
  /// A stack trace, usually included when an error is present.
  ///
  /// This step displays the call stack at the time the log was created.
  /// Stack traces are essential for debugging because they show the
  /// sequence of function calls that led to the error.
  ///
  /// ### Example output
  /// ```
  /// #0      ApiClient._sendRequest (package:app/api.dart:42:5)
  /// #1      ApiClient.get (package:app/api.dart:28:20)
  /// #2      HomePage._loadData (package:app/pages/home.dart:55:30)
  /// ```
  ///
  /// ### When to use
  ///
  /// - When logging caught exceptions
  /// - When debugging unexpected behavior
  /// - When the call chain is not obvious from the message alone
  ///
  /// ### Relationship with [ERROR]
  ///
  /// - [STACKTRACE]: The call stack
  /// - [ERROR]: The error object
  ///
  /// Include both for complete error context.
  ///
  /// ### Performance note
  ///
  /// Stack traces can be large and expensive to capture. Only include
  /// them when they provide value (e.g., for errors, not for info
  /// messages).
  /// {@endtemplate}
  STACKTRACE;

  /// {@template log_step_defaultSteps}
  /// Default ordering and selection of log steps used by printers unless
  /// explicitly overridden by the caller.
  ///
  /// The default order is:
  /// ```
  /// DATE → TIMESTAMP → TAG → LEVEL → MESSAGE → THREAD → LOCATION → ERROR → STACKTRACE
  /// ```
  ///
  /// ### Example usage
  ///
  /// ```dart
  /// // Use default steps
  /// ConsolePrinter(); // uses defaultSteps
  ///
  /// // Custom steps
  /// ConsolePrinter(
  ///   steps: [LogStep.TIMESTAMP, LogStep.LEVEL, LogStep.MESSAGE],
  /// );
  /// ```
  ///
  /// ### Customization
  ///
  /// You can reorder, include, or exclude steps:
  /// ```dart
  /// // Minimal logging
  /// ConsolePrinter(steps: [LogStep.LEVEL, LogStep.MESSAGE]);
  ///
  /// // Verbose logging
  /// ConsolePrinter(steps: LogStep.defaultSteps);
  /// ```
  ///
  /// ### Why this ordering?
  ///
  /// The default order follows a natural reading flow:
  /// 1. **When** it happened (DATE, TIMESTAMP)
  /// 2. **Who** produced it (TAG)
  /// 3. **How severe** it is (LEVEL)
  /// 4. **What** happened (MESSAGE)
  /// 5. **Where** it happened (THREAD, LOCATION)
  /// 6. **What went wrong** (ERROR, STACKTRACE)
  /// {@endtemplate}
  static List<LogStep> get defaultSteps => [
    DATE,
    TIMESTAMP,
    TAG,
    LEVEL,
    MESSAGE,
    THREAD,
    LOCATION,
    ERROR,
    STACKTRACE,
  ];
}