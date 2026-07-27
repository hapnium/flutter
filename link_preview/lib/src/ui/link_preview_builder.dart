import 'package:flutter/material.dart';

import '../link_preview.dart';
import '../models/link_preview_data.dart';
import '../typedefs.dart' show LinkPreviewAnimationBuilder, LinkPreviewWidgetBuilder, OnPreviewDataFetched;

/// {@template link_preview_builder}
/// A stateful widget that fetches link preview metadata and builds a custom UI using a builder callback.
///
/// This widget asynchronously fetches Open Graph and other metadata from a given URL
/// (including title, description, and image) and passes the result to a user-provided
/// builder function. It supports optional loading indicators, expand animations, and
/// full control over network request configuration (e.g., user agent, timeout, CORS proxy).
///
/// ### Example
///
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
///   animationDuration: const Duration(milliseconds: 400),
/// )
/// ```
///
/// ### Usage
///
/// Use [LinkPreviewBuilder] when you need full control over the rendered preview widget.
/// The [builder] callback receives a [BuildContext] and an optional [LinkPreviewData] object.
/// If the fetch fails, `data` will be `null`, allowing you to render a fallback.
///
/// ```dart
/// LinkPreviewBuilder(
///   link: url,
///   builder: (context, data) {
///     if (data == null) return const Text('No preview available');
///     return PreviewCard(data: data);
///   },
/// )
/// ```
///
/// ### Common actions
///
/// - Show a loading skeleton while fetching: provide [loadingBuilder].
/// - Animate the preview into view: set [enableAnimation] to `true`.
/// - Use a CORS proxy on web: set [corsProxy] to your proxy URL.
/// - Cache results aggressively: set [cacheDuration] to a longer duration.
///
/// ### Edge cases
///
/// - If [link] is an invalid URL, the fetch may fail and [builder] receives `null` data.
/// - If the widget is disposed before the fetch completes, no state updates occur.
/// - Changing [link] at runtime triggers a new fetch automatically via [didUpdateWidget].
/// {@endtemplate}
class LinkPreviewBuilder extends StatefulWidget {
  /// {@template link_preview_builder_link}
  /// The URL to fetch link preview metadata from.
  ///
  /// This is the primary input for the widget. The URL is used to fetch
  /// Open Graph metadata including title, description, and image.
  ///
  /// ### Parameters
  ///
  /// - Type: `String`
  /// - Required: Yes
  /// - Default: None
  ///
  /// ### Examples
  ///
  /// - `'https://example.com'`
  /// - `'https://github.com/flutter/flutter'`
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: 'https://flutter.dev',
  ///   builder: (context, data) => Text(data?.title ?? 'No title'),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Pass a dynamic URL from user input or a data source.
  /// - Change this value at runtime to re-fetch preview data.
  ///
  /// ### Edge cases
  ///
  /// - Invalid URLs may cause the fetch to fail silently.
  /// - URLs with authentication may not return public metadata.
  ///
  /// ### Return value
  ///
  /// Returns the `String` URL used for fetching preview metadata.
  /// {@endtemplate}
  final String link;

  /// {@template link_preview_builder_builder}
  /// A callback that builds the preview widget from the fetched [LinkPreviewData].
  ///
  /// This is called after metadata is successfully fetched from [link].
  /// The callback receives the current [BuildContext] and the fetched data
  /// (which may be `null` if the fetch failed).
  ///
  /// ### Parameters
  ///
  /// - `context`: The [BuildContext] of the widget tree.
  /// - `data`: The fetched [LinkPreviewData], or `null` on failure.
  ///
  /// ### Return value
  ///
  /// Returns a [Widget] that represents the preview UI.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// builder: (context, data) {
  ///   if (data == null) return const SizedBox.shrink();
  ///   return Column(
  ///     children: [
  ///       if (data.image != null) Image.network(data.image!.url),
  ///       Text(data.title ?? 'Untitled'),
  ///       Text(data.description ?? ''),
  ///     ],
  ///   );
  /// }
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Render a fallback widget when `data` is `null`.
  /// - Use `data.image` to display a thumbnail.
  /// - Use `data.title` and `data.description` for text content.
  ///
  /// ### Edge cases
  ///
  /// - `data` can be `null` if the URL is unreachable or returns no metadata.
  /// - The builder may be called multiple times if [link] changes.
  /// {@endtemplate}
  final LinkPreviewWidgetBuilder builder;

