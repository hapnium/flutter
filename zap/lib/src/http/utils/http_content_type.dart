// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// {@template http_content_type}
/// Defines standard HTTP content (MIME) types used in web communications.
///
/// These constants can be used when setting the `Content-Type` or `Accept` headers
/// in HTTP requests or responses. They cover common content types for APIs,
/// file uploads, documents, and media.
///
/// ## Example
/// ```dart
/// final headers = {
///   'Content-Type': HttpContentType.APPLICATION_JSON,
/// };
/// ```
///
/// ## Usage notes
/// - Use these constants instead of hardcoded strings to avoid typos.
/// - Some content types have helper methods for adding parameters (e.g., boundary).
/// - The constants are organized by category: APIs, documents, media, etc.
/// {@endtemplate}
abstract class HttpContentType {
  /// `application/json`
  ///
  /// Standard content type for JSON-encoded request and response bodies.
  /// Commonly used in RESTful APIs.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_JSON;
  /// ```
  static const String APPLICATION_JSON = 'application/json';

  /// `application/xml`
  ///
  /// Used for XML-formatted data in APIs or document exchanges.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_XML;
  /// ```
  static const String APPLICATION_XML = 'application/xml';

  /// `application/x-www-form-urlencoded`
  ///
  /// Standard format for submitting HTML form fields as key-value pairs.
  /// Often used with `POST` requests from web forms.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_FORM_URLENCODED;
  /// ```
  static const String APPLICATION_FORM_URLENCODED = 'application/x-www-form-urlencoded';

  /// `multipart/form-data`
  ///
  /// Used for file uploads and mixed content (e.g., file + text fields).
  /// Required when uploading files using HTML forms.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.MULTIPART_FORM_DATA;
  /// ```
  static const String MULTIPART_FORM_DATA = 'multipart/form-data';

  /// Returns `multipart/form-data` with charset parameter.
  ///
  /// ## Parameters
  /// - [charset]: The character encoding (default: 'utf-8').
  ///
  /// ## Returns
  /// The content type string with charset.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.MULTIPART_FORM_DATA_WITH_CHARSET('utf-8');
  /// ```
  static String MULTIPART_FORM_DATA_WITH_CHARSET([String? charset]) => '$MULTIPART_FORM_DATA; charset=${charset ?? 'utf-8'}';

  /// Returns `multipart/form-data` with boundary parameter.
  ///
  /// ## Parameters
  /// - [boundary]: The boundary string (default: '----ZapClientBoundary').
  ///
  /// ## Returns
  /// The content type string with boundary.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.MULTIPARET_FORM_DATA_WITH_BOUNDARY('my-boundary');
  /// ```
  static String MULTIPARET_FORM_DATA_WITH_BOUNDARY([String? boundary]) => '$MULTIPART_FORM_DATA; boundary=${boundary ?? '----ZapClientBoundary'}';

  /// `text/plain`
  ///
  /// Plain unformatted text. Often used for simple text-based payloads.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.TEXT_PLAIN;
  /// ```
  static const String TEXT_PLAIN = 'text/plain';

  /// `text/html`
  ///
  /// HTML documents used in web pages and emails.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.TEXT_HTML;
  /// ```
  static const String TEXT_HTML = 'text/html';

  /// `text/css`
  ///
  /// Stylesheets for HTML documents.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.TEXT_CSS;
  /// ```
  static const String TEXT_CSS = 'text/css';

  /// `text/javascript`
  ///
  /// Deprecated but still seen in legacy apps for JavaScript content.
  /// Prefer [APPLICATION_JAVASCRIPT] for new code.
  static const String TEXT_JAVASCRIPT = 'text/javascript';

  /// `application/javascript`
  ///
  /// The modern MIME type for JavaScript files.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_JAVASCRIPT;
  /// ```
  static const String APPLICATION_JAVASCRIPT = 'application/javascript';

  /// `application/octet-stream`
  ///
  /// Binary stream of arbitrary data. Often used for file downloads.
  /// If you don't know the specific MIME type, use this.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_OCTET_STREAM;
  /// ```
  static const String APPLICATION_OCTET_STREAM = 'application/octet-stream';

  /// `application/pdf`
  ///
  /// Standard content type for PDF documents.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_PDF;
  /// ```
  static const String APPLICATION_PDF = 'application/pdf';

  /// `image/png`
  ///
  /// Portable Network Graphics image.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.IMAGE_PNG;
  /// ```
  static const String IMAGE_PNG = 'image/png';

  /// `image/jpeg`
  ///
  /// JPEG image format, commonly used for photographs.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.IMAGE_JPEG;
  /// ```
  static const String IMAGE_JPEG = 'image/jpeg';

