/// {@template log_type}
/// Specifies the overall formatting strategy used for log output.
///
/// `LogType` determines how verbose, styled, or structured the logs are.
/// Each printer implementation maps to one or more `LogType` values,
/// providing different visual representations of the same log data.
///
/// ### Categories
///
/// The types can be grouped into three categories:
///
/// **Flat formats:** [FLAT], [FLAT_STRUCTURED], [PREFIX], [FMT], [SIMPLE]
/// Simple, single-line output with minimal decoration.
///
/// **Pretty formats:** [PRETTY], [PRETTY_STRUCTURED]
/// Styled, boxed output with visual hierarchy.
///
/// **Hybrid formats:** [HYBRID]
/// Combines elements of flat and pretty styles.
///
/// ### Selection guide
///
/// | Use case                        | Recommended type          |
/// |---------------------------------|---------------------------|
/// | Development debugging           | [PRETTY]                  |
/// | Production logging              | [FLAT] or [SIMPLE]        |
/// | Structured log ingestion        | [FLAT_STRUCTURED]         |
/// | CLI tools                       | [SIMPLE] or [FMT]         |
/// | Readable development            | [PRETTY_STRUCTURED]       |
/// | Flexible customization          | [HYBRID]                  |
/// | Prefix-based filtering          | [PREFIX]                  |
/// {@endtemplate}
enum LogType {
  /// {@template log_type_flat}
  /// Basic flat log format with minimal styling.
  ///
  /// Each log message is output as a single line with no visual
  /// decoration. This is the simplest and most compact format,
  /// suitable for production environments and log aggregation.
  ///
  /// ### Example output
  /// ```
  /// 2026-07-26 14:30:45 [INFO] User logged in
  /// 2026-07-26 14:30:46 [ERROR] Request failed: timeout
  /// ```
  ///
  /// ### When to use
  ///
  /// - Production environments
  /// - Log aggregation systems (ELK, Datadog, CloudWatch)
  /// - When minimal log output is desired
  /// - When logs are parsed by machines, not humans
  ///
  /// ### Characteristics
  ///
  /// - Single line per message
  /// - No ANSI color codes
  /// - No visual decoration
  /// - Machine-parseable
  /// - Minimal overhead
  /// {@endtemplate}
  FLAT,

  /// {@template log_type_flat_structured}
  /// Flat layout with structured key/value formatting.
  ///
  /// Like [FLAT], but includes structured data as key/value pairs.
  /// This format is ideal for log aggregation systems that support
  /// structured logging (e.g., JSON-based systems).
  ///
  /// ### Example output
  /// ```
  /// 2026-07-26 14:30:45 [INFO] user_id=123 action=login ip=192.168.1.1
  /// 2026-07-26 14:30:46 [ERROR] url=/api/users status=500 duration=1234ms
  /// ```
  ///
  /// ### When to use
  ///
  /// - Structured log ingestion (ELK, Splunk, Datadog)
  /// - When logs need to be queried by field
  /// - When building dashboards from log data
  /// - When correlating logs across services
  ///
  /// ### Characteristics
  ///
  /// - Single line per message
  /// - Key/value pairs for metadata
  /// - Machine-parseable
  /// - Query-friendly
  ///
  /// ### Example
  /// ```dart
  /// console.info('User logged in', tag: 'auth', data: {
  ///   'user_id': '123',
  ///   'ip': '192.168.1.1',
  ///   'method': 'oauth2',
  /// });
  /// ```
  /// {@endtemplate}
  FLAT_STRUCTURED,

  /// {@template log_type_pretty}
  /// Pretty format with boxed, styled output.
  ///
  /// Each log message is displayed with visual decoration including
  /// borders, colors, and spacing. This format is designed for human
  /// readability during development.
  ///
  /// ### Example output
  ///
  /// ```
  /// +-----------------------------------------+
  /// | INFO  2026-07-26 14:30:45               |
  /// | User logged in successfully              |
  /// | Tag: auth                                |
  /// +-----------------------------------------+
  /// +-----------------------------------------+
  /// | ERROR 2026-07-26 14:30:46               |
  /// | Request failed: timeout                  |
  /// | at: services/api.dart:42                 |
  /// +-----------------------------------------+
  /// ```
  ///
  /// ### When to use
  ///
  /// - Active development
  /// - Debugging sessions
  /// - When visual clarity is important
  /// - When presenting logs to developers
  ///
  /// ### Characteristics
  ///
  /// - Boxed output with borders
  /// - ANSI color codes
  /// - Emoji prefixes for levels
  /// - Visual hierarchy
  /// - Human-optimized
  ///
  /// ### Performance note
  ///
  /// Pretty formatting has higher overhead than flat formats due to
  /// string manipulation and ANSI code generation. Avoid using this
  /// format in production.
  /// {@endtemplate}
  PRETTY,

