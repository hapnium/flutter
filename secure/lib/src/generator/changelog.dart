import 'dart:io';

/// Entry point for the changelog generator script.
///
/// Parses command-line arguments and delegates to [generateChangelog].
///
/// Usage:
/// ```bash
/// dart run changelog.dart [baseCommit] [headCommit]
/// ```
///
/// - `baseCommit`: The git ref to diff from (default: `HEAD~1`)
/// - `headCommit`: The git ref to diff to (default: `HEAD`)
void main(List<String> args) {
  generateChangelog(args);
}

/// Generates a changelog by analyzing git diffs between two commits.
///
/// The [args] list can contain:
/// - `args[0]`: The base commit (default: `HEAD~1`)
/// - `args[1]`: The head commit (default: `HEAD`)
///
/// The function:
/// 1. Parses the commit range from [args]
/// 2. Runs `git diff --name-status` to classify files as added/modified/deleted
/// 3. Runs `git log --oneline` to collect commit messages
/// 4. Reads the version from `pubspec.yaml`
/// 5. Formats everything into a Markdown changelog
/// 6. Writes the result to `changes/CHANGELOG-<version>.md`
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

/// Runs `git diff --name-status` between [baseCommit] and [headCommit].
///
/// Returns a list of lines, each in the format `STATUS\tFILENAME` where
/// STATUS is one of:
/// - `A`: File was added
/// - `M`: File was modified
/// - `D`: File was deleted
///
/// Returns an empty list if the command fails.
List<String> getGitDiff(String baseCommit, String headCommit) {
  return executeGitCommand('git diff --name-status $baseCommit $headCommit');
}

/// Retrieves commit messages between [baseCommit] and [headCommit].
///
/// Runs `git log --oneline` and joins all messages with newlines.
/// Returns an empty string if no commits exist in the range.
String getCommitMessages(String baseCommit, String headCommit) {
  final messages = executeGitCommand(
      'git log --oneline $baseCommit..$headCommit');
  return messages.join('\n');
}

/// Reads the version string from `pubspec.yaml` in the current directory.
///
/// Parses the file line-by-line looking for a line starting with `version:`.
/// Returns the trimmed value after the colon. Returns `'unknown'` if the
/// file does not exist or contains no version line.
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

/// Executes a shell [command] synchronously and returns the non-empty output lines.
///
/// Splits [command] on spaces to extract the program and arguments. If the
/// process exits with code 0, the stdout is split into lines and empty lines
/// are filtered out. On failure, prints the stderr to the console and returns
/// an empty list.
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

/// Formats a [Changelog] into a Markdown string with commit messages and
/// version header.
///
/// The [commitMessages] string is split on newlines and each message is
/// prefixed with `* `. The [version] is displayed in the header. Sections
/// for Added, Modified, and Deleted files are only included if the
/// respective list is non-empty.
///
/// Returns the complete changelog as a single string.
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

/// Writes the changelog [content] to a file in the `changes/` directory.
///
/// Creates the `changes/` directory if it does not exist. The file is named
/// `CHANGELOG-<version>.md` using the provided [version] string.
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
/// A data class that accumulates file-level changes detected from git diffs.
///
/// Files are categorized into three lists:
/// - [added]: Files that are newly created (`A` status)
/// - [modified]: Files that have been changed (`M` status)
/// - [deleted]: Files that have been removed (`D` status)
///
/// Used by [generateChangelog] to build the Markdown changelog output.
/// {@endtemplate}
class Changelog {
  /// {@macro changelog}
  Changelog();

  /// Files that were added (git status `A`).
  ///
  /// These files are newly created and did not exist in the base commit.
  /// Each entry is a file path relative to the repository root.
  final List<String> added = [];

  /// Files that were modified (git status `M`).
  ///
  /// These files existed in the base commit and have been changed in the
  /// head commit. Each entry is a file path relative to the repository root.
  final List<String> modified = [];

  /// Files that were deleted (git status `D`).
  ///
  /// These files existed in the base commit but have been removed in the
  /// head commit. Each entry is a file path relative to the repository root.
  final List<String> deleted = [];
}