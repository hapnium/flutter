import 'dart:convert';

import '../enums/tappy_type.dart';

/// {@template notifier}
/// A generic class that encapsulates notification event data and metadata.
///
/// The [Notifier] class is designed to manage and transport information related
/// to a specific notification, including its type, payload (`data`), origin (`from`),
/// destination (`foreign`), and any associated actions or user input.
///
/// This is useful for notification handling in a reactive system, especially where
/// actions can be dispatched based on types or context.
///
/// ### Example
/// ```dart
/// final notification = Notifier<MyData>(
///   id: 101,
///   type: TappyType.TRIP,
///   data: MyData(...),
///   action: "VIEW_TRIP",
///   input: "",
///   from: "server",
///   foreign: "user_123"
/// );
///
/// if (notification.hasAction) {
///   handleAction(notification.action);
/// }
/// ```
///
/// The [Notifier] class also supports conversion to/from JSON, making it suitable
/// for use with APIs and local persistence mechanisms.
/// {@endtemplate}
final class Notifier {
  /// Unique identifier for the notification.
  ///
  /// This is often used to track or update specific notifications in local
  /// databases or UI lists.
  ///
  /// Default: `null` (but typically assigned a real value on creation).
  final int id;

  /// Represents the action to take in response to the notification.
  ///
  /// This may map to UI behaviors or domain actions.
  ///
  /// Default: `""`
  final String action;

  /// Represents any user input or command associated with the notification.
  ///
  /// This may be a response in a reply notification or a form value.
  ///
  /// Default: `""`
  final String input;

  /// Represents the type of notification.
  ///
  /// This determines the business context (e.g., trip, chat, transaction).
  final TappyType type;

  /// Indicates who sent or triggered the notification.
  ///
  /// This could be a server ID, username, or another service.
  final String from;

  /// Represents the intended recipient or target of the notification.
  ///
  /// This is useful in multi-tenant or targeted delivery scenarios.
  final String foreign;

  /// The payload or body of the notification.
  ///
  /// This is a generic object and can hold any model type relevant to the `type`.
  ///
  /// Default: `null`
  final Map<String, dynamic> data;

  /// {@macro notifier}
  Notifier({
    required this.type,
    required this.id,
    required this.data,
    this.action = "",
    this.input = "",
    required this.foreign,
    required this.from,
  });

  /// Creates a new instance of [Notifier] with optional property overrides.
  ///
  /// Useful for immutability and state updates:
  /// ```dart
  /// notifier = notifier.copyWith(action: "NEW_ACTION");
  /// ```
  /// 
  /// {@macro notifier}
  Notifier copyWith({
    TappyType? type,
    Map<String, dynamic>? data,
    int? id,
    String? action,
    String? input,
    String? from,
    String? foreign,
  }) {
    return Notifier(
      type: type ?? this.type,
      data: data ?? this.data,
      id: id ?? this.id,
      action: action ?? this.action,
      input: input ?? this.input,
      from: from ?? this.from,
      foreign: foreign ?? this.foreign,
    );
  }

  /// Creates a [Notifier] instance from a JSON object.
  ///
  /// Expects a valid map containing required fields. Falls back to defaults if not present.
  /// 
  /// {@macro notifier}
  factory Notifier.fromJson(Map<String, dynamic> json) => Notifier(
    id: json["id"] ?? -1,
    type: TappyType.fromString(json["type"] ?? ""),
    data: json["data"],
    action: json["action"] ?? "",
    input: json["input"] ?? "",
    from: json["from"] ?? "",
    foreign: json["foreign"] ?? "",
  );

  /// Creates an empty [Notifier] instance with default values.
  ///
  /// Useful for initializing variables or representing no-notification states.
  /// 
  /// {@macro notifier}
  factory Notifier.empty() => Notifier(
    id: -1,
    type: TappyType.OTHERS,
    data: {},
    action: "",
    input: "",
    from: "",
    foreign: "",
  );

  /// Parses a JSON string to create a [Notifier] instance.
  ///
  /// Equivalent to decoding and passing through [Notifier.fromJson].
  /// 
  /// {@macro notifier}
  factory Notifier.fromString(String source) {
    Map<String, dynamic> json = jsonDecode(source);
    return Notifier.fromJson(json);
  }

  /// Converts the [Notifier] instance into a JSON object.
  ///
  /// Useful for serialization before sending over network or storing locally.
  /// 
  /// {@macro notifier}
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type.getType(),
      "data": data,
      "action": action,
      "input": input,
      "from": from,
      "foreign": foreign,
    };
  }

  /// Converts the [Notifier] instance to a JSON string.
  ///
  /// Uses [toJson] internally and `jsonEncode`.
  @override
  String toString() => jsonEncode(toJson());

  /// Returns `true` if the notification has a non-empty `action`.
  ///
  /// Useful for determining if further handling logic is necessary.
  bool get hasAction => action.isNotEmpty;
}