/// {@template zap_page}
/// A generic, strongly-typed data container representing a single slice of a 
/// paginated dataset from a server or database.
///
/// This class acts as a standardized bridge between raw paginated API responses 
/// (usually containing metadata like offsets and totals) and the frontend UI state. 
/// By wrapping the payload [T] alongside its pagination metadata, it provides 
/// everything needed to build complex pagination controls (like "Next/Previous" 
/// buttons, infinite scrolling boundaries, or "Page X of Y" indicators) without 
/// leaking raw JSON maps into the presentation layer.
///
/// **Example Usage:**
/// ```dart
/// // Deserializing a network response into a typed ZapPage
/// final page = ZapPage<UserModel>(
///   data: rawJsonList.map((json) => UserModel.fromJson(json)).toList(),
///   total: response.headers['X-Total-Count'],
///   page: 1,
///   limit: 20,
/// );
/// 
/// // Driving UI logic
/// if (page.hasNextPage) fetchNext();
/// ```
/// {@endtemplate}
class ZapPage<T> {
  /// The strongly-typed payload for the current pagination cycle.
  ///
  /// This list contains the actual domain objects (e.g., Users, Posts, Products) 
  /// returned for this specific [page]. 
  /// 
  /// Note: The length of this list may be strictly less than [limit] if this 
  /// represents the final page of the dataset, or it may be empty if the [page] 
  /// requested exceeds the available data.
  final List<T> data;

  /// The absolute count of all items matching the query across the entire dataset.
  ///
  /// This value represents the full scope of the data on the server, ignoring the 
  /// current chunking. It is strictly required to calculate [totalPages] and to 
  /// definitively know if a subsequent page exists.
  final int total;

  /// The current, 1-based index of this specific data slice.
  ///
  /// **Crucial:** This is a 1-based page number, not a 0-based offset. 
  /// - `page: 1` represents the very first chunk of data.
  /// - `page: 2` represents the second chunk, and so forth.
  final int page;

  /// The maximum capacity of items this page was permitted to hold.
  ///
  /// This mirrors the `limit` or `pageSize` parameter sent in the original API 
  /// request. It dictates the mathematical chunking of the dataset. Even if 
  /// [data.length] is smaller than this value (e.g., on the last page), [limit] 
  /// retains the requested chunk size to ensure pagination math remains accurate.
  final int limit;

  /// {@macro zap_page}
  ///
  /// Instantiates a new pagination wrapper.
  /// 
  /// All fields are rigorously required to ensure the computed getters 
  /// ([hasNextPage], [hasPreviousPage], [totalPages]) can execute safely 
  /// without null-checks.
  const ZapPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Evaluates whether subsequent data exists beyond the current page.
  ///
  /// This relies on deterministic math rather than checking if `data.length == limit`, 
  /// which prevents edge-case bugs where the total dataset is exactly divisible 
  /// by the limit.
  ///
  /// **Math Breakdown:**
  /// If `page = 2`, `limit = 20`, we have theoretically consumed 40 items. 
  /// If `total = 45`, then `40 < 45` evaluates to `true` (a third page exists).
  ///
  /// Useful for conditionally rendering a "Load More" button or triggering 
  /// infinite scroll fetches.
  bool get hasNextPage => (page * limit) < total;

  /// Evaluates whether preceding data exists.
  ///
  /// Because [page] is strictly 1-based, any page index greater than 1 inherently 
  /// implies that prior pages exist. 
  ///
  /// Useful for enabling or disabling a "Previous Page" button in traditional 
  /// numbered pagination UIs.
  bool get hasPreviousPage => page > 1;

  /// Calculates the absolute number of pages required to display the entire dataset.
  ///
  /// This is computed by dividing the [total] items by the per-page [limit] 
  /// and rounding up to the nearest whole integer using `.ceil()`.
  ///
  /// **Examples:**
  /// - `total: 0, limit: 10` -> `0` pages.
  /// - `total: 25, limit: 10` -> `3` pages.
  /// - `total: 30, limit: 10` -> `3` pages.
  /// 
  /// Useful for rendering pagination indicators (e.g., "Page 2 of 5").
  int get totalPages => (total / limit).ceil();
}