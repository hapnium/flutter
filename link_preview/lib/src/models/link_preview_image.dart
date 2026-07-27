import 'package:meta/meta.dart';

/// {@template link_preview_image}
/// A model representing the preview image metadata extracted from a link.
///
/// Includes dimensions and the direct URL to the image, typically used
/// to display thumbnails or preview cards. This class is immutable and
/// can be safely passed around without defensive copies.
///
/// ### Examples
///
/// ```dart
/// final image = LinkPreviewImage(
///   height: 120,
///   width: 200,
///   url: 'https://example.com/image.jpg',
/// );
///
/// print(image.url);      // "https://example.com/image.jpg"
/// print(image.width);    // 200.0
/// print(image.height);   // 120.0
/// ```
///
/// ```dart
/// final image = LinkPreviewImage.fromJson({
///   'height': 630.0,
///   'width': 1200.0,
///   'url': 'https://example.com/og.png',
/// });
/// ```
///
/// ### Usage
///
/// This model is used to represent image metadata within [LinkPreviewData].
/// It supports serialization to/from JSON for caching and network transport.
///
/// ```dart
/// final image = LinkPreviewImage(
///   height: 256,
///   width: 512,
///   url: 'https://cdn.example.com/banner.png',
/// );
///
/// // Store in cache
/// await cache.set('image_key', image.toJson());
///
/// // Retrieve from cache
/// final cached = LinkPreviewImage.fromJson(jsonDecode(cachedString));
/// ```
///
/// ### Common Actions
///
/// - **Parse from JSON**: Use [fromJson] to deserialize cached or network data.
/// - **Serialize to JSON**: Use [toJson] for caching or network transport.
/// - **Display**: Use [url] with an image widget (e.g., `Image.network(image.url)`).
///
/// ### Edge Cases
///
/// - [height] and [width] are `double` values — integer pixel values are
///   automatically promoted (e.g., `200` becomes `200.0`).
/// - [url] is always a non-null, fully qualified URL string. It is **not**
///   validated for format correctness.
/// - The class is marked `@immutable` — all fields are `final` and cannot
///   be changed after construction.
/// - Negative or zero dimension values are not validated and will be stored
///   as-is. The caller or UI layer is responsible for validation.
/// {@endtemplate}
@immutable
class LinkPreviewImage {
  /// {@template link_preview_image_height}
  /// The height of the image in pixels.
  ///
  /// This is typically extracted from the `og:image:height` meta tag or
  /// from the image's actual dimensions. The value is a `double` to
  /// support fractional pixel values (e.g., for Retina displays).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final image = LinkPreviewImage(
  ///   height: 630,
  ///   width: 1200,
  ///   url: 'https://example.com/og.png',
  /// );
  ///
  /// print(image.height); // 630.0
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final aspectRatio = image.width / image.height;
  /// final constrainedHeight = image.height.clamp(0, maxPreviewHeight);
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `0` if the source did not provide dimension metadata.
  /// - May be a fractional value (e.g., `1.5`) for non-integer pixel densities.
  /// - Negative values are not validated — the caller should guard against them.
  /// - Used as a required constructor parameter; there is no default value.
  /// {@endtemplate}
  final double height;

  /// {@template link_preview_image_url}
  /// The direct URL to the image resource.
  ///
  /// This should be a fully qualified URL including the scheme (e.g.,
  /// `https://`). It is typically extracted from the `og:image` meta tag.
  /// The URL may point to any image format (JPEG, PNG, WebP, etc.).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final image = LinkPreviewImage(
  ///   height: 120,
  ///   width: 200,
  ///   url: 'https://cdn.example.com/thumbnail.jpg',
  /// );
  ///
  /// print(image.url); // "https://cdn.example.com/thumbnail.jpg"
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Display in a Flutter image widget
  /// Image.network(
  ///   image.url,
  ///   width: image.width,
  ///   height: image.height,
  ///   fit: BoxFit.cover,
  /// );
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - The URL is **not** validated for format — malformed URLs are stored as-is.
  /// - May be a relative URL if the parser did not resolve it against the base URL.
  /// - May contain query parameters, fragments, or authentication tokens.
  /// - If the image is no longer available at this URL, the link preview will
  ///   fail to display the image.
  /// - Used as a required constructor parameter; there is no default value.
  /// {@endtemplate}
  final String url;

