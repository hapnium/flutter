import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/rendering.dart';
import 'package:hapnium/hapnium.dart' hide Page;

import '../builders/pageable_layout_builder.dart';
import '../controller/pageable_controller.dart';
import '../helpers/pageable_helper.dart';
import '../models/pageable_builder_delegate.dart';

/// A scrollable grid view that supports pagination.
///
/// [PageableGridView] automatically handles fetching, displaying, and paginating
/// data using a [PageableController]. It supports vertical and horizontal scrolling
/// and provides various customization options.
///
/// - [Page] represents the type of key used for pagination.
/// - [Item] represents the type of data displayed in the grid.
///
/// **Purpose:**
///
/// The [PageableGridView] widget simplifies the creation of paginated grid views by
/// abstracting the complexities of data fetching and display. It provides
/// a flexible and efficient way to load and render large datasets in a
/// scrollable grid view.
///
/// **Usage:**
///
/// Use [PageableGridView] to create a scrollable grid that fetches and displays
/// data in pages. Provide a [PageableController] to manage the pagination logic,
/// a [SliverGridDelegate] to define the grid layout, and a
/// [PageableBuilderDelegate] to define how grid items are built.
///
/// **Example:**
///
/// ```dart
/// PagedGridView<int, Item>(
///   controller: _pagedController,
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
///   builderDelegate: PagedChildBuilderDelegate<Item>(
///     itemBuilder: (context, item, index) => GridTile(child: Text(item.title)),
///   ),
/// )
/// ```
///
/// **Customization:**
///
/// You can customize the appearance and behavior of the [PageableGridView] by
/// providing a custom [ScrollController], [SliverGridDelegate],
/// [PageableBuilderDelegate], and [PageableController]. The
/// [PageableBuilderDelegate] allows you to define how grid items are built,
/// while the [PageableController] manages the pagination logic.
///
/// **Separated Grids:**
///
/// Use the [.separated] constructor to create a [PageableGridView] with separators
/// between items. This constructor requires a [separatorBuilder] to define
/// how separators are built.
///
/// **Note:**
///
/// The [PageableGridView] widget is a specialized version of the [GridView] widget
/// that integrates with the [PageableController] for pagination support.
class PageableGridView<Page, Item> extends StatelessWidget {
  /// A delegate that controls the layout of the children within the PagedGridView.
  ///
  /// The [PageableGridView].builder, and [PageableGridView].separator constructors let you
  /// specify this delegate explicitly. The other constructors create a gridDelegate implicitly.
  final SliverGridDelegate gridDelegate;

  /// The controller responsible for managing pagination.
  final PageableController<Page, Item> controller;

  /// The builder delegate used to create list items.
  final PageableBuilderDelegate<Item> builderDelegate;

  /// The axis along which the list scrolls. Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the list is reversed (i.e., starts from the bottom).
  final bool reverse;

  /// The scroll controller used to manage scrolling.
  final ScrollController? scrollController;

  /// Whether this is the primary scroll view associated with user input.
  final bool? primary;

  /// Defines the scroll physics for the list.
  final ScrollPhysics? physics;

  /// Whether the list should shrink to fit its children.
  final bool shrinkWrap;

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// Children after [center] will be placed in the [AxisDirection] determined
  /// by [scrollDirection] and [reverse] relative to the [center]. Children
  /// before [center] will be placed in the opposite of the axis direction
  /// relative to the [center]. This makes the [center] the inflection point of
  /// the growth direction.
  ///
  /// The [center] must be the key of one of the slivers built by [buildSlivers].
  ///
  /// Of the built-in subclasses of [ScrollView], only [CustomScrollView]
  /// supports [center]; for that class, the given key must be the key of one of
  /// the slivers in the [CustomScrollView.slivers] list.
  ///
  /// Most scroll views by default are ordered [GrowthDirection.forward].
  /// Changing the default values of [ScrollView.anchor],
  /// [ScrollView.center], or both, can configure a scroll view for
  /// [GrowthDirection.reverse].
  ///
  /// {@tool dartpad}
  /// This sample shows a [CustomScrollView], with [Radio] buttons in the
  /// [AppBar.bottom] that change the [AxisDirection] to illustrate different
  /// configurations. The [CustomScrollView.anchor] and [CustomScrollView.center]
  /// properties are also set to have the 0 scroll offset positioned in the middle
  /// of the viewport, with [GrowthDirection.forward] and [GrowthDirection.reverse]
  /// illustrated on either side. The sliver that shares the
  /// [CustomScrollView.center] key is positioned at the [CustomScrollView.anchor].
  ///
  /// ** See code in examples/api/lib/rendering/growth_direction/growth_direction.0.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [anchor], which controls where the [center] as aligned in the viewport.
  final Key? center;

