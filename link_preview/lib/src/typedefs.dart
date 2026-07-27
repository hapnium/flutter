import 'package:flutter/cupertino.dart' show Animation, BuildContext, Widget;
import 'package:linkify/linkify.dart' show LinkableElement;

import 'models/link_preview_data.dart';

/// {@template link_preview_widget_builder}
/// A function signature for building a custom widget from fetched preview data.
///
/// This builder is invoked after the link preview has been successfully loaded
/// (or after an error, in which case [data] is `null`). Use this to define
/// exactly how the preview card should be rendered — image, title, description,
/// and any additional UI elements.
///
/// ### Parameters
///
/// - [context] The build context inherited from the parent widget tree. Useful
///   for accessing theme data, media queries, and navigation.
/// - [data] A nullable [LinkPreviewData] containing the resolved metadata
///   (title, description, image URL) for the given link. When `null`, the
///   preview failed to load — use this to show a fallback or error state.
///
/// ### Return value
///
/// Must return a [Widget] that represents the visual representation of the
/// link preview. Typically a [Card], [Container], or any composable widget.
///
/// ### Example
///
/// ```dart
/// LinkPreviewWidget(
///   link: 'https://flutter.dev',
///   builder: (context, data) {
///     if (data == null) {
///       return const SizedBox.shrink();
///     }
///     return Card(
///       child: Column(
///         crossAxisAlignment: CrossAxisAlignment.start,
///         children: [
///           if (data.image != null)
///             Image.network(data.image!),
///           Padding(
///             padding: const EdgeInsets.all(8),
///             child: Text(data.title ?? 'No title'),
///           ),
///         ],
///       ),
///     );
///   },
/// );
/// ```
///
/// ### Usage
///
/// Pass this builder to [LinkPreviewWidget.builder] or any widget that accepts
/// a custom preview renderer. The builder is called once the preview data is
/// available, allowing you to control every pixel of the output.
/// {@endtemplate}
typedef LinkPreviewWidgetBuilder = Widget Function(BuildContext context, LinkPreviewData? data);

/// {@template on_preview_data_fetched}
/// A callback signature invoked when link preview metadata has been resolved.
///
/// This callback fires after the internal HTTP request and HTML parsing
/// complete. Use it for side effects such as analytics logging, state
/// updates, or triggering downstream UI changes.
///
/// ### Parameters
///
/// - [data] A nullable [LinkPreviewData] holding the extracted metadata.
///   When `null`, the fetch failed — the link may be unreachable or the page
///   may have no parseable Open Graph / Twitter Card tags.
///
/// ### Return value
///
/// This callback returns `void`. It is not expected to produce a widget.
///
/// ### Example
///
/// ```dart
/// LinkPreviewWidget(
///   link: 'https://github.com/flutter/flutter',
///   onPreviewDataFetched: (data) {
///     if (data != null) {
///       analytics.logEvent('preview_loaded', {
///         'title': data.title,
///         'url': 'https://github.com/flutter/flutter',
///       });
///     } else {
///       analytics.logEvent('preview_failed', {
///         'url': 'https://github.com/flutter/flutter',
///       });
///     }
///   },
/// );
/// ```
///
/// ### Usage
///
/// Supply this callback to any widget that supports [OnPreviewDataFetched].
/// It is called exactly once per fetch cycle. The callback runs synchronously
/// within the widget's state update — avoid heavy computation inside it.
/// {@endtemplate}
typedef OnPreviewDataFetched = void Function(LinkPreviewData? data);

/// {@template link_preview_animation_builder}
/// A function signature for wrapping a preview widget in a custom animation.
///
/// This builder is called once the preview content is ready and receives both
/// the rendered child widget and an [Animation] that progresses from `0.0` to
/// `1.0`. Use it to fade in, slide, scale, or apply any custom transition
/// to the preview card.
///
/// ### Parameters
///
/// - [child] The fully built preview widget produced by [LinkPreviewWidgetBuilder].
///   This is the content to animate — do not discard it.
/// - [animation] An [Animation<double>] driven by the parent state. At `0.0`
///   the animation has not started; at `1.0` it is fully complete. Typical
///   uses include interpolating opacity, translation offsets, or scale factors.
///
/// ### Return value
///
/// Must return a [Widget] that contains [child] and applies the desired
/// animation. Common choices are [FadeTransition], [SlideTransition],
/// [ScaleTransition], or a custom [AnimatedBuilder] widget.
///
/// ### Example
///
/// ```dart
/// LinkPreviewWidget(
///   link: 'https://docs.flutter.dev',
///   animationBuilder: (child, animation) {
///     return FadeTransition(
///       opacity: animation,
///       child: SlideTransition(
///         position: Tween<Offset>(
///           begin: const Offset(0, 0.1),
///           end: Offset.zero,
///         ).animate(animation),
///         child: child,
///       ),
///     );
///   },
/// );
/// ```
///
/// ### Usage
///
/// Pass this builder to [LinkPreviewWidget.animationBuilder]. The animation
/// is typically driven by a [TickerProvider] inside the widget's state. If
/// no animation builder is provided, the preview appears without transition.
/// {@endtemplate}
typedef LinkPreviewAnimationBuilder = Widget Function(Widget child, Animation<double> animation);

/// {@template link_callback}
/// A callback signature invoked when the user taps a link within preview text.
///
/// This callback fires when a [LinkableElement] inside the parsed preview
/// content is tapped. Use it to open the link in a browser, navigate to an
/// in-app route, or log the interaction.
///
/// ### Parameters
///
/// - [link] A [LinkableElement] representing the tapped link. Contains
///   the raw [url], the display [text], and the [type] (e.g. `url`, `email`).
///
/// ### Return value
///
/// This callback returns `void`. It is not expected to produce a widget.
///
/// ### Example
///
/// ```dart
/// LinkPreviewWidget(
///   link: 'https://flutter.dev',
///   onLinkTapped: (link) {
///     launchUrl(link.url);
///   },
/// );
/// ```
///
/// ### Usage
///
/// Supply this callback to any widget that supports [LinkCallback]. It is
/// called once per tap on any detectable link in the preview body.
/// {@endtemplate}
typedef LinkCallback = void Function(LinkableElement link);