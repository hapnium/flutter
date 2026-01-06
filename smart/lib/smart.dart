/// # 📦 smart Library
///
/// The `smart` library provides a unified interface to access commonly used 
/// modules, utilities, styles, extensions, and external packages within your app.
///
/// This centralized export simplifies import statements and enhances code organization:
///
/// ```dart
/// import 'package:your_app/smart.dart';
/// ```
///
/// ## 🔧 Modules Exported
/// This library exports the following key parts of the application:

library;

/// ---------------------------------------------------------------------------
/// 📁 Core Application Libraries
/// ---------------------------------------------------------------------------

/// Handles asset paths (e.g. images, icons, fonts).
export 'assets.dart';

/// Collection of Dart and Flutter extensions (e.g. on `String`, `Widget`, `BuildContext`).
export 'extensions.dart';

/// Custom exceptions to standardize error handling throughout the app.
export 'exceptions.dart';

/// Application enums (e.g. status enums, themes, modes).
export 'enums.dart';

/// Common utility functions and helpers (e.g. date/time, formatting, math).
export 'utilities.dart';

/// Common reusable UI components (e.g. buttons, cards, custom widgets).
export 'ui.dart';

/// Global style constants such as colors, text styles, and paddings.
export 'styles.dart';

/// Responsive layout helpers and breakpoints (e.g. screen type detection).
export 'responsive.dart';

/// Flutter-specific helper methods, shortcuts, and integrations.
export 'flutter.dart';


/// ---------------------------------------------------------------------------
/// 📦 Third-Party Packages
/// ---------------------------------------------------------------------------

/// Hapnium: App-wide state management, routing, and dependency injection.
///
/// Full Documentation: https://pub.dev/packages/hapnium
///
/// This export makes features like smart routing and global states available project-wide.
export 'package:hapnium/hapnium.dart';

/// Tracing: Logging and debugging utilities for performance tracing and analytics.
///
/// Full Documentation: https://pub.dev/packages/tracing
///
/// We hide the `console` export to avoid conflicts or override the internal `console()` method.
///
/// If you need `console`, import it explicitly in the desired file:
/// ```dart
/// import 'package:tracing/tracing.dart' show console;
/// ```
export 'package:tracing/tracing.dart' hide console;