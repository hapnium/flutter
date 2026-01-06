/// {@template gallery}
/// A Flutter-compatible library to interact with the native device gallery.
///
/// The `gallery` package provides tools to list, access, and manage image and video files
/// from the device's native media store (camera roll, albums, etc.). It abstracts away
/// platform-specific details using Flutter's platform channels, offering a unified API
/// for working with photo and video content.
///
/// ### Key Features:
/// - Fetch albums filtered by media type (image/video)
/// - List paginated media items (with optional lightweight metadata)
/// - Retrieve thumbnails for both albums and media
/// - Access full media file paths for image/video playback or manipulation
/// - Delete media items and clean platform cache
///
/// ### Example:
/// ```dart
/// import 'package:gallery/gallery.dart';
///
/// Future<void> loadGallery() async {
///   final albums = await Gallery.listAlbums(mediumType: MediumType.image);
///   if (albums.isNotEmpty) {
///     final mediaPage = await Gallery._listMedia(album: albums.first);
///     for (final medium in mediaPage.items) {
///       print("Media ID: ${medium.id}");
///     }
///   }
/// }
/// ```
///
/// > Note: Some methods may behave differently across platforms. Ensure permissions are handled properly on Android and iOS.
/// {@endtemplate}
library;

/// Exposes the [MediumType] enum and related utilities for describing types of media.
///
/// Use [MediumType.image] or [MediumType.video] to filter API results based on content type.
export 'src/common/medium_type.dart';

/// Core class and methods for interacting with the gallery.
///
/// This includes the [Gallery] class, which provides static methods for fetching albums,
/// listing media items, generating thumbnails, deleting files, and managing cache.
export 'src/gallery.dart';