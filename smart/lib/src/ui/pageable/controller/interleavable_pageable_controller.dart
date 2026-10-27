import '../helpers/pageable_logger.dart';
import '../models/interleaved_source_state.dart';
import '../models/page_result.dart';
import '../models/pageable_source.dart';
import '../models/pageable_status.dart';
import 'interleave_strategy.dart';
import 'pageable_controller.dart';

/// Internal mutable state container tracking a single [PageableSource].
///
/// Wraps a [PageableSource] with runtime state: the fetched item buffer,
/// current and next pagination cursors, fetching flag, and per-source error.
///
/// This class is private to the controller and not exposed to consumers.
class _SourceEntry<PageKey, Item> {
  /// The source configuration (fetch callbacks, page keys, priority).
  final PageableSource<PageKey, Item> source;

  /// Accumulated items fetched from this source across all pages.
  ///
  /// Cleared on [reset] (e.g., during [InterleavablePageableController.refresh]).
  final List<Item> items = [];

  /// The page key of the most recently fetched page.
  ///
  /// Used by [_fetchSourceNextPage] to pass as `currentPageKey` to the
  /// source's `getNextPageKey` generator. Set to `null` after [reset].
  PageKey? currentPageKey;

  /// The page key to fetch next, or `null` if the source is exhausted.
  ///
  /// Set to `null` when:
  /// - [PageableSource.getNextPageKey] returns `null`
  /// - [PageableSource.getNextPageKey] is not provided (single-page source)
  /// - The source is reset via [reset]
  PageKey? nextPageKey;

  /// Whether this source is currently executing a fetch operation.
  ///
  /// Guards against concurrent fetches for the same source. Checked by
  /// [InterleavablePageableController._fetchSourceNextPage] to skip sources
  /// that are already mid-fetch.
  bool isFetching = false;

  /// The most recent error thrown by this source's fetch callback, or `null`
  /// if the last fetch succeeded.
  ///
  /// Stored in [InterleavablePageableController._sourceErrors] for partial
  /// failure tracking. Cleared on successful fetch or [reset].
  dynamic error;

  /// Creates a [_SourceEntry] wrapping the given [source].
  _SourceEntry(this.source);

  /// Clears all internal buffers and cursors to prep for a fresh fetch.
  ///
  /// Called during [InterleavablePageableController.refresh] and
  /// [InterleavablePageableController.clear].
  void reset() {
    items.clear();
    currentPageKey = null;
    nextPageKey = null;
    isFetching = false;
    error = null;
  }
}

