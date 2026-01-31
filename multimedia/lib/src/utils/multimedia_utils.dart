import 'package:file_picker/file_picker.dart' show FilePickerResult, FileType, FilePicker, PlatformFile;
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

/// {@template multimedia_utils}
/// A utility class that provides helper methods for media selection from the file system.
///
/// This class simplifies picking media files using `file_picker`, allowing easy configuration
/// for image-only, video-only, or both types. It also supports error handling and media processing
/// into [SelectedMedia] models for downstream use.
///
/// ### Example usage:
/// ```dart
/// List<SelectedMedia> media = await MultimediaUtils.pickFromFile(
///   onlyPhoto: true,
///   multipleAllowed: true,
///   title: "Select Images",
///   handleSelected: (selected) {
///     print("User selected ${selected.length} items.");
///   },
///   onError: (message, isCritical) {
///     print("Error: $message");
///   },
/// );
/// ```
/// {@endtemplate}
class MultimediaUtils {
  /// {@macro multimedia_utils}
  const MultimediaUtils._();

  /// Picks media files (photos/videos) from the user's file system using a file picker dialog.
  ///
  /// This method processes selected files into [SelectedMedia] instances and supports
  /// customizable behavior for selection type, multiple files, and error handling.
  ///
  /// - [onError] (default: null): A callback to handle errors that occur during file picking.
  /// - [onlyVideo] (default: `false`): Restricts selection to video files only.
  /// - [onlyPhoto] (default: `true`): Restricts selection to image files only.
  /// - [title] (default: `""`): Title shown in the file picker dialog.
  /// - [handleSelected] (default: null): Callback triggered after successful file selection.
  /// - [multipleAllowed] (default: `false`): Whether to allow selection of multiple files.
  /// - [maxSize] (default null): Maximum file size for displayed media.
  /// - [minSize] (default null): Minimum file size for displayed media.
  ///
  /// Returns a [Future] that resolves with a [List] of [SelectedMedia], or an empty list on error or cancelation.
  static Future<List<SelectedMedia>> pickFromFile({
    OnErrorReceived? onError, // null
    bool onlyVideo = false,
    bool onlyPhoto = true,
    String title = "",
    SelectedMediaListReceived? handleSelected, // null
    bool multipleAllowed = false,
    int? maxSize,
    int? minSize
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: onlyVideo ? FileType.video : onlyPhoto ? FileType.image : FileType.media,
        allowMultiple: multipleAllowed,
        dialogTitle: title,
      );

      List<PlatformFile> files = result?.files ?? [];

      if (files.isNotEmpty) {
        if(maxSize != null && files.any((file) => file.size.isGreaterThan(maxSize))) {
          onError?.call("Some assets exceeds the maximum desired size ${maxSize.toFileSize}", false);
          return [];
        }

        if(minSize != null && files.any((file) => file.size.isLessThan(minSize))) {
          onError?.call("Some assets goes below the desired minimum size ${minSize.toFileSize}", false);
          return [];
        }

        if (files.all((file) => (file.path ?? file.name).isImage || (file.path ?? file.name).isVideo)) {
          List<SelectedMedia> response = files.map((file) {
            String path = file.path ?? file.name;

            return SelectedMedia(
              path: path,
              data: file.bytes,
              size: file.size.toFileSize,
              media: path.isVideo ? MediaType.video : MediaType.photo,
            );
          }).toList();

          if (handleSelected.isNotNull) {
            handleSelected!(response, []);
          }

          return response;
        }

        if (onError.isNotNull) {
          onError!("Unsupported file format detected. Only images or videos are allowed", true);
        }
      }
    } catch (e) {
      if (onError.isNotNull) {
        onError!("Unsupported file format.", true);
      }
    }

    return [];
  }
}