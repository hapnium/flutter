import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import '../../definitions.dart';
import '../../exceptions/zap_exception.dart';
import '../utils/http_content_type.dart';
import '../utils/http_headers.dart';
import '../utils/utils.dart';
import 'multipart_file.dart';

/// The upper bound for random boundary seed generation.
const _secureRandomSeedBound = 4294967296;

/// Random number generator for boundary generation.
final _random = Random();

/// {@template form_data}
/// FormData class for multipart/form-data HTTP requests.
///
/// This class provides full async support for building multipart form data
/// requests, including file uploads and text fields. It handles boundary
/// generation, content disposition headers, and streaming serialization.
///
/// ## Features
/// - Async length calculation for accurate Content-Length headers
/// - Streaming serialization to avoid loading large files into memory
/// - Support for both text fields and file uploads
/// - Clone support for request retries
/// - CamelCase content disposition option for compatibility
///
/// ## Usage
/// ```dart
/// final formData = FormData();
/// formData.fields.add(MapEntry('name', 'John'));
/// formData.files.add(MapEntry('avatar', await MultipartFile.fromFile(
///   '/path/to/image.jpg',
///   filename: 'avatar.jpg',
/// )));
/// ```
///
/// ## Usage from Map
/// ```dart
/// final formData = FormData.fromMap({
///   'name': 'John',
///   'avatar': await MultipartFile.fromFile('/path/to/image.jpg', filename: 'avatar.jpg'),
/// });
/// ```
///
/// ## Edge cases
/// - Calling [finalize] more than once throws a [ZapException].
/// - Each [finalize] call creates a new stream; the FormData cannot be reused.
/// - Use [clone] to create a copy for retries.
/// {@endtemplate}
class FormData {
  /// Creates a new empty [FormData] instance.
  ///
  /// ## Parameters
  /// - [camelCaseContentDisposition]: Whether to use 'Content-Disposition'
  ///   (camelCase) instead of 'content-disposition' (lowercase).
  ///
  /// ## Example
  /// ```dart
  /// final formData = FormData();
  /// formData.fields.add(MapEntry('key', 'value'));
  /// ```
  FormData({
    this.camelCaseContentDisposition = false,
  }) {
    _init();
  }

  /// Creates [FormData] from a [Map].
  ///
  /// Map values are processed as follows:
  /// - `null` values are skipped.
  /// - [MultipartFile] values are added as files.
  /// - [List<MultipartFile>] values are added as multiple files.
  /// - [List] values are added as multiple field entries.
  /// - All other values are converted to strings and added as fields.
  ///
  /// ## Parameters
  /// - [map]: The form data as a key-value map.
  /// - [camelCaseContentDisposition]: Whether to use camelCase content disposition.
  ///
  /// ## Example
  /// ```dart
  /// final formData = FormData.fromMap({
  ///   'username': 'john_doe',
  ///   'age': 25,
  ///   'avatar': await MultipartFile.fromFile('/path/to/image.jpg', filename: 'avatar.jpg'),
  /// });
  /// ```
  FormData.fromMap(
    Map<String, dynamic> map, {
    this.camelCaseContentDisposition = false,
  }) {
    _init(fromMap: map);
  }

  /// Whether the 'content-disposition' header can be 'Content-Disposition'.
  ///
  /// Some servers or proxies require camelCase content disposition headers.
  /// Defaults to `false`.
  final bool camelCaseContentDisposition;

  /// Initializes the FormData with optional map data.
  void _init({Map<String, dynamic>? fromMap}) {
    // Use your existing GET_BOUNDARY
    final randomSuffix = _random.nextInt(_secureRandomSeedBound).toString();
    _boundary = '$GET_BOUNDARY$randomSuffix';
    
    if (fromMap != null) {
      fromMap.forEach((key, value) {
        if (value == null) return;
        
        if (value is MultipartFile) {
          files.add(MapEntry(key, value));
        } else if (value is List<MultipartFile>) {
          for (var file in value) {
            files.add(MapEntry(key, file));
          }
        } else if (value is List) {
          for (var item in value) {
            fields.add(MapEntry(key, item.toString()));
          }
        } else {
          fields.add(MapEntry(key, value.toString()));
        }
      });
    }
  }

  /// The boundary used in the multipart request.
  ///
  /// This is a unique string that separates parts in the multipart body.
  /// Generated automatically during initialization.
  String get boundary => _boundary;
  late String _boundary;

  /// The form fields to send for this request.
  ///
  /// Each entry is a key-value pair where the key is the field name
  /// and the value is the field value.
  ///
  /// ## Example
  /// ```dart
  /// formData.fields.add(MapEntry('username', 'john_doe'));
  /// ```
  final fields = <MapEntry<String, String>>[];

