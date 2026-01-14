import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart/ui.dart' show ItemMetadata;

import '../models/pageable.dart';
import '../models/pageable_status.dart';
import '../models/pageable_builder_delegate.dart';
import 'pageable_builder_animator.dart';
import 'pageable_indicators.dart';

/// Signature for layout builders that receive the total item count,
/// an optional indicator builder, and the item builder.
///
/// Used to build a paginated list/grid UI with optional loading or error indicators.
///
/// Parameters:
/// - [context]: The build context.
/// - [itemCount]: The total number of items to be displayed.
/// - [indicatorBuilder]: Optional builder for loading/error indicators, may be null.
/// - [itemBuilder]: Builder for individual items given their index.
///
/// Returns a [Widget] representing the entire pageable layout.
///
/// Example:
/// ```dart
/// PageableStatusWidgetBuilder<MyItem> builder = (context, itemCount, indicatorBuilder, itemBuilder) {
///   return ListView.builder(
///     itemCount: itemCount + (indicatorBuilder != null ? 1 : 0),
///     itemBuilder: (context, index) {
///       if (index == itemCount && indicatorBuilder != null) {
///         return indicatorBuilder(context);
///       }
///       return itemBuilder(context, index);
///     },
///   );
/// };
/// ```
typedef PageableStatusWidgetBuilder<Item> = Widget Function(
  BuildContext context,
  int itemCount,
  WidgetBuilder? indicatorBuilder,
  IndexedWidgetBuilder itemBuilder,
);

/// {@template pageable_builder}
/// Widget that builds UI based on the current [PageableView] state using
/// delegate and layout builder patterns.
///
/// It handles rendering items, loading indicators, error indicators,
/// and completion states in a paginated list or grid.
///
/// Generic parameters:
/// - [PageKey]: The type used for page keys in pagination (e.g., int, String).
/// - [Item]: The type of items being paginated.
///
/// Required parameters:
/// - [pageable]: The current pageable state including loaded pages and metadata.
/// - [fetchFirstPage]: Callback to trigger fetching the first page of items.
/// - [fetchNextPage]: Callback to trigger fetching the next page of items.
/// - [retry]: Callback to retry loading after an error.
/// - [builderDelegate]: Provides [itemBuilder] for items rendering.
/// - [loadingBuilder]: Builds the UI when loading more items (beyond the first page).
/// - [errorBuilder]: Builds the UI when there is an error loading more items.
/// - [completedBuilder]: Builds the UI when all pages are loaded.
///
/// Example usage:
/// ```dart
/// PageableBuilder<int, MyItem>(
///   pageable: pageable,
///   fetchFirstPage: () => controller.fetchFirstPage(),
///   fetchNextPage: () => controller.fetchNextPage(),
///   retry: () => controller.retry(),
///   builderDelegate: MyItemDelegate(),
///   loadingBuilder: myLoadingBuilder,
///   errorBuilder: myErrorBuilder,
///   completedBuilder: myCompletedBuilder,
/// )
/// ```
/// 
/// {@endtemplate}
class PageableBuilder<PageKey, Item> extends StatefulWidget {
  /// The current pageable state holding loaded pages and related metadata.
  ///
  /// This includes the list of loaded items, current page key, and status flags
  /// such as whether more pages are available or if an error occurred.
  final PageableView<PageKey, Item> pageable;

  /// Callback to trigger fetching the first page of items.
  ///
  /// Typically used to initiate or refresh the entire list from the beginning.
  final VoidCallback fetchFirstPage;

  /// Callback to trigger fetching the next page of items.
  ///
  /// Invoked when the user scrolls to the bottom or when more data is required.
  final VoidCallback fetchNextPage;

  /// Callback to retry loading items after an error has occurred.
  ///
  /// Used when a previously failed fetch attempt should be retried.
  final VoidCallback retry;

  /// Delegate responsible for building widgets for each individual item.
  ///
  /// Used to render the list content based on the current pageable data.
  final PageableBuilderDelegate<Item> builderDelegate;

  /// Builder for the loading state shown when additional pages are being fetched.
  ///
  /// This can be used to show a loading spinner or placeholder at the end of the list.
  final PageableStatusWidgetBuilder<Item> loadingBuilder;

  /// Builder for the error state shown when loading additional pages fails.
  ///
  /// Allows customization of the UI shown when a fetch operation encounters an error.
  final PageableStatusWidgetBuilder<Item> errorBuilder;

  /// Builder for the completed state when there are no more pages left to load.
  ///
  /// Use this to indicate to users that all content has been loaded.
  final PageableStatusWidgetBuilder<Item> completedBuilder;

  /// Creates a [PageableBuilder].
  ///
  /// {@macro pageable_builder}
  ///
  /// All parameters are required and must not be null.
  const PageableBuilder({
    super.key,
    required this.pageable,
    required this.builderDelegate,
    required this.fetchFirstPage,
    required this.fetchNextPage,
    required this.retry,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.completedBuilder,
  });

  @override
  State<PageableBuilder<PageKey, Item>> createState() => _PageableBuilderState<PageKey, Item>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DiagnosticsProperty<PageableView<PageKey, Item>>('pageable', pageable));
    properties.add(DiagnosticsProperty<PageableBuilderDelegate<Item>>('builderDelegate', builderDelegate));
    properties.add(DiagnosticsProperty<PageableStatusWidgetBuilder<Item>>('loadingBuilder', loadingBuilder));
    properties.add(DiagnosticsProperty<PageableStatusWidgetBuilder<Item>>('errorBuilder', errorBuilder));
    properties.add(DiagnosticsProperty<PageableStatusWidgetBuilder<Item>>('completedBuilder', completedBuilder));

    super.debugFillProperties(properties);
  }
}

