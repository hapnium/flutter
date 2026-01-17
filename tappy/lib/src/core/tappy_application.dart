import 'package:flutter/cupertino.dart' hide TargetPlatform;
import 'package:flutter/foundation.dart';
import 'package:toastification/toastification.dart';

import '../config/definitions.dart';
import '../config/platform_engine.dart';
import '../device_notification.dart';
import '../device_notification_builder.dart';
import '../device_notification_manager.dart';
import '../enums/app.dart';
import '../enums/tappy_platform.dart';
import '../in_app_notification.dart';
import '../internal/default_tappy_lifecycle.dart';
import '../internal/device_notification.dart';
import '../internal/device_notification_builder.dart';
import '../internal/device_notification_manager.dart';
import '../internal/in_app_notification.dart';
import '../models/in_app_config.dart';
import '../models/tappy_information.dart';
import 'tappy.dart';
import 'tappy_lifecycle.dart';

part 'tappy_application_state.dart';

/// {@template tappy_application}
/// A widget that wraps your root app and manages all Tappy notification functionality.
///
/// This widget must be placed above the root `MaterialApp` or `CupertinoApp`.
/// It handles initialization, permission requests, lifecycle hooks, and notification
/// tapping behavior (foreground and background).
///
/// ### Example:
/// ```dart
/// void main() {
///   runApp(
///     TappyApplication(
///       app: App.user,
///       info: TappyAppInformation(
///         androidIcon: 'ic_launcher',
///         app: App.user,
///       ),
///       platform: TappyPlatform.ANDROID,
///       showLog: true,
///       onPermitted: (permitted) {
///         debugPrint('Permission granted: $permitted');
///       },
///       onLaunchedByNotification: (notifier) {
///         debugPrint('Notification caused app launch: $notifier');
///       },
///       child: MaterialApp(
///         home: HomePage(),
///       ),
///     ),
///   );
/// }
/// ```
/// {@endtemplate}
final class TappyApplication extends StatefulWidget {
  /// The child widget (typically a [MaterialApp] or [CupertinoApp]) that this widget wraps.
  final Widget child;

  /// Information about the application, including icon and app identity.
  ///
  /// This information is used to configure and display notifications.
  final TappyInformation info;

  /// The target platform the app is running on (e.g., Android or iOS).
  ///
  /// Helps in determining platform-specific behavior.
  final TappyPlatform platform;

  /// Whether to log debug and initialization messages.
  ///
  /// Defaults to `true`. Useful for debugging notification setup.
  final bool showLog;

  /// Custom lifecycle implementation for advanced usage.
  ///
  /// Defaults to an internal implementation if not provided. Use this to inject
  /// a custom [TappyLifecycle] behavior.
  final TappyLifecycle? lifecycle;

  /// Whether to skip device notification initialization on web platforms.
  ///
  /// Defaults to `true`.
  final bool skipDeviceNotificationInitializationOnWeb;

  /// Custom builder used to construct device notifications.
  ///
  /// If not set, a default builder is used.
  final DeviceNotificationBuilderInterface? deviceNotificationBuilder;

  /// Custom manager for dismissing and handling notification state.
  ///
  /// If not provided, a default manager is used.
  final DeviceNotificationManagerInterface? deviceNotificationManager;

  /// A custom implementation of the device notification service.
  ///
  /// This manages sending and receiving device-level notifications.
  final DeviceNotificationInterface? deviceNotificationService;

  /// Custom in-app notification service for showing UI-level alerts.
  ///
  /// Uses toast, snackbar, or modal mechanisms internally.
  final InAppNotificationInterface? inAppNotificationService;

  /// Callback that receives the result of the permission request.
  ///
  /// You can use this to handle user permission status programmatically.
  final PermissionCallback? onPermitted;

  /// Callback fired when the app is launched by tapping on a notification.
  ///
  /// Useful for deep linking or opening a specific screen.
  final NotificationTapHandler? onLaunchedByNotification;

  /// Called when the app receives a notification while it’s in the foreground.
  ///
  /// This handler processes the tap and payload information.
  final NotificationTapHandler? handler;

  /// Called when a notification is tapped and the app is brought to the foreground from background.
  final NotificationResponseHandler? backgroundHandler;

  /// Optional function to configure in-app notification behavior.
  ///
  /// You can customize position, styling, and display behavior of in-app messages.
  final InAppNotificationConfigurer? inAppConfigurer;

  /// {@macro tappy_application}
  const TappyApplication({
    super.key,
    required this.child,
    required this.info,
    required this.platform,
    this.onPermitted,
    this.onLaunchedByNotification,
    this.handler,
    this.backgroundHandler,
    this.inAppConfigurer,
    this.lifecycle,
    this.deviceNotificationBuilder,
    this.deviceNotificationManager,
    this.deviceNotificationService,
    this.inAppNotificationService,
    this.showLog = true,
    this.skipDeviceNotificationInitializationOnWeb = true,
  });

  @override
  State<TappyApplication> createState() => _TappyApplicationState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('child', child));
    properties.add(DiagnosticsProperty<TappyInformation>('info', info));
    properties.add(EnumProperty<TappyPlatform>('platform', platform));
    properties.add(EnumProperty<TappyApp>('app', info.app));
    properties.add(StringProperty('androidIcon', info.androidIcon));
    properties.add(StringProperty('iosIcon', info.iosIcon));
    properties.add(FlagProperty(
      'showLog',
      value: showLog,
      ifTrue: 'show logs enabled',
      ifFalse: 'show logs disabled',
    ));
    properties.add(FlagProperty(
      'skipDeviceNotificationInitializationOnWeb',
      value: skipDeviceNotificationInitializationOnWeb,
      ifTrue: 'skip device notification initialization on web platforms',
      ifFalse: 'do not skip device notification initialization on web platforms',
    ));
    properties.add(ObjectFlagProperty<TappyLifecycle?>.has('lifecycle', lifecycle));
    properties.add(ObjectFlagProperty<DeviceNotificationBuilderInterface?>.has('deviceNotificationBuilder', deviceNotificationBuilder));
    properties.add(ObjectFlagProperty<DeviceNotificationManagerInterface?>.has('deviceNotificationManager', deviceNotificationManager));
    properties.add(ObjectFlagProperty<DeviceNotificationInterface?>.has('deviceNotificationService', deviceNotificationService));
    properties.add(ObjectFlagProperty<InAppNotificationInterface?>.has('inAppNotificationService', inAppNotificationService));
    properties.add(ObjectFlagProperty<PermissionCallback?>.has('onPermitted', onPermitted));
    properties.add(ObjectFlagProperty<NotificationTapHandler?>.has('onLaunchedByNotification', onLaunchedByNotification));
    properties.add(ObjectFlagProperty<NotificationTapHandler?>.has('handler', handler));
    properties.add(ObjectFlagProperty<NotificationResponseHandler?>.has('backgroundHandler', backgroundHandler));
    properties.add(ObjectFlagProperty<InAppNotificationConfigurer?>.has('inAppConfigurer', inAppConfigurer));
  }
}