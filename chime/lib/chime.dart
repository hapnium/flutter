/// {@template chime_library}
/// Public entry point for Chime.
///
/// This library exposes the [Chime] registry, which acts as a singleton-style
/// access point for Chime services. It keeps a reference to the active
/// [ChimeController] and [ChimeInAppNotification] instances and supplies
/// defaults when nothing has been configured.
///
/// Typical usage is to configure these values once at application startup
/// (usually through `ChimeApplication`) and then access them from any layer
/// without needing to pass dependencies through constructors.
///
/// ### Example
/// ```dart
/// void main() {
///   final controller = DefaultChimeController();
///   Chime.setController(controller);
///   Chime.setShowLogs(true);
///
///   runApp(const MyApp());
/// }
/// ```
/// {@endtemplate}
library;

import 'src/chime_controller.dart';
import 'src/chime_in_app_notification.dart';

export 'src/chime_application.dart';
export 'src/chime_configuration.dart';
export 'src/chime_controller.dart' hide DefaultChimeController;
export 'src/chime_event.dart';
export 'src/chime_in_app_notification.dart' hide DefaultChimeInAppNotification;
export 'src/chime_mixin.dart';
export 'src/chime_notification.dart';
export 'src/chime_notification_manager.dart';
export 'src/chime_push_notification.dart' hide DefaultChimePushNotification;
export 'src/chime_sound.dart';
export 'src/chime_streamable.dart';
export 'src/enums.dart';
export 'src/chime_notification_display.dart';
export 'src/chime_helpers.dart' hide ChimeHelpers;

/// {@template chime_registry}
/// Global registry for Chime services.
///
/// This class stores the active [ChimeController] and
/// [ChimeInAppNotification] instances used throughout the SDK. If no values
/// are set, default implementations are returned to keep the API usable
/// without explicit initialization.
///
/// This registry is intentionally lightweight:
/// - it does not own lifecycle or dispose resources
/// - it only holds references to configured instances
/// - it is safe to access from anywhere in the app
///
/// Use this as a shared access point when you need to interact with Chime
/// outside of widget context (for example, background isolates or services).
///
/// ### Example
/// ```dart
/// final controller = Chime.getController();
/// final inApp = Chime.getInAppNotification();
///
/// controller.publishEvent(
///   NotificationReceivedEvent(
///     ChimeNotification(id: 1, action: 'open', input: '', payload: null),
///     response: response,
///   ),
/// );
/// inApp.showInAppInfoNotification(message: 'Welcome back');
/// ```
/// {@endtemplate}
final class Chime {
  /// {@macro chime_registry}
  Chime._();

  /// Whether Chime should emit debug logs.
  ///
  /// This flag is read by Chime components that opt into logging. The registry
  /// itself does not log directly.
  static bool showLogs = false;

  /// The active controller instance.
  static ChimeController? _controller;

  /// The active in-app notification handler.
  static ChimeInAppNotification? _appNotification;

  /// Returns the active controller or a default instance.
  ///
  /// If no controller is set, a new [DefaultChimeController] is created each
  /// time this getter is called.
  static ChimeController getController() {
    if (_controller case final controller?) {
      return controller;
    }

    return DefaultChimeController();
  }

  /// Sets the active controller instance.
  ///
  /// Call this once during app startup to ensure a shared controller instance.
  static void setController(ChimeController controller) {
    _controller = controller;
  }

  /// Enables or disables Chime debug logging.
  ///
  /// This is a global flag intended for development or diagnostics.
  static void setShowLogs(bool value) => showLogs = value;

  /// Returns the active in-app notification handler or a default instance.
  ///
  /// If no handler is set, a new [DefaultChimeInAppNotification] is created
  /// each time this getter is called.
  static ChimeInAppNotification getInAppNotification() {
    if (_appNotification case final notification?) {
      return notification;
    }

    return DefaultChimeInAppNotification();
  }

  /// Sets the active in-app notification handler.
  ///
  /// Call this once during app startup to ensure consistent in-app behavior.
  static void setChimeInAppNotification(ChimeInAppNotification notification) {
    _appNotification = notification;
  }
}