  /// {@template link_preview_builder_loadingBuilder}
  /// A widget builder displayed while the preview data is being fetched.
  ///
  /// Useful for showing a loading indicator, skeleton, or placeholder
  /// while the network request is in progress.
  ///
  /// ### Parameters
  ///
  /// - `context`: The [BuildContext] of the widget tree.
  ///
  /// ### Return value
  ///
  /// Returns a [Widget] to display during the loading state.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// loadingBuilder: (context) => const Center(
  ///   child: CircularProgressIndicator(),
  /// )
  /// ```
  ///
  /// ```dart
  /// loadingBuilder: (context) => const SkeletonLoader(),
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Show a centered spinner: `const Center(child: CircularProgressIndicator())`.
  /// - Show a placeholder card matching the final layout.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, a `SizedBox.shrink()` is shown (nothing visible).
  /// - The loading widget is shown until the fetch completes or the widget is disposed.
  /// {@endtemplate}
  final WidgetBuilder? loadingBuilder;

  /// {@template link_preview_builder_animationDuration}
  /// Duration for the default expand animation.
  ///
  /// Applied when [enableAnimation] is `true`. Controls how long the
  /// SizeTransition takes to expand the preview widget into view.
  ///
  /// ### Parameters
  ///
  /// - Type: `Duration?`
  /// - Required: No
  /// - Default: `null` (falls back to 300ms internally)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// animationDuration: const Duration(milliseconds: 400)
  /// ```
  ///
  /// ```dart
  /// animationDuration: const Duration(seconds: 1)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: url,
  ///   builder: (context, data) => PreviewCard(data: data),
  ///   enableAnimation: true,
  ///   animationDuration: const Duration(milliseconds: 500),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Speed up the animation: use a shorter duration (e.g., 150ms).
  /// - Slow down the animation: use a longer duration (e.g., 1s).
  ///
  /// ### Edge cases
  ///
  /// - If `null`, defaults to 300ms.
  /// - Very short durations may appear jarring.
  /// - Very long durations may feel sluggish.
  /// {@endtemplate}
  final Duration? animationDuration;

  /// {@template link_preview_builder_enableAnimation}
  /// Enables an expand animation for the preview widget.
  ///
  /// When `true`, the resulting widget appears with an animated [SizeTransition].
  /// The animation runs after the preview data is fetched and the widget is built.
  ///
  /// ### Parameters
  ///
  /// - Type: `bool?`
  /// - Required: No
  /// - Default: `false`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// enableAnimation: true
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: url,
  ///   builder: (context, data) => PreviewCard(data: data),
  ///   enableAnimation: true,
  ///   animationDuration: const Duration(milliseconds: 400),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Enable for a polished entry effect.
  /// - Disable for instant rendering.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, treated as `false`.
  /// - Animation only runs once per fetch; changing [link] re-triggers it.
  /// - If [animatedBuilder] is provided, it overrides the default [SizeTransition].
  /// {@endtemplate}
  final bool? enableAnimation;

  /// {@template link_preview_builder_animatedBuilder}
  /// A custom animation wrapper around the result widget.
  ///
  /// If provided, this builder is used instead of the default [SizeTransition].
  /// It receives the child widget and the current [Animation<double>] and must
  /// return a widget that applies the desired animation.
  ///
  /// ### Parameters
  ///
  /// - `child`: The widget built by [builder].
  /// - `animation`: The animation driving the transition (0.0 to 1.0).
  ///
  /// ### Return value
  ///
  /// Returns a [Widget] that wraps [child] with the desired animation.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// animatedBuilder: (child, animation) => FadeTransition(
  ///   opacity: animation,
  ///   child: child,
  /// )
  /// ```
  ///
  /// ```dart
  /// animatedBuilder: (child, animation) => SlideTransition(
  ///   position: Tween<Offset>(
  ///     begin: const Offset(0, 0.1),
  ///     end: Offset.zero,
  ///   ).animate(animation),
  ///   child: child,
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use [FadeTransition] for a fade-in effect.
  /// - Use [SlideTransition] for a slide-in effect.
  /// - Combine multiple transitions for complex effects.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, the default [SizeTransition] (vertical axis) is used.
  /// - Only called when [enableAnimation] is `true` and data has been fetched.
  /// {@endtemplate}
  final LinkPreviewAnimationBuilder? animatedBuilder;

