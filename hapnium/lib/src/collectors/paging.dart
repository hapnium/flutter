// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:collection';

import 'package:hapnium/hapnium.dart';

/// {@template page}
/// Represents a **full page of data** in a paginated dataset.
///
/// A [Page] extends [PageSlicedChunk] and provides additional metadata such as:
/// - the total number of pages
/// - the total number of elements in the dataset
///
/// Pages are typically returned by repository or service layers when querying
/// paginated data. They combine content, paging metadata, and sorting information.
///
/// ### Usage Example
/// ```dart
/// final page = repository.findUsers(PageRequest.ofSize(20));
///
/// print(page.getNumber());          // current page number
/// print(page.getSize());            // page size
/// print(page.getTotalPages());      // total pages
/// print(page.getTotalElements());   // total elements
/// print(page.getContent());         // list of users in current page
/// print(page.hasNext());            // true if there is a next page
///
/// // Mapping page content to another type
/// final idsPage = page.slice((user) => user.id);
/// print(idsPage.getContent()); // List<int>
/// ```
///
/// ### Design Notes
/// - [Page] instances are **immutable** and fully describe a page in the dataset.
/// - Navigation helpers (from [PageSlicedChunk]) work seamlessly with `Pageable`.
/// - Use [empty] to create an empty page for default or placeholder responses.
/// {@endtemplate}
abstract class Page<T> extends PageSlicedChunk<T> {
  /// Constructs a [Page] with the given stream of [source] elements
  /// and the associated [Pageable] for pagination metadata.
  /// 
  /// {@macro page}
  Page(super.source, super.pageable);

  factory Page.of(Iterable<T> source, [Pageable? pageable]) => _SimplePage(source, pageable ?? Pageable.unpaged());

  /// Returns an **empty page** with the optional [pageable] metadata.
  ///
  /// Useful as a placeholder or default response when no data is available.
  ///
  /// Example:
  /// ```dart
  /// final emptyPage = Page.empty<User>();
  /// print(emptyPage.getContent()); // []
  /// print(emptyPage.isFirst());    // true
  /// ```
  static Page<T> empty<T>([Pageable? pageable]) => _SimplePage([], pageable ?? Pageable.unpaged());

  /// Returns the **total number of pages** in the dataset.
  ///
  /// Typically calculated as `ceil(totalElements / pageSize)`.
  ///
  /// Example:
  /// ```dart
  /// final totalPages = page.getTotalPages();
  /// print("Total pages: $totalPages");
  /// ```
  int getTotalPages();

  /// Returns the **total number of elements** across all pages.
  ///
  /// Example:
  /// ```dart
  /// final totalElements = page.getTotalElements();
  /// print("Total elements: $totalElements");
  /// ```
  int getTotalElements();

  @override
  Page<U> map<U>(U Function(T item) mapper);
}

/// {@template simple_page}
/// Concrete implementation of [Page<T>] representing a **page of elements**
/// with an optional total element count.
///
/// [_SimplePage] stores the page content, pagination metadata from [Pageable],
/// and the total number of elements across the dataset. It calculates
/// total pages and provides navigation helpers accordingly.
///
/// ### Usage Example
/// ```dart
/// final pageRequest = PageRequest.ofSize(10);
/// final page = _SimplePage(usersStream, pageRequest, 35);
///
/// print(page.getTotalElements()); // 35
/// print(page.getTotalPages());    // 4
/// print(page.hasNext());          // true
/// print(page.getContent());       // list of users
///
/// // Mapping page content to another type
/// final idPage = page.map((user) => user.id);
/// print(idPage.getContent()); // List<int>
/// ```
/// 
/// {@endtemplate}
class _SimplePage<T> extends Page<T> {
  /// The total number of elements in the dataset.
  final int total;

  /// Constructs a [_SimplePage] with the given [source] elements, [pageable]
  /// metadata, and optional [total] element count.
  ///
  /// If [total] is not provided, it will be calculated from the pageable's
  /// offset and the number of elements in [source], if applicable.
  ///
  /// ### Example
  /// ```dart
  /// final page = _SimplePage(usersStream, pageRequest, 42);
  /// print(page.getTotalElements()); // 42
  /// ```
  /// 
  /// {@macro simple_page}
  _SimplePage(super.source, super.pageable, [int total = 0])
      : total = pageable.optional()
          .filter((pg) => source.isNotEmpty)
          .filter((pg) => pg.getOffset().plus(pg.getPageSize()).isGreaterThan(total))
          .map((pg) => pg.getOffset().plus(source.length))
          .orElse(total) ?? 0;

  @override
  int getTotalElements() => total;

  @override
  int getTotalPages() => isEmpty() ? 1 : total.divideBy(getSize()).ceil();

  @override
  bool hasNext() => getNumber() + 1 < getTotalPages();

  @override
  Page<U> map<U>(U Function(T item) mapper) => _SimplePage(convert(mapper), getPageable(), total);
}

// SLICE

/// {@template slice}
/// Represents a **slice of a paginated dataset**, containing a subset of items
/// along with metadata about pagination and sorting.
///
/// A [PageSlice] differs from a full page in that it focuses primarily on the **current
/// subset of data**, rather than the entire collection. It provides:
/// - the current **slice number** and **size**
/// - the actual content as a `List<T>`
/// - **sorting information**
/// - navigational helpers (`hasNext`, `hasPrevious`, `nextPageable`, etc.)
///
/// [PageSlice] is generic over [T], the type of items contained, and integrates
/// seamlessly with [PageRequest], [Pageable], and [PageSort].
///
/// ### Usage Example
/// ```dart
/// Slice<User> slice = ...; // obtained from repository or service
///
/// print(slice.getNumber());          // 0
/// print(slice.getSize());            // 20
/// print(slice.getNumberOfElements()); // 15
/// print(slice.getContent());         // list of users
/// print(slice.hasNext());            // true if another slice exists
///
/// final nextPageable = slice.nextPageable();
/// final previousPageable = slice.previousOrFirstPageable();
///
/// final ids = slice.slice((user) => user.id).getContent(); // mapping elements
/// ```
///
/// ### Design Notes
/// - [PageSlice] is intended for service or repository layers returning paginated results.
/// - Supports **element transformation** via [slice].  
/// - Navigation methods return new [Pageable] instances pointing to appropriate slices.
/// - Equality and hash code are typically implemented in concrete subclasses.
/// {@endtemplate}
abstract class PageSlice<T> extends StandardGenericStream<T> implements GenericStream<T>, EqualsAndHashCode {
  /// {@macro slice}
  PageSlice(super.source);

  /// Returns the **zero-based number** of this slice in the dataset.
  ///
  /// Typically used in combination with [getSize] to compute offsets
  /// in queries or API calls.
  ///
  /// ### Example
  /// ```dart
  /// final currentPage = slice.getNumber();
  /// print("Currently viewing slice number: $currentPage");
  /// ```
  int getNumber();

  /// Returns the **maximum number of elements** that can be contained in this slice.
  ///
  /// This is typically equivalent to the page size configured in the underlying
  /// [Pageable] or [PageRequest].
  ///
  /// ### Example
  /// ```dart
  /// final pageSize = slice.getSize();
  /// print("Max elements per slice: $pageSize");
  /// ```
  int getSize();

  /// Returns the **number of elements actually contained** in this slice.
  ///
  /// Can be smaller than [getSize] for the last slice of a dataset.
  ///
  /// ### Example
  /// ```dart
  /// print("Number of elements in this slice: ${slice.getNumberOfElements()}");
  /// ```
  int getNumberOfElements();

