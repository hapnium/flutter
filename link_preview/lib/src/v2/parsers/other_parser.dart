import 'package:html/dom.dart';

import '../../models/link_preview_data.dart';
import '../../models/link_preview_image.dart';
import '../../extensions/get_extension.dart';

/// {@template other_parser}
/// A parser that extracts [LinkPreviewData] from generic `<meta>` tags
/// using `name` attributes instead of `property` attributes.
///
/// This parser targets meta tags in the form
/// `<meta name="title" content="...">`, which is a non-Open-Graph convention
/// used by some websites. It serves as a fallback when OG, Twitter Card,
/// JSON-LD, and HTML `<meta>` parsers have not extracted metadata.
///
/// ### Usage
///
/// ```dart
/// final parser = OtherParser(document);
/// final title = parser.title;
/// final description = parser.description;
/// final image = parser.image;
/// final siteName = parser.siteName;
/// final url = parser.url;
/// ```
///
/// ### Common actions
///
/// - Extract the `title` from `<meta name="title">`.
/// - Extract the `description` from `<meta name="description">`.
/// - Extract the `image` from `<meta name="image">`.
/// - Extract the `site_name` from `<meta name="site_name">`.
/// - Extract the `url` from `<meta name="url">`.
///
/// ### Edge cases
///
/// - If [document] is `null`, all getters return `null`.
/// - If a meta tag is missing, the corresponding getter returns `null`.
/// - The [image] getter attempts to parse `height` and `width` from the
///   body, but defaults to `0.0` if unavailable.
/// - Image URL `"null"` (literal string) is treated as missing.
/// {@endtemplate}
class OtherParser with BaseMetaInfo {
  /// {@template other_parser_document}
  /// The parsed HTML [Document] to extract generic meta tags from.
  ///
  /// All getters in this parser operate on this document, searching for
  /// `<meta name="*" content="...">` tags in the `<head>` section.
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to inspect. Can be `null`.
  /// {@endtemplate}
  final Document? _document;

  /// {@template other_parser_constructor}
  /// Creates an [OtherParser] from a parsed HTML [Document].
  ///
  /// ### Parameters
  ///
  /// - `document` — The parsed [Document] to extract generic meta tags from.
  ///   Pass `null` to produce a parser that always returns `null` values.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
  /// print(parser.title);
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - If `document` is `null`, all getters return `null`.
  /// {@endtemplate}
  OtherParser(this._document);

  /// {@template other_parser_title}
  /// The page title extracted from the `<meta name="title">` tag.
  ///
  /// Searches the document for `<meta name="title" content="...">` and
  /// returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
  /// print('Title: ${parser.title}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta name="title" content="My Page">`:
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
  /// - Returns `null` if `<meta name="title">` is absent.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `<meta name="title">`, or `null`.
  /// {@endtemplate}
  @override
  String? get title => getProperty(_document, attribute: 'name', property: 'title');

  /// {@template other_parser_description}
  /// The page description extracted from the `<meta name="description">` tag.
  ///
  /// Searches the document for
  /// `<meta name="description" content="...">` and returns the `content`
  /// attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
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
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `<meta name="description">`, or `null`.
  /// {@endtemplate}
  @override
  String? get description => getProperty(_document, attribute: 'name', property: 'description');

  /// {@template other_parser_image}
  /// The image URL extracted from the `<meta name="image">` tag.
  ///
  /// Searches the document for `<meta name="image" content="...">` and
  /// returns a [LinkPreviewImage] containing the URL and dimensions.
  /// Height and width are parsed from the body's `image` element.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
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
  /// `<meta name="image" content="https://example.com/photo.jpg">`:
  /// ```dart
  /// final image = parser.image;
  /// assert(image!.url == 'https://example.com/photo.jpg');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display a thumbnail in a link preview card.
  /// - Use the URL for image caching or preloading.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `<meta name="image">` is absent or its value is `"null"`.
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
    String? img = getProperty(_document, attribute: 'name', property: 'image');
    double h = double.tryParse(_document?.body?.querySelector('image')?.attributes.get('height') ?? "0.0") ?? 0.0;
    double w = double.tryParse(_document?.body?.querySelector('image')?.attributes.get('width') ?? "0.0") ?? 0.0;

    if(img != null && img != "null") {
      return LinkPreviewImage(url: img, height: h, width: w);
    }

    return null;
  }

  /// {@template other_parser_site_name}
  /// The site name extracted from the `<meta name="site_name">` tag.
  ///
  /// Searches the document for
  /// `<meta name="site_name" content="...">` and returns the `content`
  /// attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
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
  /// - Identify the source website for the shared link.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `<meta name="site_name">` is absent.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `<meta name="site_name">`, or `null`.
  /// {@endtemplate}
  @override
  String? get siteName => getProperty(_document, attribute: 'name', property: 'site_name');

  /// {@template other_parser_url}
  /// The page URL extracted from the `<meta name="url">` tag.
  ///
  /// Searches the document for `<meta name="url" content="...">` and
  /// returns the `content` attribute value.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
  /// print('URL: ${parser.url}');
  /// ```
  ///
  /// ### Example
  ///
  /// For a document containing
  /// `<meta name="url" content="https://example.com/page">`:
  /// ```dart
  /// assert(parser.url == 'https://example.com/page');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display the canonical URL in a link preview.
  /// - Use for deep linking or opening the page in a browser.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if `<meta name="url">` is absent.
  /// - Returns `null` if [document] is `null`.
  ///
  /// ### Return value
  ///
  /// Returns the `content` of `<meta name="url">`, or `null`.
  /// {@endtemplate}
  @override
  String? get url => getProperty(_document, attribute: 'name', property: 'url');

  /// {@template other_parser_to_string}
  /// Returns a string representation of the parsed [LinkPreviewData].
  ///
  /// Delegates to [BaseMetaInfo.parse] and converts the result to a string.
  /// Useful for debugging and logging the extracted metadata.
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final parser = OtherParser(document);
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