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
/// A data model representing a notification within the Chime notification system.
///
/// This immutable class encapsulates all the data needed to display, process,
/// and respond to a notification, whether it originates from a push notification,
/// local alert, or in-app event.
///
/// The name "Chime" suggests a notification system that creates attention
/// (like a bell chime) while maintaining elegance and clarity.
///
/// ### Usage Example
/// ```dart
/// final notification = ChimeNotification(
///   id: 12345,
///   action: 'navigate_to_chat',
///   input: 'user_reply',
///   payload: '{"chat_id": "abc123", "sender": "John"}',
/// );
///
/// final data = notification.getPayloadAsJson();
/// if (data != null) {
///   print(data['chat_id']); // Output: abc123
/// }
/// ```
/// {@endtemplate}
final class ChimeNotification with EqualsAndHashCode, ToString {
  /// Unique identifier for the notification.
  ///
  /// This is often used to track or update specific notifications in local
  /// databases or UI lists. Typically assigned a real value on creation.
  final int id;

  /// Represents the action to take in response to the notification.
  ///
  /// This string maps to UI behaviors or domain actions. Common examples:
  /// - `"navigate_to_chat"`: Opens a chat screen
  /// - `"show_alert"`: Displays an alert dialog
  /// - `"update_badge"`: Updates app badge count
  /// - `"open_url"`: Opens a web URL
  final String? action;

  /// Represents any user input or command associated with the notification.
  ///
  /// This may be a response in a reply notification or a form value.
  /// Examples:
  /// - `"user_reply"`: For reply-style notifications
  /// - `"yes"`/`"no"`: For confirmation notifications
  /// - `""`: When no specific input is provided
  final String? input;

  /// Optional JSON-encoded string containing additional notification data.
  ///
  /// This field can contain any structured data needed to process the
  /// notification, such as:
  /// - Chat or message IDs
  /// - User information
  /// - Deep link parameters
  /// - Custom metadata
  ///
  /// Use [getPayloadAsJson()] to safely parse this field.
  final String? payload;

  final String identifier;

  final Map<String, dynamic> data;

  /// {@macro chime_notification}
  const ChimeNotification({
    required this.id,
    required this.action,
    required this.input,
    this.payload,
    required this.identifier,
    this.data = const {}
  });

  /// {@macro chime_notification}
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

  @override
  List<Object?> equalizedProperties() => [action, input, payload, id];
}

final class ChimeCreatedNotification extends ChimeNotification {
  final String? title;
  final String? body;
  final NotificationDetails? notificationDetails;

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
  List<Object?> equalizedProperties() => [...super.equalizedProperties(), title, body];
}

final class ChimeScheduledNotification extends ChimeCreatedNotification {
  final TZDateTime scheduledDate;
  final AndroidScheduleMode? androidScheduleMode;
  final DateTimeComponents? dateTimeComponents;
  
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
  List<Object?> equalizedProperties() => [...super.equalizedProperties(), title, body];
}

final class ChimeAppNotification extends ChimeNotification {
  final String title;
  final String description;
  final ChimeInAppState state;
  final ToastificationItem item;
  
  ChimeAppNotification({
    required super.identifier,
    required this.description,
    required this.state,
    required this.title,
    required this.item,
    super.data
  }) : super(id: _generateSecureRandomId(), action: "IN_APP", input: "IN_APP");
}

final class ChimeCreatedAppNotification extends ChimeCreatedNotification {
  final String description;
  final ChimeInAppState state;
  final ToastificationItem item;

  ChimeCreatedAppNotification({
    required super.identifier,
    required String title,
    required this.description,
    required this.state,
    required this.item,
    super.data
  }) : super(title: title, id: _generateSecureRandomId());
}