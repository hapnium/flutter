part of '../gallery.dart';

/// {@template thumbnail_provider}
/// An [ImageProvider] that asynchronously loads a thumbnail image
/// for a medium (photo or video) stored in the native gallery.
///
/// Useful for rendering previews in grid views or media pickers.
///
/// ### Example usage:
/// ```dart
/// Image(
///   image: ThumbnailProvider(
///     mediumId: '12345',
///     mediumType: MediumType.image,
///     width: 200,
///     height: 200,
///     highQuality: true,
///   ),
/// )
/// ```
/// {@endtemplate}
class ThumbnailProvider extends ImageProvider<ThumbnailProvider> {
  /// The unique ID of the media item in the gallery.
  ///
  /// Used to fetch the correct thumbnail.
  final String mediumId;

  /// The type of medium (image or video).
  ///
  /// Default: `null`
  final MediumType? mediumType;

  /// Desired height of the thumbnail in pixels.
  ///
  /// Default: `null`
  final int? height;

  /// Desired width of the thumbnail in pixels.
  ///
  /// Default: `null`
  final int? width;

  /// Whether to load a higher quality thumbnail.
  ///
  /// Default: `false`
  final bool? highQuality;

  /// {@macro thumbnail_provider}
  const ThumbnailProvider({
    required this.mediumId,
    this.mediumType,
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
        yield ErrorDescription('Id: $mediumId');
      },
    );
  }

  Future<ui.Codec> _loadAsync(ThumbnailProvider key, ImageDecoderCallback decode) async {
    assert(key == this);
    late ui.ImmutableBuffer buffer;
    
    try {
      final data = await Gallery.getThumbnail(
        mediumId: mediumId,
        mediumType: mediumType,
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
  Future<ThumbnailProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ThumbnailProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final typedOther = other as ThumbnailProvider;
    return mediumId == typedOther.mediumId;
  }

  @override
  int get hashCode => mediumId.hashCode;

  @override
  String toString() => '$runtimeType("$mediumId")';
}