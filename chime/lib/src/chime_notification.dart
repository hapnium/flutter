import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hapnium/hapnium.dart';
import 'package:timezone/timezone.dart' show TZDateTime;
import 'package:toastification/toastification.dart';

import 'enums.dart';

int _generateSecureRandomId() {
  final random = Random.secure();
  return random.nextInt(1 << 32);
}

/// {@template chime_notification}
/// Core Chime notification payload.
///
/// [ChimeNotification] is the base data model for all notification flows in
/// Chime: device-level push/local notifications, scheduled reminders, and
/// in-app overlays. It captures a unique identifier, user-visible intent, and
/// an optional payload for richer context.
///
/// This class is intentionally simple and immutable so it can be passed across
/// layers (UI, background handlers, analytics) without side effects.
///
/// Typical usage includes:
/// - interpreting the `action` field to route navigation
/// - reading `payload` for deep link data
/// - using `identifier` to deduplicate or dismiss notifications
/// - storing lightweight metadata in `data`
///
/// Data model conventions:
/// - [id] is the platform notification id (for display/cancel).
/// - [identifier] is your stable domain key (for dedupe/lookup).
/// - [payload] holds JSON-encoded data for external systems.
/// - [data] holds in-memory metadata that does not need encoding.
///
/// ### Usage Example
/// ```dart
/// final notification = ChimeNotification(
///   id: 12345,
///   action: 'navigate_to_chat',
///   input: 'user_reply',
///   payload: '{"chat_id": "abc123", "sender": "John"}',
///   identifier: 'chat:abc123',
/// );
///
/// final data = notification.getPayloadAsJson();
/// if (data != null) {
///   print(data['chat_id']); // Output: abc123
/// }
/// ```
/// {@endtemplate}
final class ChimeNotification with EqualsAndHashCode, ToString {
  /// Unique identifier for the notification instance.
  ///
  /// This is commonly used by the platform notification system to update,
  /// replace, or cancel a displayed notification.
  final int id;

  /// Action to take when the notification is handled.
  ///
  /// This string is application-defined and typically maps to navigation or
  /// domain behavior. Common examples:
  /// - `"navigate_to_chat"`: open a chat screen
  /// - `"show_alert"`: display an alert dialog
  /// - `"update_badge"`: update app badge count
  /// - `"open_url"`: open a web URL
  final String? action;

  /// User input or command associated with the notification.
  ///
  /// For example, a quick-reply string or a confirmation selection. This is
  /// often empty for passive notifications.
  final String? input;

  /// Optional JSON-encoded string with additional data.
  ///
  /// Store structured data here when you need more context than `action` and
  /// `input` provide. Use [getPayloadAsJson] to parse it safely.
  ///
  /// If you already have a map, consider serializing it with `jsonEncode`.
  final String? payload;

  /// Stable identifier for deduplication and lookup.
  ///
  /// This is typically a string key meaningful to your domain, such as a
  /// message ID or composite key. It should remain stable across app launches
  /// so that repeated notifications can be detected.
  final String identifier;

  /// Additional data attached to the notification.
  ///
  /// This is separate from [payload] and useful for in-memory metadata that
  /// does not need JSON encoding. Avoid large objects here.
  final Map<String, dynamic> data;

  /// {@macro chime_notification}
  ///
  /// Use this when you already have a platform id for the notification.
  const ChimeNotification({
    required this.id,
    required this.action,
    required this.input,
    this.payload,
    required this.identifier,
    this.data = const {}
  });

  /// {@macro chime_notification}
  ///
  /// Use this when the platform id should be generated automatically.
  ChimeNotification.withGeneratedId({
    required this.action,
    required this.input,
    this.payload,
    required this.identifier,
    this.data = const {}
  }) : id = _generateSecureRandomId();

