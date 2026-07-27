import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Element;
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' as parser show parse;
import 'package:http/http.dart' as http show get;
import 'package:link_preview/link_preview.dart';

CacheManager _manager = LinkPreview.cacheManager();

/// Prefixes [baseUrl] with [proxy] when non-null.
String _calculateUrl(String baseUrl, String? proxy) {
  if (proxy != null) {
    return '$proxy$baseUrl';
  }

  return baseUrl;
}

/// Extracts the `content` attribute of the first `<meta>` tag matching [propertyValue].
String? _getMetaContent(Document document, String propertyValue) {
  final meta = document.getElementsByTagName('meta');
  final element = meta.firstWhere(
    (e) => e.attributes['property'] == propertyValue,
    orElse: () => meta.firstWhere(
      (e) => e.attributes['name'] == propertyValue,
      orElse: () => Element.tag(null),
    ),
  );

  return element.attributes['content']?.trim();
}

/// Returns `true` if the document declares a UTF-8 charset or has no charset declaration.
bool _hasUTF8Charset(Document document) {
  final emptyElement = Element.tag(null);
  final meta = document.getElementsByTagName('meta');
  final element = meta.firstWhere(
    (e) => e.attributes.containsKey('charset'),
    orElse: () => emptyElement,
  );

  if (element == emptyElement) return true;
  return element.attributes['charset']!.toLowerCase() == 'utf-8';
}

/// Returns the page title from `<title>`, `og:title`, `twitter:title`, or `og:site_name`.
String? _getTitle(Document document) {
  final titleElements = document.getElementsByTagName('title');
  if (titleElements.isNotEmpty) return titleElements.first.text;

  return _getMetaContent(document, 'og:title') ??
      _getMetaContent(document, 'twitter:title') ??
      _getMetaContent(document, 'og:site_name');
}

/// Returns the page description from `og:description`, `description`, or `twitter:description`.
String? _getDescription(Document document) =>
    _getMetaContent(document, 'og:description') ??
    _getMetaContent(document, 'description') ??
    _getMetaContent(document, 'twitter:description');

/// Collects all image URLs from Open Graph / Twitter meta tags, falling back to `<img>` tags.
List<String> _getImageUrls(Document document, String baseUrl) {
  final meta = document.getElementsByTagName('meta');
  var attribute = 'content';
  var elements = meta
      .where((e) => e.attributes['property'] == 'og:image' || e.attributes['property'] == 'twitter:image',)
      .toList();

  if (elements.isEmpty) {
    elements = document.getElementsByTagName('img');
    attribute = 'src';
  }

  return elements.fold<List<String>>([], (previousValue, element) {
    final actualImageUrl = _getActualImageUrl(baseUrl, element.attributes[attribute]?.trim());

    return actualImageUrl != null ? [...previousValue, actualImageUrl] : previousValue;
  });
}

/// Resolves a potentially relative image URL against [baseUrl], filtering out invalid sources.
String? _getActualImageUrl(String baseUrl, String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty || imageUrl.startsWith('data')) {
    return null;
  }

  if (imageUrl.contains('.svg') || imageUrl.contains('.gif')) return null;

  if (imageUrl.startsWith('//')) imageUrl = 'https:$imageUrl';

  if (!imageUrl.startsWith('http')) {
    if (baseUrl.endsWith('/') && imageUrl.startsWith('/')) {
      imageUrl = '${baseUrl.substring(0, baseUrl.length - 1)}$imageUrl';
    } else if (!baseUrl.endsWith('/') && !imageUrl.startsWith('/')) {
      imageUrl = '$baseUrl/$imageUrl';
    } else {
      imageUrl = '$baseUrl$imageUrl';
    }
  }

  return imageUrl;
}

/// Downloads the image at [url] and returns its decoded pixel dimensions.
Future<Size> _getImageSize(String url) {
  final completer = Completer<Size>();
  final stream = Image.network(url).image.resolve(ImageConfiguration.empty);
  late ImageStreamListener streamListener;

  void onError(Object error, StackTrace? stackTrace) {
    completer.completeError(error, stackTrace);
  }

  void listener(ImageInfo info, bool _) {
    if (!completer.isCompleted) {
      completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }
    stream.removeListener(streamListener);
  }

  streamListener = ImageStreamListener(listener, onError: onError);

  stream.addListener(streamListener);
  return completer.future;
}

/// Iterates up to five candidate image URLs and returns the one with the largest pixel area.
Future<String> _getBiggestImageUrl(List<String> imageUrls, String? proxy) async {
  if (imageUrls.length > 5) {
    imageUrls.removeRange(5, imageUrls.length);
  }

  var currentUrl = imageUrls[0];
  var currentArea = 0.0;

  await Future.forEach(imageUrls, (String url) async {
    final size = await _getImageSize(_calculateUrl(url, proxy));
    final area = size.width * size.height;
    if (area > currentArea) {
      currentArea = area;
      currentUrl = _calculateUrl(url, proxy);
    }
  });

  return currentUrl;
}

