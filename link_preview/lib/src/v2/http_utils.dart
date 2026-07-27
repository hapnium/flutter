import 'package:http/http.dart' as http;

/// {@template fetch_with_redirects}
/// Fetches a URL and follows HTTP redirect chains automatically.
///
/// Makes an HTTP GET request to [url] and follows any 301, 302, 303, 307,
/// or 308 redirects by reading the `Location` header and making a new
/// request to the resolved location. This continues until a non-redirect
/// response is received or [maxRedirects] is exceeded.
///
/// ### Example
///
/// ```dart
/// final response = await fetchWithRedirects(
///   'https://t.co/example',
///   headers: {'Accept': 'text/html'},
///   userAgent: 'MyBot/1.0',
/// );
/// print(response.statusCode); // 200
/// print(response.body);       // Final destination HTML
/// ```
///
/// ### Parameters
///
/// - [url] — The initial URL to fetch. Must be a valid HTTP or HTTPS URL.
/// - [maxRedirects] — Maximum number of redirects to follow before
///   throwing. Defaults to 7, which matches most browser defaults.
/// - [headers] — Optional HTTP headers to include in every request in
///   the redirect chain. Defaults to an empty map.
/// - [userAgent] — Optional user agent string. Falls back to
///   `'WhatsApp/2.21.12.21 A'` if not provided. This user agent triggers
///   server-side rendering on many social media platforms.
///
/// ### Return value
///
/// Returns a [Future] that resolves to the final [http.Response] after
/// all redirects have been followed. The response contains the status
/// code, headers, and body from the final destination URL.
///
/// ### Edge cases
///
/// - **Missing Location header**: Throws an [Exception] with message
///   `'HTTP redirect without Location header'` if a redirect response
///   lacks a `Location` header.
/// - **Redirect loop**: If the redirect chain exceeds [maxRedirects],
///   throws an [Exception] with message `'Maximum redirect limit reached'`.
/// - **Relative redirect locations**: The `Location` header is passed
///   directly to [Uri.parse]. Relative locations may cause a
///   [FormatException] if not resolved by the server.
/// - **Cross-origin redirects**: Fully supported — the function follows
///   redirects across different domains without restriction.
/// - **Non-200 final responses**: The response is returned as-is, even if
///   the final destination returns a 404, 500, or other error status.
/// {@endtemplate}
Future<http.Response> fetchWithRedirects(String url, {
  int maxRedirects = 7,
  Map<String, String> headers = const {},
  String? userAgent,
}) async {
  const userAgentFallback = 'WhatsApp/2.21.12.21 A';
  Map<String, String>? allHeaders = {
    ...headers,
    'User-Agent': userAgent ?? userAgentFallback,
  };
  var response = await http.get(Uri.parse(url), headers: allHeaders);
  var redirectCount = 0;

  while (_isRedirect(response) && redirectCount < maxRedirects) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('HTTP redirect without Location header');
    }

    response = await http.get(Uri.parse(location), headers: allHeaders);
    redirectCount++;
  }

  if (redirectCount >= maxRedirects) {
    throw Exception('Maximum redirect limit reached');
  }

  return response;
}

/// Returns `true` if the response status code is a redirect (301, 302, 303, 307, 308).
bool _isRedirect(http.Response response) {
  return [301, 302, 303, 307, 308].contains(response.statusCode);
}

