import 'dart:io';

import 'phosphor_parser.dart';
import 'file_utils.dart';

/// Configuration for a single Phosphor icon weight style.
///
/// Each style (Regular, Thin, Light, Bold, Fill, Duotone) has its own
/// [className], [fontFamily], [fileName], [label], and [description]
/// used during code generation.
class StyleConfig {
  /// The name of the generated Dart class (e.g. `PhosphorIconsRegular`).
  final String className;

  /// The font family string used in [IconData] (e.g. `PhosphorRegular`).
  final String fontFamily;

  /// The output file name without extension (e.g. `phosphor_icons_regular`).
  final String fileName;

  /// A human-readable label for this weight (e.g. `Regular`, `Bold`).
  final String label;

  /// A rich description of this weight's visual characteristics, used in
  /// the generated `{@template}` doc comment.
  final String description;

  const StyleConfig(
    this.className,
    this.fontFamily,
    this.fileName,
    this.label,
    this.description,
  );
}

/// The six Phosphor icon weight styles, in generation order.
const styleConfigs = [
  StyleConfig(
    'PhosphorIconsRegular',
    'PhosphorRegular',
    'phosphor_icons_regular',
    'Regular',
    'The default weight, suitable for most use cases. Offers a balanced '
        'stroke width that pairs well with body text and UI elements.',
  ),
  StyleConfig(
    'PhosphorIconsThin',
    'PhosphorThin',
    'phosphor_icons_thin',
    'Thin',
    'A delicate, lightweight stroke ideal for large headings, hero sections, '
        'and decorative contexts where a refined appearance is desired.',
  ),
  StyleConfig(
    'PhosphorIconsLight',
    'PhosphorLight',
    'phosphor_icons_light',
    'Light',
    'A slightly heavier stroke than Thin, providing improved legibility '
        'while still maintaining an elegant, airy feel.',
  ),
  StyleConfig(
    'PhosphorIconsBold',
    'PhosphorBold',
    'phosphor_icons_bold',
    'Bold',
    'A thick, commanding stroke designed for emphasis, small sizes, '
        'and high-contrast interfaces where icons must stand out.',
  ),
  StyleConfig(
    'PhosphorIconsFill',
    'PhosphorFill',
    'phosphor_icons_fill',
    'Fill',
    'A solid, filled variant that replaces the outlined strokes with '
        'filled shapes. Useful for active states, selections, and toggles.',
  ),
  StyleConfig(
    'PhosphorIconsDuotone',
    'PhosphorDuotone',
    'phosphor_icons_duotone',
    'Duotone',
    'A two-tone variant that pairs a primary stroke with a secondary '
        'fill, adding depth and visual hierarchy to icon compositions.',
  ),
];

/// Base URL for upstream Phosphor Icons SVG assets.
const _upstreamBaseUrl =
    'https://raw.githubusercontent.com/phosphor-icons/core/main/assets';

/// Generates the 6 style class files in `lib/src/styles/`.
///
/// Each generated file contains an `abstract final class` annotated with
/// `@staticIconProvider`, holding a `static const IconData` for every icon
/// in the [Phosphor] source of truth.
void generateStyleClasses(List<IconEntry> icons) {
  final stylesDir = Directory('lib/src/styles');
  if (!stylesDir.existsSync()) {
    stylesDir.createSync(recursive: true);
  }

  for (final config in styleConfigs) {
    _generateStyleFile(icons, config);
  }
}

/// Derives the subdirectory name from a font family string.
///
/// Example: `'PhosphorRegular'` → `'regular'`.
String _styleDirName(String fontFamily) {
  return fontFamily.replaceFirst('Phosphor', '').toLowerCase();
}

/// Builds the upstream SVG URL for a given icon name and style.
///
/// Regular weight uses `{name}.svg`, all other weights use `{name}-{weight}.svg`.
String _svgUrl(String iconName, String styleDir) {
  if (styleDir == 'regular') {
    return '$_upstreamBaseUrl/regular/$iconName.svg';
  }
  return '$_upstreamBaseUrl/$styleDir/$iconName-$styleDir.svg';
}

/// Generates a single style class file for the given [config].
///
/// The output includes:
/// - A `{@template}` / `{@endtemplate}` doc block on the class.
/// - A `{@macro}` doc on the constructor.
/// - One `static const IconData` per icon, referencing `Phosphor.<name>`.
void _generateStyleFile(List<IconEntry> icons, StyleConfig config) {
  final dirName = _styleDirName(config.fontFamily);
  final templateName = config.className.toLowerCase();
  final buf = StringBuffer();
  buf.write('// Auto generated File\n');
  buf.write('// DON\'T EDIT BY HAND\n');
  buf.write('\n');
  buf.write('import \'package:flutter/widgets.dart\';\n');
  buf.write('import \'package:phosphor_flutter/src/phosphor.dart\';\n');
  buf.write('\n');
  buf.write('const _fontFamily = "${config.fontFamily}";\n');
  buf.write('\n');
  buf.write('/// {@template $templateName}\n');
  buf.write('/// The ${config.label} weight variant of the Phosphor icon font family.\n');
  buf.write('///\n');
  buf.write('/// ${config.description}\n');
  buf.write('///\n');
  buf.write('/// Provides access to all [Phosphor] icons rendered in the ${config.label} weight.\n');
  buf.write('/// Use the static const fields on this class to obtain [IconData] values\n');
  buf.write('/// suitable for use with Flutter\'s [Icon] widget or [TextStyle.iconFontFamily].\n');
  buf.write('///\n');
  buf.write('/// Each icon constant is a fully configured [IconData] that includes the\n');
  buf.write('/// correct [fontFamily], [fontPackage], and [matchTextDirection] properties\n');
  buf.write('/// for the Phosphor ${config.label} font.\n');
  buf.write('///\n');
  buf.write('/// See also:\n');
  buf.write('///   - [PhosphorIconsRegular] for the Regular weight variant.\n');
  buf.write('///   - [PhosphorIconsThin] for the Thin weight variant.\n');
  buf.write('///   - [PhosphorIconsLight] for the Light weight variant.\n');
  buf.write('///   - [PhosphorIconsBold] for the Bold weight variant.\n');
  buf.write('///   - [PhosphorIconsFill] for the Fill weight variant.\n');
  buf.write('///   - [PhosphorIconsDuotone] for the Duotone weight variant.\n');
  buf.write('/// {@endtemplate}\n');
  buf.write('@staticIconProvider\n');
  buf.write('abstract final class ${config.className} {\n');
  buf.write('  /// {@macro $templateName}\n');
  buf.write('  const ${config.className}();\n');

  for (final icon in icons) {
    buf.write('\n');
    buf.write('  /// ![${icon.name}](${_svgUrl(icon.name, dirName)})\n');
    buf.write('  static const ${icon.name} = IconData(\n');
    buf.write('    Phosphor.${icon.name},\n');
    buf.write('    fontFamily: _fontFamily,\n');
    buf.write('    fontPackage: Phosphor.fontPackage,\n');
    buf.write('    matchTextDirection: true,\n');
    buf.write('  );\n');
  }

  buf.write('}');

  final path = 'lib/src/styles/${config.fileName}.dart';
  writeGeneratedFile(path, buf.toString());
  formatDartFile(path);
  print('  Generated $path');
}