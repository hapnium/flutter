import 'package:camera/camera.dart' show CameraDescription;
import 'package:flutter/material.dart' show BuildContext, ImageProvider, Widget;
import 'package:gallery/gallery.dart' show Album, Medium;

import 'models/selected_media.dart';

/// Callback for receiving a single selected media item.
typedef SelectedMediaReceived = Function(SelectedMedia media);

/// Callback for receiving a list of selected media items.
typedef SelectedMediaListReceived = Function(List<SelectedMedia> media, List<Medium> mediums);

/// Callback for receiving an informational message.
typedef OnInformationReceived = Function(String message);

/// Callback for receiving an error message.
typedef OnErrorReceived = Function(String error, bool useTip);

/// Callback for receiving updated camera descriptions.
typedef CameraDescriptionUpdated = Function(List<CameraDescription> cameras);

/// Callback for receiving a list of media items.
typedef MediumListReceived = void Function(List<Medium>);

/// Callback for receiving a single media item.
typedef MediumReceived = void Function(Medium);

/// Callback to build an album item.
typedef AlbumItemBuilder = Widget Function(BuildContext context, Album album, ImageProvider image);

/// Callback to build an medium item.
typedef MediumItemBuilder = Widget Function(BuildContext context, Medium medium, ImageProvider image, bool isSelected);

/// Callback to build an selected indicator.
typedef SelectedIndicator = Widget Function(int index);

/// Callback to notify when the layout changes.
typedef OnMultimediaLayoutChanged = void Function(bool isGrid);

/// Callback to notify when the grid count changes.
typedef OnMultimediaGridChanged = void Function(int count);