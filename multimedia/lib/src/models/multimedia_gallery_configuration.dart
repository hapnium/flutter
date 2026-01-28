import 'package:flutter/cupertino.dart';
import 'package:multimedia/multimedia.dart';

/// {@template multimedia_gallery_configuration}
/// Configuration class for customizing the behavior and appearance of the
/// [MultimediaGallery] widget.
///
/// This class allows developers to specify display options, layout configurations,
/// permission handling, media filtering, and various UI customizations.
///
/// ### Example:
/// ```dart
/// final config = MultimediaGalleryConfiguration(
///   title: "My Gallery",
///   showOnlyVideo: false,
///   showOnlyPhoto: true,
///   allowMultipleSelection: true,
///   maxSelection: 5,
///   appBarElevation: 4.0,
///   titleColor: Colors.black,
///   titleWeight: FontWeight.bold,
///   titleSize: 18.0,
///   spacing: 8.0,
///   showDivider: true,
/// );
/// ```
/// {@endtemplate}
class MultimediaGalleryConfiguration {
  /// Title shown in the gallery app bar.
  ///
  /// Defaults to an empty string.
  final String title;

  /// Whether to show only videos in the gallery.
  ///
  /// Defaults to false.
  final bool showOnlyVideo;

  /// Whether to show only photos in the gallery.
  ///
  /// Defaults to true.
  final bool showOnlyPhoto;

  /// If true, allows users to select multiple media items.
  ///
  /// Defaults to false.
  final bool allowMultipleSelection;

  /// Callback triggered when a list of selected media is returned.
  ///
  /// Defaults to null.
  final SelectedMediaListReceived? onMediaReceived;

  /// Maximum number of selectable media items.
  ///
  /// If null, the selection is unlimited.
  final int? maxSelection;

  /// Custom UI configuration for the gallery's grid or list layout.
  ///
  /// Defaults to null.
  final GalleryViewConfiguration? configuration;

  /// Custom icons used within the gallery.
  ///
  /// Defaults to null.
  final MultimediaIconConfiguration? iconConfiguration;

  /// Layout customization for the multimedia interface elements.
  ///
  /// Defaults to null.
  final MultimediaLayoutConfiguration? layoutConfiguration;

  /// Configuration for displaying UI when no media items are available.
  ///
  /// Defaults to null.
  final MultimediaNoItemConfiguration? noItemConfiguration;

  /// Configuration for displaying UI when gallery permission is not granted.
  ///
  /// Defaults to null.
  final MultimediaNoPermissionConfiguration? noPermissionConfiguration;

  /// File manager configuration for handling gallery files.
  ///
  /// Defaults to null.
  final MultimediaFileManagerConfiguration? fileManagerConfiguration;

  /// Elevation value for the app bar.
  ///
  /// Defaults to null.
  final double? appBarElevation;

  /// Color of the app bar title text.
  ///
  /// Defaults to null.
  final Color? titleColor;

  /// Font weight of the app bar title text.
  ///
  /// Defaults to null.
  final FontWeight? titleWeight;

  /// Font size of the app bar title text.
  ///
  /// Defaults to null.
  final double? titleSize;

  /// A custom widget to replace the default app bar title.
  ///
  /// Defaults to null.
  final Widget? titleWidget;

  /// Color of the divider between sections.
  ///
  /// Defaults to null.
  final Color? dividerColor;

  /// Thickness of the divider line.
  ///
  /// Defaults to null.
  final double? dividerThickness;

  /// Determines whether the section header is displayed.
  ///
  /// Defaults to true.
  final bool showHeader;

  /// Padding applied around the header section.
  ///
  /// Defaults to null.
  final EdgeInsets? headerPadding;

  /// Color of the header text.
  ///
  /// Defaults to null.
  final Color? headerColor;

  /// Font size of the header text.
  ///
  /// Defaults to null.
  final double? headerSize;

  /// Font weight of the header text.
  ///
  /// Defaults to null.
  final FontWeight? headerWeight;

  /// Whether to show a divider between UI sections.
  ///
  /// Defaults to true.
  final bool showDivider;

  /// Whether to show the media manager at the bottom of the UI.
  ///
  /// Defaults to true.
  final bool showManager;

  /// Custom builder used when the gallery is empty.
  ///
  /// Defaults to null.
  final WidgetBuilder? emptyBuilder;

  /// Custom builder used when permission is denied.
  ///
  /// Defaults to null.
  final WidgetBuilder? noPermissionBuilder;

  /// Custom builder used when checking permission.
  ///
  /// Defaults to null.
  final WidgetBuilder? permissionCheckBuilder;

  /// Custom builder used when loading assets.
  ///
  /// Defaults to null.
  final WidgetBuilder? loadingBuilder;

  /// The spacing between media items in grid or list layout.
  ///
  /// Defaults to null.
  final double? spacing;

  /// Controls how media items are aligned along the main axis.
  ///
  /// Defaults to null.
  final MainAxisAlignment? mainAxisAlignment;

  /// Determines the size of the main axis for media items.
  ///
  /// Defaults to null.
  final MainAxisSize? mainAxisSize;

  /// Controls how media items are aligned along the cross axis.
  ///
  /// Defaults to null.
  final CrossAxisAlignment? crossAxisAlignment;

  /// Callback triggered when the layout is changed (e.g., from grid to list).
  ///
  /// Defaults to null.
  final OnMultimediaLayoutChanged? onLayoutChanged;

  /// Optional override to handle permission checks manually.
  ///
  /// Defaults to null.
  final Future<bool> Function()? hasPermission;

  /// If true, pops all previous routes when navigating back.
  ///
  /// Defaults to true.
  final bool popAllWhileGoingBack;

  /// Maximum file size (for file manager constraints) for displayed media.
  ///
  /// If targeting `gallery` constraints, use the `MultimediaGalleryAlbumConfiguration`
  /// Items larger than this will be excluded.
  ///
  /// `null` by default.
  final int? maxSize;

  /// Minimum file size (for file manager constraints) for displayed media.
  ///
  /// If targeting `gallery` constraints, use the `MultimediaGalleryAlbumConfiguration`
  /// Items smaller than this will be excluded.
  ///
  /// `null` by default.
  final int? minSize;

  /// {@macro multimedia_gallery_configuration}
  const MultimediaGalleryConfiguration({
    this.title = "",
    this.showOnlyVideo = false,
    this.showOnlyPhoto = true,
    this.onMediaReceived,
    this.allowMultipleSelection = false,
    this.maxSelection,
    this.configuration,
    this.iconConfiguration,
    this.layoutConfiguration,
    this.noItemConfiguration,
    this.noPermissionConfiguration,
    this.fileManagerConfiguration,
    this.appBarElevation,
    this.titleColor,
    this.titleWeight,
    this.titleSize,
    this.titleWidget,
    this.dividerColor,
    this.dividerThickness,
    this.showHeader = true,
    this.headerPadding,
    this.headerColor,
    this.headerSize,
    this.headerWeight,
    this.showDivider = true,
    this.showManager = true,
    this.emptyBuilder,
    this.noPermissionBuilder,
    this.spacing,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.onLayoutChanged,
    this.hasPermission,
    this.popAllWhileGoingBack = true,
    this.maxSize,
    this.minSize,
    this.loadingBuilder,
    this.permissionCheckBuilder
  });
}