/// {@template run_v1}
/// Parses the given [text] and returns [LinkPreviewData] for the first found link.
///
/// This is the primary entry point for the V1 link preview pipeline. It extracts
/// URLs from the provided text, fetches the HTML content of the first URL found,
/// and parses metadata (title, description, image) from the response.
///
/// ### Parameters
///
/// - [text] — The raw text to scan for links. Emails are filtered out before
///   URL extraction so that `user@example.com` is not treated as a link.
/// - [proxy] — An optional proxy prefix prepended to every resolved URL.
///   When non-null the final URL becomes `$proxy$url`.
/// - [cache] — Duration for which preview data is cached. Defaults to
///   `Duration(hours: 24)`. Pass `Duration.zero` or `null` to disable caching.
/// - [requestTimeout] — Maximum time allowed for the HTTP request.
///   Defaults to `Duration(seconds: 5)`.
/// - [userAgent] — Custom `User-Agent` header sent with the HTTP request.
///   Defaults to `'WhatsApp/2'`.
///
/// ### Return value
///
/// Returns a [Future] that resolves to:
/// - A [LinkPreviewData] containing the title, description, image, and URL of
///   the first link found, or
/// - `null` if no link is found, the text contains only emails, the response
///   is not UTF-8 encoded, or an error occurs during fetching/parsing.
///
/// ### Common actions
///
/// ```dart
/// // Basic usage — fetch preview for a single URL
/// final data = await runV1('Check out https://flutter.dev');
/// print(data?.title); // "Flutter - Build apps for any screen"
///
/// // With a proxy prefix
/// final data = await runV1(
///   'Visit https://example.com',
///   proxy: 'https://my-proxy.com/?url=',
/// );
///
/// // Disable caching
/// final data = await runV1(
///   'https://example.com',
///   cache: Duration.zero,
/// );
///
/// // Custom timeout and user agent
/// final data = await runV1(
///   'https://example.com',
///   requestTimeout: Duration(seconds: 10),
///   userAgent: 'MyBot/1.0',
/// );
/// ```
///
/// ### Edge cases
///
/// - Returns `null` when [text] contains only email addresses.
/// - Returns `null` when no valid URL is found in [text].
/// - Returns `null` when the HTTP response content type is an image
///   (a [LinkPreviewData] with only the image field populated is returned).
/// - Returns `null` when the document charset is not UTF-8.
/// - Returns `null` on any network or parsing error (swallowed internally).
/// - When multiple URLs are present, only the first is processed.
/// - Protocol-less URLs (e.g. `example.com`) are automatically prefixed with
///   `https://`.
/// - When multiple images are found, the one with the largest pixel area is
///   selected.
/// - When [cache] is non-zero, the result is cached and returned on
///   subsequent calls with the same [text].
/// {@endtemplate}
Future<LinkPreviewData?> runV1(String text, {
  String? proxy,
  Duration? cache = const Duration(hours: 24),
  Duration? requestTimeout,
  String? userAgent
}) async {
  LinkPreviewData? previewData;

  String? previewDataDescription;
  LinkPreviewImage? previewDataImage;
  String? previewDataTitle;
  String? previewDataUrl;

  LinkPreviewData? info;
  if ((cache?.inSeconds ?? 0) > 0) {
    info = await _manager.get(text);
  } else {
    _manager.delete(text);
  }
  if (info != null) return info;

  try {
    final emailRegexp = RegExp(regexEmail, caseSensitive: false);
    final textWithoutEmails = text.replaceAllMapped(emailRegexp, (match) => '').trim();

    if (textWithoutEmails.isEmpty) {
      return previewData;
    }

    final urlRegexp = RegExp(regexLink, caseSensitive: false);
    final matches = urlRegexp.allMatches(textWithoutEmails);

    if (matches.isEmpty) {
      return previewData;
    }

    var url = textWithoutEmails.substring(matches.first.start, matches.first.end);

    if (!url.toLowerCase().startsWith('http')) {
      url = 'https://$url';
    }
    previewDataUrl = _calculateUrl(url, proxy);
    final uri = Uri.parse(previewDataUrl);
    final response = await http.get(uri, headers: {
      'User-Agent': userAgent ?? 'WhatsApp/2',
    }).timeout(requestTimeout ?? const Duration(seconds: 5));
    final document = parser.parse(utf8.decode(response.bodyBytes));

    final imageRegexp = RegExp(regexImageContentType);

    if (imageRegexp.hasMatch(response.headers['content-type'] ?? '')) {
      final imageSize = await _getImageSize(previewDataUrl);
      previewDataImage = LinkPreviewImage(
        height: imageSize.height,
        url: previewDataUrl,
        width: imageSize.width,
      );

      return LinkPreviewData()
        ..image = previewDataImage
        ..url = previewDataUrl;
    }

    if (!_hasUTF8Charset(document)) {
      return previewData;
    }

    final title = _getTitle(document);
    if (title != null) {
      previewDataTitle = title.trim();
    }

    final description = _getDescription(document);
    if (description != null) {
      previewDataDescription = description.trim();
    }

    final imageUrls = _getImageUrls(document, url);

    Size imageSize;
    String imageUrl;

    if (imageUrls.isNotEmpty) {
      imageUrl = imageUrls.length == 1 ? _calculateUrl(imageUrls[0], proxy) : await _getBiggestImageUrl(imageUrls, proxy);

      imageSize = await _getImageSize(imageUrl);
      previewDataImage = LinkPreviewImage(
        height: imageSize.height,
        url: imageUrl,
        width: imageSize.width,
      );
    }

    final data_ = LinkPreviewData()
      ..description = previewDataDescription
      ..image = previewDataImage
      ..url = previewDataUrl
      ..title = previewDataTitle;
    _manager.set(url, data_);

    return data_;
  } catch (e) {
    return null;
  }
}

