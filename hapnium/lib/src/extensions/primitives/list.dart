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

import '../../utils/typedefs.dart';
import 'iterable.dart';
import '../others/t.dart';

extension ListExtensions<T> on List<T> {
  /// Checks if all list data have same value.
  /// 
  /// ## Returns
  /// - `true` if all list data have same value
  /// - `false` otherwise
  bool get isOneAKind {
    if(isEmpty) {
      return false;
    } else {
      var first = this[0];
      int len = length;

      for (int i = 0; i < len; i++) {
        if (this[i] != first) {
          return false;
        }
      }

      return true;
    }
  }

  /// Adds an item to a list if a condition is met.
  /// 
  /// ## Parameters
  /// - `condition`: The condition to check
  /// - `element`: The element to add
  void addIf(ConditionTester<T> condition, T element) {
    for (var item in List<T>.from(this)) {
      if (condition(item)) {
        add(element);
      }
    }

    return;
  }

  /// Adds all items from another list to a list if a condition is met.
  /// 
  /// ## Parameters
  /// - `condition`: The condition to check
  /// - `items`: The items to add
  void addAllIf(ConditionTester<T> condition, Iterable<T> items) {
    if(all(condition)) {
      addAll(items);
    }
  }

  /// Removes an item from a list if a condition is met.
  /// 
  /// ## Parameters
  /// - `condition`: The condition to check
  /// - `element`: The element to remove
  void removeIf(ConditionTester<T> condition, T element) {
    for (var item in List<T>.from(this)) {
      if (condition(item)) {
        remove(element);
      }
    }
  }

  /// Removes all items from another list if a condition is met.
  /// 
  /// ## Parameters
  /// - `condition`: The condition to check
  /// - `items`: The items to remove
  void removeAllIf(ConditionTester<T> condition, Iterable<T> items) {
    if(all(condition)) {
      removeWhere((element) => items.any((e) => e.equals(element)));
    }
  }

  /// Removes and returns the first element of the list.
  /// 
  /// Returns `null` if the list is empty.
  T? shift() {
    if (isEmpty) return null;
    return removeAt(0);
  }

  /// Removes and returns the last element of the list.
  /// 
  /// Returns `null` if the list is empty.
  T? pop() {
    if (isEmpty) return null;
    return removeAt(length - 1);
  }

  /// Returns a new list with the elements in reverse order.
  List<T> reverse() {
    return List<T>.from(this).reversed.toList();
  }
}