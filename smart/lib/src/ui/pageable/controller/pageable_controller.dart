import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:smart/exceptions.dart';

import '../helpers/pageable_logger.dart';
import '../models/pageable.dart';
import '../models/pageable_status.dart';
import '../models/page_result.dart';

/// Callback function to fetch a page of items asynchronously or synchronously.
///
/// [PageKey] is the type identifying the page to fetch.
/// Returns a [Future] or direct [List<Item>] for the given [pageKey].
typedef PageableCallback<PageKey, Item> = FutureOr<List<Item>> Function(PageKey pageKey);

/// Function that generates the next page key based on the current page info.
///
/// Takes:
/// - [currentPageKey]: The key of the page just fetched.
/// - [currentPageItems]: The list of items retrieved for the current page.
/// - [totalLoadedItems]: The total number of items loaded so far across all pages.
///
/// Returns:
/// - The key for the next page to fetch, or null if there are no more pages.
typedef NextPageKeyGenerator<PageKey, Item> = PageKey? Function(
  PageKey currentPageKey,
  List<Item> currentPageItems,
  int totalLoadedItems,
);

/// {@template pageable_controller}
/// Controller that manages pagination state and data fetching logic.
///
/// Handles automatic calculation of pagination boundaries, manages fetch
/// operations for first and subsequent pages, debounces rapid requests, and
/// provides utilities to refresh, retry, and clear paged data.
///
/// Uses [PageKey] to identify pages and [Item] as the data type for items.
///
/// Extends [ValueNotifier] to notify listeners on pagination state changes.
///
/// Example usage:
/// ```dart
/// final controller = PageableController<int, String>(
///   fetchPage: (pageKey) async {
///     // fetch items for pageKey from API or DB
///   },
///   getFirstPageKey: () => 1,
///   getNextPageKey: (currentKey, items, totalLoaded) => currentKey + 1,
/// );
/// ```
/// 
/// {@endtemplate}
class PageableController<PageKey, Item> extends ValueNotifier<PageableView<PageKey, Item>> {
  /// The callback function that fetches a page of items based on a [PageKey].
  ///
  /// Returns a [Future] or synchronous [List<Item>] for the specified page key.
  final PageableCallback<PageKey, Item> _pageFetcher;
  
  /// Function that returns the initial page key for fetching the first page.
  final PageKey _firstPageKey;
  
  /// Optional function that generates the next page key given the current page key,
  /// the items fetched for the current page, and the total items loaded so far.
  ///
  /// Returning `null` indicates no further pages.
  final NextPageKeyGenerator<PageKey, Item>? _nextPageKeyGenerator;
  
  /// Expected number of items per page, used for automatically detecting the last page.
  final int _pageSize;
  
  /// Logger instance for debugging and tracing internal operations.
  ///
  /// If not provided, a default console logger is used when [showLog] is true.
  final PageableLogger? _logger;
  
  /// Tracks the set of page keys currently being fetched to prevent duplicate fetches.
  final Set<PageKey> _fetchingPages = {};
  
  /// Completer that represents the ongoing fetch operation.
  Completer<void>? _currentFetchCompleter;
  
  /// Flag indicating whether the controller has been disposed.
  bool _isDisposed = false;
  
  /// Timer used to debounce successive fetchNextPage calls.
  Timer? _debounceTimer;

  /// Whether the controller has been initialized.
  bool _hasInitialized = false;
  
