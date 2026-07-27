import 'package:html/dom.dart';

import '../../models/link_preview_data.dart';
import '../../models/link_preview_image.dart';
import '../../extensions/get_extension.dart';

/// {@template open_graph_parser}
/// A parser that extracts [LinkPreviewData] from Open Graph (`og:*`) meta tags.
///
/// Open Graph is a protocol originally created by Facebook for rich social
/// sharing. Pages that implement OG tags expose structured metadata via
/// `<meta property="og:*">` tags in the document `<head>`. This parser
/// extracts the title, description, image, site name, and canonical URL
/// from these tags.
///
/// ### Usage
///
/// ```dart
/// final parser = OpenGraphParser(document);
/// final title = parser.title;
/// final description = parser.description;
/// final image = parser.image;
/// final siteName = parser.siteName;
/// final url = parser.url;
/// ```
///
/// ### Common actions
///
/// - Extract the `og:title` property for the page title.
/// - Extract the `og:description` property for the summary.
/// - Extract the `og:image` property for a thumbnail image.
/// - Extract the `og:site_name` property for the site identifier.
/// - Extract the `og:url` property for the canonical page URL.
///
/// ### Edge cases
///
/// - If [document] is `null`, all getters return `null`.
/// - If an OG property is missing from the document, the corresponding
///   getter returns `null`.
/// - The [image] getter attempts to parse `height` and `width` from the
///   body, but defaults to `0.0` if unavailable.
/// - Image URL `"null"` (literal string) is treated as missing.
/// {@endtemplate}
class OpenGraphParser with BaseMetaInfo {
  /// {@template open_graph_parser_document}
  /// The parsed HTML [Document] to extract Open Graph metadata from.
  ///
  /// All getters in this parser operate on this document, searching for
  /// `<meta property="og:*">` tags in the `<head>` section.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to inspect. Can be `null`.
  /// {@endtemplate}
  final Document? _document;

  /// {@template open_graph_parser_constructor}
  /// Creates an [OpenGraphParser] from a parsed HTML [Document].
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to extract Open Graph metadata from.
  ///   Pass `null` to produce a parser that always returns `null` values.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
  /// print(parser.title);
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - If `document` is `null`, all getters return `null`.
  /// {@endtemplate}
  OpenGraphParser(this._document);

  /// {@template open_graph_parser_title}
  /// The page title extracted from the `og:title` property.
  ///
  /// Searches the document for `<meta property="og:title" content="...">`
  /// and returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
  /// print('Title: ${parser.title}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta property="og:title" content="My Article">`:
  /// ```dart
  /// assert(parser.title == 'My Article');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the OG title in a link preview card.
  /// - Use as the primary title for social sharing previews.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:title` is absent from the document.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `og:title`, or `null`.
  /// {@endtemplate}
  @override
  String? get title => getProperty(_document, property: 'og:title');

  /// {@template open_graph_parser_description}
  /// The page description extracted from the `og:description` property.
  ///
  /// Searches the document for
  /// `<meta property="og:description" content="...">` and returns the
  /// `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
  /// print('Description: ${parser.description}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta property="og:description" content="A brief overview">`:
  /// ```dart
  /// assert(parser.description == 'A brief overview');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a summary below the title in a link preview.
  /// - Use as the primary description for social sharing previews.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:description` is absent from the document.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `og:description`, or `null`.
  /// {@endtemplate}
  @override
  String? get description => getProperty(_document, property: 'og:description');

  /// {@template open_graph_parser_image}
  /// The image URL extracted from the `og:image` property.
  ///
  /// Searches the document for `<meta property="og:image" content="...">`
  /// and returns a [LinkPreviewImage] containing the URL and dimensions.
  /// Height and width are parsed from the body's `og:image` element.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
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
  /// For a document containing
  /// `<meta property="og:image" content="https://example.com/image.jpg">`:
  /// ```dart
  /// final image = parser.image;
  /// assert(image!.url == 'https://example.com/image.jpg');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a thumbnail in a link preview card.
  /// - Use the URL for image caching or preloading.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:image` is absent or its value is `"null"`.
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
    String? img = getProperty(_document, property: 'og:image');
    double h = double.tryParse(_document?.body?.querySelector('og:image')?.attributes.get('height') ?? "0.0") ?? 0.0;
    double w = double.tryParse(_document?.body?.querySelector('og:image')?.attributes.get('width') ?? "0.0") ?? 0.0;

    if(img != null && img != "null") {
      return LinkPreviewImage(url: img, height: h, width: w);
    }

    return null;
  }

  /// {@template open_graph_parser_site_name}
  /// The site name extracted from the `og:site_name` property.
  ///
  /// Searches the document for
  /// `<meta property="og:site_name" content="...">` and returns the
  /// `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
  /// print('Site: ${parser.siteName}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta property="og:site_name" content="Example Blog">`:
  /// ```dart
  /// assert(parser.siteName == 'Example Blog');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the site name in a link preview card.
  /// - Identify the source website for the shared link.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:site_name` is absent from the document.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `og:site_name`, or `null`.
  /// {@endtemplate}
  @override
  String? get siteName => getProperty(_document, property: 'og:site_name');

  /// {@template open_graph_parser_url}
  /// The canonical URL extracted from the `og:url` property.
  ///
  /// Searches the document for
  /// `<meta property="og:url" content="...">` and returns the
  /// `content` attribute value. This is typically the canonical URL
  /// of the page.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
  /// print('URL: ${parser.url}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta property="og:url" content="https://example.com/article">`:
  /// ```dart
  /// assert(parser.url == 'https://example.com/article');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the canonical URL in a link preview.
  /// - Use for deep linking or opening the page in a browser.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:url` is absent from the document.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `og:url`, or `null`.
  /// {@endtemplate}
  @override
  String? get url => getProperty(_document, property: 'og:url');

  /// {@template open_graph_parser_to_string}
  /// Returns a string representation of the parsed [LinkPreviewData].
  ///
  /// Delegates to [BaseMetaInfo.parse] and converts the result to a string.
  /// Useful for debugging and logging the extracted metadata.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OpenGraphParser(document);
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