import 'dart:io';

/// Writes [content] to the file at [path] with no trailing newline.
///
/// Used by the code generator to produce deterministic output that
/// `dart format` can later normalize without adding spurious newlines.
void writeGeneratedFile(String path, String content) {
  File(path).writeAsStringSync(content);
}

/// Runs `dart format` on the file at [path], then strips any trailing newline.
///
/// This ensures generated files end with `}` (no trailing `\n`),
/// which is the project convention for generated Dart code.
void formatDartFile(String path) {
  Process.runSync('dart', ['format', path]);
  var content = File(path).readAsStringSync();
  if (content.endsWith('\n')) {
    content = content.substring(0, content.length - 1);
  }
  File(path).writeAsStringSync(content);
}