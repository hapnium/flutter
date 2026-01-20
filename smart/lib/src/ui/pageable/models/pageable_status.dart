// ignore_for_file: constant_identifier_names

/// Enum representing the various states of a pageable data source.
///
/// This enum is used to track the current loading and error status
/// when working with paginated data, such as lists or grids.
/// It covers the full lifecycle from initial state, loading,
/// success, error, empty results, and completion.
///
/// The states include:
/// - [INITIAL]: No data has been loaded yet.
/// - [LOADING_FIRST_PAGE]: The first page is currently loading.
/// - [LOADED_PAGE]: The first page has loaded successfully with items.
/// - [LOADING_NEW_PAGE]: Additional pages are currently loading.
/// - [NO_ITEMS_FOUND]: The first page loaded but contained no items.
/// - [FIRST_PAGE_ERROR]: An error occurred while loading the first page.
/// - [NEW_PAGE_ERROR]: An error occurred while loading additional pages.
/// - [COMPLETED]: All pages have been loaded, no more data available.
///
/// Example usage:
/// ```dart
/// if (status.isLoadingFirstPage) {
///   return CircularProgressIndicator();
/// } else if (status.hasError) {
///   return ErrorWidget();
/// } else if (status.isCompleted) {
///   return Text('All items loaded');
/// }
/// ```
enum PageableStatus {
  /// Loading the first page
  LOADING_FIRST_PAGE,

  /// Page loaded successfully with items
  LOADED_PAGE,

  /// Loading additional pages
  LOADING_NEW_PAGE,

  /// No items found on the first page
  NO_ITEMS_FOUND,

  /// Error occurred during first page load
  FIRST_PAGE_ERROR,

  /// Error occurred while loading more pages
  NEW_PAGE_ERROR,

  /// All pages loaded - no more data available
  COMPLETED,
  
  /// Refreshing - no need to change ui since it will still contain existing data
  REFRESHING,
}

/// Extension providing convenient boolean getters for [PageableStatus].
extension PageableStatusExtension on PageableStatus {
  /// Whether the first page is currently loading.
  bool get isLoadingFirstPage => this == PageableStatus.LOADING_FIRST_PAGE;

  /// Whether the page has loaded successfully.
  bool get isLoaded => this == PageableStatus.LOADED_PAGE || this == PageableStatus.COMPLETED;

  /// Whether additional pages are currently loading.
  bool get isLoadingMore => this == PageableStatus.LOADING_NEW_PAGE;

  /// Whether the page loaded but no items were found.
  bool get isNoItemsFound => this == PageableStatus.NO_ITEMS_FOUND;

  /// Whether an error occurred while loading the first page.
  bool get isFirstPageError => this == PageableStatus.FIRST_PAGE_ERROR;

  /// Whether an error occurred while loading more pages.
  bool get isLoadingMoreError => this == PageableStatus.NEW_PAGE_ERROR;

  /// Whether all pages have been loaded and no more data is available.
  bool get isCompleted => this == PageableStatus.COMPLETED;

  /// Whether any loading operation is currently in progress.
  bool get isLoading => isLoadingFirstPage || isLoadingMore;

  /// Whether the pageable has successfully loaded some data.
  bool get hasData => isLoaded || isLoadingMore || isLoadingMoreError || isCompleted;

  /// Whether the pageable has encountered an error.
  bool get hasError => isFirstPageError || isLoadingMoreError;

  /// Whether more pages can be loaded (i.e., not completed and no blocking errors).
  bool get canLoadMore => isLoaded || isLoadingMoreError;
}