/// {@template interleavable_pageable_controller}
/// A [PageableController] that orchestrates multiple independent paginated data
/// sources and merges them into a single, unified feed.
///
/// Unlike a standard [PageableController] which manages a single linear data
/// stream, this controller delegates fetching to a collection of
/// [PageableSource] objects. Each source maintains its own independent
/// pagination cursor, loading state, and error boundary.
///
/// ## Type Parameters
///
/// - [PageKey] — the page key type shared by every [PageableSource] registered
///   with this controller (e.g., `int`, `String`, `DateTime`). All sources
///   must use the same [PageKey] type.
/// - [Item] — the type of items yielded by the interleaved feed. All sources
///   must share the same [Item] type.
///
/// ## How It Works
///
/// 1. **Synthetic page keys**: Source-level pagination uses [PageKey], but to
///    the parent widget (e.g., a `ListView`) the controller emits `int`
///    "synthetic page keys". A single synthetic "page" represents one
///    complete batch of interleaved items — not a raw source page.
/// 2. **Strategy-driven**: Relies on an [InterleaveStrategy] to determine both
///    *which* sources to fetch data from on the next pagination cycle, and
///    *how* to order the fetched items in the final list.
/// 3. **Parent bypass**: Completely overrides the parent's single-source
///    fetching logic (`fetchFirstPage`, `fetchNextPage`, `refresh`, etc.)
///    so the parent's internal `_activeFetches`, `_fetchingPages`, and
///    `_pageFetcher` are never used.
/// 4. **Partial failure isolation**: If one source fails, its error is trapped
///    per-source while the remaining sources continue to render normally.
///
/// ## Usage
///
/// ```dart
/// final controller = InterleavablePageableController<int, Post>(
///   strategy: RoundRobinInterleaveStrategy(itemsPerSource: 5),
///   sources: [
///     PageableSource<int, Post>(
///       id: 'feed',
///       fetchPage: (pageKey) => api.fetchFeed(pageKey),
///       firstPageKey: 1,
///       getNextPageKey: (key, items, total) => key + 1,
///       pageSize: 20,
///     ),
///     PageableSource<int, Post>(
///       id: 'ads',
///       fetchPage: (pageKey) => api.fetchAds(pageKey),
///       firstPageKey: 1,
///       getNextPageKey: (key, items, total) => key + 1,
///       pageSize: 5,
///       priority: 1,
///     ),
///   ],
/// );
///
/// // Works directly with existing pageable widgets:
/// PageableListView<int, Post>(
///   controller: controller,
///   builderDelegate: PagedChildBuilderDelegate<Post>(
///     itemBuilder: (context, post, index) => PostTile(post: post),
///   ),
/// );
///
/// // Dynamic source management at runtime:
/// controller.addSource(PageableSource<int, Post>(
///   id: 'sponsored',
///   fetchPage: (page) => api.fetchSponsored(page),
///   firstPageKey: 1,
///   getNextPageKey: (key, items, total) => items.length < 10 ? null : key + 1,
///   pageSize: 10,
/// ));
///
/// // Cursor-based sources use the same [PageKey] type:
/// InterleavablePageableController<String, Post>(
///   strategy: RoundRobinInterleaveStrategy(itemsPerSource: 5),
///   sources: [
///     PageableSource<String, Post>(
///       id: 'feed',
///       fetchPage: (cursor) => api.fetchFeed(cursor),
///       firstPageKey: 'start',
///       getNextPageKey: (key, items, total) => items.last.cursor,
///       pageSize: 20,
///     ),
///   ],
/// );
/// ```
///
/// ## State Mapping
///
/// The controller maps per-source states to a unified [PageableStatus]:
///
/// | Condition | Status |
/// |---|---|
/// | All sources empty + all errored | [PageableStatus.FIRST_PAGE_ERROR] |
/// | All sources empty (no errors) | [PageableStatus.NO_ITEMS_FOUND] |
/// | Any source can load more | [PageableStatus.LOADED_PAGE] |
/// | All sources exhausted | [PageableStatus.COMPLETED] |
///
/// ## Retry Behavior
///
/// [retry] retries only sources that have per-source errors. If no per-source
/// errors exist but the overall status implies failure, it falls back to
/// [fetchFirstPage] or [fetchNextPage].
///
/// {@endtemplate}
class InterleavablePageableController<PageKey, Item> extends PageableController<int, Item> {
  /// The strategy defining fetch routing (which sources to load) and merging
  /// logic (how items are ordered in the final list).
  final InterleaveStrategy<Item> _strategy;

  /// Custom logger dedicated to interleave operations.
  ///
  /// When non-null, all internal operations (fetches, errors, re-interleaves)
  /// are logged with the tag `'InterleavedController'`.
  final PageableLogger? _interleaveLogger;

  /// Internal registry mapping source IDs to their active state and data
  /// buffers.
  ///
  /// Sources are stored by their [PageableSource.id]. Each entry tracks the
  /// source's fetched items, pagination cursors, and error state.
  final Map<String, _SourceEntry<PageKey, Item>> _sources = {};

  /// Tracks the current synthetic page batch.
  ///
  /// Increments each time [_reinterleave] generates a new batch of items for
  /// the UI. Used as the `pageKey` in the synthetic [PageResult] emitted to
  /// the parent widget.
  int _syntheticPageKey = 0;

  /// Internal flag tracking if an overarching parallel fetch operation is in
  /// progress.
  ///
  /// Replaces the parent controller's internal `_activeFetches` counter, as
  /// multiple sources may be fetching concurrently under a single logical
  /// operation (e.g., [fetchFirstPage]).
  bool _isFetching = false;

