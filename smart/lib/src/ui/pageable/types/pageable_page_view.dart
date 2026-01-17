import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/rendering.dart';
import 'package:hapnium/hapnium.dart' hide Page;

import '../../models/floating_config.dart';
import '../builders/pageable_layout_builder.dart';
import '../controller/pageable_controller.dart';
import '../helpers/pageable_helper.dart';
import '../models/pageable_builder_delegate.dart';

/// A scrollable page view that supports pagination.
///
/// [PageablePageView] automatically handles fetching, displaying, and paginating
/// data using a [PageableController]. It supports horizontal and vertical page
/// scrolling and provides various customization options.
///
/// - [Page] represents the type of key used for pagination.
/// - [Item] represents the type of data displayed in the page view.
///
/// **Purpose:**
///
/// The [PageablePageView] widget simplifies the creation of paginated page views by
/// abstracting the complexities of data fetching and display. It provides
/// a flexible and efficient way to load and render large datasets in a
/// scrollable page view with page-by-page navigation.
///
/// **Usage:**
///
/// Use [PageablePageView] to create a scrollable page view that fetches and displays
/// data in pages. Provide a [PageableController] to manage the pagination logic
/// and a [PageableBuilderDelegate] to define how page items are built.
///
/// **Example:**
///
/// ```dart
/// PagedPageView<int, Item>(
///   controller: _pagedController,
///   builderDelegate: PagedChildBuilderDelegate<Item>(
///     itemBuilder: (context, item, index) => Center(child: Text(item.title)),
///   ),
/// )
/// ```
///
/// **Customization:**
///
/// You can customize the appearance and behavior of the [PageablePageView] by
/// providing a custom [PageController], [PageableBuilderDelegate], and
/// [PageableController]. The [PageableBuilderDelegate] allows you to define
/// how page items are built, while the [PageableController] manages the
/// pagination logic.
///
/// **Separated Pages:**
///
/// Use the [.separated] constructor to create a [PageablePageView] with separators
/// between pages. This constructor requires a [separatorBuilder] to define
/// how separators are built.
///
/// **Note:**
///
/// The [PageablePageView] widget is a specialized version of the [PageView] widget
/// that integrates with the [PageableController] for pagination support.
class PageablePageView<Page, Item> extends StatelessWidget {
  /// The controller responsible for managing pagination.
  final PageableController<Page, Item> controller;

  /// The builder delegate used to create list items.
  final PageableBuilderDelegate<Item> builderDelegate;

  /// Controls whether the widget's pages will respond to
  /// [RenderObject.showOnScreen], which will allow for implicit accessibility
  /// scrolling.
  ///
  /// With this flag set to false, when accessibility focus reaches the end of
  /// the current page and the user attempts to move it to the next element, the
  /// focus will traverse to the next widget outside of the page view.
  ///
  /// With this flag set to true, when accessibility focus reaches the end of
  /// the current page and user attempts to move it to the next element, focus
  /// will traverse to the next page in the page view.
  final bool allowImplicitScrolling;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// The [Axis] along which the scroll view's offset increases with each page.
  ///
  /// For the direction in which active scrolling may be occurring, see
  /// [ScrollDirection].
  ///
  /// Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// Whether the page view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the page view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the page view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this page
  /// view is scrolled.
  final PageController? pageController;

  /// How the page view should respond to user input.
  ///
  /// For example, determines how the page view continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [physics].
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// Set to false to disable page snapping, useful for custom scroll behavior.
  ///
  /// If the [padEnds] is false and [PageController.viewportFraction] < 1.0,
  /// the page will snap to the beginning of the viewport; otherwise, the page
  /// will snap to the center of the viewport.
  final bool pageSnapping;

