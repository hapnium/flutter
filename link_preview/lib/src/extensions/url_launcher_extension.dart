import 'package:url_launcher/url_launcher.dart';

import '../link_preview_interface.dart';

/// {@template url_launcher_extension}
/// Extension that provides common URL launching methods for [LinkPreviewInterface].
///
/// This extension offers methods to open URLs in external browsers,
/// in-app web views, or new browser tabs. It handles URL parsing and
/// checks if the URL can be launched before attempting to open it.
///
/// ### Common actions
///
/// - Open in browser: `linkPreview.launch(url)`
/// - Open in-app: `linkPreview.launchInApp(url)`
/// - Open in new tab: `linkPreview.launchInBrowserTab(url)`
///
/// ### Edge cases
///
/// - All methods are silent no-ops if the URL cannot be launched
/// - URL parsing uses [Uri.parse] — malformed URLs are handled gracefully
/// - Platform-specific behavior varies (e.g., web vs mobile)
///
/// ### Usage
///
/// ```dart
/// // Open URL in external browser
/// await linkPreview.launch('https://example.com');
///
/// // Open URL in in-app web view
/// await linkPreview.launchInApp('https://example.com');
/// ```
/// {@endtemplate}
extension UrlLauncherExtension on LinkPreviewInterface {
  /// {@template url_launcher_extension_launch}
  /// Launches the given [url] in the external application (e.g., browser).
  ///
  /// Parses the URL and checks if it can be launched. If successful,
  /// opens the URL in the platform's default external application.
  /// On mobile, this typically opens the default browser. On web,
  /// this opens a new browser tab.
  ///
  /// ### Parameters
  ///
  /// - [url]: The URL string to launch. Must be a valid URL format.
  ///
  /// ### Return value
  ///
  /// Returns a [Future<void>] that completes when the URL has been launched
  /// or if the URL cannot be launched (silent failure).
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Open a website in the default browser
  /// linkPreview.launch('https://example.com');
  /// ```
  ///
  /// ```dart
  /// // Open a phone dialer
  /// linkPreview.launch('tel:+15551234567');
  /// ```
  ///
  /// ```dart
  /// // Open email client
  /// linkPreview.launch('mailto:test@example.com');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Open external links from link previews
  /// - Launch deep links (tel:, mailto:, sms:)
  /// - Open app store links
  ///
  /// ### Edge cases
  ///
  /// - Silently does nothing if the URL cannot be launched
  /// - Does not throw exceptions on launch failure
  /// - Platform-specific behavior: iOS may show confirmation dialog
  /// - Web platform opens in new browser tab
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // In a GestureDetector for link preview taps
  /// GestureDetector(
  ///   onTap: () => linkPreview.launch(url),
  ///   child: LinkPreviewWidget(data: previewData),
  /// );
  /// ```
  /// {@endtemplate}
  Future<void> launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// {@template url_launcher_extension_launch_in_app}
  /// Launches the given [url] in an in-app web view.
  ///
  /// Parses the URL and checks if it can be launched. If successful,
  /// opens the URL in an in-app web view component. This keeps the
  /// user within the app while browsing the linked content.
  ///
  /// ### Parameters
  ///
  /// - [url]: The URL string to launch. Must be a valid URL format.
  ///
  /// ### Return value
  ///
  /// Returns a [Future<void>] that completes when the URL has been launched
  /// or if the URL cannot be launched (silent failure).
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Open link preview URL in-app without leaving the app
  /// linkPreview.launchInApp('https://example.com');
  /// ```
  ///
  /// ### Common actions
  ///   - Keep users within the app while browsing linked content
  ///   - Open link preview URLs in a controlled web view
  ///   - Provide a seamless browsing experience
  ///
  /// ### Edge cases
  ///
  /// - Silently does nothing if the URL cannot be launched
  /// - Does not throw exceptions on launch failure
  /// - In-app web view may have limited JavaScript support
  /// - Some URLs may force external launch (e.g., app deep links)
  /// - Platform-specific: Android may use Chrome Custom Tabs
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Open link preview in-app for better UX
  /// linkPreview.launchInApp(previewData.url);
  /// ```
  /// {@endtemplate}
  Future<void> launchInApp(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  /// {@template url_launcher_extension_launch_in_browser_tab}
  /// Launches the given [url] in a new browser tab (for web).
  ///
  /// Parses the URL and checks if it can be launched. If successful,
  /// opens the URL using the platform's default behavior, which typically
  /// opens in a new browser tab on web platforms. On mobile, this behaves
  /// similarly to [launch].
  ///
  /// ### Parameters
  ///
  /// - [url]: The URL string to launch. Must be a valid URL format.
  ///
  /// ### Return value
  ///
  /// Returns a [Future<void>] that completes when the URL has been launched
  /// or if the URL cannot be launched (silent failure).
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Open link in new browser tab (web)
  /// linkPreview.launchInBrowserTab('https://example.com');
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Open links in new tabs on web platforms
  /// - Preserve app state while browsing external content
  ///
  /// ### Edge cases
  ///
  /// - Silently does nothing if the URL cannot be launched
  /// - Does not throw exceptions on launch failure
  /// - On mobile, behavior is similar to [launch] (opens default browser)
  /// - Platform-specific: web opens new tab, mobile opens external browser
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Web-specific: open in new tab
  /// linkPreview.launchInBrowserTab(previewData.url);
  /// ```
  /// {@endtemplate}
  Future<void> launchInBrowserTab(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}