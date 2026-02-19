import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tracing/tracing.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'chime_event.dart';
import 'chime_mixin.dart';
import 'chime_sound.dart';
import 'chime_notification.dart';
import 'enums.dart';

NotificationResponseCallback? _chimeBackgroundForwarder;
Future<void> Function(NotificationResponse details)? _chimeBackgroundPublisher;

@pragma('vm:entry-point')
void chimeBackgroundNotificationDispatcher(NotificationResponse details) async {
  // Keep Chime event publishing
  if (_chimeBackgroundPublisher case final publisher?) {
    await publisher(details);
  }

  // Keep user-provided background callback
  if (_chimeBackgroundForwarder case final forwarder?) {
    forwarder(details);
  }
}

/// {@template chime_push_notification_builder}
/// Base builder for constructing and publishing Chime notifications.
///
/// Extend this class to integrate push providers (Firebase, APNs, etc.) and
/// convert their payloads into Chime notifications. The builder gives you
/// helpers for vibration patterns, time parsing, local timezone configuration,
/// and publishing created/scheduled notifications through the Chime pipeline.
///
/// The intended usage is to subclass and call [pushChimeNotification] or
/// [pushScheduledChimeNotification] after mapping provider payloads to
/// [ChimeCreatedNotification] or [ChimeScheduledNotification].
///
/// ### Example
/// ```dart
/// class FirebasePushNotificationBuilder extends ChimePushNotificationBuilder {
///   FirebasePushNotificationBuilder(this._controller);
///
///   final ChimeController _controller;
///
///   @override
///   ChimeController get chimeController => _controller;
///
///   @override
///   bool get showChimeLogs => true;
///
///   Future<void> push(RemoteMessage message) async {
///     await pushChimeNotification(() async {
///       final details = NotificationDetails(
///         android: AndroidNotificationDetails('default', 'Default'),
///       );
///       return ChimeCreatedNotification(
///         id: 1,
///         identifier: message.messageId ?? 'unknown',
///         title: message.notification?.title,
///         body: message.notification?.body,
///         notificationDetails: details,
///       );
///     });
///   }
/// }
/// ```
/// {@endtemplate}
abstract class ChimePushNotificationBuilder with ChimeMixin {
  /// {@template chime_push_notification_builder_log_prefix}
  /// Prefix used for log messages emitted by this builder.
  ///
  /// Override to customize the log prefix per integration.
  /// {@endtemplate}
  @protected
  String getChimeLogPrefix() => "[Chime Push Notification Builder]";

  /// {@template chime_push_notification_builder_low_vibration}
  /// Vibration pattern for low-intensity alerts.
  /// {@endtemplate}
  @protected
  Int64List getLowVibrationPattern() => Int64List.fromList([0, 200, 200, 200]);

  /// {@template chime_push_notification_builder_medium_vibration}
  /// Vibration pattern for medium-intensity alerts.
  /// {@endtemplate}
  @protected
  Int64List getMediumVibrationPattern() => Int64List.fromList([0, 500, 200, 200, 200, 200]);

  /// {@template chime_push_notification_builder_high_vibration}
  /// Vibration pattern for high-intensity alerts.
  /// {@endtemplate}
  @protected
  Int64List getHighVibrationPattern() => Int64List.fromList([0, 1000, 200, 200, 200, 200, 200, 200]);

  /// Combines the current date with a given time string.
  ///
  /// The time string must be in the format "Minute:Seconds AM/PM",
  /// such as "9:00 AM" or "9:00PM".
  ///
  /// Returns an ISO-8601 string representing the combined date and time.
  ///
  /// Example:
  /// ```dart
  /// final result = parseTimeToDate("9:00 AM");
  /// print(result); // Prints: 2025-01-07T09:00:00.000
  /// ```
  @protected
  String parseTimeToDate(String time) {
    // Get the current date
    DateTime now = DateTime.now();

    // Normalize the time string (remove extra spaces and ensure uppercase AM/PM)
    time = time.trim().toUpperCase();

    // Extract hours, minutes, and period (AM/PM)
    final timeRegex = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$');
    final match = timeRegex.firstMatch(time);

    if (match == null) {
      throw FormatException("Invalid time format. Expected format is 'H:MM AM/PM'.");
    }

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;

    // Convert hour to 24-hour format if necessary
    if (period == "PM" && hour != 12) {
      hour += 12;
    } else if (period == "AM" && hour == 12) {
      hour = 0;
    }

    // Combine the parsed time with the current date
    return DateTime(now.year, now.month, now.day, hour, minute).toIso8601String();
  }

