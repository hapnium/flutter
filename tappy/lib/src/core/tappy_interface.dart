import '../device_notification_builder.dart';
import '../enums/tappy_platform.dart';
import '../exception/tappy_exception.dart';
import '../device_notification.dart';
import '../in_app_notification.dart';
import '../models/tappy_information.dart';
import '../device_notification_manager.dart';
import 'tappy_lifecycle.dart';
import 'tappy_controller.dart';

/// {@template tappy_interface}
/// An abstract base class that holds all core dependencies and configuration
/// required for Tappy notification services.
///
/// This class is intended to be mixed into a singleton or controller that manages
/// access to device and in-app notification services, lifecycle, and configuration.
/// 
/// All setters are typically called from within `TappyApplication` during
/// initialization. Attempts to access getters before initialization will
/// result in a [TappyException].
/// {@endtemplate}
abstract class TappyInterface {
  bool showLogs = true;
  TappyPlatform? _platform;
  TappyLifecycle? _lifecycle;
  TappyInformation? _info;
  DeviceNotificationBuilderInterface? _deviceBuilder;
  DeviceNotificationManagerInterface? _deviceManager;
  DeviceNotificationInterface? _deviceService;
  InAppNotificationInterface? _inAppService;

  /// The global [TappyController] instance.
  ///
  /// Provides access to notification lifecycle hooks and trigger methods.
  /// {@macro tappy_controller}
  final TappyController controller = TappyController.instance;

  /// Sets the in-app notification service.
  ///
  /// This service displays toasts/snackbars/etc. inside the app UI.
  set inAppNotificationService(InAppNotificationInterface service) {
    _inAppService = service;
  }

  /// Sets the device-level notification service.
  ///
  /// Used for sending system-level push notifications.
  set deviceNotificationService(DeviceNotificationInterface service) {
    _deviceService = service;
  }

  /// Sets the device notification manager for dismissing or managing state.
  set deviceNotificationManager(DeviceNotificationManagerInterface manager) {
    _deviceManager = manager;
  }

  /// Sets the builder for constructing device notifications.
  set deviceNotificationBuilder(DeviceNotificationBuilderInterface builder) {
    _deviceBuilder = builder;
  }

  /// Sets the application metadata.
  set appInformation(TappyInformation info) {
    _info = info;
  }

  /// Sets the lifecycle manager.
  ///
  /// This manages app lifecycle hooks relevant to notifications.
  set lifecycle(TappyLifecycle lifecycle) {
    _lifecycle = lifecycle;
  }

  /// Sets the target platform (Android/iOS).
  set platform(TappyPlatform platform) {
    _platform = platform;
  }

  /// Gets the in-app notification service.
  ///
  /// Throws a [TappyException] if not initialized.
  InAppNotificationInterface get inAppNotificationService {
    if (_inAppService == null) {
      throw TappyException("You must wrap your application with TappyApplication");
    }
    return _inAppService!;
  }

  /// Gets the target platform.
  ///
  /// Throws a [TappyException] if not initialized.
  TappyPlatform get platform {
    if (_platform == null) _throwException();
    return _platform!;
  }

  /// Gets the lifecycle manager.
  ///
  /// Throws a [TappyException] if not initialized.
  TappyLifecycle get lifecycle {
    if (_lifecycle == null) _throwException();
    return _lifecycle!;
  }

  /// Gets the device notification service.
  ///
  /// Throws a [TappyException] if not initialized.
  DeviceNotificationInterface get deviceNotificationService {
    if (_deviceService == null) _throwException();
    return _deviceService!;
  }

  /// Gets the app information.
  ///
  /// Throws a [TappyException] if not initialized.
  TappyInformation get appInformation {
    if (_info == null) _throwException();
    return _info!;
  }

  /// Gets the device notification manager.
  ///
  /// Throws a [TappyException] if not initialized.
  DeviceNotificationManagerInterface get deviceNotificationManager {
    if (_deviceManager == null) _throwException();
    return _deviceManager!;
  }

  /// Gets the builder used to construct notifications.
  ///
  /// Throws a [TappyException] if not initialized.
  DeviceNotificationBuilderInterface get deviceNotificationBuilder {
    if (_deviceBuilder == null) _throwException();
    return _deviceBuilder!;
  }
}

/// Throws a [TappyException] if the application is not properly initialized.
Exception _throwException() {
  throw TappyException(
    """
      [TAPPY] An instance of TappyApplication has not been called. 
      
      Did you forget to wrap your application with TappyApplication?
      
      Example:
      
      void main() {
        runApp(TappyApplication(child: MyApp()));
      }
    """
  );
}