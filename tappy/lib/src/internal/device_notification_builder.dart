import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tracing/tracing.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/tappy_event.dart';
import '../enums/tappy_type.dart';
import '../models/notifier.dart';
import '../models/remote_notification.dart';
import '../config/definitions.dart';
import '../config/tappy_sound.dart';
import '../config/platform_engine.dart';
import '../device_notification_builder.dart';
import '../models/remote_notification_config.dart';
import '../models/types/call_notification.dart';
import '../models/types/chat_notification.dart';
import '../models/types/nearby_notification.dart';
import '../models/types/schedule_notification.dart';
import '../models/types/transaction_notification.dart';
import '../models/types/trip_notification.dart';
import '../core/tappy.dart';
import '../core/tappy_mixin.dart';
import 'device_notification.dart';

class DefaultDeviceNotificationBuilder<T> with TappyMixin implements DeviceNotificationBuilderInterface<T> {
  DefaultDeviceNotificationBuilder();

  final String prefix = "[Tappy Device Builder]";

  RemoteNotificationConfig<T>? _config;
  int createUniqueId() => DateTime.now().millisecondsSinceEpoch.remainder(100000);

  Int64List lowVibrationPattern = Int64List.fromList([0, 200, 200, 200]);
  Int64List mediumVibrationPattern = Int64List.fromList([0, 500, 200, 200, 200, 200]);
  Int64List highVibrationPattern = Int64List.fromList([0, 1000, 200, 200, 200, 200, 200, 200]);

  @protected
  Color get _COMMON_BUTTON_COLOR => _config?.buttonColor ?? Colors.blueGrey;

  @protected
  Color get _COMMON_DANGER_BUTTON_COLOR => _config?.dangerButtonColor ?? Colors.red;

  @protected
  Color get _NOTIFICATION_COLOR => _config?.backgroundColor ?? Color(0xfff1f1f1);

  @protected
  bool get _isColored => _config != null && _config!.backgroundColor != null;

  @protected
  String _sound(String fallback) => _config?.sound ?? fallback;

  @protected
  RawResourceAndroidNotificationSound androidSound(TappySound sound) => RawResourceAndroidNotificationSound(_sound(sound.getKey()));

  @protected
  String _getEvent(TappyEvent event) => event.getKey();

