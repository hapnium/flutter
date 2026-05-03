# tracing

Structured logging for Dart / Flutter: **levels**, **listeners**, **printers**, **`LogConfig`**, and optional **tags**, **errors**, and **stack traces**. The global **`console`** is a **`Tracing`** instance.

**Import:** `package:tracing/tracing.dart`

> Internal docs sometimes say “logger”; the package name is **`tracing`**.

---

## `Tracing` class

| Method | Level | Description |
|--------|-------|-------------|
| **`info(message, {tag, error, stackTrace})`** | `INFO` | Normal operational messages. |
| **`debug(...)`** | `DEBUG` | Verbose development logs. |
| **`trace(...)`** | `TRACE` | Fine-grained flow. |
| **`warn(...)`** | `WARN` | Recoverable issues. |
| **`error(...)`** | `ERROR` | Failures needing attention. |
| **`fatal(...)`** | `FATAL` | Critical failures. |
| **`log(..., {level})`** | configurable | Log with explicit **`LogLevel`**. |
| **`addListener(TracingListener listener)`** | — | Replace the active listener (strategy). |

**Constructor `Tracing({...})`** creates **`DefaultTracingListener`** with:

| Parameter | Effect |
|-----------|--------|
| **`level`** | Minimum **`LogLevel`** (filter in listener). |
| **`printer`** | Custom **`LogPrinter`**; overrides **`type`** if set. |
| **`type`** | **`LogType`** → built-in printer (see below). |
| **`output`** | `void Function(String)` per line; default **`print`**. |
| **`name`** | Default logger/tag name when **`tag`** omitted. |
| **`config`** | **`LogConfig`** passed into built-in printers. |

**Global:** **`final console = Tracing();`** — same API as **`Tracing`**.

---

## `TracingListener` and `onLog`

**`TracingListener`** is the strategy interface. Subclasses use the constructor with **`level`**, **`printer`** / **`type`**, **`output`**, **`name`**, **`config`**.

**`onLog(LogLevel level, dynamic message, {String? tag, Object? error, StackTrace? stackTrace})`**:

1. If **`!_level.isEnabledFor(level)`** → return.
2. Builds **`LogRecord`** (`message.toString()`, **`loggerName: tag ?? _name`**, **`error`**, **`stackTrace`**).
3. Calls **`_printer.log(record)`** → `List<String>` lines.
4. Sends each line to **`_output`** or **`print`**.

Implement a **custom listener** by extending **`TracingListener`** and overriding **`onLog`** if you need non-printer routing (metrics, remote sink without string formatting).

---

## `LogPrinter` and `LogType`

**`LogPrinter`** — implement **`List<String> log(LogRecord record)`**.

**Built-in mapping** (`TracingListener` constructor):

| `LogType` | Printer class |
|-----------|----------------|
| `SIMPLE` | `SimplePrinter` |
| `FLAT` | `FlatPrinter` |
| `FLAT_STRUCTURED` | `FlatStructuredPrinter` |
| `PRETTY` | `PrettyPrinter` |
| `PRETTY_STRUCTURED` | `PrettyStructuredPrinter` |
| `PREFIX` | `PrefixPrinter` |
| `FMT` | `FmtPrinter` |
| `HYBRID` | `HybridPrinter` |

All are constructed with **`LogConfig`** (timestamps, colors, **`LogStep`** inclusion, etc. — see **`log_config.dart`** and **`log_step.dart`**).

---

## `LogRecord` (key fields)

| Field | Meaning |
|-------|---------|
| **`level`** | **`LogLevel`**. |
| **`message`** | String body. |
| **`loggerName`** | Tag / source. |
| **`time`** | **`DateTime`**. |
| **`error`** | Optional **`Object`**. |
| **`stackTrace`** | Optional **`StackTrace`**. |

Printers may use **`StackTraceParser`** helpers for pretty output.

---

## `LogLevel` / `LogStep`

- **`LogLevel`**: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL` — **`isEnabledFor`** defines filtering relative to configured minimum.
- **`LogStep`**: which parts of a line to include (message, time, level, error, …) — used by **`LogConfig`**.

---

## Integration note (`smart` package)

**`package:smart/smart.dart`** re-exports **`tracing`** but **hides `console`**. Use **`import 'package:tracing/tracing.dart';`** when you need the global **`console`**.

---

## Installation (private monorepo)

```yaml
dependencies:
  tracing:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: tracing
```

---

## License

See [LICENSE](LICENSE) in this package directory.