  /// Returns the list of items contained in this slice.
  ///
  /// The returned list is usually immutable. Modifying it may break internal invariants.
  ///
  /// ### Example
  /// ```dart
  /// final users = slice.getContent();
  /// users.forEach((user) => print(user.username));
  /// ```
  Iterable<T> getContent();

  /// Returns `true` if this slice contains **any elements**.
  ///
  /// Useful for short-circuiting operations when a slice may be empty.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.hasContent()) {
  ///   print("Slice contains ${slice.getNumberOfElements()} items");
  /// } else {
  ///   print("Slice is empty");
  /// }
  /// ```
  bool hasContent();

  /// Returns the [PageSort] configuration applied to this slice.
  ///
  /// This can be used to generate subsequent queries or maintain consistent ordering.
  ///
  /// ### Example
  /// ```dart
  /// final sort = slice.getSort();
  /// print("Sorting applied: $sort");
  /// ```
  PageSort getSort();

  /// Returns `true` if this slice is the first slice in the dataset.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.isFirst()) print("Currently at the first slice");
  /// ```
  bool isFirst();

  /// Returns `true` if this slice is the last slice in the dataset.
  ///
  /// Determining this may require knowledge of total elements in the dataset.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.isLast()) print("Currently at the last slice");
  /// ```
  bool isLast();

  /// Returns `true` if there exists a subsequent slice after this one.
  ///
  /// Useful for generating "Next" navigation links or deciding whether
  /// to request more data from the repository.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.hasNext()) fetchNextSlice(slice.nextPageable());
  /// ```
  bool hasNext();

  /// Returns `true` if there exists a preceding slice before this one.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.hasPrevious()) fetchPreviousSlice(slice.previousPageable());
  /// ```
  bool hasPrevious();

  /// Returns a [Pageable] representing the current slice.
  ///
  /// Useful when converting slices to pageable requests for repository queries.
  ///
  /// ### Example
  /// ```dart
  /// final currentPageable = slice.getPageable();
  /// print(currentPageable.getPageNumber());
  /// ```
  Pageable getPageable() => PageRequest(getNumber(), getSize(), getSort());

  /// Returns a [Pageable] representing the next slice.
  ///
  /// Calling this when [hasNext] is `false` may result in an empty slice in the next query.
  ///
  /// ### Example
  /// ```dart
  /// final nextPageable = slice.nextPageable();
  /// ```
  Pageable nextPageable();

  /// Returns a [Pageable] representing the previous slice.
  ///
  /// Calling this when [hasPrevious] is `false` should return the first slice.
  ///
  /// ### Example
  /// ```dart
  /// final previousPageable = slice.previousPageable();
  /// ```
  Pageable previousPageable();

  /// Returns the next [Pageable] if [hasNext] is `true`, otherwise returns the
  /// current [Pageable].
  ///
  /// Convenient for safe navigation without checking `hasNext`.
  ///
  /// ### Example
  /// ```dart
  /// final nextOrCurrent = slice.nextOrLastPageable();
  /// ```
  Pageable nextOrLastPageable() => hasNext() ? nextPageable() : getPageable();

  /// Returns the previous [Pageable] if [hasPrevious] is `true`, otherwise returns
  /// the current [Pageable].
  ///
  /// Convenient for safe navigation without checking `hasPrevious`.
  ///
  /// ### Example
  /// ```dart
  /// final previousOrCurrent = slice.previousOrFirstPageable();
  /// ```
  Pageable previousOrFirstPageable() => hasPrevious() ? previousPageable() : getPageable();

  /// Returns a new [Slice<U>] by applying the [mapper] function to each element.
  ///
  /// This is useful for mapping the content to a different type while retaining
  /// slice metadata (page number, size, sorting, navigation).
  ///
  /// ### Example
  /// ```dart
  /// final idSlice = slice.map((user) => user.id);
  /// print(idSlice.getContent()); // List<int> of user IDs
  /// ```
  @override
  PageSlice<U> map<U>(U Function(T item) mapper);
}

// SLICED CHUNK

/// {@template sliced_chunk}
/// Concrete implementation of [Slice<T>] backed by a [Pageable] and a stream of elements.
///
/// [PageSlicedChunk] represents a **chunk of data** corresponding to a single slice/page.
/// It decorates a [GenericStream] of elements with pagination metadata and sorting
/// information from a [Pageable].
///
/// Unlike [PageSlice], which is purely abstract, [PageSlicedChunk] provides default
/// implementations for most navigation and content-related methods.
///
/// ### Usage Example
/// ```dart
/// final pageRequest = PageRequest.of(0, 10, SortDirection.asc, ['name']);
/// final chunk = SlicedChunk(usersStream, pageRequest);
///
/// print(chunk.getNumber());           // 0
/// print(chunk.getSize());             // 10
/// print(chunk.getNumberOfElements()); // actual number of users in the stream
/// print(chunk.hasContent());          // true if stream is not empty
/// print(chunk.getContent());          // immutable list of users
/// print(chunk.getSort());             // Sort applied to this chunk
/// ```
/// {@endtemplate}
abstract class PageSlicedChunk<T> extends PageSlice<T> {
  /// The underlying pageable object containing page number, size, and sort.
  final Pageable _pageable;

  /// {@macro sliced_chunk}
  ///
  /// [source] is the stream of elements representing the chunk content.
  /// [_pageable] provides pagination metadata and sorting.
  PageSlicedChunk(super.source, this._pageable);

  @override
  int getNumber() => _pageable.isPaged() ? _pageable.getPageNumber() : 0;

  @override
  int getSize() => _pageable.isPaged() ? _pageable.getPageSize() : toList().length;

  @override
  int getNumberOfElements() => toList().length;

  @override
  bool hasPrevious() => getNumber() > 0;

  @override
  bool isFirst() => !hasPrevious();

  @override
  bool isLast() => !hasNext();

  @override
  bool hasContent() => toList().isNotEmpty;

  @override
  Iterable<T> getContent() sync* {
    yield* iterable();
  }

  @override
  PageSort getSort() => _pageable.getSort();

  @override
  Pageable getPageable() => _pageable;

  @override
  Pageable nextPageable() => hasNext() ? _pageable.getNext() : Pageable.unpaged();

  @override
  Pageable previousPageable() => hasPrevious() ? _pageable.getPreviousOrFirst() : Pageable.unpaged();

  /// Returns `true` if this page contains no elements.
  ///
  /// This is a convenience method equivalent to checking:
  /// ```dart
  /// page.getSize() == 0
  /// ```
  ///
  /// Example:
  /// ```dart
  /// if (page.isEmpty()) {
  ///   print('No items on this page');
  /// }
  /// ```
  bool isEmpty() => getSize() == 0;

  /// Returns `true` if this page contains one or more elements.
  ///
  /// This is the inverse of [isEmpty].  
  /// Equivalent to checking:
  /// ```dart
  /// page.getSize() > 0
  /// ```
  ///
  /// Example:
  /// ```dart
  /// if (page.isNotEmpty()) {
  ///   print('There are items on this page');
  /// }
  /// ```
  bool isNotEmpty() => !isEmpty();

  /// Converts each element in this chunk using the provided [converter] function.
  ///
  /// Returns a new `List<U>` containing the transformed elements.
  ///
  /// ### Example
  /// ```dart
  /// final ids = chunk.convert((user) => user.id);
  /// ```
  List<U> convert<U>(U Function(T item) converter) => map(converter).collect();

  @override
  List<Object?> equalizedProperties() => [_pageable];
}

// SORT

/// Represents the direction in which results should be sorted.
///
/// Commonly used for database queries, API filters, and collection
/// utilities that require specifying ascending or descending order.
enum PageSortDirection {
  /// Sort values from smallest → largest (A → Z, 0 → 9).
  ASC,