  /// The files to send for this request.
  ///
  /// Each entry is a key-value pair where the key is the field name
  /// and the value is the [MultipartFile] to upload.
  ///
  /// ## Example
  /// ```dart
  /// final file = await MultipartFile.fromFile('/path/to/file.jpg', filename: 'file.jpg');
  /// formData.files.add(MapEntry('avatar', file));
  /// ```
  final files = <MapEntry<String, MultipartFile>>[];

  /// Whether [finalize] has been called.
  ///
  /// Once `true`, the FormData cannot be finalized again.
  /// Use [clone] to create a new instance for retries.
  bool get isFinalized => _isFinalized;
  bool _isFinalized = false;

  /// Returns the content disposition key, respecting the camelCase setting.
  String get _contentDispositionKey => camelCaseContentDisposition
      ? HttpHeaders.CONTENT_DISPOSITION.toUpperCase().split('-').map((word) => 
          word[0].toUpperCase() + word.substring(1)).join('-')
      : HttpHeaders.CONTENT_DISPOSITION;

  /// Returns the header string for a field part.
  ///
  /// ## Parameters
  /// - [name]: The field name.
  /// - [value]: The field value.
  ///
  /// ## Returns
  /// The header string including content disposition and optional encoding headers.
  String _headerForField(String name, String value) {
    var header = '$_contentDispositionKey: ${HttpContentType.FORM_DATA}; name="${browserEncode(name)}"';
    
    if (!isPlainAscii(value)) {
      header = '$header\r\n'
        '${HttpHeaders.CONTENT_TYPE}: ${HttpContentType.TEXT_PLAIN}; ${HttpContentType.CHARSET_UTF_8}\r\n'
        '${HttpHeaders.CONTENT_TRANSFER_ENCODING}: ${HttpContentType.BINARY}';
    }
    return '$header\r\n\r\n';
  }

  /// Returns the header string for a file part.
  ///
  /// ## Parameters
  /// - [entry]: The file entry containing the field name and [MultipartFile].
  ///
  /// ## Returns
  /// The header string including content disposition and content type.
  String _headerForFile(MapEntry<String, MultipartFile> entry) {
    final file = entry.value;
    String header = '$_contentDispositionKey: ${HttpContentType.FORM_DATA}; name="${browserEncode(entry.key)}"';
    
    if (file.filename.isNotEmpty) {
      header = '$header; filename="${browserEncode(file.filename)}"';
    }
    
    header = '$header\r\n'
      '${HttpHeaders.CONTENT_TYPE}: ${file.contentType}\r\n\r\n';
    return header;
  }

  /// Get total length asynchronously (non-blocking).
  ///
  /// This method calculates the total byte length of the multipart body
  /// including all fields, files, boundaries, and headers. It awaits
  /// file length calculations which may involve I/O.
  ///
  /// ## Returns
  /// The total byte length of the serialized form data.
  ///
  /// ## Example
  /// ```dart
  /// final length = await formData.lengthAsync;
  /// print('Content-Length: $length');
  /// ```
  Future<int> get lengthAsync async {
    int length = 0;
    
    for (final entry in fields) {
      length += '--'.length +
          _boundary.length +
          '\r\n'.length +
          utf8.encode(_headerForField(entry.key, entry.value)).length +
          utf8.encode(entry.value).length +
          '\r\n'.length;
    }

    for (final file in files) {
      final fileLength = await file.value.length;
      length += '--'.length +
          _boundary.length +
          '\r\n'.length +
          utf8.encode(_headerForFile(file)).length +
          fileLength +
          '\r\n'.length;
    }

    return length + '--'.length + _boundary.length + '--\r\n'.length;
  }

  /// Synchronous length (uses cached values, may be inaccurate).
  ///
  /// This is a synchronous approximation that uses cached file lengths.
  /// It may not be accurate for files that haven't been length-calculated yet.
  ///
  /// ## Returns
  /// The approximate byte length of the serialized form data.
  ///
  /// ## Edge cases
  /// - Returns 0 for uncached file lengths. Use [lengthAsync] for accuracy.
  int get length {
    int length = 0;
    
    for (final entry in fields) {
      length += '--'.length +
          _boundary.length +
          '\r\n'.length +
          utf8.encode(_headerForField(entry.key, entry.value)).length +
          utf8.encode(entry.value).length +
          '\r\n'.length;
    }

    for (final file in files) {
      length += '--'.length +
          _boundary.length +
          '\r\n'.length +
          utf8.encode(_headerForFile(file)).length +
          file.value.lengthSync +
          '\r\n'.length;
    }

    return length + '--'.length + _boundary.length + '--\r\n'.length;
  }