  /// Tracks errors thrown by specific sources, keyed by source ID.
  ///
  /// Allows for partial success — if "feed" loads successfully but "ads"
  /// fails, the feed still renders while the error is recorded separately.
  /// Cleared on each new [fetchFirstPage] or [refresh] call.
  final Map<String, dynamic> _sourceErrors = {};

  /// {@macro interleavable_pageable_controller}
  ///
  /// The [strategy] determines how items from multiple sources are interleaved
  /// and which sources are fetched from on each pagination cycle.
  ///
  /// The [sources] list provides the initial set of data sources. Sources can
  /// also be added or removed dynamically after construction via [addSource]
  /// and [removeSource].
  ///
  /// All other parameters are forwarded to the parent [PageableController] and
  /// control behavior like safe mode, logging, and retry configuration.
  InterleavablePageableController({
    /// The merging and routing logic applied to the data sources.
    required InterleaveStrategy<Item> strategy,

    /// The initial list of data sources to interleave. Defaults to empty.
    /// Sources can be added later via [addSource].
    ///
    /// All sources must share this controller's [PageKey] and [Item] types.
    List<PageableSource<PageKey, Item>> sources = const [],

    super.getPreviousPageKey,
    super.enabled,
    super.reloadKey,
    super.resetOnReloadKeyChange,
    super.pollInterval,
    super.pausePollingWhenHidden,
    super.cacheKey,
    super.cache,
    super.useSafeMode,
    super.showLog,
    super.logger,
    super.onPageableInitCallback,
    super.onPageableReadyCallback,
    super.onPageableDisposeCallback,
    super.maxRetries,
    super.retryDelay,
    super.retryIf,
    super.retryDelayBuilder,
    super.onRetryAttempt,
  })  : _strategy = strategy,
        _interleaveLogger = logger ?? (showLog == true ? ConsolePageableLogger() : null),
        super(
          // Pass dummy values to the parent. The parent's linear fetch logic
          // is completely bypassed by our overrides of fetchFirstPage and
          // fetchNextPage.
          fetchPage: (_) async => const [],
          getFirstPageKey: 0,
          pageSize: 1,
        ) {
    for (final source in sources) {
      _sources[source.id] = _SourceEntry(source);
    }
  }

  // ─── Overrides ──────────────────────────────────────────────

  /// Returns `int` — the synthetic page key type used for interleaved batches.
  ///
  /// The parent widget (e.g., `PageableListView<int, Item>`) uses this type
  /// parameter. Each synthetic page key is a monotonically increasing integer
  /// representing one batch of interleaved items. Note this is distinct from
  /// the source-level [PageKey] type, which each [PageableSource] uses for
  /// its own pagination.
  @override
  Type getPageKeyType() => int;

  /// Returns the generic [Item] type yielded by this controller.
  @override
  Type getItemType() => Item;

  /// Whether any parallel fetch operations are currently active across all
  /// sources.
  ///
  /// Returns `true` when at least one source is mid-fetch. This replaces the
  /// parent's `_activeFetches > 0` check since we manage our own fetch state.
  @override
  bool get isFetching => _isFetching;

  /// Whether the controller can fetch the next page.
  ///
  /// Returns `true` only when the controller is [enabled], no fetches are
  /// active AND at least one source has a non-null `nextPageKey` (i.e., it
  /// can still load more data).
  @override
  bool get canFetchNextPage => enabled && !_isFetching && _anySourceCanLoadMore;

