import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../device_notification_manager.dart';
import 'device_notification.dart';

/// {@template default_device_notification_manager}
/// Provides a default implementation of [DeviceNotificationManagerInterface] using
/// the `flutter_local_notifications` plugin to manage device notifications.
///
/// This class allows dismissing individual notifications by ID, clearing
/// all notifications, and dismissing notifications by channel or group key.
///
/// ### Example
/// ```dart
/// final manager = DefaultDeviceNotificationManager();
/// manager.dismissById(101);
/// manager.dismissChannelNotifications('chat');
/// manager.dismissAll();
/// ```
/// {@endtemplate}
class DefaultDeviceNotificationManager<T> implements DeviceNotificationManagerInterface<T> {
  /// {@macro default_device_notification_manager}
  DefaultDeviceNotificationManager();

  @override
  void dismissById(int id) async {
    await plugin.cancel(id);
  }

  @override
  void dismissAll() async {
    await plugin.cancelAll();
  }

  @override
  void dismissChannelNotifications(String channel) => _dismiss(channel);

  void _dismiss(String id) async {
    List<ActiveNotification> notifications = await plugin.getActiveNotifications();
    notifications = notifications.where((n) => n.channelId == id).toList();

    if(notifications.isNotEmpty) {
      for (final n in notifications) {
        if(n.id != null) {
          await plugin.cancel(n.id!);
        }
      }
    }
  }

  @override
  void dismissGroupedNotifications(String groupKey) async {
    List<ActiveNotification> notifications = await plugin.getActiveNotifications();
    notifications = notifications.where((n) => n.groupKey == groupKey).toList();

    if(notifications.isNotEmpty) {
      for (final n in notifications) {
        if(n.id != null) {
          await plugin.cancel(n.id!);
        }
      }
    }
  }
}