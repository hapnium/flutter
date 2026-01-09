import 'package:flutter/material.dart';

/// Base class for reactive field states.
///
/// Extend this class to create type-safe state containers for your
/// application data. Each [FieldState] is a [ValueNotifier] that
/// notifies listeners when its value changes.
///
/// ## Type Parameters
///
/// * `T` - The type of value stored in this state
///
/// ## Example
///
/// ```dart
/// class CounterState extends FieldState<int> {
///   CounterState() : super(0);
///   
///   void increment() => value++;
///   void decrement() => value--;
/// }
///
/// class UserState extends FieldState<User?> {
///   UserState() : super(null);
///   
///   bool get isLoggedIn => value != null;
/// }
/// ```
abstract class FieldState<T> extends ValueNotifier<T> {
  /// Creates a [FieldState] with the initial [value].
  FieldState(super.value);
}

/// Mixin providing convenient state management methods.
///
/// Include this mixin in your widget states to access the [use], [watch],
/// and [batch] methods for interacting with [FieldController] instances.
///
/// ## When to Use
///
/// Use this mixin when:
/// - You need to manage multiple related states
/// - You want to reduce boilerplate for state access
/// - You need batch update capabilities
///
/// ## See Also
///
/// * [FieldController] for managing states
/// * [FieldState] for individual state containers
mixin FieldMixin {
  /// Registers a state with a controller or returns an existing instance.
  ///
  /// This method ensures that only one instance of each state type exists
  /// within a controller. If a state of type [S] is already registered,
  /// the existing instance is returned.
  ///
  /// ## Parameters
  ///
  /// * `controller` - The [FieldController] managing the state
  /// * `initialState` - The initial state instance to register
  ///
  /// ## Returns
  ///
  /// The registered [FieldState] instance
  ///
  /// ## Example
  ///
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> with FieldMixin {
  ///   final _controller = FieldController();
  ///   
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     // Register states
  ///     final emailState = use(_controller, EmailState());
  ///     final passwordState = use(_controller, PasswordState());
  ///   }
  /// }
  /// ```
  S use<S extends FieldState>(FieldController controller, S initialState) => controller.add<S>(initialState);

  /// Watches a state's value and rebuilds when it changes.
  ///
  /// This method retrieves the current value of a state and ensures that
  /// the calling widget rebuilds whenever the state's value changes.
  ///
  /// ## Type Parameters
  ///
  /// * `S` - The [FieldState] type to watch
  /// * `V` - The value type returned by the state
  ///
  /// ## Parameters
  ///
  /// * `controller` - The [FieldController] containing the state
  ///
  /// ## Returns
  ///
  /// The current value of the watched state
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   final email = watch<EmailState, String>(_controller);
  ///   final count = watch<CounterState, int>(_controller);
  ///   
  ///   return Text('Email: $email, Count: $count');
  /// }
  /// ```
  V watch<S extends FieldState<V>, V>(FieldController controller) => controller.find<S>().value;

  /// Performs multiple state updates in a single operation.
  ///
  /// This method groups multiple state updates together, which is useful
  /// for:
  /// - Ensuring atomic updates (all or nothing)
  /// - Reducing the number of rebuilds
  /// - Maintaining data consistency
  ///
  /// ## Parameters
  ///
  /// * `controller` - The [FieldController] to update
  /// * `updates` - A function that performs state updates
  ///
  /// ## Example
  ///
  /// ```dart
  /// void resetForm() {
  ///   batch(_controller, (controller) {
  ///     controller.update<EmailState, String>('');
  ///     controller.update<PasswordState, String>('');
  ///     controller.update<RememberMeState, bool>(false);
  ///   });
  /// }
  /// ```
  void batch(FieldController controller, void Function(FieldController) updates) => updates(controller);
}

/// Signature for callbacks that provide access to a field controller.
///
/// This typedef defines the function signature for callbacks that receive
/// a [FieldController] instance, typically used in form field widgets to
/// expose controller functionality to parent widgets.
///
/// This pattern is useful when you need to give parent widgets control over
/// field behaviors like focus, validation, or text manipulation.
///
/// Example usage:
/// ```dart
/// class CustomTextField extends StatefulWidget {
///   final FieldControllerValue? onControllerCreated;
///
///   const CustomTextField({this.onControllerCreated});
///
///   @override
///   State<CustomTextField> createState() => _CustomTextFieldState();
/// }
///
/// class _CustomTextFieldState extends State<CustomTextField> {
///   late final FieldController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = FieldController();
///     widget.onControllerCreated?.call(_controller);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
typedef FieldControllerValue = void Function(FieldController controller);

/// A state management system for form fields and UI components.
///
/// This library provides a lightweight, reactive state management solution
/// optimized for form fields and UI state. It combines `ValueNotifier`-based
/// reactivity with a controller pattern for managing multiple related states.
///
/// ## Overview
///
/// The system consists of three main components:
/// 1. [FieldState] - A reactive state container
/// 2. [FieldController] - Manages multiple FieldStates and their lifecycle
/// 3. [FieldMixin] - Provides convenience methods for state access
///
/// ## Key Features
///
/// - **Reactivity**: Built on `ValueNotifier` for efficient UI updates
/// - **Type Safety**: Strongly typed states and values
/// - **Lifecycle Management**: Automatic cleanup of resources
/// - **Batch Updates**: Atomic updates to multiple states
/// - **Dependency Injection**: Easy state access via controllers
///
/// ## Example Usage
///
/// ```dart
/// // 1. Define your state classes
/// class EmailState extends FieldState<String> {
///   EmailState() : super('');
///   
///   bool get isValid => value.contains('@');
/// }
///
/// class PasswordState extends FieldState<String> {
///   PasswordState() : super('');
///   
///   bool get isSecure => value.length >= 8;
/// }
///
/// // 2. Create a widget using the FieldMixin
/// class LoginForm extends StatefulWidget {
///   const LoginForm({super.key});
///
///   @override
///   State<LoginForm> createState() => _LoginFormState();
/// }
///
/// class _LoginFormState extends State<LoginForm> with FieldMixin {
///   final _controller = FieldController();
///
///   @override
///   void initState() {
///     super.initState();
///     _controller.onInit();
///     
///     // Register states
///     use(_controller, EmailState());
///     use(_controller, PasswordState());
///     
///     // Execute after first frame
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       _controller.onReady();
///     });
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     // Watch for state changes
///     final email = watch<EmailState, String>(_controller);
///     final password = watch<PasswordState, String>(_controller);
///     
///     return Column(
///       children: [
///         TextField(
///           onChanged: (value) => _controller.update<EmailState, String>(value),
///           decoration: InputDecoration(
///             labelText: 'Email',
///             errorText: email.isEmpty ? 'Required' : null,
///           ),
///         ),
///         TextField(
///           onChanged: (value) => _controller.update<PasswordState, String>(value),
///           obscureText: true,
///           decoration: InputDecoration(
///             labelText: 'Password',
///             errorText: password.length < 8 ? 'Too short' : null,
///           ),
///         ),
///         ElevatedButton(
///           onPressed: () {
///             // Batch update multiple states
///             batch(_controller, (controller) {
///               controller.update<EmailState, String>('');
///               controller.update<PasswordState, String>('');
///             });
///           },
///           child: const Text('Reset'),
///         ),
///       ],
///     );
///   }
/// }
/// ```

/// A callback that receives a [FieldController] and returns a value.
///
/// This typedef is commonly used for creating reactive computations or
/// selectors that depend on multiple states managed by a controller.
///
/// ## Type Parameters
///
/// * `T` - The type of value returned by the callback
///
/// ## Example
///
/// ```dart
/// // Create a selector that computes a derived value
/// final isFormValid = FieldSubscriber<bool>((controller) {
///   final email = controller.find<EmailState>().value;
///   final password = controller.find<PasswordState>().value;
///   return email.isNotEmpty && password.length >= 8;
/// });
///
/// // Use in a widget
/// final isValid = isFormValid(_controller);
/// ```
typedef FieldSubscriber<T> = T Function(FieldController controller);

/// Central controller for managing a collection of [FieldState] instances.
///
/// This class serves as a container and lifecycle manager for related states.
/// It provides methods to register, access, update, and dispose of states
/// in a coordinated manner.
///
/// ## Lifecycle
///
/// 1. **onInit** - Called when the controller is first set up
/// 2. **onReady** - Called after the first frame is rendered
/// 3. **onClose** - Called when the controller is being disposed
///
/// ## Best Practices
///
/// - One controller per logical feature or form
/// - Dispose controllers in `State.dispose()` to prevent memory leaks
/// - Use [batch] for related updates to reduce rebuilds
/// - Prefer [watch] over direct value access in UI code
///
/// ## See Also
///
/// * [FieldMixin] for convenient access methods
/// * [FieldState] for individual state containers
class FieldController extends ChangeNotifier {
  final Map<Type, FieldState> _states = {};

  /// Called when the controller is first initialized.
  ///
  /// Override this method to perform setup operations like:
  /// - Loading initial data
  /// - Setting up listeners
  /// - Initializing dependencies
  ///
  /// ## Important
  ///
  /// Always call `super.onInit()` when overriding this method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void onInit() {
  ///   super.onInit();
  ///   // Load saved preferences
  ///   _loadPreferences();
  ///   // Setup network listeners
  ///   _setupListeners();
  /// }
  /// ```
  @mustCallSuper
  void onInit() {}

  /// Called after the first frame is rendered.
  ///
  /// Use this for operations that require the widget tree to be fully built,
  /// such as:
  /// - Showing snackbars or dialogs
  /// - Starting animations
  /// - Focusing form fields
  ///
  /// ## Important
  ///
  /// Always call `super.onReady()` when overriding this method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void onReady() {
  ///   super.onReady();
  ///   // Auto-focus the first field
  ///   FocusScope.of(context).requestFocus(_firstFieldFocus);
  ///   // Show welcome message
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text('Welcome back!')),
  ///   );
  /// }
  /// ```
  @mustCallSuper
  void onReady() { }

  /// Called when the controller is being disposed.
  ///
  /// Override this method to clean up resources like:
  /// - Cancelling timers
  /// - Closing streams
  /// - Removing listeners
  ///
  /// ## Important
  ///
  /// Always call `super.onClose()` when overriding this method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Timer? _timer;
  /// StreamSubscription? _subscription;
  ///
  /// @override
  /// void onClose() {
  ///   super.onClose();
  ///   _timer?.cancel();
  ///   _subscription?.cancel();
  /// }
  /// ```
  @mustCallSuper
  void onClose() {
    for (var state in _states.values) {
      state.removeListener(notifyListeners);
      state.dispose();
    }
  }

  /// Registers a state with this controller.
  ///
  /// If a state of the same type is already registered, the existing
  /// instance is returned (singleton pattern per type).
  ///
  /// ## Type Parameters
  ///
  /// * `T` - The [FieldState] type to register
  ///
  /// ## Parameters
  ///
  /// * `state` - The state instance to register
  ///
  /// ## Returns
  ///
  /// The registered state instance
  ///
  /// ## Throws
  ///
  /// Throws if the state is null
  ///
  /// ## Example
  ///
  /// ```dart
  /// final emailState = controller.add(EmailState());
  /// final passwordState = controller.add(PasswordState());
  /// ```
  T add<T extends FieldState>(T state) {
    if (_states.containsKey(T)) return _states[T] as T;
    _states[T] = state;
    state.addListener(notifyListeners);
    return state;
  }

  /// Retrieves a registered state by its type.
  ///
  /// ## Type Parameters
  ///
  /// * `T` - The [FieldState] type to retrieve
  ///
  /// ## Returns
  ///
  /// The state instance of type [T]
  ///
  /// ## Throws
  ///
  /// Throws an [Exception] if no state of type [T] is registered
  ///
  /// ## Example
  ///
  /// ```dart
  /// final emailState = controller.find<EmailState>();
  /// final passwordState = controller.find<PasswordState>();
  /// ```
  T find<T extends FieldState>() {
    final state = _states[T];
    if (state == null) throw Exception("FieldState $T not registered.");
    return state as T;
  }

  /// Updates the value of a registered state.
  ///
  /// This is a convenience method for updating state values without
  /// explicitly retrieving the state instance first.
  ///
  /// ## Type Parameters
  ///
  /// * `T` - The [FieldState] type to update
  /// * `V` - The value type of the state
  ///
  /// ## Parameters
  ///
  /// * `newValue` - The new value to set
  ///
  /// ## Throws
  ///
  /// Throws an [Exception] if no state of type [T] is registered
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Update email
  /// controller.update<EmailState, String>('user@example.com');
  /// 
  /// // Update counter
  /// controller.update<CounterState, int>(42);
  /// ```
  void update<T extends FieldState<V>, V>(V newValue) {
    find<T>().value = newValue;
  }

  /// Removes and disposes a state from the controller.
  ///
  /// This method:
  /// 1. Removes the listener from the state
  /// 2. Disposes the state
  /// 3. Removes it from the registry
  /// 4. Notifies listeners of the change
  ///
  /// ## Type Parameters
  ///
  /// * `T` - The [FieldState] type to remove
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Remove temporary state
  /// controller.remove<TemporaryState>();
  /// 
  /// // Clean up when switching modes
  /// void switchToEditMode() {
  ///   controller.remove<ViewModeState>();
  ///   controller.add(EditModeState());
  /// }
  /// ```
  void remove<T extends FieldState>() {
    if (_states.containsKey(T)) {
      _states[T]!.removeListener(notifyListeners);
      _states[T]!.dispose();
      _states.remove(T);
      notifyListeners();
    }
  }

  /// Checks if a state type is registered with this controller.
  ///
  /// ## Type Parameters
  ///
  /// * `T` - The [FieldState] type to check
  ///
  /// ## Returns
  ///
  /// `true` if a state of type [T] is registered, `false` otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (controller.has<EmailState>()) {
  ///   // State is available
  /// } else {
  ///   // State needs to be registered
  ///   controller.add(EmailState());
  /// }
  /// ```
  bool has<T extends FieldState>() => _states.containsKey(T);

  /// Creates a [FieldSubscriber] for a specific state value.
  ///
  /// This method generates a subscriber function that extracts a value
  /// from a specific state type. Useful for creating reusable selectors.
  ///
  /// ## Type Parameters
  ///
  /// * `S` - The [FieldState] type to subscribe to
  /// * `T` - The value type returned by the subscriber
  ///
  /// ## Returns
  ///
  /// A [FieldSubscriber] that returns the current value of state [S]
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Create subscriber
  /// final emailSubscriber = controller.rx<EmailState, String>();
  /// 
  /// // Use subscriber
  /// final currentEmail = emailSubscriber(controller);
  /// 
  /// // Or pass to widgets
  /// EmailDisplay(
  ///   emailProvider: controller.rx<EmailState, String>(),
  /// );
  /// ```
  FieldSubscriber<T> rx<S extends FieldState<T>, T>() => (controller) => controller.find<S>().value;

  /// Disposes the controller and all registered states.
  ///
  /// This method calls [onClose] to clean up resources, then calls
  /// `super.dispose()`.
  ///
  /// ## Important
  ///
  /// Always call this method in `State.dispose()` to prevent memory leaks.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _controller.dispose();
  ///   super.dispose();
  /// }
  /// ```
  @override
  void dispose() {
    onClose();
    super.dispose();
  }
}

