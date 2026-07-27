part of 'multimedia_gallery.dart';

/// {@template multimedia_gallery_state}
/// Manages the full lifecycle of the [MultimediaGallery] widget.
///
/// This state class coordinates three sequential phases: (1) permission
/// checking via the user-supplied [MultimediaGalleryConfiguration.hasPermission]
/// callback, (2) album fetching from the device gallery using the
/// [Gallery] plugin, and (3) rendering the appropriate view — either a
/// grid of albums, a list of albums, or an empty/permission-denied
/// placeholder. The grid/list toggle is controlled by [_isGrid] and
/// can be switched at runtime via the app bar action button.
///
/// Media selection is handled by [_handleSelectedMedium], which resolves
/// each selected [Medium] into a [SelectedMedia] object containing the
/// file path, size, type, and raw bytes. The resolved list is then
/// forwarded to the parent through the configured callback or popped
/// from the navigation stack.
/// {@endtemplate}
class _MultimediaGalleryState extends SmartState<MultimediaGallery> {
  /// The complete list of albums fetched from the device gallery.
  ///
  /// Populated after a successful permission check and album fetch.
  /// Each [Album] contains a name, cover thumbnail, media count, and
  /// whether it is the newest album on the device.
  List<Album> _albums = <Album>[];

  /// Controls whether the gallery displays albums in a grid or list layout.
  ///
  /// Toggled by the app bar action button via [_onLayoutChanged]. When
  /// `true`, [GalleryGridView] is rendered; when `false`,
  /// [GalleryListView] is rendered instead.
  bool _isGrid = true;

  /// Indicates whether the gallery has been granted access to device media.
  ///
  /// Set after the asynchronous permission check completes. When `false`,
  /// the gallery displays a permission-denied placeholder with a retry
  /// button that re-invokes [_initializeGallery].
  bool _hasPermission = false;

  /// Whether the gallery is currently fetching albums from the device.
  ///
  /// While `true`, a loading indicator is shown. This flag is cleared
  /// after [_fetchAlbums] completes, regardless of whether the result
  /// is empty or non-empty.
  bool _isInitializing = false;

  /// Whether a permission check is currently in progress.
  ///
  /// While `true`, the gallery shows a permission-checking indicator.
  /// This is the first phase of initialization and must complete before
  /// album fetching can begin.
  bool _isCheckingPermission = false;

  /// The resolved [MultimediaGalleryConfiguration] from the parent widget.
  ///
  /// Cached in [initState] and updated in [didUpdateWidget] when the
  /// parent provides a new configuration. All derived getters
  /// (e.g., [configuration], [iconConfig]) read from this field.
  late MultimediaGalleryConfiguration parent;