  /// Initiates the first fetch cycle across all registered sources concurrently.
  ///
  /// Forces every source to fetch its initial page via
  /// [PageableSource.fetchPage]. Once all parallel requests complete, the
  /// results are merged via [_reinterleave] and pushed to the UI as a single
  /// synthetic [PageResult].
  ///
  /// If an individual source fails, its error is trapped in [_sourceErrors]
  /// so the feed can still render items from successful sources. The overall
  /// status is set to [PageableStatus.FIRST_PAGE_ERROR] only if *all* sources
  /// fail with no items.
  ///
  /// This method is a no-op if a fetch is already in progress.
  @override
  Future<void> fetchFirstPage() async {
    if (_isFetching) return;
    if (useSafeMode && !mounted) return;
    debugAssertNotDisposed();

    _log('Fetching first pages from ${_sources.length} sources');
    _isFetching = true;
    value = value.copyWith(status: PageableStatus.LOADING_FIRST_PAGE, clearError: true);
    _sourceErrors.clear();

    try {
      // Execute the initial fetch across all sources simultaneously.
      await Future.wait(
        _sources.values.map((entry) => _fetchSourceFirstPage(entry)),
      );

      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();

      _reinterleave();
    } finally {
      _isFetching = false;
    }
  }

  /// Evaluates which sources need more data and fetches from them concurrently.
  ///
  /// Delegates source selection to [InterleaveStrategy.selectSourcesForFetch],
  /// which receives a snapshot of every source's current state. The strategy
  /// returns a list of source IDs to fetch from, in priority order.
  ///
  /// Only the selected sources are fetched — others remain idle. Once all
  /// selected sources complete, the results are merged into the next synthetic
  /// page via [_reinterleave].
  ///
  /// This method is a no-op if [canFetchNextPage] is `false`.
  @override
  Future<void> fetchNextPage() async {
    if (!canFetchNextPage) return;
    if (useSafeMode && !mounted) return;
    debugAssertNotDisposed();

    // 1. Snapshot the current state of all sources.
    final states = _buildSourceStates();

    // 2. Ask the strategy which sources need network calls to satisfy the
    //    next batch.
    final toFetch = _strategy.selectSourcesForFetch(states);

    if (toFetch.isEmpty) {
      _log('No sources selected for next fetch');
      return;
    }

    _log('Fetching next pages from: $toFetch');
    _isFetching = true;
    value = value.copyWith(status: PageableStatus.LOADING_NEW_PAGE, clearError: true);

    try {
      // 3. Fire parallel requests only for the sources the strategy selected.
      await Future.wait(
        toFetch.map((id) {
          final entry = _sources[id];
          return entry != null ? _fetchSourceNextPage(entry) : Future.value();
        }),
      );

      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();

      // 4. Merge the newly expanded buffers into the next synthetic page.
      _reinterleave();
    } finally {
      _isFetching = false;
    }
  }

  /// Hard resets all internal source states, clears errors, and initiates a
  /// brand new concurrent fetch from the beginning.
  ///
  /// Unlike [fetchFirstPage], this method:
  /// - Resets every source's internal buffer, cursors, and error state
  /// - Clears the synthetic page key counter
  /// - Clears all per-source errors
  /// - Sets status to [PageableStatus.REFRESHING] before fetching
  ///
  /// After all sources complete their first-page fetch, the results are merged
  /// into a fresh synthetic page.
  @override
  Future<void> refresh() async {
    if (useSafeMode && !mounted) return;
    debugAssertNotDisposed();

    _log('Refreshing all sources');
    _isFetching = true;
    _sourceErrors.clear();
    _syntheticPageKey = 0;
    value = value.copyWith(status: PageableStatus.REFRESHING, clearError: true);

    try {
      for (final entry in _sources.values) {
        entry.reset();
      }

      await Future.wait(
        _sources.values.map((entry) => _fetchSourceFirstPage(entry)),
      );

      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();

      _reinterleave();
    } finally {
      _isFetching = false;
    }
  }