class _PageableBuilderState<PageKey, Item> extends State<PageableBuilder<PageKey, Item>> {
  /// Tracks if we've requested the next page for the current state
  bool _hasRequestedNextPage = false;

  @protected
  PageableView<PageKey, Item> get value => widget.pageable;

  @protected
  PageableBuilderDelegate<Item> get delegate => widget.builderDelegate;

  @protected
  VoidCallback get fetchNextPage => () => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    widget.fetchNextPage();
  });

  @protected
  WidgetBuilder get firstPageErrorBuilder => delegate.firstPageErrorIndicatorBuilder ?? (_) => FirstPageErrorIndicator(
    onTryAgain: widget.retry,
  );

  @protected
  WidgetBuilder get newPageErrorBuilder => delegate.newPageErrorIndicatorBuilder ?? (_) => NewPageErrorIndicator(
    onTap: widget.retry,
  );

  @protected
  WidgetBuilder get firstPageProgressBuilder => delegate.firstPageProgressIndicatorBuilder ?? (_) => FirstPageProgressIndicator();

  @protected
  WidgetBuilder get newPageProgressBuilder => delegate.newPageProgressIndicatorBuilder ?? (_) => NewPageProgressIndicator();

  @protected
  WidgetBuilder get noItemsFoundBuilder => delegate.noItemsFoundIndicatorBuilder ?? (_) => NoItemsFoundIndicator();

  @protected
  WidgetBuilder get noMoreItemsBuilder => delegate.noMoreItemsIndicatorBuilder ?? (_) => SizedBox.shrink();

  @protected
  ItemWidgetBuilder<Item> get itemBuilder => delegate.itemBuilder;

  @protected
  int get invisibleItemsThreshold => delegate.invisibleItemsThreshold;

  @protected
  List<Item> get list => value.items;

  @protected
  int get itemCount => list.length;

  @protected
  bool get hasNextPage => value.hasNextPage;

  @protected
  double get percentageThreshold => delegate.percentageThreshold / 100;

  @override
  void didUpdateWidget(covariant PageableBuilder<PageKey, Item> oldWidget) {
    // Reset the request flag when:
    // 1. Status changes to a loaded state AND we have new items
    // 2. Status becomes completed (no more pages)
    // 3. There's an error (so we can retry)
    if (oldWidget.pageable != widget.pageable) {
      final newStatus = value.status;
      final oldItemCount = oldWidget.pageable.itemCount;
      final newItemCount = value.itemCount;
      
      // Reset flag when we get new items or status changes significantly
      if (newItemCount > oldItemCount || newStatus.isCompleted || newStatus.isLoadingMoreError || newStatus.isFirstPageError || newStatus.isLoaded) {
        _hasRequestedNextPage = false;
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  /// Handle scroll notifications to detect when we're near the end
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (!hasNextPage || _hasRequestedNextPage || value.status.isLoadingMore || value.status.isCompleted) {
        return false;
      }

      final metrics = notification.metrics;
      
      // Calculate remaining scroll distance
      final remainingDistance = metrics.maxScrollExtent - metrics.pixels;
      
      // Use viewport dimension as a more accurate threshold
      final threshold = metrics.viewportDimension * percentageThreshold;
      
      if (remainingDistance <= threshold) {
        _hasRequestedNextPage = true;
        
        if(value.showLog) {
          debugPrint('Triggering next page fetch - remaining: $remainingDistance, threshold: $threshold, viewport: ${metrics.viewportDimension}');
        }
        
        fetchNextPage();
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: PageableBuilderAnimator(
        animateTransitions: delegate.animateTransitions,
        transitionDuration: delegate.transitionDuration,
        child: switch (value.status) {
          PageableStatus.LOADING_FIRST_PAGE => firstPageProgressBuilder(context),
          PageableStatus.FIRST_PAGE_ERROR => firstPageErrorBuilder(context),
          PageableStatus.NO_ITEMS_FOUND => noItemsFoundBuilder(context),
          PageableStatus.LOADING_NEW_PAGE => widget.loadingBuilder(
            context,
            itemCount,
            newPageProgressBuilder,
            (context, index) => _buildItem(context, index, list),
          ),
          PageableStatus.NEW_PAGE_ERROR => widget.errorBuilder(
            context,
            itemCount,
            newPageErrorBuilder,
            (context, index) => _buildItem(context, index, list),
          ),
          PageableStatus.COMPLETED || PageableStatus.LOADED_PAGE => widget.completedBuilder(
            context,
            itemCount,
            // Only show "no more items" indicator when actually completed
            value.status == PageableStatus.COMPLETED ? noMoreItemsBuilder : null,
            (context, index) => _buildItem(context, index, list),
          ),
        },
      ),
    );
  }

  /// Builds a list item and triggers page fetching when nearing the end
  Widget _buildItem(BuildContext context, int index, List<Item> items) {
    // Handle indicator at the end
    if (index >= itemCount) {
      return const SizedBox.shrink();
    }

    ItemMetadata<Item> metadata = ItemMetadata(
      isFirst: index == 0,
      isLast: index == (itemCount - 1),
      index: index,
      totalItems: itemCount,
      item: items[index],
    );

    return itemBuilder(context, metadata);
  }
}