  /// The relative position of the zero scroll offset.
  ///
  /// For example, if [anchor] is 0.5 and the [AxisDirection] determined by
  /// [scrollDirection] and [reverse] is [AxisDirection.down] or
  /// [AxisDirection.up], then the zero scroll offset is vertically centered
  /// within the viewport. If the [anchor] is 1.0, and the axis direction is
  /// [AxisDirection.right], then the zero scroll offset is on the left edge of
  /// the viewport.
  ///
  /// Most scroll views by default are ordered [GrowthDirection.forward].
  /// Changing the default values of [ScrollView.anchor],
  /// [ScrollView.center], or both, can configure a scroll view for
  /// [GrowthDirection.reverse].
  ///
  /// {@tool dartpad}
  /// This sample shows a [CustomScrollView], with [Radio] buttons in the
  /// [AppBar.bottom] that change the [AxisDirection] to illustrate different
  /// configurations. The [CustomScrollView.anchor] and [CustomScrollView.center]
  /// properties are also set to have the 0 scroll offset positioned in the middle
  /// of the viewport, with [GrowthDirection.forward] and [GrowthDirection.reverse]
  /// illustrated on either side. The sliver that shares the
  /// [CustomScrollView.center] key is positioned at the [CustomScrollView.anchor].
  ///
  /// ** See code in examples/api/lib/rendering/growth_direction/growth_direction.0.dart **
  /// {@end-tool}
  final double anchor;

  /// The number of pixels to cache for preloading items.
  final double? cacheExtent;

  /// The number of children for semantic accessibility.
  final int? semanticChildCount;

  /// Defines the behavior when a drag starts.
  final DragStartBehavior dragStartBehavior;

  /// Determines how the keyboard should be dismissed when scrolling.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// The restoration ID used to restore scroll position.
  final String? restorationId;

  /// The clipping behavior for the list.
  final Clip clipBehavior;

  /// The builder for separators in `.separated` constructor.
  final NullableIndexedWidgetBuilder? separatorBuilder;

  final ScrollBehavior? scrollBehavior;

  /// Creates a [ScrollView] uses a single child layout model.
  final HitTestBehavior hitTestBehavior;

  /// A strategy function to determine when to show separators.
  final PageableSeparatorStrategy? separatorStrategy;

  /// Whether to automatically keep items alive.
  final bool addAutomaticKeepAlives;

  /// Whether to add repaint boundaries around items.
  final bool addRepaintBoundaries;

  /// Whether to add semantic indexes for accessibility.
  final bool addSemanticIndexes;

  /// Creates a scrollable, linear array of widgets that are created on demand.
  final ChildIndexGetter? findChildIndexCallback;

  /// Whether to apply a separator to the last item.
  final bool applySeparatorToLastItem;

  /// Creates a [PageableGridView] with pagination support.
  ///
  /// Use this constructor for a standard paged list without separators.
  const PageableGridView.builder({
    super.key,
    required this.controller,
    required this.gridDelegate,
    required this.builderDelegate,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0.0,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.scrollBehavior,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.findChildIndexCallback,
  }) : separatorBuilder = null, separatorStrategy = null, applySeparatorToLastItem = false;

  /// Creates a [PageableGridView] with pagination support and separators.
  ///
  /// Use this constructor when a separator is required between items.
  const PageableGridView.separated({
    super.key,
    required this.controller,
    required this.builderDelegate,
    required this.separatorBuilder,
    required this.gridDelegate,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0.0,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.scrollBehavior,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.separatorStrategy,
    this.addAutomaticKeepAlives = true,
    this.applySeparatorToLastItem = false,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.findChildIndexCallback,
  }) : semanticChildCount = null;

