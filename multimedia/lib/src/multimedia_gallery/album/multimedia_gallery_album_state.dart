part of 'multimedia_gallery_album.dart';

/// {@template multimedia_gallery_album_state}
/// State for [MultimediaGalleryAlbum] that manages media fetching, selection,
/// grid density, and layout toggle.
///
/// On initialization, this state fetches all [Medium] items from the
/// album via [Album.listMedia] and populates [_mediums]. Selection is
/// managed through [_selected], which tracks selected items by their ID.
/// The grid density is controlled by [_gridCount], which is updated
/// when the user taps a filter button (e.g., "2x" or "3x").
///
/// The layout can be toggled between grid and list via [_onLayoutChanged],
/// and the final selection is delivered either through the
/// [MultimediaGalleryAlbum.onMediumReceived] callback or by popping
/// the navigation stack with the selected items.
/// {@endtemplate}
class _MultimediaGalleryAlbumState extends State<MultimediaGalleryAlbum> {
  /// Whether the current view is grid mode (`true`) or list mode (`false`).
  ///
  /// Toggled by the app bar action button via [_onLayoutChanged]. When
  /// `true`, [AlbumGridView] is rendered; when `false`,
  /// [AlbumListView] is rendered instead.
  bool _isGrid = true;

  /// All media items fetched from the album.
  ///
  /// Populated asynchronously in [_fetch] after the widget initializes.
  /// Each [Medium] contains an ID, filename, type, size, and thumbnail
  /// data that is rendered by the grid/list views.
  List<Medium> _mediums = <Medium>[];

  /// The list of currently selected media items.
  ///
  /// Items are added/removed by [_handleSelectedMedium] when the user
  /// taps a medium in multi-select mode. In single-select mode, this
  /// list is never populated — the selection is immediately forwarded
  /// to [_send].
  List<Medium> _selected = [];

  /// The current number of columns in the grid view.
  ///
  /// Defaults to `2`. Updated by [_onGridChanged] when the user taps a
  /// filter button. The value is extracted from the filter label using
  /// a regex that matches the first numeric substring (e.g., "3x" → 3).
  int _gridCount = 2;

  /// The label of the currently selected grid-density filter button.
  ///
  /// Used to highlight the active filter button in [_buildFilters].
  /// Updated by [_onGridChanged] whenever the user selects a new
  /// grid density.
  String _selectedGrid = "";

  /// Whether media items are currently being fetched from the album.
  ///
  /// While `true`, a loading indicator is shown. Cleared after [_fetch]
  /// completes, regardless of whether the result is empty.
  bool _isFetching = true;

  /// The resolved [MultimediaGalleryAlbumConfiguration] from the parent widget.
  ///
  /// Cached in [initState] and updated in [didUpdateWidget] when the
  /// parent provides a new configuration.
  late MultimediaGalleryAlbumConfiguration parent;

  @override
  void initState() {
    parent = widget.configuration;
    _fetch();
    _onGridChanged(grids[0].header);

    super.initState();
  }

  /// Fetches all media items from the album asynchronously.
  ///
  /// Calls [Album.listMedia] to obtain a [MediaPage] containing the
  /// album's items, then assigns the items to [_mediums] and sets
  /// [_isFetching] to `false`. The UI re-renders after each state
  /// update to show the loading indicator, then the media grid/list.
  void _fetch() async {
    MediaPage page = await widget.album.listMedia();
    setState(() {
      _mediums = page.items;
      _isFetching = false;
    });
  }