  /// Creates a [PageableController] with the given fetchers and configuration.
  ///
  /// - [fetchPage]: required callback to fetch a page of items by page key.
  /// - [getFirstPageKey]: required callback to obtain the first page key.
  /// - [getNextPageKey]: optional callback to generate next page keys.
  /// - [pageSize]: optional expected page size to detect last page.
  /// - [autoFetchFirstPage]: whether to auto-fetch first page on init.
  /// - [showLog]: enable or disable default console logging.
  /// - [logger]: custom logger instance; overrides [showLog] setting.
  /// 
  /// {@macro pageable_controller}
  PageableController({
    required PageableCallback<PageKey, Item> fetchPage,
    required PageKey getFirstPageKey,
    NextPageKeyGenerator<PageKey, Item>? getNextPageKey,
    required int pageSize,
    bool showLog = true,
    PageableLogger? logger,
  })  : _pageFetcher = fetchPage,
        _firstPageKey = getFirstPageKey,
        _nextPageKeyGenerator = getNextPageKey,
        _pageSize = pageSize,
        _logger = logger ?? (showLog ? ConsolePageableLogger() : null),
        super(PageableView.initial(showLog: showLog, pageSize: pageSize))
  {
    
    _log('Initialized (firstPageKey: $_firstPageKey, pageSize: $pageSize, status: ${value.status})');
    
    // Schedule first page fetch for next frame to avoid build conflicts
    // Only schedule first page fetch once
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          fetchFirstPage();
        }
      });
    }
  }
  
  /// Creates a controller from an existing list of page results.
  ///
  /// Useful when you want to initialize the controller with pre-fetched data.
  ///
  /// {@macro pageable_controller}
  factory PageableController.fromPages({
    required List<PageResult<PageKey, Item>> pages,
    required PageableCallback<PageKey, Item> fetchPage,
    required PageKey getFirstPageKey,
    NextPageKeyGenerator<PageKey, Item>? getNextPageKey,
    PageKey? nextPageKey,
    required int pageSize,
    bool showLog = false,
    PageableLogger? logger,
  }) {
    final controller = PageableController<PageKey, Item>(
      fetchPage: fetchPage,
      getFirstPageKey: getFirstPageKey,
      getNextPageKey: getNextPageKey,
      pageSize: pageSize,
      showLog: showLog,
      logger: logger,
    );
    
    controller.value = PageableView.fromPages(
      pages: pages,
      nextPageKey: nextPageKey,
      showLog: showLog,
      pageSize: pageSize,
    );
    
    controller._log('Controller created from existing data: ${controller.value}');
    return controller;
  }
  
  /// Current pageable data, including all loaded pages and status.
  PageableView<PageKey, Item> get pageable => value;

  /// Flattened list of all items loaded so far.
  List<Item> get itemList => value.items;

  /// Current error (if any) encountered during fetching.
  dynamic get error => value.error;
  
  /// Whether a fetch operation is currently in progress.
  bool get isFetching => _currentFetchCompleter != null && !_currentFetchCompleter!.isCompleted;
  
  /// Whether the controller can fetch the next page
  bool get canFetchNextPage => !isFetching && value.canLoadMore;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_isDisposed) {
        throw SmartException(
          'A PageableController was used after being disposed.\nOnce you have '
              'called dispose() on a PageableController, it can no longer be '
              'used.\nIf you’re using a Future, it probably completed after '
              'the disposal of the owning widget.\nMake sure dispose() has not '
              'been called yet before using the PageableController.',
        );
      }
      return true;
    }());
    return true;
  }
  
  /// Fetches the first page of data.
  ///
  /// If a fetch is already ongoing, waits for it to complete instead of starting a new one.
  /// Updates the controller's state and handles errors accordingly.
  Future<void> fetchFirstPage() async {
    _debugAssertNotDisposed();
    
    // Prevent multiple simultaneous first page fetches
    if (isFetching) {
      _log('First page fetch already in progress, waiting...');
      await _currentFetchCompleter!.future;
      return;
    }
    
    _log('Fetching first page');
    _currentFetchCompleter = Completer<void>();
    
    try {
      final firstPageKey = _firstPageKey;
      
      // Check if this page is already being fetched
      if (_fetchingPages.contains(firstPageKey)) {
        _log('First page already being fetched');
        return;
      }
      
      _fetchingPages.add(firstPageKey);
      
      // Update status to loading first page
      value = value.copyWith(
        status: PageableStatus.LOADING_FIRST_PAGE,
        clearError: true,
      );
      
      final items = await _pageFetcher(firstPageKey);
      
      _debugAssertNotDisposed();
      
      _log('First page fetched: ${items.length} items');
      
      // Create page result
      final pageResult = PageResult<PageKey, Item>(
        pageKey: firstPageKey,
        items: items,
      );
      
      // Determine the new status based on the result
      PageableStatus newStatus;
      PageKey? nextPageKey;
      
      if (items.isEmpty) {
        // When first page is empty, it should be NO_ITEMS_FOUND
        newStatus = PageableStatus.NO_ITEMS_FOUND;
        nextPageKey = null; // Ensure nextPageKey is null
        _log('No items found on first page');
      } else {
        // Check if this is the last page
        final isLastPage = _isLastPage(items);
        if (isLastPage) {
          newStatus = PageableStatus.COMPLETED;
          nextPageKey = null; // Clear nextPageKey when completed
          _log('First page is also the last page (completed)');
        } else {
          newStatus = PageableStatus.LOADED_PAGE;
          _log('First page loaded, more pages available');
          // Generate next page key if generator is provided
          if (_nextPageKeyGenerator != null) {
            nextPageKey = _nextPageKeyGenerator!(firstPageKey, items, items.length);
          }
        }
      }
      
      value = value.copyWith(
        pages: [pageResult],
        status: newStatus,
        nextPageKey: nextPageKey,
        clearError: true,
      );
      
    } catch (error, stackTrace) {
      _debugAssertNotDisposed();
      
      _log('Error fetching first page: $error');
      value = value.copyWith(
        status: PageableStatus.FIRST_PAGE_ERROR,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _fetchingPages.remove(_firstPageKey);
      _currentFetchCompleter?.complete();
      _currentFetchCompleter = null;
    }
  }
  
  /// Fetches the next page of data if available and not currently fetching.
  ///
  /// This method debounces rapid successive calls to avoid excessive fetching.
  Future<void> fetchNextPage() async {
    _debugAssertNotDisposed();
    
    // Strict guards against excessive fetching
    if (!canFetchNextPage) {
      _log('Cannot fetch next page: isFetching=$isFetching, canLoadMore=${value.canLoadMore}');
      return;
    }
    
    // Debounce rapid calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () async {
      await _performNextPageFetch();
    });
  }
  
  Future<void> _performNextPageFetch() async {
    if (_isDisposed || !canFetchNextPage) return;
    
    PageKey? nextPageKey;
    
    // Generate next page key
    if (_nextPageKeyGenerator != null && value.pages.isNotEmpty) {
      final lastPage = value.pages.last;
      nextPageKey = _nextPageKeyGenerator!(
        lastPage.pageKey, 
        lastPage.items, 
        value.itemCount,
      );
    } else if (value.nextPageKey != null) {
      nextPageKey = value.nextPageKey;
    }
    
    if (nextPageKey == null) {
      _log('No next page key available');
      value = value.copyWith(status: PageableStatus.COMPLETED);
      return;
    }
    
    // Prevent duplicate requests for the same page
    if (_fetchingPages.contains(nextPageKey)) {
      _log('Next page ($nextPageKey) already being fetched');
      return;
    }
    
    _log('Fetching next page: $nextPageKey');
    _fetchingPages.add(nextPageKey);
    
    try {
      // Update status to loading more
      value = value.copyWith(
        status: PageableStatus.LOADING_NEW_PAGE,
        clearError: true,
      );
      
      final items = await _pageFetcher(nextPageKey);
      
      _debugAssertNotDisposed();
      
      _log('Next page fetched: ${items.length} items');
      
      // Create new page result
      final pageResult = PageResult<PageKey, Item>(
        pageKey: nextPageKey,
        items: items,
      );
      
      // Add to existing page results
      final newPageResults = List<PageResult<PageKey, Item>>.from(value.pages);
      newPageResults.add(pageResult);
      
      // Determine the new status and next page key
      PageableStatus newStatus;
      PageKey? newNextPageKey;
      
      final isLastPage = _isLastPage(items);
      if (isLastPage) {
        newStatus = PageableStatus.COMPLETED;
        newNextPageKey = null; // Clear the next page key when completed
        _log('Reached last page (completed)');
      } else {
        newStatus = PageableStatus.LOADED_PAGE;
        _log('More pages available');
        // Generate next page key if generator is provided
        if (_nextPageKeyGenerator != null) {
          newNextPageKey = _nextPageKeyGenerator!(nextPageKey, items, value.itemCount + items.length);
        }
      }
      
      value = value.copyWith(
        pages: newPageResults,
        status: newStatus,
        nextPageKey: newNextPageKey,
        clearError: true,
      );
      
    } catch (error, stackTrace) {
      _debugAssertNotDisposed();
      
      _log('Error fetching next page: $error');
      value = value.copyWith(
        status: PageableStatus.NEW_PAGE_ERROR,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _fetchingPages.remove(nextPageKey);
    }
  }
  
  /// Auto-calculates if this is the last page based on page size
  bool _isLastPage(List<Item> items) {
    // If items count is less than expected page size, it's the last page
    return items.length < _pageSize;
  }
  
  /// Refreshes the data by fetching the first page again.
  ///
  /// Cancels ongoing fetches and resets the controller state.
  Future<void> refresh() async {
    _debugAssertNotDisposed();

    // Prevent multiple simultaneous refresh operations
    if (isFetching) {
      _log('Refresh already in progress, waiting...');
      await _currentFetchCompleter!.future;
      return;
    }
    
    // Cancel any ongoing operations
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _currentFetchCompleter?.complete();
    _currentFetchCompleter = null;
    
    _log('Refreshing data');
    _currentFetchCompleter = Completer<void>();
    
    try {
      final firstPageKey = _firstPageKey;
      _fetchingPages.add(firstPageKey);
      
      // Update status to REFRESHING
      value = value.copyWith(
        status: PageableStatus.REFRESHING,
        clearError: true,
      );
      
      final items = await _pageFetcher(firstPageKey);
      
      _debugAssertNotDisposed();
      
      _log('Data refreshed: ${items.length} items');
      
      // Create new page result
      final pageResult = PageResult<PageKey, Item>(
        pageKey: firstPageKey,
        items: items,
      );
      
      // Determine the new status
      PageableStatus newStatus;
      PageKey? nextPageKey;
      
      if (items.isEmpty) {
        newStatus = PageableStatus.NO_ITEMS_FOUND;
        nextPageKey = null;
        _log('No items found after refresh');
      } else {
        final isLastPage = _isLastPage(items);
        if (isLastPage) {
          newStatus = PageableStatus.COMPLETED;
          nextPageKey = null;
          _log('Refresh completed - no more pages');
        } else {
          newStatus = PageableStatus.LOADED_PAGE;
          _log('Refresh completed - more pages available');
          if (_nextPageKeyGenerator != null) {
            nextPageKey = _nextPageKeyGenerator!(firstPageKey, items, items.length);
          }
        }
      }
      
      value = PageableView<PageKey, Item>(
        pages: [pageResult],
        status: newStatus,
        nextPageKey: nextPageKey,
        showLog: value.showLog,
        pageSize: value.pageSize,
      );
      
    } catch (error, stackTrace) {
      _debugAssertNotDisposed();
      
      _log('Error REFRESHING data: $error');
      value = value.copyWith(
        status: value.hasData ? PageableStatus.LOADED_PAGE : PageableStatus.FIRST_PAGE_ERROR,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _fetchingPages.remove(_firstPageKey);
      _currentFetchCompleter?.complete();
      _currentFetchCompleter = null;
    }
  }
  
  /// Retries the last failed fetch operation.
  ///
  /// If last failure was fetching the first page, retries first page fetch.
  /// If last failure was fetching next page, retries next page fetch.
  Future<void> retry() async {
    _debugAssertNotDisposed();
    
    _log('Retrying last operation (status: ${value.status})');
    
    if (value.status == PageableStatus.FIRST_PAGE_ERROR) {
      await fetchFirstPage();
    } else if (value.status == PageableStatus.NEW_PAGE_ERROR) {
      await fetchNextPage();
    }
  }
  
  /// Clears all data and resets to initial state
  void clear() {
    _debugAssertNotDisposed();
    
    _log('Clearing all data');
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _currentFetchCompleter?.complete();
    _currentFetchCompleter = null;
    
    value = PageableView.initial(showLog: value.showLog, pageSize: value.pageSize);
  }
  
  /// Logs a message if logging is enabled
  void _log(String message) {
    _logger?.log(message, tag: '$runtimeType ${runtimeType.hashCode}');
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _currentFetchCompleter?.complete();
    _log('PageableController disposed');
    
    super.dispose();
  }
}