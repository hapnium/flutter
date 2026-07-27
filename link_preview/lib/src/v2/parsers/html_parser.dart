import 'package:html/dom.dart';

import '../../models/link_preview_data.dart';
import '../../models/link_preview_image.dart';
import '../../extensions/get_extension.dart';

/// {@template html_meta_parser}
/// A fallback HTML parser that extracts [LinkPreviewData] from standard HTML
/// `<meta>`, `<title>`, and `<img>` tags when Open Graph, Twitter Card, or
/// JSON-LD data is absent.
///
/// This parser is used as the last resort when no structured metadata is
/// found in the document. It reads the `<title>` tag, the
/// `<meta name="description">` tag, the first `<img>` tag in the body,
/// and the `<meta name="site_name">` tag.
///
/// ### Usage
///
/// ```dart
/// final parser = HtmlMetaParser(document);
/// final title = parser.title;
/// final description = parser.description;
/// final image = parser.image;
/// ```
///
/// ### Common actions
///
/// - Extract the page title from `<title>`.
/// - Extract the meta description from `<meta name="description">`.
/// - Extract the first image URL from `<img>` in `<body>`.
/// - Extract the site name from `<meta name="site_name">`.
///
/// ### Edge cases
///
/// - If [document] is `null`, all getters return `null`.
/// - If `<img>` has no `src`, the [image] getter returns `null`.
/// - If `<img>` `src` is the literal string `"null"`, the [image] getter
///   returns `null`.
/// - If `<img>` has no `height` or `width` attributes, defaults to `0.0`.
/// - If `<meta name="site_name">` is absent, [siteName] returns `null`.
/// {@endtemplate}
class HtmlMetaParser with BaseMetaInfo {
  /// {@template html_meta_parser_document}
  /// The parsed HTML [Document] to extract metadata from.
  ///
  /// This is typically the result of parsing an HTML page with the `html`
  /// package. All getters in this parser operate on this document.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to inspect. Can be `null`.
  ///
  /// ### Return value
  ///
  /// Returns the [Document] provided at construction time.
  /// {@endtemplate}
  final Document? _document;

  /// {@template html_meta_parser_constructor}
  /// Creates an [HtmlMetaParser] from a parsed HTML [Document].
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to extract metadata from.
  ///   Pass `null` to produce a parser that always returns `null` values.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = HtmlMetaParser(document);
  /// print(parser.title);
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - If `document` is `null`, all getters return `null`.
  /// {@endtemplate}
  HtmlMetaParser(this._document);

  /// {@template html_meta_parser_title}
  /// The page title extracted from the `<title>` tag inside `<head>`.
  ///
  /// Searches the document for `<title>` and returns its text content.
  /// Falls back to `null` if the tag is missing or the document is `null`.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = HtmlMetaParser(document);
  /// print('Title: ${parser.title}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing `<title>My Page</title>`:
  /// ```dart
  /// assert(parser.title == 'My Page');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the page title in a link preview card.
  /// - Use as a fallback when OG/Twitter title is missing.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if the `<title>` tag is absent.
  /// - Returns `null` if [document] is `null`.
  /// - Returns empty string if `<title>` exists but has no text content.
  ///
  /// ### Return value
  ///
  /// Returns the text content of the `<title>` tag, or `null`.
  /// {@endtemplate}
  @override
  String? get title => _document?.head?.querySelector('title')?.text;

  /// {@template html_meta_parser_description}
  /// The page description extracted from `<meta name="description">` in `<head>`.
  ///
  /// Searches the document for `<meta name="description" content="...">` and
  /// returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = HtmlMetaParser(document);
  /// print('Description: ${parser.description}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta name="description" content="A brief summary">`:
  /// ```dart
  /// assert(parser.description == 'A brief summary');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a summary below the title in a link preview.
  /// - Use as a fallback when OG/Twitter description is missing.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `<meta name="description">` is absent.
  /// - Returns `null` if the tag exists but has no `content` attribute.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` attribute of `<meta name="description">`, or `null`.
  /// {@endtemplate}
  @override
  String? get description => _document?.head
      ?.querySelector("meta[name='description']")
      ?.attributes
      .get('content');

  /// {@template html_meta_parser_image}
  /// The first image extracted from the `<img>` tag in the `<body>`.
  ///
  /// Searches the document body for the first `<img>` element and extracts its
  /// `src`, `height`, and `width` attributes. Returns a [LinkPreviewImage]
  /// containing the URL and dimensions.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = HtmlMetaParser(document);
  /// final image = parser.image;
  /// if (image != null) {
  ///   print('Image URL: ${image.url}');
  ///   print('Width: ${image.width}');
  ///   print('Height: ${image.height}');
  /// }
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing `<img src="photo.jpg" width="120" height="80">`:
  /// ```dart
  /// final image = parser.image;
  /// assert(image!.url == 'photo.jpg');
  /// assert(image.width == 120.0);
  /// assert(image.height == 80.0);
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a thumbnail in a link preview card.
  /// - Use the URL for image caching or preloading.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if no `<img>` tag exists in the body.
  /// - Returns `null` if the `src` attribute is missing or is `"null"`.
  /// - Returns `null` if [document] is `null`.
  /// - `height` defaults to `0.0` if the `height` attribute is absent or
  ///   cannot be parsed as a double.
  /// - `width` defaults to `0.0` if the `width` attribute is absent or
  ///   cannot be parsed as a double.
  ///
  /// ### Return value
  ///
  /// Returns a [LinkPreviewImage] with the image URL and dimensions,
  /// or `null` if no valid image is found.
  /// {@endtemplate}
  @override
  LinkPreviewImage? get image {
    String? img = _document?.body?.querySelector('img')?.attributes.get('src');
    double h = double.tryParse(_document?.body?.querySelector('img')?.attributes.get('height') ?? "0.0") ?? 0.0;
    double w = double.tryParse(_document?.body?.querySelector('img')?.attributes.get('width') ?? "0.0") ?? 0.0;

    if(img != null && img != "null") {
      return LinkPreviewImage(url: img, height: h, width: w);
    }

    return null;
  }

  /// {@template html_meta_parser_site_name}
  /// The site name extracted from `<meta name="site_name">` in `<head>`.
  ///
  /// Searches the document for `<meta name="site_name" content="...">` and
  /// returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = HtmlMetaParser(document);
  /// print('Site: ${parser.siteName}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta name="site_name" content="Example Blog">`:
  /// ```dart
  /// assert(parser.siteName == 'Example Blog');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the site name in a link preview card.
  /// - Use as a fallback when OG/Twitter site name is missing.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `<meta name="site_name">` is absent.
  /// - Returns `null` if the tag exists but has no `content` attribute.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` attribute of `<meta name="site_name">`, or `null`.
  /// {@endtemplate}
  @override
  String? get siteName => _document?.head
      ?.querySelector("meta[name='site_name']")
      ?.attributes
      .get('content');

  /// {@template html_meta_parser_to_string}
  /// Returns a string representation of the parsed [LinkPreviewData].
  ///
  /// Delegates to [BaseMetaInfo.parse] and converts the result to a string.
  /// Useful for debugging and logging the extracted metadata.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = HtmlMetaParser(document);
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