import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:toastification/toastification.dart';

import '../chime.dart';
import 'chime_controller.dart';
import 'chime_push_notification.dart';

/// Callback type for handling notification permissions.
///
/// The [PermissionCallback] is invoked with a boolean value
/// indicating whether notification permissions were granted.
typedef PermissionCallback = void Function(bool granted);

/// A typedef for a function that configures an [InAppConfiguration] object.
///
/// This allows for a more concise way to customize the in-app notification
/// configuration. You can create a function that takes an existing
/// [InAppConfiguration] and returns a modified version.
typedef InAppNotificationConfigurer = InAppConfiguration Function(InAppConfiguration config);

/// {@template chime_application}
/// Application-level widget that wires Chime into your widget tree.
///
/// Place [ChimeApplication] above your app widget to initialize Chime services,
/// configure in-app notifications, and handle notification callbacks.
///
/// The widget:
/// - initializes the configured controller and event listeners
/// - sets up device-level notifications when enabled
/// - applies in-app notification UI configuration via [ToastificationWrapper]
///
/// ### Example
/// ```dart
/// ChimeApplication(
///   applicationName: 'MyApp',
///   platform: ChimePlatform.ANDROID,
///   configuration: ChimeConfiguration(
///     controller: DefaultChimeController(),
///     inAppNotification: DefaultChimeInAppNotification(),
///   ),
///   child: MaterialApp(home: HomeScreen()),
/// );
/// ```
/// {@endtemplate}
class ChimeApplication extends StatefulWidget {
  /// The child widget (typically a [MaterialApp] or [CupertinoApp]) that this widget wraps.
  final Widget child;

  /// The application name used for notification channel configuration.
  final String applicationName;

  /// The target platform the app is running on (e.g., Android or iOS).
  ///
  /// Helps in determining platform-specific behavior.
  final ChimePlatform platform;

  /// Whether to log debug and initialization messages.
  ///
  /// Defaults to `true`. Useful for debugging notification setup.
  final bool showLog;

  /// Whether to skip device notification initialization on web platforms.
  ///
  /// Defaults to `true`.
  final bool skipDeviceNotificationInitializationOnWeb;

  /// Callback that receives the result of the permission request.
  ///
  /// You can use this to handle user permission status programmatically.
  final PermissionCallback? onPermitted;

  /// Callback fired when the app is launched by tapping on a notification.
  ///
  /// Useful for deep linking or opening a specific screen.
  final ChimeNotificationCallback? onLaunchedByNotification;

  /// Called when the app receives a notification while it’s in the foreground.
  ///
  /// This handler processes the tap and payload information.
  final ChimeNotificationCallback? onForegroundNotification;

  /// Called when a notification is tapped and the app is brought to the foreground from background.
  final NotificationResponseCallback? onBackgroundNotification;

  /// Optional function to configure in-app notification behavior.
  ///
  /// You can customize position, styling, and display behavior of in-app messages.
  final InAppNotificationConfigurer? inAppConfigurer;

  /// Optional initialization settings for the notification plugin.
  final InitializationSettings? initializationSettings;

  /// The overall Chime configuration for this application.
  final ChimeConfiguration configuration;
  
  const ChimeApplication({
    super.key,
    required this.child,
    this.configuration = const ChimeConfiguration(),
    required this.platform,
    this.onPermitted,
    this.onLaunchedByNotification,
    this.onBackgroundNotification,
    this.onForegroundNotification,
    this.inAppConfigurer,
    required this.applicationName,
    this.showLog = true,
    this.initializationSettings,
    this.skipDeviceNotificationInitializationOnWeb = true,
  });

