import '../link_preview.dart';
import 'v1/core_v1.dart';
import 'v2/core_v2.dart';

/// {@template link_preview_interface}
/// Abstract interface for fetching link preview metadata.
///
/// This interface is designed to support both legacy and modern metadata retrieval methods
/// (e.g., `v1` for legacy parsing and `v2` for structured extraction and fallback logic).
/// The `get()` method is the main entry point and will attempt `v1` first, then fall back to `v2`
/// if needed. It also supports optional customization through proxy configuration, request timeout,
/// user agent specification, and cache duration.
///
/// This is useful for scenarios like social previews, content sharing widgets, or media cards.
///
/// ## Example usage:
/// ```dart
/// final data = await MyCustomPreviewService().get('https://example.com');
/// if (data != null && data.hasAnyData) {
///   print('Title: ${data.title}');
/// }
/// ```
/// {@endtemplate}
abstract class LinkPreviewInterface {
  /// Fetches preview metadata for the provided [link] (URL or a string containing a URL).
  ///
  /// Internally, it first attempts to fetch metadata using legacy `v1` logic. If that fails,
  /// and the link is considered valid, it tries again using modern parsing from `v2`, optionally
  /// prepending a CORS proxy (if provided).
  ///
  /// Returns a [LinkPreviewData] object if successful, or `null` on failure.
  ///
  /// - [link]: The target URL to extract metadata from.
  ///
  /// Optional named parameters:
  ///
  /// - [proxy]: Optional CORS proxy to prepend to the request URL.
  ///   Useful for bypassing CORS restrictions in Flutter Web.
  ///
  /// - [cacheDuration]: How long the preview metadata should be cached.
  ///   Prevents refetching during the specified period. Default is handled internally.
  ///
  /// - [requestTimeout]: Maximum duration to wait for the response (applies to v1 only).
  ///   Helps avoid UI hangs from long network calls. Defaults to 5 seconds.
  ///
  /// - [userAgent]: Custom `User-Agent` header for the HTTP request.
  ///   Can be used to simulate browsers or crawlers.
  Future<LinkPreviewData?> get(String link, {
    String? proxy,
    Duration? cacheDuration,
    Duration? requestTimeout,
    String? userAgent
  }) async {
    final v1 = await runV1(link, proxy: proxy, cache: cacheDuration, requestTimeout: requestTimeout, userAgent: userAgent);

    if(v1 != null) {
      return v1;
    } else if(LinkPreview.isValidLink(link)) {
      // removing www. from the link if available
      if (link.startsWith('www.')) link = link.replaceFirst('www.', '');
      return await _getMetadata(link, proxyUrl: proxy, cache: cacheDuration, userAgent: userAgent);
    }

    return null;
  }
}

/// Internal helper that fetches metadata using V2 logic with optional CORS and client-side fallback.
///
/// This method:
/// - Validates the proxy (if any)
/// - Constructs the final URL to fetch (applying the proxy if needed)
/// - Tries to get metadata via [runV2]
/// - Falls back to [runV2ClientSide] if the response is null or lacks usable data
/// - Post-processes the image URL to resolve it against the proxy if applicable
///
/// Returns a [LinkPreviewData] object or `null` if metadata cannot be fetched.
Future<LinkPreviewData?> _getMetadata(String link, {
  Duration? cache = const Duration(days: 1),
  Map<String, String>? headers,
  String? userAgent,
  String? proxyUrl
}) async {
  try {
    var proxyValid = true;
    var proxy_ = proxyUrl ?? '';
    if (proxy_.isNotEmpty) proxyValid = LinkPreview.isValidUrl(proxyUrl!);
    var linkToFetch = link.trim();
    if (proxyValid) linkToFetch = (proxy_ + link).trim();
    var info = await runV2(
      linkToFetch,
      cache: cache,
      headers: headers ?? {},
      userAgent: userAgent,
    );
    if (info == null || info.hasData == false) {
      // if info is null or data is empty ,try to read URL metadata
      // client-side
      info = await runV2ClientSide(linkToFetch, cache: cache, headers: headers ?? {}, userAgent: userAgent);
    }

    var img = info?.image?.url ?? '';
    if (img.isNotEmpty && proxy_.isNotEmpty) {
      info?.image = LinkPreviewImage(height: 0.0, url: LinkPreview.resolveUrl(link, proxy_, img), width: 0.0);
    }

    return info;
  } catch (error) {
    return null;
  }
}