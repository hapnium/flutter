import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:smart/exceptions.dart';

import '../helpers/pageable_logger.dart';
import 'pageable_controller_lifecycle.dart';
import 'pageable_controller_lifecycle_mixin.dart';
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

typedef PageableRetryIf = bool Function(Object error, StackTrace stackTrace, int attempt);
typedef PageableRetryDelayBuilder = Duration Function(int attempt);
typedef PageableRetryCallback = void Function(int attempt, Object error, StackTrace stackTrace, Duration delay);

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
class PageableController<PageKey, Item> extends ValueNotifier<PageableView<PageKey, Item>> with PageableControllerLifecycleMixin<PageKey, Item>, PageableControllerLifecycle {
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

  /// Enables mounted/disposed guards after async awaits.
  ///
  /// When false, the controller keeps its original behavior and throws if used
  /// after disposal.
  final bool useSafeMode;

  /// Maximum number of retry attempts for a single page fetch.
  ///
  /// `0` means no retries.
  final int maxRetries;

  /// Fallback delay used between retry attempts when [retryDelayBuilder] is null.
  final Duration retryDelay;

  /// Optional callback to control whether a specific error should be retried.
  final PageableRetryIf? retryIf;

  /// Optional callback to compute retry delay per attempt.
  final PageableRetryDelayBuilder? retryDelayBuilder;

  /// Optional callback invoked whenever a retry is scheduled.
  final PageableRetryCallback? onRetryAttempt;

  /// Lifecycle callback invoked once after controller initialization.
  final VoidCallback? onPageableInitCallback;

  /// Lifecycle callback invoked once when controller is ready.
  final VoidCallback? onPageableReadyCallback;

  /// Lifecycle callback invoked once during disposal.
  final VoidCallback? onPageableDisposeCallback;
  
  /// Tracks the set of page keys currently being fetched to prevent duplicate fetches.
  final Set<PageKey> _fetchingPages = {};
  
