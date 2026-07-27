import 'package:test/test.dart';
import 'package:tracing/src/generator/changelog.dart';

void main() {
  group('Changelog', () {
    test('initializes with empty lists', () {
      final changelog = Changelog();
      expect(changelog.added, isEmpty);
      expect(changelog.modified, isEmpty);
      expect(changelog.deleted, isEmpty);
    });

    test('added list is mutable', () {
      final changelog = Changelog();
      changelog.added.add('new_file.dart');
      expect(changelog.added, ['new_file.dart']);
    });

    test('modified list is mutable', () {
      final changelog = Changelog();
      changelog.modified.add('existing_file.dart');
      expect(changelog.modified, ['existing_file.dart']);
    });

    test('deleted list is mutable', () {
      final changelog = Changelog();
      changelog.deleted.add('old_file.dart');
      expect(changelog.deleted, ['old_file.dart']);
    });
  });

  group('prepareChangelogContent', () {
    test('includes version header', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, contains('Version: **1.0.0**'));
    });

    test('includes changelog header', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, contains('# Changelog'));
    });

    test('includes unreleased section', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, contains('## [Unreleased]'));
    });

    test('includes commit messages when non-empty', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(
        changelog,
        'fix: resolve crash\nfeat: add dark mode',
        '1.0.0',
      );
      expect(result, contains('Commit Messages'));
      expect(result, contains('fix: resolve crash'));
      expect(result, contains('feat: add dark mode'));
    });

    test('omits commit messages section when empty', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, isNot(contains('Commit Messages')));
    });

    test('includes added files', () {
      final changelog = Changelog()..added.add('lib/new.dart');
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, contains('Added'));
      expect(result, contains('lib/new.dart'));
    });

    test('includes modified files', () {
      final changelog = Changelog()..modified.add('lib/changed.dart');
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, contains('Modified'));
      expect(result, contains('lib/changed.dart'));
    });

    test('includes deleted files', () {
      final changelog = Changelog()..deleted.add('lib/removed.dart');
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, contains('Deleted'));
      expect(result, contains('lib/removed.dart'));
    });

    test('omits added section when empty', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, isNot(contains('### ✨ Added')));
    });

    test('omits modified section when empty', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, isNot(contains('### 🛠️ Modified')));
    });

    test('omits deleted section when empty', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, isNot(contains('### ❌ Deleted')));
    });

    test('includes all sections when all have data', () {
      final changelog = Changelog()
        ..added.add('a.dart')
        ..modified.add('b.dart')
        ..deleted.add('c.dart');
      final result = prepareChangelogContent(changelog, 'msg', '2.0.0');
      expect(result, contains('Added'));
      expect(result, contains('Modified'));
      expect(result, contains('Deleted'));
      expect(result, contains('Commit Messages'));
    });

    test('result ends with newline', () {
      final changelog = Changelog();
      final result = prepareChangelogContent(changelog, '', '1.0.0');
      expect(result, endsWith('\n'));
    });
  });

  group('getVersionFromPubspec', () {
    test('returns a string', () {
      final version = getVersionFromPubspec();
      expect(version, isA<String>());
    });
  });
}