  /// {@template link_preview_builder_corsProxy}
  /// Optional CORS proxy URL for web-based link previews.
  ///
  /// This is useful when dealing with cross-origin issues on Flutter Web.
  /// The proxy URL is prepended to the target URL before making the request.
  ///
  /// ### Parameters
  ///
  /// - Type: `String?`
  /// - Required: No
  /// - Default: `null`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// corsProxy: 'https://corsproxy.io/?'
  /// ```
  ///
  /// ```dart
  /// corsProxy: 'https://my-proxy.example.com/proxy?url='
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: 'https://example.com',
  ///   corsProxy: 'https://corsproxy.io/?',
  ///   builder: (context, data) => Text(data?.title ?? ''),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use a public CORS proxy for development.
  /// - Use a self-hosted proxy for production.
  ///
  /// ### Edge cases
  ///
  /// - Not guaranteed to work with all target servers.
  /// - May add latency due to the extra hop.
  /// - Some proxies may rate-limit or block requests.
  /// {@endtemplate}
  final String? corsProxy;

  /// {@template link_preview_builder_userAgent}
  /// User agent string sent as a GET header when requesting preview data.
  ///
  /// Can be used to simulate requests from a specific browser or crawler.
  /// Some servers return different content based on the user agent.
  ///
  /// ### Parameters
  ///
  /// - Type: `String?`
  /// - Required: No
  /// - Default: `'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// userAgent: 'Googlebot/2.1 (+http://www.google.com/bot.html)'
  /// ```
  ///
  /// ```dart
  /// userAgent: 'MyApp/1.0 (iOS; 16.0)'
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: url,
  ///   userAgent: 'MyApp/1.0',
  ///   builder: (context, data) => Text(data?.title ?? ''),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Use a browser user agent to get full page content.
  /// - Use a bot user agent if the server serves different content to bots.
  ///
  /// ### Edge cases
  ///
  /// - Some servers may block requests with non-browser user agents.
  /// - If `null`, the default user agent is used.
  /// {@endtemplate}
  final String? userAgent;

  /// {@template link_preview_builder_requestTimeout}
  /// Maximum time to wait for a preview request before timing out.
  ///
  /// If the network request takes longer than this duration, it will be aborted
  /// and the [builder] will receive `null` data.
  ///
  /// ### Parameters
  ///
  /// - Type: `Duration?`
  /// - Required: No
  /// - Default: `null` (defaults to 5 seconds internally)
  ///
  /// ### Examples
  ///
  /// ```dart
  /// requestTimeout: const Duration(seconds: 10)
  /// ```
  ///
  /// ```dart
  /// requestTimeout: const Duration(milliseconds: 500)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: url,
  ///   requestTimeout: const Duration(seconds: 3),
  ///   builder: (context, data) => Text(data?.title ?? ''),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Increase for slow networks or large pages.
  /// - Decrease for snappier UX on fast networks.
  ///
  /// ### Edge cases
  ///
  /// - If `null`, defaults to 5 seconds.
  /// - Very short timeouts may cause frequent failures.
  /// - Timeout applies to the entire request, not just connection.
  /// {@endtemplate}
  final Duration? requestTimeout;

