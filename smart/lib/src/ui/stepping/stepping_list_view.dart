import 'package:flutter/material.dart';

import 'stepping.dart';

/// A customizable ListView that renders a list of [Stepping] widgets.
///
/// Supports all major flavors of [ListView] such as [ListView.builder],
/// [ListView.separated], and the default [ListView] with children.
///
/// Automatically manages whether to show the bottom line of each step based
/// on its position in the list.
class SteppingListView extends StatelessWidget {
  /// A list of [Stepping] widgets.
  final List<Stepping> children;

  /// Scroll direction of the list.
  final Axis scrollDirection;

  /// Whether the list should be reversed.
  final bool reverse;

  /// Controller for the scroll view.
  final ScrollController? controller;

  /// Whether the scroll view is primary.
  final bool? primary;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// Whether the list should shrink-wrap its content.
  final bool shrinkWrap;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Optional separator between each step.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Optional builder callback for custom list rendering.
  final bool useBuilder;

  /// Whether to use `ListView.separated` or not.
  final bool useSeparated;

  /// Optional item extent for fixed-height items.
  final double? itemExtent;

  /// Optional cache extent for the list.
  final double? cacheExtent;

  /// Optional restoration ID for state restoration.
  final String? restorationId;

  /// Optional keyboard dismiss behavior.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Optional clip behavior.
  final Clip clipBehavior;

  /// Constructor for [SteppingListView].
  const SteppingListView({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.separatorBuilder,
    this.useBuilder = false,
    this.useSeparated = false,
    this.itemExtent,
    this.cacheExtent,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  });

  /// Constructor for a separated [SteppingListView].
  const SteppingListView.separated({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.separatorBuilder,
    this.cacheExtent,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : useSeparated = true, useBuilder = false, itemExtent = null;

  /// Constructor for a builder [SteppingListView].
  const SteppingListView.builder({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.cacheExtent,
    this.restorationId,
    this.itemExtent,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : useSeparated = false, useBuilder = true, separatorBuilder = null;

  @override
  Widget build(BuildContext context) {
    if (useSeparated && separatorBuilder != null) {
      return ListView.separated(
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: children.length,
        itemBuilder: (context, index) {
          return _buildStepping(index);
        },
        separatorBuilder: separatorBuilder!,
        cacheExtent: cacheExtent,
        restorationId: restorationId,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
      );
    }

    if (useBuilder) {
      return ListView.builder(
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: children.length,
        itemBuilder: (context, index) {
          return _buildStepping(index);
        },
        itemExtent: itemExtent,
        cacheExtent: cacheExtent,
        restorationId: restorationId,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
      );
    }

    return ListView(
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      children: List.generate(children.length, _buildStepping),
      itemExtent: itemExtent,
      cacheExtent: cacheExtent,
      restorationId: restorationId,
      keyboardDismissBehavior: keyboardDismissBehavior,
      clipBehavior: clipBehavior,
    );
  }

  Widget _buildStepping(int index) {
    final stepping = children[index];
    final bool showLine = index != children.length - 1;

    // Return a modified clone of the stepping with showBottomLine overridden
    return Stepping(
      key: stepping.key,
      title: stepping.title,
      child: stepping.child,
      lineColor: stepping.lineColor,
      titleColor: stepping.titleColor,
      titleSize: stepping.titleSize,
      titleWeight: stepping.titleWeight,
      description: stepping.description,
      descriptionColor: stepping.descriptionColor,
      descriptionSize: stepping.descriptionSize,
      descriptionWeight: stepping.descriptionWeight,
      startWithTitle: stepping.startWithTitle,
      showTopLine: stepping.showTopLine,
      showBottomLine: showLine,
      topLineHeight: stepping.topLineHeight,
      lineWidth: stepping.lineWidth,
      lineSpacing: stepping.lineSpacing,
      spacing: stepping.spacing,
      opacity: stepping.opacity,
      titlePadding: stepping.titlePadding,
      indicatorRadius: stepping.indicatorRadius,
      indicatorPadding: stepping.indicatorPadding,
      direction: stepping.direction,
      mainAxisAlignment: stepping.mainAxisAlignment,
      mainAxisSize: stepping.mainAxisSize,
      crossAxisAlignment: stepping.crossAxisAlignment,
      lineMainAxisAlignment: stepping.lineMainAxisAlignment,
      lineMainAxisSize: stepping.lineMainAxisSize,
      lineCrossAxisAlignment: stepping.lineCrossAxisAlignment,
      contentMainAxisAlignment: stepping.contentMainAxisAlignment,
      contentMainAxisSize: stepping.contentMainAxisSize,
      contentCrossAxisAlignment: stepping.contentCrossAxisAlignment,
      contentSpacing: stepping.contentSpacing,
      width: stepping.width,
      indicator: stepping.indicator,
    );
  }
}