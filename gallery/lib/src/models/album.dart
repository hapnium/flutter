part of '../gallery.dart';

/// {@template album}
/// Represents a media album in the device's gallery.
///
/// Albums can contain images or videos, depending on their [mediumType].
/// Provides helper methods to fetch media entries or a thumbnail preview.
///
/// ### Example usage:
/// ```dart
/// final album = Album.fromJson(json, MediumType.image, true);
/// final mediaPage = await album.listMedia(skip: 0, take: 50);
/// final thumbnail = await album.getThumbnail(width: 200, height: 200);
/// ```
/// {@endtemplate}
@immutable
class Album {
  /// A unique identifier for the album.
  ///
  /// Used internally to fetch album content.
  final String id;

  /// The type of media the album holds (e.g., image, video).
  ///
  /// Default: `null`
  final MediumType? mediumType;

  /// Whether the album is sorted by newest items first.
  ///
  /// Default: `null`
  final bool newest;

  /// The name/title of the album as displayed in the UI.
  ///
  /// Default: `null`
  final String? name;

  /// Total number of media items in this album.
  ///
  /// Default: `0`
  final int count;

  /// Returns `true` if this album represents all media entries.
  bool get isAllAlbum => id == "__ALL__";

  /// {@macro album}
  Album.fromJson(dynamic json, this.mediumType, this.newest)
      : id = json['id'],
        name = json['name'],
        count = json['count'] ?? 0;

  /// Retrieves a page of media items in the album.
  ///
  /// Pagination can be controlled using [skip] (offset) and [take] (limit).
  /// Optionally uses a lightweight fetch mode via [lightWeight].
  Future<MediaPage> listMedia({int? skip, int? take, bool? lightWeight}) {
    return Gallery._listMedia(
      album: this,
      skip: skip,
      take: take,
      lightWeight: lightWeight,
    );
  }

  /// Fetches thumbnail data representing this album.
  ///
  /// Displays the most recent medium's thumbnail in the album.
  /// Useful for preview purposes in album grids or lists.
  Future<List<int>> getThumbnail({int? width, int? height, bool? highQuality = false}) {
    return Gallery.getAlbumThumbnail(
      albumId: id,
      mediumType: mediumType,
      width: width,
      height: height,
      highQuality: highQuality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mediumType == other.mediumType &&
          name == other.name &&
          count == other.count;

  @override
  int get hashCode =>
      id.hashCode ^ mediumType.hashCode ^ name.hashCode ^ count.hashCode;

  @override
  String toString() {
    return 'Album{id: $id, '
        'mediumType: $mediumType, '
        'name: $name, '
        'count: $count}';
  }
}