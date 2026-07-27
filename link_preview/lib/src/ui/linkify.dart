import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';

/// {@template link_callback}
/// A callback signature invoked when a user taps on a link within linkified text.
///
/// This callback is triggered by [TapGestureRecognizer] on [LinkableElement] spans.
/// Use it to open URLs, navigate to routes, or perform any link-related action.
///
/// ### Parameters
///
/// - `link`: The [LinkableElement] that was tapped, containing the URL and display text.
///
/// ### Return value
///
/// Returns `void`. This is a side-effect callback.
///
/// ### Examples
///
/// ```dart
/// LinkCallback onOpen = (LinkableElement link) {
///   launchUrl(Uri.parse(link.url));
/// };
/// ```
///
/// ```dart
/// LinkCallback onOpen = (link) {
///   Navigator.pushNamed(context, '/link', arguments: link.url);
/// };
/// ```
///
/// ### Common actions
///
/// - Open the URL in a browser or in-app web view.
/// - Navigate to an in-app route.
/// - Log the tap for analytics.
///
/// ### Edge cases
///
/// - The [link.url] may not be a valid URL if the linkifier produced unexpected output.
/// - Multiple taps on the same link will invoke the callback each time.
/// {@endtemplate}
typedef LinkCallback = void Function(LinkableElement link);

/// {@template linkify}
/// A widget that converts URLs, emails, and phone numbers in text into tappable links.
///
/// Uses the `linkify` package to parse plain text and identify linkifiable elements.
/// Rendered as a [Text.rich] widget with [TextSpan] children for each element.
///
/// ### Example
///
/// ```dart
/// Linkify(
///   text: 'Visit https://flutter.dev for more info',
///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
///   style: const TextStyle(fontSize: 16),
///   linkStyle: const TextStyle(color: Colors.blue),
/// )
/// ```
///
/// ### Usage
///
/// Use [Linkify] when you need non-selectable text with tappable links.
/// For selectable text, use [SelectableLinkify] instead.
///
/// ```dart
/// Linkify(
///   text: 'Contact us at support@example.com or call 555-1234',
///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
/// )
/// ```
///
/// ### Common actions
///
/// - Display linkified text in a chat message or comment.
/// - Open URLs in a web view when tapped.
/// - Customize link appearance with [linkStyle].
///
/// ### Edge cases
///
/// - If [text] contains no linkifiable elements, all text is rendered with [style].
/// - If [onOpen] is `null`, links are visually styled but not tappable.
/// - Empty [text] renders an empty [Text.rich] widget.
/// {@endtemplate}
class Linkify extends StatelessWidget {
  /// {@template linkify_text}
  /// The plain text to be linkified.
  ///
  /// This text is parsed by the `linkify` package to identify URLs, emails,
  /// and phone numbers based on the configured [linkifiers] and [options].
  ///
  /// ### Parameters
  ///
  /// - Type: `String`
  /// - Required: Yes
  ///
  /// ### Examples
  ///
  /// ```dart
  /// text: 'Visit https://flutter.dev for more info'
  /// ```
  ///
  /// ```dart
  /// text: 'Email us at support@example.com'
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: 'Check out https://github.com for open source projects',
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Pass user-generated content (comments, messages).
  /// - Pass static text with embedded URLs.
  ///
  /// ### Edge cases
  ///
  /// - An empty string renders no visible content.
  /// - Text with no linkifiable elements renders as plain text.
  /// {@endtemplate}
  final String text;

  /// {@template linkify_linkifiers}
  /// The list of [Linkifier] instances used to parse [text].
  ///
  /// Each linkifier identifies a specific type of link (URL, email, phone, etc.).
  /// The default [defaultLinkifiers] includes URL, email, and phone linkifiers.
  ///
  /// ### Parameters
  ///
  /// - Type: `List<Linkifier>`
  /// - Required: No
  /// - Default: `defaultLinkifiers`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// linkifiers: [UrlLinkifier(), EmailLinkifier()]
  /// ```
  ///
  /// ```dart
  /// linkifiers: [UrlLinkifier()] // Only linkify URLs
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   linkifiers: [UrlLinkifier()], // Skip emails and phones
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use default linkifiers for general-purpose linkification.
  /// - Use only [UrlLinkifier] to ignore emails and phone numbers.
  /// - Create custom linkifiers for domain-specific patterns.
  ///
  /// ### Edge cases
  ///
  /// - An empty list results in no linkification.
  /// - Linkifiers are applied in order; first match wins for overlapping patterns.
  /// {@endtemplate}
  final List<Linkifier> linkifiers;

  /// {@template linkify_onOpen}
  /// Callback invoked when a user taps on a linkified element.
  ///
  /// If `null`, links are visually styled but not interactive.
  /// The callback receives the [LinkableElement] containing the URL and text.
  ///
  /// ### Parameters
  ///
  /// - Type: `LinkCallback?`
  /// - Required: No
  /// - Default: `null`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// onOpen: (link) => launchUrl(Uri.parse(link.url))
  /// ```
  ///
  /// ```dart
  /// onOpen: (link) {
  ///   if (link.url.startsWith('https://')) {
  ///     context.push('/webview?url=${link.url}');
  ///   }
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: 'Visit https://flutter.dev',
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Open the URL in a browser.
  /// - Navigate to an in-app web view.
  /// - Log the tap event.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the [TapGestureRecognizer] is not attached to link spans.
  /// - The callback is invoked for every tap, including rapid repeated taps.
  /// {@endtemplate}
  final LinkCallback? onOpen;

  /// {@template linkify_options}
  /// Configuration options for the `linkify` parser.
  ///
  /// Controls parsing behavior such as whether to match URLs without protocols,
  /// whether to match email addresses, etc.
  ///
  /// ### Parameters
  ///
  /// - Type: `LinkifyOptions`
  /// - Required: No
  /// - Default: `const LinkifyOptions()`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// options: LinkifyOptions(humanize: false)
  /// ```
  ///
  /// ```dart
  /// options: LinkifyOptions(defaultToHttps: true)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: 'Visit flutter.dev',
  ///   options: LinkifyOptions(defaultToHttps: true),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable `humanize` to remove protocol prefixes from display text.
  /// - Enable `defaultToHttps` to prepend `https://` to bare domains.
  ///
  /// ### Edge cases
  ///
  /// - Different options may produce different link counts for the same text.
  /// - Invalid option combinations may produce unexpected results.
  /// {@endtemplate}
  final LinkifyOptions options;

  /// {@template linkify_style}
  /// The text style applied to non-link text spans.
  ///
  /// If `null`, falls back to [Theme.of(context).textTheme.bodyMedium].
  /// This style is applied to all [TextSpan] elements that are not [LinkableElement]s.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextStyle?`
  /// - Required: No
  /// - Default: `null` (uses theme bodyMedium)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// style: const TextStyle(fontSize: 16, color: Colors.black87)
  /// ```
  ///
  /// ```dart
  /// style: Theme.of(context).textTheme.bodyLarge
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   style: const TextStyle(fontSize: 14),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Match the style of surrounding text.
  /// - Use a smaller font for secondary content.
  ///
  /// ### Edge cases
  ///
  /// - If `null` and no theme is available, the default Flutter text style is used.
  /// - This style is merged with [linkStyle] for link spans (linkStyle takes precedence).
  /// {@endtemplate}
  final TextStyle? style;