  @override
  void initState() {
    parent = widget.configuration;
    _initializeGallery();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MultimediaGallery oldWidget) {
    if(oldWidget.configuration != widget.configuration) {
      setState(() {
        parent = widget.configuration;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  /// The display label for the current media type filter.
  ///
  /// Returns "Video" when [MultimediaGalleryConfiguration.showOnlyVideo]
  /// is `true`, "Photo" when [MultimediaGalleryConfiguration.showOnlyPhoto]
  /// is `true`, or "Media" when neither filter is active. This label is
  /// shown in the app bar header as "Gallery {header} Albums".
  @protected
  String get header => parent.showOnlyVideo ? "Video" : parent.showOnlyPhoto ? "Photo" : "Media";

  /// Whether the gallery allows selecting more than one media item at a time.
  ///
  /// Mirrors [MultimediaGalleryConfiguration.allowMultipleSelection]. When
  /// `true`, tapping a medium toggles its selection state; when `false`,
  /// tapping a medium immediately finalizes the selection and pops.
  @protected
  bool get multipleAllowed => parent.allowMultipleSelection;

  /// The resolved [GalleryViewConfiguration] for the album grid/list.
  ///
  /// Falls back to a default [GalleryViewConfiguration] when the parent
  /// does not provide one. Controls display count, aspect ratio, spacing,
  /// image styling, and custom item builders for the album views.
  @protected
  GalleryViewConfiguration get configuration => parent.configuration ?? GalleryViewConfiguration();

  /// The resolved [MultimediaIconConfiguration] for the grid/list toggle icon.
  ///
  /// Falls back to a default [MultimediaIconConfiguration] when the parent
  /// does not provide one. Controls the icon data, color, and size of the
  /// layout-toggle button in the app bar.
  @protected
  MultimediaIconConfiguration get iconConfig => parent.iconConfiguration ?? MultimediaIconConfiguration();

  /// The resolved [MultimediaLayoutConfiguration] for the page scaffold.
  ///
  /// Falls back to a default [MultimediaLayoutConfiguration] when the
  /// parent does not provide one. Controls background color, app bar
  /// styling, floating buttons, drawers, and loading indicators.
  @protected
  MultimediaLayoutConfiguration get layoutConfig => parent.layoutConfiguration ?? MultimediaLayoutConfiguration();

  /// The resolved [MultimediaNoItemConfiguration] for the empty-state view.
  ///
  /// Falls back to a default [MultimediaNoItemConfiguration] when the
  /// parent does not provide one. Controls the message, icon, and
  /// styling shown when no albums are found on the device.
  @protected
  MultimediaNoItemConfiguration get noItemConfig => parent.noItemConfiguration ?? MultimediaNoItemConfiguration();

  /// The resolved [MultimediaNoPermissionConfiguration] for the permission-denied view.
  ///
  /// Falls back to a default [MultimediaNoPermissionConfiguration] when
  /// the parent does not provide one. Controls the message, icon, retry
  /// button, and styling shown when gallery access is denied.
  @protected
  MultimediaNoPermissionConfiguration get noPermitConfig => parent.noPermissionConfiguration ?? MultimediaNoPermissionConfiguration();

  /// The resolved [MultimediaFileManagerConfiguration] for the file-manager picker.
  ///
  /// Falls back to a default [MultimediaFileManagerConfiguration] when
  /// the parent does not provide one. Controls the label, icon, callback,
  /// and size constraints for the "Select from file manager" button.
  @protected
  MultimediaFileManagerConfiguration get fileManagerConfig => parent.fileManagerConfiguration ?? MultimediaFileManagerConfiguration();

  /// Performs the two-phase gallery initialization sequence.
  ///
  /// Phase 1: Sets [_isCheckingPermission] to `true` and awaits the
  /// [MultimediaGalleryConfiguration.hasPermission] callback. If the
  /// callback is null, permission is assumed denied. Phase 2: If
  /// permission is granted, sets [_isInitializing] to `true` and calls
  /// [_fetchAlbums] to load all albums from the device. Each phase
  /// updates its respective flag via [setState] so the UI re-renders
  /// at the correct loading stage.
  void _initializeGallery() async {
    setState(() => _isCheckingPermission = true);
    bool hasPermission = parent.hasPermission.isNotNull ? await parent.hasPermission!() : false;

    setState(() {
      _isCheckingPermission = false;
      _hasPermission = hasPermission;
    });

    if(hasPermission) {
      setState(() => _isInitializing = true);
      List<Album> list = await _fetchAlbums();
      setState(() {
        _isInitializing = false;
        _albums = list;
      });
    }
  }

  /// Queries the device gallery for albums, filtered by media type.
  ///
  /// If [MultimediaGalleryConfiguration.showOnlyVideo] is `true`, only
  /// video albums are returned. If [MultimediaGalleryConfiguration.showOnlyPhoto]
  /// is `true`, only image albums are returned. Otherwise, all albums
  /// (images and videos) are returned. The returned list is assigned
  /// to [_albums] by the caller.
  Future<List<Album>> _fetchAlbums() async {
    if(parent.showOnlyVideo) {
      return await Gallery.listAlbums(mediumType: MediumType.video);
    } else if(parent.showOnlyPhoto) {
      return await Gallery.listAlbums(mediumType: MediumType.image);
    } else {
      return await Gallery.listAlbums();
    }
  }

  /// Toggles between grid and list layout modes.
  ///
  /// Flips [_isGrid] and, if the parent provided an
  /// [MultimediaGalleryConfiguration.onLayoutChanged] callback, invokes
  /// it with the new boolean value so the parent can react to the change
  /// (e.g., persisting the user's layout preference).
  void _onLayoutChanged() {
    setState(() => _isGrid = !_isGrid);

    if(parent.onLayoutChanged.isNotNull) {
      parent.onLayoutChanged!(_isGrid);
    }
  }

  /// Forwards media selected from the file manager to the parent callback.
  ///
  /// Called by [MultimediaUtils.pickFromFile] after the user selects files
  /// through the system file picker. The [files] list contains fully
  /// resolved [SelectedMedia] objects, while [mediums] contains the raw
  /// gallery [Medium] entries in the same order. Both are passed to
  /// [MultimediaGalleryConfiguration.onMediaReceived].
  void handleSelectedListMedia(List<SelectedMedia> files, List<Medium> mediums) {
    if(parent.onMediaReceived.isNotNull) {
      parent.onMediaReceived!(files, mediums);
    }
  }

  /// Resolves selected [Medium] items into [SelectedMedia] objects and delivers them.
  ///
  /// For each [Medium], this method: (1) calls [Medium.getFile] to obtain
  /// the platform file, (2) determines the [MediaType] by checking the
  /// medium's type or falling back to the file extension, (3) reads the
  /// file bytes, and (4) constructs a [SelectedMedia] with path, size,
  /// type, and data. After all items are resolved, the result is either
  /// forwarded to [MultimediaGalleryConfiguration.onMediaReceived] or
  /// popped from the navigation stack. When
  /// [MultimediaGalleryConfiguration.popAllWhileGoingBack] is `true`,
  /// two pops are performed — the first returns to the album page, and
  /// the second returns the result to the calling screen.
  Future<void> _handleSelectedMedium(List<Medium> medium) async {
    List<Future<SelectedMedia>> list = medium.map((medium) async {
      final file = await medium.getFile();
      MediaType type = medium.mediumType.isNotNull
          ? (medium.mediumType == MediumType.video ? MediaType.video : MediaType.photo)
          : (file.path.isVideo ? MediaType.video : MediaType.photo);

      return SelectedMedia(
        path: file.path,
        size: (await file.length()).toFileSize,
        media: type,
        data: await file.readAsBytes(),
      );
    }).toList();

    List<SelectedMedia> files = [];
    for(Future<SelectedMedia> file in list) {
      files.add(await file);
    }

    if(parent.onMediaReceived.isNotNull) {
      parent.onMediaReceived!(files, medium);
    } else if(parent.popAllWhileGoingBack) {
      Navigator.pop(context);
      Future.delayed(Duration.zero, () {
        Navigator.pop(context, files);
      });
    }else {
      Navigator.pop(context, files);
    }
  }

  @override
  Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme) {
    return ViewLayout(
      config: layoutConfig.config,
      extendBehindAppbar: layoutConfig.extendBehindAppbar,
      extendBody: layoutConfig.extendBody,
      goDark: layoutConfig.goDark,
      theme: layoutConfig.theme,
      shouldWillPop: layoutConfig.shouldWillPop,
      shouldOverride: layoutConfig.shouldOverride,
      floatingButton: layoutConfig.floatingButton,
      floater: layoutConfig.floater,
      floaterWidth: layoutConfig.floaterWidth,
      floatingLocation: layoutConfig.floatingLocation,
      drawer: layoutConfig.drawer,
      endDrawer: layoutConfig.endDrawer,
      needSafeArea: layoutConfig.needSafeArea,
      useFloaterWidth: layoutConfig.useFloaterWidth,
      withActivity: layoutConfig.withActivity,
      onInactivity: layoutConfig.onInactivity,
      onActivity: layoutConfig.onActivity,
      inactivityDuration: layoutConfig.inactivityDuration,
      isLoading: layoutConfig.isLoading,
      loadingHeight: layoutConfig.loadingHeight,
      loadingPosition: layoutConfig.loadingPosition,
      loadingWidth: layoutConfig.loadingWidth,
      loadingColor: layoutConfig.loadingColor,
      loadingBackgroundColor: layoutConfig.loadingBackgroundColor,
      floatFit: layoutConfig.floatFit,
      loadingFit: layoutConfig.loadingFit,
      bottomNavbar: layoutConfig.bottomNavbar,
      bottomSheet: layoutConfig.bottomSheet,
      barColor: layoutConfig.barColor,
      navigationColor: layoutConfig.navigationColor,
      darkBackgroundColor: layoutConfig.darkBackgroundColor,
      onWillPop: layoutConfig.onWillPop,
      backgroundColor: layoutConfig.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appbar: AppBar(
        elevation: parent.appBarElevation ?? 0.5,
        title: parent.titleWidget ?? TextBuilder.center(
          text: parent.title,
          size: parent.titleSize ?? Sizing.font(20),
          weight: parent.titleWeight ?? FontWeight.bold,
          color: parent.titleColor ?? Theme.of(context).primaryColor
        ),
        actions: [
          InfoButton(
            onPressed: _onLayoutChanged,
            defaultIcon: _isGrid ? (iconConfig.grid ?? Icons.grid_view_rounded) : (iconConfig.list ?? Icons.format_list_bulleted_outlined),
            defaultIconColor: iconConfig.color ?? Theme.of(context).primaryColor,
            defaultIconSize: iconConfig.size ?? Sizing.font(20),
          )
        ],
      ),
      child: Column(
        spacing: parent.spacing ?? 0,
        mainAxisAlignment: parent.mainAxisAlignment ?? MainAxisAlignment.start,
        mainAxisSize: parent.mainAxisSize ?? MainAxisSize.max,
        crossAxisAlignment: parent.crossAxisAlignment ?? CrossAxisAlignment.start,
        children: [
          if(parent.showManager) ...[
            SmartButton(
              tab: ButtonView(
                icon: fileManagerConfig.icon ?? Icons.photo_library_rounded,
                header: fileManagerConfig.text ?? "Select from file manager",
                body: fileManagerConfig.body ?? "You can select up to 30mb of photo size",
              ),
              color: fileManagerConfig.color ?? Theme.of(context).primaryColor,
              backgroundColor: Colors.transparent,
              onTap: () {
                if(fileManagerConfig.onPressed.isNotNull) {
                  fileManagerConfig.onPressed!();
                } else {
                  MultimediaUtils.pickFromFile(
                    onError: fileManagerConfig.onError,
                    handleSelected: handleSelectedListMedia,
                    onlyVideo: parent.showOnlyVideo,
                    onlyPhoto: parent.showOnlyPhoto,
                    multipleAllowed: multipleAllowed,
                    title: parent.title,
                    maxSize: parent.maxSize,
                    minSize: parent.minSize
                  );
                }
              },
            ),
            if(parent.showDivider) ...[
              Divider(color: parent.dividerColor ?? Theme.of(context).primaryColor, thickness: parent.dividerThickness),
            ]
          ],
          if(parent.showHeader) ...[
            Padding(
              padding: parent.headerPadding ?? const EdgeInsets.only(left: 6.0),
              child: TextBuilder(
                text: "Gallery $header Albums",
                color: parent.headerColor ?? Theme.of(context).primaryColorLight,
                size: parent.headerSize ?? Sizing.font(14),
                weight: parent.headerWeight ?? FontWeight.normal,
              ),
            )
          ],
          if(parent.showDivider) ...[
            Divider(color: parent.dividerColor ?? Theme.of(context).primaryColor, thickness: parent.dividerThickness),
          ],
          Expanded(child: _build())
        ],
      )
    );
  }

  /// Builds the main content area based on the current gallery state.
  ///
  /// The widget tree follows a priority order: (1) if permission is being
  /// checked, show the permission-checking indicator or custom builder;
  /// (2) if permission is denied, show the permission-denied view or
  /// custom builder; (3) if albums are loading, show the loading indicator
  /// or custom builder; (4) if no albums exist, show the empty-state view
  /// or custom builder; (5) otherwise, show [GalleryGridView] or
  /// [GalleryListView] depending on [_isGrid]. Each state can be
  /// overridden by providing the corresponding builder in the configuration.
  Widget _build() {
    if(_isCheckingPermission) {
      if (parent.permissionCheckBuilder case WidgetBuilder builder?) {
        return builder(context);
      }

      return Center(child: CircularProgressIndicator());
    } else if(_hasPermission.isFalse) {
      String permissionMessage = "Permission is needed to access your gallery";

      if (parent.noPermissionBuilder case WidgetBuilder builder?) {
        return builder(context);
      }

      return NoItemFoundIndicator(
        message: noPermitConfig.message ?? permissionMessage,
        icon: noPermitConfig.icon ?? Icons.photo_library_rounded,
        textColor: noPermitConfig.textColor ?? Theme.of(context).primaryColor,
        onRefresh: _initializeGallery,
        buttonColor: noPermitConfig.buttonColor ?? Theme.of(context).primaryColor,
        iconSize: noPermitConfig.iconSize ?? Sizing.font(100),
        textSize: noPermitConfig.textSize ?? Sizing.font(16),
        spacing: noPermitConfig.spacing ?? 10,
        buttonWeight: noPermitConfig.buttonWeight ?? FontWeight.bold,
        buttonSize: noPermitConfig.buttonSize ?? Sizing.font(14),
        buttonText: noPermitConfig.buttonText ?? "Refresh",
        buttonPadding: noPermitConfig.buttonPadding ?? EdgeInsets.symmetric(horizontal: 6),
        buttonShape: noPermitConfig.buttonShape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        buttonOverlayColor: noPermitConfig.buttonOverlayColor,
        opacity: noPermitConfig.opacity ?? 0.2,
        customIcon: noPermitConfig.iconWidget,
        buttonBackgroundColor: noPermitConfig.buttonBackgroundColor,
        buttonForegroundColor: noPermitConfig.buttonForegroundColor,
      );
    } else if(_isInitializing) {
      if (parent.loadingBuilder case WidgetBuilder builder?) {
        return builder(context);
      }

      return Center(child: CircularProgressIndicator());
    } else if(_albums.isEmpty) {
      if (parent.emptyBuilder case WidgetBuilder builder?) {
        return builder(context);
      }

      return NoItemFoundIndicator(
        message: noItemConfig.message ?? "No gallery asset found in your device",
        icon: noItemConfig.icon ?? Icons.photo_library_rounded,
        textColor: noItemConfig.textColor ?? Theme.of(context).primaryColor,
        iconSize: noItemConfig.iconSize ?? Sizing.font(100),
        textSize: noItemConfig.textSize ?? Sizing.font(16),
        spacing: noItemConfig.spacing ?? 10,
        opacity: noItemConfig.opacity ?? 0.2,
        customIcon: noItemConfig.iconWidget,
      );
    } else if(_isGrid) {
      return GalleryGridView(
        albums: _albums,
        multipleAllowed: multipleAllowed,
        onSelected: _handleSelectedMedium,
        maxSelection: parent.maxSelection,
        configuration: configuration,
        parentRoute: widget.route,
      );
    } else {
      return GalleryListView(
        albums: _albums,
        multipleAllowed: multipleAllowed,
        onSelected: _handleSelectedMedium,
        maxSelection: parent.maxSelection,
        configuration: configuration,
        parentRoute: widget.route,
      );
    }
  }
}