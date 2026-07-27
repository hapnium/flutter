import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import 'medium_image.dart';

/// {@template album_list_view}
/// A vertical list view that displays media items from a single album
/// in a scrollable layout with selection support.
///
/// Each list row shows the media thumbnail via [MediumImage], the item's
/// filename, file size, and a type icon (video/image). When the item is
/// selected, a colored border and selection badge are displayed. Unlike
/// [AlbumGridView], the type icon is rendered inline next to the file
/// size rather than overlaid on the thumbnail.
///
/// When [AlbumViewConfiguration.mediumItemBuilder] is provided, it
/// completely replaces the default list tile, giving the caller full
/// control over media-item rendering.
/// {@endtemplate}
class AlbumListView extends StatelessWidget {
  /// The list of media items to display in the list.
  ///
  /// Each [Medium] provides an ID, filename, type, size, and thumbnail
  /// data. The list is typically produced by [Album.listMedia] and
  /// assigned to [_MultimediaGalleryAlbumState._mediums].
  final List<Medium> mediums;

  /// The list of IDs for currently selected media items.
  ///
  /// Used to determine whether each row should show a selection border
  /// and badge. Items whose ID appears in this list are rendered with
  /// [AlbumViewConfiguration.selectedColor] and a numbered badge.
  final List<String> selected;

  /// Callback invoked when a media item is tapped.
  ///
  /// In multi-select mode, this toggles the item's selection state. In
  /// single-select mode, this finalizes the selection and pops the stack.
  final MediumReceived onSelected;

  /// The configuration controlling list layout, styling, and selection.
  ///
  /// Provides item height, spacing, image styling, text styling,
  /// selection/unselected colors, separator, and optionally a custom
  /// [mediumItemBuilder].
  final AlbumViewConfiguration configuration;

  /// {@macro album_list_view}
  ///
  /// All parameters are required.
  const AlbumListView({
    super.key,
    required this.mediums,
    required this.onSelected,
    required this.selected,
    required this.configuration,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thickness: configuration.scrollThickness ?? 5.0,
      child: ListView.separated(
        padding: configuration.padding ?? EdgeInsets.all(6.0),
        itemCount: mediums.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) {
          return configuration.separator ?? SizedBox(height: 6);
        },
        itemBuilder: (context, index) {
          Medium medium = mediums[index];
          IconData icon = medium.mediumType == MediumType.video
              ? configuration.videoIcon ?? Icons.slow_motion_video_rounded
              : medium.mediumType == MediumType.image
              ? configuration.imageIcon ?? Icons.motion_photos_on_rounded
              : configuration.defaultIcon ?? Icons.browse_gallery_rounded;
          bool isSelected = selected.any((i) => i.equals(medium.id));
          int selectedIndex = selected.findIndex((i) => i.equals(medium.id));
          Color color = isSelected.isFalse ? Colors.teal : Colors.green;
          ImageProvider image = ThumbnailProvider(mediumId: medium.id, mediumType: medium.mediumType, highQuality: true);

          if(configuration.mediumItemBuilder.isNotNull) {
            return configuration.mediumItemBuilder!(context, medium, image, isSelected);
          }

          return SizedBox(
            height: configuration.itemHeight ?? 250,
            child: ClipRRect(
              borderRadius: configuration.itemBorderRadius ?? BorderRadius.circular(6),
              child: Material(
                shape: isSelected ? configuration.selectedShape ?? RoundedRectangleBorder(
                  side: BorderSide(color: color, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ) : configuration.unselectedShape,
                child: InkWell(
                  onTap: () => onSelected(medium),
                  child: Column(
                    spacing: configuration.itemSpacing ?? 0,
                    mainAxisSize: configuration.itemMainAxisSize ?? MainAxisSize.max,
                    mainAxisAlignment: configuration.itemMainAxisAlignment ?? MainAxisAlignment.start,
                    crossAxisAlignment: configuration.itemCrossAxisAlignment ?? CrossAxisAlignment.start,
                    children: [
                      Expanded(child: MediumImage(
                        image: image,
                        isSelected: isSelected,
                        selectedIndex: selectedIndex,
                        selectedIndicator: configuration.selectedIndicator,
                        imageHeight: configuration.imageHeight,
                        imageWidth: configuration.imageWidth,
                        imageFit: configuration.imageFit,
                        showIcon: false,
                        itemBackgroundColor: configuration.itemBackgroundColor,
                        itemWidth: configuration.itemWidth,
                        color: color,
                      )),
                      Padding(
                        padding: configuration.textPadding ?? EdgeInsets.all(8),
                        child: Column(
                          spacing: configuration.textSpacing ?? 0,
                          mainAxisSize: configuration.textMainAxisSize ?? MainAxisSize.max,
                          mainAxisAlignment: configuration.textMainAxisAlignment ?? MainAxisAlignment.start,
                          crossAxisAlignment: configuration.textCrossAxisAlignment ?? CrossAxisAlignment.start,
                          children: [
                            TextBuilder(
                              text: (medium.filename ?? medium.title ?? "Unnamed image").capitalizeEach,
                              size: configuration.titleSize ?? Sizing.font(14),
                              autoSize: false,
                              weight: configuration.titleWeight ?? FontWeight.bold,
                              color: configuration.titleColor ?? Theme.of(context).primaryColor,
                              flow: configuration.titleFlow ?? TextOverflow.ellipsis,
                            ),
                            Row(
                              spacing: configuration.fileSizeSpacing ?? 10,
                              mainAxisSize: configuration.fileSizeMainAxisSize ?? MainAxisSize.max,
                              mainAxisAlignment: configuration.fileSizeMainAxisAlignment ?? MainAxisAlignment.start,
                              crossAxisAlignment: configuration.fileSizeCrossAxisAlignment ?? CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextBuilder(
                                    text: (medium.size ?? 0).toFileSize,
                                    size: configuration.fileSize ?? Sizing.font(12),
                                    autoSize: false,
                                    color: configuration.fileSizeColor ?? Theme.of(context).primaryColor,
                                    flow: configuration.fileSizeFlow ?? TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(icon, size: configuration.iconSize ?? 20, color: color)
                              ],
                            ),
                          ],
                        ),
                      )
                    ]
                  ),
                ),
              ),
            )
          );
        }
      )
    );
  }
}