  @protected
  /// {@template chime_push_notification_builder_android_sound}
  /// Converts a [ChimeSound] into an Android raw resource sound.
  ///
  /// Use this when building [NotificationDetails] for Android.
  /// {@endtemplate}
  RawResourceAndroidNotificationSound androidSound(ChimeSound sound) => RawResourceAndroidNotificationSound(sound.getKey());

  // It is always better to skip this when on web platform.
  // Always call this before performing any scheduled notification push
  @protected
  /// {@template chime_push_notification_builder_configure_timezone}
  /// Initializes timezone data and sets the local timezone.
  ///
  /// Call this before scheduling notifications, especially on Android, to
  /// ensure correct delivery times.
  /// {@endtemplate}
  Future<void> configureLocalTimeZone(String timezone) async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezone.isNotEmpty ? timezone : "Africa/Lagos"));
  }
  
  /// {@template chime_push_notification_builder_push}
  /// Builds and publishes a notification created by the provided callback.
  ///
  /// The [onCreatedNotification] callback should return a fully constructed
  /// [ChimeCreatedNotification]. If a notification with the same identifier
  /// already exists, it will be skipped.
  ///
  /// On success, this publishes [NotificationCreatedEvent]. On failure, it
  /// publishes [NotificationFailedEvent].
  /// {@endtemplate}
  Future<void> pushChimeNotification(Future<ChimeCreatedNotification> Function() onCreatedNotification) async {
    final notification = await onCreatedNotification();
  
    if(hasCreatedNotification(notification)) {
      if(showChimeLogs) {
        console.trace("Notification (${notification.identifier}) has already been created", tag: getChimeLogPrefix());
      }

      return;
    }

    try {
      await plugin.show(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        notificationDetails: notification.notificationDetails,
        payload: notification.toString()
      );

      if(showChimeLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: getChimeLogPrefix());
      }
      await publishEvent(NotificationCreatedEvent(notification));
    } catch (error, st) {
      if(showChimeLogs) {
        console.info("Notification failed to build. Sending it to `failedNotification` controller", tag: getChimeLogPrefix());
      }
      await publishEvent(NotificationFailedEvent(notification, error, st));
    }
  }

  /// {@template chime_push_notification_builder_push_scheduled}
  /// Builds and publishes a scheduled notification.
  ///
  /// The [onCreatedNotification] callback should return a fully constructed
  /// [ChimeScheduledNotification]. If a notification with the same identifier
  /// already exists, it will be skipped.
  ///
  /// On success, this publishes [NotificationScheduledEvent]. On failure, it
  /// publishes [NotificationFailedEvent].
  /// {@endtemplate}
  Future<void> pushScheduledChimeNotification({required ChimeScheduledNotification Function() onCreatedNotification}) async {
    final notification = onCreatedNotification();
  
    if(hasCreatedNotification(notification)) {
      if(showChimeLogs) {
        console.trace("Notification (${notification.identifier}) has already been created", tag: getChimeLogPrefix());
      }

      return;
    }

    if (notification.notificationDetails case NotificationDetails details?) {
      try {
        await plugin.zonedSchedule(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          notificationDetails: details,
          scheduledDate: notification.scheduledDate,
          androidScheduleMode: notification.androidScheduleMode ?? AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: notification.dateTimeComponents ?? DateTimeComponents.dateAndTime,
          payload: notification.payload
        );

        if(showChimeLogs) {
          console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: getChimeLogPrefix());
        }
        await publishEvent(NotificationScheduledEvent(notification));
      } catch (error, st) {
        if(showChimeLogs) {
          console.info("Notification failed to build. Sending it to `failedNotification` controller", tag: getChimeLogPrefix());
        }
        await publishEvent(NotificationFailedEvent(notification, error, st));
      }
    } else {
      console.warn("Notification could not be built since it is lacking `notificationDetails`", tag: getChimeLogPrefix());
    }
  }
}

