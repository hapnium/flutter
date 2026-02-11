import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/rendering.dart';
import 'package:hapnium/hapnium.dart' hide Page;

import '../builders/pageable_layout_builder.dart';
import '../controller/pageable_controller.dart';
import '../helpers/pageable_helper.dart';
import '../models/pageable_builder_delegate.dart';

/// A paginated staggered (masonry-like) view built with core Flutter widgets only.
///
/// This implementation does not rely on external packages. Items are distributed
/// across columns to produce a staggered appearance.
class PageableStaggeredView<Page, Item> extends StatelessWidget {
  /// The controller responsible for managing pagination.
  final PageableController<Page, Item> controller;

  /// Delegate used to build item widgets and status indicators.
  final PageableBuilderDelegate<Item> builderDelegate;

  /// Number of columns in the staggered layout.
  final int crossAxisCount;

  /// Horizontal spacing between columns.
  final double crossAxisSpacing;

  /// Vertical spacing between items in each column.
  final double mainAxisSpacing;

  /// Padding around the staggered content.
  final EdgeInsetsGeometry padding;

  /// The axis along which the view scrolls.
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  final bool reverse;

  /// The scroll controller used to manage scrolling.
  final ScrollController? scrollController;

  /// Whether this is the primary scroll view associated with user input.
  final bool? primary;

  /// Scroll physics for the view.
  final ScrollPhysics? physics;

  /// Whether the extent in the scrollDirection should be determined by contents.
  final bool shrinkWrap;

  /// The first child in the [GrowthDirection.forward] growth direction.
  final Key? center;

  /// Relative position of the zero scroll offset.
  final double anchor;

  /// The number of pixels to cache for preloading items.
  final double? cacheExtent;

  /// Number of children for semantic accessibility.
  final int? semanticChildCount;

  /// Defines the behavior when a drag starts.
  final DragStartBehavior dragStartBehavior;

  /// Determines how the keyboard should be dismissed when scrolling.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Restoration ID used to restore scroll position.
  final String? restorationId;

  /// Clipping behavior for the scroll view.
  final Clip clipBehavior;

  /// Custom scroll behavior.
  final ScrollBehavior? scrollBehavior;

  /// Hit test behavior.
  final HitTestBehavior hitTestBehavior;

  /// Optional separator builder.
  final NullableIndexedWidgetBuilder? separatorBuilder;

  /// Strategy function to determine when to show separators.
  final PageableSeparatorStrategy? separatorStrategy;

  /// Whether to apply separator to the last item.
  final bool applySeparatorToLastItem;

  const PageableStaggeredView._({
    super.key,
    required this.controller,
    required this.builderDelegate,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.padding,
    required this.scrollDirection,
    required this.reverse,
    required this.scrollController,
    required this.primary,
    required this.physics,
    required this.shrinkWrap,
    required this.center,
    required this.anchor,
    required this.cacheExtent,
    required this.semanticChildCount,
    required this.dragStartBehavior,
    required this.keyboardDismissBehavior,
    required this.restorationId,
    required this.clipBehavior,
    required this.scrollBehavior,
    required this.hitTestBehavior,
    required this.separatorBuilder,
    required this.separatorStrategy,
    required this.applySeparatorToLastItem,
  });

  /// Creates a [PageableStaggeredView] without separators.
  const PageableStaggeredView.builder({
    Key? key,
    required PageableController<Page, Item> controller,
    required PageableBuilderDelegate<Item> builderDelegate,
    int crossAxisCount = 2,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? scrollController,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
  }) : this._(
    key: key,
    controller: controller,
    builderDelegate: builderDelegate,
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
    padding: padding,
    scrollDirection: scrollDirection,
    reverse: reverse,
    scrollController: scrollController,
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
    scrollBehavior: scrollBehavior,
    hitTestBehavior: hitTestBehavior,
    separatorBuilder: null,
    separatorStrategy: null,
    applySeparatorToLastItem: false,
  );

