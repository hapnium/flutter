import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimedia/src/models/file_reader/file_reader_io.dart';

void main() {
  group('readFileBytes (IO)', () {
    test('reads bytes from an existing file', () async {
      // Create a temporary file with known content
      final tempDir = Directory.systemTemp.createTempSync('file_reader_test_');
      final tempFile = File('${tempDir.path}/test.txt');
      final content = [72, 101, 108, 108, 111]; // "Hello"
      tempFile.writeAsBytesSync(content);

      try {
        final bytes = await readFileBytes(tempFile.path);

        expect(bytes, equals(content));
        expect(bytes.length, equals(5));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('reads empty file as empty bytes', () async {
      final tempDir = Directory.systemTemp.createTempSync('file_reader_test_');
      final tempFile = File('${tempDir.path}/empty.txt');
      tempFile.writeAsBytesSync([]);

      try {
        final bytes = await readFileBytes(tempFile.path);

        expect(bytes, isEmpty);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('reads binary content correctly', () async {
      final tempDir = Directory.systemTemp.createTempSync('file_reader_test_');
      final tempFile = File('${tempDir.path}/binary.bin');
      final content = [0, 1, 2, 255, 128, 64];
      tempFile.writeAsBytesSync(content);

      try {
        final bytes = await readFileBytes(tempFile.path);

        expect(bytes, equals(content));
        expect(bytes.length, equals(6));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws when file does not exist', () async {
      expect(
        () => readFileBytes('/nonexistent/path/file.txt'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}