  /// Sort values from largest → smallest (Z → A, 9 → 0).
  DESC;

  /// Returns `true` if this direction is ascending.
  ///
  /// Equivalent to checking `this == SortDirection.ASC`.
  bool isAscending() => equals(ASC);

  /// Returns `true` if this direction is descending.
  ///
  /// Equivalent to checking `this == SortDirection.DESC`.
  bool isDescending() => equals(DESC);

  /// Parses a string into a [PageSortDirection].
  ///
  /// The comparison is case-insensitive.
  ///
  /// ### Example
  /// ```dart
  /// final dir1 = SortDirection.fromString("asc");  // SortDirection.ASC
  /// final dir2 = SortDirection.fromString("DESC"); // SortDirection.DESC
  /// ```
  ///
  /// Throws an [HapniumException] if the value does not match `"asc"`
  /// or `"desc"`.
  static PageSortDirection fromString(String value) {
    return switch (value.toUpperCase()) {
      "ASC" => ASC,
      "DESC" => DESC,
      _ => throw HapniumException("Unknown value passed. Value must either be 'desc' or 'asc'."),
    };
  }
}

/// {@template sort_order}
/// Represents a **single sorting instruction** consisting of:
/// - a **property** (field name),
/// - a **direction** ([PageSortDirection]),
/// - and whether the sort should be **case-insensitive**.
///
/// This class is part of the fluent sorting API used to construct declarative,
/// immutable sort configurations for queries, collections, or persistence
/// frameworks.
///
/// ### Usage Example
/// ```dart
/// // Basic ascending order
/// final order = SortOrder('username');
///
/// // Descending order
/// final order = SortOrder.desc('createdAt');
///
/// // Case-insensitive ordering
/// final order = SortOrder('email', ignoreCase: true);
///
/// // Fluent modification
/// final reversed = order.reverse();
/// ```
///
/// ### Behavior Notes
/// - `property` must be non-empty.
/// - Defaults to ascending order if no direction is provided.
/// - Instances are **immutable**; transformation methods return new instances.
/// - Implements equality through [EqualsAndHashCode].
///
/// ### See Also
/// - [PageSort]
/// - [PageSortDirection]
/// {@endtemplate}
final class PageSortOrder with EqualsAndHashCode {
  /// The default direction used when none is provided: ascending.
  static final PageSortDirection DEFAULT_DIRECTION = PageSortDirection.ASC;

  /// The sorting direction (ascending or descending).
  final PageSortDirection direction;

  /// The property (field) name to be sorted by.
  final String property;

  /// Whether sorting should be case-insensitive.
  final bool ignoreCase;

  /// {@macro sort_order}
  PageSortOrder(this.property, {PageSortDirection? direction, bool? ignoreCase})
    : direction = direction ?? DEFAULT_DIRECTION,
      ignoreCase = ignoreCase ?? false,
      assert(property.isNotEmpty, "Property cannot be empty");

  // ---------------------------------------------------------------------------
  // Static Constructors
  // ---------------------------------------------------------------------------

  /// Creates a new ascending order for the given [property].
  ///
  /// ```dart
  /// final o = SortOrder.by('age');
  /// ```
  static PageSortOrder by(String property) => PageSortOrder(property);

  /// Creates an ascending sort order for [property].
  ///
  /// ```dart
  /// final o = SortOrder.asc('name');
  /// ```
  static PageSortOrder asc(String property) => PageSortOrder(property, direction: DEFAULT_DIRECTION);

  /// Creates a descending sort order for [property].
  ///
  /// ```dart
  /// final o = SortOrder.desc('createdAt');
  /// ```
  static PageSortOrder desc(String property) => PageSortOrder(property, direction: PageSortDirection.DESC);

  // ---------------------------------------------------------------------------
  // Transformations (Fluent API)
  // ---------------------------------------------------------------------------

  /// Returns a copy of this order with the given [direction].
  ///
  /// ```dart
  /// final o = SortOrder('age').withDirection(SortDirection.DESC);
  /// ```
  PageSortOrder withDirection(PageSortDirection direction) => copyWith(direction: direction);

  /// Reverses the sort direction.
  ///
  /// - ASC → DESC  
  /// - DESC → ASC
  ///
  /// ```dart
  /// final reversed = SortOrder.asc('age').reverse(); // DESC
  /// ```
  PageSortOrder reverse() => withDirection(direction.isAscending() ? PageSortDirection.DESC : DEFAULT_DIRECTION);

  /// Returns a copy of this order with the given [property].
  ///
  /// ```dart
  /// final o = SortOrder('name').withProperty('email');
  /// ```
  PageSortOrder withProperty(String property) => copyWith(property: property);

  /// Returns a copy of this order with case-insensitive sorting enabled.
  ///
  /// ```dart
  /// final o = SortOrder('email').withIgnoreCase();
  /// ```
  PageSortOrder withIgnoreCase() => copyWith(ignoreCase: true);

  /// Creates a new [PageSort] using this order’s direction and the given
  /// list of [properties].
  ///
  /// ```dart
  /// final sort = SortOrder('name').withProperties(['name', 'email']);
  /// ```
  PageSort withProperties(List<String> properties) => PageSort.withDirection(direction, properties);

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Creates a new [PageSortOrder] with the optionally overridden values.
  ///
  /// ```dart
  /// final updated = order.copyWith(ignoreCase: true);
  /// ```
  PageSortOrder copyWith({PageSortDirection? direction, String? property, bool? ignoreCase}) => PageSortOrder(
    property ?? this.property,
    direction: direction ?? this.direction,
    ignoreCase: ignoreCase ?? this.ignoreCase,
  );

  @override
  List<Object?> equalizedProperties() => [direction, property, ignoreCase];

  @override
  String toString() => "SortOrder(property: $property, direction: $direction, ignoreCase: $ignoreCase)";
}

/// {@template sort}
/// Represents an **ordered collection of sorting instructions**, each expressed
/// as a [PageSortOrder].  
///
/// A [PageSort] instance models a declarative sorting strategy typically used in
/// database queries, repository abstractions, or in-memory sorting operations.
///
/// ### Core Characteristics
/// - Immutable collection of [PageSortOrder] elements  
/// - Supports fluent transformations (ascending, descending, reverse, merge)  
/// - Provides helper methods to inspect sorting state  
/// - Implements [GenericStream] for iterable-like APIs  
///
/// ### Usage Example
/// ```dart
/// // A simple ascending sort by "username"
/// final s1 = Sort.by([SortOrder.asc('username')]);
///
/// // Multiple-field sorting
/// final s2 = Sort.withDirection(
///   SortDirection.DESC,
///   ['createdAt', 'id'],
/// );
///
/// // Combine sorts
/// final merged = s1.and(s2);
///
/// // Reverse existing sort
/// final reversed = merged.reverse(merged);
/// ```
///
/// ### Design Notes
/// - `Sort.UNSORTED` is a singleton representing no sorting.  
/// - Empty sorts are always treated as unsorted.  
/// - Transformations return **new instances**, never modifying the original.  
/// - A sort is considered *active* when it contains at least one [PageSortOrder].  
///
/// ### See Also
/// - [PageSortOrder]  
/// - [PageSortDirection]  
/// - [GenericStream]  
/// {@endtemplate}
final class PageSort extends StandardGenericStream<PageSortOrder> with EqualsAndHashCode implements GenericStream<PageSortOrder> {
  /// A singleton representing the absence of sorting.
  ///
  /// This is used whenever an empty list of [PageSortOrder] objects is provided.
  static final PageSort UNSORTED = PageSort([]);

  /// {@macro sort}
  PageSort(super.source);