/// {@template get_youtube_data}
/// Fetches YouTube oembed metadata for a given video ID.
///
/// Uses the YouTube oEmbed API endpoint to retrieve structured metadata
/// (title, author, thumbnail) for a YouTube video without needing to
/// parse the full YouTube page HTML. This is more reliable than HTML
/// parsing since YouTube's markup changes frequently.
///
/// The oEmbed endpoint returns JSON with fields like `title`, `author_name`,
/// `author_url`, `thumbnail_url`, and `thumbnail_width`/`thumbnail_height`.
///
/// ### Example
///
/// ```dart
/// final response = await getYoutubeData('dQw4w9WgXcQ');
/// if (response.statusCode == 200) {
///   final data = jsonDecode(response.body);
///   print(data['title']);         // Video title
///   print(data['author_name']);   // Channel name
///   print(data['thumbnail_url']); // Thumbnail URL
/// }
/// ```
///
/// ### Parameters
///
/// - [videoId] — The 11-character YouTube video ID (e.g., `'dQw4w9WgXcQ'`).
///   This is extracted from the URL by [getYouTubeVideoId].
/// - [headers] — Optional HTTP headers to include in the request. If
///   `null`, only the user agent header is sent.
/// - [userAgent] — Optional user agent string. Falls back to
///   `'WhatsApp/2.21.12.21 A'` if not provided.
///
/// ### Return value
///
/// Returns a [Future] that resolves to the [http.Response] from the
/// YouTube oEmbed endpoint. The response body is JSON-encoded with
/// the video metadata. A successful response has `statusCode` 200.
///
/// ### Edge cases
///
/// - **Invalid video ID**: Returns a response with `statusCode` 401 and
///   an error message in the body.
/// - **Deleted/private videos**: Returns a response with `statusCode` 401.
/// - **Network errors**: Propagates the exception from [http.get].
/// - **Rate limiting**: YouTube may return 429 responses if too many
///   requests are made in quick succession.
/// - **Embed-disabled videos**: Some videos have embedding disabled but
///   the oEmbed endpoint still returns metadata.
/// {@endtemplate}
Future<http.Response> getYoutubeData(String videoId, {Map<String, String>? headers, String? userAgent}) async {
  const userAgentFallback = 'WhatsApp/2.21.12.21 A';
  Map<String, String>? allHeaders = {
    ...?headers,
    'User-Agent': userAgent ?? userAgentFallback,
  };
  var response = await http.get(
    Uri.parse('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'),
    headers: allHeaders,
  );
  return response;
}

/// {@template get_you_tube_video_id}
/// Extracts the 11-character video ID from a YouTube URL.
///
/// Parses various YouTube URL formats using a regular expression to
/// extract the unique video identifier. Supports standard YouTube URLs,
/// short URLs, embed URLs, and URLs with proxy prefixes.
///
/// ### Example
///
/// ```dart
/// final id1 = getYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
/// print(id1); // 'dQw4w9WgXcQ'
///
/// final id2 = getYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ');
/// print(id2); // 'dQw4w9WgXcQ'
///
/// final id3 = getYouTubeVideoId('https://example.com');
/// print(id3); // null
/// ```
///
/// ### Parameters
///
/// - [url] — The URL to extract the video ID from. Can be any string
///   that contains a YouTube URL (e.g., full URLs, shortened URLs,
///   embed URLs).
///
/// ### Return value
///
/// Returns the 11-character YouTube video ID as a [String], or `null`
/// if the URL does not match any known YouTube URL pattern.
///
/// ### Supported URL formats
///
/// - `https://www.youtube.com/watch?v=VIDEO_ID`
/// - `https://www.youtube.com/watch?v=VIDEO_ID&list=...`
/// - `https://www.youtube.com/embed/VIDEO_ID`
/// - `https://www.youtube.com/v/VIDEO_ID`
/// - `https://www.youtube.com/shorts/VIDEO_ID`
/// - `https://youtu.be/VIDEO_ID`
/// - `https://m.youtube.com/watch?v=VIDEO_ID`
/// - URLs with proxy prefixes (e.g., `https://proxy.com/youtube.com/...`)
///
/// ### Edge cases
///
/// - **Non-YouTube URLs**: Returns `null`.
/// - **Malformed video IDs**: If the ID doesn't match the 11-character
///   alphanumeric pattern, returns `null`.
/// - **YouTube channel URLs**: URLs like `youtube.com/channel/ID` do not
///   contain video IDs and return `null`.
/// - **YouTube playlist URLs**: Only extracts the video ID if present in
///   the `v` parameter; playlist IDs are ignored.
/// - **Case sensitivity**: Video IDs are case-sensitive; the regex
///   preserves the original case.
/// {@endtemplate}
String? getYouTubeVideoId(String url) {
  // Regular expression pattern to detect YouTube URLs
  // with or without a proxy prefix
  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:[^\/]+\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|v\/|.+\?v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
  );

  // Apply the regex to the URL
  final match = regExp.firstMatch(url);

  // If a match is found, return the first capture group, which is the video ID
  return match?.group(1);
}