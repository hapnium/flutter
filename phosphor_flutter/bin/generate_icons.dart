/// Code generator for the phosphor_flutter package.
///
/// Parses the hand-maintained [Phosphor] class in `lib/src/phosphor.dart`
/// to extract icon code points, then generates:
///
/// - **6 style classes** (`PhosphorIconsRegular`, `PhosphorIconsThin`, etc.)
///   in `lib/src/styles/`, each containing [IconData] constants for every icon.
/// - **`PhosphorIcons`** in `lib/src/phosphor_icons.dart`, a convenience class
///   with switch-based methods that dispatch to the correct style class.
///
/// Run from the package root:
/// ```sh
/// dart run bin/generate_icons.dart
/// ```
///
/// After running, verify with:
/// ```sh
/// flutter test
/// dart analyze
/// ```
import 'src/phosphor_parser.dart';
import 'src/style_class_generator.dart';
import 'src/base_class_generator.dart';

void main() {
  final icons = parsePhosphorClass('lib/src/phosphor.dart');
  print('Parsed ${icons.length} icons from Phosphor class.\n');

  print('Generating style classes...');
  generateStyleClasses(icons);

  print('\nGenerating PhosphorIcons class...');
  generatePhosphorIconsClass(icons);

  print('\nDone. Generated ${icons.length} icons across 7 files.');
}