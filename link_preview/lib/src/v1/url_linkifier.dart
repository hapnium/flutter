import 'package:flutter/foundation.dart' show immutable;
import 'package:linkify/linkify.dart';

RegExp _urlRegex = RegExp(r'^(.*?)((?:https?:\/\/|www\.)[^\s/$.?#].[^\s]*)', caseSensitive: false, dotAll: true);

RegExp _looseUrlRegex = RegExp(
  r'^(.*?)((https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*))',
  caseSensitive: false,
  dotAll: true,
);

RegExp _protocolIdentifierRegex = RegExp(r'^(https?:\/\/)', caseSensitive: false);

/// {@template url_linkifier}
/// A [Linkifier] implementation that extracts URLs from text elements.
///
/// This class scans each [TextElement] in the input list for URL patterns and
/// replaces matching segments with [UrlElement] instances. It supports both
/// strict (protocol-required) and loose (protocol-less) matching modes.
///
/// ### Example
///
/// ```dart
/// final linkifier = UrlLinkifier();
/// final results = linkifier.parse(
///   [TextElement('Visit https://flutter.dev today')],
///   LinkifyOptions(),
/// );
/// // results contains a UrlElement with url 'https://flutter.dev'
/// ```
///
/// ### Usage
///
/// ```dart
/// // Basic link extraction
/// final linkifier = UrlLinkifier();
/// final elements = linkifier.parse(textElements, LinkifyOptions());
///
/// // With loose URL matching (no protocol required)
/// final options = LinkifyOptions(looseUrl: true);
/// final elements = linkifier.parse(textElements, options);
///
/// // Default to HTTPS for protocol-less URLs
/// final options = LinkifyOptions(defaultToHttps: true);
/// final elements = linkifier.parse(textElements, options);
/// ```
///
/// ### Edge cases
///
/// - Text that contains no URLs is returned as-is in a [TextElement].
/// - When a URL is preceded by non-URL text, the text before the URL is
///   returned as a separate [TextElement].
/// - When [LinkifyOptions.excludeLastPeriod] is `true` and the URL ends with
///   a period, the trailing period is separated into its own [TextElement].
/// - Protocol-less URLs are automatically prefixed with `http://` or `https://`
///   depending on [LinkifyOptions.defaultToHttps].
/// - The method recurses to handle multiple URLs in a single text element.
/// {@endtemplate}
class UrlLinkifier extends Linkifier {
  /// {@template url_linkifier_constructor}
  /// Creates a [UrlLinkifier] instance.
  ///
  /// This is a constant constructor with no parameters. The linkifier
  /// behavior is determined entirely by the [LinkifyOptions] passed to
  /// [parse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final linkifier = UrlLinkifier();
  /// ```
  /// {@endtemplate}
  const UrlLinkifier();

