import 'package:flutter/widgets.dart';
import '../controller/pageable_controller.dart';
import '../models/pageable.dart';

/// Signature for builder functions that build a widget
/// based on the current pageable state and control callbacks.
///
/// This function type is used to build custom widgets
/// that react to pagination state changes.
///
/// Generic parameters:
/// - [PageKey]: The type of the page key used in pagination (e.g., int, String).
/// - [Item]: The type of the items being paginated.
///
/// Parameters:
/// - [context]: The current [BuildContext].
/// - [pageable]: The current [PageableView] state containing loaded pages, next page key,
///   loading and error flags, etc.
/// - [fetchFirstPage]: Callback to trigger fetching the first page of data.
/// - [fetchNextPage]: Callback to trigger fetching the next page of data.
/// - [retry]: Callback to retry a failed fetch request.
///
/// Returns a [Widget] that reflects the current pagination state.
///
/// Example:
/// ```dart
/// PageableLayoutWidgetBuilder<int, MyItem> builder = (context, pageable, fetchFirstPage, fetchNextPage, retry) {
///   if (pageable.status.isLoadingFirstPage) {
///     return const CircularProgressIndicator();
///   } else if (pageable.status.isFirstPageError) {
///     return ElevatedButton(
///       onPressed: retry,
///       child: const Text('Try Again'),
///     );
///   }
///   return ListView.builder(
///     itemCount: state.pages.values.fold(0, (sum, list) => sum + list.length),
///     itemBuilder: (context, index) {
///       final items = state.pages.values.expand((e) => e).toList();
///       return ListTile(title: Text(items[index].toString()));
///     },
///   );
/// };
/// ```
typedef PageableLayoutWidgetBuilder<PageKey, Item> = Widget Function(
  BuildContext context,
  PageableView<PageKey, Item> pageable,
  VoidCallback fetchFirstPage,
  VoidCallback fetchNextPage,
  VoidCallback retry,
);

/// {@template pageable_listener}
/// A widget that listens to a [PageableController] and rebuilds whenever the pagination state changes.
///
/// This is useful for integrating pagination logic (loading, errors, new items)
/// with custom UI widgets.
///
/// It uses a [ValueListenableBuilder] internally to react to changes in the [PageableController].
///
/// ### Example:
/// ```dart
/// PageableListener<int, Product>(
///   controller: controller,
///   builder: (context, pageable, fetchFirstPage, fetchNextPage, retry) {
///     if (pageable.status.isLoadingFirstPage) {
///       return Center(child: CircularProgressIndicator());
///     }
///
///     if (pageable.status.isFirstPageError) {
///       return Center(child: Text('Error: ${state.error}'));
///     }
///
///     final items = state.items;
///     return ListView.builder(
///       itemCount: items.length,
///       itemBuilder: (context, index) {
///         final product = items[index];
///         return ListTile(title: Text(product.name));
///       },
///     );
///   },
/// )
/// ```
/// {@endtemplate}
class PageableListener<PageKey, Item> extends StatelessWidget {
  /// The [PageableController] that holds the paginated state and notifies listeners when changed.
  final PageableController<PageKey, Item> controller;

  /// Called every time the controller's value changes.
  ///
  /// This function provides:
  /// - [context] - The build context
  /// - [state] - The current paginated state from the controller
  /// - [fetchNextPage] - A function you can call to trigger the next page fetch
  /// - [onTryAgain] - A function you can call to retry loading after an error
  final PageableLayoutWidgetBuilder<PageKey, Item> builder;

  /// {@macro pageable_listener}
  const PageableListener({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PageableView<PageKey, Item>>(
      valueListenable: controller,
      builder: (context, state, _) => builder(context, state, controller.fetchFirstPage, controller.fetchNextPage, controller.retry),
    );
  }
}