import 'package:flutter_local_notifications/flutter_local_notifications.dart' show NotificationResponse;

import '../config/definitions.dart';
import '../models/notifier.dart';
import '../models/remote_notification.dart';
import '../models/types/call_notification.dart';
import '../models/types/chat_notification.dart';
import '../models/types/nearby_notification.dart';
import '../models/types/schedule_notification.dart';
import '../models/types/transaction_notification.dart';
import '../models/types/trip_notification.dart';

/// {@template tappy_type}
/// Enum representing different types of notification events.
///
/// Used to categorize and route notifications to appropriate handlers
/// or UI components in the application.
///
/// ### Categories:
/// - `TRANSACTION`: Notifications about financial transactions.
/// - `TRIP`: Notifications for travel or trip-related updates.
/// - `SCHEDULE`: Notifications for calendar or scheduled events.
/// - `CHAT`: Messaging-related notifications.
/// - `CALL`: Notifications for incoming or ongoing calls.
/// - `NEARBY_BCAP`: Notifications about nearby broadcasted capabilities.
/// - `NEARBY_ACTIVITY`: Notifications about nearby activities.
/// - `NEARBY_TREND`: Notifications about trending activities nearby.
/// - `NEARBY_TOURNAMENT`: Notifications about nearby tournaments.
/// - `OTHERS`: Fallback for unclassified or custom types.
/// 
/// ### Example usage:
/// ```dart
/// final type = fromString("transaction");
/// ```
/// {@endtemplate}
enum TappyType {
  /// Notification related to a default notification.
  /// 
  /// {@macro tappy_type}
  DEFAULT("snt"),

  /// Notification related to a default call notification.
  /// 
  /// {@macro tappy_type}
  DEFAULT_CALL("sender"),

  /// Notification related to a transaction.
  /// 
  /// {@macro tappy_type}
  TRANSACTION("transaction"),

  /// Notification related to a trip.
  /// 
  /// {@macro tappy_type}
  TRIP("trip"),

  /// Notification related to a nearby broadcast capability.
  /// 
  /// {@macro tappy_type}
  NEARBY_BCAP("nearby_bcap"),

  /// Notification related to a nearby activity.
  /// 
  /// {@macro tappy_type}
  NEARBY_ACTIVITY("nearby_activity"),

  /// Notification related to a nearby trend.
  /// 
  /// {@macro tappy_type}
  NEARBY_TREND("nearby_trend"),

  /// Notification related to a nearby tournament.
  /// 
  /// {@macro tappy_type}
  NEARBY_TOURNAMENT("nearby_tournament"),

  /// Notification related to a scheduled event.
  /// 
  /// {@macro tappy_type}
  SCHEDULE("schedule"),

  /// Notification related to a chat or messaging.
  /// 
  /// {@macro tappy_type}
  CHAT("chat"),

  /// Notification related to a voice or video call.
  /// 
  /// {@macro tappy_type}
  CALL("call"),

  /// Fallback type for unknown or uncategorized notifications.
  /// 
  /// {@macro tappy_type}
  OTHERS("others");

  /// Internal type identifier.
  final String _type;

  /// Const constructor for enum with associated string type.
  /// 
  /// {@macro tappy_type}
  const TappyType(this._type);

  /// Returns the notification channel name, e.g., `transaction_notification`.
  String getChannel() => "${_type}_notification";

  /// Returns the enum key as an uppercase string, e.g., `TRANSACTION`.
  String getKey() => _type.toUpperCase();

  /// Returns the original type string, e.g., `transaction`.
  String getType() => _type;

