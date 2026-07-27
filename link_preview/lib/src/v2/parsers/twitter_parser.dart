import 'package:html/dom.dart';

import '../../models/link_preview_data.dart';
import '../../models/link_preview_image.dart';
import '../../extensions/get_extension.dart';
import 'og_parser.dart';

/// {@template twitter_parser}
/// A parser that extracts [LinkPreviewData] from Twitter Card (`twitter:*`) meta tags.
///
/// Twitter Cards are a format for attaching rich media and metadata to
/// tweets. Pages that implement Twitter Cards expose structured data
/// via `<meta name="twitter:*">` or `<meta property="twitter:*">` tags.
/// This parser extracts the title, description, and image from these tags,
/// and falls back to Open Graph for site name and URL.
///
/// ### Usage
///
/// ```dart
/// final parser = TwitterParser(document);
/// final title = parser.title;
/// final description = parser.description;
/// final image = parser.image;
/// final siteName = parser.siteName;
/// final url = parser.url;
/// ```
///
/// ### Common actions
///
/// - Extract `twitter:title` for the page title.
/// - Extract `twitter:description` for the summary.
/// - Extract `twitter:image` for a thumbnail image.
/// - Fall back to `og:site_name` for the site name.
/// - Fall back to `og:url` for the canonical URL.
///
/// ### Edge cases
///
/// - If [document] is `null`, all getters return `null`.
/// - Twitter Card tags may use either `name` or `property` attributes;
///   this parser checks both.
/// - [siteName] and [url] delegate to [OpenGraphParser] since Twitter Cards
///   have no standard properties for these fields.
/// - Image URL `"null"` (literal string) is treated as missing.
/// {@endtemplate}
class TwitterParser with BaseMetaInfo {
  /// {@template twitter_parser_document}
  /// The parsed HTML [Document] to extract Twitter Card metadata from.
  ///
  /// All getters in this parser operate on this document, searching for
  /// `<meta name="twitter:*">` and `<meta property="twitter:*">` tags.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to inspect. Can be `null`.
  /// {@endtemplate}
  final Document? _document;

  /// {@template twitter_parser_constructor}
  /// Creates a [TwitterParser] from a parsed HTML [Document].
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to extract Twitter Card metadata from.
  ///   Pass `null` to produce a parser that always returns `null` values.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
  /// print(parser.title);
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - If `document` is `null`, all getters return `null`.
  /// {@endtemplate}
  TwitterParser(this._document);

  /// {@template twitter_parser_title}
  /// The page title extracted from the `twitter:title` meta tag.
  ///
  /// Searches the document for `<meta name="twitter:title">` first,
  /// then falls back to `<meta property="twitter:title">` if not found.
  /// Returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
  /// print('Title: ${parser.title}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta name="twitter:title" content="My Article">`:
  /// ```dart
  /// assert(parser.title == 'My Article');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the Twitter Card title in a link preview card.
  /// - Use as the primary title for Twitter sharing previews.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if neither `name` nor `property` attribute contains
  ///   `twitter:title`.
  /// - Returns `null` if [document] is `null`.
  /// - Prefers `name` attribute over `property` when both exist.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `twitter:title`, or `null`.
  /// {@endtemplate}
  @override
  String? get title => getProperty(_document, attribute: 'name', property: 'twitter:title')
      ?? getProperty(_document, property: 'twitter:title');

  /// {@template twitter_parser_description}
  /// The page description extracted from the `twitter:description` meta tag.
  ///
  /// Searches the document for `<meta name="twitter:description">` first,
  /// then falls back to `<meta property="twitter:description">` if not found.
  /// Returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
  /// print('Description: ${parser.description}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta name="twitter:description" content="A brief overview">`:
  /// ```dart
  /// assert(parser.description == 'A brief overview');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a summary below the title in a link preview.
  /// - Use as the primary description for Twitter sharing previews.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if neither `name` nor `property` attribute contains
  ///   `twitter:description`.
  /// - Returns `null` if [document] is `null`.
  /// - Prefers `name` attribute over `property` when both exist.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `twitter:description`, or `null`.
  /// {@endtemplate}
  @override
  String? get description => getProperty(_document, attribute: 'name', property: 'twitter:description')
      ?? getProperty(_document, property: 'twitter:description');

  /// {@template twitter_parser_image}
  /// The image URL extracted from the `twitter:image` meta tag.
  ///
  /// Searches the document for `<meta name="twitter:image">` first,
  /// then falls back to `<meta property="twitter:image">` if not found.
  /// Returns a [LinkPreviewImage] containing the URL and dimensions.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
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
  /// `<meta name="twitter:image" content="https://example.com/photo.jpg">`:
  /// ```dart
  /// final image = parser.image;
  /// assert(image!.url == 'https://example.com/photo.jpg');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a thumbnail in a Twitter Card preview.
  /// - Use the URL for image caching or preloading.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if neither `name` nor `property` attribute contains
  ///   `twitter:image`, or if the value is `"null"`.
  /// - Returns `null` if [document] is `null`.
  /// - `height` defaults to `0.0` if the `height` attribute is absent or
  ///   cannot be parsed as a double.
  /// - `width` defaults to `0.0` if the `width` attribute is absent or
  ///   cannot be parsed as a double.
  /// - Prefers `name` attribute over `property` when both exist.
  ///
  /// ### Return value
  ///
  /// Returns a [LinkPreviewImage] with the image URL and dimensions,
  /// or `null` if no valid image is found.
  /// {@endtemplate}
  @override
  LinkPreviewImage? get image {
    String? img = getProperty(_document, attribute: 'name', property: 'twitter:image')
        ?? getProperty(_document, property: 'twitter:image');
    double h = double.tryParse(_document?.body?.querySelector('twitter:image')?.attributes.get('height') ?? "0.0") ?? 0.0;
    double w = double.tryParse(_document?.body?.querySelector('twitter:image')?.attributes.get('width') ?? "0.0") ?? 0.0;

    if(img != null && img != "null") {
      return LinkPreviewImage(url: img, height: h, width: w);
    }

    return null;
  }

  /// {@template twitter_parser_site_name}
  /// The site name extracted via Open Graph fallback.
  ///
  /// Twitter Cards have no standard site name property, so this getter
  /// delegates to [OpenGraphParser.siteName] to extract `og:site_name`
  /// from the same document.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
  /// print('Site: ${parser.siteName}');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the site name in a Twitter Card preview.
  /// - Identify the source website for the shared link.
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
  String? get siteName => OpenGraphParser(_document).siteName;

  /// {@template twitter_parser_url}
  /// The canonical URL extracted via Open Graph fallback.
  ///
  /// Twitter Cards have no standard URL property, so this getter
  /// delegates to [OpenGraphParser.url] to extract `og:url` from the
  /// same document.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
  /// print('URL: ${parser.url}');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the canonical URL in a Twitter Card preview.
  /// - Use for deep linking or opening the page in a browser.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `og:url` is absent from the document.
  /// - Returns `null` if [document] is `null`.
  /// - A new [OpenGraphParser] is instantiated on every access.
  ///
  /// ### Return value
  ///
  /// Returns the `og:url` value, or `null` if not available.
  /// {@endtemplate}
  @override
  String? get url => OpenGraphParser(_document).url;

  /// {@template twitter_parser_to_string}
  /// Returns a string representation of the parsed [LinkPreviewData].
  ///
  /// Delegates to [BaseMetaInfo.parse] and converts the result to a string.
  /// Useful for debugging and logging the extracted metadata.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = TwitterParser(document);
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