  /// {@template linkify_linkStyle}
  /// The text style applied to linkified text spans.
  ///
  /// This style is merged on top of [style] using [TextStyle.merge].
  /// The default merge applies blue color and underline decoration.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextStyle?`
  /// - Required: No
  /// - Default: `null` (blue accent + underline applied by default)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// linkStyle: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)
  /// ```
  ///
  /// ```dart
  /// linkStyle: TextStyle(
  ///   color: Theme.of(context).colorScheme.primary,
  ///   decoration: TextDecoration.underline,
  /// )
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   linkStyle: const TextStyle(color: Colors.teal),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Override the default blue color.
  /// - Remove underline decoration.
  /// - Add custom decoration (e.g., dotted underline).
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default blue + underline style is applied.
  /// - Properties not set in [linkStyle] inherit from [style].
  /// {@endtemplate}
  final TextStyle? linkStyle;

  /// {@template linkify_textAlign}
  /// How the text should be aligned horizontally.
  ///
  /// Applied to the [Text.rich] widget that renders the linkified text.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextAlign`
  /// - Required: No
  /// - Default: `TextAlign.start`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textAlign: TextAlign.center
  /// ```
  ///
  /// ```dart
  /// textAlign: TextAlign.justify
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   textAlign: TextAlign.center,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Center text for captions or labels.
  /// - Justify text for long paragraphs.
  ///
  /// ### Edge cases
  ///
  /// - `TextAlign.start` is LTR-aware and respects text direction.
  /// - `TextAlign.justify` may produce uneven spacing with short lines.
  /// {@endtemplate}
  final TextAlign textAlign;

  /// {@template linkify_textDirection}
  /// The text direction of the text.
  ///
  /// Used to disambiguate left-to-right and right-to-left text rendering.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextDirection?`
  /// - Required: No
  /// - Default: `null` (inherited from context)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textDirection: TextDirection.ltr
  /// ```
  ///
  /// ```dart
  /// textDirection: TextDirection.rtl
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   textDirection: TextDirection.rtl,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Explicitly set for mixed-direction text.
  /// - Leave `null` to inherit from the widget tree.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the direction is inherited from [Directionality] ancestor.
  /// - No [Directionality] ancestor and `null` causes a runtime error.
  /// {@endtemplate}
  final TextDirection? textDirection;

  /// {@template linkify_maxLines}
  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If the text exceeds this limit, it is truncated with [overflow].
  ///
  /// ### Parameters
  ///
  /// - Type: `int?`
  /// - Required: No
  /// - Default: `null` (unlimited lines)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// maxLines: 2
  /// ```
  ///
  /// ```dart
  /// maxLines: 1 // Single line with ellipsis
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: longText,
  ///   maxLines: 3,
  ///   overflow: TextOverflow.ellipsis,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Limit preview text to 2-3 lines.
  /// - Combine with [TextOverflow.ellipsis] for truncated display.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, text wraps to any number of lines.
  /// - `maxLines: 1` with `TextOverflow.clip` clips at the edge.
  /// {@endtemplate}
  final int? maxLines;

  /// {@template linkify_overflow}
  /// How visual overflow should be handled.
  ///
  /// Applied when [maxLines] is set and the text exceeds the limit.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextOverflow?`
  /// - Required: No
  /// - Default: `TextOverflow.clip`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// overflow: TextOverflow.ellipsis
  /// ```
  ///
  /// ```dart
  /// overflow: TextOverflow.fade
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: longText,
  ///   maxLines: 2,
  ///   overflow: TextOverflow.ellipsis,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Show ellipsis (`...`) when text is truncated.
  /// - Fade text at the boundary.
  ///
  /// ### Edge cases
  ///
  /// - `TextOverflow.clip` hard-clips text without visual indicator.
  /// - `TextOverflow.visible` shows text outside bounds (rarely desired).
  /// {@endtemplate}
  final TextOverflow? overflow;

  /// {@template linkify_softWrap}
  /// Whether the text should break at soft line breaks.
  ///
  /// When `true`, text wraps at word boundaries to fit the available width.
  /// When `false`, text only breaks at explicit newline characters.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool`
  /// - Required: No
  /// - Default: `true`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// softWrap: false // No wrapping
  /// ```
  ///
  /// ```dart
  /// softWrap: true // Wrap at word boundaries
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   softWrap: true,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable for responsive text layout.
  /// - Disable for single-line display.
  ///
  /// ### Edge cases
  ///
  /// - If `false` and text is wider than the container, it overflows.
  /// - Soft wrapping respects Unicode line break opportunities.
  /// {@endtemplate}
  final bool softWrap;

  /// {@template linkify_strutStyle}
  /// The strut style used for the vertical layout.
  ///
  /// Defines the minimum line height and other vertical metrics for the text.
  ///
  /// ### Parameters
  ///
  /// - Type: `StrutStyle?`
  /// - Required: No
  /// - Default: `null` (uses default strut)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// strutStyle: StrutStyle(fontSize: 16, height: 1.5)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   strutStyle: const StrutStyle(height: 1.2),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Increase line height for readability.
  /// - Match strut style across multiple text widgets.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default strut from the text theme is used.
  /// - Strut style only affects vertical metrics, not horizontal layout.
  /// {@endtemplate}
  final StrutStyle? strutStyle;

  /// {@template linkify_locale}
  /// The locale used to select a font when the same Unicode character can be rendered differently.
  ///
  /// Some characters (e.g., Chinese, Japanese, Korean) have locale-specific glyphs.
  ///
  /// ### Parameters
  ///
  /// - Type: `Locale?`
  /// - Required: No
  /// - Default: `null` (uses platform locale)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// locale: const Locale('en', 'US')
  /// ```
  ///
  /// ```dart
  /// locale: const Locale('ja', 'JP')
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   locale: Localizations.localeOf(context),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Pass the current locale from [Localizations].
  /// - Explicitly set for known character sets.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the platform locale is used.
  /// - Incorrect locale may cause wrong glyph selection.
  /// {@endtemplate}
  final Locale? locale;

  /// {@template linkify_textWidthBasis}
  /// Defines how to measure the width of the rendered text.
  ///
  /// Affects how the text widget determines its intrinsic width.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextWidthBasis`
  /// - Required: No
  /// - Default: `TextWidthBasis.parent`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textWidthBasis: TextWidthBasis.longestLine
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   textWidthBasis: TextWidthBasis.longestLine,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use `parent` for typical layouts.
  /// - Use `longestLine` when width should match the longest line.
  ///
  /// ### Edge cases
  ///
  /// - `longestLine` may cause unexpected sizing with wrapped text.
  /// - Affects intrinsic size calculations in flex layouts.
  /// {@endtemplate}
  final TextWidthBasis textWidthBasis;

