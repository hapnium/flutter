import 'dart:io';

/// A single icon entry parsed from the [Phosphor] class.
///
/// Each entry maps a Dart identifier (e.g. `acorn`) to its Unicode
/// code point (e.g. `0xeb9a`).
class IconEntry {
  /// The Dart identifier for this icon (e.g. `acorn`, `addressBook`).
  final String name;

  /// The Unicode code point (e.g. `0xeb9a`).
  final int codePoint;

  const IconEntry(this.name, this.codePoint);
}

/// Parses the hand-maintained [Phosphor] class file and extracts all icon
/// entries as [IconEntry] objects.
///
/// The parser reads `static const int <name> = 0x<hex>;` lines from
/// [filePath] and returns a list of [IconEntry] instances suitable for
/// code generation.
///
/// Throws [FileSystemException] if [filePath] does not exist.
List<IconEntry> parsePhosphorClass(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw FileSystemException('Phosphor class not found', filePath);
  }

  final lines = file.readAsLinesSync();
  final entries = <IconEntry>[];
  String? pendingName;

  for (final line in lines) {
    final nameMatch =
        RegExp(r'static const int (\w+) = ').firstMatch(line);
    if (nameMatch != null) {
      pendingName = nameMatch.group(1);
      final codeMatch = RegExp(r'= (0x[0-9a-fA-F]+);').firstMatch(line);
      if (codeMatch != null) {
        entries.add(IconEntry(
          pendingName!,
          int.parse(codeMatch.group(1)!),
        ));
        pendingName = null;
      }
    }
  }

  return entries;
}