/// Callback type for handling notification taps.
///
/// The [ChimeNotificationCallback] is invoked when a notification is tapped,
/// providing the associated [ChimeNotification] object.
///
/// This is typically used to route the user to a specific screen or to mark
/// content as read.
typedef ChimeNotificationCallback = void Function(ChimeNotification);

/// Callback type for handling notification responses.
///
/// The [NotificationResponseCallback] is invoked when a user interacts
/// with a notification and returns the associated [NotificationResponse].
///
/// Use this to access action identifiers, input text, or platform metadata.
typedef NotificationResponseCallback = void Function(NotificationResponse);

/// {@template chime_push_notification}
/// Interface for handling device-level push notifications.
///
/// Implementations should:
/// - request and verify permissions
/// - initialize the notification plugin with callbacks
/// - translate platform responses into [ChimeNotification] instances
/// - expose lifecycle hooks for when the app is launched from a notification
///
/// This interface is intentionally minimal so platform-specific services
/// (Firebase, APNs, etc.) can plug in without tight coupling.
/// {@endtemplate}
abstract interface class ChimePushNotification {
  /// Requests permission for notifications.
  ///
  /// This method should be implemented to request necessary permissions for
  /// displaying notifications. Depending on the platform, it may involve requesting
  /// permission to send alerts, badges, or sounds.
  /// 
  /// Implementations should handle platform differences and return `true` only
  /// when the permission prompt is accepted (or already granted).
  ///
  /// @return A [Future] that resolves to a [bool] indicating if the permission was granted.
  Future<bool> requestPermission();

  /// Returns the platform this implementation targets.
  ///
  /// Use this to branch on platform-specific behavior when needed, such as
  /// requesting permissions or reading launch details.
  ChimePlatform getPlatform();

  /// Returns the application name used for notification channels.
  ///
  /// This is typically used for Android channel registration and logging.
  String getApplicationName();

  /// Checks if notifications are permitted for the device.
  ///
  /// Returns a [Future] that resolves to `true` if notification permissions are granted,
  /// and `false` otherwise.
  ///
  /// @return A [Future] indicating whether notifications are permitted.
  ///
  /// Implementations should reflect the platform's runtime permission state
  /// without prompting the user.
  Future<bool> get isPermitted;

  /// Initializes the notification service.
  ///
  /// Provide [initializationSettings] for the underlying platform. The optional
  /// callbacks are invoked when notifications are tapped in the foreground or
  /// when a background response is received.
  ///
  /// Implementations should publish [NotificationReceivedEvent] and
  /// [NotificationTappedEvent] as appropriate so listeners can react.
  Future<void> initialize({
    required InitializationSettings initializationSettings,
    ChimeNotificationCallback? onNotificationTapped,
    NotificationResponseCallback? onBackgroundNotificationReceived
  });

  /// Registers a callback invoked when the app is launched via a notification.
  ///
  /// Use this to deep-link into your UI at startup.
  Future<void> onAppLaunchedByNotification(ChimeNotificationCallback onAppLaunchedByNotification);
}

/// {@template default_device_notification}
/// Provides the default implementation of [ChimePushNotification]
/// using the `flutter_local_notifications` plugin for notification
/// initialization, permission handling, and response processing.
///
/// This class is designed to be used as the underlying system for
/// managing native device notifications.
///
/// ### Example
/// ```dart
/// final notificationService = DefaultChimePushNotification(
///   'MyApp',
///   ChimePlatform.ANDROID,
/// );
/// await notificationService.requestPermission();
/// await notificationService.initialize(
///   initializationSettings: InitializationSettings(
///     android: AndroidInitializationSettings('@mipmap/ic_launcher'),
///   ),
/// );
/// ```
/// {@endtemplate}
/// {@template default_chime_push_notification}
/// Default [ChimePushNotification] backed by `flutter_local_notifications`.
///
/// This implementation handles permission requests, initialization, and
/// response dispatching for local and push notifications. It is intended to be
/// used as the base device notification handler in most applications.
/// {@endtemplate}
@internal
class DefaultChimePushNotification with ChimeMixin implements ChimePushNotification {
  /// Label prefix used for logging and debugging.
  ///
  /// Defaults to `"Chime Device Core"`.
  final String prefix = "Chime Device Core";

