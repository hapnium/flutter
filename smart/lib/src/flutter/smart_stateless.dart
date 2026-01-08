import 'package:flutter/material.dart' show BuildContext, StatelessWidget, Widget, Theme, ThemeData;
import 'package:flutter/foundation.dart' show nonVirtual;
import 'package:smart/responsive.dart' show ResponsiveUtil, ResponsiveConfig;

BuildContext? _context;

/// {@template smart_stateless}
/// Base class for stateless widgets using [ResponsiveUtil].
///
/// Provides access to responsive utilities, theme data, and build context
/// through a simplified API. Subclasses must implement [create] instead of
/// overriding [build].
///
/// ## Example Usage
/// ```dart
/// class MyScreen extends SmartStateless {
///   const MyScreen({super.key});
///
///   @override
///   Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme) {
///     return Scaffold(
///       body: responsive.isMobile ? MobileView() : DesktopView(),
///     );
///   }
/// }
/// ```
/// 
/// {@endtemplate}
abstract class SmartStateless extends StatelessWidget {
  /// {@macro smart_stateless}
  const SmartStateless({super.key});

  /// Retrieves the most recent build context used by this widget.
  ///
  /// ## Returns
  /// The [BuildContext] from the last [build] call, or `null` if not built yet.
  ///
  /// ## Note
  /// This method should be used cautiously as the context may be stale.
  /// Prefer using the context provided in [create] method.
  BuildContext? getContext() => _context;

  /// Provides responsive utilities for the current context.
  ///
  /// ## Returns
  /// A [ResponsiveUtil] instance configured with the widget's responsive settings,
  /// or `null` if the widget hasn't been built yet.
  ///
  /// ## Example
  /// ```dart
  /// final responsive = widget.responsive;
  /// if (responsive?.isMobile ?? false) {
  ///   // Mobile-specific logic
  /// }
  /// ```
  ResponsiveUtil? get responsive {
    if (_context case final context?) {
      return ResponsiveUtil(context, config: getResponsiveConfiguration());
    }

    return null;
  }

  /// Optional responsive configuration that overrides global [ResponsiveConfig] settings.
  ///
  /// Override this method in subclasses to provide custom responsive breakpoints
  /// for specific screens or widgets.
  ///
  /// ## Returns
  /// A [ResponsiveConfig] instance or `null` to use global defaults.
  ///
  /// ## Example
  /// ```dart
  /// @override
  /// ResponsiveConfig getResponsiveConfiguration() => CustomResponsiveConfig();
  /// ```
  ResponsiveConfig? getResponsiveConfiguration() => null;

  /// Builds the widget by invoking the [create] method with [ResponsiveUtil] and [ThemeData].
  ///
  /// This method should not be overridden. Instead, override [create] to define
  /// the widget's layout and behavior.
  ///
  /// ## Parameters
  /// - [context]: The build context for widget creation.
  ///
  /// ## Returns
  /// The widget tree returned by [create].
  @override
  @nonVirtual
  Widget build(BuildContext context) {
    _context = context;
    return create(context, ResponsiveUtil(context, config: getResponsiveConfiguration()), Theme.of(context));
  }

  /// A method to construct the body of the screen with responsive and theme context.
  ///
  /// Must be implemented in subclasses to define the view layout and behavior.
  ///
  /// ## Parameters
  /// - [context]: The build context for widget creation and navigation.
  /// - [responsive]: Pre-configured [ResponsiveUtil] for layout decisions.
  /// - [theme]: The current theme data for consistent styling.
  ///
  /// ## Returns
  /// The widget tree representing this screen or component.
  ///
  /// ## Example
  /// ```dart
  /// @override
  /// Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme) {
  ///   return Container(
  ///     color: theme.primaryColor,
  ///     padding: responsive.isMobile 
  ///         ? const EdgeInsets.all(16) 
  ///         : const EdgeInsets.all(32),
  ///     child: Text('Responsive Content'),
  ///   );
  /// }
  /// ```
  Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme);
}