/// A widget that manages the lifecycle of a [FieldController] for form state.
///
/// `FieldFormManager` is a [StatefulWidget] that provides a convenient way to
/// manage form state using the [FieldController] system. It handles controller
/// initialization, lifecycle management, and proper disposal, making it easier
/// to work with reactive form state in Flutter applications.
///
/// ## Key Features
///
/// - **Flexible Controller Ownership**: Can use either an external controller
///   (provided by parent) or create its own internal controller
/// - **Lifecycle Management**: Automatically calls [FieldController.onInit],
///   [FieldController.onReady], and disposes the controller when needed
/// - **Hot Reload Support**: Handles controller changes during hot reload
/// - **Builder Pattern**: Uses a builder function for clean widget composition
///
/// ## Usage Patterns
///
/// ### 1. Internal Controller (Managed)
/// When you don't need to access the controller from outside:
///
/// ```dart
/// FieldFormManager(
///   onInit: (controller) {
///     // Set up initial states
///     controller.add(EmailState(''));
///     controller.add(PasswordState(''));
///   },
///   builder: (context, controller) {
///     final email = controller.watch<EmailState, String>();
///     final password = controller.watch<PasswordState, String>();
///     
///     return Column(
///       children: [
///         TextField(
///           onChanged: (value) => controller.update<EmailState, String>(value),
///           decoration: InputDecoration(labelText: 'Email'),
///         ),
///         TextField(
///           onChanged: (value) => controller.update<PasswordState, String>(value),
///           obscureText: true,
///           decoration: InputDecoration(labelText: 'Password'),
///         ),
///       ],
///     );
///   },
/// )
/// ```
///
/// ### 2. External Controller (Controlled)
/// When you need to share or control the controller from a parent widget:
///
/// ```dart
/// class ParentWidget extends StatefulWidget {
///   const ParentWidget({super.key});
///
///   @override
///   State<ParentWidget> createState() => _ParentWidgetState();
/// }
///
/// class _ParentWidgetState extends State<ParentWidget> {
///   late final FieldController _formController;
///
///   @override
///   void initState() {
///     super.initState();
///     _formController = FieldController();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         FieldFormManager(
///           stateController: _formController,
///           onInit: (controller) {
///             // Optional: Additional setup
///             controller.add(EmailState(''));
///             controller.add(PasswordState(''));
///           },
///           builder: (context, controller) {
///             return LoginForm(controller: controller);
///           },
///         ),
///         ElevatedButton(
///           onPressed: () {
///             // Parent can interact with the controller
///             _formController.update<EmailState, String>('');
///             _formController.update<PasswordState, String>('');
///           },
///           child: const Text('Reset Form'),
///         ),
///       ],
///     );
///   }
///
///   @override
///   void dispose() {
///     _formController.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// ## Lifecycle
///
/// The manager ensures proper lifecycle events are called:
/// 1. **onInit**: Called immediately after controller creation/assignment
/// 2. **onReady**: Called after the first frame is rendered
/// 3. **onClose**: Called when the controller is disposed
///
/// ## Important Considerations
///
/// - When using an external controller (`stateController`), the parent widget
///   is responsible for disposing it
/// - When using an internal controller, `FieldFormManager` handles disposal
/// - The `onInit` callback is useful for setting up initial state values
/// - The `onReady` timing is ideal for focus management or showing dialogs
///
/// ## See Also
///
/// - [FieldController] for the underlying state management system
/// - [FieldMixin] for convenient state access methods
/// - [FieldState] for individual state containers
class FieldFormManager extends StatefulWidget {
  /// An optional [FieldController] instance provided by a parent widget.
  ///
  /// When provided, `FieldFormManager` will use this controller instead of
  /// creating its own. The parent widget is responsible for disposing this
  /// controller.
  ///
  /// If `null`, `FieldFormManager` will create and manage its own controller
  /// instance, disposing it when the widget is removed from the tree.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Parent creates and manages the controller
  /// class ParentWidget extends StatefulWidget {
  ///   @override
  ///   State<ParentWidget> createState() => _ParentWidgetState();
  /// }
  ///
  /// class _ParentWidgetState extends State<ParentWidget> {
  ///   late final FieldController _sharedController;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     _sharedController = FieldController();
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return FieldFormManager(
  ///       stateController: _sharedController,
  ///       builder: (context, controller) => /* ... */,
  ///     );
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     _sharedController.dispose();
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  final FieldController? stateController;

  /// An optional callback that is called after the controller is initialized.
  ///
  /// This callback provides an opportunity to:
  /// - Set up initial state values
  /// - Register additional states
  /// - Perform any other controller setup
  ///
  /// The callback is called in the following situations:
  /// 1. When the widget is first initialized
  /// 2. When a new external controller is provided via `stateController`
  ///
  /// ## Example
  ///
  /// ```dart
  /// FieldFormManager(
  ///   onInit: (controller) {
  ///     // Set initial values
  ///     controller.add(EmailState('initial@example.com'));
  ///     controller.add(PasswordState(''));
  ///     
  ///     // Register additional states
  ///     controller.add(RememberMeState(false));
  ///     controller.add(FormSubmittedState(false));
  ///     
  ///     // Set up any initial business logic
  ///     if (shouldPrepopulate) {
  ///       controller.update<EmailState, String>('prepopulated@example.com');
  ///     }
  ///   },
  ///   builder: (context, controller) => /* ... */,
  /// )
  /// ```
  final void Function(FieldController controller)? onInit;

  /// A builder function that creates the widget tree using the controller.
  ///
  /// This function is called on every build and provides access to the
  /// [FieldController] instance. Use this to build your form UI and connect
  /// it to the state controller.
  ///
  /// ## Parameters
  ///
  /// - `context`: The [BuildContext] for the widget
  /// - `controller`: The [FieldController] instance managing the form state
  ///
  /// ## Example
  ///
  /// ```dart
  /// FieldFormManager(
  ///   builder: (context, controller) {
  ///     // Use watch to react to state changes
  ///     final email = controller.watch<EmailState, String>();
  ///     final password = controller.watch<PasswordState, String>();
  ///     final isLoading = controller.watch<FormLoadingState, bool>();
  ///     
  ///     return Column(
  ///       children: [
  ///         TextField(
  ///           onChanged: (value) => controller.update<EmailState, String>(value),
  ///           decoration: InputDecoration(
  ///             labelText: 'Email',
  ///             errorText: email.isEmpty ? 'Required' : null,
  ///           ),
  ///         ),
  ///         if (isLoading)
  ///           CircularProgressIndicator()
  ///         else
  ///           ElevatedButton(
  ///             onPressed: () => _submitForm(controller),
  ///             child: const Text('Submit'),
  ///           ),
  ///       ],
  ///     );
  ///   },
  /// )
  /// ```
  final Widget Function(BuildContext context, FieldController controller) builder;

  /// Creates a [FieldFormManager] widget.
  ///
  /// The [builder] parameter is required and must not be null.
  ///
  /// ## Parameters
  ///
  /// - `key`: The widget's key
  /// - `stateController`: An optional external [FieldController] to use
  /// - `onInit`: An optional callback for controller setup
  /// - `builder`: A function that builds the widget tree using the controller
  const FieldFormManager({
    super.key,
    this.stateController,
    this.onInit,
    required this.builder,
  });

  @override
  State<FieldFormManager> createState() => _FieldFormManagerState();
}

class _FieldFormManagerState extends State<FieldFormManager> {
  /// The controller instance being used.
  ///
  /// This is either:
  /// 1. The external controller provided via `widget.stateController`, or
  /// 2. An internal controller created by this widget
  late FieldController _controller;

