import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

import 'medium_image.dart';

/// A customizable vertical list view for displaying a list of media items.
///
/// The `AlbumListView` displays media items (`Medium`) in a scrollable list,
/// optionally supporting item selection, custom layout, styling, and icons.
///
/// ### Example:
/// ```dart
/// AlbumListView(
///   mediums: myMedia,
///   selected: selectedIds,
///   onSelected: (medium) => print(medium.id),
/// )
/// ```
class AlbumListView extends StatelessWidget {
  /// List of media items to display.
  final List<Medium> mediums;

  /// List of selected media IDs.
  final List<String> selected;

  /// Callback when a media item is tapped.
  final MediumReceived onSelected;

  /// The configuration for the album view.
  final AlbumViewConfiguration configuration;

  /// Creates a scrollable list view for displaying media items.
  const AlbumListView({
    super.key,
    required this.mediums,
    required this.onSelected,
    required this.selected,
    required this.configuration
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