  /// Called whenever the page in the center of the viewport changes.
  final ValueChanged<int>? onPageChanged;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scrollable.hitTestBehavior}
  ///
  /// Defaults to [HitTestBehavior.opaque].
  final HitTestBehavior hitTestBehavior;

  /// {@macro flutter.widgets.scrollable.scrollBehavior}
  ///
  /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
  /// modified by default to not apply a [Scrollbar].
  final ScrollBehavior? scrollBehavior;

  /// Whether to add padding to both ends of the list.
  ///
  /// If this is set to true and [PageController.viewportFraction] < 1.0, padding will be added
  /// such that the first and last child slivers will be in the center of
  /// the viewport when scrolled all the way to the start or end, respectively.
  ///
  /// If [PageController.viewportFraction] >= 1.0, this property has no effect.
  ///
  /// This property defaults to true.
  final bool padEnds;

  /// The builder for separators in `.separated` constructor.
  final NullableIndexedWidgetBuilder? separatorBuilder;

  /// A strategy function to determine when to show separators.
  final PageableSeparatorStrategy? separatorStrategy;

  /// How the children should be placed along the main axis.
  ///
  /// For example, [MainAxisAlignment.start], the default, places the children
  /// at the start (i.e., the left for a [Row] or the top for a [Column]) of the
  /// main axis.
  final MainAxisAlignment? mainAxisAlignment;

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  final MainAxisSize? mainAxisSize;

  /// How the children should be placed along the cross axis.
  ///
  /// For example, [CrossAxisAlignment.center], the default, centers the
  /// children in the cross axis (e.g., horizontally for a [Column]).
  ///
  /// When the cross axis is vertical (as for a [Row]) and the children
  /// contain text, consider using [CrossAxisAlignment.baseline] instead.
  /// This typically produces better visual results if the different children
  /// have text with different font metrics, for example because they differ in
  /// [TextStyle.fontSize] or other [TextStyle] properties, or because
  /// they use different fonts due to being written in different scripts.
  final CrossAxisAlignment? crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If [textDirection] is [TextDirection.rtl], then the direction in which
  /// text flows starts from right to left. Otherwise, if [textDirection] is
  /// [TextDirection.ltr], then the direction in which text flows starts from
  /// left to right.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// the children are positioned (left-to-right or right-to-left), and the
  /// meaning of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
  /// [MainAxisAlignment.end], or there's more than one child, then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  final TextDirection? textDirection;

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// Defaults to [VerticalDirection.down].
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  final VerticalDirection? verticalDirection;

  /// If aligning items according to their baseline, which baseline to use.
  ///
  /// This must be set if using baseline alignment. There is no default because there is no
  /// way for the framework to know the correct baseline _a priori_.
  final TextBaseline? textBaseline;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip? itemClipBehavior;

  /// {@macro flutter.rendering.RenderFlex.spacing}
  final double? spacing;

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  ///
  /// The non-positioned children are placed relative to each other such that
  /// the points determined by [alignment] are co-located. For example, if the
  /// [alignment] is [Alignment.topLeft], then the top left corner of
  /// each non-positioned child will be located at the same global coordinate.
  ///
  /// Partially-positioned children, those that do not specify an alignment in a
  /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
  /// alignment to determine how they should be positioned in that
  /// under-specified axis.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry? alignment;

  /// How to size the non-positioned children in the stack.
  ///
  /// The constraints passed into the [Stack] from its parent are either
  /// loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  final StackFit? fit;

  /// Configuration for the floating extra widgets.
  ///
  /// Defaults to null.
  final FloatingConfig? floatConfig;

  /// Whether to use a [Stack] or a [PageView].
  final bool useStack;

  /// Whether to apply a separator to the last item.
  final bool applySeparatorToLastItem;

  /// Creates a [PageablePageView] with pagination support.
  ///
  /// Use this constructor for a standard paged list without separators.
  const PageablePageView.builder({
    super.key,
    required this.controller,
    required this.builderDelegate,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.pageController,
    this.allowImplicitScrolling = false,
    this.physics,
    this.padEnds = true,
    this.pageSnapping = true,
    this.onPageChanged,
    this.scrollBehavior,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
    this.spacing,
  }) : separatorBuilder = null,
    useStack = false,
    separatorStrategy = null,
    alignment = null,
    fit = null,
    floatConfig = null,
    itemClipBehavior = null,
    applySeparatorToLastItem = false;

  /// Creates a [PageablePageView] with pagination support and separators.
  ///
  /// Use this constructor when a separator is required between items.
  const PageablePageView.separated({
    super.key,
    required this.controller,
    required this.builderDelegate,
    required this.separatorBuilder,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.pageController,
    this.allowImplicitScrolling = false,
    this.physics,
    this.padEnds = true,
    this.pageSnapping = true,
    this.onPageChanged,
    this.scrollBehavior,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.separatorStrategy,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
    this.spacing,
    this.applySeparatorToLastItem = false
  }) : useStack = false, alignment = null, fit = null, floatConfig = null, itemClipBehavior = null;

  /// Creates a [PageablePageView] with pagination support.
  ///
  /// Use this constructor for a standard paged list without separators.
  const PageablePageView.stackBuilder({
    super.key,
    required this.controller,
    required this.builderDelegate,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.pageController,
    this.allowImplicitScrolling = false,
    this.physics,
    this.padEnds = true,
    this.pageSnapping = true,
    this.onPageChanged,
    this.scrollBehavior,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.textDirection,
    this.itemClipBehavior,
    this.alignment,
    this.fit,
    this.floatConfig
  }) : separatorBuilder = null,
    useStack = true,
    spacing = null,
    textBaseline = null,
    verticalDirection = null,
    separatorStrategy = null,
    crossAxisAlignment = null,
    mainAxisAlignment = null,
    applySeparatorToLastItem = false,
    mainAxisSize = null;

  /// Creates a [PageablePageView] with pagination support and separators.
  ///
  /// Use this constructor when a separator is required between items.
  const PageablePageView.stackSeparated({
    super.key,
    required this.controller,
    required this.builderDelegate,
    required this.separatorBuilder,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.pageController,
    this.allowImplicitScrolling = false,
    this.physics,
    this.padEnds = true,
    this.pageSnapping = true,
    this.onPageChanged,
    this.scrollBehavior,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.separatorStrategy,
    this.textDirection,
    this.itemClipBehavior,
    this.alignment,
    this.fit,
    this.floatConfig,
    this.applySeparatorToLastItem = false
  }) : useStack = true,
      spacing = null,
      textBaseline = null,
      verticalDirection = null,
      crossAxisAlignment = null,
      mainAxisAlignment = null,
      mainAxisSize = null;

  /// Debug properties for [PageablePageView].
  ///
  /// This helps in debugging by providing insights into the widget’s properties.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('pagingController', controller));
    properties.add(DiagnosticsProperty('builderDelegate', builderDelegate));
    properties.add(EnumProperty<Axis>('scrollDirection', scrollDirection));
    properties.add(FlagProperty('reverse', value: reverse, ifTrue: 'reversed'));
    properties.add(DiagnosticsProperty<ScrollController?>('pageController', pageController));
    properties.add(DiagnosticsProperty<ScrollPhysics?>('physics', physics));
    properties.add(EnumProperty<DragStartBehavior>('dragStartBehavior', dragStartBehavior));
    properties.add(StringProperty('restorationId', restorationId));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties.add(DiagnosticsProperty<NullableIndexedWidgetBuilder?>('separatorBuilder', separatorBuilder));
    properties.add(EnumProperty<HitTestBehavior>('hitTestBehavior', hitTestBehavior));
    properties.add(DiagnosticsProperty<PageableSeparatorStrategy?>('separatorStrategy', separatorStrategy));
    properties.add(FlagProperty('allowImplicitScrolling', value: allowImplicitScrolling, ifTrue: 'allowImplicitScrolling enabled'));
    properties.add(FlagProperty('pageSnapping', value: pageSnapping, ifTrue: 'pageSnapping enabled'));
    properties.add(FlagProperty('padEnds', value: padEnds, ifTrue: 'padEnds enabled'));
    properties.add(DiagnosticsProperty<ScrollBehavior?>('scrollBehavior', scrollBehavior));
    properties.add(DiagnosticsProperty<ValueChanged<int>?>('onPageChanged', onPageChanged));
    properties.add(DiagnosticsProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
    properties.add(DiagnosticsProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
    properties.add(DiagnosticsProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
    properties.add(DiagnosticsProperty<TextDirection?>('textDirection', textDirection));
    properties.add(DiagnosticsProperty<VerticalDirection>('verticalDirection', verticalDirection));
    properties.add(DiagnosticsProperty<TextBaseline?>('textBaseline', textBaseline));
    properties.add(EnumProperty<Clip>('itemClipBehavior', itemClipBehavior));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(DiagnosticsProperty<AlignmentGeometry?>('alignment', alignment));
    properties.add(EnumProperty<StackFit?>('fit', fit));
    properties.add(DiagnosticsProperty<FloatingConfig?>('floatConfig', floatConfig));
    properties.add(FlagProperty('useStack', value: useStack, ifTrue: 'useStack enabled'));
    properties.add(FlagProperty('applySeparatorToLastItem', value: applySeparatorToLastItem, ifTrue: 'applySeparatorToLastItem enabled'));
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
      Widget? child;

      int itemIndex = PageableHelper.getActualItemIndex(strategy, hasSeparator, index);
      bool isLastItem = index == totalItemCount - 1;

      if (canShowSeparator(index)) {
        child = separatorBuilder!(context, itemIndex);
      } else {
        child = itemBuilder(context, itemIndex);
      }

      if(child.isNotNull) {
        if(useStack) {
          final FloatingConfig config = floatConfig ?? FloatingConfig();
          Positioned positioned(Widget child) => Positioned(
            left: config.left,
            right: config.right,
            top: config.top,
            bottom: config.bottom,
            height: config.height,
            width: config.width,
            child: child,
          );

          return Stack(
            fit: fit ?? StackFit.loose,
            alignment: alignment ?? AlignmentDirectional.topStart,
            clipBehavior: itemClipBehavior ?? Clip.hardEdge,
            children: [
              child!,
              if(isLastItem && widgetBuilder != null) ...[
                positioned(widgetBuilder(context))
              ]
            ],
          );
        } else {
          return Column(
            spacing: spacing ?? 0.0,
            verticalDirection: verticalDirection ?? VerticalDirection.down,
            textDirection: textDirection,
            textBaseline: textBaseline,
            mainAxisSize: mainAxisSize ?? MainAxisSize.max,
            crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
            mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
            children: [
              Expanded(child: child!),
              if(isLastItem && widgetBuilder != null) ...[
                widgetBuilder(context)
              ]
            ]
          );
        }
      }

      return null;
    }

    return PageView.builder(
      controller: pageController,
      scrollDirection: scrollDirection,
      reverse: reverse,
      allowImplicitScrolling: allowImplicitScrolling,
      onPageChanged: onPageChanged,
      physics: physics,
      dragStartBehavior: dragStartBehavior,
      hitTestBehavior: hitTestBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      scrollBehavior: scrollBehavior,
      padEnds: padEnds,
      pageSnapping: pageSnapping,
      itemCount: totalItemCount,
      itemBuilder: child,
    );
  }
}