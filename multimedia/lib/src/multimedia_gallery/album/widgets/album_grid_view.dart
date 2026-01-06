import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import 'medium_image.dart';

/// A customizable grid view for displaying media items in a tiled layout.
///
/// The `AlbumGridView` displays media in a grid layout, supporting selection,
/// custom icons, styles, and layouts.
///
/// ### Example:
/// ```dart
/// AlbumGridView(
///   mediums: myMedia,
///   count: 3,
///   selected: selectedIds,
///   onSelected: (medium) => print(medium.id),
/// )
/// ```
class AlbumGridView extends StatelessWidget {
  /// List of media items to display.
  final List<Medium> mediums;

  /// Number of items per row.
  final int count;

  /// List of selected media IDs.
  final List<String> selected;

  /// Callback when a media item is tapped.
  final MediumReceived onSelected;

  /// The configuration for the grid view.
  final AlbumViewConfiguration configuration;

  /// Creates a responsive grid view for displaying media items.
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