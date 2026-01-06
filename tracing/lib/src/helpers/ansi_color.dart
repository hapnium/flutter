/// {@template ansiColor}
/// A utility class to apply ANSI terminal color codes to strings.
///
/// This is useful for enhancing log output or command-line interfaces with
/// colored messages for better readability and severity-level distinction.
///
/// It supports both foreground and background color settings using ANSI 256-color codes.
///
/// Example usage:
/// ```dart
/// final color = AnsiColor.fg(34); // Bright blue text
/// print(color('This text is blue'));
/// ```
/// {@endtemplate}
class AnsiColor {
  /// The ANSI escape sequence introducer. Signals the terminal that a control sequence follows.
  static const ansiEsc = '\x1B[';

  /// ANSI sequence to reset all styles, colors, and attributes to default.
  static const ansiDefault = '${ansiEsc}0m';

  /// Foreground color (text color), represented by a 256-color ANSI code.
  ///
  /// If `null`, no foreground color is applied.
  final int? fg;

  /// Background color, represented by a 256-color ANSI code.
  ///
  /// If `null`, no background color is applied.
  final int? bg;

  /// Whether colorization is enabled.
  ///
  /// If `false`, no ANSI codes will be applied to strings.
  final bool color;

  /// {@macro ansiColor}
  ///
  /// Creates an [AnsiColor] with optional background and foreground colors.
  ///
  /// Set [color] to `true` to enable color output.
  const AnsiColor({this.bg, this.fg, this.color = false});

  /// {@macro ansiColor}
  ///
  /// Creates an [AnsiColor] instance with no foreground or background color.
  ///
  /// This is effectively a no-op color.
  const AnsiColor.none()
      : fg = null,
        bg = null,
        color = false;

  /// {@macro ansiColor}
  ///
  /// Creates an [AnsiColor] with only a foreground color.
  ///
  /// Automatically enables color output.
  const AnsiColor.fg(this.fg)
      : bg = null,
        color = true;

  /// {@macro ansiColor}
  ///
  /// Creates an [AnsiColor] with only a background color.
  ///
  /// Automatically enables color output.
  const AnsiColor.bg(this.bg)
      : fg = null,
        color = true;

  /// Converts this instance to a foreground-only [AnsiColor] using the background color.
  ///
  /// Useful when you want to apply the same color as a foreground instead.
  AnsiColor toFg() => AnsiColor.fg(bg);

  /// Converts this instance to a background-only [AnsiColor] using the foreground color.
  ///
  /// Useful when you want to reverse the color to be a background.
  AnsiColor toBg() => AnsiColor.bg(fg);

  /// ANSI escape sequence to reset the foreground color to default.
  ///
  /// Does not affect the background.
  String get resetForeground => color ? '${ansiEsc}39m' : '';

  /// ANSI escape sequence to reset the background color to default.
  ///
  /// Does not affect the foreground.
  String get resetBackground => color ? '${ansiEsc}49m' : '';

  /// Returns the ANSI escape code string that applies this color configuration.
  ///
  /// If no colors are set, returns an empty string.
  @override
  String toString() {
    if (fg != null) {
      return '${ansiEsc}38;5;${fg}m';
    } else if (bg != null) {
      return '${ansiEsc}48;5;${bg}m';
    } else {
      return '';
    }
  }

  /// Applies the ANSI color codes to the provided [msg] and resets formatting after.
  ///
  /// If [color] is `false`, the original message is returned unmodified.
  ///
  /// Example:
  /// ```dart
  /// final red = AnsiColor.fg(9);
  /// print(red('Error!')); // Prints in red
  /// ```
  String call(String msg) {
    if (color) {
      return '$this$msg$ansiDefault';
    } else {
      return msg;
    }
  }

  /// Computes a grey shade ANSI color code based on a normalized [level] from 0.0 to 1.0.
  ///
  /// The result will be an integer ANSI code in the 232–255 grayscale range.
  static int grey(double level) => 232 + (level.clamp(0.0, 1.0) * 23).round();
}