  /// Re-attempts fetching for sources that are currently in an error state.
  ///
  /// **Behavior:**
  /// - If per-source errors exist: retries only those failed sources
  ///   concurrently, then re-interleaves.
  /// - If no per-source errors exist but the overall status is
  ///   [PageableStatus.FIRST_PAGE_ERROR]: falls back to [fetchFirstPage].
  /// - If no per-source errors exist but the overall status is
  ///   [PageableStatus.NEW_PAGE_ERROR]: falls back to [fetchNextPage].
  @override
  Future<void> retry() async {
    if (useSafeMode && !mounted) return;
    debugAssertNotDisposed();

    final failed = _sources.entries
        .where((e) => e.value.error != null)
        .toList();

    if (failed.isEmpty) {
      if (value.status.isFirstPageError) {
        await fetchFirstPage();
      } else if (value.status.isLoadingMoreError) {
        await fetchNextPage();
      }
      return;
    }

    _log('Retrying ${failed.length} failed sources');
    _isFetching = true;

    try {
      await Future.wait(failed.map((e) => _retrySource(e.value)));

      if (useSafeMode && !mounted) return;
      debugAssertNotDisposed();

      _reinterleave();
    } finally {
      _isFetching = false;
    }
  }

  /// Clears all synthetic pages, resets all internal source buffers, and
  /// prepares the controller for a fresh start.
  ///
  /// After calling this method:
  /// - All source items, cursors, and errors are cleared
  /// - The synthetic page key counter resets to 0
  /// - The parent's value is reset to [PageableView.initial]
  @override
  void clear() {
    debugAssertNotDisposed();
    _log('Clearing all sources');
    _sourceErrors.clear();
    _syntheticPageKey = 0;
    for (final entry in _sources.values) {
      entry.reset();
    }
    super.clear();
  }

  /// Forces an immediate re-evaluation and re-merge of the current source
  /// buffers.
  ///
  /// Call this after mutating items in-place within a source's buffer. The
  /// controller will re-run the [InterleaveStrategy] and emit a new synthetic
  /// page with the updated items.
  @override
  void notifyItemListChanged() {
    _reinterleave();
  }

  /// Cleans up internal registries and removes error tracking.
  ///
  /// Does **not** dispose individual source controllers — sources are
  /// configuration objects ([PageableSource]), not controllers that own
  /// resources.
  @override
  void dispose() {
    _sources.clear();
    _sourceErrors.clear();
    super.dispose();
  }

  // ─── Source Management ──────────────────────────────────────

  /// Dynamically registers a new [PageableSource] into the interleaving
  /// engine.
  ///
  /// The source is immediately available for the next fetch cycle. If the
  /// controller is currently idle, you may need to call [fetchNextPage] or
  /// [fetchFirstPage] to trigger an initial fetch for the new source.
  ///
  /// The source must share this controller's [PageKey] and [Item] types.
  ///
  /// Throws an [ArgumentError] if a source with the same
  /// [PageableSource.id] already exists.
  void addSource(PageableSource<PageKey, Item> source) {
    if (_sources.containsKey(source.id)) {
      throw ArgumentError('Source "${source.id}" already exists');
    }
    _sources[source.id] = _SourceEntry(source);
    _log('Added source: ${source.id}');
  }

  /// Dynamically removes an active [PageableSource] by its [sourceId].
  ///
  /// The source's items are immediately removed from the interleaved feed
  /// via a re-interleave. If the source was mid-fetch, the fetch continues
  /// in the background but its results are discarded.
  ///
  /// This method is a no-op if the [sourceId] does not match any registered
  /// source.
  void removeSource(String sourceId) {
    if (!_sources.containsKey(sourceId)) return;
    _sources.remove(sourceId);
    _sourceErrors.remove(sourceId);
    _log('Removed source: $sourceId');
    _reinterleave();
  }

  /// Retrieves the [PageableSource] configuration of a registered source by
  /// its [sourceId].
  ///
  /// Returns `null` if no source with the given ID is registered.
  PageableSource<PageKey, Item>? getSource(String sourceId) {
    return _sources[sourceId]?.source;
  }

  /// Returns a list of all currently registered source identifiers.
  ///
  /// The order is not guaranteed to match insertion order.
  List<String> get sourceIds => _sources.keys.toList();

  // ─── Logging Helpers ────────────────────────────────────────

  /// Conditionally forwards messages to the internal [PageableLogger].
  ///
  /// Messages are tagged with this controller's [uniqueId] so logs from
  /// separate interleavable controllers can be distinguished.
  void _log(String message) {
    _interleaveLogger?.log(
      message,
      tag: 'InterleavedController ${uniqueId.toCompactString()}',
    );
  }

