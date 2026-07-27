part of '../gallery.dart';

/// {@template photo_provider}
/// An [ImageProvider] that loads the full-resolution image
/// for a given media item in the gallery.
///
/// Typically used to render a photo after user selection.
///
/// ### Example usage:
/// ```dart
/// Image(
///   image: PhotoProvider(
///     mediumId: '67890',
///     mimeType: 'image/jpeg',
///   ),
/// )
/// ```
/// {@endtemplate}
class PhotoProvider extends ImageProvider<PhotoProvider> {
  /// The unique ID of the media item.
  final String mediumId;

  /// Optional MIME type of the image (e.g., `image/jpeg`).
  ///
  /// Default: `null`
  final String? mimeType;

  /// {@macro photo_provider}
  PhotoProvider({required this.mediumId, this.mimeType});

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

  Future<ui.Codec> _loadAsync(
    PhotoProvider key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);
    final file = await Gallery.getFile(
        mediumId: mediumId, mediumType: MediumType.image, mimeType: mimeType);
    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromFilePath(file.path);
    return decode(buffer);
  }

  @override
  Future<PhotoProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PhotoProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final typedOther = other as PhotoProvider;
    return mediumId == typedOther.mediumId;
  }

  @override
  int get hashCode => mediumId.hashCode;

  @override
  String toString() => '$runtimeType("$mediumId")';
}