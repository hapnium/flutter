import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../definitions.dart';
import '../utils/http_content_type.dart';

/// {@template multipart_file}
/// A class to represent a file in a form data with async operations.
///
/// This class supports multiple construction methods: from file path, from
/// bytes, or from a stream. It provides lazy loading and caching of file
/// data to optimize memory usage.
///
/// ## Type Parameters
/// None (this is not a generic class).
///
/// ## Features
/// - Lazy file reading from disk
/// - Stream-based construction for large files
/// - Content type detection from file extension
/// - Clone support for request retries
/// - Cached length for performance
///
/// ## Example
/// ```dart
/// final file = await MultipartFile.fromFile(
///   'path/to/file.jpg',
///   filename: 'image.jpg',
/// );
/// ```
///
/// ## Edge cases
/// - [fromFile] throws [ArgumentError] if the file does not exist.
/// - [stream] returns `null` if no data source is configured.
/// - [lengthSync] returns 0 if the length has not been cached.
/// {@endtemplate}
class MultipartFile {
  /// The file path (if constructed from file).
  final String? _filePath;

  /// Pre-loaded bytes (if constructed from bytes).
  final BodyBytes? _bytes;

  /// Pre-created stream (if constructed from stream).
  final BodyByteStream? _stream;

  /// The content type of the file (defaults to application/octet-stream).
  ///
  /// This is sent in the `Content-Type` header of the file part.
  /// If not provided, it is auto-detected from the filename extension.
  ///
  /// ## Example
  /// ```dart
  /// final file = MultipartFile.fromBytes(
  ///   bytes,
  ///   filename: 'data.bin',
  ///   contentType: 'application/octet-stream',
  /// );
  /// ```
  final String contentType;

  /// The filename of the file (sent in the request).
  ///
  /// This is used in the `Content-Disposition` header. It may differ
  /// from the original file path.
  ///
  /// ## Example
  /// ```dart
  /// final file = await MultipartFile.fromFile(
  ///   '/Users/me/documents/report.pdf',
  ///   filename: 'report.pdf',
  /// );
  /// ```
  final String filename;

  /// Cached length.
  int? _length;

  /// Cached stream to avoid recreating on repeated access.
  BodyByteStream? _cachedStream;

  /// Creates a [MultipartFile] from a file path.
  ///
  /// The file is not read until [stream] or [bytes] is accessed.
  ///
  /// ## Parameters
  /// - [filePath]: The path to the file on disk.
  /// - [filename]: The filename to use in the request.
  /// - [contentType]: The MIME type (auto-detected if not provided).
  ///
  /// ## Throws
  /// No validation is performed at construction time. The file is read
  /// lazily when [stream] or [bytes] is accessed.
  ///
  /// ## Example
  /// ```dart
  /// final file = MultipartFile(
  ///   '/path/to/image.jpg',
  ///   filename: 'image.jpg',
  /// );
  /// ```
  /// 
  /// {@macro multipart_file}
  MultipartFile(
    String filePath, {
    required this.filename,
    this.contentType = HttpContentType.APPLICATION_OCTET_STREAM,
  })  : _filePath = filePath,
        _bytes = null,
        _stream = null;

  /// Private constructor for internal use.
  MultipartFile._({
    String? filePath,
    BodyBytes? bytes,
    BodyByteStream? stream,
    required this.filename,
    required this.contentType,
    int? length,
  })  : _filePath = filePath,
        _bytes = bytes,
        _stream = stream,
        _length = length;

  /// Creates a MultipartFile from a file path (async).
  ///
  /// Validates that the file exists before creating the instance.
  ///
  /// ## Parameters
  /// - [path]: The path to the file.
  /// - [filename]: The filename to use in the request.
  /// - [contentType]: The MIME type (auto-detected if not provided).
  ///
  /// ## Returns
  /// A [Future<MultipartFile>] with the configured file.
  ///
  /// ## Throws
  /// [ArgumentError] if the file does not exist at the given path.
  ///
  /// ## Example
  /// ```dart
  /// final file = await MultipartFile.fromFile(
  ///   '/path/to/file.png',
  ///   filename: 'image.png',
  /// );
  /// ```
  static Future<MultipartFile> fromFile(
    String path, {
    required String filename,
    String? contentType,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError('File does not exist: $path');
    }

    // Determine content type if not provided
    final finalContentType = contentType ?? _getContentTypeFromExtension(filename);

    return MultipartFile._(
      filePath: path,
      filename: filename,
      contentType: finalContentType,
    );
  }

  /// Creates a MultipartFile from a list of bytes.
  ///
  /// The bytes are copied to an immutable [Uint8List].
  ///
  /// ## Parameters
  /// - [bytes]: The file content as bytes.
  /// - [filename]: The filename to use in the request.
  /// - [contentType]: The MIME type (auto-detected if not provided).
  ///
  /// ## Returns
  /// A [MultipartFile] with the provided bytes.
  ///
  /// ## Example
  /// ```dart
  /// final file = MultipartFile.fromBytes(
  ///   [72, 101, 108, 108, 111], // "Hello"
  ///   filename: 'greeting.txt',
  ///   contentType: 'text/plain',
  /// );
  /// ```
  factory MultipartFile.fromBytes(
    List<int> bytes, {
    required String filename,
    String? contentType,
  }) {
    final finalContentType = contentType ?? _getContentTypeFromExtension(filename);
    
    return MultipartFile._(
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      contentType: finalContentType,
      length: bytes.length,
    );
  }