  // ─── Internal Pagination ────────────────────────────────────

  /// Fetches the initial page for a specific source and prepares its cursor.
  ///
  /// Calls [PageableSource.fetchPage] with [PageableSource.firstPageKey],
  /// populates the source's item buffer, and resolves the next pagination
  /// cursor via [PageableSource.getNextPageKey].
  ///
  /// If [PageableSource.getNextPageKey] is `null`, the source is treated as
  /// a single-page source and `nextPageKey` is set to `null`.
  ///
  /// Errors are trapped per-source: stored in [entry].error and
  /// [_sourceErrors] so other sources are unaffected.
  Future<void> _fetchSourceFirstPage(_SourceEntry<PageKey, Item> entry) async {
    try {
      entry.isFetching = true;
      final items = await entry.source.fetchPage(entry.source.firstPageKey);

      entry.items
        ..clear()
        ..addAll(items);
      entry.currentPageKey = entry.source.firstPageKey;
      entry.error = null;

      // Handle null generator explicitly to prevent infinite re-fetching
      // of single pages.
      if (entry.source.getNextPageKey != null) {
        entry.nextPageKey = entry.source.getNextPageKey!(
          entry.source.firstPageKey,
          items,
          items.length,
        );
      } else {
        entry.nextPageKey = null; // No generator = single-page source
      }

      _sourceErrors.remove(entry.source.id);
    } catch (e) {
      entry.error = e;
      _sourceErrors[entry.source.id] = e;
      _log('Error fetching first page from ${entry.source.id}: $e');
    } finally {
      entry.isFetching = false;
    }
  }

  /// Fetches the next page for a specific source using its internal cursor.
  ///
  /// Appends the fetched items to the source's item buffer and updates the
  /// pagination cursor. If [PageableSource.getNextPageKey] returns `null`,
  /// the source is marked as exhausted.
  ///
  /// This method is a no-op if the source has no `nextPageKey` or is already
  /// fetching.
  Future<void> _fetchSourceNextPage(_SourceEntry<PageKey, Item> entry) async {
    if (entry.isFetching) return;

    final pageKey = entry.nextPageKey;
    if (pageKey == null) return;

    try {
      entry.isFetching = true;
      final items = await entry.source.fetchPage(pageKey);

      entry.items.addAll(items);
      entry.currentPageKey = pageKey;
      entry.error = null;

      // Handle null generator explicitly to prevent infinite re-fetching
      // of single pages.
      if (entry.source.getNextPageKey != null) {
        entry.nextPageKey = entry.source.getNextPageKey!(
          pageKey,
          items,
          entry.items.length,
        );
      } else {
        entry.nextPageKey = null; // No generator = single-page source
      }

      _sourceErrors.remove(entry.source.id);
    } catch (e) {
      entry.error = e;
      _sourceErrors[entry.source.id] = e;
      _log('Error fetching next page from ${entry.source.id}: $e');
    } finally {
      entry.isFetching = false;
    }
  }

  /// Retries a specific source based on whether it failed on the first page
  /// or a subsequent page.
  ///
  /// If the source has no items, retries via [_fetchSourceFirstPage].
  /// Otherwise, retries via [_fetchSourceNextPage].
  Future<void> _retrySource(_SourceEntry<PageKey, Item> entry) async {
    if (entry.items.isEmpty) {
      await _fetchSourceFirstPage(entry);
    } else {
      await _fetchSourceNextPage(entry);
    }
  }

  // ─── Interleave ─────────────────────────────────────────────

