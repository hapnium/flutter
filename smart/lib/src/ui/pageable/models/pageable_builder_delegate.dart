import 'package:flutter/cupertino.dart';
import 'package:smart/ui.dart';

/// A typedef for constructing a widget for a specific item in a list.
///
/// This function takes in a `BuildContext`, metadata about the item, an optional
/// extra index, and the current pagination status, and returns a `Widget`.
///
/// - [context] The `BuildContext` used for widget building.
/// - [metadata] The metadata associated with the item.
typedef ItemWidgetBuilder<ItemType> = Widget Function(BuildContext context, ItemMetadata<ItemType> metadata);

/// {@template pageable_builder_delegate}
/// A delegate class used for building children and state indicators in a paginated list view.
///
/// You can define custom UI for various pagination states, including:
/// - Item building
/// - Loading indicators
/// - Error states
/// - Empty list states
/// - End of list indicators
///
/// This delegate is commonly used with widgets like `PageableListView`, `PageableGridView`, etc.
///
/// Example:
/// ```dart
/// PageableBuilderDelegate<Product>(
///   itemBuilder: (context, product, index) => ProductCard(product),
///   firstPageProgressIndicatorBuilder: (context) => CircularProgressIndicator(),
///   newPageProgressIndicatorBuilder: (context) => CupertinoActivityIndicator(),
///   firstPageErrorIndicatorBuilder: (context) => Text("Failed to load items"),
///   noItemsFoundIndicatorBuilder: (context) => Text("No products found."),
/// )
/// ```
/// {@endtemplate}
class PageableBuilderDelegate<Item> {
  /// The number of invisible items remaining below the scroll viewport
  /// that should trigger the loading of a new page.
  ///
  /// This is used for scroll-based pagination.
  ///
  /// Defaults to `3`.
  ///
  /// Example: If set to 3, then when the user scrolls within 3 items from
  /// the bottom of the list, `fetchNextPage()` is triggered.
  final int invisibleItemsThreshold;

  /// The percentage of the viewport height that should trigger the loading of a new page.
  ///
  /// Defaults to `20`.
  /// 
  /// It must fall within the range of `0` to `100`.
  final int percentageThreshold;

  /// Builds a widget for each item in the paginated list.
  ///
  /// This is a **required** function and should return the item widget at a given index.
  ///
  /// Example:
  /// ```dart
  /// itemBuilder: (context, item, index) => ListTile(title: Text(item.title)),
  /// ```
  final ItemWidgetBuilder<Item> itemBuilder;

  /// Builds a loading indicator shown when the first page is being fetched.
  ///
  /// This is typically a spinner displayed while the initial data is loading.
  ///
  /// Return `null` to show nothing.
  ///
  /// Example:
  /// ```dart
  /// firstPageProgressIndicatorBuilder: (context) => Center(child: CircularProgressIndicator()),
  /// ```
  final WidgetBuilder? firstPageProgressIndicatorBuilder;

  /// Builds a loading indicator shown when additional pages are being fetched.
  ///
  /// Appears at the bottom of the list while more items are loading.
  ///
  /// Return `null` to show nothing.
  ///
  /// Example:
  /// ```dart
  /// newPageProgressIndicatorBuilder: (context) => Center(child: CupertinoActivityIndicator()),
  /// ```
  final WidgetBuilder? newPageProgressIndicatorBuilder;

  /// Builds a widget shown when the first page fails to load.
  ///
  /// Useful for showing retry buttons or error messages.
  ///
  /// Return `null` to skip showing an error UI.
  ///
  /// Example:
  /// ```dart
  /// firstPageErrorIndicatorBuilder: (context) => Center(child: Text("Failed to load data")),
  /// ```
  final WidgetBuilder? firstPageErrorIndicatorBuilder;

  /// Builds a widget shown when loading a new page fails.
  ///
  /// Displayed at the bottom of the list if pagination fails mid-scroll.
  ///
  /// Return `null` to skip the error widget.
  ///
  /// Example:
  /// ```dart
  /// newPageErrorIndicatorBuilder: (context) => Center(child: Text("Could not load more")),
  /// ```
  final WidgetBuilder? newPageErrorIndicatorBuilder;

  /// Builds a loading indicator shown when earlier pages are being fetched.
  ///
  /// Appears inline with the list while previous items are loading
  /// (see [PageableController.fetchPreviousPage]).
  ///
  /// Return `null` to show nothing.
  ///
  /// Example:
  /// ```dart
  /// previousPageProgressIndicatorBuilder: (context) => Center(child: CupertinoActivityIndicator()),
  /// ```
  final WidgetBuilder? previousPageProgressIndicatorBuilder;

  /// Builds a widget shown when loading an earlier page fails.
  ///
  /// Return `null` to skip the error widget.
  ///
  /// Example:
  /// ```dart
  /// previousPageErrorIndicatorBuilder: (context) => Center(child: Text("Could not load earlier items")),
  /// ```
  final WidgetBuilder? previousPageErrorIndicatorBuilder;

  /// Builds a widget shown when the data source returns no items.
  ///
  /// This is only called if the first page returns an empty list.
  ///
  /// Return `null` to show nothing.
  ///
  /// Example:
  /// ```dart
  /// noItemsFoundIndicatorBuilder: (context) => Center(child: Text("Nothing here")),
  /// ```
  final WidgetBuilder? noItemsFoundIndicatorBuilder;

  /// Builds a widget shown when there are no more pages to load.
  ///
  /// Typically shown as a footer or message indicating the end of content.
  ///
  /// Return `null` to omit this indicator.
  ///
  /// Example:
  /// ```dart
  /// noMoreItemsIndicatorBuilder: (context) => Center(child: Text("That's all!")),
  /// ```
  final WidgetBuilder? noMoreItemsIndicatorBuilder;

  /// Whether status transitions should be animated.
  /// 
  /// Defaults to `true`.
  final bool animateTransitions;

  /// The duration of animated transitions when [animateTransitions] is `true`.
  /// 
  /// Defaults to `Duration(milliseconds: 300)`.
  final Duration transitionDuration;

  /// {@macro pageable_builder_delegate}
  const PageableBuilderDelegate({
    required this.itemBuilder,
    this.percentageThreshold = 20,
    this.invisibleItemsThreshold = 3,
    this.firstPageProgressIndicatorBuilder,
    this.newPageProgressIndicatorBuilder,
    this.previousPageProgressIndicatorBuilder,
    this.firstPageErrorIndicatorBuilder,
    this.newPageErrorIndicatorBuilder,
    this.previousPageErrorIndicatorBuilder,
    this.noItemsFoundIndicatorBuilder,
    this.noMoreItemsIndicatorBuilder,
    this.animateTransitions = true,
    this.transitionDuration = const Duration(milliseconds: 300),
  }) : assert(percentageThreshold >= 0 && percentageThreshold <= 100, 'percentageThreshold must be between 0 and 100');
}