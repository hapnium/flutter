import 'package:html/dom.dart';

/// {@template get_extension}
/// Extension on [Map] to provide convenient getter methods for extracting
/// values from maps with type safety and flexibility.
///
/// This extension is particularly useful when working with parsed HTML
/// or JSON data where values may be of mixed types and need safe
/// extraction with automatic type conversion.
///
/// ### Common actions
///
/// - Extract a string value: `map.get('key')`
/// - Extract a raw dynamic value: `map.getDynamic('key')`
///
/// ### Edge cases
///
/// - Returns `null` if the key does not exist
/// - `get()` automatically converts non-string values to string representation
/// - `get()` extracts the first element if the value is a [List]
///
/// ### Usage
///
/// ```dart
/// final metadata = {'title': 'My Page', 'tags': ['flutter', 'dart']};
/// final title = metadata.get('title'); // 'My Page'
/// final firstTag = metadata.get('tags'); // 'flutter'
/// ```
/// {@endtemplate}
extension GetExtension on Map {
  /// {@template get_extension_get}
  /// Retrieves the value associated with the given [key] from the map.
  ///
  /// If the value is a [List], returns the first element.
  /// Otherwise, returns the value converted to a [String].
  /// Returns `null` if the key does not exist in the map.
  ///
  /// ### Parameters
  ///
  /// - [key]: The key to look up in the map. Can be any type since
  ///   [Map] supports dynamic keys.
  ///
  /// ### Return value
  ///
  /// Returns a [String?] — the first element of a list, the string
  /// representation of the value, or `null` if the key is missing.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final map = {'key': 'value'};
  /// final value = map.get('key'); // Returns 'value'
  /// ```
  ///
  /// ```dart
  /// final map = {'count': 42};
  /// final value = map.get('count'); // Returns '42'
  /// ```
  ///
  /// ```dart
  /// final map = {'tags': ['flutter', 'dart']};
  /// final value = map.get('tags'); // Returns 'flutter' (first element)
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Extract metadata values from parsed HTML attributes
  /// - Safely convert dynamic values to strings
  /// - Get the first item from list-valued map entries
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` for missing keys
  /// - For list values, only the first element is returned;
  ///   subsequent elements are discarded
  /// - For `null` values, returns `null` (via `value?.toString()`)
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Safe extraction from parsed HTML attributes
  /// final metaTags = document.getElementsByTagName('meta');
  /// final description = attributes.get('content');
  /// ```
  /// {@endtemplate}
  String? get(dynamic key) {
    final value = this[key];
    if (value is List) return value.first;
    return value?.toString();
  }

  /// {@template get_extension_get_dynamic}
  /// Retrieves the raw value associated with the given [key] from the map.
  ///
  /// Returns the value without any type conversion, allowing access to
  /// the original type stored in the map. This is useful when you need
  /// to preserve the original type (e.g., [int], [bool], [List]) rather
  /// than converting to a string.
  ///
  /// ### Parameters
  ///
  /// - [key]: The key to look up in the map. Can be any type since
  ///   [Map] supports dynamic keys.
  ///
  /// ### Return value
  ///
  /// Returns `dynamic` — the raw value associated with the key,
  /// or `null` if the key does not exist.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final map = {'key': 123};
  /// final value = map.getDynamic('key'); // Returns 123 as dynamic
  /// ```
  ///
  /// ```dart
  /// final map = {'active': true};
  /// final value = map.getDynamic('active'); // Returns true as dynamic
  /// ```
  ///
  /// ```dart
  /// final map = {'items': [1, 2, 3]};
  /// final value = map.getDynamic('items'); // Returns [1, 2, 3] as List<int>
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Access values that need to retain their original type
  /// - Check for key existence (returns `null` for missing keys)
  /// - Retrieve complex nested structures without string conversion
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if the key does not exist
  /// - Does not perform any type coercion — the value is returned as-is
  /// - The return type is [dynamic], so callers must handle type checking
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Preserve original type when extracting
  /// final count = map.getDynamic('count');
  /// if (count is int) {
  ///   print('Count is an integer: $count');
  /// }
  /// ```
  /// {@endtemplate}
  dynamic getDynamic(dynamic key) {
    return this[key];
  }
}