  @override
  State<ChimeApplication> createState() => _ChimeApplicationState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('child', child));
    properties.add(EnumProperty<ChimePlatform>('platform', platform));
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
    properties.add(ObjectFlagProperty<PermissionCallback?>.has('onPermitted', onPermitted));
    properties.add(ObjectFlagProperty<ChimeNotificationCallback?>.has('onLaunchedByNotification', onLaunchedByNotification));
    properties.add(ObjectFlagProperty<ChimeNotificationCallback?>.has('onForegroundNotification', onForegroundNotification));
    properties.add(ObjectFlagProperty<NotificationResponseCallback?>.has('onBackgroundNotification', onBackgroundNotification));
    properties.add(ObjectFlagProperty<InAppNotificationConfigurer?>.has('inAppConfigurer', inAppConfigurer));
  }
}

class _ChimeApplicationState extends State<ChimeApplication> {
  InAppConfiguration _config = InAppConfiguration();

  @override
  void initState() {
    _applyInAppConfigurer();
    
    WidgetsBinding.instance.addPostFrameCallback((d) async {
      await _init();
    });

    super.initState();
  }

  Future<void> _init() async {
    Chime.setApplicationName(widget.applicationName);
    Chime.setPlatform(widget.platform);

    final controller = widget.configuration.controller ?? DefaultChimeController();

    for (final listener in widget.configuration.eventListeners) {
      controller.addChimeEventListener(listener);
    }

    final skipOnWeb = widget.platform == ChimePlatform.WEB && widget.skipDeviceNotificationInitializationOnWeb;
    if (!skipOnWeb) {
      final pusher = widget.configuration.pushNotification ?? DefaultChimePushNotification(widget.applicationName, widget.platform);
      Chime.setChimePushNotification(pusher);
      
      if (widget.initializationSettings case final initializationSettings?) {
        await pusher.initialize(
          initializationSettings: initializationSettings,
          onBackgroundNotificationReceived: widget.onBackgroundNotification,
          onNotificationTapped: widget.onForegroundNotification
        );
      }

      if (widget.onLaunchedByNotification case final onAppLaunchedByNotification?) {
        await pusher.onAppLaunchedByNotification(onAppLaunchedByNotification);
      }

      Chime.setChimePushNotification(pusher);
    }

    Chime.setShowLogs(widget.showLog);
    Chime.setController(controller);

    if (widget.configuration.inAppNotification case final notification?) {
      Chime.setChimeInAppNotification(notification);
    }
  }

  void _applyInAppConfigurer() {
    if (widget.inAppConfigurer case final configurer?) {
      _config = configurer(_config);
    }
  }

  @override
  void didUpdateWidget(covariant ChimeApplication oldWidget) {
    final shouldReinit = widget.configuration != oldWidget.configuration ||
      widget.platform != oldWidget.platform ||
      widget.applicationName != oldWidget.applicationName ||
      widget.initializationSettings != oldWidget.initializationSettings ||
      widget.onBackgroundNotification != oldWidget.onBackgroundNotification ||
      widget.onForegroundNotification != oldWidget.onForegroundNotification ||
      widget.onLaunchedByNotification != oldWidget.onLaunchedByNotification ||
      widget.skipDeviceNotificationInitializationOnWeb != oldWidget.skipDeviceNotificationInitializationOnWeb ||
      widget.showLog != oldWidget.showLog;

    if (shouldReinit) {
      WidgetsBinding.instance.addPostFrameCallback((d) async {
        await _init();
      });
      setState(() {});
    }

    if (widget.inAppConfigurer != oldWidget.inAppConfigurer) {
      _applyInAppConfigurer();
      WidgetsBinding.instance.addPostFrameCallback((d) async {
        await _init();
      });
      setState(() {});
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    ToastificationConfig toastConfig = ToastificationConfigProvider.maybeOf(context)?.config ?? const ToastificationConfig();

    toastConfig = toastConfig.copyWith(
      alignment: _config.alignment,
      itemWidth: _config.itemWidth,
      clipBehavior: _config.clipBehavior,
      animationDuration: _config.animationDuration,
      animationBuilder: _config.animationBuilder,
      marginBuilder: _config.marginBuilder,
      applyMediaQueryViewInsets: _config.applyMediaQueryViewInsets,
    );

    return ToastificationWrapper(config: toastConfig, child: widget.child);
  }
}
