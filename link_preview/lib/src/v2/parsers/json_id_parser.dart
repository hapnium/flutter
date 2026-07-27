import 'dart:convert';

import 'package:html/dom.dart';

import '../../models/link_preview_data.dart';
import '../../models/link_preview_image.dart';
import '../../extensions/get_extension.dart';
import 'og_parser.dart';

/// {@template json_ld_parser}
/// A parser that extracts [LinkPreviewData] from JSON-LD structured data.
///
/// JSON-LD (JSON for Linked Data) is embedded in `<script type="application/ld+json">`
/// tags and is the preferred format for semantic metadata on modern web pages.
/// This parser extracts the page title, description, image, and site name
/// from the JSON-LD `@graph` or root object.
///
/// ### Usage
///
/// ```dart
/// final parser = JsonLdParser(document);
/// final title = parser.title;
/// final description = parser.description;
/// final image = parser.image;
/// ```
///
/// ### Common actions
///
/// - Extract structured metadata from JSON-LD script tags.
/// - Parse the `name` or `headline` fields for the title.
/// - Parse the `description` or `headline` fields for the description.
/// - Extract the `logo` or `image` field for the image URL.
/// - Fall back to Open Graph `og:site_name` for the site name.
///
/// ### Edge cases
///
/// - If [document] is `null` or has no JSON-LD script, all getters return `null`.
/// - JSON-LD data can be a `List` (multiple `@graph` entries) or a `Map`.
/// - When data is a `List`, the first entry is used.
/// - If the `logo` field is a list, the first element is used.
/// - The `siteName` getter delegates to [OpenGraphParser] since JSON-LD has
///   no standard site name property.
/// {@endtemplate}
class JsonLdParser with BaseMetaInfo {
  /// {@template json_ld_parser_document}
  /// The parsed HTML [Document] to extract JSON-LD data from.
  ///
  /// This document is searched for `<script type="application/ld+json">` tags.
  /// Can be `null` to produce a parser that always returns `null` values.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to inspect. Can be `null`.
  /// {@endtemplate}
  Document? document;

  /// {@template json_ld_parser_json_data}
  /// The parsed JSON-LD data extracted from the document.
  ///
  /// This is either a `List` (when the JSON-LD contains `@graph` entries)
  /// or a `Map` (when it contains a single structured object). Populated
  /// at construction time by [_parseToJson].
  /// {@endtemplate}
  dynamic _jsonData;

  /// {@template json_ld_parser_constructor}
  /// Creates a [JsonLdParser] from a parsed HTML [Document].
  ///
  /// Immediately parses the document to extract JSON-LD data from
  /// `<script type="application/ld+json">` tags.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to extract JSON-LD data from.
  ///   Pass `null` to produce a parser that always returns `null` values.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = JsonLdParser(document);
  /// print(parser.title);
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - If `document` is `null`, all getters return `null`.
  /// - If no `<script type="application/ld+json">` tag exists, all getters
  ///   return `null`.
  /// - Newline characters in JSON are stripped before parsing.
  /// {@endtemplate}
  JsonLdParser(this.document) {
    _jsonData = _parseToJson(document);
  }

  /// {@template json_ld_parser_parse_to_json}
  /// Extracts and decodes JSON-LD data from the document.
  ///
  /// Locates the first `<script type="application/ld+json">` tag, extracts
  /// its inner HTML, replaces newline characters with spaces (to handle
  /// multiline JSON), and decodes it using [jsonDecode].
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to search for JSON-LD script tags.
  ///   Can be `null`.
  ///
  /// ### Return value
  ///
  /// Returns a decoded JSON object (`List` or `Map`), or `null` if no
  /// JSON-LD data is found.
  /// {@endtemplate}
  dynamic _parseToJson(Document? document) {
    final data = document?.head
        ?.querySelector("script[type='application/ld+json']")
        ?.innerHtml;
    if (data == null) return null;
    // For multiline json file
    // Replacing all new line characters with empty space
    // before performing json decode on data
    return jsonDecode(data.replaceAll('\n', ' '));
  }

  /// {@template json_ld_parser_title}
  /// The page title extracted from the JSON-LD `name` or `headline` field.
  ///
  /// Searches the JSON-LD data for a title. When the data is a `List`,
  /// the `name` field of the first entry is used. When the data is a `Map`,
  /// it checks `name` first, then falls back to `headline`.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = JsonLdParser(document);
  /// print('Title: ${parser.title}');
  /// ```
  ///
  /// ### Example
  ///
  /// For JSON-LD containing `{"@type": "Article", "name": "My Article"}`:
  /// ```dart
  /// assert(parser.title == 'My Article');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the article name in a link preview card.
  /// - Use as a higher-priority title source than OG/HTML.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON-LD data is absent or neither `name` nor
  ///   `headline` fields exist.
  /// - Returns `null` if [document] is `null`.
  /// - When data is a `List`, only the first entry's `name` field is checked.
  ///
  /// ### Return value
  ///
  /// Returns the `name` or `headline` field from the JSON-LD data, or `null`.
  /// {@endtemplate}
  @override
  String? get title {
    final data = _jsonData;
    if (data is List) {
      return data.first['name'];
    } else if (data is Map) {
      return data.get('name') ?? data.get('headline');
    }
    return null;
  }

