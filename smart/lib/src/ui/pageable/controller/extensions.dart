import '../models/page_result.dart';

extension PageResultBuilderExtension<PageKey, Item> on List<Item> {
  /// Builds a list of [PageResult]s from a flat list of items using integer page keys.
  ///
  /// [pageSize] defines how many items per page.
  /// Pages will be numbered starting at 0.
  ///
  /// Example:
  /// ```dart
  /// final items = List.generate(25, (i) => 'Item $i');
  /// final pages = items.buildPageablePages(pageSize: 10);
  /// print(pages.length); // 3
  /// print(pages[0].pageKey); // 0
  /// print(pages[0].items.length); // 10
  /// print(pages[2].items.length); // 5
  /// ```
  ///
  /// Throws [ArgumentError] if [pageSize] is less than or equal to zero.
  List<PageResult<int, Item>> buildPageablePages({int pageSize = 10}) {
    if (pageSize <= 0) {
      throw ArgumentError('pageSize must be greater than zero');
    }
    final List<PageResult<int, Item>> results = [];
    for (int i = 0; i < length; i += pageSize) {
      final pageKey = i ~/ pageSize;
      final pageItems = skip(i).take(pageSize).toList();
      results.add(PageResult<int, Item>(pageKey: pageKey, items: pageItems));
    }
    return results;
  }

  /// Builds a list of [PageResult]s from a flat list of items using a custom page key builder.
  ///
  /// [pageSize] defines how many items per page.
  /// [keyBuilder] generates a page key of type [PageKey] from the start index of each page chunk.
  ///
  /// Example:
  /// ```dart
  /// final items = List.generate(25, (i) => 'Item $i');
  /// final pages = items.buildPageablePagesWithKeyBuilder(
  ///   pageSize: 10,
  ///   keyBuilder: (startIndex) => 'page_${startIndex ~/ 10}',
  /// );
  /// print(pages.length); // 3
  /// print(pages[0].pageKey); // 'page_0'
  /// print(pages[0].items.length); // 10
  /// print(pages[2].items.length); // 5
  /// ```
  ///
  /// Throws [ArgumentError] if [pageSize] is less than or equal to zero.
  List<PageResult<PageKey, Item>> buildPageablePagesWithKeyBuilder({
    required PageKey Function(int startIndex) keyBuilder,
    int pageSize = 10,
  }) {
    if (pageSize <= 0) {
      throw ArgumentError('pageSize must be greater than zero');
    }
    final List<PageResult<PageKey, Item>> results = [];
    for (int i = 0; i < length; i += pageSize) {
      final pageKey = keyBuilder(i);
      final pageItems = skip(i).take(pageSize).toList();
      results.add(PageResult<PageKey, Item>(pageKey: pageKey, items: pageItems));
    }
    return results;
  }

  /// Returns a [PageResult] for a specific [pageKey] based on [pageSize].
  /// Returns null or an empty PageResult if the pageKey is out of bounds.
  PageResult<int, Item> buildPageablePage({required int pageKey, required int pageSize}) {
    if (pageSize <= 0) {
      throw ArgumentError('pageSize must be greater than zero');
    }

    final int start = pageKey * pageSize;
    
    // Check if the requested start index is within bounds
    if (start >= length || start < 0) {
      return PageResult<int, Item>(pageKey: pageKey, items: []);
    }

    final int end = (start + pageSize > length) ? length : start + pageSize;
    final List<Item> items = sublist(start, end);

    return PageResult<int, Item>(pageKey: pageKey, items: items);
  }
}