  /// Creates a MultipartFile from a byte stream and known length.
  ///
  /// Use this when the file is large or streaming from memory/disk/network.
  /// The length must be known in advance for the `Content-Length` header.
  ///
  /// ## Parameters
  /// - [stream]: The byte stream containing the file data.
  /// - [length]: The total byte length of the stream.
  /// - [filename]: The filename to use in the request.
  /// - [contentType]: The MIME type (auto-detected if not provided).
  ///
  /// ## Returns
  /// A [MultipartFile] configured for streaming.
  ///
  /// ## Example
  /// ```dart
  /// final stream = myFile.openRead();
  /// final file = MultipartFile.fromStream(
  ///   stream,
  ///   length: 12345,
  ///   filename: 'doc.pdf',
  /// );
  /// ```
  factory MultipartFile.fromStream(
    BodyByteStream stream, {
    required int length,
    required String filename,
    String? contentType,
  }) {
    final finalContentType = contentType ?? _getContentTypeFromExtension(filename);
    
    return MultipartFile._(
      stream: stream,
      filename: filename,
      contentType: finalContentType,
      length: length,
    );
  }

  /// Get the length of the file (async).
  ///
  /// Returns the cached length if available, otherwise reads from disk
  /// or calculates from the byte source.
  ///
  /// ## Returns
  /// A [Future<int>] with the file length in bytes.
  ///
  /// ## Example
  /// ```dart
  /// final length = await file.length;
  /// print('File size: $length bytes');
  /// ```
  Future<int> get length async {
    if (_length != null) return _length!;

    if (_bytes != null) {
      _length = _bytes.length;
      return _length!;
    }

    if (_filePath != null) {
      final file = File(_filePath);
      if (await file.exists()) {
        _length = await file.length();
        return _length!;
      }
    }

    return 0;
  }

  /// Get the length synchronously (returns cached value or 0).
  ///
  /// ## Returns
  /// The cached length, or 0 if not yet calculated.
  ///
  /// ## Edge cases
  /// - Returns 0 for files that haven't been length-calculated yet.
  ///   Use [length] for accurate results.
  int get lengthSync => _length ?? (_bytes?.length ?? 0);

  /// Get the byte stream of the file (async, non-blocking).
  ///
  /// Returns a cached stream if available, otherwise creates one from
  /// the underlying data source (bytes, stream, or file path).
  ///
  /// ## Returns
  /// A [BodyByteStream] containing the file data, or `null` if no data source.
  ///
  /// ## Example
  /// ```dart
  /// final stream = file.stream;
  /// if (stream != null) {
  ///   await for (final chunk in stream) {
  ///     // Process chunk
  ///   }
  /// }
  /// ```
  BodyByteStream? get stream {
    if (_cachedStream != null) return _cachedStream;

    if (_bytes != null) {
      _cachedStream = Stream.value(_bytes);
      return _cachedStream;
    }

    if (_stream != null) {
      _cachedStream = _stream;
      return _cachedStream;
    }

    if (_filePath != null) {
      final file = File(_filePath);
      _cachedStream = file.openRead().cast<List<int>>();
      return _cachedStream;
    }

    return null;
  }

  /// Get the raw bytes (async, only use for small files).
  ///
  /// Reads the entire file into memory. For large files, prefer [stream].
  ///
  /// ## Returns
  /// A [Future<BodyBytes>] containing all file bytes.
  ///
  /// ## Edge cases
  /// - Returns an empty [Uint8List] if no data source is available.
  /// - For stream-based files, all chunks are collected into memory.
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await file.bytes;
  /// // Process bytes
  /// ```
  Future<BodyBytes> get bytes async {
    if (_bytes != null) return _bytes;

    if (_filePath != null) {
      final file = File(_filePath);
      if (await file.exists()) {
        return await file.readAsBytes(); // Async read
      }
    }

    if (_stream != null) {
      final chunks = <int>[];
      await for (final chunk in _stream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    }

    return Uint8List(0);
  }

  /// Clone for retries.
  ///
  /// Creates a new [MultipartFile] with the same configuration.
  /// The cloned file shares the same underlying data sources.
  ///
  /// ## Returns
  /// A new [MultipartFile] instance.
  ///
  /// ## Example
  /// ```dart
  /// final original = await MultipartFile.fromFile('/path/to/file.jpg', filename: 'image.jpg');
  /// final retry = original.clone();
  /// ```
  MultipartFile clone() {
    return MultipartFile._(
      filePath: _filePath,
      bytes: _bytes,
      stream: _stream,
      filename: filename,
      contentType: contentType,
      length: _length,
    );
  }

  /// Determine content type from file extension.
  ///
  /// ## Parameters
  /// - [filename]: The filename to extract the extension from.
  ///
  /// ## Returns
  /// The MIME type string, or `'application/octet-stream'` for unknown extensions.
  ///
  /// ## Supported extensions
  /// - Images: jpg, jpeg, png, gif
  /// - Documents: pdf
  /// - Media: mp4, mp3
  /// - Data: json, xml, zip
  /// - Default: application/octet-stream
  static String _getContentTypeFromExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return HttpContentType.IMAGE_JPEG;
      case 'png':
        return HttpContentType.IMAGE_PNG;
      case 'gif':
        return HttpContentType.IMAGE_GIF;
      case 'pdf':
        return HttpContentType.APPLICATION_PDF;
      case 'mp4':
        return HttpContentType.VIDEO_MP4;
      case 'mp3':
        return HttpContentType.AUDIO_MPEG;
      case 'json':
        return HttpContentType.APPLICATION_JSON;
      case 'xml':
        return HttpContentType.APPLICATION_XML;
      case 'zip':
        return HttpContentType.APPLICATION_ZIP;
      default:
        return HttpContentType.APPLICATION_OCTET_STREAM;
    }
  }
}