  /// Creates a [PageSort] using a list of property names and a shared [direction].
  ///
  /// Each property is converted into a corresponding [PageSortOrder] instance.
  ///
  /// ```dart
  /// final sort = Sort.withDirection(
  ///   SortDirection.ASC,
  ///   ['name', 'email'],
  /// );
  /// ```
  ///
  /// Throws an assertion error if [properties] is empty.
  PageSort.withDirection(PageSortDirection direction, List<String> properties)
    : assert(properties.isNotEmpty, "You must provide atleast, one property"),
      super(properties.map((property) => PageSortOrder(property, direction: direction)));

  /// Creates a new [PageSort] using the provided list of [orders].
  ///
  /// If the list is empty, returns [UNSORTED].
  ///
  /// ```dart
  /// final sort = Sort.by([
  ///   SortOrder.asc('username'),
  ///   SortOrder.desc('createdAt'),
  /// ]);
  /// ```
  static PageSort by(List<PageSortOrder> orders) => orders.isEmpty ? UNSORTED : PageSort(orders);

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Internal method that applies the given [direction] to all existing orders.
  ///
  /// Used by [ascending] and [descending].
  PageSort _withDirection(PageSortDirection direction) {
    final orders = toList();
    final newList = <PageSortOrder>[];

    for (final order in orders) {
      newList.add(order.withDirection(direction));
    }

    return PageSort.by(orders);
  }

  // ---------------------------------------------------------------------------
  // Transformations
  // ---------------------------------------------------------------------------

  /// Returns a copy of this [PageSort] with all orders set to **descending**.
  ///
  /// ```dart
  /// final desc = sort.descending();
  /// ```
  PageSort descending() => _withDirection(PageSortDirection.DESC);

  /// Returns a copy of this [PageSort] with all orders set to **ascending**.
  ///
  /// ```dart
  /// final asc = sort.ascending();
  /// ```
  PageSort ascending() => _withDirection(PageSortDirection.ASC);

  // ---------------------------------------------------------------------------
  // Introspection
  // ---------------------------------------------------------------------------

  /// Returns `true` if this sort contains at least one [PageSortOrder].
  ///
  /// ```dart
  /// if (sort.isSorted()) {
  ///   print("Sort is active");
  /// }
  /// ```
  bool isSorted() => toList().isNotEmpty;

  /// Returns `true` if this sort contains no orders.
  ///
  /// ```dart
  /// if (sort.isEmpty()) print("No sorting applied");
  /// ```
  bool isEmpty() => toList().isEmpty;

  // ---------------------------------------------------------------------------
  // Combination & Reversal
  // ---------------------------------------------------------------------------

  /// Combines this sort with another [sort], returning a new [PageSort].
  ///
  /// Orders from the provided [sort] are appended.
  ///
  /// ```dart
  /// final combined = sort1.and(sort2);
  /// ```
  PageSort and(PageSort sort) {
    final current = toList();
    for (final order in sort.toList()) {
      current.add(order);
    }

    return PageSort.by(current);
  }

  /// Produces a new [PageSort] where each [PageSortOrder] has its direction reversed.
  ///
  /// ```dart
  /// final reversed = sort.reverse(sort);
  /// ```
  PageSort reverse(PageSort sort) {
    final reversed = <PageSortOrder>[];
    for (final order in toList()) {
      reversed.add(order.reverse());
    }

    return PageSort.by(reversed);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Retrieves the [PageSortOrder] associated with the given [property],
  /// or returns `null` if no matching order exists.
  ///
  /// ```dart
  /// final order = sort.getFor("username");
  /// ```
  PageSortOrder? getFor(String property) => toList().find((order) => order.property.equals(property));

  @override
  List<Object?> equalizedProperties() => [toList()];

  @override
  String toString() => isEmpty() ? "Sort(UNSORTED)" : "Sort(${toList()})";
}

// UNPAGED

/// {@template unpaged}
/// Represents an **unpaged pagination request**, i.e., a sentinel object
/// indicating that no pagination boundaries should be applied.
///
/// Unpaged instances are typically returned by [Pageable.unpaged] and can
/// optionally carry a [PageSort] specification. All page-related operations
/// (page number, offset, size) are unsupported and will throw exceptions.
///
/// ### Usage Example
/// ```dart
/// final unpaged = Unpaged.sorted(Sort.asc("username"));
///
/// print(unpaged.isPaged()); // false
/// print(unpaged.getSort()); // Sort([SortOrder(property=username, ...)])
/// ```
///
/// ### Design Notes
/// - Immutable class with singleton-style optimization for unsorted instances.
/// - Overrides all page-specific methods to throw [HapniumException].
/// - `Sort` is the only meaningful property; defaults to [PageSort.UNSORTED].
/// - Safe to use as a default when no pagination is required.
/// {@endtemplate}
final class Unpaged extends Pageable {
  /// Singleton instance representing an unpaged, unsorted request.
  static final Pageable UNSORTED = Unpaged(PageSort.UNSORTED);

  /// Returns an unpaged instance with the given [sort], or UNSORTED if the
  /// sort is not defined.
  ///
  /// ```dart
  /// final unpagedSorted = Unpaged.sorted(Sort.asc("id"));
  /// ```
  static Pageable sorted(PageSort sort) => sort.isSorted() ? Unpaged(sort) : UNSORTED;

  /// The sort configuration applied to this unpaged request.
  final PageSort _sort;

  /// {@macro unpaged}
  Unpaged(this._sort);

  @override
  List<Object?> equalizedProperties() => [_sort];

  @override
  Pageable getFirst() => this;

  @override
  int getOffset() => throw HapniumException("Cannot get offset for an unpaged request. Unpaged instances have no page boundaries.");

  @override
  int getPageNumber() => throw HapniumException("Cannot get page number for an unpaged request. This Pageable is not paginated.");

  @override
  int getPageSize() => throw HapniumException("Cannot get page size for an unpaged request. Use a paged Pageable to access page size.");

  @override
  PageSort getSort() => _sort;

  @override
  bool hasPrevious() => false;

  @override
  bool isPaged() => false;

  @override
  Pageable getNext() => this;

  @override
  Pageable getPreviousOrFirst() => this;

  @override
  Pageable withPage(int pageNumber) => pageNumber.equals(0) 
    ? this
    : throw HapniumException("Cannot create a paged instance from an unpaged Pageable. Requested page index: $pageNumber. Valid index for unpaged is only 0.");
}

// SCROLL POSITION

/// {@template scroll_direction}
/// Represents the direction of a **scrolling action**, such as navigating
/// through paginated results, lists, or timeline-like structures.
///
/// This enum is commonly used in cursor-based pagination, UI navigation,  
/// request traversal, and streaming APIs.
///
/// ### Directions
/// - **[PageScrollDirection.FORWARD]** → Moves toward later/next items  
/// - **[PageScrollDirection.BACKWARD]** → Moves toward earlier/previous items  
///
/// ### Usage Example
/// ```dart
/// ScrollDirection direction = ScrollDirection.FORWARD;
///
/// // Reverse scrolling (FORWARD → BACKWARD)
/// direction = direction.reverse();
/// ```
///
/// ### Behavior Notes
/// - The enum is intentionally minimal and highly ergonomic for pagination use.
/// - [reverse] always swaps to the opposite direction.
/// - No-op states do not exist; both values always toggle deterministically.
/// {@endtemplate}
enum PageScrollDirection {
  /// Scrolls **forward**, usually meaning:
  /// - toward next elements in a list
  /// - advancing a cursor or page
  /// - moving chronologically forward
  FORWARD,

  /// Scrolls **backward**, usually meaning:
  /// - toward previous elements
  /// - moving to an earlier cursor or page
  /// - navigating to older items
  BACKWARD;

