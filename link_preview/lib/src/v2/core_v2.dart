import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import '../extensions/get_extension.dart';
import 'parsers/html_parser.dart';
import 'parsers/json_id_parser.dart';
import 'parsers/og_parser.dart';
import 'parsers/other_parser.dart';
import 'parsers/twitter_parser.dart';
import 'parsers/youtube_parser.dart';
import 'http_utils.dart';

import 'package:link_preview/link_preview.dart';

CacheManager _manager = LinkPreview.cacheManager();

/// {@template run_v2_client_side}
/// Fetches a link preview for a URL that generates meta tags client-side.
///
/// This is a specialized wrapper around [runV2] that uses a browser-like
/// user agent to work around sites (notably Twitter/X) that render meta tags
/// via JavaScript. By spoofing the user agent, the server-side rendered
/// response includes the meta tags that would otherwise only be available
/// after client-side rendering.
///
/// ### Example
///
/// ```dart
/// final preview = await runV2ClientSide('https://twitter.com/user/status/123');
/// if (preview != null) {
///   print(preview.title);
///   print(preview.image?.url);
/// }
/// ```
///
/// ### Parameters
///
/// - [url] — The URL to fetch. Must be a valid URL recognized by
///   [LinkPreview.isURL]. If the URL is invalid, `null` is returned.
/// - [cache] — Duration for which the result is cached. Defaults to 24
///   hours. Pass `null` to disable caching entirely. Pass `Duration.zero`
///   to skip cache read but still store the result.
/// - [headers] — Optional HTTP headers to include in the request. Useful
///   for adding authentication tokens or custom accept headers.
/// - [userAgent] — The user agent string sent with the request. Defaults
///   to `'WhatsApp/2.21.12.21 A'` which triggers server-side meta tag
///   rendering on most platforms.
///
/// ### Return value
///
/// Returns a [Future] that resolves to a [LinkPreviewData] containing the
/// extracted metadata, or `null` if:
/// - The URL is invalid
/// - The request fails
/// - The response cannot be parsed
///
/// ### Edge cases
///
/// - If the URL points directly to an image (content-type starts with
///   `image/`), the returned [LinkPreviewData] will have an empty title
///   and the image URL set to the original URL.
/// - If the cache is expired or disabled, a fresh fetch is performed.
/// - Network errors are caught and logged, returning `null`.
/// - Redirect chains are followed automatically (up to 7 redirects).
/// {@endtemplate}
Future<LinkPreviewData?> runV2ClientSide(String url, {
  Duration? cache = const Duration(hours: 24),
  Map<String, String> headers = const {},
  String? userAgent = 'WhatsApp/2.21.12.21 A',
}) => runV2(url, cache: cache, headers: headers, userAgent: userAgent);

/// {@template run_v2}
/// Fetches a URL, extracts metadata, and returns a [LinkPreviewData].
///
/// This is the core function that powers the v2 link preview pipeline. It:
/// 1. Checks the cache for a valid entry
/// 2. Validates the URL format
/// 3. Fetches the URL (or YouTube oembed data for YouTube URLs)
/// 4. Parses the HTML response through a chain of parsers
/// 5. Caches and returns the result
///
/// The parser chain tries OpenGraph, Twitter Cards, YouTube, JSON-LD,
/// HTML meta tags, and finally a generic HTML parser. The first parser
/// to populate all metadata fields wins.
///
/// ### Example
///
/// ```dart
/// final preview = await runV2('https://example.com');
/// if (preview != null) {
///   print('Title: ${preview.title}');
///   print('Description: ${preview.description}');
///   print('Image: ${preview.image?.url}');
/// }
/// ```
///
/// ### Parameters
///
/// - [url] — The URL to fetch and extract metadata from. Must pass
///   [LinkPreview.isURL] validation. If invalid, `null` is returned.
/// - [cache] — Duration for which the result is cached. Defaults to 24
///   hours. Pass `null` to disable caching entirely. Pass `Duration.zero`
///   to skip cache read but still store the result for future requests.
/// - [headers] — Optional HTTP headers to include in the request.
/// - [userAgent] — Optional user agent string. If `null`, the server's
///   default user agent is used. YouTube oembed requests always use the
///   default WhatsApp user agent regardless of this parameter.
///
/// ### Return value
///
/// Returns a [Future] that resolves to a [LinkPreviewData] containing the
/// extracted metadata (title, description, image, site name, URL), or
/// `null` if the URL is invalid or the request fails.
///
/// ### Edge cases
///
/// - **Image URLs**: If the response content-type starts with `image/`,
///   a minimal [LinkPreviewData] is returned with the image URL and empty
///   title/description/siteName.
/// - **YouTube URLs**: Automatically detected and fetched via the YouTube
///   oembed endpoint, which returns structured JSON instead of HTML.
/// - **Cache expiry**: Cached entries older than [cache] duration are
///   treated as a cache miss and re-fetched.
/// - **Cache disabled**: When `cache` is `null`, any existing cache entry
///   is deleted and no new cache entry is stored.
/// - **Network errors**: Caught and logged via [debugPrint], returning
///   `null` without propagating the exception.
/// - **Redirect chains**: Followed automatically via [fetchWithRedirects].
/// - **Relative image URLs**: Resolved against the page URL if the parsers
///   return relative paths.
/// - **Non-200 responses**: [responseToDocument] returns `null`, causing
///   this function to return the default info (domain as title, URL as
///   description).
/// {@endtemplate}
Future<LinkPreviewData?> runV2(String url, {
  Duration? cache = const Duration(hours: 24),
  Map<String, String> headers = const {},
  String? userAgent,
}) async {
  LinkPreviewData? info;
  if ((cache?.inSeconds ?? 0) > 0) {
    info = await _manager.get(url);
  } else {
    _manager.delete(url);
  }
  if (info != null) return info;

  if (!LinkPreview.isURL(url)) return null;

  // Default values; Domain name as the [title],
  // URL as the [description]
  info?.title = getDomain(url);
  info?.description = url;
  info?.siteName = getDomain(url);
  info?.url = url;

  try {
    // Make our network call
    String? videoId = getYouTubeVideoId(url);
    http.Response response = videoId == null
        ? await fetchWithRedirects(url, headers: headers, userAgent: userAgent)
        : await getYoutubeData(videoId, headers: headers, userAgent: userAgent);
    String? headerContentType = response.headers['content-type'];

    if (headerContentType != null && headerContentType.startsWith('image/')) {
      info?.title = '';
      info?.description = '';
      info?.siteName = '';
      info?.image = LinkPreviewImage(url: url, height: 0.0, width: 0.0);
      return info;
    }

    final document = responseToDocument(response);
    if (document == null) return info;

    final data_ = _extractMetadata(document, url: url);

    if (data_ == null) {
      return info;
    } else if (cache != null) {
      data_.timeout = DateTime.now().add(cache);
      _manager.set(url, data_);
    }

    return data_;
  } catch (error) {
    debugPrint('AnyLinkPreview - Error in $url response ($error)');
    // Any sort of exceptions due to wrong URL's, host lookup failure etc.
    return null;
  }
}

