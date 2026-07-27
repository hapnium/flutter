part of '../gallery.dart';

/// {@template medium}
/// Represents a single media item (photo or video) in the gallery.
///
/// It contains metadata like ID, dimensions, orientation, creation date, and more.
/// Provides utility methods for retrieving the thumbnail or original file.
///
/// ### Example usage:
/// ```dart
/// final medium = await Gallery.getMedium(mediumId: 'abc123');
///
/// final thumb = await medium.getThumbnail(width: 100, height: 100);
/// final file = await medium.getFile();
/// ```
/// {@endtemplate}
@immutable
class Medium {
  /// Unique identifier for the medium in the gallery.
  final String id;

  /// File name of the medium.
  ///
  /// Default: `null`
  final String? filename;

  /// Title metadata of the medium.
  ///
  /// Default: `null`
  final String? title;

  /// Type of media (image or video).
  ///
  /// Default: `null`
  final MediumType? mediumType;

  /// Width in pixels.
  ///
  /// Default: `null`
  final int? width;

  /// Height in pixels.
  ///
  /// Default: `null`
  final int? height;

  /// File size in bytes.
  ///
  /// Default: `null`
  final int? size;

  /// Orientation of the media.
  ///
  /// Default: `null`
  final int? orientation;

  /// MIME type (e.g., image/jpeg).
  ///
  /// Default: `null`
  final String? mimeType;

  /// Duration in milliseconds for videos.
  ///
  /// Default: `0`
  final int duration;

  /// When the media was created.
  ///
  /// Default: `null`
  final DateTime? creationDate;

  /// When the media was last modified.
  ///
  /// Default: `null`
  final DateTime? modifiedDate;

  /// {@macro medium}
  Medium.fromJson(dynamic json)
      : id = json["id"],
        filename = json["filename"],
        title = json["title"],
        mediumType = jsonToMediumType(json["mediumType"]),
        width = json["width"],
        height = json["height"],
        size = json["size"],
        orientation = json["orientation"],
        mimeType = json["mimeType"],
        duration = json['duration'] ?? 0,
        creationDate = json['creationDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['creationDate'])
            : null,
        modifiedDate = json['modifiedDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['modifiedDate'])
            : null;

  /// Get a JPEG thumbnail's data for this medium.
  /// 
  /// {@macro medium}
  Future<List<int>> getThumbnail({int? width, int? height, bool? highQuality = false}) {
    return Gallery.getThumbnail(
      mediumId: id,
      width: width,
      height: height,
      mediumType: mediumType,
      highQuality: highQuality,
    );
  }

  /// Get the original file.
  /// 
  /// {@macro medium}
  Future<File> getFile() {
    return Gallery.getFile(
      mediumId: id,
      mediumType: mediumType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medium &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filename == other.filename &&
          title == other.title &&
          mediumType == other.mediumType &&
          width == other.width &&
          height == other.height &&
          orientation == other.orientation &&
          mimeType == other.mimeType &&
          creationDate == other.creationDate &&
          modifiedDate == other.modifiedDate;

  @override
  int get hashCode =>
      id.hashCode ^
      filename.hashCode ^
      title.hashCode ^
      mediumType.hashCode ^
      width.hashCode ^
      height.hashCode ^
      orientation.hashCode ^
      mimeType.hashCode ^
      creationDate.hashCode ^
      modifiedDate.hashCode;

  @override
  String toString() {
    return 'Medium{id: $id, '
        'filename: $filename, '
        'title: $title, '
        'mediumType: $mediumType, '
        'width: $width, '
        'height: $height, '
        'orientation: $orientation, '
        'mimeType: $mimeType, '
        'creationDate: $creationDate, '
        'modifiedDate: $modifiedDate}';
  }
}