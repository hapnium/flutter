import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:smart/exceptions.dart';

import '../helpers/pageable_logger.dart';
import 'pageable_controller_lifecycle.dart';
import 'pageable_controller_lifecycle_mixin.dart';
import '../models/pageable.dart';
import '../models/pageable_cache.dart';
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

/// Function that generates the previous page key based on the current first page.
///
/// Takes:
/// - [currentFirstPageKey]: The key of the first loaded page.
/// - [currentFirstPageItems]: The list of items in the first loaded page.
/// - [totalLoadedItems]: The total number of items loaded so far across all pages.
///
/// Returns:
/// - The key for the page before the first page, or null if there are no earlier pages.
///
/// Prepends the fetched items ahead of the current list, so scrolling upward
/// can reveal earlier content (for example page `firstPage - 1` in an
/// offset-based API, bounded below by the initial page).
typedef PreviousPageKeyGenerator<PageKey, Item> = PageKey? Function(
  PageKey currentFirstPageKey,
  List<Item> currentFirstPageItems,
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
class PageableController<PageKey, Item> extends ValueNotifier<PageableView<PageKey, Item>> with PageableControllerLifecycleMixin<PageKey, Item>, PageableControllerLifecycle, WidgetsBindingObserver {
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

  /// Optional function that generates the previous page key given the first page key,
  /// the items fetched for the first page, and the total items loaded so far.
  ///
  /// Returning `null` indicates no earlier pages.
  final PreviousPageKeyGenerator<PageKey, Item>? _prevPageKeyGenerator;

  /// Whether the controller is allowed to load automatically.
  ///
  /// While disabled, the initial load, polling, and reload-key effects are
  /// skipped and [canFetchNextPage]/[canLoadPrevious] report `false`. Manual
  /// calls ([refresh], [retry], fetch methods) still work.
  bool _enabled;

  /// External reload token consumed by [setReloadKey].
  ///
  /// Change it via [setReloadKey] to retrigger the first-page load.
  Object? _reloadKey;

  /// Whether [setReloadKey] wipes visible state before reloading.
  ///
  /// When false, the reload keeps existing items on screen with a
  /// [PageableStatus.REFRESHING] status instead of flashing a full-page loader.
  final bool resetOnReloadKeyChange;

  /// Interval for automatically refreshing the first page.
  ///
  /// When non-null, [startPolling] is called after initialization; use
  /// [stopPolling] to cancel. Polling is skipped while [enabled] is false.
  final Duration? pollInterval;

  /// Whether polling pauses while the app is in the background.
  ///
  /// When true, the controller observes [AppLifecycleState] and skips poll
  /// ticks while the app is backgrounded.
  final bool pausePollingWhenHidden;

  /// Cache key used to hydrate and persist pageable snapshots.
  ///
  /// When set without an explicit [cache], an [InMemoryPageableCache] is
  /// used. The controller restores the last snapshot on initialization (then
  /// refreshes from the source) and persists every successful load.
  final String? cacheKey;

  /// Storage used with [cacheKey] for snapshot hydration and persistence.
  ///
  /// Defaults to an [InMemoryPageableCache] when [cacheKey] is set and no
  /// cache is provided; pass a custom [PageableCache] for persistent
  /// storage, or leave both unset to disable caching.
  final PageableCache<PageKey, Item>? cache;
  
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

  int _activeFetches = 0;
  
  /// Timer used to debounce successive fetchNextPage calls.
  Timer? _debounceTimer;

  /// Whether the controller has been initialized.
  bool _hasInitialized = false;

  /// Monotonic token that invalidates stale fetch results.
  ///
  /// Replace-style operations ([fetchFirstPage], [refresh], [clear],
  /// [replaceSnapshot], reloads) bump it; in-flight appends/prepends whose
  /// token no longer matches are discarded when they complete.
  int _requestId = 0;

  /// Timer driving automatic [refresh] polling when [pollInterval] is set.
  Timer? _pollTimer;

  /// Whether the app is currently in the background.
  ///
  /// Tracked via [WidgetsBindingObserver] only when [pausePollingWhenHidden]
  /// is true.
  bool _appPaused = false;
  
  /// Creates a [PageableController] with the given fetchers and configuration.
  ///
  /// - [fetchPage]: required callback to fetch a page of items by page key.
  /// - [getFirstPageKey]: required callback to obtain the first page key.
  /// - [getNextPageKey]: optional callback to generate next page keys.
  /// - [getPreviousPageKey]: optional callback to generate previous page keys
  ///   for [fetchPreviousPage]; without it, earlier pages can only come from
  ///   snapshots carrying a [PageableView.prevPageKey].
  /// - [pageSize]: optional expected page size to detect last page.
  /// - [enabled]: when false, the automatic first load, polling, and
  ///   reload-key effects are skipped until [setEnabled] turns it on.
  /// - [reloadKey]: external reload token consumed by [setReloadKey].
  /// - [resetOnReloadKeyChange]: wipe visible state on [setReloadKey].
  /// - [pollInterval]: automatically [refresh] on this cadence (see [startPolling]).
  /// - [pausePollingWhenHidden]: pause polling while the app is backgrounded.
  /// - [cacheKey]/[cache]: hydrate the last snapshot on init (then refresh)
  ///   and persist every successful load.
  /// - [showLog]: enable or disable default console logging.
  /// - [logger]: custom logger instance; overrides [showLog] setting.
  ///
  /// {@macro pageable_controller}
  PageableController({
    required PageableCallback<PageKey, Item> fetchPage,
    required PageKey getFirstPageKey,
    NextPageKeyGenerator<PageKey, Item>? getNextPageKey,
    PreviousPageKeyGenerator<PageKey, Item>? getPreviousPageKey,
    required int pageSize,
    bool enabled = true,
    Object? reloadKey,
    this.resetOnReloadKeyChange = false,
    this.pollInterval,
    this.pausePollingWhenHidden = false,
    this.cacheKey,
    PageableCache<PageKey, Item>? cache,
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
        _prevPageKeyGenerator = getPreviousPageKey,
        _enabled = enabled,
        _reloadKey = reloadKey,
        cache = cache ?? (cacheKey != null ? InMemoryPageableCache<PageKey, Item>() : null),
        _pageSize = pageSize,
        _logger = logger ?? (showLog ? ConsolePageableLogger() : null),
        super(PageableView.initial(showLog: showLog, pageSize: pageSize))
  {
    if (maxRetries < 0) {
      throw ArgumentError.value(maxRetries, 'maxRetries', 'must be greater than or equal to 0');
    }
    if (pollInterval != null && pollInterval! <= Duration.zero) {
      throw ArgumentError.value(pollInterval, 'pollInterval', 'must be greater than zero');
    }

    triggerPageableInit();

    if (pausePollingWhenHidden && pollInterval != null) {
      WidgetsBinding.instance.addObserver(this);
    }

    if (!_enabled) {
      value = value.copyWith(status: PageableStatus.COMPLETED, clearError: true);
    }

    _log('Initialized (firstPageKey: $_firstPageKey, pageSize: $pageSize, status: ${value.status})');

    // Schedule first page fetch for next frame to avoid build conflicts
    // Only schedule first page fetch once
    if (!_hasInitialized) {
      _hasInitialized = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        triggerPageableReady();
        if (!_enabled) return;
        
        if (cacheKey != null && cache != null) {
          _hydrateAndLoad();
        } else {
          fetchFirstPage();
        }

        startPolling();
      });
    }
  }
  
  /// Creates a controller from an existing list of page results.
  ///
  /// Useful when you want to initialize the controller with pre-fetched data.
  ///
  /// {@macro pageable_controller}
  PageableController.fromPages({
    required List<PageResult<PageKey, Item>> pages,
    required PageableCallback<PageKey, Item> fetchPage,
    required PageKey getFirstPageKey,
    NextPageKeyGenerator<PageKey, Item>? getNextPageKey,
    PreviousPageKeyGenerator<PageKey, Item>? getPreviousPageKey,
    PageKey? nextPageKey,
    PageKey? prevPageKey,
    required int pageSize,
    bool enabled = true,
    Object? reloadKey,
    this.resetOnReloadKeyChange = false,
    this.pollInterval,
    this.pausePollingWhenHidden = false,
    this.cacheKey,
    PageableCache<PageKey, Item>? cache,
    this.useSafeMode = true,
    this.maxRetries = 0,
    this.retryDelay = Duration.zero,
    this.retryIf,
    this.retryDelayBuilder,
    this.onRetryAttempt,
    this.onPageableInitCallback,
    this.onPageableReadyCallback,
    this.onPageableDisposeCallback,
    bool showLog = false,
    PageableLogger? logger,
  }) : _pageFetcher = fetchPage,
      _firstPageKey = getFirstPageKey,
      _nextPageKeyGenerator = getNextPageKey,
      _prevPageKeyGenerator = getPreviousPageKey,
      _enabled = enabled,
      _reloadKey = reloadKey,
      cache = cache ?? (cacheKey != null ? InMemoryPageableCache<PageKey, Item>() : null),
      _pageSize = pageSize,
      _logger = logger ?? (showLog ? ConsolePageableLogger() : null),
      super(PageableView.initial(showLog: showLog, pageSize: pageSize))
  {

    if (maxRetries < 0) {
      throw ArgumentError.value(maxRetries, 'maxRetries', 'must be greater than or equal to 0');
    }
    if (pollInterval != null && pollInterval! <= Duration.zero) {
      throw ArgumentError.value(pollInterval, 'pollInterval', 'must be greater than zero');
    }

    triggerPageableInit();

    if (pausePollingWhenHidden && pollInterval != null) {
      WidgetsBinding.instance.addObserver(this);
    }

    if (!_hasInitialized) {
      _hasInitialized = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        triggerPageableReady();
        value = PageableView.fromPages(
          pages: pages,
          nextPageKey: nextPageKey,
          prevPageKey: prevPageKey,
          showLog: showLog,
          pageSize: pageSize,
        );
        
        if (!_enabled) {
          value = value.copyWith(status: PageableStatus.COMPLETED, clearError: true);
          return;
        }

        startPolling();
      });
    }

    _log('Controller created from existing data: $value');
  }
  
  /// Current pageable data, including all loaded pages and status.
  PageableView<PageKey, Item> get pageable => value;

  /// Flattened list of all items loaded so far.
  List<Item> get itemList => value.items;

  /// Current error (if any) encountered during fetching.
  dynamic get error => value.error;
  
  /// Whether a fetch operation is currently in progress.
  bool get isFetching => _activeFetches > 0;

  /// Whether the controller can fetch the next page.
  bool get canFetchNextPage => _enabled && !isFetching && value.canLoadMore;

  /// Whether the controller is allowed to load automatically.
  bool get enabled => _enabled;

  /// The current external reload token (see [setReloadKey]).
  Object? get reloadKey => _reloadKey;

  /// Expected number of items per page.
  int get pageSize => _pageSize;

  /// Current loading/error status.
  PageableStatus get status => value.status;

  /// Flattened list of all items loaded so far (alias of [itemList]).
  List<Item> get items => value.items;

  /// Whether any items have been loaded.
  bool get hasData => value.hasData;

  /// Whether any loading operation is currently reported in [status].
  bool get isLoading => value.isLoading;

  /// Whether earlier pages can be fetched via [fetchPreviousPage].
  bool get canLoadPrevious => _enabled && !isFetching && value.canLoadPrevious;

  /// Key of the last loaded page, or `null` if no pages are loaded.
  PageKey? get currentPageKey => value.lastPageKey;

  /// Key of the first loaded page, or `null` if no pages are loaded.
  PageKey? get currentFirstPageKey => value.firstPageKey;

  /// Enables or disables automatic loading.
  ///
  /// Disabling invalidates in-flight replace operations and parks the
  /// controller at [PageableStatus.COMPLETED] when it holds no data;
  /// enabling with no data triggers [fetchFirstPage] and resumes polling.
  Future<void> setEnabled(bool enabled) async {
    trackOperation('setEnabled');
    debugAssertNotDisposed();
    
    if (_enabled == enabled) return;
    _enabled = enabled;

    if (!enabled) {
      _requestId += 1;
      _debounceTimer?.cancel();
      stopPolling();
      value = value.copyWith(clearError: true);
      
      if (!value.hasData) {
        value = value.copyWith(status: PageableStatus.COMPLETED);
      }
      return;
    }

    if (!value.hasData && value.status == PageableStatus.COMPLETED) {
      await fetchFirstPage();
    }

    startPolling();
  }

  /// Updates the external reload token, retriggering the first-page load.
  ///
  /// Calls with an unchanged key are ignored. When [reset] (or
  /// [resetOnReloadKeyChange] when [reset] is null) is true, visible state is
  /// wiped before reloading; otherwise existing items stay on screen behind
  /// a [PageableStatus.REFRESHING] status via [refresh].
  Future<void> setReloadKey(Object? key, {bool? reset}) async {
    trackOperation('setReloadKey');
    debugAssertNotDisposed();
    
    if (key == _reloadKey) return;
    _reloadKey = key;
    
    if (!_enabled || !mounted) return;

    if (reset ?? resetOnReloadKeyChange) {
      _requestId += 1;
      _debounceTimer?.cancel();
      _fetchingPages.clear();
      value = PageableView.initial(showLog: value.showLog, pageSize: value.pageSize);
      await fetchFirstPage();
    } else {
      await refresh();
    }
  }

  /// Starts automatic [refresh] polling on [pollInterval].
  ///
  /// Safe to call multiple times; does nothing when [pollInterval] is null.
  void startPolling() {
    trackOperation('startPolling');
    final interval = pollInterval;
    
    if (interval == null || isDisposed) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      if (isDisposed || !_enabled) return;
      if (pausePollingWhenHidden && _appPaused) return;
      if (isFetching) return;
      
      await refresh();
    });
  }

  /// Stops automatic [refresh] polling started by [startPolling].
  void stopPolling() {
    trackOperation('stopPolling');
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appPaused = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden;
  }

  /// Replaces the entire pageable state with [items] as a single page.
  ///
  /// In-flight replace operations are invalidated, the snapshot is applied
  /// immediately, and the result is persisted to [cache] when [cacheKey] is
  /// set. An empty [items] list resolves to [PageableStatus.NO_ITEMS_FOUND]
  /// unless [status] is given.
  Future<void> replaceSnapshot({
    required List<Item> items,
    PageKey? pageKey,
    PageKey? nextPageKey,
    PageKey? prevPageKey,
    PageableStatus? status,
    bool? showLog,
    int? pageSize,
  }) async {
    trackOperation('replaceSnapshot');
    debugAssertNotDisposed();

    _requestId += 1;
    _debounceTimer?.cancel();
    _fetchingPages.clear();

    final resolvedKey = pageKey ?? _firstPageKey;
    value = PageableView<PageKey, Item>(
      pages: items.isEmpty
          ? <PageResult<PageKey, Item>>[]
          : <PageResult<PageKey, Item>>[
              PageResult<PageKey, Item>(pageKey: resolvedKey, items: List.of(items)),
            ],
      status: status ?? (items.isEmpty ? PageableStatus.NO_ITEMS_FOUND : PageableStatus.LOADED_PAGE),
      nextPageKey: nextPageKey,
      prevPageKey: prevPageKey,
      showLog: showLog ?? value.showLog,
      pageSize: pageSize ?? value.pageSize,
    );

    await _persistCache();
  }

  /// Persists the current snapshot to [cache] for subclasses.
  ///
  /// Subclasses whose fetch flows bypass the parent implementations (such as
  /// [InterleavablePageableController], which merges per-source buffers
  /// itself) call this after updating [value]. Does nothing unless both
  /// [cacheKey] and [cache] are set.
  @protected
  void persistCacheSnapshot() {
    _persistCache();
  }

  /// Persists the current pages and cursors to [cache] under [cacheKey}.
  ///
  /// Failures are swallowed so caching never breaks pagination.
  Future<void> _persistCache() async {    final key = cacheKey;
    final store = cache;
    
    if (key == null || store == null) return;
    try {
      await store.write(
        key,
        PageableCacheSnapshot<PageKey, Item>(
          pages: List.of(value.pages),
          nextPageKey: value.nextPageKey,
          prevPageKey: value.prevPageKey,
        ),
      );
    } catch (_) {}
  }

  /// Restores the cached snapshot (if any), then loads fresh data.
  ///
  /// Cached items are shown immediately with [PageableStatus.LOADED_PAGE],
  /// then a [refresh] replaces them (keeping them visible behind
  /// [PageableStatus.REFRESHING]); with no cache hit, [fetchFirstPage] runs.
  Future<void> _hydrateAndLoad() async {
    trackOperation('_hydrateAndLoad');
    final key = cacheKey;
    final store = cache;
    
    if (key != null && store != null) {
      try {
        final snapshot = await store.read(key);
        if (useSafeMode && !mounted) return;
        
        debugAssertNotDisposed();
        if (snapshot != null && snapshot.hasItems) {
          value = PageableView<PageKey, Item>(
            pages: List.of(snapshot.pages),
            status: PageableStatus.LOADED_PAGE,
            nextPageKey: snapshot.nextPageKey,
            prevPageKey: snapshot.prevPageKey,
            showLog: value.showLog,
            pageSize: value.pageSize,
          );
        }
      } catch (_) {}
    }
    
    if (!mounted) return;
    
    if (value.hasData) {
      await refresh();
    } else {
      await fetchFirstPage();
    }
  }

  Completer<void> _beginFetchOperation() {
    final completer = Completer<void>();
    _currentFetchCompleter = completer;
    _activeFetches += 1;
    return completer;
  }

  void _endFetchOperation(Completer<void> completer) {
    if (_activeFetches > 0) {
      _activeFetches -= 1;
    }

    if (!completer.isCompleted) {
      try {
        completer.complete();
      } catch (_) {}
    }

    if (identical(_currentFetchCompleter, completer)) {
      _currentFetchCompleter = null;
    }
  }

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
      final inFlight = _currentFetchCompleter;
      if (inFlight != null && !inFlight.isCompleted) {
        await inFlight.future;
      }
      return;
    }
    
    _log('Fetching first page');
    final fetchCompleter = _beginFetchOperation();
    final requestId = ++_requestId;

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

      if (requestId != _requestId) {
        _log('fetchFirstPage result ignored because a newer operation superseded it');
        return;
      }
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
      PageKey? prevPageKey;

      if (items.isEmpty) {
        // When first page is empty, it should be NO_ITEMS_FOUND
        newStatus = PageableStatus.NO_ITEMS_FOUND;
        _log('No items found on first page');
      } else {
        // Check if this is the last page
        final isLastPage = _isLastPage(items);
        if (isLastPage) {
          newStatus = PageableStatus.COMPLETED;
          _log('First page is also the last page (completed)');
        } else {
          newStatus = PageableStatus.LOADED_PAGE;
          _log('First page loaded, more pages available');
          // Generate next page key if generator is provided
          if (_nextPageKeyGenerator != null) {
            nextPageKey = _nextPageKeyGenerator(firstPageKey, items, items.length);
          }
        }
        // Derive the previous page key so earlier pages can be fetched.
        if (_prevPageKeyGenerator != null) {
          prevPageKey = _prevPageKeyGenerator(firstPageKey, items, items.length);
        }
      }

      value = value.copyWith(
        pages: [pageResult],
        status: newStatus,
        nextPageKey: nextPageKey,
        prevPageKey: prevPageKey,
        clearError: true,
        clearNextPageKey: nextPageKey == null,
        clearPrevPageKey: prevPageKey == null,
      );
      await _persistCache();

    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
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
      _endFetchOperation(fetchCompleter);
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

    final requestId = _requestId;
    final fetchCompleter = _beginFetchOperation();
    PageKey? nextPageKey;
    
    // Generate next page key
    if (_nextPageKeyGenerator != null && value.pages.isNotEmpty) {
      final lastPage = value.pages.last;
      nextPageKey = _nextPageKeyGenerator(
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

      if (requestId != _requestId) {
        _log('_performNextPageFetch result ignored because a newer operation superseded it');
        return;
      }

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
        _log('Reached last page (completed)');
      } else {
        newStatus = PageableStatus.LOADED_PAGE;
        _log('More pages available');
        // Generate next page key if generator is provided
        if (_nextPageKeyGenerator != null) {
          newNextPageKey = _nextPageKeyGenerator(nextPageKey, items, value.itemCount + items.length);
        }
      }

      value = value.copyWith(
        pages: newPageResults,
        status: newStatus,
        nextPageKey: newNextPageKey,
        clearError: true,
        clearNextPageKey: newNextPageKey == null,
      );
      await _persistCache();

    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
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
      _endFetchOperation(fetchCompleter);
    }
  }

  /// Fetches the page before the first loaded page, prepending its items.
  ///
  /// Does nothing when [canLoadPrevious] is false. An empty result clears
  /// the previous cursor without changing the visible items; a failure
  /// surfaces [PageableStatus.PREVIOUS_PAGE_ERROR] (or
  /// [PageableStatus.FIRST_PAGE_ERROR] when nothing is loaded).
  Future<void> fetchPreviousPage() async {
    trackOperation('fetchPreviousPage');
    debugAssertNotDisposed();

    if (!canLoadPrevious) {
      _log('Cannot fetch previous page: enabled=$_enabled, isFetching=$isFetching, canLoadPrevious=${value.canLoadPrevious}');
      return;
    }

    await _performPreviousPageFetch();
  }

  Future<void> _performPreviousPageFetch() async {
    trackOperation('_performPreviousPageFetch');
    if (isDisposed || !canLoadPrevious) return;

    PageKey? prevPageKey;
    if (value.pages.isNotEmpty) {
      final firstPage = value.pages.first;
      if (_prevPageKeyGenerator != null) {
        prevPageKey = _prevPageKeyGenerator(firstPage.pageKey, firstPage.items, value.itemCount);
      } else {
        prevPageKey = value.prevPageKey;
      }
    } else {
      prevPageKey = value.prevPageKey;
    }

    if (prevPageKey == null) {
      _log('No previous page key available');
      return;
    }

    // Prevent duplicate requests for the same page
    if (_fetchingPages.contains(prevPageKey)) {
      _log('Previous page ($prevPageKey) already being fetched');
      return;
    }

    final requestId = _requestId;
    _log('Fetching previous page: $prevPageKey');
    _fetchingPages.add(prevPageKey);
    final fetchCompleter = _beginFetchOperation();

    try {
      // Update status to loading previous page
      value = value.copyWith(
        status: PageableStatus.LOADING_PREVIOUS_PAGE,
        clearError: true,
      );

      final items = await _fetchPageWithRetry(prevPageKey, operation: '_performPreviousPageFetch');

      if (requestId != _requestId) {
        _log('_performPreviousPageFetch result ignored because a newer operation superseded it');
        return;
      }
      if (useSafeMode && !mounted) {
        _log('_performPreviousPageFetch result ignored because controller is disposed');
        return;
      }
      debugAssertNotDisposed();

      _log('Previous page fetched: ${items.length} items');

      if (items.isEmpty) {
        value = value.copyWith(
          status: PageableStatus.LOADED_PAGE,
          clearError: true,
          clearPrevPageKey: true,
        );
        _log('No more previous pages');
        return;
      }

      final pageResult = PageResult<PageKey, Item>(
        pageKey: prevPageKey,
        items: items,
      );

      final newPageResults = <PageResult<PageKey, Item>>[pageResult, ...value.pages];

      PageKey? newPrevPageKey;
      if (_prevPageKeyGenerator != null) {
        newPrevPageKey = _prevPageKeyGenerator(prevPageKey, items, value.itemCount + items.length);
      }

      value = value.copyWith(
        pages: newPageResults,
        status: PageableStatus.LOADED_PAGE,
        prevPageKey: newPrevPageKey,
        clearError: true,
        clearPrevPageKey: newPrevPageKey == null,
      );
      await _persistCache();
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();

      _log('Error fetching previous page: $error');
      value = value.copyWith(
        status: value.hasData ? PageableStatus.PREVIOUS_PAGE_ERROR : PageableStatus.FIRST_PAGE_ERROR,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _fetchingPages.remove(prevPageKey);
      _endFetchOperation(fetchCompleter);
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
    if (useSafeMode && !mounted) return;

    trackOperation('refresh');
    debugAssertNotDisposed();

    // Prevent multiple simultaneous refresh operations
    if (isFetching) {
      _log('Refresh already in progress, waiting...');
      final inFlight = _currentFetchCompleter;
      if (inFlight != null && !inFlight.isCompleted) {
        await inFlight.future;
      }
      return;
    }
    
    // Cancel any ongoing operations
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _log('Refreshing data');
    final fetchCompleter = _beginFetchOperation();
    final requestId = ++_requestId;

    try {
      final firstPageKey = _firstPageKey;
      _fetchingPages.add(firstPageKey);

      // Update status to REFRESHING
      value = value.copyWith(
        status: PageableStatus.REFRESHING,
        clearError: true,
      );

      final items = await _fetchPageWithRetry(firstPageKey, operation: 'refresh');

      if (requestId != _requestId) {
        _log('refresh result ignored because a newer operation superseded it');
        return;
      }
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
      PageKey? prevPageKey;

      if (items.isEmpty) {
        newStatus = PageableStatus.NO_ITEMS_FOUND;
        _log('No items found after refresh');
      } else {
        final isLastPage = _isLastPage(items);
        if (isLastPage) {
          newStatus = PageableStatus.COMPLETED;
          _log('Refresh completed - no more pages');
        } else {
          newStatus = PageableStatus.LOADED_PAGE;
          _log('Refresh completed - more pages available');
          if (_nextPageKeyGenerator != null) {
            nextPageKey = _nextPageKeyGenerator(firstPageKey, items, items.length);
          }
        }
        if (_prevPageKeyGenerator != null) {
          prevPageKey = _prevPageKeyGenerator(firstPageKey, items, items.length);
        }
      }

      value = PageableView<PageKey, Item>(
        pages: [pageResult],
        status: newStatus,
        nextPageKey: nextPageKey,
        prevPageKey: prevPageKey,
        showLog: value.showLog,
        pageSize: value.pageSize,
      );
      await _persistCache();

    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
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
      _endFetchOperation(fetchCompleter);
    }
  }
  
  /// Retries the last failed fetch operation.
  ///
  /// If last failure was fetching the first page, retries first page fetch.
  /// If last failure was fetching next page, retries next page fetch.
  /// If last failure was fetching a previous page, retries previous page fetch.
  Future<void> retry() async {
    trackOperation('retry');
    debugAssertNotDisposed();

    _log('Retrying last operation (status: ${value.status})');

    if (value.status == PageableStatus.FIRST_PAGE_ERROR) {
      await fetchFirstPage();
    } else if (value.status == PageableStatus.NEW_PAGE_ERROR) {
      await fetchNextPage();
    } else if (value.status == PageableStatus.PREVIOUS_PAGE_ERROR) {
      await fetchPreviousPage();
    }
  }

  /// Clears all data and resets to initial state
  void clear() {
    trackOperation('clear');
    debugAssertNotDisposed();

    _log('Clearing all data');
    _requestId += 1;
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _completeCurrentFetchIfPending();
    _currentFetchCompleter = null;

    value = PageableView.initial(showLog: value.showLog, pageSize: value.pageSize);
  }

  /// Forces listeners to rebuild after in-place item mutations.
  ///
  /// Use this when you mutate objects already inside existing pages
  /// without replacing the page/item lists.
  void notifyItemListChanged() {
    trackOperation('notifyItemListChanged');
    debugAssertNotDisposed();
    value = value.copyWith();
  }

  void _completeCurrentFetchIfPending() {
    final completer = _currentFetchCompleter;
    if (completer != null && !completer.isCompleted) {
      try {
        completer.complete();
      } catch (_) {}
    }
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
    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
    _fetchingPages.clear();
    _activeFetches = 0;
    _completeCurrentFetchIfPending();
    _currentFetchCompleter = null;
    WidgetsBinding.instance.removeObserver(this);
    _log('PageableController disposed');

    super.dispose();
  }
}