  /// {@template json_ld_parser_description}
  /// The page description extracted from the JSON-LD `description` or `headline` field.
  ///
  /// Searches the JSON-LD data for a description. When the data is a `List`,
  /// the `description` or `headline` field of the first entry is used. When
  /// the data is a `Map`, it checks `description` first, then falls back
  /// to `headline`.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = JsonLdParser(document);
  /// print('Description: ${parser.description}');
  /// ```
  ///
  /// ### Example
  ///
  /// For JSON-LD containing `{"description": "A great article"}`:
  /// ```dart
  /// assert(parser.description == 'A great article');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a summary below the title in a link preview.
  /// - Use as a higher-priority description source than OG/HTML.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON-LD data is absent or neither `description`
  ///   nor `headline` fields exist.
  /// - Returns `null` if [document] is `null`.
  /// - When data is a `List`, only the first entry's fields are checked.
  ///
  /// ### Return value
  ///
  /// Returns the `description` or `headline` field from the JSON-LD data,
  /// or `null`.
  /// {@endtemplate}
  @override
  String? get description {
    final data = _jsonData;
    if (data is List) {
      return data.first['description'] ?? data.first['headline'];
    } else if (data is Map) {
      return data.get('description') ?? data.get('headline');
    }
    return null;
  }

  /// {@template json_ld_parser_image}
  /// The image URL extracted from the JSON-LD `logo` or `image` field.
  ///
  /// Searches the JSON-LD data for an image. When the data is a `List`,
  /// the `logo` or `image` field of the first entry is used. When the data
  /// is a `Map`, it checks `logo` first, then falls back to `image`.
  ///
  /// If the resolved field is a `List`, its first element is used.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = JsonLdParser(document);
  /// final image = parser.image;
  /// if (image != null) {
  ///   print('Image URL: ${image.url}');
  /// }
  /// ```
  ///
  /// ### Example
  ///
  /// For JSON-LD containing `{"logo": "https://example.com/logo.png"}`:
  /// ```dart
  /// final image = parser.image;
  /// assert(image!.url == 'https://example.com/logo.png');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a thumbnail or logo in a link preview card.
  /// - Use the URL for image caching or preloading.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if JSON-LD data is absent or neither `logo` nor
  ///   `image` fields exist.
  /// - Returns `null` if the resolved value is not a `String` or is `"null"`.
  /// - Returns `null` if [document] is `null`.
  /// - When data is a `List`, only the first entry's fields are checked.
  /// - `height` and `width` are always `0.0` since JSON-LD does not
  ///   include image dimensions.
  ///
  /// ### Return value
  ///
  /// Returns a [LinkPreviewImage] with the image URL and zero dimensions,
  /// or `null` if no valid image is found.
  /// {@endtemplate}
  @override
  LinkPreviewImage? get image {
    String? img;
    final data = _jsonData;
    if (data is List && data.isNotEmpty) {
      img = _imgResultToStr(data.first['logo'] ?? data.first['image']);
    } else if (data is Map) {
      img = _imgResultToStr(data.getDynamic('logo') ?? data.getDynamic('image'));
    }

    double h = 0.0;
    double w = 0.0;

    if(img != null && img != "null") {
      return LinkPreviewImage(url: img, height: h, width: w);
    }

    return null;
  }

  /// {@template json_ld_parser_site_name}
  /// The site name extracted via Open Graph fallback.
  ///
  /// JSON-LD has no standard site name property, so this getter delegates
  /// to [OpenGraphParser.siteName] to extract `og:site_name` from the
  /// same document.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = JsonLdParser(document);
  /// print('Site: ${parser.siteName}');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the site name in a link preview card.
  /// - Use as a fallback for identifying the source website.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:site_name` is absent from the document.
  /// - Returns `null` if [document] is `null`.
  /// - A new [OpenGraphParser] is instantiated on every access.
  ///
  /// ### Return value
  ///
  /// Returns the `og:site_name` value, or `null` if not available.
  /// {@endtemplate}
  @override
  String? get siteName => OpenGraphParser(document).siteName;

  /// {@template json_ld_parser_img_result_to_str}
  /// Converts a JSON-LD image result to a string URL.
  ///
  /// If the result is a `List`, its first element is used. If the element
  /// is a `String`, it is returned directly.
  ///
  /// ### Parameters
  ///
  /// - `result` — The raw value from the JSON-LD image field. Can be a
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

  /// {@template json_ld_parser_to_string}
  /// Returns a string representation of the parsed [LinkPreviewData].
  ///
  /// Delegates to [BaseMetaInfo.parse] and converts the result to a string.
  /// Useful for debugging and logging the extracted metadata.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = JsonLdParser(document);
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