  /// Creates a [PageableStaggeredView] with separators.
  const PageableStaggeredView.separated({
    Key? key,
    required PageableController<Page, Item> controller,
    required PageableBuilderDelegate<Item> builderDelegate,
    required NullableIndexedWidgetBuilder separatorBuilder,
    int crossAxisCount = 2,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? scrollController,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
    PageableSeparatorStrategy? separatorStrategy,
    bool applySeparatorToLastItem = false,
  }) : this._(
    key: key,
    controller: controller,
    builderDelegate: builderDelegate,
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
    padding: padding,
    scrollDirection: scrollDirection,
    reverse: reverse,
    scrollController: scrollController,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    center: center,
    anchor: anchor,
    cacheExtent: cacheExtent,
    semanticChildCount: null,
    dragStartBehavior: dragStartBehavior,
    keyboardDismissBehavior: keyboardDismissBehavior,
    restorationId: restorationId,
    clipBehavior: clipBehavior,
    scrollBehavior: scrollBehavior,
    hitTestBehavior: hitTestBehavior,
    separatorBuilder: separatorBuilder,
    separatorStrategy: separatorStrategy,
    applySeparatorToLastItem: applySeparatorToLastItem,
  );

  /// Creates a vertically scrolling [PageableStaggeredView].
  ///
  /// If [separatorBuilder] is provided, this behaves like `.separated`.
  const PageableStaggeredView.vertical({
    Key? key,
    required PageableController<Page, Item> controller,
    required PageableBuilderDelegate<Item> builderDelegate,
    NullableIndexedWidgetBuilder? separatorBuilder,
    int crossAxisCount = 2,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool reverse = false,
    ScrollController? scrollController,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
    PageableSeparatorStrategy? separatorStrategy,
    bool applySeparatorToLastItem = false,
  }) : this._(
    key: key,
    controller: controller,
    builderDelegate: builderDelegate,
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
    padding: padding,
    scrollDirection: Axis.vertical,
    reverse: reverse,
    scrollController: scrollController,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    center: center,
    anchor: anchor,
    cacheExtent: cacheExtent,
    semanticChildCount: separatorBuilder == null ? semanticChildCount : null,
    dragStartBehavior: dragStartBehavior,
    keyboardDismissBehavior: keyboardDismissBehavior,
    restorationId: restorationId,
    clipBehavior: clipBehavior,
    scrollBehavior: scrollBehavior,
    hitTestBehavior: hitTestBehavior,
    separatorBuilder: separatorBuilder,
    separatorStrategy: separatorStrategy,
    applySeparatorToLastItem: applySeparatorToLastItem,
  );

