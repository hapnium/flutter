import 'dart:convert';
import 'package:html/dom.dart';

import '../../models/link_preview_data.dart';
import '../../models/link_preview_image.dart';
import '../../extensions/get_extension.dart';

/// {@template youtube_parser}
/// A parser that extracts [LinkPreviewData] from YouTube's embedded JSON-LD data.
///
/// YouTube pages embed structured video metadata as JSON within the document.
/// This parser decodes the entire document HTML as JSON (after stripping the
/// `<html><head></head><body>` and `</body></html>` wrapper), then extracts
/// the video title, thumbnail, provider name, and provider URL.
///
/// ### Usage
///
/// ```dart
/// final parser = YoutubeParser(document);
/// final title = parser.title;
/// final image = parser.image;
/// final siteName = parser.siteName;
/// final url = parser.url;
/// ```
///
/// ### Common actions
///
/// - Extract the video title from the `title` field.
/// - Extract the thumbnail from the `thumbnail_url` field.
/// - Extract the provider name from the `provider_name` field.
/// - Extract the provider URL from the `provider_url` field.
///
/// ### Edge cases
///
/// - If [document] is `null`, all getters return `null`.
/// - JSON data can be a `List` (multiple entries) or a `Map` (single entry).
/// - When data is a `List`, the first entry is used.
/// - If the `thumbnail_url` field is a list, the first element is used.
/// - `height` and `width` are always `0.0` since YouTube's embedded data
///   does not include explicit image dimensions.
/// {@endtemplate}
class YoutubeParser with BaseMetaInfo {
  /// {@template youtube_parser_document}
  /// The parsed HTML [Document] to extract YouTube metadata from.
  ///
  /// This document is decoded as JSON after stripping the HTML wrapper tags.
  /// Can be `null` to produce a parser that always returns `null` values.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to inspect. Can be `null`.
  /// {@endtemplate}
  Document? document;

  /// {@template youtube_parser_json_data}
  /// The parsed JSON data extracted from the YouTube document.
  ///
  /// This is either a `List` or a `Map` depending on the structure of the
  /// embedded JSON. Populated at construction time by [_parseToJson].
  /// {@endtemplate}
  dynamic _jsonData;

  /// {@template youtube_parser_constructor}
  /// Creates a [YoutubeParser] from a parsed HTML [Document].
  ///
  /// Immediately parses the document by decoding its outer HTML as JSON
  /// (after stripping the HTML wrapper tags).
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to extract YouTube metadata from.
  ///   Pass `null` to produce a parser that always returns `null` values.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = YoutubeParser(document);
  /// print(parser.title);
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - If `document` is `null`, all getters return `null`.
  /// - If the document content is not valid JSON, a [FormatException]
  ///   is thrown during construction.
  /// - Newline characters in JSON are stripped before parsing.
  /// {@endtemplate}
  YoutubeParser(this.document) {
    _jsonData = _parseToJson(document);
  }