  /// {@template link_preview_image_width}
  /// The width of the image in pixels.
  ///
  /// This is typically extracted from the `og:image:width` meta tag or
  /// from the image's actual dimensions. The value is a `double` to
  /// support fractional pixel values (e.g., for Retina displays).
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final image = LinkPreviewImage(
  ///   height: 630,
  ///   width: 1200,
  ///   url: 'https://example.com/og.png',
  /// );
  ///
  /// print(image.width); // 1200.0
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final aspectRatio = image.width / image.height;
  /// final constrainedWidth = image.width.clamp(0, maxPreviewWidth);
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - May be `0` if the source did not provide dimension metadata.
  /// - May be a fractional value (e.g., `1.5`) for non-integer pixel densities.
  /// - Negative values are not validated — the caller should guard against them.
  /// - Used as a required constructor parameter; there is no default value.
  /// {@endtemplate}
  final double width;

  /// {@template link_preview_image_constructor}
  /// Creates an immutable [LinkPreviewImage] instance.
  ///
  /// All parameters are required. There are no optional or default values —
  /// every field must be explicitly provided.
  ///
  /// ### Parameters
  ///
  /// - `height` — The image height in pixels as a `double`.
  /// - `url` — The direct URL to the image as a [String].
  /// - `width` — The image width in pixels as a `double`.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// const image = LinkPreviewImage(
  ///   height: 120,
  ///   width: 200,
  ///   url: 'https://example.com/thumb.jpg',
  /// );
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final image = LinkPreviewImage(
  ///   height: metadata['height'] as double,
  ///   width: metadata['width'] as double,
  ///   url: metadata['url'] as String,
  /// );
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - This is a `const` constructor — instances can be compile-time constants
  ///   if all arguments are compile-time constants.
  /// - No validation is performed on the values. Negative dimensions, empty
  ///   URLs, and zero values are all accepted.
  /// {@endtemplate}
  const LinkPreviewImage({
    required this.height,
    required this.url,
    required this.width,
  });

  /// {@template link_preview_image_fromJson}
  /// Creates a [LinkPreviewImage] from a JSON-compatible map.
  ///
  /// The map is expected to contain `height` (double), `url` (String),
  /// and `width` (double) keys. This factory is typically used when
  /// deserializing cached image metadata.
  ///
  /// ### Parameters
  ///
  /// - `json` — A [Map] with string keys and dynamic values, typically
  ///   from `jsonDecode`. Must contain `height`, `url`, and `width` keys.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final image = LinkPreviewImage.fromJson({
  ///   'height': 630.0,
  ///   'width': 1200.0,
  ///   'url': 'https://example.com/og.png',
  /// });
  ///
  /// print(image.url);    // "https://example.com/og.png"
  /// print(image.height); // 630.0
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final jsonString = await cache.get('image_cache');
  /// final json = jsonDecode(jsonString) as Map<String, dynamic>;
  /// final image = LinkPreviewImage.fromJson(json);
  ///
  /// // Use in a widget
  /// Image.network(image.url);
  /// ```
  ///
  /// ### Edge Cases
  /// - If `json['height']` is an `int`, it will be automatically promoted
  ///   to `double` by Dart's type system (since `int` is a subtype of `num`).
  /// - If `json['url']` is missing, a [TypeError] is thrown at runtime.
  /// - If `json['height']` or `json['width']` is `null`, a [TypeError] is thrown.
  /// - The URL string is not validated for format.
  ///
  /// ### Return value
  ///
  /// A new [LinkPreviewImage] instance with all fields populated from the map.
  /// {@endtemplate}
  factory LinkPreviewImage.fromJson(Map<String, dynamic> json) {
    return LinkPreviewImage(
      height: json['height'] as double,
      url: json['url'] as String,
      width: json['width'] as double,
    );
  }

  /// {@template link_preview_image_toJson}
  /// Converts this [LinkPreviewImage] to a JSON-serializable map.
  ///
  /// The returned map contains `height`, `url`, and `width` keys and is
  /// suitable for passing to `jsonEncode` or storing in a local cache.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final image = LinkPreviewImage(
  ///   height: 120,
  ///   width: 200,
  ///   url: 'https://example.com/thumb.jpg',
  /// );
  ///
  /// final json = image.toJson();
  /// print(json);
  /// // {height: 120.0, url: 'https://example.com/thumb.jpg', width: 200.0}
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final encoded = jsonEncode(image.toJson());
  /// await cache.set('image_key', encoded);
  /// ```
  ///
  /// ### Edge Cases
  ///
  /// - The `url` value is stored as a [String], not a [Uri].
  /// - `height` and `width` are stored as [double] values (not integers).
  /// - The map is a new instance each time — mutations do not affect the
  ///   original [LinkPreviewImage].
  ///
  /// ### Return value
  ///
  /// A [Map] with `height` ([double]), `url` ([String]), and `width` ([double])
  /// keys.
  /// {@endtemplate}
  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'url': url,
      'width': width,
    };
  }
}