  Future<void> _configureLocalTimeZone(String timezone) async {
    if (PlatformEngine.isWeb) {
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezone.isNotEmpty ? timezone : "Africa/Lagos"));
  }

  @override
  void build(RemoteNotificationConfig<T> config) {
    _config = config;

    switch(config.type) {
      case TappyType.CALL:
        return _buildCall(config.notification, config.isBackground, config.useInApp);
      case TappyType.CHAT:
        return _buildChat(config.notification, config.isBackground, config.useInApp, config.onMessageDecrypted);
      case TappyType.SCHEDULE:
        _configureLocalTimeZone(config.timezone);

        return _buildSchedule(config.notification, config.isBackground, config.useInApp);
      case TappyType.TRANSACTION:
        return _buildTransaction(config.notification, config.isBackground, config.useInApp);
      case TappyType.TRIP:
        return _buildTrip(config.notification, config.isBackground, config.useInApp);
      case TappyType.NEARBY_BCAP:
        return _buildNearbyBCap(config.notification, config.isBackground, config.useInApp);
      case TappyType.NEARBY_ACTIVITY:
        return _buildNearbyActivity(config.notification, config.isBackground, config.useInApp);
      case TappyType.NEARBY_TREND:
        return _buildNearbyTrend(config.notification, config.isBackground, config.useInApp);
      default:
        return _buildOthers(config.notification, config.isBackground, config.useInApp);
    }
  }

  void _buildChat(RemoteNotification notification, bool isBackground, bool useInApp, MessageDecryptionCallback? decryptor) async {
    if(Tappy.showLogs) {
      console.debug("Building chat notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    ChatResponse message = TappyType.chat(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.CHAT,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.foreign, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.CALL.getChannel(),
        'Chat Notification',
        channelDescription: 'Notification for chat messaging',
        channelShowBadge: true,
        playSound: true,
        groupAlertBehavior: GroupAlertBehavior.children,
        vibrationPattern: lowVibrationPattern,
        sound: androidSound(TappySound.MESSAGE),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'chat_ticker',
        showWhen: true,
        subText: message.summary,
        category: AndroidNotificationCategory.message,
        groupKey: message.room,
        color: _NOTIFICATION_COLOR,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _getEvent(TappyEvent.REPLY_MESSAGE),
            'Reply',
            titleColor: _COMMON_BUTTON_COLOR,
            inputs: [
              AndroidNotificationActionInput(label: "Reply message")
            ],
            cancelNotification: false
          ),
          AndroidNotificationAction(
            _getEvent(TappyEvent.VIEW_CHAT),
            "Open",
            titleColor: _COMMON_BUTTON_COLOR,
            cancelNotification: false
          ),
          AndroidNotificationAction(
            _getEvent(TappyEvent.MARK_MESSAGE_AS_READ),
            "Mark read",
            titleColor: _COMMON_BUTTON_COLOR,
            cancelNotification: false
          ),
        ],
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.CALL.getChannel(),
        // sound: 'message.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      String body = process(
        decryptor,
        onProcess: (value) => value(notification.body),
      ) ?? "";
      body = body.isEmpty ? "Chat message from ${message.name}" : body;

      if(Tappy.showLogs) {
        console.info("Notification body info: Encrypted = ${notification.body} | Decrypted = $body", tag: prefix);
      }

      await plugin.show(id, notification.title, body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildCall(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building call notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    CallNotification message = TappyType.call(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.CALL,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify("${message.channel}:::${message.type}", orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.info("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.CALL.getChannel(),
        'Call Notification',
        channelDescription: 'Notification for incoming calls (Video, Audio and T2F)',
        channelShowBadge: message.isMissed ? true : false,
        playSound: message.isMissed ? false : true,
        groupAlertBehavior: GroupAlertBehavior.children,
        sound: androidSound(TappySound.INCOMING),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'call_ticker',
        showWhen: true,
        fullScreenIntent: true,
        timeoutAfter: 3000,
        vibrationPattern: highVibrationPattern,
        ongoing: message.isRinging,
        category: message.isMissed ? AndroidNotificationCategory.missedCall : AndroidNotificationCategory.call,
        groupKey: message.isMissed ? 'missed_calls' : message.channel,
        color: _NOTIFICATION_COLOR,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _getEvent(TappyEvent.VIEW_CALL),
            'Open',
            titleColor: _COMMON_BUTTON_COLOR,
            cancelNotification: false
          ),
        ],
        // actions: <AndroidNotificationAction>[
        //   AndroidNotificationAction(
        //     TappyEventKey.ANSWER_INCOMING_CALL,
        //     'Answer',
        //     titleColor: Colors.greenAccent,
        //   ),
        //   AndroidNotificationAction(
        //     TappyEventKey.DECLINE_INCOMING_CALL,
        //     "Decline",
        //     titleColor: _COMMON_DANGER_BUTTON_COLOR,
        //   ),
        // ],
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.CALL.getChannel(),
        // sound: 'incoming.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildTransaction(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building transaction notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    TransactionResponse message = TappyType.transaction(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.TRANSACTION,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.foreign, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.TRANSACTION.getChannel(),
        'Transaction Notification',
        channelDescription: 'Notification for platform transactions',
        playSound: true,
        vibrationPattern: mediumVibrationPattern,
        sound: androidSound(TappySound.NOTIFY),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'transaction_ticker',
        showWhen: true,
        groupKey: 'payment_transactions',
        color: _NOTIFICATION_COLOR,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _getEvent(TappyEvent.VIEW_TRANSACTION),
            'View details',
            titleColor: _COMMON_BUTTON_COLOR,
            cancelNotification: false
          ),
        ],
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.TRANSACTION.getChannel(),
        // sound: 'tappy.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildSchedule(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building schedule notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    ScheduleNotification message = TappyType.schedule(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.SCHEDULE,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.id, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.SCHEDULE.getChannel(),
        'Schedule Notification',
        channelDescription: 'Notification for trip schedules',
        playSound: true,
        vibrationPattern: highVibrationPattern,
        sound: androidSound(TappySound.NOTIFY),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'schedule_ticker',
        showWhen: true,
        groupKey: 'schedules',
        color: _NOTIFICATION_COLOR,
        actions: <AndroidNotificationAction>[
          if(message.isPending) ...[
            AndroidNotificationAction(
              _getEvent(TappyEvent.ACCEPT_SCHEDULE),
              'Accept',
              titleColor: _COMMON_BUTTON_COLOR,
              cancelNotification: false
            ),
            AndroidNotificationAction(
              _getEvent(TappyEvent.DECLINE_SCHEDULE),
              'Decline',
              titleColor: _COMMON_DANGER_BUTTON_COLOR,
              cancelNotification: false,
              inputs: [
                AndroidNotificationActionInput(label: "Let us know the reason for cancellation")
              ]
            ),
          ],
          AndroidNotificationAction(
            _getEvent(TappyEvent.VIEW_SCHEDULE),
            'View details',
            titleColor: _COMMON_BUTTON_COLOR,
          ),
        ],
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.SCHEDULE.getChannel(),
        // sound: 'schedule.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }

    _buildScheduledNotification(id, notification, message, notifier);
  }

  /// Combines the current date with a given time string.
  ///
  /// The time string must be in the format "Minute:Seconds AM/PM",
  /// such as "9:00 AM" or "9:00PM".
  ///
  /// Returns a [DateTime] object representing the combined date and time.
  ///
  /// Example:
  /// ```dart
  /// DateTime result = parseTimeToDate("9:00 AM");
  /// print(result); // Prints: 2025-01-07 09:00:00.000
  /// ```
  String _parseTimeToDate(String time) {
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

  void _buildScheduledNotification(int id, RemoteNotification notification, ScheduleNotification message, Notifier notifier) async {
    if(Tappy.showLogs) {
      console.debug("Building scheduled notification", tag: prefix);
    }

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      TappyType.SCHEDULE.getChannel(),
      'Scheduled Notification',
      channelDescription: 'Notification for scheduled trips',
      ledColor: Color(0xff050404),
      playSound: true,
      vibrationPattern: highVibrationPattern,
      sound: androidSound(TappySound.NOTIFY),
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'schedule_ticker',
      showWhen: true,
      groupKey: 'scheduled_trips',
      color: _NOTIFICATION_COLOR,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _getEvent(TappyEvent.START_SCHEDULED_TRIP),
          'Start scheduled trip',
          titleColor: _COMMON_BUTTON_COLOR,
          cancelNotification: false
        ),
      ],
    );

    DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      categoryIdentifier: TappyType.SCHEDULE.getChannel(),
      sound: 'schedule.aiff',
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await plugin.zonedSchedule(
      id,
      notification.title,
      notification.body,
      tz.TZDateTime.parse(tz.local, _parseTimeToDate(message.time)),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: notifier.toString()
    );

    Tappy.lifecycle.onScheduled(notifier);
  }

  void _buildTrip(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building trip notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    TripNotification message = TappyType.trip(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.TRIP,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.trip, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.TRIP.getChannel(),
        'Trip Notification',
        channelDescription: 'Notification for service trips',
        playSound: true,
        groupAlertBehavior: GroupAlertBehavior.children,
        vibrationPattern: mediumVibrationPattern,
        sound: androidSound(TappySound.CONNECT),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'trip_ticker',
        showWhen: true,
        groupKey: message.trip,
        color: _NOTIFICATION_COLOR,
        ongoing: message.isWaiting || message.isActive,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _getEvent(TappyEvent.VIEW_TRIP_DETAILS),
            'View details',
            titleColor: _COMMON_BUTTON_COLOR,
            cancelNotification: false
          ),
        ],
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.TRIP.getChannel(),
        // sound: 'connect.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildNearbyBCap(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building go-bcap notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    NearbyBCapNotification message = TappyType.nearbyBcap(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.NEARBY_BCAP,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.title, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.NEARBY_BCAP.getChannel(),
        'Go BCap Notification',
        channelDescription: 'Notification for go bcap notifications, showing updates about an event.',
        playSound: true,
        groupAlertBehavior: GroupAlertBehavior.children,
        vibrationPattern: mediumVibrationPattern,
        sound: androidSound(TappySound.NOTIFY),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'go-bcap_ticker',
        showWhen: true,
        groupKey: "${message.interest}",
        color: _NOTIFICATION_COLOR,
        colorized: _isColored,
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.NEARBY_BCAP.getChannel(),
        // sound: 'connect.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildNearbyActivity(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building go-activity notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    NearbyActivityNotification message = TappyType.nearbyActivity(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.NEARBY_ACTIVITY,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.title, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.NEARBY_ACTIVITY.getChannel(),
        'Go Activity Notification',
        channelDescription: 'Notification for go activity notifications, showing updates about an activity.',
        playSound: true,
        groupAlertBehavior: GroupAlertBehavior.children,
        vibrationPattern: mediumVibrationPattern,
        sound: androidSound(TappySound.NOTIFY),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'go-activity_ticker',
        subText: message.summary,
        showWhen: true,
        groupKey: "${message.interest}",
        color: _NOTIFICATION_COLOR,
        colorized: _isColored,
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.NEARBY_ACTIVITY.getChannel(),
        // sound: 'connect.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildNearbyTrend(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building go-trend notification", tag: prefix);
    }

    if(notification.data == null) {
      if(Tappy.showLogs) {
        console.warn("Couldn't complete notification building due to null data", tag: prefix);
      }

      return;
    }

    int id = createUniqueId();
    NearbyTrendNotification message = TappyType.nearbyTrend(notification.data);
    Notifier notifier = Notifier(
      type: TappyType.NEARBY_TREND,
      id: id,
      data: message.toJson(),
      from: notification.token,
      foreign: qualify(message.title, orElse: notification.title)
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.NEARBY_TREND.getChannel(),
        'Go Trend Notification',
        channelDescription: 'Notification for go trend notifications, showing updates about an interest trends.',
        playSound: true,
        groupAlertBehavior: GroupAlertBehavior.children,
        vibrationPattern: mediumVibrationPattern,
        sound: androidSound(TappySound.NOTIFY),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'go-trend_ticker',
        showWhen: true,
        groupKey: "${message.interest}",
        color: _NOTIFICATION_COLOR,
        colorized: _isColored,
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.NEARBY_TREND.getChannel(),
        // sound: 'connect.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString()).then((v) {
        if(Tappy.showLogs) {
          console.info("Notification builder done", tag: prefix);
        }
      });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }

  void _buildOthers(RemoteNotification notification, bool isBackground, bool useInApp) async {
    if(Tappy.showLogs) {
      console.debug("Building other notifications", tag: prefix);
    }

    int id = createUniqueId();
    Notifier notifier = Notifier(
      type: TappyType.OTHERS,
      id: id,
      data: OtherNotificationData(notification.data),
      from: notification.token,
      foreign: notification.title
    );

    if(controller.hasCreatedNotification(notifier)) {
      if(Tappy.showLogs) {
        console.trace("Notification with foreign key: ${notifier.foreign} has already been created", tag: prefix);
      }

      return;
    }

    if(useInApp && !isBackground) {
      if(Tappy.showLogs) {
        console.debug("Sending notification to `inAppNotificationController` for inApp builder", tag: prefix);
      }

      Tappy.lifecycle.onUseInApp(notifier);
      return;
    } else {
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        TappyType.OTHERS.getChannel(),
        'Other Notifications',
        channelDescription: 'Notification for services not defined or independent',
        playSound: true,
        groupAlertBehavior: GroupAlertBehavior.children,
        sound: androidSound(TappySound.NOTIFY),
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'other_ticker',
        showWhen: true,
        groupKey: "Hapnium Inc.",
        color: _NOTIFICATION_COLOR,
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: TappyType.OTHERS.getChannel(),
        // sound: 'tappy.aiff',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await plugin.show(id, notification.title, notification.body, notificationDetails, payload: notifier.toString())
        .then((v) {
          if(Tappy.showLogs) {
            console.info("Notification builder done", tag: prefix);
          }
        });

      if(Tappy.showLogs) {
        console.info("Notification built successfully. Sending it to `createdNotification` controller", tag: prefix);
      }

      Tappy.lifecycle.onCreated(notifier);
    }
  }
}

final class OtherNotificationData extends MapView<String, dynamic> {
  OtherNotificationData(dynamic data) : super({"other": data});
}