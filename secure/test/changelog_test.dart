import 'dart:io';

import 'package:secure/src/generator/changelog.dart';
import 'package:test/test.dart';

void main() {
  group('Changelog', () {
    test('initializes with empty lists', () {
      final changelog = Changelog();

      expect(changelog.added, isEmpty);
      expect(changelog.modified, isEmpty);
      expect(changelog.deleted, isEmpty);
    });

    test('can add files to added list', () {
      final changelog = Changelog();
      changelog.added.add('src/new_file.dart');

      expect(changelog.added, contains('src/new_file.dart'));
      expect(changelog.added.length, equals(1));
    });

    test('can add files to modified list', () {
      final changelog = Changelog();
      changelog.modified.add('src/existing_file.dart');

      expect(changelog.modified, contains('src/existing_file.dart'));
      expect(changelog.modified.length, equals(1));
    });

    test('can add files to deleted list', () {
      final changelog = Changelog();
      changelog.deleted.add('src/old_file.dart');

      expect(changelog.deleted, contains('src/old_file.dart'));
      expect(changelog.deleted.length, equals(1));
    });

    test('can add multiple files to each list', () {
      final changelog = Changelog();
      changelog.added.addAll(['a.dart', 'b.dart']);
      changelog.modified.addAll(['c.dart', 'd.dart']);
      changelog.deleted.addAll(['e.dart']);

      expect(changelog.added.length, equals(2));
      expect(changelog.modified.length, equals(2));
      expect(changelog.deleted.length, equals(1));
    });
  });

  group('prepareChangelogContent', () {
    test('generates changelog with all sections', () {
      final changelog = Changelog();
      changelog.added.add('src/new.dart');
      changelog.modified.add('src/changed.dart');
      changelog.deleted.add('src/removed.dart');

      final content = prepareChangelogContent(
        changelog,
        'abc123 Initial commit',
        '1.0.0',
      );

      expect(content, contains('# Changelog'));
      expect(content, contains('Version: **1.0.0**'));
      expect(content, contains('### ✍️ Commit Messages'));
      expect(content, contains('abc123 Initial commit'));
      expect(content, contains('### ✨ Added'));
      expect(content, contains('`src/new.dart`'));
      expect(content, contains('### 🛠️ Modified'));
      expect(content, contains('`src/changed.dart`'));
      expect(content, contains('### ❌ Deleted'));
      expect(content, contains('`src/removed.dart`'));
    });

    test('generates changelog with only added files', () {
      final changelog = Changelog();
      changelog.added.add('feature.dart');

      final content = prepareChangelogContent(changelog, '', '2.0.0');

      expect(content, contains('### ✨ Added'));
      expect(content, contains('`feature.dart`'));
      expect(content, isNot(contains('### 🛠️ Modified')));
      expect(content, isNot(contains('### ❌ Deleted')));
    });

    test('generates changelog with only commit messages', () {
      final changelog = Changelog();

      final content = prepareChangelogContent(
        changelog,
        'fix: resolve bug\nfeat: add feature',
        '3.0.0',
      );

      expect(content, contains('### ✍️ Commit Messages'));
      expect(content, contains('* fix: resolve bug'));
      expect(content, contains('* feat: add feature'));
      expect(content, isNot(contains('### ✨ Added')));
    });

    test('generates changelog with empty commit messages', () {
      final changelog = Changelog();

      final content = prepareChangelogContent(changelog, '', '1.0.0');

      expect(content, isNot(contains('### ✍️ Commit Messages')));
    });

    test('generates changelog with empty changelog', () {
      final changelog = Changelog();

      final content = prepareChangelogContent(changelog, '', '1.0.0');

      expect(content, contains('# Changelog'));
      expect(content, contains('Version: **1.0.0**'));
      expect(content, isNot(contains('### ✨ Added')));
      expect(content, isNot(contains('### 🛠️ Modified')));
      expect(content, isNot(contains('### ❌ Deleted')));
    });

    test('handles multiple commit messages', () {
      final changelog = Changelog();
      final messages = 'commit1\ncommit2\ncommit3';

      final content = prepareChangelogContent(changelog, messages, '1.0.0');

      expect(content, contains('* commit1'));
      expect(content, contains('* commit2'));
      expect(content, contains('* commit3'));
    });
  });

  group('getVersionFromPubspec', () {
    test('returns version from pubspec.yaml if it exists', () {
      // This test depends on the current directory having a pubspec.yaml
      // with a version field, which the secure package does
      final version = getVersionFromPubspec();

      // The secure package version is 0.2.5
      expect(version, isNot(equals('unknown')));
      expect(version, isNotEmpty);
    });
  });

  group('executeGitCommand', () {
    test('returns non-empty list for valid git command', () {
      final result = executeGitCommand('git --version');

      expect(result, isA<List<String>>());
      expect(result, isNotEmpty);
      expect(result.first, contains('git version'));
    });

    test('returns empty list for invalid git command', () {
      final result = executeGitCommand('git nonexistent-command-xyz');

      expect(result, isEmpty);
    });
  });

  group('writeChangelogToFile', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('changelog_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('creates changes directory and writes file', () {
      // We need to change to temp dir for this test
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        writeChangelogToFile('# Test Changelog\n', '1.0.0');

        final file = File('changes/CHANGELOG-1.0.0.md');
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('# Test Changelog\n'));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('overwrites existing changelog file', () {
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        writeChangelogToFile('Version 1', '1.0.0');
        writeChangelogToFile('Version 2', '1.0.0');

        final file = File('changes/CHANGELOG-1.0.0.md');
        expect(file.readAsStringSync(), equals('Version 2'));
      } finally {
        Directory.current = originalDir;
      }
    });
  });

  group('getGitDiff', () {
    test('returns list of changed files', () {
      // In a git repo, this should return some results
      final result = getGitDiff('HEAD~1', 'HEAD');

      expect(result, isA<List<String>>());
      // Each entry should be in STATUS\tFILENAME format
      for (final entry in result) {
        final parts = entry.split('\t');
        expect(parts.length, equals(2));
        expect(['A', 'M', 'D', 'R'], contains(parts[0]));
      }
    });
  });

  group('getCommitMessages', () {
    test('returns commit messages between refs', () {
      final result = getCommitMessages('HEAD~1', 'HEAD');

      expect(result, isA<String>());
      // May be empty if there's only one commit, but should not throw
    });
  });
}