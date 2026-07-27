import 'package:flutter/material.dart';
import 'package:multimedia/multimedia.dart';
import 'package:smart/smart.dart';

/// {@template album_information}
/// A badge widget that displays whether an album is the newest or oldest
/// in the gallery based on the [Album.newest] flag.
///
/// Renders a small, colored pill-shaped container with the text "NEWEST"
/// or "OLDEST" inside it. The badge is designed to be overlaid on album
/// thumbnails or placed in album list rows to quickly communicate album
/// recency to the user. The background color automatically switches
/// between [newestColor] and [oldestColor] based on the album's recency.
///
/// This widget is used internally by [GalleryGridView] and
/// [GalleryListView] but can also be used standalone in custom album
/// layouts.
/// {@endtemplate}
class AlbumInformation extends StatelessWidget {
  /// The album whose recency status to display.
  ///
  /// The [Album.newest] property determines whether the badge shows
  /// "NEWEST" or "OLDEST", and which background color is applied.
  final Album album;

  /// Background color for the badge when [Album.newest] is `true`.
  ///
  /// Defaults to [Colors.blue] if not provided. Applied only when the
  /// album is the most recently added album on the device.
  final Color? newestColor;

  /// Background color for the badge when [Album.newest] is `false`.
  ///
  /// Defaults to [Colors.red] if not provided. Applied only when the
  /// album is the oldest album on the device.
  final Color? oldestColor;

  /// Text color for the badge label ("NEWEST" or "OLDEST").
  ///
  /// Defaults to [Colors.white] to ensure contrast against the
  /// colored background. Should be light when the background is dark,
  /// or dark when the background is light.
  final Color? infoColor;

  /// Font size of the badge text in logical pixels.
  ///
  /// Defaults to `9`. This is intentionally small to keep the badge
  /// unobtrusive when overlaid on thumbnails.
  final double? infoSize;

  /// Internal padding of the badge container.
  ///
  /// Defaults to `EdgeInsets.only(top: 4, bottom: 2, left: 4, right: 4)`.
  /// The asymmetric vertical padding accounts for visual centering of
  /// the uppercase text.
  final EdgeInsetsGeometry? infoPadding;

  /// Border radius of the badge container.
  ///
  /// Defaults to `BorderRadius.circular(4)`. A small radius gives the
  /// badge a slightly rounded appearance without being fully pill-shaped.
  final BorderRadiusGeometry? infoRadius;

  /// {@macro album_information}
  const AlbumInformation({
    super.key,
    required this.album,
    this.newestColor,
    this.oldestColor,
    this.infoColor,
    this.infoSize,
    this.infoPadding,
    this.infoRadius
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: infoPadding ?? EdgeInsets.only(top: 4, bottom: 2, left: 4, right: 4),
      decoration: BoxDecoration(
        color: album.newest ? (newestColor ?? Colors.blue) : (oldestColor ?? Colors.red),
        borderRadius: infoRadius ?? BorderRadius.circular(4)
      ),
      child: TextBuilder(
        text: album.newest ? "NEWEST" : "OLDEST",
        size: infoSize ?? 9,
        autoSize: false,
        color: infoColor ?? Colors.white,
        flow: TextOverflow.ellipsis,
      ),
    );
  }
}