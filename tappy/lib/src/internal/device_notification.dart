import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tracing/tracing.dart';

import '../config/definitions.dart';
import '../config/platform_engine.dart';
import '../device_notification.dart';
import '../models/notifier.dart';
import '../models/tappy_information.dart';
import '../tappy.dart';

final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

/// {@template default_device_notification}
/// Provides the default implementation of [DeviceNotificationInterface]
/// using the `flutter_local_notifications` plugin for notification
/// initialization, permission handling, and response processing.
///
/// This class is designed to be used as the underlying system for
/// managing native device notifications.
///
/// ### Example
/// ```dart
/// final notificationService = DefaultDeviceNotification();
/// await notificationService.requestPermission();
/// notificationService.init(appInfo, true, handler, backgroundHandler);
/// ```
/// {@endtemplate}
class DefaultDeviceNotification implements DeviceNotificationInterface {
  /// Label prefix used for logging and debugging.
  ///
  /// Defaults to `"Tappy Device Core"`.
  final String prefix = "Tappy Device Core";

  /// {@macro default_device_notification}
  DefaultDeviceNotification();

  @override
  Future<bool> requestPermission() async {
    if (PlatformEngine.isIOS) {
      return await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    } else if (PlatformEngine.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? response = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? grantedNotificationPermission = await response?.requestNotificationsPermission();

      return grantedNotificationPermission ?? false;
    }

    return false;
  }

  /// Returns Android-specific initialization settings.
  ///
  /// Uses the icon provided in [TappyInformation.androidIcon].
  ///
  /// {@macro default_device_notification}
  AndroidInitializationSettings _androidSettings(TappyInformation info) => AndroidInitializationSettings(info.androidIcon);

  // List<DarwinNotificationCategory> _darwinNotificationCategories() => <DarwinNotificationCategory>[
  //   DarwinNotificationCategory(
  //     darwinNotificationCategoryText,
  //     actions: <DarwinNotificationAction>[
  //       DarwinNotificationAction.text(
  //         'text_1',
  //         'Action 1',
  //         buttonTitle: 'Send',
  //         placeholder: 'Placeholder',
  //       ),
  //     ],
  //   ),
  //   DarwinNotificationCategory(
  //     darwinNotificationCategoryPlain,
  //     actions: <DarwinNotificationAction>[
  //       DarwinNotificationAction.plain('id_1', 'Action 1'),
  //       DarwinNotificationAction.plain(
  //         'id_2',
  //         'Action 2 (destructive)',
  //         options: <DarwinNotificationActionOption>{
  //           DarwinNotificationActionOption.destructive,
  //         },
  //       ),
  //       DarwinNotificationAction.plain(
  //         navigationActionId,
  //         'Action 3 (foreground)',
  //         options: <DarwinNotificationActionOption>{
  //           DarwinNotificationActionOption.foreground,
  //         },
  //       ),
  //       DarwinNotificationAction.plain(
  //         'id_4',
  //         'Action 4 (auth required)',
  //         options: <DarwinNotificationActionOption>{
  //           DarwinNotificationActionOption.authenticationRequired,
  //         },
  //       ),
  //     ],
  //     options: <DarwinNotificationCategoryOption>{
  //       DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
  //     },
  //   )
  // ];
  //
  // DarwinInitializationSettings _darwinSettings(AppPlatform info) => DarwinInitializationSettings(
  //   requestAlertPermission: true,
  //   requestBadgePermission: true,
  //   requestSoundPermission: true,
  //   notificationCategories: _darwinNotificationCategories(),
  // );
  //
  // LinuxInitializationSettings _linuxSettings(AppPlatform info) => LinuxInitializationSettings(
  //   defaultActionName: 'Open notification',
  //   defaultIcon: AssetsLinuxIcon(_icon(info)),
  // );

  InitializationSettings _initializationSettings(TappyInformation info) => InitializationSettings(
    android: _androidSettings(info),
    // iOS: _darwinSettings(info),
    // macOS: _darwinSettings(info),
    // linux: _linuxSettings(info),
  );

  @override
  void init(NotificationTapHandler? handler, NotificationResponseHandler? backgroundHandler) async {
    if(Tappy.showLogs) {
      console.debug("Initializing remote notification for ${Tappy.appInformation.app.name}", tag: prefix);
    }

    await plugin.initialize(
      _initializationSettings(Tappy.appInformation),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if(Tappy.showLogs) {
          console.info("Remote notification for ${Tappy.appInformation.app.name}", tag: prefix);
        }

        Notifier notifier;

        if(response.payload != null) {
          notifier = Notifier.fromString(response.payload!);
        } else {
          notifier = Notifier.empty();
        }
        notifier = notifier.copyWith(action: response.actionId, input: response.input, id: response.id);

        if(Tappy.showLogs) {
          console.info("Remote notification for ${Tappy.appInformation.app.name} details: ${notifier.toJson()}", tag: prefix);
        }

        process(handler, onProcess: (value) => value(notifier));

        Tappy.lifecycle.onTapped(notifier);
      },
      onDidReceiveBackgroundNotificationResponse: backgroundHandler,
    ).then((v) {
      if(v ?? false) {
        if(Tappy.showLogs) {
          console.info("Initialized remote notification for ${Tappy.appInformation.app.name}", tag: prefix);
        }
      } else {
        if(Tappy.showLogs) {
          console.error("Couldn't initialize remote notification for ${Tappy.appInformation.app.name}", tag: prefix);
        }
      }
    });
  }

  @override
  Future<bool> get isPermitted async {
    if (PlatformEngine.isAndroid) {
      return await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
    } else if (PlatformEngine.isIOS) {
      NotificationsEnabledOptions? response = await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();

      if(response != null) {
        return response.isEnabled;
      }

      return false;
    }

    return false;
  }

  @override
  void onAppLaunchedByNotification(NotificationTapHandler onReceived) async {
    final NotificationAppLaunchDetails? details = !PlatformEngine.isWeb
        ? null
        : await plugin.getNotificationAppLaunchDetails();

    if (details != null && details.didNotificationLaunchApp) {
      NotificationResponse? response = details.notificationResponse;

      if(response != null) {
        Notifier notifier;

        if(response.payload != null) {
          notifier = Notifier.fromString(response.payload!);
        } else {
          notifier = Notifier.empty();
        }
        notifier = notifier.copyWith(action: response.actionId, input: response.input, id: response.id);

        Tappy.lifecycle.onAppLaunched(notifier);
      }
    }
  }
}