  /// {@template log_type_pretty_structured}
  /// Pretty format with structured sections and symbols.
  ///
  /// Like [PRETTY], but includes structured sections with visual
  /// separators and symbols. Each component of the log message is
  /// displayed in its own section for maximum clarity.
  ///
  /// ### Example output
  ///
  /// ```
  /// +--- INFO ---------------------------------+
  /// | 2026-07-26 14:30:45                      |
  /// | auth                                     |
  /// | User logged in successfully              |
  /// | at: services/auth.dart:128               |
  /// +------------------------------------------+
  /// ```
  ///
  /// ### When to use
  ///
  /// - Detailed debugging
  /// - When you need to see all metadata at a glance
  /// - When presenting logs to non-technical stakeholders
  /// - When visual hierarchy is critical
  ///
  /// ### Characteristics
  ///
  /// - Boxed output with rounded corners
  /// - Emoji-decorated sections
  /// - Structured metadata display
  /// - Maximum visual clarity
  /// {@endtemplate}
  PRETTY_STRUCTURED,

  /// {@template log_type_prefix}
  /// Prefix-based logs where each line begins with a level/tag.
  ///
  /// Each log message starts with a prefix containing the level and
  /// optional tag, followed by the message content. This format is
  /// useful for quick visual scanning and filtering.
  ///
  /// ### Example output
  ///
  /// ```
  /// [INFO]  User logged in
  /// [DEBUG] Cache hit for key: user_123
  /// [ERROR] Request failed: timeout
  /// [WARN]  Deprecated API usage detected
  /// ```
  ///
  /// ### When to use
  ///
  /// - Quick visual scanning of log output
  /// - When you need to identify the level at a glance
  /// - When logs are viewed in a terminal
  /// - When filtering by prefix is useful
  ///
  /// ### Characteristics
  ///
  /// - Prefix-based structure
  /// - Quick level identification
  /// - Compact format
  /// - Terminal-friendly
  ///
  /// ### Customization
  ///
  /// The prefix format can be customized:
  /// ```dart
  /// ConsolePrinter(
  ///   prefixFormat: '[${level.name}] ',
  /// );
  /// ```
  /// {@endtemplate}
  PREFIX,

  /// {@template log_type_fmt}
  /// printf-style formatting with placeholders and patterns.
  ///
  /// Uses format strings with placeholders (like `printf` in C) to
  /// produce structured output. This format is familiar to developers
  /// from other languages and is useful for precise output control.
  ///
  /// ### Example output
  ///
  /// ```
  /// [2026-07-26 14:30:45] [INFO]  User logged in from 192.168.1.1
  /// [2026-07-26 14:30:46] [ERROR] Request to /api/users failed with status 500
  /// ```
  ///
  /// ### When to use
  ///
  /// - When you need precise output formatting
  /// - When migrating from C/C++ logging systems
  /// - When building custom log formatters
  /// - When output must match a specific pattern
  ///
  /// ### Characteristics
  ///
  /// - Format string support
  /// - Placeholder-based output
  /// - Flexible formatting
  /// - Familiar to C developers
  ///
  /// ### Example
  ///
  /// ```dart
  /// console.fmt('User %s logged in from %s', [user.name, user.ip]);
  /// ```
  /// {@endtemplate}
  FMT,

  /// {@template log_type_simple}
  /// Compact single-line logs suitable for CLI or minimal environments.
  ///
  /// The most minimal format -- just the essential information in a
  /// single line. Designed for environments where log output should
  /// be as compact as possible.
  ///
  /// ### Example output
  ///
  /// ```
  /// INFO User logged in
  /// ERROR Request failed
  /// ```
  ///
  /// ### When to use
  ///
  /// - CLI tools
  /// - Minimal environments
  /// - When log output should be compact
  /// - When parsing is done by external tools
  ///
  /// ### Characteristics
  ///
  /// - Minimal format
  /// - No decoration
  /// - Essential information only
  /// - Compact output
  ///
  /// ### Distinction from [FLAT]
  ///
  /// - [FLAT]: Includes timestamp and other metadata
  /// - [SIMPLE]: Only level and message
  /// {@endtemplate}
  SIMPLE,

  /// {@template log_type_hybrid}
  /// Hybrid format combining flat and pretty elements.
  ///
  /// Uses flat formatting for the main content but adds pretty elements
  /// (colors, borders) for visual enhancement. This provides a balance
  /// between readability and compactness.
  ///
  /// ### Example output
  ///
  /// ```
  /// [INFO]  User logged in successfully
  ///         at: services/auth.dart:128
  /// [ERROR] Request failed: timeout
  ///         Duration: 1234ms
  /// ```
  ///
  /// ### When to use
  ///
  /// - When you want some visual enhancement without full pretty mode
  /// - When output needs to be both readable and compact
  /// - When transitioning between flat and pretty formats
  /// - When different sections need different formatting
  ///
  /// ### Characteristics
  ///
  /// - Mixed formatting style
  /// - Flat main content
  /// - Pretty accents for metadata
  /// - Balanced readability
  ///
  /// ### Customization
  ///
  /// The hybrid format can be extensively customized:
  /// ```dart
  /// ConsolePrinter(
  ///   type: LogType.HYBRID,
  ///   prettySections: {LogStep.ERROR, LogStep.STACKTRACE},
  /// );
  /// ```
  /// {@endtemplate}
  HYBRID,
}