  /// Creates a horizontally scrolling [PageableStaggeredView].
  ///
  /// If [separatorBuilder] is provided, this behaves like `.separated`.
  const PageableStaggeredView.horizontal({
    Key? key,
    required PageableController<Page, Item> controller,
    required PageableBuilderDelegate<Item> builderDelegate,
    NullableIndexedWidgetBuilder? separatorBuilder,
    int crossAxisCount = 2,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool reverse = false,
    ScrollController? scrollController,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
    PageableSeparatorStrategy? separatorStrategy,
    bool applySeparatorToLastItem = false,
  }) : this._(
    key: key,
    controller: controller,
    builderDelegate: builderDelegate,
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
    padding: padding,
    scrollDirection: Axis.horizontal,
    reverse: reverse,
    scrollController: scrollController,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    center: center,
    anchor: anchor,
    cacheExtent: cacheExtent,
    semanticChildCount: separatorBuilder == null ? semanticChildCount : null,
    dragStartBehavior: dragStartBehavior,
    keyboardDismissBehavior: keyboardDismissBehavior,
    restorationId: restorationId,
    clipBehavior: clipBehavior,
    scrollBehavior: scrollBehavior,
    hitTestBehavior: hitTestBehavior,
    separatorBuilder: separatorBuilder,
    separatorStrategy: separatorStrategy,
    applySeparatorToLastItem: applySeparatorToLastItem,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('pagingController', controller));
    properties.add(DiagnosticsProperty('builderDelegate', builderDelegate));
    properties.add(IntProperty('crossAxisCount', crossAxisCount));
    properties.add(DoubleProperty('crossAxisSpacing', crossAxisSpacing));
    properties.add(DoubleProperty('mainAxisSpacing', mainAxisSpacing));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
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
    properties.add(DiagnosticsProperty<ScrollBehavior?>('scrollBehavior', scrollBehavior));
    properties.add(EnumProperty<HitTestBehavior>('hitTestBehavior', hitTestBehavior));
    properties.add(DiagnosticsProperty<NullableIndexedWidgetBuilder?>('separatorBuilder', separatorBuilder));
    properties.add(DiagnosticsProperty<PageableSeparatorStrategy?>('separatorStrategy', separatorStrategy));
    properties.add(FlagProperty('applySeparatorToLastItem', value: applySeparatorToLastItem, ifTrue: 'apply separator to last item'));
  }

  @override
  Widget build(BuildContext context) => PageableLayoutBuilder(
    controller: controller,
    builderDelegate: builderDelegate,
    completedBuilder: (context, count, widgetBuilder, itemBuilder) => _build(context, count, widgetBuilder, itemBuilder),
    loadingBuilder: (context, count, widgetBuilder, itemBuilder) => _build(context, count, widgetBuilder, itemBuilder),
    errorBuilder: (context, count, widgetBuilder, itemBuilder) => _build(context, count, widgetBuilder, itemBuilder),
  );

  Widget _build(
    BuildContext context,
    int count,
    WidgetBuilder? widgetBuilder,
    IndexedWidgetBuilder itemBuilder,
  ) {
    assert(crossAxisCount > 0, 'crossAxisCount must be greater than zero.');

    final hasSeparator = separatorBuilder.isNotNull;
    final strategy = separatorStrategy ?? PageableHelper.defaultStrategy;
    final totalSeparators = hasSeparator
        ? PageableHelper.calculateTotalSeparators(strategy, separatorBuilder, context, count)
        : 0;
    final baseItemCount = widgetBuilder != null ? count - 1 : count;
    final totalSlotCount = baseItemCount + totalSeparators;

    bool canShowSeparator(int index) {
      final isLast = index == totalSlotCount - 1;
      return hasSeparator && totalSeparators.isGt(0) && strategy(index) && (applySeparatorToLastItem || !isLast);
    }

    Widget resolveSlot(int index) {
      final itemIndex = PageableHelper.getActualItemIndex(strategy, hasSeparator, index);
      if (canShowSeparator(index)) {
        return separatorBuilder!(context, itemIndex) ?? const SizedBox.shrink();
      }
      return itemBuilder(context, itemIndex);
    }

    final columns = List<List<Widget>>.generate(crossAxisCount, (_) => <Widget>[]);
    int trackIndex = 0;

    for (int i = 0; i < totalSlotCount; i++) {
      final track = columns[trackIndex];
      if (track.isNotEmpty) {
        track.add(
          scrollDirection == Axis.vertical
              ? SizedBox(height: mainAxisSpacing)
              : SizedBox(width: mainAxisSpacing),
        );
      }
      track.add(resolveSlot(i));
      trackIndex = (trackIndex + 1) % crossAxisCount;
    }

    final content = Padding(
      padding: padding,
      child: scrollDirection == Axis.vertical ? _buildVerticalContent(columns) : _buildHorizontalContent(columns),
    );

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
        SliverToBoxAdapter(
          child: content,
        ),
        if (widgetBuilder != null) ...[
          SliverToBoxAdapter(child: widgetBuilder(context)),
        ],
      ],
    );
  }

  Widget _buildVerticalContent(List<List<Widget>> columns) {
    final rowChildren = <Widget>[];
    for (int index = 0; index < crossAxisCount; index++) {
      if (index > 0) {
        rowChildren.add(SizedBox(width: crossAxisSpacing));
      }
      rowChildren.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columns[index],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowChildren,
    );
  }

  Widget _buildHorizontalContent(List<List<Widget>> rows) {
    final columnChildren = <Widget>[];
    for (int index = 0; index < crossAxisCount; index++) {
      if (index > 0) {
        columnChildren.add(SizedBox(height: crossAxisSpacing));
      }
      columnChildren.add(
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows[index],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnChildren,
    );
  }
}