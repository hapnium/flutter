import 'package:flutter/material.dart' show BuildContext, StatefulWidget, Widget, Theme, ThemeData, State;
import 'package:flutter/foundation.dart' show nonVirtual;
import 'package:smart/responsive.dart' show ResponsiveUtil, ResponsiveConfig;

/// {@template smart_stateful}
/// A base class for stateful widgets that integrates responsive utilities.
///
/// This widget provides a default [ResponsiveConfig] which can be overridden
/// by individual screens to define their own responsive behavior. Subclasses
/// should extend this class and pair it with a [SmartState].
/// 
/// ## Example Usage
/// ```dart
/// class MyScreen extends SmartStateful {
///   const MyScreen({super.key});
///
///   @override
///   ResponsiveConfig getResponsiveConfiguration() => CustomResponsiveConfig();
/// }
/// ```
/// 
/// {@endtemplate}
abstract class SmartStateful extends StatefulWidget {
  /// {@macro smart_stateful}
  const SmartStateful({super.key});

  /// Optional responsive settings that override the global [ResponsiveConfig].
  ///
  /// Override this property in subclasses to provide custom responsive breakpoints
  /// for different screen sizes and orientations.
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
}

/// {@template smart_state}
/// A base state class for [SmartStateful] that includes responsive and theme support.
///
/// Subclasses must override [create] instead of [build] to construct their UI
/// with access to [ResponsiveUtil] and [ThemeData].
/// 
/// ## Example Usage
/// ```dart
/// class _MyScreenState extends SmartState<MyScreen> {
///   @override
///   Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme) {
///     return Scaffold(
///       body: responsive.isMobile ? MobileLayout() : DesktopLayout(),
///     );
///   }
/// }
/// ```
/// 
/// {@endtemplate}
abstract class SmartState<T extends SmartStateful> extends State<T> {
  /// Optional responsive settings that override the global [ResponsiveConfig].
  ///
  /// Override this property in subclasses to provide custom responsive breakpoints
  /// for different screen sizes and orientations.
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

  /// Provides responsive utilities for the current context.
  ///
  /// Uses the widget's [SmartStateful.getResponsiveConfiguration] if available,
  /// otherwise falls back to global responsive settings.
  /// 
  /// ## Example
  /// ```dart
  /// if (responsive.isMobile) return MobileLayout();
  /// if (responsive.isTablet) return TabletLayout();
  /// return DesktopLayout();
  /// ```
  ResponsiveUtil get responsive => ResponsiveUtil(context, config: getResponsiveConfiguration() ?? widget.getResponsiveConfiguration());
  
  /// Builds the widget using a responsive utility and theme.
  ///
  /// Do not override this method. Use [create] to define the layout instead.
  /// 
  /// {@macro smart_state}
  @override
  @nonVirtual
  Widget build(BuildContext context) => create(context, responsive, Theme.of(context));

  /// A method to construct the UI with responsive and theme context.
  ///
  /// Must be implemented in subclasses to define the screen layout.
  /// 
  /// ## Parameters
  /// - [context]: The build context for widget creation.
  /// - [responsive]: Pre-configured [ResponsiveUtil] for layout decisions.
  /// - [theme]: The current theme data for styling widgets.
  /// 
  /// ## Returns
  /// The widget tree for this screen.
  /// 
  /// ## Example
  /// ```dart
  /// @override
  /// Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme) {
  ///   return Container(
  ///     color: theme.backgroundColor,
  ///     child: responsive.isMobile ? MobileView() : DesktopView(),
  ///   );
  /// }
  /// ```
  Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme);
}