import 'package:flutter/material.dart';

import '../typedefs.dart';
import '../link_preview_interface.dart';
import '../ui/link_preview_builder.dart';

/// {@template ui_extension}
/// UI helpers for [LinkPreviewInterface], allowing easier widget construction.
///
/// This extension provides convenience methods for building link preview
/// widgets with various customization options and callbacks. It wraps
/// [LinkPreviewBuilder] with a simpler API for common use cases.
///
/// ### Common actions
///
/// - Build a link preview widget: `linkPreview.builder(link: url, builder: ...)`
/// - Add loading state: `linkPreview.builder(link: url, loadingBuilder: ...)`
/// - Enable animation: `linkPreview.builder(link: url, enableAnimation: true)`
///
/// ### Edge cases
///
/// - [link] parameter is required — must be a valid URL string
/// - [builder] parameter is required — provides the preview data to the UI
/// - Default animation duration is 300ms when [enableAnimation] is true
///
/// ### Usage
///
/// ```dart
/// linkPreview.builder(
///   link: 'https://example.com',
///   builder: (context, data) => Text(data?.title ?? 'No title'),
///   loadingBuilder: (context) => CircularProgressIndicator(),
/// );
/// ```
/// {@endtemplate}
extension UiExtension on LinkPreviewInterface {
  /// {@template ui_extension_builder}
  /// Builds a [LinkPreviewBuilder] widget with the provided parameters.
  ///
  /// This is a convenience method to create link preview widgets in UI code.
  /// The widget automatically fetches preview data for the specified link
  /// and builds the UI using the provided builder functions.
  ///
  /// ### Parameters
  ///
  /// - [link]: **Required.** The URL to preview. Must be a valid URL string.
  /// - [builder]: **Required.** Builds the final widget using the fetched
  ///   preview data. Receives [BuildContext] and [PreviewData]? (null while loading).
  /// - [loadingBuilder]: Optional widget builder displayed while fetching
  ///   preview data. If null, no loading indicator is shown.
  /// - [animationDuration]: Duration for the default expand animation.
  ///   Defaults to 300ms. Only used when [enableAnimation] is true.
  /// - [enableAnimation]: Enables expand animation when preview data loads.
  ///   Defaults to false.
  /// - [animatedBuilder]: Allows you to define a custom animation wrapper
  ///   around the result widget. Overrides default animation behavior.
  /// - [corsProxy]: Optional CORS proxy URL for web use. Not guaranteed
  ///   to work in all cases. Only needed for web platform.
  /// - [userAgent]: User-Agent header for the HTTP request. Defaults to
  ///   a Chrome/WhatsApp user-agent string.
  /// - [requestTimeout]: Maximum time to wait for a preview request
  ///   before timing out. Defaults to 5 seconds.
  /// - [onPreviewDataFetched]: Callback triggered when preview data is fetched.
  ///   Useful for logging or analytics.
  /// - [cacheDuration]: Duration for the cache. Defaults to 24 hours.
  ///   Set to `Duration.zero` to disable caching.
  ///
  /// ### Return value
  ///
  /// Returns a [Widget] — specifically a [LinkPreviewBuilder] that handles
  /// fetching, caching, and rendering the link preview.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Basic usage with loading state
  /// linkPreview.builder(
  ///   link: 'https://example.com',
  ///   builder: (context, data) {
  ///     if (data == null) return SizedBox.shrink();
  ///     return Column(
  ///       crossAxisAlignment: CrossAxisAlignment.start,
  ///       children: [
  ///         if (data.image != null) Image.network(data.image!),
  ///         Text(data.title ?? 'No title'),
  ///         Text(data.description ?? 'No description'),
  ///       ],
  ///     );
  ///   },
  ///   loadingBuilder: (context) => CircularProgressIndicator(),
  /// );
  /// ```
  ///
  /// ```dart
  /// // With animation and custom timeout
  /// linkPreview.builder(
  ///   link: 'https://example.com',
  ///   builder: (context, data) => MyPreviewWidget(data: data),
  ///   enableAnimation: true,
  ///   animationDuration: Duration(milliseconds: 500),
  ///   requestTimeout: Duration(seconds: 10),
  /// );
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Display rich link previews in chat or social feeds
  /// - Show loading states while fetching metadata
  /// - Animate the preview appearance on load
  /// - Cache preview data to reduce network requests
  ///
  /// ### Edge cases
  ///
  /// - If [link] is not a valid URL, the builder receives `null` data
  /// - If the request times out, the builder receives `null` data
  /// - [animatedBuilder] takes precedence over [enableAnimation] and
  ///   [animationDuration] when both are provided
  /// - [corsProxy] may not work on all web platforms due to CORS policies
  /// - Setting [cacheDuration] to `Duration.zero` disables caching entirely
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // In a ListView item
  /// ListView.builder(
  ///   itemCount: urls.length,
  ///   itemBuilder: (context, index) {
  ///     return linkPreview.builder(
  ///       link: urls[index],
  ///       builder: (context, data) => LinkPreviewCard(data: data),
  ///       loadingBuilder: (context) => SkeletonLoader(),
  ///     );
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  Widget builder({
    /// The URL to preview.
    required String link,

    /// Builds the final widget using the fetched preview data.
    required LinkPreviewWidgetBuilder builder,

    /// Widget builder displayed while fetching preview data.
    WidgetBuilder? loadingBuilder,

    /// Duration for the default expand animation. Defaults to 300ms.
    Duration? animationDuration,

    /// Enables expand animation. Defaults to false.
    bool? enableAnimation,

    /// Allows you to define a custom animation wrapper around the result widget.
    LinkPreviewAnimationBuilder? animatedBuilder,

    /// Optional CORS proxy for web use. Not guaranteed to work in all cases.
    String? corsProxy,

    /// User-Agent to be used in the HTTP request to the link
    /// Default: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3', 'WhatsApp/2.21.12.21 A'
    String? userAgent,

    /// Maximum time to wait for a preview request before timing out. Defaults to 5 seconds.
    Duration? requestTimeout,

    /// Callback triggered when preview data is fetched.
    OnPreviewDataFetched? onPreviewDataFetched,

    /// Duration for the cache. Defaults to 24 hours.
    Duration? cacheDuration,
  }) {
    return LinkPreviewBuilder(
      link: link,
      builder: builder,
      loadingBuilder: loadingBuilder,
      animationDuration: animationDuration,
      enableAnimation: enableAnimation,
      animatedBuilder: animatedBuilder,
      corsProxy: corsProxy,
      userAgent: userAgent,
      requestTimeout: requestTimeout,
      onPreviewDataFetched: onPreviewDataFetched,
      cacheDuration: cacheDuration,
    );
  }
}