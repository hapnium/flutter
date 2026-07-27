import 'package:test/test.dart';
import 'package:tracing/src/helpers/ansi_color.dart';

void main() {
  group('AnsiColor', () {
    group('constructors', () {
      test('default constructor sets null fg and bg', () {
        const color = AnsiColor();
        expect(color.fg, isNull);
        expect(color.bg, isNull);
        expect(color.color, isFalse);
      });

      test('none() constructor sets null fg, bg, and color false', () {
        const color = AnsiColor.none();
        expect(color.fg, isNull);
        expect(color.bg, isNull);
        expect(color.color, isFalse);
      });

      test('fg() constructor sets foreground and enables color', () {
        const color = AnsiColor.fg(9);
        expect(color.fg, 9);
        expect(color.bg, isNull);
        expect(color.color, isTrue);
      });

      test('bg() constructor sets background and enables color', () {
        const color = AnsiColor.bg(42);
        expect(color.fg, isNull);
        expect(color.bg, 42);
        expect(color.color, isTrue);
      });
    });

    group('toString', () {
      test('returns ANSI foreground escape code when fg is set', () {
        const color = AnsiColor.fg(9);
        expect(color.toString(), '\x1B[38;5;9m');
      });

      test('returns ANSI background escape code when bg is set', () {
        const color = AnsiColor.bg(42);
        expect(color.toString(), '\x1B[48;5;42m');
      });

      test('returns empty string when no color is set', () {
        const color = AnsiColor.none();
        expect(color.toString(), '');
      });
    });

    group('call', () {
      test('wraps message with ANSI codes when color is enabled', () {
        const color = AnsiColor.fg(9);
        final result = color('hello');
        expect(result, '\x1B[38;5;9mhello\x1B[0m');
      });

      test('returns message unmodified when color is disabled', () {
        const color = AnsiColor.none();
        final result = color('hello');
        expect(result, 'hello');
      });
    });

    group('toFg and toBg', () {
      test('toFg converts background to foreground', () {
        const color = AnsiColor.bg(42);
        final fg = color.toFg();
        expect(fg.fg, 42);
        expect(fg.bg, isNull);
        expect(fg.color, isTrue);
      });

      test('toBg converts foreground to background', () {
        const color = AnsiColor.fg(9);
        final bg = color.toBg();
        expect(bg.bg, 9);
        expect(bg.fg, isNull);
        expect(bg.color, isTrue);
      });
    });

    group('resetForeground and resetBackground', () {
      test('resetForeground returns ANSI reset code when color enabled', () {
        const color = AnsiColor.fg(9);
        expect(color.resetForeground, '\x1B[39m');
      });

      test('resetBackground returns ANSI reset code when color enabled', () {
        const color = AnsiColor.fg(9);
        expect(color.resetBackground, '\x1B[49m');
      });

      test('resetForeground returns empty when color disabled', () {
        const color = AnsiColor.none();
        expect(color.resetForeground, '');
      });

      test('resetBackground returns empty when color disabled', () {
        const color = AnsiColor.none();
        expect(color.resetBackground, '');
      });
    });

    group('grey', () {
      test('returns 232 for level 0.0', () {
        expect(AnsiColor.grey(0.0), 232);
      });

      test('returns 255 for level 1.0', () {
        expect(AnsiColor.grey(1.0), 255);
      });

      test('returns 243 for level 0.5', () {
        expect(AnsiColor.grey(0.5), 244);
      });

      test('clamps values below 0.0', () {
        expect(AnsiColor.grey(-0.5), 232);
      });

      test('clamps values above 1.0', () {
        expect(AnsiColor.grey(1.5), 255);
      });
    });
  });
}