  /// `image/gif`
  ///
  /// GIF image format, often used for animations.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.IMAGE_GIF;
  /// ```
  static const String IMAGE_GIF = 'image/gif';

  /// `audio/mpeg`
  ///
  /// MPEG audio file, such as MP3.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.AUDIO_MPEG;
  /// ```
  static const String AUDIO_MPEG = 'audio/mpeg';

  /// `video/mp4`
  ///
  /// MP4 video format, widely supported in browsers and devices.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.VIDEO_MP4;
  /// ```
  static const String VIDEO_MP4 = 'video/mp4';

  /// `video/quicktime`
  ///
  /// QuickTime video format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.VIDEO_QUICKTIME;
  /// ```
  static const String VIDEO_QUICKTIME = 'video/quicktime';

  /// `form-data`
  ///
  /// Form data transfer encoding. Used in multipart form data headers.
  static const String FORM_DATA = 'form-data';

  /// `binary`
  ///
  /// Binary transfer encoding. Used in Content-Transfer-Encoding headers.
  static const String BINARY = 'binary';

  /// `charset`
  ///
  /// Character encoding. Used in Content-Type parameter names.
  static const String CHARSET = 'charset';

  /// `charset=utf-8`
  ///
  /// UTF-8 character encoding parameter.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = 'text/plain; ${HttpContentType.CHARSET_UTF_8}';
  /// ```
  static const String CHARSET_UTF_8 = '$CHARSET=utf-8';

  /// `application/zip`
  ///
  /// ZIP archive file format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_ZIP;
  /// ```
  static const String APPLICATION_ZIP = 'application/zip';

  /// `application/vnd.api+json`
  ///
  /// JSON:API standard content type for APIs following the JSON:API spec.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_JSON_API;
  /// ```
  static const String APPLICATION_JSON_API = 'application/vnd.api+json';

  /// `application/graphql`
  ///
  /// Used to submit GraphQL queries.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_GRAPHQL;
  /// ```
  static const String APPLICATION_GRAPHQL = 'application/graphql';

  /// `application/ld+json`
  ///
  /// JSON for Linked Data. Used in semantic web and schema.org annotations.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_JSON_LD;
  /// ```
  static const String APPLICATION_JSON_LD = 'application/ld+json';

  /// `application/msword`
  ///
  /// Microsoft Word `.doc` format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_MSWORD;
  /// ```
  static const String APPLICATION_MSWORD = 'application/msword';

  /// `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
  ///
  /// Microsoft Word `.docx` format (Office Open XML).
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_MSWORD_DOCX;
  /// ```
  static const String APPLICATION_MSWORD_DOCX = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  /// `application/vnd.ms-excel`
  ///
  /// Microsoft Excel `.xls` legacy format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_MSEXCEL;
  /// ```
  static const String APPLICATION_MSEXCEL = 'application/vnd.ms-excel';

  /// `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  ///
  /// Microsoft Excel `.xlsx` format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_MSEXCEL_XLSX;
  /// ```
  static const String APPLICATION_MSEXCEL_XLSX = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// `application/vnd.ms-powerpoint`
  ///
  /// Microsoft PowerPoint `.ppt` legacy format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_MSPOWERPOINT;
  /// ```
  static const String APPLICATION_MSPOWERPOINT = 'application/vnd.ms-powerpoint';

  /// `application/vnd.openxmlformats-officedocument.presentationml.presentation`
  ///
  /// Microsoft PowerPoint `.pptx` format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_MSPOWERPOINT_PPTX;
  /// ```
  static const String APPLICATION_MSPOWERPOINT_PPTX = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

  /// `application/x-ndjson`
  ///
  /// Newline-delimited JSON. Each line is a separate JSON object.
  /// Useful for streaming large JSON datasets.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_NDJSON;
  /// ```
  static const String APPLICATION_NDJSON = 'application/x-ndjson';

  /// `application/x-yaml`
  ///
  /// YAML document format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_YAML;
  /// ```
  static const String APPLICATION_YAML = 'application/x-yaml';

  /// `application/x-tar`
  ///
  /// TAR archive format.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_TAR;
  /// ```
  static const String APPLICATION_TAR = 'application/x-tar';

  /// `application/x-www-form-urlencoded`
  ///
  /// Standard format for submitting HTML form fields as key-value pairs.
  /// Often used with `POST` requests from web forms.
  ///
  /// ## Example
  /// ```dart
  /// headers['Content-Type'] = HttpContentType.APPLICATION_X_WWW_FORM_URLENCODED;
  /// ```
  static const String APPLICATION_X_WWW_FORM_URLENCODED = 'application/x-www-form-urlencoded';
}