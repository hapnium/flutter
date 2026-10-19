import 'phosphor_parser.dart';
import 'style_class_generator.dart';
import 'file_utils.dart';

/// Base URL for upstream Phosphor Icons SVG assets.
const _upstreamBaseUrl =
    'https://raw.githubusercontent.com/phosphor-icons/core/main/assets';

/// Builds the upstream SVG URL for a given icon name and style directory.
///
/// Regular weight uses `{name}.svg`, all other weights use `{name}-{weight}.svg`.
String _svgUrl(String iconName, String styleDir) {
  if (styleDir == 'regular') {
    return '$_upstreamBaseUrl/regular/$iconName.svg';
  }
  return '$_upstreamBaseUrl/$styleDir/$iconName-$styleDir.svg';
}

/// Generates the `PhosphorIcons` convenience class and `PhosphorIconsStyle`
/// enum in `lib/src/phosphor_icons.dart`.
///
/// The generated `PhosphorIcons` class provides static methods for every icon
/// (e.g. `PhosphorIcons.acorn([style])`) that dispatch to the correct style
/// class via a switch on [PhosphorIconsStyle].
///
/// The `PhosphorIconsStyle` enum lists the six available weight variants:
/// [regular], [thin], [light], [bold], [fill], [duotone].
void generatePhosphorIconsClass(List<IconEntry> icons) {
  final buf = StringBuffer();
  buf.write('// Auto generated File\n');
  buf.write('// DON\'T EDIT BY HAND\n');
  buf.write('\n');
  buf.write('import \'package:flutter/widgets.dart\';\n');

  for (final config in styleConfigs) {
    buf.write('import \'package:phosphor_flutter/src/styles/${config.fileName}.dart\';\n');
  }

  buf.write('\n');
  buf.write('/// {@template phosphor_icons_style}\n');
  buf.write('/// An enumeration of the available weight styles for Phosphor icons.\n');
  buf.write('///\n');
  buf.write('/// Each variant corresponds to a different visual weight of the icon glyphs,\n');
  buf.write('/// ranging from Thin (lightest) to Bold (heaviest), plus Fill and Duotone\n');
  buf.write('/// special variants.\n');
  buf.write('///\n');
  buf.write('/// Used with [PhosphorIcons] convenience methods to select the desired\n');
  buf.write('/// icon style at runtime.\n');
  buf.write('/// {@endtemplate}\n');
  buf.write('enum PhosphorIconsStyle {\n');
  buf.write('  /// The default weight, suitable for most use cases.\n');
  buf.write('  regular,\n');
  buf.write('\n');
  buf.write('  /// A delicate, lightweight stroke ideal for large headings.\n');
  buf.write('  thin,\n');
  buf.write('\n');
  buf.write('  /// A slightly heavier stroke than Thin with improved legibility.\n');
  buf.write('  light,\n');
  buf.write('\n');
  buf.write('  /// A thick, commanding stroke designed for emphasis.\n');
  buf.write('  bold,\n');
  buf.write('\n');
  buf.write('  /// A solid, filled variant for active states and selections.\n');
  buf.write('  fill,\n');
  buf.write('\n');
  buf.write('  /// A two-tone variant with primary stroke and secondary fill.\n');
  buf.write('  duotone,\n');
  buf.write('}\n');
  buf.write('\n');
  buf.write('/// {@template phosphor_icons}\n');
  buf.write('/// A convenience entry point for accessing Phosphor icons across all weight styles.\n');
  buf.write('///\n');
  buf.write('/// This class provides static methods that return the appropriate [IconData]\n');
  buf.write('/// for each icon based on the requested [PhosphorIconsStyle]. The default style\n');
  buf.write('/// is [PhosphorIconsStyle.regular].\n');
  buf.write('///\n');
  buf.write('/// For direct access to a specific style\'s full icon set, use the\n');
  buf.write('/// corresponding style class instead:\n');

  for (final config in styleConfigs) {
    buf.write('///   - [${config.className}]\n');
  }

  buf.write('///\n');
  buf.write('/// Example:\n');
  buf.write('/// ```dart\n');
  buf.write('/// // Using the convenience accessor:\n');
  buf.write('/// Icon(PhosphorIcons.acorn(PhosphorIconsStyle.bold));\n');
  buf.write('///\n');
  buf.write('/// // Using a specific style class directly:\n');
  buf.write('/// Icon(PhosphorIconsBold.acorn);\n');
  buf.write('/// ```\n');
  buf.write('/// {@endtemplate}\n');
  buf.write('abstract final class PhosphorIcons {\n');

  for (final icon in icons) {
    buf.write('\n');
    buf.write('  /// regular: ![${icon.name}](${_svgUrl(icon.name, 'regular')})\n');
    buf.write('  /// thin: ![${icon.name}](${_svgUrl(icon.name, 'thin')})\n');
    buf.write('  /// light: ![${icon.name}](${_svgUrl(icon.name, 'light')})\n');
    buf.write('  /// bold: ![${icon.name}](${_svgUrl(icon.name, 'bold')})\n');
    buf.write('  /// fill: ![${icon.name}](${_svgUrl(icon.name, 'fill')})\n');
    buf.write('  /// duotone: ![${icon.name}](${_svgUrl(icon.name, 'duotone')})\n');
    buf.write('  static IconData ${icon.name}([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) {\n');
    buf.write('    switch (style) {\n');

    for (final config in styleConfigs) {
      final styleName = config.className
          .replaceFirst('PhosphorIcons', '')
          .toLowerCase();
      buf.write('      case PhosphorIconsStyle.$styleName:\n');
      buf.write('        return ${config.className}.${icon.name};\n');
    }

    buf.write('    }\n');
    buf.write('  }\n');
  }

  buf.write('}');

  final path = 'lib/src/phosphor_icons.dart';
  writeGeneratedFile(path, buf.toString());
  formatDartFile(path);
  print('  Generated $path');
}