import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import '../album/multimedia_gallery_album.dart';
import 'album_information.dart';

/// {@template gallery_list_view}
/// A scrollable list view that displays media albums as horizontal rows.
///
/// Each row shows the album's cover thumbnail on the left, the album
/// name and item count in the center, and an [AlbumInformation] badge
/// on the right. Tapping a row navigates to [MultimediaGalleryAlbum]
/// via the [Animated] page-route widget, providing a smooth transition
/// from the album list to the album detail view.
///
/// The list uses [ListView.separated] for consistent spacing between
/// rows, and wraps in a [Scrollbar] for visual feedback during scrolling.
/// When [GalleryViewConfiguration.albumItemBuilder] is provided, it
/// completely replaces the default row widget, giving the caller full
/// control over album rendering.
/// {@endtemplate}
class GalleryListView extends StatelessWidget {
  /// The parent route name used for constructing nested navigation routes.
  ///
  /// Each album's route is derived as `"$parentRoute/$albumRoute"` where
  /// `albumRoute` comes from [GalleryViewConfiguration.route] or defaults
  /// to `"?album=${album.id}"`.
  final String parentRoute;

  /// The list of albums to display in the scrollable list.
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

  /// The configuration controlling list layout, styling, and navigation.
  ///
  /// Provides padding, separator style, image dimensions, text styling,
  /// and optionally a custom [albumItemBuilder] to replace the default row.
  final GalleryViewConfiguration configuration;

  /// {@macro gallery_list_view}
  ///
  /// All parameters are required.
  const GalleryListView({
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
    return Scrollbar(
      thickness: configuration.scrollThickness ?? 5.0,
      child: ListView.separated(
        padding: configuration.padding ?? EdgeInsets.all(6.0),
        itemCount: albums.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) {
          return configuration.separator ?? SizedBox(height: 6);
        },
        itemBuilder: (context, index) {
          Album album = albums[index];
          String route = "$parentRoute/${configuration.route ?? "?album=${album.id}"}";
          ImageProvider image = AlbumThumbnailProvider(album: album, highQuality: true);

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
            closedElevation: 0,
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  color: configuration.imageBackgroundColor ?? Colors.grey[300],
                  height: configuration.imageHeight ?? 70,
                  width: configuration.imageWidth ?? 70,
                  child: FadeInImage(fit: configuration.imageFit ?? BoxFit.cover, placeholder: image, image: image),
                ),
                Expanded(
                  child: Column(
                    spacing: configuration.contentSpacing ?? 0,
                    mainAxisAlignment: configuration.contentMainAxisAlignment ?? MainAxisAlignment.start,
                    crossAxisAlignment: configuration.contentCrossAxisAlignment ?? CrossAxisAlignment.start,
                    children: [
                      TextBuilder(
                        text: (album.name ?? "Unnamed Album").capitalizeEach,
                        size: configuration.nameSize ?? Sizing.font(14),
                        autoSize: false,
                        weight: configuration.nameWeight ?? FontWeight.bold,
                        color: configuration.nameColor ?? Theme.of(context).primaryColor,
                        flow: configuration.nameOverflow ?? TextOverflow.ellipsis,
                      ),
                      TextBuilder(
                        text: "${album.count}",
                        size: configuration.countSize ?? Sizing.font(12),
                        autoSize: false,
                        color: configuration.countColor ?? Theme.of(context).primaryColor,
                        flow: configuration.countOverflow ?? TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AlbumInformation(
                  album: album,
                  newestColor: configuration.newestColor,
                  oldestColor: configuration.oldestColor,
                  infoColor: configuration.infoColor,
                  infoSize: configuration.infoSize,
                  infoPadding: configuration.infoPadding,
                  infoRadius: configuration.infoRadius
                ),
              ],
            ),
          );
        }
      )
    );
  }
}