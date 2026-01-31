import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'common/medium_type.dart';

part 'providers/album_thumbnail_provider.dart';
part 'providers/photo_provider.dart';
part 'providers/thumbnail_provider.dart';
part 'models/album.dart';
part 'models/media_page.dart';
part 'models/medium.dart';

/// {@template gallery}
/// A utility class to access the native device photo and video gallery through platform channels.
///
/// The [Gallery] class provides static methods for:
/// - Listing albums and their contents
/// - Fetching media files and metadata
/// - Accessing media thumbnails and album covers
/// - Deleting media and clearing cache
///
/// This utility abstracts the underlying platform-specific implementation
/// and makes it easier to access media data in a unified Dart interface.
///
/// ### Example usage:
/// ```dart
/// List<Album> albums = await Gallery.listAlbums(mediumType: MediumType.image);
///
/// if (albums.isNotEmpty) {
///   MediaPage mediaPage = await Gallery._listMedia(album: albums.first);
///   List<Medium> mediaItems = mediaPage.items;
///
///   for (var item in mediaItems) {
///     print("Media ID: ${item.id}");
///   }
/// }
/// ```
/// {@endtemplate}
class Gallery {
  /// {@macro gallery}
  const Gallery._();

  /// A [MethodChannel] used to communicate with the native gallery platform implementation.
  static const MethodChannel _channel = MethodChannel('smart_hap_gallery');

  /// Lists available albums on the device with optional filtering.
  ///
  /// - [mediumType] (default: `null`): Filter albums by media type (e.g., image, video).
  /// - [newest] (default: `true`): Sort albums by most recent items first.
  /// - [hideIfEmpty] (default: `true`): Hide albums that contain no media (iOS only).
  ///
  /// Returns a list of [Album] objects containing metadata and media count.
  static Future<List<Album>> listAlbums({MediumType? mediumType, bool newest = true, bool hideIfEmpty = true}) async {
    final json = await _channel.invokeMethod('listAlbums', {
      'mediumType': mediumTypeToJson(mediumType),
      'hideIfEmpty': hideIfEmpty,
    });

    return json.map<Album>((album) => Album.fromJson(album, mediumType, newest)).toList();
  }

  /// Lists paginated media items within a specified [album].
  ///
  /// - [album]: The album from which to list media.
  /// - [skip] (default: `null`): How many media items to skip (used for pagination).
  /// - [take] (default: `null`): How many media items to fetch.
  /// - [lightWeight] (default: `null`): If true, fetch minimal media metadata.
  ///
  /// Returns a [MediaPage] with a list of media and pagination details.
  static Future<MediaPage> _listMedia({required Album album, int? skip, int? take, bool? lightWeight}) async {
    final json = await _channel.invokeMethod('listMedia', {
      'albumId': album.id,
      'mediumType': mediumTypeToJson(album.mediumType),
      'newest': album.newest,
      'skip': skip,
      'take': take,
      'lightWeight': lightWeight,
    });

    return MediaPage.fromJson(album, json);
  }

  /// Fetches metadata for a specific medium using its [mediumId].
  ///
  /// - [mediumId]: The unique identifier of the media file.
  /// - [mediumType] (default: `null`): The type of media.
  ///
  /// Returns a [Medium] containing media metadata such as type, creation date, etc.
  static Future<Medium> getMedium({required String mediumId, MediumType? mediumType}) async {
    final json = await _channel.invokeMethod('getMedium', {
      'mediumId': mediumId,
      'mediumType': mediumTypeToJson(mediumType),
    });

    return Medium.fromJson(json);
  }

  /// Retrieves a thumbnail for the given media [mediumId].
  ///
  /// - [mediumId]: Unique identifier of the medium.
  /// - [mediumType] (default: `null`): Media type.
  /// - [width] (default: `null`): Desired thumbnail width.
  /// - [height] (default: `null`): Desired thumbnail height.
  /// - [highQuality] (default: `false`): Whether to request a higher quality thumbnail.
  ///
  /// Returns a list of bytes representing the thumbnail image.
  static Future<List<int>> getThumbnail({
    required String mediumId,
    MediumType? mediumType, // null
    int? width, // null
    int? height, // null
    bool? highQuality = false,
  }) async {
    final bytes = await _channel.invokeMethod('getThumbnail', {
      'mediumId': mediumId,
      'mediumType': mediumTypeToJson(mediumType),
      'width': width,
      'height': height,
      'highQuality': highQuality,
    });
    if (bytes == null) throw "Failed to fetch thumbnail of medium $mediumId";

    return List<int>.from(bytes);
  }

  /// Retrieves a thumbnail for the given album by [albumId].
  ///
  /// - [albumId]: Unique identifier of the album.
  /// - [mediumType] (default: `null`): Type of media to consider for the thumbnail.
  /// - [newest] (default: `true`): Whether to use the newest item in the album for the thumbnail.
  /// - [width] (default: `null`): Desired width of the thumbnail.
  /// - [height] (default: `null`): Desired height of the thumbnail.
  /// - [highQuality] (default: `false`): Whether to use a high quality thumbnail.
  ///
  /// Returns the thumbnail image as a byte list.
  static Future<List<int>> getAlbumThumbnail({
    required String albumId,
    MediumType? mediumType, // null
    bool newest = true,
    int? width, // null
    int? height, // null
    bool? highQuality = false,
  }) async {
    final bytes = await _channel.invokeMethod('getAlbumThumbnail', {
      'albumId': albumId,
      'mediumType': mediumTypeToJson(mediumType),
      'newest': newest,
      'width': width,
      'height': height,
      'highQuality': highQuality,
    });
    if (bytes == null) throw "Failed to fetch thumbnail of album $albumId";

    return List<int>.from(bytes);
  }

  /// Retrieves the full media file for the given [mediumId].
  ///
  /// - [mediumType] (default: `null`): Type of the media file.
  /// - [mimeType] (default: `null`): Optional MIME type hint.
  ///
  /// Returns a [File] pointing to the physical media on disk.
  static Future<File> getFile({
    required String mediumId,
    MediumType? mediumType, // null
    String? mimeType, // null
  }) async {
    final path = await _channel.invokeMethod('getFile', {
      'mediumId': mediumId,
      'mediumType': mediumTypeToJson(mediumType),
      'mimeType': mimeType,
    }) as String?;
    if (path == null) throw "Cannot get file $mediumId with type $mimeType";

    return File(path);
  }

  /// Deletes a specific media item from the device storage by its [mediumId].
  ///
  /// - [mediumType] (default: `null`): The type of media to delete.
  ///
  /// This action is irreversible.
  static Future<void> deleteMedium({required String mediumId, MediumType? mediumType}) async {
    await _channel.invokeMethod('deleteMedium', {
      'mediumId': mediumId,
      'mediumType': mediumTypeToJson(mediumType),
    });
  }

  /// Clears cached media and thumbnails stored by the native layer.
  ///
  /// Useful for freeing up memory or resetting the internal cache state.
  static Future<void> cleanCache() async {
    _channel.invokeMethod('cleanCache', {});
  }
}