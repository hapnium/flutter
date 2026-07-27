import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import '../album/multimedia_gallery_album.dart';
import 'album_information.dart';

/// {@template gallery_grid_view}
/// A responsive grid view that displays media albums in a tiled layout.
///
/// Each grid cell shows the album's cover thumbnail, name, item count,
/// and an [AlbumInformation] badge indicating recency. Tapping a cell
/// navigates to [MultimediaGalleryAlbum] via the [Animated] page-route
/// widget, which provides a shared-axis transition between the album
/// list and album detail views.
///
/// The grid adapts to screen width using [LayoutBuilder]: the number of
/// columns is controlled by [GalleryViewConfiguration.displayCount]
/// (default `2`), and each cell's aspect ratio is computed from the
/// available width. When [GalleryViewConfiguration.albumItemBuilder] is
/// provided, it completely replaces the default cell widget, giving the
/// caller full control over album rendering.
/// {@endtemplate}
class GalleryGridView extends StatelessWidget {
  /// The parent route name used for constructing nested navigation routes.
  ///
  /// Each album's route is derived as `"$parentRoute/$albumRoute"` where
  /// `albumRoute` comes from [GalleryViewConfiguration.route] or defaults
  /// to `"?album=${album.id}"`.
  final String parentRoute;

  /// The list of albums to display in the grid.
  ///
  /// Each [Album] provides a name, cover thumbnail, media count, and
  /// recency flag. The list is typically produced by
  /// [_MultimediaGalleryState._fetchAlbums].
  final List<Album> albums;

  /// Whether the user can select multiple media items within each album.
  ///
  /// Passed through to [MultimediaGalleryAlbum] when navigating into
  /// an album. When `true`, the album view shows a "Done" button and
  /// allows toggling individual media selections.
  final bool multipleAllowed;

  /// Callback invoked when the user finalizes their media selection.
  ///
  /// Receives the list of selected [Medium] items from the album view.
  /// This callback is forwarded to [MultimediaGalleryAlbum] and
  /// ultimately to [_MultimediaGalleryState._handleSelectedMedium].
  final MediumListReceived onSelected;

  /// Optional maximum number of media items the user can select.
  ///
  /// When `null`, selection is unlimited (subject to the device's
  /// storage). When set, the album view enforces the cap and disables
  /// further selections once reached.
  final int? maxSelection;

  /// The configuration controlling grid layout, styling, and navigation.
  ///
  /// Provides display count, aspect ratio, spacing, image styling, and
  /// optionally a custom [albumItemBuilder] to replace the default cell.
  final GalleryViewConfiguration configuration;

  /// {@macro gallery_grid_view}
  ///
  /// All parameters are required.
  const GalleryGridView({
    super.key,
    required this.albums,
    required this.onSelected,
    required this.maxSelection,
    required this.multipleAllowed,
    required this.configuration,
    required this.parentRoute
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: configuration.padding ?? const EdgeInsets.all(4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int count = configuration.displayCount ?? 2;
          double gridWidth = configuration.width ?? (constraints.maxWidth - 20) / count;

          return Scrollbar(
            thickness: configuration.scrollThickness ?? 5.0,
            child: GridView.builder(
              padding: configuration.padding ?? const EdgeInsets.all(12.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: configuration.ratio ?? gridWidth / (gridWidth + 50),
                crossAxisCount: count,
                mainAxisSpacing: configuration.mainAxisSpacing ?? 10.0,
                crossAxisSpacing: configuration.crossAxisSpacing ?? 10.0,
              ),
              itemCount: albums.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                Album album = albums[index];
                ImageProvider image = AlbumThumbnailProvider(album: album, highQuality: true);
                String route = "$parentRoute/${configuration.route ?? "?album=${album.id}"}";

                if(configuration.albumItemBuilder.isNotNull) {
                  return configuration.albumItemBuilder!(context, album, image);
                }

                return Animated(
                  toWidget: MultimediaGalleryAlbum(
                    album: album,
                    onMediumReceived: onSelected,
                    multipleAllowed: multipleAllowed,
                    maxSelection: maxSelection,
                    configuration: configuration.albumConfiguration,
                    parentRoute: route
                  ),
                  borderRadius: configuration.borderRadius ?? BorderRadius.circular(12),
                  route: route,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          color: configuration.imageBackgroundColor ?? Colors.grey[300],
                          width: gridWidth,
                          child: FadeInImage(fit: configuration.imageFit ?? BoxFit.cover, placeholder: image, image: image),
                        ),
                      ),
                      Padding(
                        padding: configuration.contentPadding ?? const EdgeInsets.all(8.0),
                        child: Column(
                          spacing: configuration.contentSpacing ?? 2,
                          mainAxisAlignment: configuration.contentMainAxisAlignment ?? MainAxisAlignment.start,
                          crossAxisAlignment: configuration.contentCrossAxisAlignment ?? CrossAxisAlignment.start,
                          children: [
                            AlbumInformation(
                              album: album,
                              newestColor: configuration.newestColor,
                              oldestColor: configuration.oldestColor,
                              infoColor: configuration.infoColor,
                              infoSize: configuration.infoSize,
                              infoPadding: configuration.infoPadding,
                              infoRadius: configuration.infoRadius
                            ),
                            TextBuilder(
                              text: "(${album.count}) ${(album.name ?? "Unnamed Album").capitalizeEach}",
                              size: configuration.nameSize ?? 14,
                              autoSize: false,
                              weight: configuration.nameWeight ?? FontWeight.bold,
                              color: configuration.nameColor ?? Theme.of(context).primaryColor,
                              flow: TextOverflow.ellipsis,
                            ),
                          ]
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          );
        }
      )
    );
  }
}