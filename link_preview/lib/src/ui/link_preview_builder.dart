import 'package:flutter/material.dart';

import '../link_preview.dart';
import '../models/link_preview_data.dart';
import '../typedefs.dart' show LinkPreviewAnimationBuilder, LinkPreviewWidgetBuilder, OnPreviewDataFetched;

/// {@template link_preview_builder}
/// A widget that fetches link preview metadata and builds a widget using the provided builder.
///
/// This widget fetches metadata from a provided URL (such as title, description, and image)
/// and passes it to a custom builder function to render your own preview UI.
///
/// It supports optional loading states, customizable animations, and full control over the
/// network request configuration (e.g., user agent, timeout, CORS proxy).
///
/// ## Example usage:
/// ```dart
/// LinkPreviewBuilder(
///   link: 'https://example.com',
///   builder: (context, data) => Card(
///     child: ListTile(
///       leading: data.image != null ? Image.network(data.image!.url) : null,
///       title: Text(data.title ?? ''),
///       subtitle: Text(data.description ?? ''),
///     ),
///   ),
///   loadingBuilder: (context) => const CircularProgressIndicator(),
///   enableAnimation: true,
/// )
/// ```
/// {@endtemplate}
class LinkPreviewBuilder extends StatefulWidget {
  /// The URL to preview.
  ///
  /// This is the link from which the preview metadata will be fetched.
  /// Required field. Default: null
  final String link;

  /// Builds the final widget using the fetched preview data.
  ///
  /// This is called after metadata is fetched successfully from the link.
  /// Required field. Default: null
  final LinkPreviewWidgetBuilder builder;

  /// Widget builder displayed while fetching preview data.
  ///
  /// Useful for showing a loading indicator or placeholder while waiting
  /// for metadata to load. Default: null (no loading widget shown)
  final WidgetBuilder? loadingBuilder;

  /// Duration for the default expand animation.
  ///
  /// Applied when [enableAnimation] is true. Default: null (falls back to 300ms)
  final Duration? animationDuration;

  /// Enables expand animation for the preview widget.
  ///
  /// When enabled, the resulting widget appears with an animated size transition.
  /// Default: false
  final bool? enableAnimation;

  /// Allows you to define a custom animation wrapper around the result widget.
  ///
  /// If not provided, a default [SizeTransition] is used.
  /// Default: null
  final LinkPreviewAnimationBuilder? animatedBuilder;

  /// Optional CORS proxy for web-based link previews.
  ///
  /// This is useful when dealing with cross-origin issues on Flutter Web.
  /// It is not guaranteed to work in all cases, depending on the target server.
  /// Default: null
  final String? corsProxy;

  /// User agent to send as a GET header when requesting the preview data.
  ///
  /// Can be used to simulate requests from a browser or crawler.
  /// Default:
  /// `'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'`
  final String? userAgent;

  /// Maximum time to wait for a preview request before timing out.
  ///
  /// If the request takes longer than this duration, it will be aborted.
  /// Default: null (defaults to 5 seconds internally)
  final Duration? requestTimeout;

  /// Duration to cache the preview data.
  ///
  /// Prevents redundant network calls for the same link within the duration.
  /// Default: `Duration(hours: 24)`
  final Duration? cacheDuration;

  /// Callback triggered when preview data is successfully fetched.
  ///
  /// Can be used to handle side-effects like caching or logging.
  /// Default: null
  final OnPreviewDataFetched? onPreviewDataFetched;

  /// {@macro link_preview_builder}
  const LinkPreviewBuilder({
    super.key,
    required this.link,
    required this.builder,
    this.loadingBuilder,
    this.animationDuration,
    this.enableAnimation,
    this.animatedBuilder,
    this.corsProxy,
    this.userAgent,
    this.requestTimeout,
    this.onPreviewDataFetched,
    this.cacheDuration = const Duration(hours: 24),
  });

  @override
  State<LinkPreviewBuilder> createState() => _LinkPreviewBuilderState();
}

class _LinkPreviewBuilderState extends State<LinkPreviewBuilder> with SingleTickerProviderStateMixin {
  bool isFetchingPreviewData = false;
  bool shouldAnimate = false;

  late final Animation<double> _animation;
  late final AnimationController _controller;

  LinkPreviewData? _previewData;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    );

    _fetchData(widget.link);
  }

  @override
  void didUpdateWidget(covariant LinkPreviewBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.link != oldWidget.link) {
      _fetchData(widget.link);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Determines whether animation should be run.
  bool get runAnimation => widget.enableAnimation == true && shouldAnimate;

  /// Fetches preview data for the given link.
  Future<void> _fetchData(String link) async {
    if (!mounted) return;

    setState(() {
      isFetchingPreviewData = true;
    });

    final previewData = await LinkPreview.get(
      link,
      cacheDuration: widget.cacheDuration,
      proxy: widget.corsProxy,
      requestTimeout: widget.requestTimeout,
      userAgent: widget.userAgent,
    );

    if (!mounted) return;

    setState(() {
      shouldAnimate = true;
      _previewData = previewData;
    });

    _controller.reset();
    _controller.forward();

    await _handlePreviewDataFetched(previewData);
  }

  Future<void> _handlePreviewDataFetched(LinkPreviewData? previewData) async {
    await Future.delayed(widget.animationDuration ?? const Duration(milliseconds: 300));

    if (mounted) {
      widget.onPreviewDataFetched?.call(previewData);
      setState(() {
        isFetchingPreviewData = false;
      });
    }
  }

  Widget _defaultAnimated(Widget child) => SizeTransition(
    axis: Axis.vertical,
    axisAlignment: -1,
    sizeFactor: _animation,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    if (isFetchingPreviewData) {
      return widget.loadingBuilder != null ? widget.loadingBuilder!(context) : const SizedBox.shrink();
    }

    final child = widget.builder(context, _previewData);

    if (runAnimation) {
      return widget.animatedBuilder != null ? widget.animatedBuilder!(child, _animation) : _defaultAnimated(child);
    } else {
      return child;
    }
  }
}