  /// Factory method to get [TappyType] from a raw string.
  ///
  /// If the value is not recognized, [OTHERS] is returned.
  /// 
  /// {@macro tappy_type}
  static TappyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'transaction':
        return TRANSACTION;
      case 'trip':
        return TRIP;
      case 'schedule':
        return SCHEDULE;
      case 'chat':
        return CHAT;
      case 'call':
        return CALL;
      case 'nearby_bcap':
        return NEARBY_BCAP;
      case 'nearby_activity':
        return NEARBY_ACTIVITY;
      case 'nearby_trend':
        return NEARBY_TREND;
      case 'nearby_tournament':
        return NEARBY_TOURNAMENT;
      default:
        return OTHERS;
    }
  }

  /// Factory method to get [TappyType] from a raw data map.
  /// 
  /// This method type checks the notification to classify the notification
  /// and fills in fallback values if the type is unrecognized.
  /// 
  /// Returns an instance of [TappyType] with all computed flags and UI preferences.
  /// 
  /// {@macro tappy_type}
  static TappyType fromData(Data data) {
    bool hasDefault = data.containsKey(DEFAULT.name);
    bool hasDefaultCall = data.containsKey(DEFAULT_CALL.name);
    
    if(hasDefault && data[DEFAULT.name] == CHAT) {
      return CHAT;
    }

    if((hasDefault && data[DEFAULT.name] == CALL) || (hasDefaultCall && data[DEFAULT_CALL.name] == CALL)) {
      return CALL;
    }

    if(hasDefault && data[DEFAULT.name] == TRANSACTION) {
      return TRANSACTION;
    }

    if(hasDefault && data[DEFAULT.name] == TRIP) {
      return TRIP;
    }

    if(hasDefault && data[DEFAULT.name] == SCHEDULE) {
      return SCHEDULE;
    }

    if(hasDefault && data[DEFAULT.name] == NEARBY_BCAP) {
      return NEARBY_BCAP;
    }

    if(hasDefault && data[DEFAULT.name] == NEARBY_ACTIVITY) {
      return NEARBY_ACTIVITY;
    }

    if(hasDefault && data[DEFAULT.name] == NEARBY_TREND) {
      return NEARBY_TREND;
    }

    if(hasDefault && data[DEFAULT.name] == NEARBY_TOURNAMENT) {
      return NEARBY_TOURNAMENT;
    }

    return OTHERS;
  }

  /// Factory method to build a [RemoteNotification] from a raw data map.
  /// 
  /// This method type checks the notification to classify the notification
  /// and fills in fallback values if the type is unrecognized.
  /// 
  /// Returns an instance of [RemoteNotification] with all computed flags and UI preferences.
  /// 
  /// {@macro remote_notification}
  static RemoteNotification<T> build<T>(Data data, String title, String body) {
    RemoteNotification<T> notification = RemoteNotification.fromJson(data);

    switch(fromData(data)) {
      case OTHERS:
      case DEFAULT:
      case DEFAULT_CALL:
        notification = notification.copyWith(title: title, body: body);
        break;
      default:
        break;
    }

    return notification;
  }

  /// Creates a [ChatResponse] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [ChatResponse].
  static ChatResponse chat(Data json) {
    return ChatResponse.fromJson(json);
  }

  /// Creates a [CallNotification] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [CallNotification].
  static CallNotification call(Data json) {
    return CallNotification.fromJson(json);
  }

  /// Creates a [TripNotification] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [TripNotification].
  static TripNotification trip(Data json) {
    return TripNotification.fromJson(json);
  }

  /// Creates a [TransactionResponse] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [TransactionResponse].
  static TransactionResponse transaction(Data json) {
    return TransactionResponse.fromJson(json);
  }

  /// Creates a [ScheduleNotification] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [ScheduleNotification].
  static ScheduleNotification schedule(Data json) {
    return ScheduleNotification.fromJson(json);
  }

  /// Creates a [NearbyActivityNotification] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [NearbyActivityNotification].
  static NearbyActivityNotification nearbyActivity(Data json) {
    return NearbyActivityNotification.fromJson(json);
  }

  /// Creates a [NearbyBCapNotification] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [NearbyBCapNotification].
  static NearbyBCapNotification nearbyBcap(Data json) {
    return NearbyBCapNotification.fromJson(json);
  }

  /// Creates a [NearbyTrendNotification] from the given JSON data.
  ///
  /// - [json]: The JSON data to parse into a [NearbyTrendNotification].
  static NearbyTrendNotification nearbyTrend(Data json) {
    return NearbyTrendNotification.fromJson(json);
  }

  /// Creates a [Notifier] from the given [NotificationResponse] data.
  ///
  /// - [response]: The [NotificationResponse] data to parse into a [Notifier] payload.
  static Notifier parse(NotificationResponse response) {
    Notifier notifier;

    if(response.payload != null) {
      notifier = Notifier.fromString(response.payload!);
    } else {
      notifier = Notifier.empty();
    }
    notifier = notifier.copyWith(action: response.actionId, input: response.input, id: response.id);

    return notifier;
  }
}