/// {@template regex_email}
/// Regular expression pattern that matches standard email addresses.
///
/// The pattern matches strings of the form `local@domain.tld` where:
/// - The local part may contain alphanumeric characters, dots, underscores,
///   percent signs, plus signs, and hyphens.
/// - The domain part may contain alphanumeric characters, dots, and hyphens.
/// - The top-level domain must be at least two alphabetic characters.
///
/// ### Example
///
/// ```dart
/// final regexp = RegExp(regexEmail, caseSensitive: false);
/// regexp.hasMatch('user@example.com'); // true
/// regexp.hasMatch('not-an-email');     // false
/// regexp.hasMatch('name.last+tag@sub.domain.co.uk'); // true
/// ```
///
/// ### Usage
///
/// ```dart
/// // Strip emails from text before URL extraction
/// final cleaned = text.replaceAllMapped(
///   RegExp(regexEmail, caseSensitive: false),
///   (match) => '',
/// );
/// ```
///
/// ### Return value
///
/// A raw [String] pattern suitable for use with [RegExp].
/// {@endtemplate}
const regexEmail = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}';

/// {@template regex_image_content_type}
/// Regular expression pattern that matches HTTP `Content-Type` values for images.
///
/// The pattern matches any string beginning with `image/` followed by zero or
/// more characters, covering all standard image MIME types such as
/// `image/png`, `image/jpeg`, `image/gif`, `image/webp`, and `image/svg+xml`.
///
/// ### Example
///
/// ```dart
/// final regexp = RegExp(regexImageContentType);
/// regexp.hasMatch('image/png');      // true
/// regexp.hasMatch('image/jpeg');     // true
/// regexp.hasMatch('text/html');      // false
/// regexp.hasMatch('application/json'); // false
/// ```
///
/// ### Usage
///
/// ```dart
/// // Check if an HTTP response is an image
/// final contentType = response.headers['content-type'] ?? '';
/// if (RegExp(regexImageContentType).hasMatch(contentType)) {
///   // Handle direct image response
/// }
/// ```
///
/// ### Return value
///
/// A raw [String] pattern suitable for use with [RegExp].
/// {@endtemplate}
const regexImageContentType = r'image\/*';

/// {@template regex_link}
/// Regular expression pattern that finds URLs within a block of text.
///
/// The pattern matches both absolute URLs (with a protocol prefix such as
/// `http://`, `https://`, or `ftp://`) and protocol-less domain references
/// such as `example.com/path`. It captures:
///
/// 1. The optional protocol prefix (`http`, `https`, `ftp`).
/// 2. The domain name including subdomains and multi-part TLDs.
/// 3. An optional path, query string, or fragment identifier.
///
/// ### Example
///
/// ```dart
/// final regexp = RegExp(regexLink, caseSensitive: false);
/// final matches = regexp.allMatches('Visit https://flutter.dev today');
/// matches.first.group(0); // 'https://flutter.dev'
///
/// // Protocol-less URL
/// final matches2 = regexp.allMatches('Go to example.com/path?q=1');
/// matches2.first.group(0); // 'example.com/path?q=1'
/// ```
///
/// ### Usage
///
/// ```dart
/// // Extract the first URL from user input
/// final regexp = RegExp(regexLink, caseSensitive: false);
/// final match = regexp.firstMatch(userInput);
/// if (match != null) {
///   final url = userInput.substring(match.start, match.end);
/// }
/// ```
///
/// ### Return value
///
/// A raw [String] pattern suitable for use with [RegExp].
/// {@endtemplate}
const regexLink = r'((http|ftp|https):\/\/)?([\w_-]+(?:(?:\.[\w_-]*[a-zA-Z_][\w_-]*)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?[^\.\s]';