import 'package:flutter/cupertino.dart' show ScrollController, WidgetsBindingObserver;

import '../mixins/smart_lifecycle.dart';
import 'list_notifier.dart';

abstract class SmartController extends ListNotifier with SmartLifecycle {
  bool isPermanent = false;

  /// Rebuilds `GetBuilder` each time you call `update()`;
  /// Can take a List of [ids], that will only update the matching
  /// `GetBuilder( id: )`,
  /// [ids] can be reused among `GetBuilders` like group tags.
  /// The update will only notify the Widgets, if [condition] is true.
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) {
      return;
    }
    if (ids == null) {
      refresh();
    } else {
      for (final id in ids) {
        refreshGroup(id);
      }
    }
  }
}

/// this mixin allow to fetch data when the scroll is at the bottom or on the
/// top
mixin ScrollMixin on SmartLifecycle {
  final ScrollController scroll = ScrollController();

  @override
  void onInit() {
    super.onInit();
    scroll.addListener(_listener);
  }

  bool _canFetchBottom = true;

  bool _canFetchTop = true;

  void _listener() {
    if (scroll.position.atEdge) {
      _checkIfCanLoadMore();
    }
  }

  Future<void> _checkIfCanLoadMore() async {
    if (scroll.position.pixels == 0) {
      if (!_canFetchTop) return;
      _canFetchTop = false;
      await onTopScroll();
      _canFetchTop = true;
    } else {
      if (!_canFetchBottom) return;
      _canFetchBottom = false;
      await onEndScroll();
      _canFetchBottom = true;
    }
  }

  /// this method is called when the scroll is at the bottom
  Future<void> onEndScroll();

  /// this method is called when the scroll is at the top
  Future<void> onTopScroll();

  @override
  void onClose() {
    scroll.removeListener(_listener);
    super.onClose();
  }
}

/// A clean controller to be used with only Sx variables
abstract class SxController with SmartLifecycle {}
//
// /// A recommended way to use Smart with Future fetching
// abstract class SmartStateController<T> extends SmartController with StateMixin<T> {}
//
// /// A controller with super lifecycles (including native lifecycles) and StateMixins
// abstract class SuperSmartController<T> extends SmartFullLifeCycleController with SmartFullLifeCycleMixin, StateMixin<T> {}

/// A controller with super lifecycles (including native lifecycles)
abstract class SmartFullLifeCycleController extends SmartController with WidgetsBindingObserver {}