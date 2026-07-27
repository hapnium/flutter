import 'link_preview_image.dart';

/// {@template link_preview_data}
/// A data model representing metadata extracted from a web link for preview purposes.
///
/// It includes fields like title, description, image, site name, and URL.
/// This model is typically constructed after parsing metadata from a webpage and is
/// suitable for caching, display, and serialization.
///
/// ### Examples
///
/// ```dart
/// final preview = LinkPreviewData()
///   ..title = "OpenAI"
///   ..description = "AI research and deployment company"
///   ..url = "https://openai.com"
///   ..timeout = DateTime.now().add(Duration(hours: 1));
/// ```
///
/// ```dart
/// final preview = LinkPreviewData.fromJson({
///   'title': 'Flutter',
///   'description': 'Build apps for any screen',
///   'url': 'https://flutter.dev',
///   'timeout': 1700000000,
/// });
/// ```
///
/// ### Usage
///
/// This model is used to represent parsed link metadata for display in
/// link preview widgets. It supports serialization to/from JSON for caching.
///
/// ```dart
/// final preview = LinkPreviewData()
///   ..title = 'Example'
///   ..url = 'https://example.com';
///
/// // Check if preview has useful data
/// if (preview.hasAnyData) {
///   print('Preview available: ${preview.title}');
/// }
/// ```
///
/// ### Common Actions
///
/// - **Parse from JSON**: Use [fromJson] to deserialize cached or network data.
/// - **Serialize to JSON**: Use [toJson] for caching or network transport.
/// - **Immutable copy**: Use [copyWith] to create a modified duplicate.
/// - **Check completeness**: Use [hasAllMetadata] to verify all fields are present.
///
/// ### Edge Cases
///
/// - [title], [description], [url], and [siteName] may all be `null` if parsing failed.
/// - [timeout] is a `late` field and will throw a [LateInitializationError] if read
///   before being set.
/// - The [image] field is a nested [LinkPreviewImage] and may be `null` if the page
///   has no preview image.
/// - [fromJson] will throw a [TypeError] if the JSON map contains unexpected types.
/// {@endtemplate}
class LinkPreviewData extends InfoBase with BaseMetaInfo, MetadataKeys {
  /// {@template link_preview_data_fromJson}
  /// Creates a [LinkPreviewData] instance from a JSON-compatible map.
  ///
  /// This factory parses a decoded JSON map and populates all fields of the
  /// model, including deserializing the nested [LinkPreviewImage] if present.
  ///
  /// The `timeout` field is expected to be a Unix timestamp in **seconds**
  /// (not milliseconds), and is converted to a [DateTime] internally.
  ///
  /// ### Parameters
  ///
  /// - `json` — A [Map] with string keys and dynamic values, typically from
  ///   `jsonDecode`. Must contain at least a `timeout` key (as a numeric value).
  ///   All other keys are optional.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final data = LinkPreviewData.fromJson({
  ///   'title': 'GitHub',
  ///   'description': 'Where the world builds software',
  ///   'image': {
  ///     'height': 120.0,
  ///     'width': 200.0,
  ///     'url': 'https://github.com/og.png',
  ///   },
  ///   'siteName': 'GitHub',
  ///   'url': 'https://github.com',
  ///   'timeout': 1700000000,
  /// });
  ///
  /// print(data.title); // "GitHub"
  /// print(data.image?.width); // 200.0
  /// ```
///
  /// ### Usage
  ///
  /// ```dart
  /// final jsonString = await cache.get('preview_cache_key');
  /// final json = jsonDecode(jsonString) as Map<String, dynamic>;
  /// final preview = LinkPreviewData.fromJson(json);
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - If `json['image']` is `null`, [image] will be set to `null`.
  /// - If `json['timeout']` is missing, a null dereference error occurs.
  /// - If `json['timeout']` is in milliseconds instead of seconds, the resulting
  ///   [DateTime] will be far in the future.
  /// - Keys not present in the map result in `null` for their respective fields.
  ///
  /// ### Return value
  ///
  /// Returns a fully constructed [LinkPreviewData] instance with all fields
  /// populated from the provided map.
  /// {@endtemplate}
  static LinkPreviewData fromJson(Map<String, dynamic> json) {
    return LinkPreviewData()
      ..title = json[MetadataKeys.kTitle]
      ..description = json[MetadataKeys.kDescription]
      ..image = json[MetadataKeys.kImage] != null ? LinkPreviewImage.fromJson(json[MetadataKeys.kImage]) : null
      ..siteName = json[MetadataKeys.kSiteName]
      ..url = json[MetadataKeys.kUrl]
      ..timeout = DateTime.fromMillisecondsSinceEpoch(json[MetadataKeys.kTimeout]! * 1000);
  }