  /// The platform this instance is configured for.
  final ChimePlatform _platform;

  /// The app name used for platform channel configuration.
  final String _applicationName;

  /// {@macro default_chime_push_notification}
  DefaultChimePushNotification(this._applicationName, this._platform);

  @override
  ChimePlatform getPlatform() => _platform;

  @override
  String getApplicationName() => _applicationName;

  @override
  Future<bool> requestPermission() async {
    if (getPlatform() == ChimePlatform.IOS) {
      return await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    } else if (getPlatform() == ChimePlatform.ANDROID) {
      final response = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? grantedNotificationPermission = await response?.requestNotificationsPermission();

      return grantedNotificationPermission ?? false;
    }

    return false;
  }

  @override
  Future<void> initialize({
    required InitializationSettings initializationSettings,
    ChimeNotificationCallback? onNotificationTapped,
    NotificationResponseCallback? onBackgroundNotificationReceived
  }) async {
    if(showChimeLogs) {
      console.debug("Initializing remote notification for ${getApplicationName()}", tag: prefix);
    }

    _chimeBackgroundForwarder = onBackgroundNotificationReceived;
    _chimeBackgroundPublisher = (details) async {
      final notification = ChimeNotification(
        action: details.actionId,
        input: details.input,
        id: details.id ?? 0,
        data: details.data,
        identifier: details.toString(),
      );

      if (showChimeLogs) {
        console.info("Background notification for ${getApplicationName()} details: $notification", tag: prefix);
      }

      try {
        await publishEvent(
          NotificationReceivedEvent(
            notification,
            response: details,
            isBackgroundNotification: true,
          ),
        );
      } catch (_) {}
    };

    await plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        if(showChimeLogs) {
          console.info("Remote notification for ${getApplicationName()}", tag: prefix);
        }

        final notification = ChimeNotification(
          action: response.actionId,
          input: response.input,
          id: response.id ?? 0,
          data: response.data,
          identifier: response.toString()
        );

        if(showChimeLogs) {
          console.info("Remote notification for ${getApplicationName()} details: $notification", tag: prefix);
        }

        if (onNotificationTapped case final onTapped?) {
          onTapped(notification);
          await publishEvent(NotificationTappedEvent(notification));
        }

        try {
          await publishEvent(NotificationReceivedEvent(notification, response: response));
        } catch (_) {}
      },
      onDidReceiveBackgroundNotificationResponse: chimeBackgroundNotificationDispatcher,
    ).then((v) {
      if(v ?? false) {
        if(showChimeLogs) {
          console.info("Initialized remote notification for ${getApplicationName()}", tag: prefix);
        }
      } else {
        if(showChimeLogs) {
          console.error("Couldn't initialize remote notification for ${getApplicationName()}", tag: prefix);
        }
      }
    });
  }

  @override
  Future<bool> get isPermitted async {
    if (getPlatform() == ChimePlatform.ANDROID) {
      return await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
    } else if (getPlatform() == ChimePlatform.IOS) {
      final response = await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
      return response?.isEnabled ?? false;
    }

    return false;
  }

  @override
  Future<void> onAppLaunchedByNotification(ChimeNotificationCallback onAppLaunchedByNotification) async {
    final NotificationAppLaunchDetails? details = getPlatform() == ChimePlatform.WEB
      ? null
      : await plugin.getNotificationAppLaunchDetails();

    if (details != null && details.didNotificationLaunchApp) {
      if(details.notificationResponse case final response?) {
        final notification = ChimeNotification(
          action: response.actionId,
          input: response.input,
          id: response.id ?? 0,
          data: response.data,
          identifier: response.toString()
        );

        if(showChimeLogs) {
          console.info("App launched notification for ${getApplicationName()} response: $notification", tag: prefix);
        }

        try {
          await publishEvent(NotificationLaunchedAppEvent(notification, response: response));
        } catch (_) {}
      }
    }
  }
}
