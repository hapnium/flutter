import 'dart:io';

/// Entry point for the changelog generator when invoked as a Dart script.
///
/// Delegates to [generateChangelog] with the supplied [args].
void main(List<String> args) {
  generateChangelog(args);
}

/// Generates a Markdown changelog file from git history.
///
/// [args] may contain:
/// - `args[0]`: the base commit (defaults to `HEAD~1`)
/// - `args[1]`: the head commit (defaults to `HEAD`)
///
/// The function reads `git diff` output to classify files, fetches commit
/// messages, reads the version from `pubspec.yaml`, and writes the result
/// to `changes/CHANGELOG-<version>.md`.
void generateChangelog(List<String> args) {
  final baseCommit = args.isNotEmpty ? args[0] : 'HEAD~1';
  final headCommit = args.length > 1 ? args[1] : 'HEAD';

  final changelog = Changelog();

  // Get the changes
  final changes = getGitDiff(baseCommit, headCommit);
  for (var change in changes) {
    final parts = change.split('\t');
    if (parts.length == 2) {
      final status = parts[0];
      final file = parts[1];
      switch (status) {
        case 'A':
          changelog.added.add(file);
          break;
        case 'M':
          changelog.modified.add(file);
          break;
        case 'D':
          changelog.deleted.add(file);
          break;
      }
    }
  }

  // Prepare changelog content
  final changelogContent = prepareChangelogContent(
    changelog,
    getCommitMessages(baseCommit, headCommit),
    getVersionFromPubspec(),
  );

  // Write to CHANGELOG.md
  writeChangelogToFile(changelogContent, getVersionFromPubspec());
}

/// Runs `git diff --name-status` between [baseCommit] and [headCommit]
/// and returns the raw output lines.
///
/// Each line has the format `STATUS\tFILE_PATH` where STATUS is one of
/// `A` (added), `M` (modified), or `D` (deleted).
List<String> getGitDiff(String baseCommit, String headCommit) {
  return executeGitCommand('git diff --name-status $baseCommit $headCommit');
}

/// Returns commit messages between [baseCommit] and [headCommit] as a
/// single newline-joined string.
///
/// Uses `git log --oneline` to produce compact one-line summaries.
String getCommitMessages(String baseCommit, String headCommit) {
  final messages = executeGitCommand(
      'git log --oneline $baseCommit..$headCommit');
  return messages.join('\n');
}

/// Reads the `version:` field from `pubspec.yaml` in the current directory.
///
/// Returns the trimmed version string (e.g. `"0.1.7"`), or `"unknown"` if
/// the file is missing or does not contain a version line.
String getVersionFromPubspec() {
  // Read the version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final lines = pubspecFile.readAsLinesSync();
    for (var line in lines) {
      if (line.startsWith('version:')) {
        return line
            .split(':')
            .last
            .trim();
      }
    }
  }
  return 'unknown';
}

/// Executes a shell [command] synchronously and returns its stdout lines.
///
/// The command string is split on spaces; the first element is treated as
/// the executable and the remainder as arguments. Returns an empty list
/// when the process exits with a non-zero code.
List<String> executeGitCommand(String command) {
  final parts = command.split(' ');
  final result = Process.runSync(parts[0], parts.sublist(1));
  if (result.exitCode == 0) {
    return result.stdout.toString().split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
  } else {
    print('Error executing command: ${result.stderr}');
    return [];
  }
}

/// Builds a Markdown changelog string from the given [changelog] data,
/// [commitMessages], and [version].
///
/// The output includes sections for commit messages, added files,
/// modified files, and deleted files. Each section is omitted when empty.
String prepareChangelogContent(Changelog changelog, String commitMessages, String version) {
  final buffer = StringBuffer();
  buffer.writeln('# Changelog\n');
  buffer.writeln('Version: **$version**\n');
  buffer.writeln(
      'All notable changes to this project will be documented in this file.\n');
  buffer.writeln('## [Unreleased]\n');

  // Commit messages section
  if (commitMessages.isNotEmpty) {
    buffer.writeln('### ✍️ Commit Messages\n');
    for (var message in commitMessages.split('\n')) {
      buffer.writeln('* $message');
    }
    buffer.writeln('');
  }

  // Added section
  if (changelog.added.isNotEmpty) {
    buffer.writeln('### ✨ Added\n');
    for (var file in changelog.added) {
      buffer.writeln('* `$file` - New functionality or features introduced.');
    }
    buffer.writeln('');
  }

  // Modified section
  if (changelog.modified.isNotEmpty) {
    buffer.writeln('### 🛠️ Modified\n');
    for (var file in changelog.modified) {
      buffer.writeln(
          '* `$file` - Updated to improve functionality or fix issues.');
    }
    buffer.writeln('');
  }

  // Deleted section
  if (changelog.deleted.isNotEmpty) {
    buffer.writeln('### ❌ Deleted\n');
    for (var file in changelog.deleted) {
      buffer.writeln('* `$file` - Removed as it was no longer needed.');
    }
    buffer.writeln('');
  }

  return '${buffer.toString().trim()}\n';
}

/// Writes [content] to `changes/CHANGELOG-<version>.md`.
///
/// Creates the `changes/` directory if it does not already exist.
void writeChangelogToFile(String content, String version) {
  final changesDir = Directory('changes');
  if (!changesDir.existsSync()) {
    changesDir.createSync();
  }

  final changelogFile = File('changes/CHANGELOG-$version.md');
  changelogFile.writeAsStringSync(content);
  print('CHANGELOG-$version.md has been updated successfully!');
}

/// {@template changelog}
/// Data container that accumulates file-level change categories for a single
/// release cycle.
///
/// Instances are populated by parsing `git diff --name-status` output and
/// classify each affected file into one of three lists:
/// - [added]: newly created files
/// - [modified]: existing files that were changed
/// - [deleted]: files that were removed
///
/// The categories are consumed by [prepareChangelogContent] to produce a
/// human-readable Markdown changelog.
/// {@endtemplate}
class Changelog {
  final List<String> added = [];
  final List<String> modified = [];
  final List<String> deleted = [];
}