  /// Finalize the FormData into a stream (fully async, non-blocking).
  ///
  /// This method serializes the form data into a byte stream. Once called,
  /// the FormData is marked as finalized and cannot be finalized again.
  ///
  /// ## Returns
  /// A [Stream<Uint8List>] containing the serialized multipart body.
  ///
  /// ## Throws
  /// [ZapException] if called more than once on the same instance.
  ///
  /// ## Example
  /// ```dart
  /// final stream = formData.finalize();
  /// await for (final chunk in stream) {
  ///   // Process each chunk
  /// }
  /// ```
  Stream<Uint8List> finalize() {
    if (isFinalized) {
      throw ZapException(
        'The FormData has already been finalized. '
        'This typically means you are using the same FormData in repeated requests.',
      );
    }
    _isFinalized = true;

    final controller = StreamController<Uint8List>(sync: false);
    final rnU8 = Uint8List.fromList([13, 10]);

    void writeLine() => controller.add(rnU8);
    void writeUtf8(String s) => controller.add(_effectiveU8Encoding(utf8.encode(s)));

    // Process everything asynchronously
    _processFormDataAsync(controller, writeUtf8, writeLine);

    return controller.stream;
  }

  /// Processes the form data asynchronously and writes to the controller.
  ///
  /// Writes fields first, then files with streaming, then the closing boundary.
  /// Yields control periodically to prevent blocking the UI thread.
  Future<void> _processFormDataAsync(
    StreamController<Uint8List> controller,
    void Function(String) writeUtf8,
    void Function() writeLine,
  ) async {
    try {
      // Write fields first
      for (final entry in fields) {
        writeUtf8('--$boundary\r\n');
        writeUtf8(_headerForField(entry.key, entry.value));
        writeUtf8(entry.value);
        writeLine();
        
        // Yield control to prevent blocking
        await Future.delayed(Duration.zero);
      }

      // Write files with streaming
      for (final file in files) {
        writeUtf8('--$boundary\r\n');
        writeUtf8(_headerForFile(file));
        
        final fileStream = file.value.stream;
        if (fileStream != null) {
          await for (final chunk in fileStream) {
            controller.add(_effectiveU8Encoding(chunk));
            // Yield control periodically to keep UI responsive
            await Future.delayed(Duration.zero);
          }
        }
        writeLine();
      }
      
      writeUtf8('--$boundary--\r\n');
    } catch (e) {
      controller.addError(e);
    } finally {
      controller.close();
    }
  }

  /// Transform the entire FormData contents as bytes (async).
  ///
  /// This method reads the entire form data into memory as a single byte array.
  /// Use this when you need the complete body at once.
  ///
  /// ## Returns
  /// A [Future<Uint8List>] containing the complete serialized form data.
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await formData.readAsBytes();
  /// // Use bytes for Content-Length calculation or other purposes
  /// ```
  Future<Uint8List> readAsBytes() {
    return finalize().fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    ).then((bytes) => Uint8List.fromList(bytes));
  }

  /// Returns the request body as a list of bytes (compatible with existing code).
  ///
  /// This is an alias for [readAsBytes] for backward compatibility.
  ///
  /// ## Returns
  /// A [Future<BodyBytes>] containing the serialized form data.
  Future<BodyBytes> toBytes() async {
    return await readAsBytes();
  }

  /// Clone the FormData for retries.
  ///
  /// Creates a deep copy of the form data with the same boundary,
  /// fields, and files. Each file is cloned individually.
  ///
  /// ## Returns
  /// A new [FormData] instance with the same data.
  ///
  /// ## Example
  /// ```dart
  /// final original = FormData.fromMap({'name': 'John'});
  /// final retry = original.clone();
  /// // retry can be finalized independently
  /// ```
  FormData clone() {
    final clone = FormData(
      camelCaseContentDisposition: camelCaseContentDisposition,
    );
    clone._boundary = _boundary;
    clone.fields.addAll(fields);
    
    for (final file in files) {
      clone.files.add(MapEntry(file.key, file.value.clone()));
    }
    return clone;
  }
}

/// Converts a list of integers to a Uint8List if not already one.
///
/// ## Parameters
/// - [encoded]: The list of integers.
///
/// ## Returns
/// A [Uint8List] containing the same bytes.
Uint8List _effectiveU8Encoding(List<int> encoded) {
  return encoded is Uint8List ? encoded : Uint8List.fromList(encoded);
}