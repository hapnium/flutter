// import 'dart:async';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
//
// import '../state/list_notifier.dart';
//
// extension _Empty on Object {
//   bool _isEmpty() {
//     final val = this;
//     // if (val == null) return true;
//     var result = false;
//     if (val is Iterable) {
//       result = val.isEmpty;
//     } else if (val is String) {
//       result = val.trim().isEmpty;
//     } else if (val is Map) {
//       result = val.isEmpty;
//     }
//     return result;
//   }
// }
//
// mixin StateMixin<T> on ListNotifier {
//   T? _value;
//   SmartStatus<T>? _status;
//
//   void _fillInitialStatus() {
//     _status = (_value == null || _value!._isEmpty())
//         ? SmartStatus<T>.loading()
//         : SmartStatus<T>.success(_value as T);
//   }
//
//   SmartStatus<T> get status {
//     reportRead();
//     return _status ??= _status = SmartStatus.loading();
//   }
//
//   T get state => value;
//
//   set status(SmartStatus<T> newStatus) {
//     if (newStatus == status) return;
//     _status = newStatus;
//     if (newStatus is SuccessStatus<T>) {
//       _value = newStatus.data;
//     }
//     refresh();
//   }
//
//   @protected
//   T get value {
//     reportRead();
//     return _value as T;
//   }
//
//   @protected
//   set value(T newValue) {
//     if (_value == newValue) return;
//     _value = newValue;
//     refresh();
//   }
//
//   @protected
//   void change(SmartStatus<T> status) {
//     if (status != this.status) {
//       this.status = status;
//     }
//   }
//
//   void setSuccess(T data) {
//     change(SmartStatus<T>.success(data));
//   }
//
//   void setError(Object error) {
//     change(SmartStatus<T>.error(error));
//   }
//
//   void setLoading() {
//     change(SmartStatus<T>.loading());
//   }
//
//   void setEmpty() {
//     change(SmartStatus<T>.empty());
//   }
//
//   void futurize(Future<T> Function() body,
//       {T? initialData, String? errorMessage, bool useEmpty = true}) {
//     final compute = body;
//     _value ??= initialData;
//     status = SmartStatus<T>.loading();
//     compute().then((newValue) {
//       if ((newValue == null || newValue._isEmpty()) && useEmpty) {
//         status = SmartStatus<T>.empty();
//       } else {
//         status = SmartStatus<T>.success(newValue);
//       }
//
//       refresh();
//     }, onError: (err) {
//       status = SmartStatus.error(
//           err is Exception ? err : Exception(errorMessage ?? err.toString()));
//       refresh();
//     });
//   }
// }
//
// typedef FuturizeCallback<T> = Future<T> Function(VoidCallback fn);
//
// typedef VoidCallback = void Function();
//
// class SmartListenable<T> extends ListNotifierSingle implements RxInterface<T> {
//   SmartListenable(T val) : _value = val;
//
//   StreamController<T>? _controller;
//
//   StreamController<T> get subject {
//     if (_controller == null) {
//       _controller =
//       StreamController<T>.broadcast(onCancel: addListener(_streamListener));
//       _controller?.add(_value);
//
//     }
//     return _controller!;
//   }
//
//   void _streamListener() {
//     _controller?.add(_value);
//   }
//
//   @override
//   @mustCallSuper
//   void close() {
//     removeListener(_streamListener);
//     _controller?.close();
//     dispose();
//   }
//
//   Stream<T> get stream {
//     return subject.stream;
//   }
//
//   T _value;
//
//   @override
//   T get value {
//     reportRead();
//     return _value;
//   }
//
//   void _notify() {
//     refresh();
//   }
//
//   set value(T newValue) {
//     if (_value == newValue) return;
//     _value = newValue;
//     _notify();
//   }
//
//   T? call([T? v]) {
//     if (v != null) {
//       value = v;
//     }
//     return value;
//   }
//
//   @override
//   StreamSubscription<T> listen(
//       void Function(T)? onData, {
//         Function? onError,
//         void Function()? onDone,
//         bool? cancelOnError,
//       }) =>
//       stream.listen(
//         onData,
//         onError: onError,
//         onDone: onDone,
//         cancelOnError: cancelOnError ?? false,
//       );
//
//   @override
//   String toString() => value.toString();
// }
//
// class Value<T> extends ListNotifier
//     with StateMixin<T>
//     implements ValueListenable<T?> {
//   Value(T val) {
//     _value = val;
//     _fillInitialStatus();
//   }
//
//   @override
//   T get value {
//     reportRead();
//     return _value as T;
//   }
//
//   @override
//   set value(T newValue) {
//     if (_value == newValue) return;
//     _value = newValue;
//     refresh();
//   }
//
//   T? call([T? v]) {
//     if (v != null) {
//       value = v;
//     }
//     return value;
//   }
//
//   void update(T Function(T? value) fn) {
//     value = fn(value);
//     // refresh();
//   }
//
//   @override
//   String toString() => value.toString();
//
//   dynamic toJson() => (value as dynamic)?.toJson();
// }
//
// /// SmartNotifier has a native status and state implementation, with the
// /// Smart Lifecycle
// abstract class SmartNotifier<T> extends Value<T> with SmartLifeCycleMixin {
//   SmartNotifier(super.initial);
// }
//
// extension StateExt<T> on StateMixin<T> {
//   Widget obx(
//       NotifierBuilder<T> widget, {
//         Widget Function(String? error)? onError,
//         Widget? onLoading,
//         Widget? onEmpty,
//         WidgetBuilder? onCustom,
//       }) {
//     return Observer(builder: (context) {
//       if (status.isLoading) {
//         return onLoading ?? const Center(child: CircularProgressIndicator());
//       } else if (status.isError) {
//         return onError != null
//             ? onError(status.errorMessage)
//             : Center(child: Text('A error occurred: ${status.errorMessage}'));
//       } else if (status.isEmpty) {
//         return onEmpty ??
//             const SizedBox.shrink(); // Also can be widget(null); but is risky
//       } else if (status.isSuccess) {
//         return widget(value);
//       } else if (status.isCustom) {
//         return onCustom?.call(context) ??
//             const SizedBox.shrink(); // Also can be widget(null); but is risky
//       }
//       return widget(value);
//     });
//   }
// }
//
// typedef NotifierBuilder<T> = Widget Function(T state);
//
// abstract class SmartStatus<T> with Equality {
//   const SmartStatus();
//
//   factory SmartStatus.loading() => LoadingStatus<T>();
//
//   factory SmartStatus.error(Object message) => ErrorStatus<T, Object>(message);
//
//   factory SmartStatus.empty() => EmptyStatus<T>();
//
//   factory SmartStatus.success(T data) => SuccessStatus<T>(data);
//
//   factory SmartStatus.custom() => CustomStatus<T>();
// }
//
// class CustomStatus<T> extends SmartStatus<T> {
//   @override
//   List get props => [];
// }
//
// class LoadingStatus<T> extends SmartStatus<T> {
//   @override
//   List get props => [];
// }
//
// class SuccessStatus<T> extends SmartStatus<T> {
//   final T data;
//
//   const SuccessStatus(this.data);
//
//   @override
//   List get props => [data];
// }
//
// class ErrorStatus<T, S> extends SmartStatus<T> {
//   final S? error;
//
//   const ErrorStatus([this.error]);
//
//   @override
//   List get props => [error];
// }
//
// class EmptyStatus<T> extends SmartStatus<T> {
//   @override
//   List get props => [];
// }
//
// extension StatusDataExt<T> on SmartStatus<T> {
//   bool get isLoading => this is LoadingStatus;
//
//   bool get isSuccess => this is SuccessStatus;
//
//   bool get isError => this is ErrorStatus;
//
//   bool get isEmpty => this is EmptyStatus;
//
//   bool get isCustom => !isLoading && !isSuccess && !isError && !isEmpty;
//
//   dynamic get error {
//     if (this is ErrorStatus) {
//       return (this as ErrorStatus).error;
//     }
//     return null;
//   }
//
//   String get errorMessage {
//     final isError = this is ErrorStatus;
//     if (isError) {
//       final err = this as ErrorStatus;
//       if (err.error != null) {
//         if (err.error is String) {
//           return err.error as String;
//         }
//         return err.error.toString();
//       }
//     }
//
//     return '';
//   }
//
//   T? get data {
//     if (this is SuccessStatus<T>) {
//       final success = this as SuccessStatus<T>;
//       return success.data;
//     }
//     return null;
//   }
// }