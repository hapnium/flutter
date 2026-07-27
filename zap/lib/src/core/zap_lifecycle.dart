import 'package:flutter/foundation.dart' show nonVirtual;
import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsFlutterBinding, protected, mustCallSuper;

/// {@template zap_lifecycle}
/// Mixin that provides a structured, ordered lifecycle for controllers,
/// services, and other long-lived objects in a Flutter application.
///
/// `ZapLifecycle` defines five hooks that mirror the typical object lifetime:
///
/// 1. **[onStart]** — Called once when the instance is first activated.
///   Delegates to [onInit] and sets an internal guard so subsequent
///   calls are no-ops. Marked `@nonVirtual` — subclasses must not override.
/// 2. **[onInit]** — Override this to perform synchronous initialization
///   (registering listeners, opening streams, allocating resources). The
///   default implementation schedules [onReady] for the next frame via
///   a post-frame callback.
/// 3. **[onReady]** — Called one frame after [onInit]. Ideal for navigation
///   events, dialogs, or async requests that need the widget tree to be
///   fully built. The default implementation is a no-op.
/// 4. **[onClose]** — Called before [onDelete]. Use this to release resources
///   (close streams, dispose controllers, persist data). The default
///   implementation is a no-op.
/// 5. **[onDelete]** — Called when the instance is removed from memory.
///   Delegates to [onClose] and sets an internal guard so subsequent
///   calls are no-ops. Marked `@nonVirtual` — subclasses must not override.
///
/// ### State tracking
///
/// - [initialized]: `true` after [onStart] has been called.
/// - [isClosed]: `true` after [onDelete] has been called.
///
/// ### Guard behavior
///
/// Both [onStart] and [onDelete] are idempotent. Calling them multiple
/// times has no effect beyond the first invocation. This prevents double
/// initialization or double disposal, which are common bugs in
/// controller-based architectures.
///
/// ### Example
/// ```dart
/// class MyController with ZapLifecycle {
///   late final StreamSubscription _sub;
///
///   MyController() {
///     onStart(); // triggers onInit → (next frame) → onReady
///   }
///
///   @override
///   void onInit() {
///     super.onInit(); // required: schedules onReady
///     _sub = eventStream.listen(_onEvent);
///   }
///
///   @override
///   void onReady() {
///     // safe to show dialogs, navigate, or start async work
///     Navigator.of(context).pushNamed('/dashboard');
///   }
///
///   @override
///   void onClose() {
///     _sub.cancel();
///   }
/// }
/// ```
///
/// ### Calling onDelete
///
/// When the controller is no longer needed, call [onDelete] to trigger
/// teardown:
/// ```dart
/// controller.onDelete(); // triggers onClose
/// // controller.initialized is still true
/// // controller.isClosed is now true
/// ```
///
/// ### Relationship with GetX
///
/// This lifecycle is modeled after GetX's `GetxController` lifecycle but
/// is independent of any state management framework. It can be mixed into
/// any class.
/// {@endtemplate}
mixin ZapLifecycle {
  /// {@template zap_lifecycle_onInit}
  /// Called immediately after the widget or controller is allocated.
  ///
  /// Override this method to perform synchronous initialization such as:
  /// - Registering stream listeners
  /// - Opening database connections
  /// - Allocating controllers (e.g., `AnimationController`)
  /// - Setting up default state
  ///
  /// **You must call `super.onInit()`** to ensure [onReady] is scheduled
  /// for the next frame. Failing to call `super.onInit()` will prevent
  /// [onReady] from ever being invoked.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void onInit() {
  ///   super.onInit();
  ///   _loadInitialData();
  /// }
  /// ```
  ///
  /// ### Timing
  ///
  /// This method is called synchronously from [onStart]. Any asynchronous
  /// work should be started here but awaited in [onReady] (after the
  /// widget tree is built).
  /// {@endtemplate}
  @protected
  @mustCallSuper
  void onInit() {
    Engine.instance.addPostFrameCallback((_) => onReady());
  }

  /// {@template zap_lifecycle_onReady}
  /// Called one frame after [onInit], once the widget tree is fully built.
  ///
  /// This is the ideal place for operations that require the widget tree
  /// to be mounted, such as:
  /// - Showing a dialog or snackbar
  /// - Navigating to a new route
  /// - Starting an async network request
  /// - Accessing `BuildContext`-dependent features
  ///
  /// The default implementation is a no-op. Override it without calling
  /// `super.onReady()`.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void onReady() {
  ///   showDialog(
  ///     context: context,
  ///     builder: (_) => const WelcomeDialog(),
  ///   );
  /// }
  /// ```
  ///
  /// ### Timing
  ///
  /// This method is invoked via `WidgetsBinding.instance.addPostFrameCallback`,
  /// which means it runs after the current frame's build phase completes.
  /// In rare cases (e.g., during app startup), the callback may fire
  /// before any frame is scheduled — ensure your code handles this gracefully.
  /// {@endtemplate}
  void onReady() {}

  /// {@template zap_lifecycle_onClose}
  /// Called just before [onDelete] to release resources.
  ///
  /// Override this method to perform cleanup such as:
  /// - Closing `StreamController`s or cancelling `StreamSubscription`s
  /// - Disposing `AnimationController`s or `TextEditingController`s
  /// - Persisting unsaved data to disk
  /// - Removing event listeners
  ///
  /// The default implementation is a no-op. Override it without calling
  /// `super.onClose()`.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void onClose() {
  ///   _animationController.dispose();
  ///   _subscription.cancel();
  /// }
  /// ```
  ///
  /// ### Order of operations
  ///
  /// [onClose] is called by [onDelete] before the [isClosed] flag is set.
  /// This means [isClosed] is still `false` during [onClose] execution.
  /// {@endtemplate}
  void onClose() {}

  /// {@template zap_lifecycle_initialized}
  /// Whether [onStart] has been called at least once.
  ///
  /// Returns `true` after the first invocation of [onStart], which in turn
  /// calls [onInit]. Subsequent calls to [onStart] are no-ops.
  ///
  /// ### Example
  /// ```dart
  /// if (!controller.initialized) {
  ///   controller.onStart();
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// This is primarily used internally to enforce single-initialization
  /// semantics. It can also be checked by consumers to verify that a
  /// controller has been activated.
  /// {@endtemplate}
  bool get initialized => _initialized;

  bool _initialized = false;

  /// {@template zap_lifecycle_onStart}
  /// Triggers the initialization sequence exactly once.
  ///
  /// On the first call:
  /// 1. [onInit] is invoked.
  /// 2. [initialized] becomes `true`.
  ///
  /// All subsequent calls are no-ops, ensuring that initialization logic
  /// runs exactly once even if [onStart] is called multiple times.
  ///
  /// This method is marked `@nonVirtual` and `@mustCallSuper` — subclasses
  /// must not override it, and callers must call it to activate the lifecycle.
  ///
  /// ### Example
  /// ```dart
  /// class MyController with ZapLifecycle {
  ///   MyController() {
  ///     onStart(); // activate lifecycle
  ///   }
  /// }
  /// ```
  ///
  /// ### Guard behavior
  ///
  /// If [onStart] has already been called, this method returns immediately
  /// without invoking [onInit] again. This prevents double-initialization
  /// bugs.
  /// {@endtemplate}
  @mustCallSuper
  @nonVirtual
  void onStart() {
    if (_initialized) return;
    onInit();
    _initialized = true;
  }

  /// {@template zap_lifecycle_isClosed}
  /// Whether [onDelete] has been called at least once.
  ///
  /// Returns `true` after the first invocation of [onDelete], which in turn
  /// calls [onClose]. Subsequent calls to [onDelete] are no-ops.
  ///
  /// ### Example
  /// ```dart
  /// if (!controller.isClosed) {
  ///   controller.onDelete();
  /// }
  /// ```
  ///
  /// ### Usage
  ///
  /// This flag can be used by consumers to check if a controller has been
  /// torn down before attempting to use it.
  /// {@endtemplate}
  bool get isClosed => _isClosed;

  bool _isClosed = false;

  /// {@template zap_lifecycle_onDelete}
  /// Triggers the teardown sequence exactly once.
  ///
  /// On the first call:
  /// 1. [isClosed] becomes `true`.
  /// 2. [onClose] is invoked.
  ///
  /// All subsequent calls are no-ops, ensuring that cleanup logic
  /// runs exactly once even if [onDelete] is called multiple times.
  ///
  /// This method is marked `@nonVirtual` and `@mustCallSuper` — subclasses
  /// must not override it.
  ///
  /// ### Example
  /// ```dart
  /// // When the controller is no longer needed
  /// controller.onDelete();
  /// // controller.isClosed == true
  /// // controller.onClose() has been called
  /// ```
  ///
  /// ### Guard behavior
  ///
  /// If [onDelete] has already been called, this method returns immediately
  /// without invoking [onClose] again. This prevents double-disposal bugs.
  ///
  /// ### Order of operations
  ///
  /// Note that [isClosed] is set to `true` *before* [onClose] is called.
  /// This means [onClose] can check [isClosed] to determine if the
  /// teardown is in progress.
  /// {@endtemplate}
  @mustCallSuper
  @nonVirtual
  void onDelete() {
    if (_isClosed) return;
    _isClosed = true;
    onClose();
  }
}

