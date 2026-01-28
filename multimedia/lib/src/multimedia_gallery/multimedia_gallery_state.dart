part of 'multimedia_gallery.dart';

class _MultimediaGalleryState extends SmartState<MultimediaGallery> {
  List<Album> _albums = <Album>[];
  bool _isGrid = true;
  bool _hasPermission = false;
  bool _isInitializing = false;
  bool _isCheckingPermission = false;
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

  @protected
  String get header => parent.showOnlyVideo ? "Video" : parent.showOnlyPhoto ? "Photo" : "Media";

  @protected
  bool get multipleAllowed => parent.allowMultipleSelection;

  @protected
  GalleryViewConfiguration get configuration => parent.configuration ?? GalleryViewConfiguration();

  @protected
  MultimediaIconConfiguration get iconConfig => parent.iconConfiguration ?? MultimediaIconConfiguration();

  @protected
  MultimediaLayoutConfiguration get layoutConfig => parent.layoutConfiguration ?? MultimediaLayoutConfiguration();

  @protected
  MultimediaNoItemConfiguration get noItemConfig => parent.noItemConfiguration ?? MultimediaNoItemConfiguration();

  @protected
  MultimediaNoPermissionConfiguration get noPermitConfig => parent.noPermissionConfiguration ?? MultimediaNoPermissionConfiguration();

  @protected
  MultimediaFileManagerConfiguration get fileManagerConfig => parent.fileManagerConfiguration ?? MultimediaFileManagerConfiguration();

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

  Future<List<Album>> _fetchAlbums() async {
    if(parent.showOnlyVideo) {
      return await Gallery.listAlbums(mediumType: MediumType.video);
    } else if(parent.showOnlyPhoto) {
      return await Gallery.listAlbums(mediumType: MediumType.image);
    } else {
      return await Gallery.listAlbums();
    }
  }

  void _onLayoutChanged() {
    setState(() => _isGrid = !_isGrid);

    if(parent.onLayoutChanged.isNotNull) {
      parent.onLayoutChanged!(_isGrid);
    }
  }

  void handleSelectedListMedia(List<SelectedMedia> files) {
    if(parent.onMediaReceived.isNotNull) {
      parent.onMediaReceived!(files);
    }
  }

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
      parent.onMediaReceived!(files);
    } else if(parent.popAllWhileGoingBack) {
      // First pop returns to the album page
      Navigator.pop(context);
      // Delay the second pop until the current pop completes
      Future.delayed(Duration.zero, () {
        Navigator.pop(context, files); // Pop album page with result
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