  /// Returns the **opposite** scroll direction.
  ///
  /// - `FORWARD → BACKWARD`  
  /// - `BACKWARD → FORWARD`
  ///
  /// ```dart
  /// final reversed = ScrollDirection.FORWARD.reverse(); // BACKWARD
  /// ```
  PageScrollDirection reverse() => this == FORWARD ? BACKWARD : FORWARD;
}

/// {@template scroll_position}
/// Represents a **position in a scrollable or paginated collection**.
///
/// This abstract interface provides a common abstraction for different types
/// of scrolling strategies, including:
/// - **Key-set based scrolling** (cursor-based)
/// - **Offset-based scrolling** (index-based)
///
/// ### Usage Example
/// ```dart
/// // Key-set initial position
/// final initialKeyset = ScrollPosition.keySet();
///
/// // Key-set forward scrolling
/// final nextPage = ScrollPosition.forward({"id": 123});
///
/// // Offset-based scrolling
/// final offsetPos = ScrollPosition.offSet(10);
/// ```
///
/// ### Design Notes
/// - Implementations must provide [isInitial] to indicate whether the scroll
///   position represents the start of the collection.
/// - Static factory methods provide a convenient way to create commonly used
///   positions.
/// - Suitable for repository queries, API pagination, or UI scroll tracking.
///
/// ### See Also
/// - [KeysetPageScrollPosition]
/// - [OffsetPageScrollPosition]
/// - [PageScrollDirection]
/// {@endtemplate}
abstract interface class PageScrollPosition with EqualsAndHashCode {
  /// Returns `true` if this scroll position represents the **initial position**
  /// of the collection or dataset.
  ///
  /// ### Example
  /// ```dart
  /// final pos = ScrollPosition.keySet();
  /// print(pos.isInitial()); // true
  /// ```
  bool isInitial();

  /// Creates a **key-set scroll position at the initial position**.
  ///
  /// ### Example
  /// ```dart
  /// final initial = ScrollPosition.keySet();
  /// ```
  static KeysetPageScrollPosition keySet() => KeysetPageScrollPosition.initial();

  /// Creates a **key-set scroll position moving forward** from the given [keys].
  ///
  /// ### Example
  /// ```dart
  /// final next = ScrollPosition.forward({"id": 100});
  /// ```
  static KeysetPageScrollPosition forward(Map<String, Object> keys) => KeysetPageScrollPosition.of(PageScrollDirection.FORWARD, keys);

  /// Creates a **key-set scroll position moving backward** from the given [keys].
  ///
  /// ### Example
  /// ```dart
  /// final previous = ScrollPosition.backward({"id": 50});
  /// ```
  static KeysetPageScrollPosition backward(Map<String, Object> keys) => KeysetPageScrollPosition.of(PageScrollDirection.BACKWARD, keys);

  /// Creates an **offset-based scroll position** at the given [offset].
  ///
  /// If [offset] is `null`, returns the initial offset (0).
  ///
  /// ### Example
  /// ```dart
  /// final initial = ScrollPosition.offSet();
  /// final offset10 = ScrollPosition.offSet(10);
  /// ```
  static OffsetPageScrollPosition offSet([int? offset]) => offset == null ? OffsetPageScrollPosition.initial() : OffsetPageScrollPosition.of(offset);
}

/// {@template key_set_scroll_position}
/// Represents a **key-set (cursor-based) scroll position** in a collection.
///
/// Each instance contains:
/// - a map of `keys` representing the current cursor position  
/// - a `direction` indicating whether the scroll is **forward** or **backward**
///
/// This class is used in **cursor-based pagination** or any context where
/// navigating a dataset relies on the last known key values rather than an offset.
///
/// ### Usage Example
/// ```dart
/// // Initial position (forward)
/// final initial = KeysetScrollPosition.initial();
///
/// // Forward scroll from a specific key
/// final nextPage = KeysetScrollPosition.of(
///   ScrollDirection.FORWARD,
///   {"id": 123},
/// );
///
/// // Reverse scrolling
/// final previousPage = nextPage.reverse();
/// ```
///
/// ### Design Notes
/// - Immutable once created (keys are wrapped in [UnmodifiableMapView])  
/// - `EMPTY_FORWARD` and `EMPTY_BACKWARD` singletons optimize empty key sets  
/// - Provides convenient helpers for scrolling and reversing direction  
/// - Works seamlessly with [PageScrollPosition] abstraction
/// {@endtemplate}
final class KeysetPageScrollPosition implements PageScrollPosition {
  /// Singleton representing an empty forward scroll position.
  static final KeysetPageScrollPosition EMPTY_FORWARD = KeysetPageScrollPosition(PageScrollDirection.FORWARD, {});

  /// Singleton representing an empty backward scroll position.
  static final KeysetPageScrollPosition EMPTY_BACKWARD = KeysetPageScrollPosition(PageScrollDirection.BACKWARD, {});

  /// The cursor keys representing the current scroll position.
  final Map<String, Object> keys;

  /// The direction of the scroll.
  final PageScrollDirection direction;

  /// {@macro key_set_scroll_position}
  KeysetPageScrollPosition(this.direction, this.keys);

  /// Returns the **initial forward scroll position**.
  ///
  /// Equivalent to an empty cursor moving forward.
  ///
  /// ```dart
  /// final initial = KeysetScrollPosition.initial();
  /// print(initial.isInitial()); // true
  /// ```
  static KeysetPageScrollPosition initial() => EMPTY_FORWARD;

  /// Creates a [KeysetPageScrollPosition] from the given [direction] and [keys].
  ///
  /// If [keys] is empty, returns the corresponding singleton ([EMPTY_FORWARD] or
  /// [EMPTY_BACKWARD]) to optimize memory usage.
  ///
  /// ### Example
  /// ```dart
  /// final pos = KeysetScrollPosition.of(
  ///   ScrollDirection.FORWARD,
  ///   {"id": 42},
  /// );
  /// ```
  static KeysetPageScrollPosition of(PageScrollDirection direction, Map<String, Object> keys) {
    if (keys.isEmpty) {
      return direction == PageScrollDirection.FORWARD ? EMPTY_FORWARD : EMPTY_BACKWARD;
    }

    return KeysetPageScrollPosition(direction, UnmodifiableMapView(keys));
  }

  /// Returns `true` if this position scrolls **forward**.
  ///
  /// ```dart
  /// print(position.scrollsForward()); // true or false
  /// ```
  bool scrollsForward() => direction == PageScrollDirection.FORWARD;

  /// Returns `true` if this position scrolls **backward**.
  ///
  /// ```dart
  /// print(position.scrollsBackward()); // true or false
  /// ```
  bool scrollsBackward() => direction == PageScrollDirection.BACKWARD;

  /// Returns a new scroll position moving **forward**.
  ///
  /// If already forward, returns `this`.
  KeysetPageScrollPosition scrollForward() => direction == PageScrollDirection.FORWARD 
    ? this
    : KeysetPageScrollPosition(PageScrollDirection.FORWARD, keys);

  /// Returns a new scroll position moving **backward**.
  ///
  /// If already backward, returns `this`.
  KeysetPageScrollPosition scrollBackward() => direction == PageScrollDirection.BACKWARD 
    ? this
    : KeysetPageScrollPosition(PageScrollDirection.BACKWARD, keys);

  /// Returns a new [KeysetPageScrollPosition] with **reversed direction**.
  ///
  /// ```dart
  /// final reversed = position.reverse();
  /// ```
  KeysetPageScrollPosition reverse() => KeysetPageScrollPosition(direction.reverse(), keys);

  @override
  bool isInitial() => keys.isEmpty;