  @override
  void didUpdateWidget(covariant MultimediaGalleryAlbum oldWidget) {
    if(oldWidget.album.notEquals(widget.album) || oldWidget.multipleAllowed.notEquals(widget.multipleAllowed)) {
      setState(() { });
    }

    if(oldWidget.configuration != widget.configuration) {
      setState(() {
        parent = widget.configuration;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  /// The list of available grid-density filter options.
  ///
  /// Each option is a [ButtonView] with a label like "2x" or "3x".
  /// Defaults to `["2x", "3x"]` when
  /// [MultimediaGalleryAlbumConfiguration.grids] is null. The first
  /// option is selected by default in [initState].
  @protected
  List<ButtonView> get grids => (parent.grids ?? ["2x", "3x"]).asMap().entries.map((MapEntry<int, String> item) {
    return ButtonView(header: item.value, index: item.key);
  }).toList();

  /// Whether the user can select multiple media items.
  ///
  /// Mirrors [MultimediaGalleryAlbum.multipleAllowed]. Used by
  /// [_handleSelectedMedium] to decide between toggling selection
  /// and immediately forwarding a single selection.
  @protected
  bool get multipleAllowed => widget.multipleAllowed;

  /// The list of IDs for all currently selected media items.
  ///
  /// Derived from [_selected] by mapping each [Medium] to its [Medium.id]
  /// and deduplicating. Used by [AlbumGridView] and [AlbumListView]
  /// to highlight selected items.
  @protected
  List<String> get selectedIds => _selected.map((m) => m.id).toSet().toList();

  /// The resolved [AlbumViewConfiguration] for the media grid/list.
  ///
  /// Falls back to a default [AlbumViewConfiguration] when the parent
  /// does not provide one. Controls cell styling, selection indicators,
  /// image sizing, and custom item builders.
  @protected
  AlbumViewConfiguration get configuration => parent.configuration ?? AlbumViewConfiguration();

  /// The resolved [MultimediaIconConfiguration] for the grid/list toggle icon.
  ///
  /// Falls back to a default [MultimediaIconConfiguration] when the
  /// parent does not provide one. Controls the icon data, color, and
  /// size of the layout-toggle button in the app bar.
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
  /// styling shown when the album contains no media items.
  @protected
  MultimediaNoItemConfiguration get noItemConfig => parent.noItemConfiguration ?? MultimediaNoItemConfiguration();

  /// The resolved [MultimediaGridFilterConfiguration] for the grid-density filter buttons.
  ///
  /// Falls back to a default [MultimediaGridFilterConfiguration] when
  /// the parent does not provide one. Controls button styling, spacing,
  /// padding, and shape for the grid-density selection buttons.
  @protected
  MultimediaGridFilterConfiguration get gridFilterConfig => parent.gridFilterConfiguration ?? MultimediaGridFilterConfiguration();

  /// The resolved [MultimediaDoneButtonConfiguration] for the "Done" button.
  ///
  /// Falls back to a default [MultimediaDoneButtonConfiguration] when
  /// the parent does not provide one. Controls the button text, color,
  /// font weight, padding, and shape.
  @protected
  MultimediaDoneButtonConfiguration get doneButtonConfig => parent.doneButtonConfiguration ?? MultimediaDoneButtonConfiguration();

  /// Finalizes the selection and delivers the result.
  ///
  /// Called when the user taps the "Done" button in the app bar.
  /// Delegates to [_send] with the current [_selected] list.
  void _onCompleted() => _send(_selected);

  /// Delivers the selected media items to the parent or pops the stack.
  ///
  /// If [MultimediaGalleryAlbum.onMediumReceived] is provided, the
  /// [selected] list is forwarded to it directly. Otherwise, the method
  /// pops the navigation stack. When
  /// [MultimediaGalleryAlbumConfiguration.popAllWhileGoingBack] is `true`,
  /// two pops are performed — the first returns to the album list, and
  /// the second returns the selected items to the calling screen.
  void _send(List<Medium> selected) {
    if(widget.onMediumReceived.isNotNull) {
      widget.onMediumReceived!(selected);
    } else if(parent.popAllWhileGoingBack) {
      Navigator.pop(context);
      Future.delayed(Duration.zero, () {
        Navigator.pop(context, selected);
      });
    } else {
      Navigator.pop(context, selected);
    }
  }

  /// Toggles between grid and list layout modes.
  ///
  /// Flips [_isGrid] and, if the parent provided a
  /// [MultimediaGalleryAlbumConfiguration.onLayoutChanged] callback,
  /// invokes it with the new boolean value so the parent can react
  /// to the change (e.g., persisting the user's layout preference).
  void _onLayoutChanged() {
    setState(() => _isGrid = !_isGrid);

    if(parent.onLayoutChanged.isNotNull) {
      parent.onLayoutChanged!(_isGrid);
    }
  }

  /// Updates the grid column count based on the selected filter label.
  ///
  /// Parses the first numeric substring from [value] using a regex
  /// (e.g., "3x" → 3) and sets [_gridCount] to that value. If no
  /// numeric substring is found, falls back to 2 columns. Also updates
  /// [_selectedGrid] to highlight the active filter button, and invokes
  /// [MultimediaGalleryAlbumConfiguration.onGridChanged] if provided.
  void _onGridChanged(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if(match != null) {
      final grid = int.parse(match.group(0)!);

      setState(() {
        _gridCount = grid;
        _selectedGrid = value;
      });
    } else {
      setState(() {
        _gridCount = 2;
      });
    }

    if(parent.onGridChanged.isNotNull) {
      parent.onGridChanged!(_gridCount);
    }
  }

  /// Handles a tap on a medium item, toggling selection or finalizing.
  ///
  /// First validates the medium's file size against
  /// [MultimediaGalleryAlbumConfiguration.maxSize] and [minSize],
  /// invoking [MultimediaGalleryAlbum.onErrorReceived] if the size
  /// is outside the allowed range. In multi-select mode, toggles the
  /// medium's presence in [_selected]. In single-select mode, calls
  /// [_send] immediately with the tapped medium.
  void _handleSelectedMedium(Medium medium) {
    if(parent.maxSize != null && medium.size != null && medium.size!.isGreaterThan(parent.maxSize!)) {
      parent.onErrorReceived?.call("Selected asset exceeds the maximum desired size ${parent.maxSize?.toFileSize}", false);
      return;
    }

    if(parent.minSize != null && medium.size != null && medium.size!.isLessThan(parent.minSize!)) {
      parent.onErrorReceived?.call("Selected asset is below the desired minimum size ${parent.minSize?.toFileSize}", false);
      return;
    }

    if(multipleAllowed) {
      List<Medium> list = List.from(_selected);
      int index = list.findIndex((i) => i.id.equals(medium.id));
      if(index.equals(-1)) {
        list.add(medium);
      } else {
        list.removeAt(index);
      }

      setState(() {
        _selected = list;
      });
    } else {
      _send([medium]);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          text: ("${widget.album.name ?? "Unnamed Album"} (${widget.album.count.toString()})").capitalizeEach,
          size: parent.titleSize ?? Sizing.font(20),
          weight: parent.titleWeight ?? FontWeight.bold,
          color: parent.titleColor ?? Theme.of(context).primaryColor
        ),
        actions: [
          if(selectedIds.isNotEmpty) ...[
            TextButton(
              onPressed: _onCompleted,
              style: ButtonStyle(
                overlayColor: WidgetStatePropertyAll(doneButtonConfig.overlayColor ?? Colors.transparent),
                backgroundColor: WidgetStateProperty.all(doneButtonConfig.backgroundColor ?? Colors.transparent),
                foregroundColor: WidgetStateProperty.all(doneButtonConfig.foregroundColor ?? Colors.transparent),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: WidgetStateProperty.all(doneButtonConfig.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                padding: WidgetStateProperty.all(doneButtonConfig.padding ?? EdgeInsets.symmetric(horizontal: 6))
              ),
              child: TextBuilder(
                text: doneButtonConfig.text ?? "Done",
                weight: doneButtonConfig.fontWeight ?? FontWeight.bold,
                color: doneButtonConfig.color ?? Colors.black
              )
            ),
          ],
          InfoButton(
            onPressed: _onLayoutChanged,
            defaultIcon: _isGrid ? (iconConfig.grid ?? Icons.grid_view_rounded) : (iconConfig.list ?? Icons.format_list_bulleted_outlined),
            defaultIconColor: iconConfig.color ?? Theme.of(context).primaryColor,
            defaultIconSize: iconConfig.size ?? Sizing.font(20),
          )
        ],
      ),
      child: _build()
    );
  }

  /// Builds the main content area based on the current album state.
  ///
  /// Returns one of: (1) a loading indicator while [_isFetching] is
  /// `true`, (2) an empty-state view when [_mediums] is empty, (3) a
  /// column containing filter buttons and [AlbumGridView] when in grid
  /// mode, or (4) [AlbumListView] when in list mode. Each state can be
  /// overridden by providing the corresponding builder in the configuration.
  Widget _build() {
    if(_isFetching) {
      return parent.loadingBuilder.isNotNull ? parent.loadingBuilder!(context) : Center(
        child: CircularProgressIndicator(color: parent.loadingColor ?? Theme.of(context).primaryColor)
      );
    } else if(_mediums.isEmpty) {
      return parent.emptyBuilder.isNotNull ? parent.emptyBuilder!(context) : NoItemFoundIndicator(
        message: noItemConfig.message ?? "No media found in this album",
        icon: noItemConfig.icon ?? Icons.photo_library_rounded,
        textColor: noItemConfig.textColor ?? Theme.of(context).primaryColor,
        iconSize: noItemConfig.iconSize ?? Sizing.font(100),
        textSize: noItemConfig.textSize ?? Sizing.font(16),
        spacing: noItemConfig.spacing ?? 10,
        opacity: noItemConfig.opacity ?? 0.2,
        customIcon: noItemConfig.iconWidget,
      );
    } else if(_isGrid) {
      return Column(
        spacing: parent.gridViewSpacing ?? 4,
        mainAxisAlignment: parent.gridViewMainAlignment ?? MainAxisAlignment.start,
        mainAxisSize: parent.gridViewMainAxisSize ?? MainAxisSize.max,
        crossAxisAlignment: parent.gridViewCrossAlignment ?? CrossAxisAlignment.start,
        children: [
          if(parent.showFilters) ...[
            Padding(padding: gridFilterConfig.padding ?? const EdgeInsets.all(10.0), child: _buildFilters(context)),
          ],
          Expanded(
            child: AlbumGridView(
              mediums: _mediums,
              onSelected: _handleSelectedMedium,
              count: _gridCount,
              selected: selectedIds,
              configuration: configuration
            )
          )
        ]
      );
    } else {
      return AlbumListView(
        mediums: _mediums,
        onSelected: _handleSelectedMedium,
        selected: selectedIds,
        configuration: configuration
      );
    }
  }

  /// Builds the grid-density filter buttons as a [Wrap] layout.
  ///
  /// Each filter option from [grids] is rendered as a [TextButton]
  /// with a highlighted background when its label matches [_selectedGrid].
  /// The button colors are derived from [MultimediaGridFilterConfiguration.buttonColor]
  /// with lighten/darken adjustments based on selection state. Tapping
  /// a button calls [_onGridChanged] to update the grid column count.
  Widget _buildFilters(BuildContext context) {
    return Wrap(
      runAlignment: gridFilterConfig.runAlignment ?? WrapAlignment.spaceBetween,
      crossAxisAlignment: gridFilterConfig.crossAlignment ?? WrapCrossAlignment.center,
      spacing: gridFilterConfig.spacing ?? 5,
      runSpacing: gridFilterConfig.runSpacing ?? 5,
      children: grids.map((view) {
        final bool isSelected = view.header.equals(_selectedGrid);

        final Color baseColor = gridFilterConfig.buttonColor ?? Colors.amber;
        final Color bgColor = isSelected ? baseColor.lighten(45) : baseColor.lighten(90);
        final Color txtColor = isSelected ? baseColor : baseColor.lighten(30);

        return TextButton(
          onPressed: () => _onGridChanged(view.header),
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(bgColor),
            overlayColor: WidgetStatePropertyAll(baseColor.lighten(60)),
            padding: WidgetStateProperty.all(gridFilterConfig.buttonPadding ?? EdgeInsets.symmetric(horizontal: 6)),
            shape: WidgetStateProperty.all(gridFilterConfig.buttonShape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: TextBuilder(
            text: view.header,
            size: Sizing.font(gridFilterConfig.buttonTextSize ?? 11),
            color: txtColor,
          )
        );
      }).toList(),
    );
  }
}