  /// {@template link_preview_data_toJson}
  /// Converts this [LinkPreviewData] instance to a JSON-serializable map.
  ///
  /// The returned map uses [MetadataKeys] constants as keys and is suitable
  /// for passing to `jsonEncode` or storing in a local cache.
  ///
  /// The `timeout` field is serialized as a Unix timestamp in **seconds**
  /// (not milliseconds).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final preview = LinkPreviewData()
  ///   ..title = 'Example'
  ///   ..url = 'https://example.com'
  ///   ..timeout = DateTime(2026, 1, 1);
  ///
  /// final json = preview.toJson();
  /// print(json['title']); // "Example"
  /// print(json['url']);   // "https://example.com"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final encoded = jsonEncode(preview.toJson());
  /// await cache.write('preview_key', encoded);
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Fields that are `null` will be stored as `null` in the map.
  /// - The [image] field is serialized as a nested map (not a string).
  /// - If [timeout] has not been set (late initialization), a
  ///   [LateInitializationError] is thrown.
  ///
  /// ### Return value
  ///
  /// A [Map] with [String] keys from [MetadataKeys] and dynamic values.
  /// {@endtemplate}
  Map<String, dynamic> toJson() {
    return {
      MetadataKeys.kTitle: title,
      MetadataKeys.kDescription: description,
      MetadataKeys.kImage: image,
      MetadataKeys.kSiteName: siteName,
      MetadataKeys.kUrl: url,
      MetadataKeys.kTimeout: timeout.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// {@template link_preview_data_copyWith}
  /// Creates an immutable copy of this [LinkPreviewData] with selected fields
  /// overridden by the provided values.
  ///
  /// Any parameter left as `null` retains the value from the current instance.
  /// This is useful for creating modified versions without mutating the original.
  ///
  /// ### Parameters
  ///
  /// - `title` — New title value, or `null` to keep the current title.
  /// - `description` — New description value, or `null` to keep the current description.
  /// - `image` — New preview image, or `null` to keep the current image.
  /// - `url` — New URL value, or `null` to keep the current URL.
  /// - `siteName` — New site name value, or `null` to keep the current site name.
  /// - `timeout` — New timeout value, or `null` to keep the current timeout.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final original = LinkPreviewData()
  ///   ..title = 'Old Title'
  ///   ..url = 'https://old.com'
  ///   ..timeout = DateTime(2025, 1, 1);
  ///
  /// final updated = original.copyWith(
  ///   title: 'New Title',
  ///   url: 'https://new.com',
  /// );
  ///
  /// print(updated.title); // "New Title"
  /// print(updated.url);   // "https://new.com"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Refresh only the timeout while keeping everything else
  /// final refreshed = cachedPreview.copyWith(
  ///   timeout: DateTime.now().add(Duration(hours: 1)),
  /// );
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - The returned copy is a new instance; mutations to it do not affect the original.
  /// - The [timeout] of the copied instance must already be initialized on the
  ///   original, otherwise a [LateInitializationError] occurs when copying.
  /// - All parameters default to `null`, so calling `copyWith()` with no arguments
  ///   creates a shallow copy with the same field values.
  ///
  /// ### Return value
  ///
  /// A new [LinkPreviewData] instance with the specified fields overridden.
  /// {@endtemplate}
  LinkPreviewData copyWith({
    String? title,
    String? description,
    LinkPreviewImage? image,
    String? url,
    String? siteName,
    DateTime? timeout,
  }) {
    return LinkPreviewData()
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..image = image ?? this.image
      ..url = url ?? this.url
      ..siteName = siteName ?? this.siteName
      ..timeout = timeout ?? this.timeout;
  }

  @override
  String toString() => toJson().toString();

  /// {@template link_preview_data_hasAllMetadata}
  /// Whether all core metadata fields ([title], [description], [image], [url])
  /// are non-null.
  ///
  /// This does **not** check [siteName] or [timeout]. Use this to determine
  /// whether the preview has enough data to render a full preview card.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final full = LinkPreviewData()
  ///   ..title = 'Title'
  ///   ..description = 'Desc'
  ///   ..image = LinkPreviewImage(height: 100, width: 200, url: 'https://img.png')
  ///   ..url = 'https://example.com'
  ///   ..timeout = DateTime.now();
  ///
  /// print(full.hasAllMetadata); // true
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (preview.hasAllMetadata) {
  ///   showFullPreviewCard(preview);
  /// } else {
  ///   showMinimalPreview(preview);
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Returns `false` if any of the four fields is `null`.
  /// - Does **not** validate whether strings are empty or whitespace-only.
  /// - Does **not** check [siteName].
  ///
  /// ### Return value
  ///
  /// `true` if [title], [description], [image], and [url] are all non-null;
  /// `false` otherwise.
  /// {@endtemplate}
  bool get hasAllMetadata => title != null && description != null && image != null && url != null;

  /// {@template link_preview_data_hasTitle}
  /// Whether the [title] field is non-null and non-empty.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..title = 'My Page';
  /// print(preview.hasTitle); // true
  /// ```
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..title = '';
  /// print(preview.hasTitle); // false
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (preview.hasTitle) {
  ///   titleWidget.text = preview.title!;
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Returns `false` if [title] is `null`.
  /// - Returns `false` if [title] is an empty string `''`.
  /// - Returns `true` for whitespace-only strings (e.g., `" "`).
  ///
  /// ### Return value
  ///
  /// `true` if [title] is non-null and has at least one character.
  /// {@endtemplate}
  bool get hasTitle => title?.isNotEmpty == true;

  /// {@template link_preview_data_hasDescription}
  /// Whether the [description] field is non-null and non-empty.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..description = 'A short summary';
  /// print(preview.hasDescription); // true
  /// ```
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..description = '';
  /// print(preview.hasDescription); // false
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (preview.hasDescription) {
  ///   subtitleWidget.text = preview.description!;
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Returns `false` if [description] is `null`.
  /// - Returns `false` if [description] is an empty string `''`.
  /// - Returns `true` for whitespace-only strings (e.g., `" "`).
  ///
  /// ### Return value
  ///
  /// `true` if [description] is non-null and has at least one character.
  /// {@endtemplate}
  bool get hasDescription => description?.isNotEmpty == true;

  /// {@template link_preview_data_hasImage}
  /// Whether the [image] is non-null and its [LinkPreviewImage.url] is non-empty.
  ///
  /// This is a composite check — it verifies both that the image object exists
  /// and that it contains a valid URL string.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final preview = LinkPreviewData()
  ///   ..image = LinkPreviewImage(
  ///     height: 120,
  ///     width: 200,
  ///     url: 'https://example.com/og.png',
  ///   );
  ///
  /// print(preview.hasImage); // true
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (preview.hasImage) {
  ///   imageWidget.network(preview.image!.url);
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Returns `false` if [image] is `null`.
  /// - Returns `false` if [image] is non-null but [LinkPreviewImage.url] is empty.
  /// - Does **not** validate that the URL points to an actual image resource.
  ///
  /// ### Return value
  ///
  /// `true` if [image] is non-null and [image.url] is non-empty.
  /// {@endtemplate}
  bool get hasImage => image != null && image?.url.isNotEmpty == true;

  /// {@template link_preview_data_hasLink}
  /// Whether the [url] field is non-null and non-empty.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..url = 'https://example.com';
  /// print(preview.hasLink); // true
  /// ```
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..url = '';
  /// print(preview.hasLink); // false
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (preview.hasLink) {
  ///   launchUrl(Uri.parse(preview.url!));
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Returns `false` if [url] is `null`.
  /// - Returns `false` if [url] is an empty string `''`.
  /// - Does **not** validate the URL format (e.g., missing scheme).
  ///
  /// ### Return value
  ///
  /// `true` if [url] is non-null and has at least one character.
  /// {@endtemplate}
  bool get hasLink => url?.isNotEmpty == true;

  /// {@template link_preview_data_hasAnyData}
  /// Whether at least one of [hasTitle], [hasDescription], or [hasImage] is `true`.
  ///
  /// This is the broadest availability check — use it to determine if there is
  /// any useful content to display in a preview, even if incomplete.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final preview = LinkPreviewData()..title = 'Only Title';
  /// print(preview.hasAnyData); // true (hasTitle is true)
  /// ```
  ///
  /// ```dart
  /// final preview = LinkPreviewData();
  /// print(preview.hasAnyData); // false (all fields null)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (preview.hasAnyData) {
  ///   showPreviewWidget(preview);
  /// } else {
  ///   showFallbackLink(preview.url);
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Does **not** check [hasLink]. A preview with only a URL but no title,
  ///   description, or image returns `false`.
  /// - Returns `false` if all fields are `null` or empty.
  ///
  /// ### Return value
  ///
  /// `true` if at least one of [hasTitle], [hasDescription], or [hasImage] is `true`.
  /// {@endtemplate}
  bool get hasAnyData => hasTitle || hasDescription || hasImage;
}

/// {@template metadata_keys}
/// A mixin providing a collection of constant keys used for identifying metadata
/// fields within maps, such as when serializing or deserializing [LinkPreviewData].
///
/// These keys are typically used to extract or encode title, description, image, URL,
/// site name, and expiration time (`timeout`) from a JSON object.
///
/// ### Examples
///
/// ```dart
/// final json = {
///   MetadataKeys.kTitle: 'OpenAI',
///   MetadataKeys.kDescription: 'AI Research Lab',
///   MetadataKeys.kImage: {'height': 120, 'width': 200, 'url': 'https://img.png'},
///   MetadataKeys.kUrl: 'https://openai.com',
///   MetadataKeys.kSiteName: 'OpenAI',
///   MetadataKeys.kTimeout: 1700000000,
/// };
/// ```
///
/// ### Usage
///
/// ```dart
/// // Accessing keys for serialization
/// final map = {
///   MetadataKeys.kTitle: preview.title,
///   MetadataKeys.kUrl: preview.url,
/// };
///
/// // Accessing keys for deserialization
/// final title = json[MetadataKeys.kTitle] as String?;
/// ```
///
/// ### Common Actions
///
/// - **Serialize**: Use constants as map keys when building JSON payloads.
/// - **Deserialize**: Use constants to safely extract values from JSON maps.
/// - **Avoid typos**: Centralizes key strings to prevent mismatched key names.
///
/// ### Edge Cases
///
/// - All keys are `static const`, so they cannot be overridden or changed.
/// - The key values are lowercase camelCase strings matching the JSON spec.
/// - `kTimeout` stores a Unix timestamp in **seconds**, not milliseconds.
/// {@endtemplate}
mixin MetadataKeys {
  /// {@template metadata_keys_kTitle}
  /// The JSON key for the title of the linked page.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// const json = {'title': 'My Page'};
  /// final title = json[MetadataKeys.kTitle]; // "My Page"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// map[MetadataKeys.kTitle] = preview.title;
  /// ```
  ///
  /// ### Return value
  ///
  /// The string literal `'title'`.
  /// {@endtemplate}
  static const kTitle = 'title';

  /// {@template metadata_keys_kDescription}
  /// The JSON key for the description or summary of the linked content.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// const json = {'description': 'A short summary'};
  /// final desc = json[MetadataKeys.kDescription]; // "A short summary"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// map[MetadataKeys.kDescription] = preview.description;
  /// ```
  ///
  /// ### Return value
  ///
  /// The string literal `'description'`.
  /// {@endtemplate}
  static const kDescription = 'description';

  /// {@template metadata_keys_kImage}
  /// The JSON key for the preview image data (a nested map with `height`,
  /// `width`, and `url` fields).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// const json = {
  ///   'image': {'height': 120, 'width': 200, 'url': 'https://img.png'},
  /// };
  /// final imageData = json[MetadataKeys.kImage];
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// map[MetadataKeys.kImage] = preview.image?.toJson();
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - The value may be `null` if the page has no preview image.
  /// - When present, it is a `Map<String, dynamic>`, not a string URL.
  ///
  /// ### Return value
  ///
  /// The string literal `'image'`.
  /// {@endtemplate}
  static const kImage = 'image';

  /// {@template metadata_keys_kUrl}
  /// The JSON key for the URL of the linked page.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// const json = {'url': 'https://example.com'};
  /// final url = json[MetadataKeys.kUrl]; // "https://example.com"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// map[MetadataKeys.kUrl] = preview.url;
  /// ```
  ///
  /// ### Return value
  ///
  /// The string literal `'url'`.
  /// {@endtemplate}
  static const kUrl = 'url';

  /// {@template metadata_keys_kSiteName}
  /// The JSON key for the site or publisher's name hosting the content.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// const json = {'siteName': 'GitHub'};
  /// final name = json[MetadataKeys.kSiteName]; // "GitHub"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// map[MetadataKeys.kSiteName] = preview.siteName;
  /// ```
  ///
  /// ### Return value
  ///
  /// The string literal `'siteName'`.
  /// {@endtemplate}
  static const kSiteName = 'siteName';

  /// {@template metadata_keys_kTimeout}
  /// The JSON key for the cache expiration timestamp, stored as a Unix
  /// timestamp in **seconds** (not milliseconds).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final expiry = DateTime.now().add(Duration(hours: 1));
  /// final json = {MetadataKeys.kTimeout: expiry.millisecondsSinceEpoch ~/ 1000};
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// map[MetadataKeys.kTimeout] = preview.timeout.millisecondsSinceEpoch ~/ 1000;
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Storing milliseconds instead of seconds will result in a far-future date.
  /// - This is a `late` field on [LinkPreviewData] — reading before assignment
  ///   throws a [LateInitializationError].
  ///
  /// ### Return value
  ///
  /// The string literal `'timeout'`.
  /// {@endtemplate}
  static const kTimeout = 'timeout';
}

/// {@template base_meta_info}
/// A reusable metadata mixin that contains optional fields representing the
/// common metadata properties extracted from a web page or link.
///
/// Can be used in classes that need to hold temporary or pre-processed metadata
/// before being converted into a [LinkPreviewData] object.
///
/// This mixin also includes a `hasData` utility to quickly check if the object
/// contains any valid metadata other than the URL.
///
/// Fields default to `null` unless explicitly set.
///
/// ### Examples
///
/// ```dart
/// class MyParser with BaseMetaInfo {
///   void parseHtml(String html) {
///     title = extractTitle(html);
///     description = extractDescription(html);
///     image = extractImage(html);
///     url = extractUrl(html);
///   }
/// }
///
/// final parser = MyParser()..parseHtml(rawHtml);
/// if (parser.hasData) {
///   final preview = parser.parse();
/// }
/// ```
///
/// ### Usage
///
/// Use this mixin when building a parser or intermediate representation
/// that collects metadata fields incrementally before producing a final
/// [LinkPreviewData] via [parse].
///
/// ### Common Actions
///
/// - **Populate fields**: Set [title], [description], [image], [url], [siteName].
/// - **Check availability**: Use [hasData] to see if any meaningful data exists.
/// - **Convert to model**: Call [parse] to get a [LinkPreviewData] instance.
///
/// ### Edge Cases
///
/// - All fields are nullable and default to `null`.
/// - The [hasData] getter also checks that field values are not the literal
///   string `'null'` (a common JSON deserialization artifact).
/// - [parse] does **not** set [InfoBase.timeout] — the caller must set it.
/// {@endtemplate}
mixin BaseMetaInfo {
  /// {@template base_meta_info_title}
  /// The title of the linked page.
  ///
  /// Typically extracted from the `<title>` tag or the `og:title` meta tag.
  /// Default value is `null`.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// info.title = 'Flutter — Build apps for any screen';
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (info.title != null) {
  ///   titleWidget.text = info.title!;
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `null` if the page has no title or parsing failed.
  /// - May be an empty string `''` if the title tag is present but empty.
  /// - May contain HTML entities if not properly decoded during parsing.
  /// {@endtemplate}
  String? title;

  /// {@template base_meta_info_description}
  /// The description or summary of the linked content.
  ///
  /// Typically extracted from the `<meta name="description">` tag or the
  /// `og:description` meta tag. Default value is `null`.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// info.description = 'Flutter transforms the app development process.';
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (info.description != null) {
  ///   subtitleWidget.text = info.description!;
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `null` if no description meta tag is present.
  /// - May be truncated by the source page (typically ~160 characters).
  /// - May contain newlines or HTML if not cleaned during parsing.
  /// {@endtemplate}
  String? description;

  /// {@template base_meta_info_image}
  /// The associated preview image for the link.
  ///
  /// Typically extracted from the `og:image` meta tag and parsed into
  /// a [LinkPreviewImage] with height, width, and URL. Default value is `null`.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// info.image = LinkPreviewImage(
  ///   height: 630,
  ///   width: 1200,
  ///   url: 'https://example.com/og-image.png',
  /// );
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (info.image != null) {
  ///   imageWidget.network(info.image!.url);
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `null` if no image meta tag is present.
  /// - The [LinkPreviewImage.url] may be a relative URL that needs resolution.
  /// - Dimensions may be `0` or incorrect if the source provides bad data.
  /// {@endtemplate}
  LinkPreviewImage? image;

  /// {@template base_meta_info_url}
  /// The URL of the link source.
  ///
  /// This is the canonical URL that was parsed. It should be a fully qualified
  /// URL including the scheme (e.g., `https://`). Default value is `null`.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// info.url = 'https://flutter.dev';
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (info.url != null) {
  ///   launchUrl(Uri.parse(info.url!));
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `null` if the URL was not provided or could not be resolved.
  /// - May be a relative URL if the parser did not resolve it.
  /// - May contain query parameters or fragments that were part of the original.
  /// {@endtemplate}
  String? url;

  /// {@template base_meta_info_siteName}
  /// The site or domain name hosting the content.
  ///
  /// Typically extracted from the `og:site_name` meta tag. This is distinct
  /// from [url] — it is a human-readable name (e.g., "GitHub") rather than
  /// a URL. Default value is `null`.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// info.siteName = 'GitHub';
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final display = info.siteName ?? Uri.parse(info.url!).host;
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `null` if no site name meta tag is present.
  /// - May differ from the domain in [url] (e.g., a subdomain or alias).
  /// {@endtemplate}
  String? siteName;

  /// {@template base_meta_info_hasData}
  /// Whether at least one of [title], [description], or [image] contains
  /// meaningful non-null, non-empty data.
  ///
  /// This getter also explicitly checks that values are not the literal
  /// string `'null'`, which can occur from JSON deserialization bugs.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final info = BaseMetaInfoImpl()
  ///   ..title = 'My Page';
  /// print(info.hasData); // true
  /// ```
  ///
  /// ```dart
  /// final info = BaseMetaInfoImpl()
  ///   ..title = 'null';
  /// print(info.hasData); // false (literal "null" string)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (parser.hasData) {
  ///   final preview = parser.parse();
  ///   cache.save(preview);
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - Returns `false` if all fields are `null`.
  /// - Returns `false` if all fields are empty strings.
  /// - Returns `false` if values are the literal string `'null'`.
  /// - Does **not** check [url] — a preview with only a URL is considered empty.
  ///
  /// ### Return value
  ///
  /// `true` if at least one of [title], [description], or [image] is
  /// non-null, non-empty, and not the literal string `'null'`.
  /// {@endtemplate}
  bool get hasData =>
      ((title?.isNotEmpty ?? false) && title != 'null') ||
      ((description?.isNotEmpty ?? false) && description != 'null') ||
      ((image?.url.isNotEmpty ?? false) && image?.url != 'null');

  /// {@template base_meta_info_parse}
  /// Converts this [BaseMetaInfo] mixin into a fully constructed [LinkPreviewData]
  /// by copying the current values of all fields.
  ///
  /// The returned [LinkPreviewData] will **not** have [InfoBase.timeout] set —
  /// the caller must assign it before use (e.g., for caching expiration).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final parser = MyParser()
  ///   ..title = 'Example'
  ///   ..description = 'An example page'
  ///   ..url = 'https://example.com';
  ///
  /// final preview = parser.parse()
  ///   ..timeout = DateTime.now().add(Duration(hours: 1));
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final data = parser.parse()
  ///   ..timeout = DateTime.now().add(Duration(hours: 6));
  /// await cache.save(key, data.toJson());
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - [siteName] is copied but [timeout] is **not** (it remains uninitialized
  ///   on the returned instance).
  /// - Fields remain nullable in the returned [LinkPreviewData].
  /// - This is a shallow copy — [image] references the same object.
  ///
  /// ### Return value
  ///
  /// A new [LinkPreviewData] instance with [title], [description], [image],
  /// [url], and [siteName] copied from this mixin.
  /// {@endtemplate}
  LinkPreviewData parse() {
    return LinkPreviewData()
      ..title = title
      ..description = description
      ..image = image
      ..url = url
      ..siteName = siteName;
  }
}

/// {@template info_base}
/// An abstract base class that defines a required [timeout] field, representing
/// the expiration or invalidation timestamp for metadata.
///
/// Typically used as a superclass for link preview models to ensure they carry
/// a cache expiry mechanism. Any class extending [InfoBase] must initialize
/// the [timeout] field before it is read.
///
/// ### Examples
///
/// ```dart
/// final info = LinkPreviewData()
///   ..timeout = DateTime.now().add(Duration(hours: 1));
///
/// if (info.timeout.isBefore(DateTime.now())) {
///   refreshPreview(info.url);
/// }
/// ```
///
/// ### Usage
///
/// Extend this class to enforce that all link preview models include a
/// cache expiration timestamp. This is critical for cache invalidation
/// strategies.
///
/// ```dart
/// class MyPreview extends InfoBase {
///   late String title;
///   late String url;
/// }
/// ```
///
/// ### Edge Cases
///
/// - [timeout] is `late` and **must** be assigned before reading, or a
///   [LateInitializationError] is thrown.
/// - There is no default value — the field is uninitialized by design.
/// - If [timeout] is set to a past date, the preview is immediately expired.
/// {@endtemplate}
abstract class InfoBase {
  /// {@template info_base_timeout}
  /// The expiration time for the metadata.
  ///
  /// This is used by cache mechanisms to determine whether the preview data
  /// is still valid or should be refreshed. The value must be a [DateTime]
  /// representing when the data expires.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// // Cache for 1 hour
  /// info.timeout = DateTime.now().add(Duration(hours: 1));
  ///
  /// // Cache until end of day
  /// info.timeout = DateTime(
  ///   DateTime.now().year,
  ///   DateTime.now().month,
  ///   DateTime.now().day,
  ///   23, 59, 59,
  /// );
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Check if expired
  /// if (info.timeout.isBefore(DateTime.now())) {
  ///   // Data is stale, refresh it
  ///   await refreshPreview();
  /// }
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - This field is `late` — reading before assignment throws
  ///   a [LateInitializationError].
  /// - Setting to a past [DateTime] marks the data as immediately expired.
  /// - Setting to a future [DateTime] keeps the data valid until that time.
  /// - There is no built-in validation — the caller controls the expiration.
  /// {@endtemplate}
  late DateTime timeout;
}