/// {@template engine}
/// Lightweight accessor for the Flutter `WidgetsBinding` instance.
///
/// `Engine` ensures that `WidgetsFlutterBinding` has been initialized before
/// any lifecycle callback is scheduled. It is used internally by
/// [ZapLifecycle.onInit] to register the [onReady] post-frame callback.
///
/// ### Purpose
///
/// The `WidgetsBinding` must be initialized before calling
/// `addPostFrameCallback`. In most Flutter apps this is handled by the
/// framework, but when using `ZapLifecycle` in a pure Dart context or in
/// tests, the binding may not be available. `Engine.instance` guarantees
/// the binding exists by calling `WidgetsFlutterBinding.ensureInitialized()`.
///
/// ### Thread safety
///
/// `WidgetsFlutterBinding.ensureInitialized()` is safe to call multiple
/// times; it returns the existing binding if already initialized.
///
/// ### Example
/// ```dart
/// // Manually ensure the binding is initialized
/// final binding = Engine.instance;
/// binding.addPostFrameCallback((_) {
///   print('Frame completed');
/// });
/// ```
/// {@endtemplate}
class Engine {
  /// {@template engine_instance}
  /// Returns the global [WidgetsBinding] instance, initializing it if needed.
  ///
  /// This is a convenience wrapper around
  /// `WidgetsFlutterBinding.ensureInitialized()`. If the binding is already
  /// initialized, the existing instance is returned. Otherwise, a new
  /// `WidgetsFlutterBinding` is created and initialized.
  ///
  /// ### Returns
  ///
  /// The global [WidgetsBinding] instance. This is always non-null.
  ///
  /// ### Example
  /// ```dart
  /// final binding = Engine.instance;
  /// binding.addPostFrameCallback((_) {
  ///   print('Post-frame callback fired');
  /// });
  /// ```
  ///
  /// ### Usage in tests
  ///
  /// In widget tests, `Engine.instance` should be called in `setUpAll` or
  /// before the first lifecycle hook:
  /// ```dart
  /// setUpAll(() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  /// });
  /// ```
  /// {@endtemplate}
  static WidgetsBinding get instance {
    return WidgetsFlutterBinding.ensureInitialized();
  }
}