/// {@template response_to_document}
/// Converts an HTTP response body into an HTML [Document].
///
/// This function takes the raw bytes from an [http.Response], decodes
/// them using UTF-8, and parses the result into an [html.Document] tree
/// that can be queried by the metadata parsers.
///
/// ### Example
///
/// ```dart
/// final response = await http.get(Uri.parse('https://example.com'));
/// final document = responseToDocument(response);
/// if (document != null) {
///   final title = document.querySelector('title')?.text;
/// }
/// ```
///
/// ### Parameters
///
/// - [response] — The HTTP response to parse. Must have a `statusCode` of
///   200 for parsing to proceed. The response body bytes are decoded as
///   UTF-8 text.
///
/// ### Return value
///
/// Returns a [Document] if the response was successfully parsed, or `null`
/// if:
/// - The status code is not 200
/// - The body cannot be decoded as valid UTF-8
/// - The HTML is malformed and cannot be parsed
///
/// ### Edge cases
///
/// - **Non-200 status codes**: Returns `null` immediately without
///   attempting to parse the body.
/// - **Binary responses**: If the response body is binary (e.g., an image
///   file served with a text content-type), UTF-8 decoding may produce
///   garbage or throw. The catch block returns `null` in this case.
/// - **Empty body**: Returns a valid but empty [Document].
/// - **Encoding issues**: UTF-8 decode errors are caught, returning `null`.
/// {@endtemplate}
Document? responseToDocument(http.Response response) {
  if (response.statusCode != 200) return null;

  Document? document;
  try {
    document = parse(utf8.decode(response.bodyBytes));
  } catch (err) {
    return document;
  }

  return document;
}

/// Extracts metadata from [document] using the parser chain, with [url]
/// as a fallback for relative image resolution.
LinkPreviewData? _extractMetadata(Document document, {String? url}) => _parse(document, url: url);

/// Default parser strategy: tries each parser in order and merges results.
/// Stops early when all metadata fields are populated.
LinkPreviewData _parse(Document? document, {String? url}) {
  final output = LinkPreviewData();

  final parsers = [
    _openGraph(document),
    _twitterCard(document),
    _youtubeCard(document),
    _jsonLdSchema(document),
    _htmlMeta(document),
    _otherParser(document),
  ];

  for (final p in parsers) {
    if (p == null) continue;

    output.title ??= p.title;
    output.description ??= p.description;
    output.image ??= p.image;
    output.siteName ??= p.siteName;
    output.url ??= p.url ?? url;

    if (output.hasAllMetadata) break;
  }
  // If the parsers did not extract a URL from the metadata, use the given
  // url, if available. This is used to attempt to resolve relative images.
  final url_ = output.url ?? url;
  final img = output.image;
  if (url_ != null && img != null) {
    output.image = LinkPreviewImage(height: 0.0, url: Uri.parse(url_).resolve(img.url).toString(), width: 0.0);
  }

  return output;
}

/// Extracts metadata from OpenGraph meta tags (og:title, og:description, etc.).
LinkPreviewData? _openGraph(Document? document) {
  try {
    return OpenGraphParser(document).parse();
  } catch (e) {
    return null;
  }
}

/// Extracts metadata from standard HTML meta tags (title, description).
LinkPreviewData? _htmlMeta(Document? document) {
  try {
    return HtmlMetaParser(document).parse();
  } catch (e) {
    return null;
  }
}

/// Extracts metadata from JSON-LD structured data scripts.
LinkPreviewData? _jsonLdSchema(Document? document) {
  try {
    return JsonLdParser(document).parse();
  } catch (e) {
    return null;
  }
}

/// Extracts metadata from YouTube-specific meta tags.
LinkPreviewData? _youtubeCard(Document? document) {
  try {
    return YoutubeParser(document).parse();
  } catch (e) {
    return null;
  }
}

/// Extracts metadata from Twitter Card meta tags (twitter:title, etc.).
LinkPreviewData? _twitterCard(Document? document) {
  try {
    return TwitterParser(document).parse();
  } catch (e) {
    return null;
  }
}

/// Fallback parser that extracts data from generic HTML elements.
LinkPreviewData? _otherParser(Document? document) {
  try {
    return OtherParser(document).parse();
  } catch (e) {
    return null;
  }
}