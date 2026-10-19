import 'dart:io';

/// One-time utility script: updates SVG documentation URLs in generated
/// style class files to point to the upstream Phosphor Icons core repository.
///
/// This script rewrites relative asset paths to absolute raw GitHub URLs
/// pointing to the official Phosphor Icons SVG assets so that icon preview
/// images render correctly in generated Dart doc comments.
///
/// Usage:
/// ```sh
/// dart run bin/fix_doc_urls.dart
/// ```
///
/// Typically you only need to run this once after the initial code generation,
/// or whenever the upstream repository URL changes.
void main() {
  final srcDir = Directory('lib/src');
  const baseUrl =
      'https://raw.githubusercontent.com/phosphor-icons/core/main/assets';

  var filesUpdated = 0;

  for (final file in srcDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('phosphor_icon_data.dart')) continue;
    if (file.path.endsWith('phosphor_icon.dart')) continue;
    if (file.path.endsWith('phosphor_icons.dart')) continue;

    var content = file.readAsStringSync();

    // Match old Hapnium repo URLs:
    //   https://raw.githubusercontent.com/Hapnium/flutter/main/phosphor_flutter/assets/icons/{style}/{name}.svg
    final updated = content.replaceAllMapped(
      RegExp(
        r'!\[([^\]]+)\]\(https://raw\.githubusercontent\.com/Hapnium/flutter/main/phosphor_flutter/assets/icons/(\w+)/([^\)]+)\)',
      ),
      (match) {
        final name = match.group(1)!;
        final style = match.group(2)!;
        final filename = match.group(3)!;

        // Extract the base icon name (remove style suffix if present)
        String iconName = filename;
        if (style != 'regular' && iconName.endsWith('-$style')) {
          iconName = iconName.substring(0, iconName.length - style.length - 1);
        }

        // Build upstream URL
        String upstreamUrl;
        if (style == 'regular') {
          upstreamUrl = '$baseUrl/regular/$iconName.svg';
        } else {
          upstreamUrl = '$baseUrl/$style/$iconName-$style.svg';
        }

        return '![$name]($upstreamUrl)';
      },
    );

    if (updated != content) {
      file.writeAsStringSync(updated);
      filesUpdated++;
      print('  Updated ${file.path}');
    }
  }

  print('\nDone. Updated $filesUpdated files.');
}