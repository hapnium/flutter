/// Finds text files that end with a newline (LF/CRLF at EOF) and removes it.
///
/// Usage:
///   dart run tool/strip_trailing_newlines.dart [paths...] [options]
///
/// Options:
///   --check         Report only; exit code 1 when any file has a trailing
///                   newline (useful in CI). Files are never modified.
///   --all           Consider every file, not just known text extensions
///                   (files containing NUL bytes are skipped as binary).
///   --ext=dart,md   Override the default extension allowlist (comma
///                   separated, with or without leading dots).
///   -h, --help      Show this help.
///
/// Paths default to the current directory. Directories are walked
/// recursively; symlinked directories are not followed. The noise
/// directories below are always skipped:
///   .git  .dart_tool  .idea  .vscode  build  node_modules  Pods  coverage
///
/// Examples:
///   dart run tool/strip_trailing_newlines.dart --check          # CI report
///   dart run tool/strip_trailing_newlines.dart                 # fix current dir
///   dart run tool/strip_trailing_newlines.dart zap/lib --ext=dart
///
/// The script edits files at the byte level: every trailing 0x0A / 0x0D byte
/// run at EOF is removed and nothing else about the file is touched, so
/// encodings, line endings inside the file, and content are preserved
/// exactly.
library;

import 'dart:io';

const Set<String> _skipDirs = {
  '.git',
  '.dart_tool',
  '.idea',
  '.vscode',
  'build',
  'node_modules',
  'Pods',
  'coverage',
};

const List<String> _defaultExtensions = [
  '.dart',
  '.yaml',
  '.yml',
  '.json',
  '.md',
  '.txt',
  '.sh',
  '.html',
  '.css',
  '.js',
  '.ts',
  '.svg',
  '.xml',
  '.toml',
  '.gradle',
  '.properties',
  '.cfg',
  '.ini',
  '.env',
  '.bzl',
  '.cmake',
];

/// Extensionless files worth processing (compared case-insensitively).
const Set<String> _allowlistedBasenames = {
  '.gitignore',
  '.gitattributes',
  '.editorconfig',
  '.env',
  'makefile',
  'dockerfile',
  'license',
  'readme',
};

Future<void> main(List<String> args) async {
  var checkOnly = false;
  var allFiles = false;
  List<String>? customExtensions;
  final paths = <String>[];

  for (final arg in args) {
    switch (arg) {
      case '-h' || '--help':
        _printUsage();
        return;
      case '--check':
        checkOnly = true;
      case '--all':
        allFiles = true;
      case _ when arg.startsWith('--ext='):
        customExtensions = arg
            .substring('--ext='.length)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) => e.startsWith('.') ? e : '.$e')
            .map((e) => e.toLowerCase())
            .toList();
      case _ when arg.startsWith('-'):
        stderr.writeln('Unknown option: $arg');
        _printUsage();
        exitCode = 64;
        return;
      default:
        paths.add(arg);
    }
  }

  final extensions = (customExtensions ?? _defaultExtensions).toSet();

  // Collect files deterministically.
  final targets = <File>[];
  for (final path in paths.isEmpty ? <String>['.'] : paths) {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      stderr.writeln('No such path: $path');
      exitCode = 64;
      return;
    }
    if (type == FileSystemEntityType.file) {
      targets.add(File(path)); // Explicit files are always processed.
      continue;
    }
    if (type != FileSystemEntityType.directory) continue;

    await for (final entity in Directory(path).list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (_shouldSkip(entity.path)) continue;
      if (!allFiles && !_isAllowlisted(entity.path, extensions)) continue;
      targets.add(entity);
    }
  }

  targets.sort((a, b) => a.path.compareTo(b.path));

  var scanned = 0;
  var offending = 0;
  var fixed = 0;
  var newlinesRemoved = 0;
  var errors = 0;

  for (final file in targets) {
    scanned++;

    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      stderr.writeln('[error] ${file.path}: $e');
      errors++;
      continue;
    }

    // Binary safety net (matters most with --all): files containing NUL
    // bytes are never treated as text.
    if (bytes.contains(0)) continue;

    var end = bytes.length;
    while (end > 0 && (bytes[end - 1] == 0x0A || bytes[end - 1] == 0x0D)) {
      end--;
    }
    if (end == bytes.length) continue;

    final count = bytes.length - end;
    offending++;
    newlinesRemoved += count;

    if (checkOnly) {
      print('[newline at eof] ${file.path} (removes $count)');
      continue;
    }

    try {
      await file.writeAsBytes(bytes.sublist(0, end), flush: true);
      fixed++;
      print('[fixed] ${file.path} (removed $count)');
    } catch (e) {
      stderr.writeln('[error] ${file.path}: $e');
      errors++;
    }
  }

  final summary = checkOnly
      ? 'Scanned $scanned file(s): $offending with a newline at eof, '
          '$newlinesRemoved newline(s) total.'
      : 'Scanned $scanned file(s): $fixed fixed, '
          '$newlinesRemoved newline(s) removed.';
  print('\n$summary');

  if (errors > 0) exitCode = 2;
  if (checkOnly && offending > 0) exitCode = 1;
}

bool _shouldSkip(String path) {
  final segments = path.split(RegExp(r'[/\\]'));
  return segments.any(_skipDirs.contains);
}

bool _isAllowlisted(String path, Set<String> extensions) {
  final name = path.split(RegExp(r'[/\\]')).last.toLowerCase();
  if (_allowlistedBasenames.contains(name)) return true;

  final dot = name.lastIndexOf('.');
  if (dot <= 0) return false;
  return extensions.contains(name.substring(dot));
}

void _printUsage() {
  stdout.writeln('''
Strips trailing newlines (LF/CRLF) from the end of text files.

Usage: dart run tool/strip_trailing_newlines.dart [paths...] [options]

Options:
  --check         Report only; exit code 1 when any file has a trailing
                  newline. Files are never modified.
  --all           Consider every file (NUL-containing files are skipped).
  --ext=dart,md   Override the default extension allowlist.
  -h, --help      Show this help.

Paths default to the current directory.''');
}