/// {@template get_domain}
/// Extracts the domain name from a given [url] string.
///
/// Parses the URL and returns the first segment of the host
/// (e.g., 'www' from 'https://www.example.com/path').
/// This is useful for extracting the subdomain or primary domain
/// identifier from a URL.
///
/// ### Parameters
///
/// - [url]: The URL string to parse. Must be a valid URI format.
///
/// ### Return value
///
/// Returns a [String?] — the first segment of the host (before the
/// first dot), or `null` if the URL cannot be parsed.
///
/// ### Example
///
/// ```dart
/// final domain = getDomain('https://www.example.com/path');
/// // Returns 'www'
/// ```
///
/// ```dart
/// final domain = getDomain('https://example.com/path');
/// // Returns 'example'
/// ```
///
/// ### Common actions
///
/// - Extract subdomain from a URL
/// - Identify the primary domain segment
///
/// ### Edge cases
///
/// - Returns the full host if there are no dots (e.g., 'localhost')
/// - Only returns the first segment; 'sub.domain.com' returns 'sub'
/// - Does not validate the URL format — relies on [Uri.parse]
///
/// ### Usage
///
/// ```dart
/// final subdomain = getDomain('https://api.example.com/v1');
/// print(subdomain); // 'api'
/// ```
/// {@endtemplate}
String? getDomain(String url) {
  return Uri.parse(url).host.split('.')[0];
}

/// {@template get_property}
/// Extracts a specific property value from an HTML [Document].
///
/// Searches for elements matching the given [tag] (default: 'meta'),
/// then looks for an element where the [attribute] (default: 'property')
/// matches the [property] value. Returns the value of the [key] attribute
/// (default: 'content') from that element.
///
/// This is commonly used for extracting Open Graph (og:) metadata
/// from HTML documents for link preview generation.
///
/// ### Parameters
///
/// - [document]: The HTML document to search. Can be `null`, in which
///   case `null` is returned immediately.
/// - [tag]: The HTML tag to search for. Defaults to `'meta'`.
/// - [attribute]: The attribute to match against. Defaults to `'property'`.
/// - [property]: The property value to look for (e.g., `'og:title'`).
///   When `null`, the first element matching the tag is returned.
/// - [key]: The attribute key to extract the value from. Defaults to `'content'`.
///
/// ### Return value
///
/// Returns a [String?] — the value of the [key] attribute from the
/// matching element, or `null` if no match is found or [document] is null.
///
/// ### Example
///
/// ```dart
/// final description = getProperty(
///   document,
///   property: 'og:description',
///   key: 'content',
/// );
/// ```
///
/// ```dart
/// final title = getProperty(
///   document,
///   tag: 'meta',
///   attribute: 'name',
///   property: 'twitter:title',
///   key: 'content',
/// );
/// ```
///
/// ### Common actions
///
/// - Extract Open Graph metadata for link previews
/// - Extract Twitter Card metadata
/// - Retrieve custom meta tag values from HTML documents
///
/// ### Edge cases
///
/// - Returns `null` if [document] is `null`
/// - Returns `null` if no matching element is found
/// - Returns `null` if the matching element lacks the [key] attribute
/// - When [property] is `null`, returns the first element matching [tag]
///
/// ### Usage
///
/// ```dart
/// // Extract Open Graph title
/// final title = getProperty(document, property: 'og:title');
///
/// // Extract Twitter description
/// final desc = getProperty(
///   document,
///   attribute: 'name',
///   property: 'twitter:description',
/// );
/// ```
/// {@endtemplate}
String? getProperty(Document? document, {
  String tag = 'meta',
  String attribute = 'property',
  String? property,
  String key = 'content',
}) {
  String? value_ = document?.getElementsByTagName(tag).cast<Element?>().firstWhere(
    (Element? element) => element?.attributes[attribute] == property,
    orElse: () => null,
  )?.attributes.get(key);

  return value_;
}