  /// Completer that represents the ongoing fetch operation.
  Completer<void>? _currentFetchCompleter;
  
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
  /// - [showLog]: enable or disable default console logging.
  /// - [logger]: custom logger instance; overrides [showLog] setting.
  /// 
  /// {@macro pageable_controller}
  PageableController({
    required PageableCallback<PageKey, Item> fetchPage,
    required PageKey getFirstPageKey,
    NextPageKeyGenerator<PageKey, Item>? getNextPageKey,
    required int pageSize,
    this.useSafeMode = true,
    this.maxRetries = 0,
    this.retryDelay = Duration.zero,
    this.retryIf,
    this.retryDelayBuilder,
    this.onRetryAttempt,
    this.onPageableInitCallback,
    this.onPageableReadyCallback,
    this.onPageableDisposeCallback,
    bool showLog = true,
    PageableLogger? logger,
  })  : _pageFetcher = fetchPage,
        _firstPageKey = getFirstPageKey,
        _nextPageKeyGenerator = getNextPageKey,
        _pageSize = pageSize,
        _logger = logger ?? (showLog ? ConsolePageableLogger() : null),
        super(PageableView.initial(showLog: showLog, pageSize: pageSize))
  {
    if (maxRetries < 0) {
      throw ArgumentError.value(maxRetries, 'maxRetries', 'must be greater than or equal to 0');
    }

    triggerPageableInit();
    
    _log('Initialized (firstPageKey: $_firstPageKey, pageSize: $pageSize, status: ${value.status})');
    
    // Schedule first page fetch for next frame to avoid build conflicts
    // Only schedule first page fetch once
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          triggerPageableReady();
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
    bool useSafeMode = true,
    int maxRetries = 0,
    Duration retryDelay = Duration.zero,
    PageableRetryIf? retryIf,
    PageableRetryDelayBuilder? retryDelayBuilder,
    PageableRetryCallback? onRetryAttempt,
    VoidCallback? onPageableInitCallback,
    VoidCallback? onPageableReadyCallback,
    VoidCallback? onPageableDisposeCallback,
    bool showLog = false,
    PageableLogger? logger,
  }) {
    final controller = PageableController<PageKey, Item>(
      fetchPage: fetchPage,
      getFirstPageKey: getFirstPageKey,
      getNextPageKey: getNextPageKey,
      pageSize: pageSize,
      useSafeMode: useSafeMode,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      retryIf: retryIf,
      retryDelayBuilder: retryDelayBuilder,
      onRetryAttempt: onRetryAttempt,
      onPageableInitCallback: onPageableInitCallback,
      onPageableReadyCallback: onPageableReadyCallback,
      onPageableDisposeCallback: onPageableDisposeCallback,
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

  @override
  Type getPageKeyType() => PageKey;

  @override
  Type getItemType() => Item;

  @override
  void onPageableInit() {
    onPageableInitCallback?.call();
  }

  @override
  void onPageableReady() {
    onPageableReadyCallback?.call();
  }

  @override
  void onPageableDispose() {
    onPageableDisposeCallback?.call();
  }

  @override
  void onPageableRetry(int attempt, Object error, StackTrace stackTrace, Duration delay) {
    onRetryAttempt?.call(attempt, error, stackTrace, delay);
  }

  Future<List<Item>> _fetchPageWithRetry(PageKey pageKey, {required String operation}) async {
    var attempt = 0;
    while (true) {
      try {
        return await _pageFetcher(pageKey);
      } catch (error, stackTrace) {
        if (attempt >= maxRetries) rethrow;
        final nextAttempt = attempt + 1;
        final shouldRetry = retryIf?.call(error, stackTrace, nextAttempt) ?? true;
        if (!shouldRetry) rethrow;

        final delay = retryDelayBuilder?.call(nextAttempt) ?? retryDelay;
        _log(
          '[$operation] retrying attempt $nextAttempt/$maxRetries for page $pageKey after '
          '${delay.inMilliseconds}ms because of $error',
        );
        triggerPageableRetry(nextAttempt, error, stackTrace, delay);

        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        attempt = nextAttempt;
      }
    }
  }
  
  /// Fetches the first page of data.
  ///
  /// If a fetch is already ongoing, waits for it to complete instead of starting a new one.
  /// Updates the controller's state and handles errors accordingly.
  Future<void> fetchFirstPage() async {
    trackOperation('fetchFirstPage');
    debugAssertNotDisposed();
    
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
      
      final items = await _fetchPageWithRetry(firstPageKey, operation: 'fetchFirstPage');
      
      if (useSafeMode && !mounted) {
        _log('fetchFirstPage result ignored because controller is disposed');
        return;
      }
      debugAssertNotDisposed();
      
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
      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();

      dynamic errorDescription;
      if (error case SmartException exception) {
        errorDescription = exception.message;
      } else {
        errorDescription = error;
      }
      
      _log('Error fetching first page: $error');
      value = value.copyWith(
        status: PageableStatus.FIRST_PAGE_ERROR,
        error: errorDescription,
        stackTrace: stackTrace,
      );
    } finally {
      _fetchingPages.remove(_firstPageKey);
      
      try {
        _currentFetchCompleter?.complete();
        _currentFetchCompleter = null;
      } catch (_) {}
    }
  }
  
  /// Fetches the next page of data if available and not currently fetching.
  ///
  /// This method debounces rapid successive calls to avoid excessive fetching.
  Future<void> fetchNextPage() async {
    trackOperation('fetchNextPage');
    debugAssertNotDisposed();
    
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
    trackOperation('_performNextPageFetch');
    if (isDisposed || !canFetchNextPage) return;
    
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
      
      final items = await _fetchPageWithRetry(nextPageKey, operation: '_performNextPageFetch');
      
      if (useSafeMode && !mounted) {
        _log('_performNextPageFetch result ignored because controller is disposed');
        return;
      }
      debugAssertNotDisposed();
      
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
      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();
      
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
    trackOperation('refresh');
    debugAssertNotDisposed();

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
      
      final items = await _fetchPageWithRetry(firstPageKey, operation: 'refresh');
      
      if (useSafeMode && !mounted) {
        _log('refresh result ignored because controller is disposed');
        return;
      }
      debugAssertNotDisposed();
      
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
      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();
      
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
    trackOperation('retry');
    debugAssertNotDisposed();
    
    _log('Retrying last operation (status: ${value.status})');
    
    if (value.status == PageableStatus.FIRST_PAGE_ERROR) {
      await fetchFirstPage();
    } else if (value.status == PageableStatus.NEW_PAGE_ERROR) {
      await fetchNextPage();
    }
  }
  
  /// Clears all data and resets to initial state
  void clear() {
    trackOperation('clear');
    debugAssertNotDisposed();
    
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
    trackOperation('dispose');
    markDisposed();
    triggerPageableDispose();
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _currentFetchCompleter?.complete();
    _log('PageableController disposed');
    
    super.dispose();
  }
}