import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import 'medium_image.dart';

/// {@template album_grid_view}
/// A customizable grid view that displays media items from a single album
/// in a tiled layout with selection support.
///
/// Each grid cell shows the media thumbnail via [MediumImage], the item's
/// filename, file size, and a type icon (video/image). When the item is
/// selected, a colored border and selection badge are displayed. The grid
/// density is controlled by [count] (columns), and the aspect ratio is
/// computed from the available width.
///
/// When [AlbumViewConfiguration.mediumItemBuilder] is provided, it
/// completely replaces the default cell widget, giving the caller full
/// control over media-item rendering. The builder receives the [Medium],
/// its [ImageProvider], and the current selection state.
/// {@endtemplate}
class AlbumGridView extends StatelessWidget {
  /// The list of media items to display in the grid.
  ///
  /// Each [Medium] provides an ID, filename, type, size, and thumbnail
  /// data. The list is typically produced by [Album.listMedia] and
  /// assigned to [_MultimediaGalleryAlbumState._mediums].
  final List<Medium> mediums;

  /// The number of columns in the grid.
  ///
  /// Controlled by the grid-density filter buttons (e.g., "2x", "3x").
  /// The available width is divided by this value to compute each
  /// cell's width, which then determines the aspect ratio.
  final int count;

  /// The list of IDs for currently selected media items.
  ///
  /// Used to determine whether each cell should show a selection border
  /// and badge. Items whose ID appears in this list are rendered with
  /// [AlbumViewConfiguration.selectedColor] and a numbered badge.
  final List<String> selected;

  /// Callback invoked when a media item is tapped.
  ///
  /// In multi-select mode, this toggles the item's selection state. In
  /// single-select mode, this finalizes the selection and pops the stack.
  final MediumReceived onSelected;

  /// The configuration controlling grid layout, styling, and selection.
  ///
  /// Provides cell aspect ratio, spacing, image styling, text styling,
  /// selection/unselected colors, and optionally a custom
  /// [mediumItemBuilder].
  final AlbumViewConfiguration configuration;

  /// {@macro album_grid_view}
  ///
  /// All parameters are required.
  const AlbumGridView({
    super.key,
    required this.mediums,
    required this.onSelected,
    required this.count,
    required this.selected,
    required this.configuration,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
            itemCount: mediums.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              Medium medium = mediums[index];
              IconData icon = medium.mediumType == MediumType.video
                ? configuration.videoIcon ?? Icons.slow_motion_video_rounded
                : medium.mediumType == MediumType.image
                ? configuration.imageIcon ?? Icons.motion_photos_on_rounded
                : configuration.defaultIcon ?? Icons.browse_gallery_rounded;
              bool isSelected = selected.any((i) => i.equals(medium.id));
              int selectedIndex = selected.findIndex((i) => i.equals(medium.id));
              Color color = isSelected.isFalse ? (configuration.unselectedColor ?? Colors.teal) : (configuration.selectedColor ?? Colors.green);
              ImageProvider image = ThumbnailProvider(mediumId: medium.id, mediumType: medium.mediumType, highQuality: true);

              if(configuration.mediumItemBuilder.isNotNull) {
                return configuration.mediumItemBuilder!(context, medium, image, isSelected);
              }

              return ClipRRect(
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
                          showIcon: configuration.showIcon,
                          itemBackgroundColor: configuration.itemBackgroundColor,
                          itemWidth: configuration.itemWidth,
                          color: color,
                          icon: icon,
                          iconSize: configuration.iconSize ?? 20,
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
                              TextBuilder(
                                text: (medium.size ?? 0).toFileSize,
                                size: configuration.fileSize ?? Sizing.font(12),
                                autoSize: false,
                                color: configuration.fileSizeColor ?? Theme.of(context).primaryColor,
                                flow: configuration.fileSizeFlow ?? TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      ]
                    )
                  ),
                ),
              );
            }
          )
        );
      }
    );
  }
}