  /// {@template link_preview_builder_cacheDuration}
  /// Duration to cache the fetched preview data.
  ///
  /// Prevents redundant network calls for the same URL within the specified duration.
  /// Cached data is stored internally by [LinkPreview.get].
  ///
  /// ### Parameters
  ///
  /// - Type: `Duration?`
  /// - Required: No
  /// - Default: `Duration(hours: 24)`
  ///
  /// ### Examples
  ///
  /// ```dart
  /// cacheDuration: const Duration(hours: 1)
  /// ```
  ///
  /// ```dart
  /// cacheDuration: const Duration(days: 7)
  /// ```
  ///
  /// ### Usage
  ///
  /// ```dart
  /// LinkPreviewBuilder(
  ///   link: url,
  ///   cacheDuration: const Duration(hours: 12),
  ///   builder: (context, data) => Text(data?.title ?? ''),
  /// )
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Set a short duration for frequently changing content.
  /// - Set a long duration for static content.
  /// - Set to `Duration.zero` to disable caching.
  ///
  /// ### Edge cases
  ///
  /// - Cache is in-memory; app restart clears it.
  /// - Different URLs are cached independently.
  /// {@endtemplate}
  final Duration? cacheDuration;

  /// {@template link_preview_builder_onPreviewDataFetched}
  /// Callback triggered after preview data is successfully fetched and the animation completes.
  ///
  /// Can be used to handle side-effects like logging, analytics, or custom caching.
  /// The callback receives the fetched [LinkPreviewData] (which may be `null` on failure).
  ///
  /// ### Parameters
  ///
  /// - `data`: The fetched [LinkPreviewData], or `null` if the fetch failed.
  ///
  /// ### Return value
  ///
  /// Returns `void`. This is a side-effect callback.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// onPreviewDataFetched: (data) {
  ///   if (data != null) {
  ///     analytics.logEvent('link_preview_fetched', {'url': link});
  ///   }
  /// }
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Log the result for debugging.
  /// - Track analytics events.
  /// - Store the data in a persistent cache.
  ///
  /// ### Edge cases
  ///
  /// - Called after the animation duration completes, not immediately on fetch.
  /// - Not called if the widget is disposed before the fetch completes.
  /// - If `null`, no action is taken.
  /// {@endtemplate}
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

/// {@template _link_preview_builder_state}
/// The mutable state for [LinkPreviewBuilder].
///
/// Manages the animation controller, fetch lifecycle, and preview data.
/// This state uses [SingleTickerProviderStateMixin] to provide a single
/// [Ticker] for the expand animation.
///
/// ### Internal lifecycle
///
/// 1. [initState] creates the [AnimationController] and starts the first fetch.
/// 2. [_fetchData] calls [LinkPreview.get] and updates state on completion.
/// 3. [_handlePreviewDataFetched] waits for the animation to finish, then
///    invokes [onPreviewDataFetched] and clears the loading state.
/// 4. [didUpdateWidget] re-fetches if [link] changes.
/// 5. [dispose] cleans up the [AnimationController].
/// {@endtemplate}
class _LinkPreviewBuilderState extends State<LinkPreviewBuilder> with SingleTickerProviderStateMixin {
  /// {@template _link_preview_builder_state_isFetchingPreviewData}
  /// Whether a preview data fetch is currently in progress.
  ///
  /// When `true`, the [loadingBuilder] is shown (if provided). When `false`,
  /// the [builder] output is shown.
  ///
  /// ### Return value
  ///
  /// Returns `true` during the network request, `false` otherwise.
  /// {@endtemplate}
  bool isFetchingPreviewData = false;

  /// {@template _link_preview_builder_state_shouldAnimate}
  /// Whether the expand animation should play.
  ///
  /// Set to `true` after the first successful fetch. This prevents the
  /// animation from playing before any data has been loaded.
  ///
  /// ### Return value
  ///
  /// Returns `true` after data has been fetched at least once.
  /// {@endtemplate}
  bool shouldAnimate = false;

  /// {@template _link_preview_builder_state_animation}
  /// The animation that drives the expand transition.
  ///
  /// A [CurvedAnimation] with [Curves.easeOutQuad] applied to [_controller].
  /// The animation value ranges from 0.0 (collapsed) to 1.0 (expanded).
  /// {@endtemplate}
  late final Animation<double> _animation;

