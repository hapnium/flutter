/// {@template link_preview_library}
/// # link_preview Library
///
/// A comprehensive library for fetching, parsing, and displaying link preview metadata.
///
/// This package allows you to:
/// - Fetch preview metadata (title, description, image, etc.) from URLs.
/// - Customize caching behavior.
/// - Extend existing functionality with powerful extensions.
/// - Render preview widgets or linkified content easily in Flutter apps.
///
/// ## Key Features:
/// - **Preview Fetching**: Extract metadata for URLs using native or web-based logic.
/// - **Caching**: Configure custom cache layers to improve performance and offline support.
/// - **UI Components**: Easily render previews and linkified text widgets.
/// - **Extensibility**: Modular extensions on URLs, strings, and UI elements.
/// {@endtemplate}
library;

export 'src/link_preview.dart';

/// {@template link_preview_cache_exports}
/// # Cache
/// Core APIs and interfaces related to preview caching.
///
/// Allows you to extend or replace caching behavior via [CacheManager].
/// {@endtemplate}
export 'src/cache/cache_manager.dart';

/// {@template link_preview_extensions_exports}
/// # Extensions
/// Helpful extensions to enhance string, URL, UI, and caching operations.
///
/// - [cache_extension.dart]: Extends types with preview caching methods.
/// - [url_extension.dart]: Extends strings and URIs for URL-related utilities.
/// - [ui_extension.dart]: Adds preview-aware functionality to Flutter UI.
/// - [linkifier_extension.dart]: Transforms text with linkifiable behavior.
/// - [url_launcher_extension.dart]: Easily open URLs with fallback behavior.
/// {@endtemplate}
export 'src/extensions/cache_extension.dart';
export 'src/extensions/url_extension.dart';
export 'src/extensions/ui_extension.dart';
export 'src/extensions/linkifier_extension.dart';
export 'src/extensions/url_launcher_extension.dart';

/// {@template link_preview_models_exports}
/// # Models
/// Data models used to represent parsed link metadata.
///
/// Includes:
/// - [LinkPreviewData]: Holds full preview metadata.
/// - [LinkPreviewImage]: Represents preview images with dimensions and URLs.
/// {@endtemplate}
export 'src/models/link_preview_data.dart' show LinkPreviewData;
export 'src/models/link_preview_image.dart';

/// {@template link_preview_ui_exports}
/// # UI Components
/// Flutter widgets for rendering previews or linkified content.
///
/// - [linkify.dart]: A linkify widget that parses text and makes URLs tappable.
/// {@endtemplate}
export 'src/ui/linkify.dart';

/// {@template link_preview_third_party_exports}
/// # Third-Party Re-exports
/// Useful types from the `linkify` package exposed for convenience.
///
/// These include:
/// - [LinkifyOptions]
/// - [LinkifyElement]
/// - [LinkableElement]
/// - [Linkifier]
/// {@endtemplate}
export 'package:linkify/linkify.dart' show LinkifyOptions, LinkifyElement, LinkableElement, Linkifier;