  /// {@template linkify_textHeightBehavior}
  /// Defines how the paragraph applies [TextStyle.height] to the ascent of the first line and descent of the last line.
  ///
  /// Controls whether the height multiplier applies to the first/last line.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextHeightBehavior?`
  /// - Required: No
  /// - Default: `null` (uses default behavior)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textHeightBehavior: const TextHeightBehavior(
  ///   applyHeightToFirstAscent: false,
  ///   applyHeightToLastDescent: false,
  /// )
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   textHeightBehavior: const TextHeightBehavior(
  ///     applyHeightToFirstAscent: false,
  ///   ),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Disable height for first/last line to reduce vertical spacing.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default behavior applies height to all lines.
  /// - Affects vertical alignment in tight layouts.
  /// {@endtemplate}
  final TextHeightBehavior? textHeightBehavior;

  /// {@template linkify_textScaler}
  /// Describes how textual contents should be scaled for better readability.
  ///
  /// Controls text scaling independently of the system font size setting.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextScaler?`
  /// - Required: No
  /// - Default: `null` (uses system scaler)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textScaler: TextScaler.linear(1.2)
  /// ```
  ///
  /// ```dart
  /// textScaler: TextScaler.noScaling
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   textScaler: TextScaler.linear(1.0),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Disable scaling: `TextScaler.noScaling`.
  /// - Apply fixed scaling: `TextScaler.linear(1.5)`.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the system text scaler is used.
  /// - Very large scalers may cause layout overflow.
  /// {@endtemplate}
  final TextScaler? textScaler;

  /// {@template linkify_useMouseRegion}
  /// Whether to wrap link spans in a [MouseRegion] to show a click cursor on hover.
  ///
  /// When `true`, hovering over a link shows the system click cursor.
  /// This enhances the visual affordance that the text is tappable.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool`
  /// - Required: No
  /// - Default: `true`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// useMouseRegion: true // Show click cursor on hover
  /// ```
  ///
  /// ```dart
  /// useMouseRegion: false // Default cursor everywhere
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// Linkify(
  ///   text: text,
  ///   useMouseRegion: true,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable for desktop/web to improve UX.
  /// - Disable on mobile where hover doesn't apply.
  ///
  /// ### Edge cases
  ///
  /// - Only affects mouse cursor; touch behavior is handled by [TapGestureRecognizer].
  /// - Adds a [MouseRegion] widget per link, which may impact performance with many links.
  /// {@endtemplate}
  final bool useMouseRegion;

  /// {@macro linkify}
  const Linkify({
    super.key,
    required this.text,
    this.linkifiers = defaultLinkifiers,
    this.onOpen,
    this.options = const LinkifyOptions(),
    // TextSpan
    this.style,
    this.linkStyle,
    // RichText
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.softWrap = true,
    this.strutStyle,
    this.locale,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.useMouseRegion = true,
    this.textScaler,
  });

  /// {@template linkify_build}
  /// Builds the linkified text widget.
  ///
  /// Parses [text] using [linkify], builds a [TextSpan] tree with
  /// [buildTextSpan], and renders it via [Text.rich].
  ///
  /// ### Return value
  ///
  /// Returns a [Text.rich] widget containing linkified text.
  ///
  /// ### Edge cases
  ///
  /// - Falls back to [Theme.of(context).textTheme.bodyMedium] if [style] is `null`.
  /// - Links default to blue accent + underline if [linkStyle] is `null`.
  /// {@endtemplate}
  @override
  Widget build(BuildContext context) {
    List<LinkifyElement> elements = linkify(text, options: options, linkifiers: linkifiers);

    return Text.rich(
      buildTextSpan(
        elements,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        onOpen: onOpen,
        useMouseRegion: useMouseRegion,
        linkStyle: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
        ).merge(linkStyle),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textScaler: textScaler,
      strutStyle: strutStyle,
      locale: locale,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}

/// {@template selectable_linkify}
/// A widget that converts URLs, emails, and phone numbers in text into tappable links
/// with text selection support.
///
/// Similar to [Linkify] but uses [SelectableText.rich] instead of [Text.rich],
/// allowing users to select and copy text. Links remain tappable while
/// non-link text is selectable.
///
/// ### Example
///
/// ```dart
/// SelectableLinkify(
///   text: 'Visit https://flutter.dev for more info',
///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
///   style: const TextStyle(fontSize: 16),
///   linkStyle: const TextStyle(color: Colors.blue),
/// )
/// ```
///
/// ### Usage
///
/// Use [SelectableLinkify] when you need both tappable links and selectable text.
/// For non-selectable text, use [Linkify] instead.
///
/// ```dart
/// SelectableLinkify(
///   text: 'Contact us at support@example.com or call 555-1234',
///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
///   enableInteractiveSelection: true,
/// )
/// ```
///
/// ### Common actions
///
/// - Display selectable linkified text in detail views.
/// - Allow users to copy parts of the text.
/// - Show a context menu with copy/paste options.
///
/// ### Edge cases
///
/// - If [text] contains no linkifiable elements, all text is selectable.
/// - If [onOpen] is `null`, links are visually styled but not tappable.
/// - Text selection and link tapping may conflict on some platforms.
/// {@endtemplate}
class SelectableLinkify extends StatelessWidget {
  /// {@template selectable_linkify_text}
  /// The plain text to be linkified.
  ///
  /// This text is parsed by the `linkify` package to identify URLs, emails,
  /// and phone numbers based on the configured [linkifiers] and [options].
  ///
  /// ### Parameters
  ///
  /// - Type: `String`
  /// - Required: Yes
  ///
  /// ### Examples
  ///
  /// ```dart
  /// text: 'Visit https://flutter.dev for more info'
  /// ```
  ///
  /// ```dart
  /// text: 'Email us at support@example.com'
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: 'Check out https://github.com for open source projects',
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Pass user-generated content (comments, messages).
  /// - Pass static text with embedded URLs.
  ///
  /// ### Edge cases
  ///
  /// - An empty string renders no visible content.
  /// - Text with no linkifiable elements renders as plain selectable text.
  /// {@endtemplate}
  final String text;

  /// {@template selectable_linkify_textScaler}
  /// Describes how textual contents should be scaled for better readability.
  ///
  /// Controls text scaling independently of the system font size setting.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextScaler?`
  /// - Required: No
  /// - Default: `null` (uses system scaler)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textScaler: TextScaler.linear(1.2)
  /// ```
  ///
  /// ```dart
  /// textScaler: TextScaler.noScaling
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   textScaler: TextScaler.linear(1.0),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Disable scaling: `TextScaler.noScaling`.
  /// - Apply fixed scaling: `TextScaler.linear(1.5)`.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the system text scaler is used.
  /// - Very large scalers may cause layout overflow.
  /// {@endtemplate}
  final TextScaler? textScaler;

  /// {@template selectable_linkify_linkifiers}
  /// The list of [Linkifier] instances used to parse [text].
  ///
  /// Each linkifier identifies a specific type of link (URL, email, phone, etc.).
  /// The default [defaultLinkifiers] includes URL, email, and phone linkifiers.
  ///
  /// ### Parameters
  ///
  /// - Type: `List<Linkifier>`
  /// - Required: No
  /// - Default: `defaultLinkifiers`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// linkifiers: [UrlLinkifier(), EmailLinkifier()]
  /// ```
  ///
  /// ```dart
  /// linkifiers: [UrlLinkifier()] // Only linkify URLs
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   linkifiers: [UrlLinkifier()], // Skip emails and phones
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use default linkifiers for general-purpose linkification.
  /// - Use only [UrlLinkifier] to ignore emails and phone numbers.
  /// - Create custom linkifiers for domain-specific patterns.
  ///
  /// ### Edge cases
  ///
  /// - An empty list results in no linkification.
  /// - Linkifiers are applied in order; first match wins for overlapping patterns.
  /// {@endtemplate}
  final List<Linkifier> linkifiers;

  /// {@template selectable_linkify_onOpen}
  /// Callback invoked when a user taps on a linkified element.
  ///
  /// If `null`, links are visually styled but not interactive.
  /// The callback receives the [LinkableElement] containing the URL and text.
  ///
  /// ### Parameters
  ///
  /// - Type: `LinkCallback?`
  /// - Required: No
  /// - Default: `null`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// onOpen: (link) => launchUrl(Uri.parse(link.url))
  /// ```
  ///
  /// ```dart
  /// onOpen: (link) {
  ///   if (link.url.startsWith('https://')) {
  ///     context.push('/webview?url=${link.url}');
  ///   }
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: 'Visit https://flutter.dev',
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Open the URL in a browser.
  /// - Navigate to an in-app web view.
  /// - Log the tap event.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the [TapGestureRecognizer] is not attached to link spans.
  /// - The callback is invoked for every tap, including rapid repeated taps.
  /// {@endtemplate}
  final LinkCallback? onOpen;

  /// {@template selectable_linkify_options}
  /// Configuration options for the `linkify` parser.
  ///
  /// Controls parsing behavior such as whether to match URLs without protocols,
  /// whether to match email addresses, etc.
  ///
  /// ### Parameters
  ///
  /// - Type: `LinkifyOptions`
  /// - Required: No
  /// - Default: `const LinkifyOptions()`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// options: LinkifyOptions(humanize: false)
  /// ```
  ///
  /// ```dart
  /// options: LinkifyOptions(defaultToHttps: true)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: 'Visit flutter.dev',
  ///   options: LinkifyOptions(defaultToHttps: true),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable `humanize` to remove protocol prefixes from display text.
  /// - Enable `defaultToHttps` to prepend `https://` to bare domains.
  ///
  /// ### Edge cases
  ///
  /// - Different options may produce different link counts for the same text.
  /// - Invalid option combinations may produce unexpected results.
  /// {@endtemplate}
  final LinkifyOptions options;

  /// {@template selectable_linkify_style}
  /// The text style applied to non-link text spans.
  ///
  /// If `null`, falls back to [Theme.of(context).textTheme.bodyMedium].
  /// This style is applied to all [TextSpan] elements that are not [LinkableElement]s.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextStyle?`
  /// - Required: No
  /// - Default: `null` (uses theme bodyMedium)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// style: const TextStyle(fontSize: 16, color: Colors.black87)
  /// ```
  ///
  /// ```dart
  /// style: Theme.of(context).textTheme.bodyLarge
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   style: const TextStyle(fontSize: 14),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Match the style of surrounding text.
  /// - Use a smaller font for secondary content.
  ///
  /// ### Edge cases
  ///
  /// - If `null` and no theme is available, the default Flutter text style is used.
  /// - This style is merged with [linkStyle] for link spans (linkStyle takes precedence).
  /// {@endtemplate}
  final TextStyle? style;

  /// {@template selectable_linkify_linkStyle}
  /// The text style applied to linkified text spans.
  ///
  /// This style is merged on top of [style] using [TextStyle.merge].
  /// The default merge applies blue color and underline decoration.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextStyle?`
  /// - Required: No
  /// - Default: `null` (blue accent + underline applied by default)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// linkStyle: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)
  /// ```
  ///
  /// ```dart
  /// linkStyle: TextStyle(
  ///   color: Theme.of(context).colorScheme.primary,
  ///   decoration: TextDecoration.underline,
  /// )
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   linkStyle: const TextStyle(color: Colors.teal),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Override the default blue color.
  /// - Remove underline decoration.
  /// - Add custom decoration (e.g., dotted underline).
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default blue + underline style is applied.
  /// - Properties not set in [linkStyle] inherit from [style].
  /// {@endtemplate}
  final TextStyle? linkStyle;

  /// {@template selectable_linkify_textAlign}
  /// How the text should be aligned horizontally.
  ///
  /// Applied to the [SelectableText.rich] widget that renders the linkified text.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextAlign?`
  /// - Required: No
  /// - Default: `null` (inherited from context)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textAlign: TextAlign.center
  /// ```
  ///
  /// ```dart
  /// textAlign: TextAlign.justify
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   textAlign: TextAlign.center,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Center text for captions or labels.
  /// - Justify text for long paragraphs.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, inherits from the nearest [DefaultTextStyle].
  /// - `TextAlign.justify` may produce uneven spacing with short lines.
  /// {@endtemplate}
  final TextAlign? textAlign;

  /// {@template selectable_linkify_textDirection}
  /// The text direction of the text.
  ///
  /// Used to disambiguate left-to-right and right-to-left text rendering.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextDirection?`
  /// - Required: No
  /// - Default: `null` (inherited from context)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textDirection: TextDirection.ltr
  /// ```
  ///
  /// ```dart
  /// textDirection: TextDirection.rtl
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   textDirection: TextDirection.rtl,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Explicitly set for mixed-direction text.
  /// - Leave `null` to inherit from the widget tree.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the direction is inherited from [Directionality] ancestor.
  /// - No [Directionality] ancestor and `null` causes a runtime error.
  /// {@endtemplate}
  final TextDirection? textDirection;

  /// {@template selectable_linkify_minLines}
  /// The minimum number of lines to occupy when the content spans fewer lines.
  ///
  /// This is different from [maxLines] in that it forces the text to take up
  /// at least this many lines, even if the content is shorter.
  ///
  /// ### Parameters
  ///
  /// - Type: `int?`
  /// - Required: No
  /// - Default: `null` (no minimum)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// minLines: 2
  /// ```
  ///
  /// ```dart
  /// minLines: 3 // Always 3 lines tall
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: shortText,
  ///   minLines: 3,
  ///   maxLines: 5,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Ensure consistent height for variable-length content.
  /// - Create a fixed-height text area.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, no minimum height is enforced.
  /// - [minLines] must be less than or equal to [maxLines] if both are set.
  /// {@endtemplate}
  final int? minLines;

  /// {@template selectable_linkify_maxLines}
  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If the text exceeds this limit, it is truncated with ellipsis or fade.
  ///
  /// ### Parameters
  ///
  /// - Type: `int?`
  /// - Required: No
  /// - Default: `null` (unlimited lines)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// maxLines: 2
  /// ```
  ///
  /// ```dart
  /// maxLines: 1 // Single line
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: longText,
  ///   maxLines: 3,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Limit preview text to 2-3 lines.
  /// - Combine with ellipsis for truncated display.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, text wraps to any number of lines.
  /// - Text selection may be limited by [maxLines].
  /// {@endtemplate}
  final int? maxLines;

  /// {@template selectable_linkify_strutStyle}
  /// The strut style used for the vertical layout.
  ///
  /// Defines the minimum line height and other vertical metrics for the text.
  ///
  /// ### Parameters
  ///
  /// - Type: `StrutStyle?`
  /// - Required: No
  /// - Default: `null` (uses default strut)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// strutStyle: StrutStyle(fontSize: 16, height: 1.5)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   strutStyle: const StrutStyle(height: 1.2),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Increase line height for readability.
  /// - Match strut style across multiple text widgets.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default strut from the text theme is used.
  /// - Strut style only affects vertical metrics, not horizontal layout.
  /// {@endtemplate}
  final StrutStyle? strutStyle;

  /// {@template selectable_linkify_textWidthBasis}
  /// Defines how to measure the width of the rendered text.
  ///
  /// Affects how the text widget determines its intrinsic width.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextWidthBasis?`
  /// - Required: No
  /// - Default: `null` (uses parent basis)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textWidthBasis: TextWidthBasis.longestLine
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   textWidthBasis: TextWidthBasis.longestLine,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use `parent` for typical layouts.
  /// - Use `longestLine` when width should match the longest line.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, defaults to `TextWidthBasis.parent`.
  /// - `longestLine` may cause unexpected sizing with wrapped text.
  /// {@endtemplate}
  final TextWidthBasis? textWidthBasis;

  /// {@template selectable_linkify_focusNode}
  /// Defines the focus for this widget.
  ///
  /// Used to programmatically focus the text field or listen for focus changes.
  ///
  /// ### Parameters
  ///
  /// - Type: `FocusNode?`
  /// - Required: No
  /// - Default: `null` (auto-created internally)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// final focusNode = FocusNode();
  /// SelectableLinkify(
  ///   text: text,
  ///   focusNode: focusNode,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// focusNode.requestFocus(); // Focus the text
  /// focusNode.unfocus(); // Unfocus the text
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Focus the text field on page load.
  /// - Unfocus when tapping outside.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, an internal focus node is created.
  /// - Disposing the external focus node is the caller's responsibility.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template selectable_linkify_showCursor}
  /// Whether to show the text cursor.
  ///
  /// When `true`, a blinking cursor is visible at the cursor position.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool`
  /// - Required: No
  /// - Default: `false`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// showCursor: true
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   showCursor: true,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Show cursor for editable text.
  /// - Hide cursor for read-only selectable text.
  ///
  /// ### Edge cases
  ///
  /// - If `true`, the cursor appears when the text field is focused.
  /// - Cursor color is controlled by [cursorColor].
  /// {@endtemplate}
  final bool showCursor;

  /// {@template selectable_linkify_autofocus}
  /// Whether this text field should focus itself if nothing else is already focused.
  ///
  /// When `true`, the text field automatically receives focus when the widget tree is built.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool`
  /// - Required: No
  /// - Default: `false`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// autofocus: true
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   autofocus: true,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Auto-focus for search fields.
  /// - Leave `false` for most display-only text.
  ///
  /// ### Edge cases
  ///
  /// - Only one widget can be autofocused at a time.
  /// - May cause unexpected keyboard appearance on mobile.
  /// {@endtemplate}
  final bool autofocus;

  /// {@template selectable_linkify_contextMenuBuilder}
  /// Builds the text selection toolbar when requested by the user.
  ///
  /// Customizes the context menu that appears on long-press or right-click.
  ///
  /// ### Parameters
  ///
  /// - `context`: The [BuildContext].
  /// - `EditableTextState`: The state of the editable text.
  ///
  /// ### Return value
  ///
  /// Returns a [Widget] for the context menu.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// contextMenuBuilder: (context, state) {
  ///   return AdaptiveTextSelectionToolbar(
  ///     anchors: state.contextMenuAnchors,
  ///     children: [
  ///       // Custom menu items
  ///     ],
  ///   );
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   contextMenuBuilder: (context, state) =>
  ///     AdaptiveTextSelectionToolbar.textItems(
  ///       context: context,
  ///       anchors: state.contextMenuAnchors,
  ///       items: state.buildTextSelectionControls(),
  ///     ),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Add custom menu items (e.g., "Share", "Translate").
  /// - Remove default menu items.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default system context menu is used.
  /// - Custom menus must handle all text selection actions.
  /// {@endtemplate}
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// {@template selectable_linkify_cursorWidth}
  /// How thick the cursor will be.
  ///
  /// Controls the width of the text cursor in logical pixels.
  ///
  /// ### Parameters
  ///
  /// - Type: `double`
  /// - Required: No
  /// - Default: `2.0`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// cursorWidth: 1.0 // Thin cursor
  /// ```
  ///
  /// ```dart
  /// cursorWidth: 3.0 // Thick cursor
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   cursorWidth: 2.0,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use default (2.0) for most cases.
  /// - Increase for better visibility on large screens.
  ///
  /// ### Edge cases
  ///
  /// - Very thin cursors may be hard to see.
  /// - Very thick cursors may obscure text.
  /// {@endtemplate}
  final double cursorWidth;

  /// {@template selectable_linkify_cursorRadius}
  /// How rounded the corners of the cursor should be.
  ///
  /// Controls the corner radius of the text cursor.
  ///
  /// ### Parameters
  ///
  /// - Type: `Radius?`
  /// - Required: No
  /// - Default: `null` (sharp corners)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// cursorRadius: const Radius.circular(2.0)
  /// ```
  ///
  /// ```dart
  /// cursorRadius: const Radius.circular(5.0) // Very rounded
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   cursorRadius: const Radius.circular(1.0),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use sharp corners for a precise look.
  /// - Use rounded corners for a softer look.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the cursor has sharp 90-degree corners.
  /// - Large radius may look odd with thin cursor width.
  /// {@endtemplate}
  final Radius? cursorRadius;

  /// {@template selectable_linkify_cursorColor}
  /// The color to use when painting the cursor.
  ///
  /// Controls the color of the text cursor. Falls back to the theme cursor color if `null`.
  ///
  /// ### Parameters
  ///
  /// - Type: `Color?`
  /// - Required: No
  /// - Default: `null` (uses theme cursor color)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// cursorColor: Colors.blue
  /// ```
  ///
  /// ```dart
  /// cursorColor: Theme.of(context).colorScheme.primary
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   cursorColor: Colors.deepPurple,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Match the cursor color to the app's theme.
  /// - Use a contrasting color for visibility.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the cursor color is inherited from the theme.
  /// - Transparent colors make the cursor invisible.
  /// {@endtemplate}
  final Color? cursorColor;

  /// {@template selectable_linkify_dragStartBehavior}
  /// Determines the way that drag start behavior is handled.
  ///
  /// Controls when a drag gesture is recognized (on initial touch down or on movement).
  ///
  /// ### Parameters
  ///
  /// - Type: `DragStartBehavior`
  /// - Required: No
  /// - Default: `DragStartBehavior.start`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// dragStartBehavior: DragStartBehavior.down
  /// ```
  ///
  /// ```dart
  /// dragStartBehavior: DragStartBehavior.start
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   dragStartBehavior: DragStartBehavior.down,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use `start` for immediate drag response.
  /// - Use `down` for a more deliberate drag start.
  ///
  /// ### Edge cases
  ///
  /// - `DragStartBehavior.start` may cause accidental drags.
  /// - `DragStartBehavior.down` requires more deliberate movement.
  /// {@endtemplate}
  final DragStartBehavior dragStartBehavior;

  /// {@template selectable_linkify_enableInteractiveSelection}
  /// Whether long-pressing this text will select text and show the cut/copy/paste menu,
  /// and tapping will move the text caret.
  ///
  /// When `true`, users can select, copy, and paste text. When `false`, text is
  /// read-only but links remain tappable.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool`
  /// - Required: No
  /// - Default: `true`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// enableInteractiveSelection: true // Full selection support
  /// ```
  ///
  /// ```dart
  /// enableInteractiveSelection: false // No selection, links only
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   enableInteractiveSelection: true,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable for user-generated content.
  /// - Disable for display-only text with links.
  ///
  /// ### Edge cases
  ///
  /// - If `false`, long-press does nothing.
  /// - Links remain tappable even when selection is disabled.
  /// {@endtemplate}
  final bool enableInteractiveSelection;

  /// {@template selectable_linkify_onTap}
  /// Called when the user taps on this selectable text (not on a link).
  ///
  /// This callback is invoked for taps on non-link text only. Link taps are
  /// handled by [onOpen].
  ///
  /// ### Parameters
  ///
  /// - Type: `GestureTapCallback?`
  /// - Required: No
  /// - Default: `null`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// onTap: () => print('Tapped on non-link text')
  /// ```
  ///
  /// ```dart
  /// onTap: () => FocusScope.of(context).unfocus()
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   onTap: () => debugPrint('Text tapped'),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Unfocus the text when tapped outside a link.
  /// - Log the tap event.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, no action is taken on non-link taps.
  /// - Link taps invoke [onOpen], not [onTap].
  /// {@endtemplate}
  final GestureTapCallback? onTap;

  /// {@template selectable_linkify_scrollPhysics}
  /// The scroll physics used for the selectable text widget.
  ///
  /// Controls how the text scrolls when it exceeds the available space.
  ///
  /// ### Parameters
  ///
  /// - Type: `ScrollPhysics?`
  /// - Required: No
  /// - Default: `null` (uses platform default)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// scrollPhysics: const NeverScrollableScrollPhysics()
  /// ```
  ///
  /// ```dart
  /// scrollPhysics: const BouncingScrollPhysics()
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: longText,
  ///   scrollPhysics: const BouncingScrollPhysics(),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Disable scrolling: `NeverScrollableScrollPhysics`.
  /// - Use platform-appropriate physics.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the platform default physics is used.
  /// - Custom physics may not match platform conventions.
  /// {@endtemplate}
  final ScrollPhysics? scrollPhysics;

  /// {@template selectable_linkify_textHeightBehavior}
  /// Defines how the paragraph applies [TextStyle.height] to the ascent of the first line and descent of the last line.
  ///
  /// Controls whether the height multiplier applies to the first/last line.
  ///
  /// ### Parameters
  ///
  /// - Type: `TextHeightBehavior?`
  /// - Required: No
  /// - Default: `null` (uses default behavior)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// textHeightBehavior: const TextHeightBehavior(
  ///   applyHeightToFirstAscent: false,
  ///   applyHeightToLastDescent: false,
  /// )
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   textHeightBehavior: const TextHeightBehavior(
  ///     applyHeightToFirstAscent: false,
  ///   ),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Disable height for first/last line to reduce vertical spacing.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default behavior applies height to all lines.
  /// - Affects vertical alignment in tight layouts.
  /// {@endtemplate}
  final TextHeightBehavior? textHeightBehavior;

  /// {@template selectable_linkify_cursorHeight}
  /// How tall the cursor will be.
  ///
  /// Controls the height of the text cursor in logical pixels.
  /// If `null`, the cursor height matches the font size.
  ///
  /// ### Parameters
  ///
  /// - Type: `double?`
  /// - Required: No
  /// - Default: `null` (matches font size)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// cursorHeight: 20.0
  /// ```
  ///
  /// ```dart
  /// cursorHeight: 24.0 // Taller than font
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   cursorHeight: 20.0,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Leave `null` for default behavior.
  /// - Set explicitly for custom cursor appearance.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the cursor height is determined by the font metrics.
  /// - Very small heights may make the cursor hard to see.
  /// {@endtemplate}
  final double? cursorHeight;

  /// {@template selectable_linkify_selectionControls}
  /// Optional delegate for building the text selection handles and toolbar.
  ///
  /// Customizes the selection UI (handles, toolbar, magnifier).
  ///
  /// ### Parameters
  ///
  /// - Type: `TextSelectionControls?`
  /// - Required: No
  /// - Default: `null` (uses platform default)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// selectionControls: MyCustomSelectionControls()
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   selectionControls: PlatformSelectionControls(),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use platform-specific selection controls.
  /// - Create custom selection UI.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the platform default controls are used.
  /// - Custom controls must implement all required methods.
  /// {@endtemplate}
  final TextSelectionControls? selectionControls;

  /// {@template selectable_linkify_onSelectionChanged}
  /// Called when the user changes the selection of text (including the cursor location).
  ///
  /// Invoked on every selection change, including cursor movement without selection.
  ///
  /// ### Parameters
  ///
  /// - `selection`: The current [TextSelection].
  /// - `cause`: The [SelectionChangedCause] (e.g., tap, drag, keyboard).
  ///
  /// ### Return value
  ///
  /// Returns `void`. This is a side-effect callback.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// onSelectionChanged: (selection, cause) {
  ///   print('Selection: ${selection.start} - ${selection.end}');
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   onSelectionChanged: (selection, cause) {
  ///     if (selection.isCollapsed) {
  ///       // Cursor moved, no text selected
  ///     }
  ///   },
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Track selection state for toolbar visibility.
  /// - Log selection changes for analytics.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, no notification is sent.
  /// - Called even when selection changes programmatically.
  /// {@endtemplate}
  final SelectionChangedCallback? onSelectionChanged;

  /// {@template selectable_linkify_useMouseRegion}
  /// Whether to wrap link spans in a [MouseRegion] to show a click cursor on hover.
  ///
  /// When `true`, hovering over a link shows the system click cursor.
  /// This enhances the visual affordance that the text is tappable.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool`
  /// - Required: No
  /// - Default: `false`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// useMouseRegion: true // Show click cursor on hover
  /// ```
  ///
  /// ```dart
  /// useMouseRegion: false // Default cursor everywhere
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// SelectableLinkify(
  ///   text: text,
  ///   useMouseRegion: true,
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable for desktop/web to improve UX.
  /// - Disable on mobile where hover doesn't apply.
  ///
  /// ### Edge cases
  ///
  /// - Only affects mouse cursor; touch behavior is handled by [TapGestureRecognizer].
  /// - Adds a [MouseRegion] widget per link, which may impact performance with many links.
  /// {@endtemplate}
  final bool useMouseRegion;

  /// {@macro selectable_linkify}
  const SelectableLinkify({
    super.key,
    required this.text,
    this.linkifiers = defaultLinkifiers,
    this.onOpen,
    this.options = const LinkifyOptions(),
    // TextSpan
    this.style,
    this.linkStyle,
    // RichText
    this.textAlign,
    this.textDirection,
    this.minLines,
    this.maxLines,
    // SelectableText
    this.focusNode,
    this.textScaler,
    this.strutStyle,
    this.showCursor = false,
    this.autofocus = false,
    this.contextMenuBuilder,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollPhysics,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.cursorHeight,
    this.selectionControls,
    this.onSelectionChanged,
    this.useMouseRegion = false,
  });

  /// {@template selectable_linkify_build}
  /// Builds the selectable linkified text widget.
  ///
  /// Parses [text] using [linkify], builds a [TextSpan] tree with
  /// [buildTextSpan], and renders it via [SelectableText.rich].
  ///
  /// ### Return value
  ///
  /// Returns a [SelectableText.rich] widget containing linkified text.
  ///
  /// ### Edge cases
  ///
  /// - Falls back to [Theme.of(context).textTheme.bodyMedium] if [style] is `null`.
  /// - Links default to blue accent + underline if [linkStyle] is `null`.
  /// {@endtemplate}
  @override
  Widget build(BuildContext context) {
    List<LinkifyElement> elements = linkify(text, options: options, linkifiers: linkifiers);

    return SelectableText.rich(
      buildTextSpan(
        elements,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        onOpen: onOpen,
        linkStyle: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
        ).merge(linkStyle),
        useMouseRegion: useMouseRegion,
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      minLines: minLines,
      maxLines: maxLines,
      focusNode: focusNode,
      strutStyle: strutStyle,
      showCursor: showCursor,
      textScaler: textScaler,
      autofocus: autofocus,
      contextMenuBuilder: contextMenuBuilder,
      cursorWidth: cursorWidth,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      dragStartBehavior: dragStartBehavior,
      enableInteractiveSelection: enableInteractiveSelection,
      onTap: onTap,
      scrollPhysics: scrollPhysics,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      cursorHeight: cursorHeight,
      selectionControls: selectionControls,
      onSelectionChanged: onSelectionChanged,
    );
  }
}

/// {@template linkable_span}
/// A [WidgetSpan] that wraps an [InlineSpan] in a [MouseRegion] for cursor feedback.
///
/// Used internally by [buildTextSpanChildren] to provide a click cursor
/// when hovering over link spans. The [MouseRegion] applies the specified
/// [mouseCursor] to the wrapped content.
///
/// ### Example
///
/// ```dart
/// LinkableSpan(
///   mouseCursor: SystemMouseCursors.click,
///   inlineSpan: TextSpan(
///     text: 'Click here',
///     style: TextStyle(color: Colors.blue),
///   ),
/// )
/// ```
///
/// ### Usage
///
/// This class is used internally by [buildTextSpanChildren]. You should not
/// need to use it directly in most cases.
///
/// ### Parameters
///
/// - `mouseCursor`: The cursor to show on hover (e.g., [SystemMouseCursors.click]).
/// - `inlineSpan`: The text span to wrap in a [MouseRegion].
///
/// ### Return value
///
/// Returns a [WidgetSpan] containing a [MouseRegion] with a [Text.rich] child.
///
/// ### Edge cases
///
/// - The [mouseCursor] is applied to the entire span area, not just text.
/// - Nested [MouseRegion] widgets may conflict with parent regions.
/// {@endtemplate}
class LinkableSpan extends WidgetSpan {
  /// {@template linkable_span_constructor}
  /// Creates a [LinkableSpan] with the specified [mouseCursor] and [inlineSpan].
  ///
  /// The [mouseCursor] is applied to a [MouseRegion] that wraps the [inlineSpan].
  /// The [inlineSpan] is rendered via [Text.rich] inside the [MouseRegion].
  ///
  /// ### Parameters
  ///
  /// - `mouseCursor`: The cursor to display on hover. Required.
  /// - `inlineSpan`: The span content to wrap. Required.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// LinkableSpan(
  ///   mouseCursor: SystemMouseCursors.click,
  ///   inlineSpan: TextSpan(text: 'Link'),
  /// )
  /// ```
  /// {@endtemplate}
  LinkableSpan({
    required MouseCursor mouseCursor,
    required InlineSpan inlineSpan,
  }) : super(
    child: MouseRegion(
      cursor: mouseCursor,
      child: Text.rich(
        inlineSpan,
      ),
    ),
  );
}

/// {@template build_text_span}
/// Builds a [TextSpan] from a list of [LinkifyElement]s with optional styling and callbacks.
///
/// This is a low-level function that constructs the [TextSpan] tree used by
/// [Linkify] and [SelectableLinkify]. Use this when you need raw [TextSpan]
/// construction for integration with your own [RichText] widget.
///
/// ### Example
///
/// ```dart
/// final elements = linkify('Visit https://flutter.dev');
/// final textSpan = buildTextSpan(
///   elements,
///   style: const TextStyle(fontSize: 16),
///   linkStyle: const TextStyle(color: Colors.blue),
///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
/// );
/// ```
///
/// ### Usage
///
/// ```dart
/// RichText(
///   text: buildTextSpan(
///     elements,
///     style: myStyle,
///     onOpen: (link) => launchUrl(Uri.parse(link.url)),
///   ),
/// )
/// ```
///
/// ### Parameters
///
/// - `elements`: The list of [LinkifyElement]s to convert to spans.
/// - `style`: The base text style for non-link text.
/// - `linkStyle`: The text style for link text (merged on top of [style]).
/// - `onOpen`: Callback invoked when a link is tapped.
/// - `useMouseRegion`: Whether to show a click cursor on link hover.
///
/// ### Return value
///
/// Returns a [TextSpan] with children for each element.
///
/// ### Edge cases
///
/// - If [elements] is empty, returns a [TextSpan] with no children.
/// - If [onOpen] is `null`, link spans have no [TapGestureRecognizer].
/// - If [useMouseRegion] is `true`, links are wrapped in [MouseRegion].
/// {@endtemplate}
TextSpan buildTextSpan(List<LinkifyElement> elements, {
  TextStyle? style,
  TextStyle? linkStyle,
  LinkCallback? onOpen,
  bool useMouseRegion = false,
}) => TextSpan(
  children: buildTextSpanChildren(
    elements,
    style: style,
    linkStyle: linkStyle,
    onOpen: onOpen,
    useMouseRegion: useMouseRegion,
  ),
);

/// {@template build_text_span_children}
/// Builds a list of [InlineSpan]s from [LinkifyElement]s with optional styling and callbacks.
///
/// This is the core function that converts linkified elements into renderable spans.
/// Each [LinkableElement] becomes a tappable [TextSpan], and each plain text element
/// becomes a styled [TextSpan].
///
/// ### Example
///
/// ```dart
/// final elements = linkify('Email support@example.com');
/// final spans = buildTextSpanChildren(
///   elements,
///   style: const TextStyle(fontSize: 16),
///   linkStyle: const TextStyle(color: Colors.blue),
///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
/// );
/// ```
///
/// ### Usage
///
/// ```dart
/// Text.rich(
///   TextSpan(
///     children: buildTextSpanChildren(elements),
///   ),
/// )
/// ```
///
/// ### Parameters
///
/// - `elements`: The list of [LinkifyElement]s to convert.
/// - `style`: The base text style for non-link text.
/// - `linkStyle`: The text style for link text (merged on top of [style]).
/// - `onOpen`: Callback invoked when a link is tapped.
/// - `useMouseRegion`: Whether to wrap links in [MouseRegion] for cursor feedback.
///
/// ### Return value
///
/// Returns a `List<InlineSpan>?` where each element is either a plain [TextSpan]
/// or a [LinkableSpan] (if [useMouseRegion] is `true`) for link elements.
///
/// ### Edge cases
///
/// - Returns `null` if [elements] is empty (though this is unlikely in practice).
/// - [LinkableElement]s get [linkStyle] applied; plain elements get [style].
/// - If [onOpen] is `null`, no [TapGestureRecognizer] is attached to link spans.
/// - If [useMouseRegion] is `true`, each link is wrapped in a [MouseRegion].
/// {@endtemplate}
List<InlineSpan>? buildTextSpanChildren(List<LinkifyElement> elements, {
  TextStyle? style,
  TextStyle? linkStyle,
  LinkCallback? onOpen,
  bool useMouseRegion = false,
}) => [
  for (var element in elements)
    if (element is LinkableElement) ...[
      TextSpan(
        text: element.text,
        style: linkStyle,
        recognizer: onOpen != null ? (TapGestureRecognizer()..onTap = () => onOpen(element)) : null,
        mouseCursor: useMouseRegion ? SystemMouseCursors.click : null,
      )
    ] else ...[
      TextSpan(text: element.text, style: style)
    ],
];

/// {@template linkify_span}
/// A [TextSpan] that automatically linkifies its text content.
///
/// Combines the functionality of [linkify] and [TextSpan] into a single widget.
/// Useful when you need a linkified text span for use in [RichText] or [Text.rich]
/// without creating a full [Linkify] widget.
///
/// ### Example
///
/// ```dart
/// Text.rich(
///   LinkifySpan(
///     text: 'Visit https://flutter.dev for docs',
///     style: const TextStyle(fontSize: 16),
///     linkStyle: const TextStyle(color: Colors.blue),
///     onOpen: (link) => launchUrl(Uri.parse(link.url)),
///   ),
/// )
/// ```
///
/// ### Usage
///
/// ```dart
/// RichText(
///   text: LinkifySpan(
///     text: 'Contact support@example.com',
///     onOpen: (link) => launchUrl(Uri.parse(link.url)),
///   ),
/// )
/// ```
///
/// ### Parameters
///
/// - `text`: The plain text to be linkified.
/// - `linkStyle`: The text style for link text.
/// - `onOpen`: Callback invoked when a link is tapped.
/// - `options`: Configuration for the `linkify` parser.
/// - `linkifiers`: List of linkifier instances to use.
/// - `useMouseRegion`: Whether to show a click cursor on link hover.
/// - All other parameters are inherited from [TextSpan].
///
/// ### Return value
///
/// Returns a [TextSpan] with children generated by [buildTextSpanChildren].
///
/// ### Edge cases
///
/// - The [text] is parsed on construction; changing it requires creating a new instance.
/// - [style] from [TextSpan] is passed to [buildTextSpanChildren] as the base style.
/// - [recognizer] from [TextSpan] is overridden by link-specific recognizers.
/// {@endtemplate}
class LinkifySpan extends TextSpan {
  /// {@template linkify_span_constructor}
  /// Creates a [LinkifySpan] that automatically linkifies the given [text].
  ///
  /// The [text] is parsed using [linkifiers] and [options]. The resulting
  /// elements are converted to [TextSpan] children via [buildTextSpanChildren].
  ///
  /// ### Parameters
  ///
  /// - `text`: The plain text to linkify. Required.
  /// - `linkStyle`: Style for link text. Optional.
  /// - `onOpen`: Callback for link taps. Optional.
  /// - `options`: Parser options. Default: `const LinkifyOptions()`.
  /// - `linkifiers`: Linkifier list. Default: `defaultLinkifiers`.
  /// - `useMouseRegion`: Show click cursor. Default: `false`.
  /// - All other parameters are forwarded to [TextSpan].
  ///
  /// ### Examples
  ///
  /// ```dart
  /// LinkifySpan(
  ///   text: 'Visit https://flutter.dev',
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ```dart
  /// LinkifySpan(
  ///   text: 'Email support@example.com',
  ///   linkStyle: const TextStyle(color: Colors.teal),
  ///   options: LinkifyOptions(defaultToHttps: true),
  ///   onOpen: (link) => launchUrl(Uri.parse(link.url)),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use in [RichText] for inline linkified text.
  /// - Combine with other [TextSpan]s for mixed content.
  ///
  /// ### Edge cases
  ///
  /// - [recognizer] from [TextSpan] is overridden; only link recognizers are active.
  /// - [mouseCursor] from [TextSpan] is ignored; link cursors are controlled by [useMouseRegion].
  /// {@endtemplate}
  LinkifySpan({
    required String text,
    TextStyle? linkStyle,
    LinkCallback? onOpen,
    LinkifyOptions options = const LinkifyOptions(),
    List<Linkifier> linkifiers = defaultLinkifiers,
    bool useMouseRegion = false,
    super.style,
    super.recognizer,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
    super.semanticsLabel,
    super.locale,
    super.spellOut,
  }) : super(
    children: buildTextSpanChildren(
      linkify(text, options: options, linkifiers: linkifiers),
      style: style,
      linkStyle: linkStyle,
      onOpen: onOpen,
      useMouseRegion: useMouseRegion,
    ),
  );
}