  /// Debug properties for [PagedListView].
  ///
  /// This helps in debugging by providing insights into the widget’s properties.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('pagingController', controller));
    properties.add(DiagnosticsProperty('builderDelegate', builderDelegate));
    properties.add(EnumProperty<Axis>('scrollDirection', scrollDirection));
    properties.add(FlagProperty('reverse', value: reverse, ifTrue: 'reversed'));
    properties.add(DiagnosticsProperty<ScrollController?>('scrollController', scrollController));
    properties.add(DiagnosticsProperty<bool?>('primary', primary));
    properties.add(DiagnosticsProperty<ScrollPhysics?>('physics', physics));
    properties.add(FlagProperty('shrinkWrap', value: shrinkWrap, ifTrue: 'shrinkWrap enabled'));
    properties.add(DiagnosticsProperty<Key?>('center', center));
    properties.add(DoubleProperty('anchor', anchor));
    properties.add(DoubleProperty('cacheExtent', cacheExtent));
    properties.add(IntProperty('semanticChildCount', semanticChildCount));
    properties.add(EnumProperty<DragStartBehavior>('dragStartBehavior', dragStartBehavior));
    properties.add(EnumProperty<ScrollViewKeyboardDismissBehavior>('keyboardDismissBehavior', keyboardDismissBehavior));
    properties.add(StringProperty('restorationId', restorationId));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties.add(DiagnosticsProperty<NullableIndexedWidgetBuilder?>('separatorBuilder', separatorBuilder));
    properties.add(DiagnosticsProperty<ScrollBehavior?>('scrollBehavior', scrollBehavior));
    properties.add(EnumProperty<HitTestBehavior>('hitTestBehavior', hitTestBehavior));
    properties.add(DiagnosticsProperty<SliverGridDelegate>('gridDelegate', gridDelegate));
    properties.add(DiagnosticsProperty<PageableSeparatorStrategy?>('separatorStrategy', separatorStrategy));
    properties.add(FlagProperty('addAutomaticKeepAlives', value: addAutomaticKeepAlives, ifTrue: 'keeps alive'));
    properties.add(FlagProperty('addRepaintBoundaries', value: addRepaintBoundaries, ifTrue: 'adds repaint boundaries'));
    properties.add(FlagProperty('addSemanticIndexes', value: addSemanticIndexes, ifTrue: 'adds semantic indexes'));
    properties.add(DiagnosticsProperty<ChildIndexGetter?>('findChildIndexCallback', findChildIndexCallback));
    properties.add(FlagProperty('applySeparatorToLastItem', value: applySeparatorToLastItem, ifTrue: 'apply separator to last item'));
  }

  @override
  Widget build(BuildContext context) => PageableLayoutBuilder(
    controller: controller,
    builderDelegate: builderDelegate,
    completedBuilder: (context, index, widgetBuilder, itemBuilder) => _build(index, widgetBuilder, itemBuilder, context),
    loadingBuilder: (context, index, widgetBuilder, itemBuilder) => _build(index, widgetBuilder, itemBuilder, context),
    errorBuilder: (context, index, widgetBuilder, itemBuilder) => _build(index, widgetBuilder, itemBuilder, context),
  );

  Widget _build(int count, WidgetBuilder? widgetBuilder, IndexedWidgetBuilder itemBuilder, BuildContext context) {
    bool hasSeparator = separatorBuilder.isNotNull;
    PageableSeparatorStrategy strategy = separatorStrategy ?? PageableHelper.defaultStrategy;
    int totalSeparators = hasSeparator
        ? PageableHelper.calculateTotalSeparators(strategy, separatorBuilder, context, count)
        : 0;
    int totalItemCount = (widgetBuilder != null ? count - 1 : count) + totalSeparators;
    // bool canShowSeparator(int index) => hasSeparator && totalSeparators.isGt(0) && strategy(index);

    bool canShowSeparator(int index) {
      final isLast = index == totalItemCount - 1;
      return hasSeparator && totalSeparators.isGt(0) && strategy(index) && (applySeparatorToLastItem || !isLast);
    }

    Widget? child(BuildContext context, int index) {
      int itemIndex = PageableHelper.getActualItemIndex(strategy, hasSeparator, index);

      if (canShowSeparator(index)) {
        return separatorBuilder!(context, itemIndex);
      }

      return itemBuilder(context, itemIndex);
    }
    
    return CustomScrollView(
      controller: scrollController,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      center: center,
      anchor: anchor,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      hitTestBehavior: hitTestBehavior,
      scrollBehavior: scrollBehavior,
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            child,
            findChildIndexCallback: findChildIndexCallback,
            childCount: totalItemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
            semanticIndexCallback: (Widget widget, int index) {
              return canShowSeparator(index) ? null : PageableHelper.getActualItemIndex(strategy, hasSeparator, index);
            },
          ),
          gridDelegate: gridDelegate,
        ),

        if(widgetBuilder != null) ...[
          SliverToBoxAdapter(child: widgetBuilder(context)),
        ]
      ],
    );
  }
}