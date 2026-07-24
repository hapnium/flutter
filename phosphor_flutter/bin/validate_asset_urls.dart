import 'dart:io';
import 'dart:async';

import 'src/phosphor_parser.dart';

/// Validates that all upstream Phosphor Icons SVG URLs referenced in the
/// generated doc comments actually exist (return HTTP 200).
///
/// Run this after adding new icons to `phosphor.dart` and regenerating
/// to verify the SVGs are available upstream before publishing.
///
/// Usage:
/// ```sh
/// dart run bin/validate_asset_urls.dart
/// ```
const _upstreamBaseUrl =
    'https://raw.githubusercontent.com/phosphor-icons/core/main/assets';

const _styles = ['regular', 'thin', 'light', 'bold', 'fill', 'duotone'];

String _svgUrl(String iconName, String style) {
  if (style == 'regular') {
    return '$_upstreamBaseUrl/regular/$iconName.svg';
  }
  return '$_upstreamBaseUrl/$style/$iconName-$style.svg';
}

Future<void> main() async {
  final icons = parsePhosphorClass('lib/src/phosphor.dart');
  print('Validating SVG URLs for ${icons.length} icons across ${_styles.length} styles...\n');

  var checked = 0;
  var failed = 0;
  final failures = <String>[];

  for (final icon in icons) {
    for (final style in _styles) {
      final url = _svgUrl(icon.name, style);
      checked++;

      try {
        final request = await HttpClient().getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != 200) {
          failed++;
          failures.add('${icon.name}/$style → ${response.statusCode}');
        }
        await response.drain<void>();
      } catch (e) {
        failed++;
        failures.add('${icon.name}/$style → $e');
      }

      // Print progress every 100 checks
      if (checked % 100 == 0) {
        print('  Checked $checked / ${icons.length * _styles.length}...');
      }
    }
  }

  print('\nResults:');
  print('  Total: $checked');
  print('  Passed: ${checked - failed}');
  print('  Failed: $failed');

  if (failures.isNotEmpty) {
    print('\nFailed URLs:');
    for (final f in failures) {
      print('  ✗ $f');
    }
    exit(1);
  } else {
    print('\n✓ All SVG URLs are valid.');
  }
}
