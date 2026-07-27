import 'package:flutter/material.dart';
import 'package:smart/smart.dart';
import 'package:multimedia/multimedia.dart' show SelectedIndicator;

/// {@template medium_image}
/// A thumbnail widget that displays a media item's image with optional
/// selection indicator and type icon overlay.
///
/// This widget is the core rendering unit for individual media items in
/// both [AlbumGridView] and [AlbumListView]. It stacks three layers:
/// (1) the thumbnail image loaded via [FadeInImage] with a placeholder,
/// (2) a selection badge or custom [SelectedIndicator] when [isSelected]
/// is `true`, and (3) a type icon (e.g., video camera, photo) in the
/// bottom-right corner when [showIcon] is `true`.
///
/// The selection indicator defaults to a [Badge] widget showing the
/// 1-based selection order, but can be fully replaced by providing a
/// [SelectedIndicator] callback that receives the selection index.
/// {@endtemplate}
class MediumImage extends StatelessWidget {
  /// An optional icon representing the media type (video, image, etc.).
  ///
  /// Rendered in the bottom-right corner of the thumbnail when [showIcon]
  /// is `true`. The icon color matches the selection state color to
  /// maintain visual consistency.
  final IconData? icon;

  /// The color applied to the selection badge and the type [icon].
  ///
  /// Changes based on selection state: typically teal for unselected
  /// items and green for selected items. Also used as the badge
  /// background color when the item is selected.
  final Color? color;

  /// The image provider for the media thumbnail.
  ///
  /// Typically a [ThumbnailProvider] that loads the thumbnail from the
  /// device's media store. Displayed using [FadeInImage] with itself
  /// as both placeholder and image for a smooth fade-in effect.
  final ImageProvider image;

  /// Whether this media item is currently selected.
  ///
  /// When `true`, a selection indicator (badge or custom widget) is
  /// overlaid on the thumbnail. When `false`, no indicator is shown.
  final bool isSelected;

  /// The 0-based index of this item in the selection list.
  ///
  /// Displayed as a 1-based number in the default [Badge] indicator.
  /// Ignored when [selectedIndicator] is provided.
  final int selectedIndex;

  /// An optional custom widget to replace the default selection badge.
  ///
  /// Receives the 1-based selection index (i.e., [selectedIndex] + 1).
  /// When provided, completely replaces the default [Badge] widget,
  /// giving the caller full control over the selection indicator's
  /// appearance and behavior.
  final SelectedIndicator? selectedIndicator;

  /// The height of the thumbnail image in logical pixels.
  ///
  /// Defaults to the full screen height via [MediaQuery.sizeOf]. In a
  /// grid context, this is typically constrained by the parent's
  /// aspect ratio.
  final double? imageHeight;

  /// The width of the thumbnail image in logical pixels.
  ///
  /// Defaults to the full screen width via [MediaQuery.sizeOf]. In a
  /// grid context, this is typically constrained by the parent's
  /// aspect ratio.
  final double? imageWidth;

  /// How the thumbnail image should be inscribed within its bounds.
  ///
  /// Defaults to [BoxFit.cover], which scales the image to fill the
  /// container while maintaining aspect ratio and cropping excess.
  final BoxFit? imageFit;

  /// Whether to show the media-type icon in the bottom-right corner.
  ///
  /// Defaults to `true`. Set to `false` in list views where the icon
  /// is shown separately in the row layout (see [AlbumListView]).
  final bool showIcon;

  /// The background color of the thumbnail container.
  ///
  /// Defaults to `Colors.grey[300]`. Visible briefly while the image
  /// loads and when the image fails to load.
  final Color? itemBackgroundColor;

  /// The width of the thumbnail container.
  ///
  /// Defaults to the full screen width via [MediaQuery.sizeOf]. In a
  /// grid context, this is constrained by the grid cell width.
  final double? itemWidth;

  /// The size of the media-type [icon] in logical pixels.
  ///
  /// Defaults to `20`. Only applies when [showIcon] is `true` and
  /// [icon] is provided.
  final double? iconSize;

  /// {@macro medium_image}
  const MediumImage({
    super.key,
    this.icon,
    this.color,
    required this.image,
    required this.isSelected,
    required this.selectedIndex,
    this.selectedIndicator,
    this.imageHeight,
    this.imageWidth,
    this.imageFit,
    this.showIcon = true,
    this.itemBackgroundColor,
    this.itemWidth,
    this.iconSize
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: itemBackgroundColor ?? Colors.grey[300],
      width: itemWidth ?? MediaQuery.sizeOf(context).width,
      child: Stack(
        children: [
          SizedBox(
            height: imageHeight ?? MediaQuery.sizeOf(context).height,
            width: imageWidth ?? MediaQuery.sizeOf(context).width,
            child: FadeInImage(fit: imageFit ?? BoxFit.cover, placeholder: image, image: image),
          ),
          if(isSelected) ...[
            selectedIndicator.isNotNull ? selectedIndicator!(selectedIndex.plus(1)) : Positioned(
              top: 4,
              left: 4,
              child: Badge(
                backgroundColor: color,
                textColor: Colors.white,
                label: TextBuilder(
                  text: "${selectedIndex.plus(1)}",
                  size: Sizing.font(14),
                  autoSize: false,
                ),
              )
            )
          ],
          if(showIcon) ...[
            Positioned(bottom: 2, right: 2, child: Icon(icon, size: iconSize ?? 20, color: color))
          ]
        ],
      ),
    );
  }
}