  /// The core engine of the controller.
  ///
  /// Takes the current snapshots of all sources via [_buildSourceStates],
  /// passes them through the [InterleaveStrategy] to generate a merged item
  /// list, and emits a single synthetic [PageResult] that the parent UI
  /// widget can consume.
  ///
  /// The synthetic page key increments on each call, ensuring the parent
  /// widget sees a new "page" each time the interleaved items change.
  void _reinterleave() {
    final states = _buildSourceStates();

    // Pass the immutable map of states directly to the strategy.
    final interleaved = _strategy.interleave(states);

    final hasMore = _anySourceCanLoadMore;
    final status = _computeOverallStatus(interleaved.isEmpty);

    final pageResult = PageResult<int, Item>(
      pageKey: _syntheticPageKey,
      items: interleaved,
    );

    _syntheticPageKey++;

    value = value.copyWith(
      pages: [pageResult],
      status: status,
      nextPageKey: hasMore ? _syntheticPageKey : null,
      clearNextPageKey: !hasMore,
      clearError: _sourceErrors.isEmpty,
      error: _sourceErrors.isNotEmpty ? _sourceErrors.values.last : null,
    );
    persistCacheSnapshot();

    _log('Re-interleaved: ${interleaved.length} items, status=$status, hasMore=$hasMore');
  }

  /// Whether ANY registered source is capable of loading more data.
  ///
  /// A source can load more if it has a non-null `nextPageKey` and is not
  /// currently fetching.
  bool get _anySourceCanLoadMore {
    return _sources.values.any((e) => e.nextPageKey != null && !e.isFetching);
  }

  /// Computes a unified [PageableStatus] to report back to the UI based on
  /// the individual states and errors of all underlying sources.
  ///
  /// The [isEmpty] parameter indicates whether the interleaved result has
  /// zero items (after the strategy merge).
  PageableStatus _computeOverallStatus(bool isEmpty) {
    if (_sources.isEmpty) return PageableStatus.NO_ITEMS_FOUND;

    // If every single source threw an error on start, it's a critical
    // first-page error.
    if (isEmpty && _sourceErrors.length == _sources.length) {
      return PageableStatus.FIRST_PAGE_ERROR;
    }

    if (isEmpty) return PageableStatus.NO_ITEMS_FOUND;
    if (_anySourceCanLoadMore) return PageableStatus.LOADED_PAGE;

    return PageableStatus.COMPLETED;
  }

  /// Generates a deeply immutable snapshot of all source states.
  ///
  /// Each source's internal state (items, cursors, errors) is mapped to an
  /// [InterleavedSourceState] with:
  /// - Items wrapped in [List.unmodifiable] to prevent accidental mutation
  ///   by the strategy.
  /// - A computed [PageableStatus] derived from the source's fetching state,
  ///   item count, error state, and pagination cursor.
  ///
  /// This snapshot is passed to [InterleaveStrategy.interleave] and
  /// [InterleaveStrategy.selectSourcesForFetch] for decision-making.
  Map<String, InterleavedSourceState<Item>> _buildSourceStates() {
    final map = <String, InterleavedSourceState<Item>>{};

    for (final entry in _sources.entries) {
      final id = entry.key;
      final sourceEntry = entry.value;

      final hasItems = sourceEntry.items.isNotEmpty;
      final hasError = sourceEntry.error != null;
      final canLoadMore = sourceEntry.nextPageKey != null;

      PageableStatus status;
      if (sourceEntry.isFetching && !hasItems) {
        status = PageableStatus.LOADING_FIRST_PAGE;
      } else if (sourceEntry.isFetching && hasItems) {
        status = PageableStatus.LOADING_NEW_PAGE;
      } else if (hasError && !hasItems) {
        status = PageableStatus.FIRST_PAGE_ERROR;
      } else if (hasError && hasItems) {
        status = PageableStatus.NEW_PAGE_ERROR;
      } else if (!hasItems) {
        status = PageableStatus.NO_ITEMS_FOUND;
      } else if (canLoadMore) {
        status = PageableStatus.LOADED_PAGE;
      } else {
        status = PageableStatus.COMPLETED;
      }

      map[id] = InterleavedSourceState<Item>(
        id: id,
        priority: sourceEntry.source.priority,
        items: List.unmodifiable(sourceEntry.items),
        canLoadMore: canLoadMore,
        isFetching: sourceEntry.isFetching,
        status: status,
        error: sourceEntry.error,
      );
    }

    return map;
  }

  @override
  List<Object?> equalizedProperties() => [
    ...super.equalizedProperties(),
    runtimeType
  ];
}