import 'package:hapnium/hapnium.dart';

import 'pageable_status.dart';
import 'page_result.dart';

/// {@template pageable}
/// Data model representing paginated data.
///
/// This class holds a collection of [PageResult]s and tracks the current
/// status, errors, and pagination metadata. It provides helper methods
/// for accessing loaded items, pagination state, and error info.
///
/// [PageKey] represents the type of the page key (e.g., int, String).
/// [Item] represents the type of each item in the pages.
///
/// Example:
/// ```dart
/// final pageable = Pageable<int, User>.initial(pageSize: 20);
///
/// if (pageable.isLoading) {
///   return CircularProgressIndicator();
/// }
///
/// final users = pageable.items;
/// ``` 
/// 
/// {@endtemplate}
class PageableView<PageKey, Item> with EqualsAndHashCode {
  /// List of page results, in the order they were fetched.
  final List<PageResult<PageKey, Item>> pages;
  
  /// Current loading/error status of the pageable data.
  final PageableStatus status;
  
  /// Error information if a fetch operation failed.
  final dynamic error;
  
  /// Optional stack trace associated with the error.
  final StackTrace? stackTrace;
  
  /// Key for the next page to load, or `null` if no more pages or unknown.
  final PageKey? nextPageKey;
  
  /// Flag indicating whether to show debug logs.
  final bool showLog;
  
  /// Page size used for calculating pagination boundaries (optional).
  final int? pageSize;
  
  /// Creates a [PageableView] with the given parameters.
  /// 
  /// {@macro pageable}
  const PageableView({
    required this.pages,
    required this.status,
    this.error,
    this.stackTrace,
    this.nextPageKey,
    this.showLog = false,
    this.pageSize,
  });
  
  /// Creates an initial empty [PageableView] with no loaded pages.
  ///
  /// [showLog] enables debug logging.
  /// [pageSize] optionally defines the page size for pagination logic.
  /// 
  /// {@macro pageable}
  factory PageableView.initial({
    bool showLog = false,
    int? pageSize,
  }) {
    return PageableView<PageKey, Item>(
      pages: [],
      status: PageableStatus.LOADING_FIRST_PAGE,
      showLog: showLog,
      pageSize: pageSize,
    );
  }
  
  /// Creates a [PageableView] from an existing list of [PageResult]s.
  ///
  /// Automatically sets the status to [PageableStatus.NO_ITEMS_FOUND]
  /// if no items are found, otherwise [PageableStatus.LOADED_PAGE].
  /// 
  /// {@macro pageable}
  factory PageableView.fromPages({
    required List<PageResult<PageKey, Item>> pages,
    PageKey? nextPageKey,
    bool showLog = false,
    int? pageSize,
  }) {
    final allItems = pages.expand((result) => result.items).toList();
    final status = allItems.isEmpty ? PageableStatus.NO_ITEMS_FOUND : PageableStatus.LOADED_PAGE;
    
    return PageableView<PageKey, Item>(
      pages: List.from(pages),
      status: status,
      nextPageKey: nextPageKey,
      showLog: showLog,
      pageSize: pageSize,
    );
  }
  
  /// Returns all loaded items as a flat list in page order.
  List<Item> get items => pages.expand((result) => result.items).toList();
  
  /// Total number of loaded items across all pages.
  int get itemCount => items.length;
  
  /// Number of pages currently loaded.
  int get pageCount => pages.length;
  
  /// Whether any data has been loaded (at least one item).
  bool get hasData => pages.isNotEmpty && items.isNotEmpty;
  
  /// Whether there are more pages to load.
  ///
  /// Returns true if [nextPageKey] is non-null or if the last page
  /// contains as many items as the [pageSize], suggesting more data.
  bool get hasNextPage {
    if (nextPageKey != null) return true;
    
    if (pageSize != null && pages.isNotEmpty) {
      final lastPage = pages.last;
      // If last page contains fewer items than pageSize, no more pages.
      return lastPage.items.length >= pageSize!;
    }
    
    return false;
  }
  
  /// Whether a loading operation is currently ongoing.
  bool get isLoading => status.isLoading;
  
  /// Whether the pageable currently has an error.
  bool get hasError => status.hasError;
  
  /// Whether the pageable is empty (no items found and not loading).
  bool get isEmpty => status.isNoItemsFound;
  
  /// Whether additional pages can be loaded.
  bool get canLoadMore => hasNextPage && status.canLoadMore;
  
  /// Returns the first loaded page, or `null` if none.
  PageResult<PageKey, Item>? get firstPage => pages.isNotEmpty ? pages.first : null;
  
  /// Returns the last loaded page, or `null` if none.
  PageResult<PageKey, Item>? get lastPage => pages.isNotEmpty ? pages.last : null;
  
  /// Returns the page key of the first loaded page.
  PageKey? get firstPageKey => firstPage?.pageKey;
  
  /// Returns the page key of the last loaded page.
  PageKey? get lastPageKey => lastPage?.pageKey;
  
  /// Returns the total item count from the most recent page that provides it.
  ///
  /// Useful for progress indicators or UI showing total results.
  int? get totalCount {
    for (final result in pages.reversed) {
      if (result.totalCount != null) {
        return result.totalCount;
      }
    }
    return null;
  }
  
  /// Creates a copy of this [PageableView] with updated properties.
  ///
  /// Set [clearError] to true to clear error and stack trace.
  /// 
  /// {@macro pageable}
  PageableView<PageKey, Item> copyWith({
    List<PageResult<PageKey, Item>>? pages,
    PageableStatus? status,
    dynamic error,
    StackTrace? stackTrace,
    PageKey? nextPageKey,
    bool? showLog,
    int? pageSize,
    bool clearError = false,
  }) {
    return PageableView<PageKey, Item>(
      pages: pages ?? List.from(this.pages),
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      stackTrace: clearError ? null : (stackTrace ?? this.stackTrace),
      nextPageKey: nextPageKey ?? this.nextPageKey,
      showLog: showLog ?? this.showLog,
      pageSize: pageSize ?? this.pageSize,
    );
  }
  
  /// Resets the pageable to its initial empty state.
  /// 
  /// {@macro pageable}
  PageableView<PageKey, Item> reset() {
    return PageableView<PageKey, Item>(
      pages: [],
      status: PageableStatus.LOADING_FIRST_PAGE,
      showLog: showLog,
      pageSize: pageSize,
    );
  }
  
  /// Returns a specific page result by its [pageKey], or `null` if not found.
  PageResult<PageKey, Item>? getPage(PageKey pageKey) => pages.where((r) => r.pageKey == pageKey).firstOrNull;
  
  @override
  String toString() {
    return 'Pageable(pages: ${pages.length}, status: $status, itemCount: $itemCount, hasNextPage: $hasNextPage)';
  }

  @override
  List<Object?> equalizedProperties() => [pages, status, nextPageKey, error, showLog, pageSize];
}