  @override
  List<Object?> equalizedProperties() => [direction, keys];
}

/// {@template offset_scroll_position}
/// Represents an **offset-based scroll position**, commonly used for
/// index-based pagination (e.g., SQL `LIMIT/OFFSET`, list slicing,
/// sequential pagination).
///
/// This model is complementary to cursor-based pagination and is useful
/// when:
/// - items are addressable by numeric index  
/// - consistent ordering is guaranteed  
/// - simple “skip N items” semantics are needed  
///
/// An offset of `-1` indicates the **initial position**, meaning no scroll
/// has yet occurred.
///
/// ### Usage Example
/// ```dart
/// // Initial position
/// final pos = OffsetScrollPosition.initial();
///
/// // Advance by 20 items
/// final next = pos.advanceBy(20);
///
/// // Directly construct offset 40
/// final at40 = OffsetScrollPosition.of(40);
/// ```
///
/// ### Design Notes
/// - Offsets must always be non-negative when created via [of].  
/// - The initial offset is internally represented as -1.  
/// - Increasing the offset is done via [advanceBy], which returns a new instance.  
/// - Implements [PageScrollPosition] for interoperability with keyset pagination.  
///
/// ### See Also
/// - [PageScrollPosition]  
/// - [KeysetPageScrollPosition]  
/// - [PageScrollDirection]  
/// {@endtemplate}
final class OffsetPageScrollPosition implements PageScrollPosition {
  /// The singleton instance representing the **initial** offset.
  ///
  /// Internal value: -1
  static final OffsetPageScrollPosition INITIAL = OffsetPageScrollPosition(-1);

  /// Internal raw offset value.
  ///
  /// - `-1` represents the initial state  
  /// - any other value represents the actual offset  
  final int _offset;

  /// {@macro offset_scroll_position}
  OffsetPageScrollPosition(this._offset);

  /// Returns the **initial** [OffsetPageScrollPosition].
  ///
  /// ```dart
  /// final pos = OffsetScrollPosition.initial();
  /// print(pos.isInitial()); // true
  /// ```
  static OffsetPageScrollPosition initial() => INITIAL;

  /// Creates a new [OffsetPageScrollPosition] with the given positive [offset].
  ///
  /// Throws an assertion error if [offset] is negative.
  ///
  /// ```dart
  /// final pos = OffsetScrollPosition.of(30);
  /// ```
  static OffsetPageScrollPosition of(int offset) {
    assert(offset >= 0, "Offset cannot be negative");
    return OffsetPageScrollPosition(offset);
  }

  /// Returns the current offset value.
  ///
  /// This method throws an assertion error if called on the initial position.
  /// Always check [isInitial] before calling:
  ///
  /// ```dart
  /// if (!pos.isInitial()) {
  ///   print(pos.getOffset());
  /// }
  /// ```
  int getOffset() {
    assert(_offset >= 0, "Offset cannot be negative. When using initial, always check isInitial() first.");
    return _offset;
  }

  /// Advances the current offset by the given [advance] amount.
  ///
  /// If the position is *initial*, the new offset becomes the advance amount.
  ///
  /// Ensures the resulting offset is never negative.
  ///
  /// ```dart
  /// final pos = OffsetScrollPosition.of(10);
  /// final next = pos.advanceBy(15); // offset = 25
  /// ```
  OffsetPageScrollPosition advanceBy(int advance) {
    final value = isInitial() ? advance : _offset.plus(advance);
    return OffsetPageScrollPosition(value.isLessThan(0) ? 0 : value);
  }

  @override
  bool isInitial() => this == INITIAL || _offset == -1;

  @override
  List<Object?> equalizedProperties() => [_offset];
}

// PAGEABLE

/// {@template pageable}
/// Represents a pagination request describing which slice of data should be
/// retrieved from a paged resource.
///
/// A [Pageable] defines:
/// - the **page number** (zero-based),
/// - the **page size** (number of items per page),
/// - an associated [PageSort] definition,
/// - navigation capabilities such as [getNext], [getPreviousOrFirst], and [getFirst].
///
/// Two concrete implementations typically exist:
/// - [PageRequest] — A fully defined, paginated request.
/// - [Unpaged] — A sentinel representing “no pagination”.
///
/// This abstraction unifies pagination logic across repositories, query
/// builders, and web controllers.
///
/// ### Usage Example
/// ```dart
/// final pageable = PageRequest.of(0, 20, Sort.asc("username"));
///
/// print(pageable.getPageNumber()); // 0
/// print(pageable.getPageSize());   // 20
/// print(pageable.getSort());       // Sort([SortOrder(property=username, ...]])
///
/// final next = pageable.next();
/// print(next.getPageNumber());     // 1
/// ```
///
/// ### Unpaged Example
/// ```dart
/// final unpaged = Pageable.unpaged();
/// print(unpaged.isUnpaged()); // true
/// print(unpaged.getSort());   // Sort.UNSORTED
/// ```
///
/// ### Design Notes
/// - All page numbers are **zero-based**.
/// - Unpaged instances represent unlimited queries (converted via [toLimit]).  
/// - Navigation methods always return new, immutable instances.  
/// - `scrollPosition` conversion uses exclusive semantics (offset - 1).  
///
/// ### Example Behaviors
/// | Condition            | Value               |
/// |----------------------|---------------------|
/// | `Pageable.unpaged()` | `isPaged == false`  |
/// | `PageRequest(...)`   | `isPaged == true`   |
/// | unpaged → `toLimit`  | `Limit.unlimited()` |
/// | paged → `toLimit`    | `Limit.of(pageSize)`|
///
/// ### See Also
/// - [PageSort]
/// - [PageSortOrder]
/// - [Limit]
/// - [OffsetPageScrollPosition]
/// - [PageRequest]
/// - [Unpaged]
/// {@endtemplate}
abstract class Pageable with EqualsAndHashCode {
  /// Creates an unpaged instance, optionally applying a [sort].
  ///
  /// ### Example
  /// ```dart
  /// final pageable = Pageable.unpaged();
  /// final sortedUnpaged = Pageable.unpaged(Sort.asc("name"));
  /// ```
  static Pageable unpaged([PageSort? sort]) => Unpaged.sorted(sort ?? PageSort.UNSORTED);

  /// Creates a paged request with the given [pageSize], starting at page `0`.
  ///
  /// ### Example
  /// ```dart
  /// final pageable = Pageable.ofSize(50);
  /// print(pageable.getPageSize()); // 50
  /// ```
  static Pageable ofSize(int pageSize) => PageRequest(0, pageSize);

  /// Indicates whether this instance represents a paged request.
  ///
  /// For paged instances, always returns `true`.  
  /// Unpaged implementations override this to return `false`.
  bool isPaged() => true;

  /// Indicates whether this instance represents an unpaged request.
  ///
  /// Defaults to the negation of [isPaged].
  bool isUnpaged() => !isPaged();

  /// Returns the zero-based page number.
  int getPageNumber();

  /// Returns the page size (number of elements per page).
  int getPageSize();

  /// Returns the offset of the first element on the page.
  ///
  /// Typically:  
  /// `offset = pageNumber * pageSize`
  int getOffset();

  /// Returns the sort configuration applied to this pagination request.
  PageSort getSort();

  /// Returns the sort defined on this instance, or falls back to the
  /// provided [sort] if this one is unsorted.
  ///
  /// ### Example
  /// ```dart
  /// final fallback = Sort.asc("id");
  /// final actual = pageable.getSortOr(fallback);
  /// ```
  PageSort getSortOr(PageSort sort) => getSort().isSorted() ? getSort() : sort;

  /// Returns a new [Pageable] pointing to the next page in the sequence.
  ///
  /// Example:
  /// ```dart
  /// final nextPage = currentPage.getNext();
  /// ```
  Pageable getNext();

