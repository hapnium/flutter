part of 'controller_advice.dart';

/// {@template exception_handler}
/// Centralized exception handling engine that dispatches [ZapException]
/// instances to registered type-specific handlers.
///
/// `ExceptionHandler` maintains a map of [ExceptionType] to handler
/// callbacks. When [handle] is invoked, it looks up the handler for the
/// exception's type and calls it. If no type-specific handler is
/// registered, the [defaultHandler] is used as a fallback.
///
/// ### Architecture
///
/// This class is inspired by Spring Boot's `@ControllerAdvice` pattern.
/// It promotes clean separation between business logic and error handling
/// by centralizing exception processing in one place.
///
/// ### Handler resolution order
///
/// 1. Type-specific handler (registered via [registerHandler])
/// 2. Default handler (set via constructor)
/// 3. Silent ignore (if neither is available)
///
/// ### Example
///
/// ```dart
/// final handler = ExceptionHandler(
///   defaultHandler: (e) => Z.error('Unhandled: ${e.message}'),
/// );
///
/// handler.registerHandler(
///   ExceptionType.network,
///   (e) => _showOfflineBanner(),
/// );
///
/// handler.registerHandler(
///   ExceptionType.auth,
///   (e) => _navigateToLogin(),
/// );
///
/// // Later during execution:
/// handler.handle(ZapException.network('No internet'));
/// // _showOfflineBanner() is called
///
/// handler.handle(ZapException.auth('Token expired'));
/// // _navigateToLogin() is called
///
/// handler.handle(ZapException.parsing('Invalid JSON'));
/// // defaultHandler is called
/// ```
///
/// ### Thread safety
///
/// This class is not thread-safe. In Dart's single-isolate model, this
/// is not a concern, but be aware of this if extending to concurrent
/// environments.
/// {@endtemplate}
class ExceptionHandler {
  /// {@template exception_handler_handlers}
  /// Map of registered handlers keyed by [ExceptionType].
  ///
  /// Each entry maps an exception type to its corresponding handler
  /// callback. Handlers are registered via [registerHandler] or
  /// [registerHandlers] and looked up during [handle].
  ///
  /// ### Example
  ///
  /// ```dart
  /// // Internal state
  /// _handlers = {
  ///   ExceptionType.network: (e) => _showOfflineBanner(),
  ///   ExceptionType.auth: (e) => _navigateToLogin(),
  /// };
  /// ```
  /// {@endtemplate}
  final Map<ExceptionType, Function(ZapException)> _handlers = {};

  /// {@template exception_handler_defaultHandler}
  /// Fallback handler invoked when no type-specific handler is registered
  /// for the exception's type.
  ///
  /// This is set via the constructor and serves as the catch-all for
  /// unclassified or unexpected exception types.
  ///
  /// ### Priority
  ///
  /// If both a type-specific handler and a default handler exist, the
  /// type-specific handler takes precedence. The default handler is only
  /// called when no type-specific handler is found.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final handler = ExceptionHandler(
  ///   defaultHandler: (e) {
  ///     Z.fatal('Unexpected: ${e.type} - ${e.message}');
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  final Function(ZapException)? _defaultHandler;

  /// {@template exception_handler_constructor}
  /// Constructs an [ExceptionHandler] with an optional default handler.
  ///
  /// ### Parameters
  ///
  /// - [defaultHandler]: Optional fallback handler invoked when no
  ///   type-specific handler is registered for the exception's type.
  ///   If `null`, unhandled exceptions are silently ignored.
  ///
  /// ### Example
  ///
  /// ```dart
  /// // With default handler
  /// final handler = ExceptionHandler(
  ///   defaultHandler: (e) => Z.error('Unhandled: ${e.message}'),
  /// );
  ///
  /// // Without default handler
  /// final handler = ExceptionHandler();
  /// // Unhandled exceptions are silently ignored
  /// ```
  /// {@endtemplate}
  /// {@macro exception_handler}
  ExceptionHandler({Function(ZapException)? defaultHandler})
      : _defaultHandler = defaultHandler;

  /// {@template exception_handler_registerHandler}
  /// Registers a handler for a specific [ExceptionType].
  ///
  /// If a handler is already registered for the given [type], it is
  /// overwritten by the new [handler].
  ///
  /// ### Parameters
  ///
  /// - [type]: The [ExceptionType] this handler addresses.
  /// - [handler]: The callback to invoke when an exception of [type]
  ///   is thrown.
  ///
  /// ### Example
  ///
  /// ```dart
  /// handler.registerHandler(
  ///   ExceptionType.network,
  ///   (e) {
  ///     Z.warn('Network error: ${e.message}');
  ///     _queueForRetry(e.uri);
  ///   },
  /// );
  /// ```
  ///
  /// ### Overwriting
  ///
  /// If you register a handler for a type that already has one, the old
  /// handler is silently replaced:
  /// ```dart
  /// handler.registerHandler(ExceptionType.network, handlerA);
  /// handler.registerHandler(ExceptionType.network, handlerB);
  /// // handlerA is no longer called for network errors
  /// ```
  /// {@endtemplate}
  void registerHandler(ExceptionType type, Function(ZapException) handler) {
    _handlers[type] = handler;
  }

  /// {@template exception_handler_registerHandlers}
  /// Registers multiple handlers at once using a map of [ExceptionType]
  /// to handler callbacks.
  ///
  /// Existing handlers for matching keys are overwritten.
  ///
  /// ### Parameters
  ///
  /// - [handlers]: A map where keys are [ExceptionType] values and values
  ///   are the corresponding handler callbacks.
  ///
  /// ### Example
  ///
  /// ```dart
  /// handler.registerHandlers({
  ///   ExceptionType.network: (e) => _showOfflineBanner(),
  ///   ExceptionType.auth: (e) => _navigateToLogin(),
  ///   ExceptionType.timeout: (e) => _showRetryDialog(),
  /// });
  /// ```
  ///
  /// ### Bulk registration
  ///
  /// This method is convenient for registering multiple handlers in a
  /// single call:
  /// ```dart
  /// handler.registerHandlers({
  ///   for (final type in ExceptionType.values)
  ///     type: (e) => Z.error('${type.name}: ${e.message}'),
  /// });
  /// ```
  /// {@endtemplate}
  void registerHandlers(Map<ExceptionType, Function(ZapException)> handlers) {
    _handlers.addAll(handlers);
  }

  /// {@template exception_handler_handle}
  /// Dispatches the given [exception] to the appropriate handler.
  ///
  /// Handler resolution follows this order:
  /// 1. Type-specific handler (from [_handlers] map)
  /// 2. Default handler ([_defaultHandler])
  /// 3. Silent ignore (if neither is available)
  ///
  /// ### Parameters
  ///
  /// - [exception]: The [ZapException] to handle. The handler is
  ///   selected based on [exception.type].
  ///
  /// ### Example
  ///
  /// ```dart
  /// try {
  ///   final response = await zap.get<User>('/users/1');
  /// } on ZapException catch (e) {
  ///   handler.handle(e);
  /// }
  /// ```
  ///
  /// ### Behavior
  ///
  /// - If a type-specific handler is registered, it is called with the
  ///   exception.
  /// - If no type-specific handler exists but a default handler is set,
  ///   the default handler is called.
  /// - If neither exists, the exception is silently ignored.
  ///
  /// ### Return value
  ///
  /// This method returns `void`. It is a side-effect dispatch, not a
  /// transformer.
  /// {@endtemplate}
  void handle(ZapException exception) {
    final handler = _handlers[exception.type] ?? _defaultHandler;
    handler?.call(exception);
  }
}