  /// {@template _link_preview_builder_state_controller}
  /// The [AnimationController] for the expand transition.
  ///
  /// Duration is set to [widget.animationDuration] or 300ms as fallback.
  /// Controlled via [_animation] with an ease-out curve.
  /// {@endtemplate}
  late final AnimationController _controller;

  /// {@template _link_preview_builder_state_previewData}
  /// The most recently fetched preview data.
  ///
  /// Initially `null`. Set after a successful fetch. Passed to [widget.builder]
  /// on each rebuild. May be `null` if the fetch failed.
  /// {@endtemplate}
  LinkPreviewData? _previewData;

  /// {@template _link_preview_builder_state_initState}
  /// Initializes the animation controller and starts the first data fetch.
  ///
  /// Creates [_controller] with the configured duration and [_animation]
  /// with [Curves.easeOutQuad]. Then calls [_fetchData] with the initial [link].
  /// {@endtemplate}
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

  /// {@template _link_preview_builder_state_didUpdateWidget}
  /// Re-fetches preview data when the [link] changes.
  ///
  /// Compares the new [widget.link] with [oldWidget.link]. If they differ,
  /// a new fetch is triggered. Other property changes do not trigger a re-fetch.
  ///
  /// ### Parameters
  ///
  /// - `oldWidget`: The previous [LinkPreviewBuilder] configuration.
  /// {@endtemplate}
  @override
  void didUpdateWidget(covariant LinkPreviewBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.link != oldWidget.link) {
      _fetchData(widget.link);
    }
  }

  /// {@template _link_preview_builder_state_dispose}
  /// Cleans up the [AnimationController] to prevent memory leaks.
  ///
  /// Must be called to release the vsync ticker.
  /// {@endtemplate}
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// {@template _link_preview_builder_state_runAnimation}
  /// Determines whether the expand animation should run.
  ///
  /// Returns `true` only if [widget.enableAnimation] is `true` AND
  /// [shouldAnimate] is `true` (i.e., data has been fetched at least once).
  ///
  /// ### Return value
  ///
  /// Returns `true` when animation should play, `false` otherwise.
  /// {@endtemplate}
  bool get runAnimation => widget.enableAnimation == true && shouldAnimate;

  /// {@template _link_preview_builder_state_fetchData}
  /// Fetches preview data for the given [link] and updates the widget state.
  ///
  /// Sets [isFetchingPreviewData] to `true`, calls [LinkPreview.get],
  /// stores the result in [_previewData], triggers the animation, and
  /// delegates to [_handlePreviewDataFetched].
  ///
  /// ### Parameters
  ///
  /// - `link`: The URL to fetch metadata from.
  ///
  /// ### Edge cases
  ///
  /// - If the widget is unmounted before the fetch completes, no state updates occur.
  /// - If the fetch fails, `_previewData` may be `null`.
  /// {@endtemplate}
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

  /// {@template _link_preview_builder_state_handlePreviewDataFetched}
  /// Handles post-fetch logic: waits for the animation, invokes the callback, and clears loading state.
  ///
  /// Delays for [widget.animationDuration] (or 300ms), then calls
  /// [widget.onPreviewDataFetched] and sets [isFetchingPreviewData] to `false`.
  ///
  /// ### Parameters
  ///
  /// - `previewData`: The fetched [LinkPreviewData], or `null` on failure.
  ///
  /// ### Edge cases
  ///
  /// - If the widget is unmounted during the delay, no updates occur.
  /// - The callback is only invoked if the widget is still mounted.
  /// {@endtemplate}
  Future<void> _handlePreviewDataFetched(LinkPreviewData? previewData) async {
    await Future.delayed(widget.animationDuration ?? const Duration(milliseconds: 300));

    if (mounted) {
      widget.onPreviewDataFetched?.call(previewData);
      setState(() {
        isFetchingPreviewData = false;
      });
    }
  }