  /// {@template youtube_parser_parse_to_json}
  /// Extracts and decodes JSON data from the YouTube document.
  ///
  /// Strips the `<html><head></head><body>` prefix and `</body></html>`
  /// suffix from the document's outer HTML, replaces newline characters
  /// with spaces (to handle multiline JSON), and decodes it using [jsonDecode].
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] whose outer HTML is decoded. Can be `null`.
  ///
  /// ### Return value
  ///
  /// Returns a decoded JSON object (`List` or `Map`), or `null` if the
  /// document is `null`.
  ///
  /// ### Edge cases
  ///
  /// - Throws [FormatException] if the content is not valid JSON.
  /// - Returns `null` if `document` is `null`.
  /// {@endtemplate}
  dynamic _parseToJson(Document? document) {
    final data = document?.outerHtml
        .replaceAll('<html><head></head><body>', '')
        .replaceAll('</body></html>', '');
    if (data == null) return null;
    /* For multiline json file */
    // Replacing all new line characters with empty space
    // before performing json decode on data
    var d = jsonDecode(data.replaceAll('\n', ' '));
    return d;
  }

  /// {@template youtube_parser_title}
  /// The video title extracted from the `title` field of the YouTube JSON data.
  ///
  /// When the data is a `List`, the `title` field of the first entry is used.
  /// When the data is a `Map`, the `title` field is read directly.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = YoutubeParser(document);
  /// print('Title: ${parser.title}');
  /// ```
  ///
  /// ### Example
  ///
  /// For YouTube JSON containing `{"title": "Funny Cat Video"}`:
  /// ```dart
  /// assert(parser.title == 'Funny Cat Video');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the video title in a link preview card.
  /// - Use as the primary label for shared YouTube links.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON data is absent or `title` field is missing.
  /// - Returns `null` if [document] is `null`.
  /// - When data is a `List`, only the first entry's `title` is used.
  ///
  /// ### Return value
  ///
  /// Returns the `title` field from the YouTube JSON data, or `null`.
  /// {@endtemplate}
  @override
  String? get title {
    final data = _jsonData;
    if (data is List) {
      return data.first['title'];
    } else if (data is Map) {
      return data.get('title');
    }

    return null;
  }

  /// {@template youtube_parser_image}
  /// The video thumbnail extracted from the `thumbnail_url` field of the YouTube JSON data.
  ///
  /// When the data is a `List`, the `thumbnail_url` field of the first entry is used.
  /// When the data is a `Map`, the `thumbnail_url` field is read directly.
  /// If the field is a `List`, its first element is used.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = YoutubeParser(document);
  /// final image = parser.image;
  /// if (image != null) {
  ///   print('Thumbnail URL: ${image.url}');
  /// }
  /// ```
  ///
  /// ### Example
  ///
  /// For YouTube JSON containing
  /// `{"thumbnail_url": "https://i.ytimg.com/vi/abc123/hqdefault.jpg"}`:
  /// ```dart
  /// final image = parser.image;
  /// assert(image!.url == 'https://i.ytimg.com/vi/abc123/hqdefault.jpg');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the video thumbnail in a link preview card.
  /// - Use the URL for image caching or preloading.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON data is absent or `thumbnail_url` is missing.
  /// - Returns `null` if the resolved value is not a `String` or is `"null"`.
  /// - Returns `null` if [document] is `null`.
  /// - `height` and `width` are always `0.0` since YouTube's JSON data
  ///   does not include explicit image dimensions.
  /// - When data is a `List`, only the first entry's `thumbnail_url` is used.
  ///
  /// ### Return value
  ///
  /// Returns a [LinkPreviewImage] with the thumbnail URL and zero dimensions,
  /// or `null` if no valid thumbnail is found.
  /// {@endtemplate}
  @override
  LinkPreviewImage? get image {
    final data = _jsonData;
    String? img;
    if (data is List && data.isNotEmpty) {
      img = _imgResultToStr(data.first['thumbnail_url']);
    } else if (data is Map) {
      img = _imgResultToStr(data.getDynamic('thumbnail_url'));
    }

    double h = 0.0;
    double w = 0.0;

    if(img != null && img != "null") {
      return LinkPreviewImage(url: img, height: h, width: w);
    }

    return null;
  }

  /// {@template youtube_parser_site_name}
  /// The provider name extracted from the `provider_name` field of the YouTube JSON data.
  ///
  /// When the data is a `List`, the `provider_name` field of the first entry
  /// is used. When the data is a `Map`, the `provider_name` field is read
  /// directly.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = YoutubeParser(document);
  /// print('Provider: ${parser.siteName}');
  /// ```
  ///
  /// ### Example
  ///
  /// For YouTube JSON containing `{"provider_name": "YouTube"}`:
  /// ```dart
  /// assert(parser.siteName == 'YouTube');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the provider name in a link preview card.
  /// - Identify the video hosting platform.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON data is absent or `provider_name` is missing.
  /// - Returns `null` if [document] is `null`.
  /// - When data is a `List`, only the first entry's `provider_name` is used.
  ///
  /// ### Return value
  ///
  /// Returns the `provider_name` field from the YouTube JSON data, or `null`.
  /// {@endtemplate}
  @override
  String? get siteName {
    final data = _jsonData;
    if (data is List) {
      return data.first['provider_name'];
    } else if (data is Map) {
      return data.get('provider_name');
    }

    return null;
  }

  /// {@template youtube_parser_url}
  /// The provider URL extracted from the `provider_url` field of the YouTube JSON data.
  ///
  /// When the data is a `List`, the `provider_url` field of the first entry
  /// is used. When the data is a `Map`, the `provider_url` field is read
  /// directly.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = YoutubeParser(document);
  /// print('Provider URL: ${parser.url}');
  /// ```
  ///
  /// ### Example
  ///
  /// For YouTube JSON containing `{"provider_url": "https://www.youtube.com"}`:
  /// ```dart
  /// assert(parser.url == 'https://www.youtube.com');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the provider URL in a link preview.
  /// - Use for deep linking or opening the provider page.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON data is absent or `provider_url` is missing.
  /// - Returns `null` if [document] is `null`.
  /// - When data is a `List`, only the first entry's `provider_url` is used.
  ///
  /// ### Return value
  ///
  /// Returns the `provider_url` field from the YouTube JSON data, or `null`.
  /// {@endtemplate}
  @override
  String? get url {
    final data = _jsonData;
    if (data is List) {
      return data.first['provider_url'];
    } else if (data is Map) {
      return data.get('provider_url');
    }

    return null;
  }

  /// {@template youtube_parser_img_result_to_str}
  /// Converts a YouTube JSON image result to a string URL.
  ///
  /// If the result is a `List`, its first element is used. If the element
  /// is a `String`, it is returned directly.
  ///
  /// ### Parameters
  ///
  /// - `result` — The raw value from the YouTube JSON image field. Can be a
  ///   `String`, `List`, or any other type.
  ///
  /// ### Return value
  ///
  /// Returns the image URL as a `String`, or `null` if the result cannot
  /// be converted.
  /// {@endtemplate}
  String? _imgResultToStr(dynamic result) {
    if (result is List && result.isNotEmpty) result = result.first;
    if (result is String) return result;
    return null;
  }

  /// {@template youtube_parser_to_string}
  /// Returns a string representation of the parsed [LinkPreviewData].
  ///
  /// Delegates to [BaseMetaInfo.parse] and converts the result to a string.
  /// Useful for debugging and logging the extracted metadata.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = YoutubeParser(document);
  /// print(parser.toString());
  /// ```
  ///
  /// ### Return value
  ///
  /// Returns the string representation of the parsed [LinkPreviewData].
  /// {@endtemplate}
  @override
  String toString() => parse().toString();
}