  /// Parses the [payload] field as a JSON object if present and valid.
  ///
  /// Returns a [Map] containing the decoded JSON data, or `null` if:
  /// - [payload] is `null`
  /// - [payload] is not valid JSON
  /// - JSON decoding fails for any reason
  ///
  /// ### Example
  /// ```dart
  /// final notification = ChimeNotification(
  ///   id: 1,
  ///   action: 'open_chat',
  ///   input: '',
  ///   payload: '{"chatId": "123", "userId": "456"}',
  /// );
  ///
  /// final data = notification.getPayloadAsJson();
  /// if (data != null) {
  ///   final chatId = data['chatId']; // "123"
  ///   final userId = data['userId']; // "456"
  /// }
  /// ```
  ///
  /// ### Error Handling
  /// This method silently catches JSON parsing errors and returns `null`.
  /// For more detailed error handling, parse the JSON manually.
  Map<String, dynamic>? getPayloadAsJson() {
    if (payload case final payload?) {
      try {
        return jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Serializes this notification into a JSON-ready map.
  ///
  /// Subclasses append their own fields when possible and omit platform
  /// objects that cannot be serialized.
  ///
  /// This output is suitable for analytics, logging, or persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'input': input,
    'payload': payload,
    'identifier': identifier,
    'data': data,
  };

  @override
  List<Object?> equalizedProperties() => [action, input, payload, id];
}

/// {@template chime_created_notification}
/// A Chime notification that has been created for device delivery.
///
/// This extends [ChimeNotification] with display-specific data such as title,
/// body, and platform notification details. It represents a notification that
/// is ready to be shown or scheduled through the local notification system.
///
/// ### Example
/// ```dart
/// final created = ChimeCreatedNotification(
///   id: 10,
///   identifier: 'welcome:1',
///   title: 'Welcome',
///   body: 'Thanks for joining',
///   notificationDetails: NotificationDetails(
///     android: AndroidNotificationDetails('default', 'Default'),
///   ),
/// );
/// ```
/// {@endtemplate}
final class ChimeCreatedNotification extends ChimeNotification {
  /// The visible title of the notification.
  final String? title;

  /// The visible body message of the notification.
  final String? body;

  /// Platform-specific notification details (not JSON-serializable).
  ///
  /// This is used by the notification plugin when displaying the notification.
  /// It is intentionally omitted from [toJson].
  final NotificationDetails? notificationDetails;

  /// {@macro chime_created_notification}
  const ChimeCreatedNotification({
    required super.id,
    super.payload,
    this.body,
    this.notificationDetails,
    this.title,
    required super.identifier,
    super.data
  }) : super(action: "", input: "");

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'title': title,
    'body': body,
  };

  @override
  List<Object?> equalizedProperties() => [...super.equalizedProperties(), title, body];
}

/// {@template chime_scheduled_notification}
/// A notification scheduled for future delivery.
///
/// This extends [ChimeCreatedNotification] with scheduling metadata used by
/// the platform notification system to determine when and how it fires.
///
/// ### Example
/// ```dart
/// final scheduled = ChimeScheduledNotification(
///   id: 11,
///   identifier: 'reminder:1',
///   title: 'Reminder',
///   body: 'Check back later',
///   scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
///   notificationDetails: NotificationDetails(
///     android: AndroidNotificationDetails('default', 'Default'),
///   ),
/// );
/// ```
/// {@endtemplate}
final class ChimeScheduledNotification extends ChimeCreatedNotification {
  /// The scheduled delivery date/time in the local timezone.
  ///
  /// This is serialized to ISO-8601 by [toJson].
  final TZDateTime scheduledDate;

  /// Android scheduling mode used for delivery.
  final AndroidScheduleMode? androidScheduleMode;

  /// The recurrence components used for repeated scheduling.
  ///
  /// This is serialized by enum name in [toJson].
  final DateTimeComponents? dateTimeComponents;
  
  /// {@macro chime_scheduled_notification}
  const ChimeScheduledNotification({
    required super.id,
    super.payload,
    super.body,
    required NotificationDetails notificationDetails,
    super.title,
    required super.identifier,
    required this.scheduledDate,
    this.androidScheduleMode,
    this.dateTimeComponents,
    super.data
  }) : super(notificationDetails: notificationDetails);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'scheduledDate': scheduledDate.toIso8601String(),
    'androidScheduleMode': androidScheduleMode?.name,
    'dateTimeComponents': dateTimeComponents?.name,
  };

  @override
  List<Object?> equalizedProperties() => [...super.equalizedProperties(), title, body];
}

/// {@template chime_app_notification}
/// In-app notification payload used for UI rendering.
///
/// This is created for in-app overlays and toasts, and it includes the
/// in-app state and display content along with the backing toast item.
///
/// ### Example
/// ```dart
/// final inApp = ChimeAppNotification(
///   identifier: 'toast:1',
///   title: 'Update',
///   description: 'Your settings were saved',
///   state: ChimeInAppState.success,
///   item: toastification.show(title: Text('Update')),
/// );
/// ```
/// {@endtemplate}
final class ChimeAppNotification extends ChimeNotification {
  /// The title shown in the in-app notification.
  final String title;

  /// The description shown in the in-app notification.
  final String description;

  /// The in-app visual state (info, warning, success, etc.).
  final ChimeInAppState state;

  /// The toastification item backing the UI (not JSON-serializable).
  ///
  /// This is used to dismiss or update the in-app UI and is omitted from
  /// [toJson].
  final ToastificationItem item;
  
  /// {@macro chime_app_notification}
  ChimeAppNotification({
    required super.identifier,
    required this.description,
    required this.state,
    required this.title,
    required this.item,
    super.data
  }) : super(id: _generateSecureRandomId(), action: "IN_APP", input: "IN_APP");

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'title': title,
    'description': description,
    'state': state.name,
  };
}

/// {@template chime_created_app_notification}
/// Created in-app notification that can be tracked and dismissed.
///
/// This extends [ChimeCreatedNotification] with in-app display fields and
/// state, while still participating in the created-notification pipeline.
/// It is commonly used to find and dismiss a specific in-app toast later.
///
/// ### Example
/// ```dart
/// final createdApp = ChimeCreatedAppNotification(
///   identifier: 'toast:2',
///   title: 'Warning',
///   description: 'Please check your input',
///   state: ChimeInAppState.warning,
///   item: toastification.show(title: Text('Warning')),
/// );
/// ```
/// {@endtemplate}
final class ChimeCreatedAppNotification extends ChimeCreatedNotification {
  /// The description shown in the in-app notification.
  final String description;

  /// The in-app visual state (info, warning, success, etc.).
  final ChimeInAppState state;

  /// The toastification item backing the UI (not JSON-serializable).
  final ToastificationItem item;

  /// {@macro chime_created_app_notification}
  ChimeCreatedAppNotification({
    required super.identifier,
    required String title,
    required this.description,
    required this.state,
    required this.item,
    super.data
  }) : super(title: title, id: _generateSecureRandomId());

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'description': description,
    'state': state.name,
  };
}