  /// {@template url_linkifier_parse}
  /// Parses a list of [LinkifyElement]s to find and extract URLs from text.
  ///
  /// Iterates through each element. For [TextElement]s, it applies two
  /// regex strategies in order: a strict regex that requires a protocol
  /// prefix, and a loose regex that also matches bare domains. If the
  /// [options] have `looseUrl` set, only the loose regex is used.
  ///
  /// ### Parameters
  ///
  /// - [elements] — The list of elements to scan. Typically produced by an
  ///   earlier linkifier pass or directly as `[TextElement(inputText)]`.
  /// - [options] — Configuration controlling matching behavior:
  ///   - `looseUrl` — When `true`, matches URLs without a protocol prefix.
  ///   - `defaultToHttps` — When `true`, protocol-less URLs are prefixed
  ///     with `https://`; otherwise `http://` is used.
  ///   - `excludeLastPeriod` — When `true`, a trailing `.` at the end of a
  ///     URL is separated into its own [TextElement].
  ///
  /// ### Return value
  ///
  /// A new [List<LinkifyElement>] where URL matches have been replaced with
  /// [UrlElement] instances, and surrounding text is preserved as
  /// [TextElement]s.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final linkifier = UrlLinkifier();
  /// final result = linkifier.parse(
  ///   [TextElement('Go to flutter.dev for docs')],
  ///   LinkifyOptions(looseUrl: true),
  /// );
  /// // result: [TextElement('Go to '), UrlElement('https://flutter.dev', 'flutter.dev'), TextElement(' for docs')]
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - Non-[TextElement] elements (e.g. existing [UrlElement]s) are passed
  ///   through unchanged.
  /// - If the matched URL group contains text before the URL, that prefix is
  ///   extracted and the remaining text is recursively parsed.
  /// - Empty text elements are not produced; empty groups are skipped.
  /// {@endtemplate}
  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement) {
        var loose = false;
        var match = _urlRegex.firstMatch(element.text);

        if (match?.group(1)?.isNotEmpty == true) {
          final looseMatch = _looseUrlRegex.firstMatch(match!.group(1)!);
          if (looseMatch != null) {
            match = looseMatch;
            loose = true;
          }
        }

        if (match == null && options.looseUrl) {
          match = _looseUrlRegex.firstMatch(element.text);
          loose = true;
        }

        if (match == null) {
          list.add(element);
        } else {
          final text = element.text.replaceFirst(match.group(0)!, '');

          if (match.group(1)?.isNotEmpty == true) {
            list.add(TextElement(match.group(1)!));
          }

          if (match.group(2)?.isNotEmpty == true) {
            var originalUrl = match.group(2)!;
            String? end;

            if (options.excludeLastPeriod &&
                originalUrl[originalUrl.length - 1] == '.') {
              end = '.';
              originalUrl = originalUrl.substring(0, originalUrl.length - 1);
            }

            final url = originalUrl;

            if (loose || !originalUrl.startsWith(_protocolIdentifierRegex)) {
              originalUrl = (options.defaultToHttps ? 'https://' : 'http://') +
                  originalUrl;
            }

            list.add(
              UrlElement(
                originalUrl,
                url,
              ),
            );

            if (end != null) {
              list.add(TextElement(end));
            }
          }

          if (text.isNotEmpty) {
            list.addAll(parse([TextElement(text)], options));
          }
        }
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

/// {@template url_element}
/// An immutable element representing a URL extracted from text.
///
/// Extends [LinkableElement] with the URL stored in [url] and the
/// display text in [text]. The class overrides equality and hash code
/// so that two [UrlElement]s with the same [url] and [text] are considered
/// equal.
///
/// ### Example
///
/// ```dart
/// final element = UrlElement('https://flutter.dev', 'Flutter');
/// print(element.url);   // 'https://flutter.dev'
/// print(element.text);  // 'Flutter'
/// ```
///
/// ### Usage
///
/// ```dart
/// // Create from a parsed URL
/// final element = UrlElement(url, url);
///
/// // Compare two elements
/// final a = UrlElement('https://example.com', 'Example');
/// final b = UrlElement('https://example.com', 'Example');
/// print(a == b); // true
///
/// // String representation
/// print(a.toString()); // "LinkElement: 'https://example.com' (Example)"
/// ```
///
/// ### Edge cases
///
/// - [text] is optional and defaults to the [url] value when omitted.
/// - [hashCode] delegates to [LinkableElement.hashCode] for consistency
///   with [operator==].
/// - Two [UrlElement]s are equal if they are both [UrlElement] instances
///   and their parent class considers them equal.
/// {@endtemplate}
@immutable
class UrlElement extends LinkableElement {
  /// {@template url_element_constructor}
  /// Creates a [UrlElement] with the given [url] and optional [text].
  ///
  /// When [text] is `null`, the display text defaults to [url].
  ///
  /// ### Parameters
  ///
  /// - [url] — The resolved URL string (including protocol).
  /// - [text] — Optional display text shown to the user. Defaults to [url].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final element = UrlElement('https://example.com');
  /// // element.text == 'https://example.com'
  ///
  /// final element2 = UrlElement('https://example.com', 'Example Site');
  /// // element2.text == 'Example Site'
  /// ```
  /// {@endtemplate}
  UrlElement(String url, [String? text]) : super(text, url);

  /// {@template url_element_hash_code}
  /// Returns a hash code consistent with [operator==].
  ///
  /// Delegates to [LinkableElement.hashCode] so that two [UrlElement]s
  /// with the same [url] and [text] produce identical hash codes.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final a = UrlElement('https://example.com', 'Example');
  /// final b = UrlElement('https://example.com', 'Example');
  /// print(a.hashCode == b.hashCode); // true
  /// ```
  ///
  /// ### Return value
  ///
  /// An [int] hash code derived from the element's [url] and [text].
  /// {@endtemplate}
  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  /// {@template url_element_operator_equals}
  /// Compares this [UrlElement] to [other] for equality.
  ///
  /// Two [UrlElement]s are considered equal when they are both [UrlElement]
  /// instances and their parent class ([LinkableElement]) considers them
  /// equal (same [url] and [text]).
  ///
  /// ### Parameters
  ///
  /// - [other] — The object to compare against.
  ///
  /// ### Return value
  ///
  /// `true` if [other] is a [UrlElement] with the same [url] and [text],
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final a = UrlElement('https://flutter.dev', 'Flutter');
  /// final b = UrlElement('https://flutter.dev', 'Flutter');
  /// final c = UrlElement('https://dart.dev', 'Dart');
  /// print(a == b); // true
  /// print(a == c); // false
  /// print(a == 'https://flutter.dev'); // false (not a UrlElement)
  /// ```
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` when [other] is not a [UrlElement].
  /// - Delegates to [equals] for the actual comparison logic.
  /// {@endtemplate}
  @override
  bool operator ==(Object other) => equals(other);

  /// {@template url_element_equals}
  /// Checks whether this [UrlElement] is equal to [other].
  ///
  /// This is the core equality method used by [operator==]. It returns
  /// `true` when [other] is a [UrlElement] and the parent class
  /// ([LinkableElement]) considers the two elements equal.
  ///
  /// ### Parameters
  ///
  /// - [other] — The object to compare against. May be any type.
  ///
  /// ### Return value
  ///
  /// `true` if [other] is a [UrlElement] with matching [url] and [text],
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final element = UrlElement('https://example.com', 'Example');
  /// print(element.equals(UrlElement('https://example.com', 'Example'))); // true
  /// print(element.equals(UrlElement('https://other.com', 'Other')));    // false
  /// print(element.equals('not a UrlElement'));                          // false
  /// ```
  /// {@endtemplate}
  @override
  // ignore: type_annotate_public_apis
  bool equals(other) => other is UrlElement && super.equals(other);

  /// {@template url_element_to_string}
  /// Returns a human-readable string representation of this [UrlElement].
  ///
  /// The format is `"LinkElement: '<url>' (<text>)"` where `<url>` is the
  /// resolved URL and `<text>` is the display text.
  ///
  /// ### Return value
  ///
  /// A [String] in the format `"LinkElement: '<url>' (<text>)"`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final element = UrlElement('https://flutter.dev', 'Flutter');
  /// print(element.toString());
  /// // "LinkElement: 'https://flutter.dev' (Flutter)"
  /// ```
  /// {@endtemplate}
  @override
  String toString() => "LinkElement: '$url' ($text)";
}