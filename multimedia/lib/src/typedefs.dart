import 'package:camera/camera.dart' show CameraDescription;
import 'package:flutter/material.dart' show BuildContext, ImageProvider, Widget;
import 'package:gallery/gallery.dart' show Album, Medium;

import 'models/selected_media.dart';

/// Signature for a callback that receives a single selected media item.
///
/// Used when the user picks one photo or video from the media picker.
///
/// ```dart
/// MultimediaPicker(
///   onReceived: (media) {
///     print('Picked: ${media.file.path}');
///   },
/// );
/// ```
typedef SelectedMediaReceived = Function(SelectedMedia media);

/// Signature for a callback that receives a list of selected media items
/// alongside their raw [Medium] representations.
///
/// The [media] list contains the fully-processed [SelectedMedia] objects.
/// The [mediums] list contains the original gallery [Medium] entries in the
/// same order, useful when you need direct access to gallery metadata
/// (e.g., duration for videos, original asset identifiers).
///
/// ```dart
/// MultimediaPicker(
///   allowMultiple: true,
///   onListReceived: (media, mediums) {
///     for (final m in media) {
///       print(m.file.path);
///     }
///   },
/// );
/// ```
typedef SelectedMediaListReceived = Function(List<SelectedMedia> media, List<Medium> mediums);

/// Signature for a callback that delivers an informational message.
///
/// Unlike error messages, these are non-blocking and typically displayed
/// as tips, hints, or status updates to the user.
///
/// ```dart
/// MultimediaPicker(
///   onInformation: (message) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(message)),
///     );
///   },
/// );
/// ```
typedef OnInformationReceived = Function(String message);

/// Signature for a callback that delivers an error message.
///
/// The [useTip] flag indicates whether the message is a recoverable hint
/// (e.g., "No cameras found") versus a hard failure. UI code can use this
/// to decide between a toast and a dialog.
///
/// ```dart
/// MultimediaPicker(
///   onError: (error, useTip) {
///     if (useTip) {
///       showTipToast(error);
///     } else {
///       showErrorDialog(error);
///     }
///   },
/// );
/// ```
typedef OnErrorReceived = Function(String error, bool useTip);

/// Signature for a callback that receives updated camera descriptions.
///
/// Fired when the available camera list changes (e.g., a camera is
/// connected or disconnected at runtime). The picker UI uses this to
/// refresh its camera selector.
///
/// ```dart
/// MultimediaPicker(
///   onCamerasUpdated: (cameras) {
///     print('Available cameras: ${cameras.length}');
///   },
/// );
/// ```
typedef CameraDescriptionUpdated = Function(List<CameraDescription> cameras);

/// Signature for a callback that receives a list of [Medium] items.
///
/// Used internally by the gallery layer to push album contents
/// to the picker UI.
///
/// ```dart
/// GalleryProvider(
///   onMediumListReceived: (mediums) {
///     setState(() => _items = mediums);
///   },
/// );
/// ```
typedef MediumListReceived = void Function(List<Medium>);

/// Signature for a callback that receives a single [Medium] item.
///
/// Used when an individual medium is selected, loaded, or updated
/// within the gallery.
///
/// ```dart
/// GalleryProvider(
///   onMediumReceived: (medium) {
///     print('Selected: ${medium.title}');
///   },
/// );
/// ```
typedef MediumReceived = void Function(Medium);

/// Signature for a builder that constructs an album thumbnail widget.
///
/// The builder receives the current [BuildContext], the [album] data,
/// and an [image] provider for the album's cover photo. Return a widget
/// that renders the album cell in the picker grid.
///
/// ```dart
/// MultimediaPicker(
///   albumBuilder: (context, album, image) {
///     return Column(
///       children: [
///         Image(image: image),
///         Text(album.name),
///       ],
///     );
///   },
/// );
/// ```
typedef AlbumItemBuilder = Widget Function(BuildContext context, Album album, ImageProvider image);

/// Signature for a builder that constructs a media thumbnail widget.
///
/// The builder receives the current [BuildContext], the [medium] data,
/// an [image] provider for the thumbnail, and an [isSelected] flag
/// indicating whether the item is currently checked. Return a widget
/// that renders the media cell in the picker grid.
///
/// ```dart
/// MultimediaPicker(
///   mediumBuilder: (context, medium, image, isSelected) {
///     return Stack(
///       children: [
///         Image(image: image),
///         if (isSelected) Icon(Icons.check_circle),
///       ],
///     );
///   },
/// );
/// ```
typedef MediumItemBuilder = Widget Function(BuildContext context, Medium medium, ImageProvider image, bool isSelected);

/// Signature for a builder that constructs a selection-order indicator.
///
/// The [index] is the 0-based position of the selected item in the
/// selection list. Return a widget (typically a numbered badge) that
/// visualizes the selection order.
///
/// ```dart
/// MultimediaPicker(
///   selectedIndicatorBuilder: (index) {
///     return CircleAvatar(
///       child: Text('${index + 1}'),
///     );
///   },
/// );
/// ```
typedef SelectedIndicator = Widget Function(int index);

/// Signature for a callback that notifies when the layout mode changes.
///
/// Called when the user toggles between grid and list views. The
/// [isGrid] parameter is `true` when the layout switches to grid mode.
///
/// ```dart
/// MultimediaPicker(
///   onLayoutChanged: (isGrid) {
///     print(isGrid ? 'Switched to grid' : 'Switched to list');
///   },
/// );
/// ```
typedef OnMultimediaLayoutChanged = void Function(bool isGrid);

/// Signature for a callback that notifies when the grid column count changes.
///
/// Called when the user adjusts the number of columns in grid view.
/// The [count] parameter is the new column count.
///
/// ```dart
/// MultimediaPicker(
///   onGridCountChanged: (count) {
///     print('Grid columns: $count');
///   },
/// );
/// ```
typedef OnMultimediaGridChanged = void Function(int count);