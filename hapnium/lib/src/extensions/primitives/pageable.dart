import '../../collectors/paging.dart';

/// A small, in-memory implementation of [Page<T>] backed by a concrete
/// `List<T>`.
///
/// MemoryPage is intended for materializing pages from in-memory
/// collections (for example when paginating search results, cached lists,
/// or test data). It stores the page content, the original `Pageable`
/// metadata and an explicit or computed `totalElements` count.
///
/// Key behaviors and guarantees:
/// - `getContent()` returns the materialized content for this page as an
///   `Iterable<T>` backed by an internal `List<T>`.
/// - `getTotalElements()` returns the value passed to the constructor if
///   supplied; otherwise it is computed from the provided `source`.
/// - `getTotalPages()` uses integer ceiling division and returns `1` for
///   non-positive page sizes to avoid division-by-zero like behavior.
/// - `map` returns a new `MemoryPage<U>` preserving pageable metadata and
///   the same total element count (mapping does not change total count).
///
/// Complexity notes:
/// - Construction copies the source into a `List<T>` (O(n)).
/// - `getTotalPages()` and `hasNext()` are O(1).
///
/// Example:
/// ```dart
/// final page = MemoryPage([1,2,3,4], PageRequest.ofSize(2));
/// print(page.getContent().toList()); // [1,2]
/// print(page.getTotalPages()); // 2
/// ```
class MemoryPage<T> extends Page<T> {
  final List<T> _content;
  final int _totalElements;

  /// Creates a [MemoryPage] from [source] using the given [pageable].
  ///
  /// Parameters:
  /// - `source`: The elements making up this page. The elements are copied
  ///   into an internal `List<T>` to guarantee stable iteration and O(1)
  ///   random access.
  /// - `pageable`: Pagination metadata (page number, size, sort). When
  ///   `pageable.isUnpaged()` the returned page will simply represent the
  ///   whole collection.
  /// - `total` (optional): An explicit total count of elements available
  ///   in the full dataset. When omitted, the constructor uses
  ///   `source.length` (traverses the iterable if it is not already a
  ///   `List`). Providing `total` avoids an extra traversal for
  ///   non-materialized iterables.
  MemoryPage(Iterable<T> source, Pageable pageable, [int? total])
      : _content = List<T>.from(source),
        _totalElements = total ?? source.length,
        super(List<T>.from(source), pageable);

  /// Returns the total number of elements across the whole dataset
  /// (not just the elements contained in this page).
  @override
  int getTotalElements() => _totalElements;

  /// Returns the number of pages computed from `getTotalElements()` and
  /// `getSize()` using ceiling division. If page size is <= 0, `1` is
  /// returned to indicate a single unbounded page.
  @override
  int getTotalPages() {
    final size = getSize();
    if (size <= 0) return 1;
    return (_totalElements + size - 1) ~/ size;
  }

  /// `true` when there exists another page after this one according to
  /// the total pages count.
  @override
  bool hasNext() => getNumber() + 1 < getTotalPages();

  /// Maps the content of this page using [mapper] and returns a new
  /// `MemoryPage<U>` preserving the same `Pageable` and `totalElements`
  /// value. The operation does **not** change the known total of the
  /// dataset.
  @override
  Page<U> map<U>(U Function(T item) mapper) => MemoryPage(_content.map(mapper), getPageable(), _totalElements);
}

extension PageableIterableExtension<T> on Iterable<T> {
  /// Creates a paged view of this iterable using the provided [pageable].
  ///
  /// This method materializes only the elements required for the requested
  /// page, making it suitable for large or lazily-evaluated iterables.
  ///
  /// ## Pagination Behavior
  /// - If [pageable] is unpaged, the entire iterable is returned as a single page.
  /// - Otherwise, elements are iterated until the requested page slice is built.
  ///
  /// ## Parameters
  /// - [pageable]: The pagination information (page number, size, offset).
  /// - [totalElements]: Optional total element count. If omitted, the iterable
  ///   length is computed, which may be expensive for non-materialized iterables.
  ///
  /// ## Returns
  /// A [Page] containing the elements for the requested page.
  ///
  /// ## Performance Notes
  /// - Iteration stops once the page is filled.
  /// - Supplying [totalElements] avoids an additional full traversal.
  Page<T> toPage(Pageable pageable, {int? totalElements}) {
    if (pageable.isUnpaged()) {
      return MemoryPage(this, pageable, totalElements ?? length);
    }

    final offset = pageable.getOffset();
    final size = pageable.getPageSize();

    final List<T> pageContent = <T>[];
    var i = 0;
    for (final e in this) {
      if (i >= offset && pageContent.length < size) pageContent.add(e);
      if (pageContent.length >= size) break;
      i++;
    }

    final total = totalElements ?? length;
    return MemoryPage(pageContent, pageable, total);
  }

  /// Returns a [Page] for the given [pageNumber] and [pageSize].
  ///
  /// This is a convenience wrapper around [toPage] that constructs a
  /// [PageRequest] internally.
  ///
  /// ## Parameters
  /// - [pageNumber]: Zero-based page index.
  /// - [pageSize]: Number of elements per page.
  ///
  /// ## Returns
  /// A [Page] representing the requested slice.
  Page<T> page(int pageNumber, int pageSize) => toPage(PageRequest(pageNumber, pageSize), totalElements: length);

  /// Returns only the content of the requested page as an [Iterable].
  ///
  /// This is useful when pagination metadata is not required.
  ///
  /// ## Parameters
  /// - [pageable]: The pagination configuration.
  ///
  /// ## Returns
  /// An iterable containing only the elements in the requested page.
  Iterable<T> pageContent(Pageable pageable) => toPage(pageable).getContent();
}

extension PageableListExtension<T> on List<T> {
  /// Creates a paged view of this list using the provided [pageable].
  ///
  /// This implementation uses [List.sublist], providing **O(1)** slicing
  /// performance.
  ///
  /// ## Pagination Behavior
  /// - If [pageable] is unpaged, the entire list is returned as a single page.
  /// - Otherwise, a sublist matching the requested page is returned.
  ///
  /// ## Parameters
  /// - [pageable]: The pagination information.
  /// - [totalElements]: Optional total element count. Defaults to the list length.
  ///
  /// ## Returns
  /// A [Page] backed by a sublist of this list.
  Page<T> toPage(Pageable pageable, {int? totalElements}) {
    if (pageable.isUnpaged()) {
      return MemoryPage(this, pageable, totalElements ?? length);
    }

    final offset = pageable.getOffset();
    final size = pageable.getPageSize();

    final start = offset.clamp(0, length);
    final end = (offset + size).clamp(0, length);

    final sub = sublist(start, end);
    final total = totalElements ?? length;
    return MemoryPage(sub, pageable, total);
  }

  /// Returns a [Page] for the given [pageNumber] and [pageSize].
  ///
  /// This is a convenience wrapper around [toPage] using [PageRequest].
  ///
  /// ## Parameters
  /// - [pageNumber]: Zero-based page index.
  /// - [pageSize]: Number of elements per page.
  ///
  /// ## Returns
  /// A [Page] representing the requested slice.
  Page<T> page(int pageNumber, int pageSize) => toPage(PageRequest(pageNumber, pageSize), totalElements: length);

  /// Returns only the content of the requested page as a [List].
  ///
  /// This avoids exposing pagination metadata when only the data slice
  /// is required.
  ///
  /// ## Parameters
  /// - [pageable]: The pagination configuration.
  ///
  /// ## Returns
  /// A list containing only the elements in the requested page.
  List<T> pageContent(Pageable pageable) => toPage(pageable).getContent().toList();
}