  /// Indicates whether this widget created and owns the controller.
  ///
  /// - `true`: This widget created the controller and must dispose it
  /// - `false`: An external controller was provided; parent handles disposal
  bool _isLocal = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    
    // Trigger onReady after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.onReady();
    });
  }

  /// Initializes the controller based on the widget configuration.
  ///
  /// This method determines whether to use an external controller or create
  /// an internal one, then calls the necessary initialization callbacks.
  ///
  /// ## Process
  ///
  /// 1. Check if `widget.stateController` is provided
  /// 2. If provided, use it and mark as external
  /// 3. If not provided, create a new controller and mark as internal
  /// 4. Call `widget.onInit` callback if provided
  /// 5. Call `_controller.onInit()` for internal initialization
  void _initializeController() {
    if (widget.stateController != null) {
      // Use the external controller provided by parent
      _controller = widget.stateController!;
      _isLocal = false;
    } else {
      // Create and manage our own controller
      _controller = FieldController();
      _isLocal = true;
    }
    
    // Call user-provided initialization callback
    widget.onInit?.call(_controller);
    
    // Call controller's internal initialization
    _controller.onInit();
  }

  @override
  void didUpdateWidget(covariant FieldFormManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the controller instance changed from the parent
    if (widget.stateController != oldWidget.stateController && widget.stateController != null) {
      setState(() {
        // Dispose the old local controller if we were managing it
        if (_isLocal) _controller.dispose();
        
        // Switch to the new external controller
        _controller = widget.stateController!;
        _isLocal = false;
        
        // Re-initialize with the new controller
        widget.onInit?.call(_controller);
      });
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller locally
    if (_isLocal) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}