part of '../gallery.dart';

/// {@template album_thumbnail_provider}
/// An [ImageProvider] that asynchronously loads a thumbnail representing an album.
///
/// This is usually derived from the newest item in the album.
///
/// ### Example usage:
/// ```dart
/// Image(
///   image: AlbumThumbnailProvider(
///     album: album,
///     width: 100,
///     height: 100,
///   ),
/// )
/// ```
/// {@endtemplate}
class AlbumThumbnailProvider extends ImageProvider<AlbumThumbnailProvider> {
  /// The [Album] whose thumbnail should be shown.
  final Album album;

  /// Desired height of the album thumbnail in pixels.
  ///
  /// Default: `null`
  final int? height;

  /// Desired width of the album thumbnail in pixels.
  ///
  /// Default: `null`
  final int? width;

  /// Whether to use a high-quality thumbnail.
  ///
  /// Default: `false`
  final bool? highQuality;

  /// {@macro album_thumbnail_provider}
  const AlbumThumbnailProvider({
    required this.album,
    this.height,
    this.width,
    this.highQuality = false,
  });

  @override
  ImageStreamCompleter loadImage(key, decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () sync* {
        yield ErrorDescription('Id: ${album.id}');
      },
    );
  }

  Future<ui.Codec> _loadAsync(AlbumThumbnailProvider key, ImageDecoderCallback decode) async {
    assert(key == this);
    late ui.ImmutableBuffer buffer;

    try {
      final data = await Gallery.getAlbumThumbnail(
        albumId: album.id,
        mediumType: album.mediumType,
        newest: album.newest,
        height: height,
        width: width,
        highQuality: highQuality,
      );
      buffer = await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(data));
    } catch (e) {
      buffer = await ui.ImmutableBuffer.fromAsset("packages/gallery/images/grey.bmp");
    }
    
    return decode(buffer);
  }

  @override
  Future<AlbumThumbnailProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AlbumThumbnailProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final typedOther = other as AlbumThumbnailProvider;
    return album.id == typedOther.album.id;
  }

  @override
  int get hashCode => album.id.hashCode;

  @override
  String toString() => '$runtimeType("${album.id}")';
}