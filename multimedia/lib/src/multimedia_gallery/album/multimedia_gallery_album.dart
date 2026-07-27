import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import '../widgets/not_item_found.dart';
import 'widgets/album_grid_view.dart';
import 'widgets/album_list_view.dart';

part 'multimedia_gallery_album_state.dart';

/// {@template multimedia_gallery_album}
/// A widget that displays all media items from a single album, supporting
/// grid/list toggle, media selection, and configurable grid density.
///
/// This is the detail view navigated to when the user taps an album in
/// [GalleryGridView] or [GalleryListView]. It fetches all [Medium] items
/// from the provided [Album], renders them in either [AlbumGridView] or
/// [AlbumListView], and manages the selection state. When multiple
/// selection is enabled, a "Done" button appears in the app bar that
/// finalizes the selection and returns the result.
///
/// Grid density is controlled by filter buttons (e.g., "2x", "3x")
/// rendered in a [Wrap] below the app bar. The user can switch between
/// grid and list layouts using the app bar action button. Selection
/// respects [maxSelection] and [MultimediaGalleryAlbumConfiguration.maxSize] /
/// [minSize] constraints, rejecting items that fall outside the allowed
/// size range.
/// {@endtemplate}
class MultimediaGalleryAlbum extends StatefulWidget {
  /// The parent route name used for constructing nested navigation routes.
  ///
  /// Passed down to child views so that route names can be composed
  /// hierarchically (e.g., "/gallery/My Photos/12345").
  final String parentRoute;

  /// The album whose media items to display.
  ///
  /// Provides the album name, ID, cover thumbnail, media count, and the
  /// [Album.listMedia] method used to fetch all items in the album.
  final Album album;

  /// Whether the user can select multiple media items.
  ///
  /// When `true`, tapping a medium toggles its selection state and a
  /// "Done" button appears in the app bar. When `false`, tapping a
  /// medium immediately finalizes the selection and pops.
  final bool multipleAllowed;

  /// Callback invoked when media items are selected.
  ///
  /// Receives the list of selected [Medium] items. When `null`, the
  /// selected items are returned via [Navigator.pop] instead. This
  /// allows the widget to work both as a callback-driven component
  /// and as a navigation-based component.
  final MediumListReceived? onMediumReceived;

  /// Optional maximum number of media items the user can select.
  ///
  /// When `null`, selection is unlimited. When set, the "Done" button
  /// only appears after at least one item is selected, and further
  /// selections are disabled once the cap is reached.
  final int? maxSelection;

  /// Configuration object for customizing the album screen's appearance
  /// and behavior.
  ///
  /// Controls app bar styling, grid density options, filter visibility,
  /// layout toggle icons, done-button styling, and empty/loading states.
  final MultimediaGalleryAlbumConfiguration configuration;

  /// {@macro multimedia_gallery_album}
  ///
  /// All parameters are required.
  const MultimediaGalleryAlbum({
    super.key,
    required this.album,
    required this.maxSelection,
    required this.onMediumReceived,
    required this.multipleAllowed,
    required this.configuration,
    required this.parentRoute
  });

  @override
  State<MultimediaGalleryAlbum> createState() => _MultimediaGalleryAlbumState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('onMediumReceived', onMediumReceived));
    properties.add(DiagnosticsProperty('album', album));
    properties.add(StringProperty('album_id', album.id));
    properties.add(StringProperty('album_name', album.name));
    properties.add(DiagnosticsProperty('album_newest', album.newest));
    properties.add(EnumProperty('album_medium_type', album.mediumType));
    properties.add(IntProperty('album_count', album.count));
    properties.add(StringProperty('album_view', album.toString()));
    properties.add(IntProperty('max_selection', maxSelection));
    properties.add(DiagnosticsProperty('multiple_allowed', multipleAllowed));
    properties.add(DiagnosticsProperty('pop_all_while_going_back', configuration.popAllWhileGoingBack));
    properties.add(DiagnosticsProperty('configuration', configuration));
    properties.add(DiagnosticsProperty('icon_configuration', configuration.iconConfiguration));
    properties.add(DiagnosticsProperty('layout_configuration', configuration.layoutConfiguration));
    properties.add(DiagnosticsProperty('done_button_configuration', configuration.doneButtonConfiguration));
    properties.add(DiagnosticsProperty('grid_filter_configuration', configuration.gridFilterConfiguration));
    properties.add(DiagnosticsProperty('no_item_configuration', configuration.noItemConfiguration));
    properties.add(DiagnosticsProperty('show_filters', configuration.showFilters));
    properties.add(DiagnosticsProperty('grids', configuration.grids));
    properties.add(DiagnosticsProperty('title_widget', configuration.titleWidget));

    if(configuration.title != null) {
      properties.add(StringProperty('title', configuration.title!));
    }

    properties.add(DiagnosticsProperty('title_size', configuration.titleSize));
    properties.add(DiagnosticsProperty('title_weight', configuration.titleWeight));
    properties.add(DiagnosticsProperty('title_color', configuration.titleColor));
    properties.add(DiagnosticsProperty('app_bar_elevation', configuration.appBarElevation));
    properties.add(DiagnosticsProperty('grid_view_spacing', configuration.gridViewSpacing));
    properties.add(DiagnosticsProperty('grid_view_main_alignment', configuration.gridViewMainAlignment));
    properties.add(DiagnosticsProperty('grid_view_main_axis_size', configuration.gridViewMainAxisSize));
    properties.add(DiagnosticsProperty('grid_view_cross_alignment', configuration.gridViewCrossAlignment));
    properties.add(DiagnosticsProperty('loading_builder', configuration.loadingBuilder));
    properties.add(DiagnosticsProperty('empty_builder', configuration.emptyBuilder));
    properties.add(DiagnosticsProperty('on_grid_changed', configuration.onGridChanged));
    properties.add(DiagnosticsProperty('on_layout_changed', configuration.onLayoutChanged));
    properties.add(DiagnosticsProperty('loading_color', configuration.loadingColor));
    properties.add(StringProperty('parent_route', parentRoute));
  }
}