  /// {@template _link_preview_builder_state_defaultAnimated}
  /// Wraps the child widget in a default [SizeTransition] animation.
  ///
  /// Uses the vertical axis with top-left alignment. The [sizeFactor] is
  /// driven by [_animation], which expands from 0.0 to 1.0.
  ///
  /// ### Parameters
  ///
  /// - `child`: The widget to animate.
  ///
  /// ### Return value
  ///
  /// Returns a [SizeTransition] wrapping [child].
  /// {@endtemplate}
  Widget _defaultAnimated(Widget child) => SizeTransition(
    axis: Axis.vertical,
    alignment: AlignmentDirectional(-1, 0),
    sizeFactor: _animation,
    child: child,
  );

  /// {@template _link_preview_builder_state_build}
  /// Builds the widget tree based on the current state.
  ///
  /// Returns the [loadingBuilder] output during fetch, or the [builder] output
  /// with optional animation after fetch completes. The entire tree is wrapped
  /// in a [KeepAlive] to preserve state in scrollable parents.
  ///
  /// ### Return value
  ///
  /// Returns a [KeepAlive] widget containing the appropriate child.
  /// {@endtemplate}
  @override
  Widget build(BuildContext context) => KeepAlive(child: () {
    if (isFetchingPreviewData) {
      return widget.loadingBuilder != null ? widget.loadingBuilder!(context) : const SizedBox.shrink();
    }

    final child = widget.builder(context, _previewData);

    if (runAnimation) {
      return widget.animatedBuilder != null ? widget.animatedBuilder!(child, _animation) : _defaultAnimated(child);
    } else {
      return child;
    }
  }());
}

/// {@template keep_alive}
/// A wrapper widget that prevents its child from being disposed in scrollable parents.
///
/// Uses [AutomaticKeepAliveClientMixin] to signal to [KeepAliveNotification]
/// handlers that this widget should remain alive. This is useful when
/// [LinkPreviewBuilder] is used inside a [ListView] or [PageView] to
/// preserve fetched data across scrolls.
///
/// ### Example
///
/// ```dart
/// KeepAlive(
///   child: LinkPreviewBuilder(
///     link: 'https://example.com',
///     builder: (context, data) => Text(data?.title ?? ''),
///   ),
/// )
/// ```
///
/// ### Usage
///
/// This widget is used internally by [LinkPreviewBuilder] to wrap the
/// entire build output. You should not need to use it directly.
///
/// ### Edge cases
///
/// - If used outside a scrollable that respects [KeepAliveNotification],
///   this widget has no effect.
/// - The child is always rebuilt; this widget only affects disposal behavior.
/// {@endtemplate}
class KeepAlive extends StatefulWidget {
  /// {@template keep_alive_child}
  /// The widget to preserve in scrollable parents.
  ///
  /// This widget is wrapped in a [KeepAlive] notification handler to
  /// prevent disposal during scrolls.
  ///
  /// ### Parameters
  ///
  /// - Type: `Widget`
  /// - Required: Yes
  ///
  /// ### Examples
  ///
  /// ```dart
  /// KeepAlive(
  ///   child: LinkPreviewBuilder(
  ///     link: url,
  ///     builder: (context, data) => Text(data?.title ?? ''),
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  final Widget child;
  const KeepAlive({required this.child, super.key});

  @override
  State<KeepAlive> createState() => _KeepAliveWrapperState();
}

/// {@template _keep_alive_wrapper_state}
/// State for [KeepAlive] that implements [AutomaticKeepAliveClientMixin].
///
/// Returns `true` for [wantKeepAlive] to signal that this widget should
/// be preserved in scrollable parents.
/// {@endtemplate}
class _KeepAliveWrapperState extends State<KeepAlive> with AutomaticKeepAliveClientMixin {
  /// {@template _keep_alive_wrapper_state_wantKeepAlive}
  /// Whether this widget wants to stay alive.
  ///
  /// Always returns `true` to preserve the widget in scrollable parents.
  ///
  /// ### Return value
  ///
  /// Returns `true` unconditionally.
  /// {@endtemplate}
  @override
  bool get wantKeepAlive => true;

  /// {@template _keep_alive_wrapper_state_build}
  /// Builds the child widget and calls [super.build] to trigger keep-alive logic.
  ///
  /// ### Return value
  ///
  /// Returns the [widget.child] unchanged.
  /// {@endtemplate}
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}