  /// Returns the previous page if one exists, or the first page if currently at page `0`.
  ///
  /// This is useful for navigating backwards safely without throwing exceptions.
  ///
  /// Example:
  /// ```dart
  /// final previous = currentPage.getPreviousOrFirst();
  /// ```
  Pageable getPreviousOrFirst();

  /// Returns a [Pageable] pointing to the first page (page `0`).
  ///
  /// Example:
  /// ```dart
  /// final firstPage = currentPage.getFirst();
  /// ```
  Pageable getFirst();

  /// Returns a new [Pageable] with the given [pageNumber].
  ///
  /// Use this to jump to an arbitrary page in the sequence.
  ///
  /// Example:
  /// ```dart
  /// final page5 = currentPage.withPage(5);
  /// ```
  Pageable withPage(int pageNumber);

  /// Returns `true` if this pagination request has a previous page available.
  ///
  /// Example:
  /// ```dart
  /// if (currentPage.hasPrevious()) {
  ///   final previous = currentPage.getPreviousOrFirst();
  /// }
  /// ```
  bool hasPrevious();

  /// Returns an [Optional] containing this [Pageable] if it is paged,
  /// or empty if this represents an unpaged request.
  ///
  /// Example:
  /// ```dart
  /// final opt = currentPage.optional();
  /// opt.ifPresent((p) => print(p.getPageNumber()));
  /// ```
  Optional<Pageable> optional() => isUnpaged() ? Optional.empty() : Optional.of(this);

  /// Converts this pagination request into a [Limit].
  ///
  /// - Unpaged → `Limit.unlimited()`  
  /// - Paged → `Limit.of(getPageSize())`
  ///
  /// ### Example
  /// ```dart
  /// final limit = pageable.toLimit();
  /// ```
  Limit toLimit() => isUnpaged() ? Limit.unlimited() : Limit.of(getPageSize());

  /// Converts this pagination request into an [OffsetPageScrollPosition].
  ///
  /// - Unpaged → throws [HapniumException]  
  /// - Paged → creates an exclusive offset (`offset - 1`)  
  ///
  /// ### Example
  /// ```dart
  /// final pos = pageable.toScrollPosition();
  /// ```
  OffsetPageScrollPosition toScrollPosition() {
    if (isUnpaged()) {
			throw HapniumException("Cannot create OffsetScrollPosition from an unpaged instance");
		}

    // scrolling is exclusive → subtract one when offset > 0
		return getOffset() > 0 ? PageScrollPosition.offSet(getOffset() - 1) : PageScrollPosition.offSet();
  }
}

// LIMIT

/// {@template limiting}
/// Marker mixin indicating that a type provides limiting behavior.
///
/// This mixin itself defines no behavior. It is used purely as a semantic
/// indicator so that frameworks and utilities can detect whether a type
/// participates in limiting operations (for example, pagination limits,
/// maximum result sizes, or query bounds).
///
/// Typically, this is implemented by classes such as [Limit], which define
/// the actual semantics of limits.
///
/// ### Example
/// ```dart
/// class MyLimiter with Limiting {
///   final int maxItems;
///   MyLimiter(this.maxItems);
/// }
///
/// bool hasLimit(Limiting object) {
///   return object is Limiting;
/// }
/// ```
///
/// ### Notes
/// - This mixin is intentionally empty.
/// - Use it to tag classes that conceptually impose limits.
/// {@endtemplate}
abstract mixin class Limiting {}

/// {@template limit}
/// A value object representing an upper bound (limit) typically used in
/// pagination, query constraints, or result-size restrictions.
///
/// A [Limit] expresses either:
/// - a **finite limit**: created via [Limit.of], representing a concrete
///   non-negative maximum, or
/// - an **unbounded state**: created via [Limit.unlimited], representing no
///   restriction.
///
/// This abstraction helps unify pagination and bounded queries while
/// maintaining immutability and type safety.
///
/// ### Creation Examples
/// ```dart
/// final limited = Limit.of(10);     // Max 10 items
/// final unlimited = Limit.unlimited(); // No maximum
///
/// print(limited.isLimited()); // true
/// print(unlimited.isUnlimited()); // true
/// ```
///
/// ### Design Notes
/// - Negative values are not allowed; enforcing correctness at construction.
/// - Subtypes must implement [max] and [isLimited].
/// - Use [isUnlimited] to check for unbounded conditions instead of
///   manually comparing values.
///
/// ### Example Behavior
/// | Input             | Result Type   | isLimited | max()    |
/// |-------------------|---------------|-----------|----------|
/// | `Limit.of(5)`     | `_Limited`    | `true`    | `5`      |
/// | `Limit.unlimited()` | `_Unlimited` | `false`   | n/a      |
///
/// ### See Also
/// - [Limiting]
/// - pagination utilities or query builders that depend on limits.
/// {@endtemplate}
sealed class Limit extends Limiting implements EqualsAndHashCode {
  /// Creates an unlimited (unbounded) limit.
  ///
  /// Equivalent to:  
  /// ```dart
  /// final limit = Limit.unlimited();
  /// ```
  static Limit unlimited() => _Unlimited._();

  /// Creates a finite limit with the given [max] value.
  ///
  /// The number **must be non-negative** and represents the maximum number
  /// of items or elements allowed.
  ///
  /// ### Example
  /// ```dart
  /// final limit = Limit.of(20);
  /// print(limit.max()); // 20
  /// ```
  static Limit of(int max) => _Limited(max);

  /// Returns the concrete maximum number of elements allowed by this limit.
  ///
  /// This method **must only** be invoked when [isLimited] is `true`.  
  /// Calling this on an unlimited instance is invalid and may result in an
  /// exception, since unlimited limits do not define a numeric upper bound.
  int max();

  /// Returns `true` if this limit represents a concrete, non-negative maximum.
  ///
  /// When this returns `true`, [max] is guaranteed to be callable and meaningful.
  bool isLimited() => this is _Limited;

  /// Returns `true` if this limit has no upper bound.
  ///
  /// Unlimited limits impose no numeric constraint, and therefore do **not**
  /// support calls to [max].
  bool isUnlimited() => !isLimited();
}

/// {@template limited}
/// Internal implementation of a finite [Limit] representing a concrete,
/// non-negative maximum value.
///
/// Instances of `_Limited` are created exclusively through the public
/// factory method [Limit.of]. This ensures that:
/// - values are validated at construction time,
/// - user code interacts only with the abstract [Limit] type,
/// - the type hierarchy remains encapsulated.
///
/// ### Example
/// ```dart
/// final limit = Limit.of(10);
///
/// if (limit.isLimited()) {
///   print(limit.max()); // 10
/// }
/// ```
///
/// ### Design Notes
/// - `_Limited` is immutable.
/// - `_max` must always be non-negative.
/// - Equality is delegated to the value of `_max`.
///
/// {@endtemplate}
final class _Limited extends Limit {
  /// The concrete maximum value represented by this limit.
  final int _max;

  /// {@macro limited}
  _Limited(this._max);

  @override
  List<Object?> equalizedProperties() => [_max];
  
  @override
  int max() => _max;

  @override
  bool isLimited() => true;
}

/// {@template unlimited}
/// Internal implementation of an unbounded [Limit] that represents the absence
/// of any maximum constraint.
///
/// Instances of `_Unlimited` are created exclusively through
/// [Limit.unlimited], ensuring that external code interacts only with the
/// abstract [Limit] type rather than the internal implementation.
///
/// This class models a “no limit” scenario, commonly used in query builders,
/// pagination systems, or result constraints where unbounded retrieval is
/// allowed.
///
/// ### Example
/// ```dart
/// final limit = Limit.unlimited();
///
/// print(limit.isUnlimited()); // true
/// print(limit.isLimited());   // false
///
/// // Calling max() is invalid:
/// // limit.max(); // ❌ throws HapniumException
/// ```
///
/// ### Design Notes
/// - Calling [max] is unsupported and will always throw.
/// - Equality is based solely on the runtime type.
/// - `_Unlimited` is a singleton-style class (created only via a private
///   constructor).
/// {@endtemplate}
final class _Unlimited extends Limit {
  /// {@macro unlimited}
  _Unlimited._();

  @override
  List<Object?> equalizedProperties() => [runtimeType];

  @override
  bool isLimited() => false;

  @override
  int max() => throw HapniumException("Always check isLimited() because unlimited limits do not define a max value");
}

// PAGE REQUEST

/// {@template page_request}
/// Represents a concrete, paged request with page number, page size, and optional [PageSort].
///
/// [PageRequest] is a standard implementation of [Pageable] for zero-based
/// pagination in repositories or query builders. It supports:
/// - retrieving offsets,
/// - navigating pages ([getNext], [getPreviousOrFirst], [getFirst]),
/// - modifying sorting ([withDirection], [withSorting]).
///
/// Use static factory methods for convenience:
/// - [of] → page number, page size, direction, and properties
/// - [ofSize] → page size, starting at page 0
///
/// ### Example Usage
/// ```dart
/// final page = PageRequest.of(0, 10, SortDirection.asc, ['name']);
/// print(page.getPageNumber()); // 0
/// print(page.getPageSize());   // 10
/// print(page.getSort());       // Sort([SortOrder(property=name, direction=ASC)])
///
/// final nextPage = page.getNext();
/// print(nextPage.getPageNumber()); // 1
///
/// final customSort = page.withDirection(SortDirection.desc, ['date']);
/// print(customSort.getSort()); // Sort([SortOrder(property=date, direction=DESC)])
/// ```
///
/// ### Design Notes
/// - Immutable value object.
/// - Navigational methods always return new instances.
/// - Equality considers both page properties and sorting.
/// - Integrates with `Limit` and `OffsetScrollPosition` via [Pageable.toLimit]
///   and [Pageable.toScrollPosition].
/// {@endtemplate}
final class PageRequest extends AbstractPageRequest {
  /// Sort configuration for this page request.
  final PageSort _sort;

  /// Constructs a [PageRequest] with a page number, page size, and optional [sort].
  ///
  /// If [sort] is not provided, defaults to [PageSort.UNSORTED].
  /// 
  /// {@macro page_request}
  PageRequest(super.pageNumber, super.pageSize, [PageSort? sort]) : _sort = sort ?? PageSort.UNSORTED;

  /// Factory constructor creating a page request with explicit direction and properties.
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.of(0, 10, SortDirection.asc, ['name']);
  /// ```
  static PageRequest of(int pageNumber, int pageSize, PageSortDirection direction, List<String> properties) {
    return PageRequest(pageNumber, pageSize, PageSort.withDirection(direction, properties));
  }

  /// Factory constructor for a page request starting at page 0 with the given size.
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.ofSize(20);
  /// ```
  static PageRequest ofSize(int pageSize) => PageRequest(0, pageSize);

  @override
  PageSort getSort() => _sort;

  @override
  Pageable getNext() => PageRequest(getPageNumber() + 1, getPageSize(), getSort());

  @override
  Pageable getPrevious() => getPageNumber() == 0 ? this : PageRequest(getPageNumber() - 1, getPageSize(), getSort());

  @override
  Pageable getFirst() => PageRequest(0, getPageSize(), getSort());

  @override
  Pageable withPage(int pageNumber) => PageRequest(pageNumber, getPageSize(), getSort());

  /// Returns a new [PageRequest] with the given [direction] and [properties] for sorting.
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.of(0, 10, SortDirection.asc, ['name']);
  /// final newPage = page.withDirection(SortDirection.desc, ['date']);
  /// print(newPage.getSort()); // sort by date descending
  /// ```
  Pageable withDirection(PageSortDirection direction, List<String> properties) => PageRequest(
    getPageNumber(),
    getPageSize(),
    PageSort.withDirection(direction, properties)
  );
 
  /// Returns a new [PageRequest] with a different [sort].
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.ofSize(20);
  /// final sortedPage = page.withSorting(Sort.by(['name'], SortDirection.asc));
  /// ```
  Pageable withSorting(PageSort sort) => PageRequest(getPageNumber(), getPageSize(), sort);

  @override
  List<Object?> equalizedProperties() => [super.equalizedProperties(), _sort];

  @override
  String toString() => 'PageRequest(page: ${getPageNumber()}, size: ${getPageSize()}, sort: $_sort)';
}

/// {@template abstract_page_request}
/// Base class for paged requests that define **page number** and **page size**.
///
/// This class provides common logic for all paginated requests, including:
/// - computing offsets
/// - checking for previous pages
/// - equality and hash code support
///
/// Concrete implementations should extend this class and implement [getPrevious].
///
/// ### Usage Example
/// ```dart
/// final request = MyPageRequest(0, 20);
///
/// print(request.getPageNumber()); // 0
/// print(request.getPageSize());   // 20
/// print(request.getOffset());     // 0
/// print(request.hasPrevious());   // false
/// ```
///
/// ### Design Notes
/// - `_pageNumber` is zero-based.  
/// - `_pageSize` must be at least 1.  
/// - Equality is based on `_pageNumber` and `_pageSize`.  
/// - Supports converting page requests into offset-based scroll positions
///   via [Pageable.toScrollPosition] and limits via [Pageable.toLimit].
/// {@endtemplate}
abstract class AbstractPageRequest extends Pageable {
  /// The zero-based page number.
  final int _pageNumber;

  /// The size of the page (number of items per page).
  final int _pageSize;

  /// {@macro abstract_page_request}
  ///
  /// Throws an assertion error if [pageNumber] < 0 or [pageSize] < 1.
  AbstractPageRequest(this._pageNumber, this._pageSize)
    : assert(_pageNumber >= 0, "Page number must not be less than 0"),
      assert(_pageSize >= 1, "Page size must not be less than 1");

  @override
  int getPageNumber() => _pageNumber;

  @override
  int getPageSize() => _pageSize;

  @override
  int getOffset() => _pageNumber.multiplyBy(_pageSize);

  @override
  bool hasPrevious() => _pageNumber > 0;

  @override
  Pageable getPreviousOrFirst() => hasPrevious() ? getPrevious() : getFirst();

  /// Returns the **previous page** in the pagination sequence.
  ///
  /// This method is intended to provide a convenient way to navigate backward
  /// through paginated data. It is **abstract** in [AbstractPageRequest] because
  /// the concrete logic for constructing the previous page depends on the
  /// specific subclass implementation (for example, `PageRequest` or
  /// `CustomPageRequest`).
  ///
  /// ### Usage
  /// ```dart
  /// final currentPage = MyPageRequest(2, 20);
  /// final previousPage = currentPage.getPrevious();
  /// print(previousPage.getPageNumber()); // 1
  /// ```
  ///
  /// ### Notes
  /// - Subclasses **must** implement this method.
  /// - If the current page is the first page (page 0), the caller should use
  ///   [getPreviousOrFirst] instead to safely obtain a valid Pageable.
  /// - The returned Pageable should maintain the same page size as the current instance.
  ///
  /// ### See Also
  /// - [getPreviousOrFirst] — returns either the previous page or the first page if none exist.
  /// - [getFirst] — returns the first page in the sequence.
  Pageable getPrevious();

  @override
  List<Object?> equalizedProperties() => [_pageNumber, _pageSize];
}