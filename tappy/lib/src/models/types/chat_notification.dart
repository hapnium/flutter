import 'dart:convert';

import '../../exception/tappy_exception.dart';
import 'schedule_notification.dart';

/// Enum representing possible data types within a chat response.
enum ChatDataType { notification, room }

/// {@template chat_response}
/// A sealed class representing a union of chat-related data responses.
///
/// A `ChatResponse` can either be a [ChatNotification] or a [ChatRoom], and exposes
/// unified methods and properties to access common information like room ID, summary,
/// name, and foreign identifier.  
///
/// This pattern allows consumers to work with a generic response type without tightly coupling
/// UI or logic layers to specific data models.
///
/// The `ChatResponse.fromJson` factory automatically determines which type to instantiate.
///
/// ### Example:
/// ```dart
/// final response = ChatResponse.fromJson(rawData);
/// if (response.isNotification) {
///   print("Notification: ${response.notification.summary}");
/// } else if (response.isRoom) {
///   print("Room message: ${response.chatRoom.summary}");
/// }
/// ```
/// {@endtemplate}
abstract class ChatResponse {
  /// {@macro chat_response}
  ChatResponse(this.dataType);

  /// The internal type of the response, either [ChatDataType.notification] or [ChatDataType.room].
  final ChatDataType dataType;

  /// Factory constructor that returns a [ChatNotification] or [ChatRoom]
  /// based on the structure of the JSON payload.
  ///
  /// If the JSON contains `"e_pub_key"` and `"id"`, it is interpreted as a `ChatNotification`,
  /// otherwise it is assumed to be a `ChatRoom`.
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("e_pub_key") && json.containsKey("id")) {
      return ChatNotification.fromJson(json);
    } else {
      return ChatRoom.fromJson(json);
    }
  }

  /// Returns true if this response is of type [ChatNotification].
  bool get isNotification => dataType == ChatDataType.notification;

  /// Returns true if this response is of type [ChatRoom].
  bool get isRoom => dataType == ChatDataType.room;

  /// Casts this response to [ChatNotification], or throws if it is not.
  ///
  /// Throws a [TappyException] if the current type is not `notification`.
  ChatNotification get notification => isNotification
      ? this as ChatNotification
      : throw TappyException("This is not a notification response");

  /// Casts this response to [ChatRoom], or throws if it is not.
  ///
  /// Throws a [TappyException] if the current type is not `room`.
  ChatRoom get chatRoom => isRoom
      ? this as ChatRoom
      : throw TappyException("This is not a room response");

  /// A foreign identifier tied to the message.
  ///
  /// For [ChatNotification], this is the `id`.
  /// For [ChatRoom], this is the `messageId`.
  String get foreign => isNotification ? notification.id : chatRoom.messageId;

  /// A human-readable summary of the response.
  ///
  /// Can be used in lists, previews, or notifications.
  String get summary => isNotification ? notification.summary : chatRoom.summary;

  /// The room ID the message or notification belongs to.
  String get room => isNotification ? notification.room : chatRoom.room;

  /// The name of the sender or participant in the conversation.
  String get name => isNotification ? notification.name : chatRoom.name;

  /// Serializes the response back to a JSON-compatible map.
  Map<String, dynamic> toJson() => isNotification ? notification.toJson() : chatRoom.toJson();

  /// Encodes the response to a JSON string.
  @override
  String toString() => jsonEncode(toJson());

  /// Reconstructs a [ChatResponse] from a JSON string.
  ChatResponse fromString(String source) => ChatResponse.fromJson(jsonDecode(source));
}

/// {@template chat_group_message}
/// A model representing a grouped collection of chat messages with shared metadata.
///
/// Typically used for organizing chat messages by date, label, or grouping logic
/// (e.g., "Today", "Yesterday", or by custom tags).
///
/// Each `ChatGroupMessage` holds:
/// - a `label` for categorization,
/// - a `time` indicating the grouping moment (e.g., the start of the day),
/// - and a list of associated `ChatMessage` objects.
///
/// ### Example:
/// ```dart
/// final group = ChatGroupMessage(
///   label: "Today",
///   time: DateTime.now(),
///   messages: [
///     ChatMessage(sender: "Alice", message: "Hi!", timestamp: DateTime.now()),
///   ],
/// );
/// ```
/// {@endtemplate}
class ChatGroupMessage {
  /// {@macro chat_group_message}
  ChatGroupMessage({
    required this.label,
    required this.time,
    required this.messages,
  });

  /// A user-friendly label to describe the group of messages.
  ///
  /// Often used to represent days (e.g., "Today", "Yesterday") or other categorizations.
  ///
  /// Default: `""` (empty string if parsed from JSON without label)
  final String label;

  /// The reference timestamp for the group.
  ///
  /// This is typically the date/time used to group messages (e.g., midnight of the day).
  ///
  /// Default: `DateTime.now()` if not parsable from JSON.
  final DateTime time;

  /// The list of chat messages that belong to this group.
  ///
  /// Messages with an empty `message` string are filtered out when created from JSON.
  ///
  /// Default: `[]` if not present in JSON.
  final List<ChatMessage> messages;

  /// Creates a copy of this group with optional property overrides.
  ///
  /// Useful for immutable state updates.
  /// 
  /// {@macro chat_group_message}
  ChatGroupMessage copyWith({
    String? label,
    DateTime? time,
    List<ChatMessage>? messages,
  }) {
    return ChatGroupMessage(
      label: label ?? this.label,
      time: time ?? this.time,
      messages: messages ?? this.messages,
    );
  }

  /// Creates a `ChatGroupMessage` instance from a JSON map.
  ///
  /// Automatically filters out messages with empty content.
  /// 
  /// {@macro chat_group_message}
  factory ChatGroupMessage.fromJson(Map<String, dynamic> json) {
    List<ChatMessage> messages = json["messages"] == null
        ? []
        : List<ChatMessage>.from(json["messages"]!.map((x) => ChatMessage.fromJson(x)));

    if (messages.isNotEmpty) {
      messages.removeWhere((message) => message.message.isEmpty);
    }

    return ChatGroupMessage(
      label: json["label"] ?? "",
      time: DateTime.tryParse(json["time"] ?? "") ?? DateTime.now(),
      messages: messages,
    );
  }

  /// Converts the `ChatGroupMessage` to a JSON-compatible map.
  /// 
  /// {@macro chat_group_message}
  Map<String, dynamic> toJson() => {
    "label": label,
    "time": time.toIso8601String(),
    "messages": messages.map((x) => x.toJson()).toList(),
  };
}

/// {@template chat_reply}
/// A model representing a reply reference to a previously sent or received chat message.
///
/// This is typically used in message reply UIs to show a preview of the original message
/// that is being replied to, including its content, sender, and additional metadata.
///
/// It encapsulates information such as the original message content, file metadata,
/// sender identity, and whether the original message was sent by the current user.
///
/// ### Example:
/// ```dart
/// final reply = ChatReply(
///   id: "msg-123",
///   label: "Alice",
///   message: "See you soon!",
///   status: "sent",
///   fileSize: "2 MB",
///   type: "text",
///   sender: "Alice",
///   duration: "00:15",
///   isSentByCurrentUser: false,
/// );
/// ```
/// {@endtemplate}
class ChatReply {
  /// {@macro chat_reply}
  ChatReply({
    required this.id,
    required this.label,
    required this.message,
    required this.status,
    required this.fileSize,
    required this.type,
    required this.sender,
    required this.duration,
    required this.isSentByCurrentUser,
  });

  /// The unique ID of the original message.
  ///
  /// Default: `""` if not present in JSON.
  final String id;

  /// A display label, often the sender’s name or message title.
  ///
  /// Default: `""`
  final String label;

  /// The actual message content being replied to.
  ///
  /// Could be text, filename, or file description depending on the type.
  ///
  /// Default: `""`
  final String message;

  /// The delivery or read status of the original message (e.g., sent, delivered, read).
  ///
  /// Default: `""`
  final String status;

  /// The size of any attached file in the original message.
  ///
  /// Applies only if `type` is media-related.
  ///
  /// Default: `""`
  final String fileSize;

  /// The type of the original message (e.g., text, image, video, audio, file).
  ///
  /// Used to determine the kind of reply preview shown.
  ///
  /// Default: `""`
  final String type;

  /// The user ID or name of the original message's sender.
  ///
  /// Default: `""`
  final String sender;

  /// Duration of audio/video message (e.g., `00:30`), if applicable.
  ///
  /// Default: `""`
  final String duration;

  /// Whether the original message was sent by the current user.
  ///
  /// Used for styling or behavioral differences in the UI.
  ///
  /// Default: `false`
  final bool isSentByCurrentUser;

  /// Creates a copy of this `ChatReply` with overridden properties.
  ///
  /// Useful for immutability and state updates.
  /// 
  /// {@macro chat_reply}
  ChatReply copyWith({
    String? id,
    String? label,
    String? message,
    String? status,
    String? fileSize,
    String? duration,
    String? type,
    String? sender,
    bool? isSentByCurrentUser,
  }) {
    return ChatReply(
      id: id ?? this.id,
      label: label ?? this.label,
      message: message ?? this.message,
      status: status ?? this.status,
      fileSize: fileSize ?? this.fileSize,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      isSentByCurrentUser: isSentByCurrentUser ?? this.isSentByCurrentUser,
    );
  }

  /// Creates a `ChatReply` from a JSON map.
  ///
  /// Fields not present in the JSON are assigned default values.
  /// 
  /// {@macro chat_reply}
  factory ChatReply.fromJson(Map<String, dynamic> json) {
    return ChatReply(
      id: json["id"] ?? "",
      label: json["label"] ?? "",
      message: json["message"] ?? "",
      status: json["status"] ?? "",
      fileSize: json["file_size"] ?? "",
      type: json["type"] ?? "",
      sender: json["sender"] ?? "",
      duration: json["duration"] ?? "",
      isSentByCurrentUser: json["is_sent_by_current_user"] ?? false,
    );
  }

  /// Converts this `ChatReply` into a JSON-compatible map.
  /// 
  /// {@macro chat_reply}
  Map<String, dynamic> toJson() => {
    "id": id,
    "label": label,
    "message": message,
    "status": status,
    "file_size": fileSize,
    "type": type,
    "duration": duration,
    "sender": sender,
    "is_sent_by_current_user": isSentByCurrentUser,
  };
}

/// {@template chat_message}
/// A data model representing a single message in a chat conversation.
///
/// This class is commonly used to structure individual messages sent or
/// received within a chat room. It supports metadata such as replies,
/// message type, file attachments, and sender context.
///
/// Example usage:
///
/// ```dart
/// final message = ChatMessage(
///   id: "msg-123",
///   label: "Info",
///   room: "room-1",
///   message: "Hello, world!",
///   status: "sent",
///   type: "text",
///   duration: "",
///   reply: null,
///   fileSize: "",
///   isSentByCurrentUser: true,
///   sentAt: DateTime.now(),
///   name: "John Doe",
/// );
/// ```
///
/// Use [ChatMessage.fromJson] to deserialize JSON into a message object,
/// or [toJson] to serialize it for transmission or storage.
/// {@endtemplate}
class ChatMessage {
  /// The unique identifier for this message.
  ///
  /// Default: `""`
  final String id;

  /// A custom or system-defined label for the message (e.g., "urgent", "note").
  ///
  /// Default: `""`
  final String label;

  /// The room or group ID this message belongs to.
  ///
  /// Default: `""`
  final String room;

  /// The actual message content (e.g., text, URL, etc).
  ///
  /// Default: `""`
  final String message;

  /// The status of the message (e.g., "sent", "delivered", "read").
  ///
  /// Default: `""`
  final String status;

  /// The type of the message (e.g., "text", "audio", "image").
  ///
  /// Default: `""`
  final String type;

  /// The duration of the media file, if applicable (e.g., for audio or video).
  ///
  /// Default: `""`
  final String duration;

  /// An optional reply message that this message is responding to.
  ///
  /// Default: `null`
  final ChatReply? reply;

  /// The file size of any attachment in the message.
  ///
  /// Default: `""`
  final String fileSize;

  /// Whether this message was sent by the current user.
  ///
  /// Default: `false`
  final bool isSentByCurrentUser;

  /// The timestamp of when this message was sent.
  ///
  /// Default: `DateTime.now()` if parsing fails.
  final DateTime sentAt;

  /// The display name of the sender of this message.
  ///
  /// Default: `""`
  final String name;

  /// {@macro chat_message}
  ChatMessage({
    required this.id,
    required this.label,
    required this.room,
    required this.message,
    required this.status,
    required this.type,
    required this.duration,
    required this.reply,
    required this.fileSize,
    required this.isSentByCurrentUser,
    required this.sentAt,
    required this.name,
  });

  /// Returns a new [ChatMessage] instance with modified fields.
  /// 
  /// {@macro chat_message}
  ChatMessage copyWith({
    String? id,
    String? label,
    String? room,
    String? message,
    String? status,
    String? type,
    String? duration,
    ChatReply? reply,
    String? fileSize,
    bool? isSentByCurrentUser,
    DateTime? sentAt,
    String? name,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      label: label ?? this.label,
      room: room ?? this.room,
      message: message ?? this.message,
      status: status ?? this.status,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      reply: reply ?? this.reply,
      fileSize: fileSize ?? this.fileSize,
      isSentByCurrentUser: isSentByCurrentUser ?? this.isSentByCurrentUser,
      sentAt: sentAt ?? this.sentAt,
      name: name ?? this.name,
    );
  }

  /// Creates a [ChatMessage] instance from a JSON map.
  /// 
  /// {@macro chat_message}
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json["id"] ?? "",
      label: json["label"] ?? "",
      room: json["room"] ?? "",
      message: json['message'] ?? "",
      name: json["name"] ?? "",
      status: json["status"] ?? "",
      type: json["type"] ?? "",
      duration: json["duration"] ?? "",
      reply: json["reply"] == null ? null : ChatReply.fromJson(json["reply"]),
      fileSize: json["file_size"] ?? "",
      isSentByCurrentUser: json["is_sent_by_current_user"] ?? false,
      sentAt: DateTime.tryParse(json["sent_at"] ?? "") ?? DateTime.now(),
    );
  }

  /// Converts the [ChatMessage] to a JSON-compatible map.
  /// 
  /// {@macro chat_message}
  Map<String, dynamic> toJson() => {
    "id": id,
    "label": label,
    "room": room,
    "message": message,
    "name": name,
    "status": status,
    "type": type,
    "duration": duration,
    "reply": reply?.toJson(),
    "file_size": fileSize,
    "is_sent_by_current_user": isSentByCurrentUser,
    "sent_at": sentAt.toIso8601String(),
  };
}

/// {@template chat_room}
/// A concrete implementation of [ChatResponse] representing a room-based chat.
///
/// This class encapsulates metadata and content relevant to a chat room, such as
/// messages, participants, timestamps, encryption keys, and visual attributes.
///
/// It also supports optional scheduling, bookmarking, and grouping features.
/// {@endtemplate}
class ChatRoom extends ChatResponse {
  /// {@macro chat_room}
  ChatRoom({
    required this.room,
    required this.roommate,
    required this.name,
    required this.avatar,
    required this.category,
    required this.image,
    required this.label,
    required this.message,
    required this.messageId,
    required this.status,
    required this.count,
    required this.groups,
    required this.lastSeen,
    required this.sentAt,
    required this.isBookmarked,
    required this.bookmark,
    required this.schedule,
    required this.isActive,
    required this.trip,
    this.isBookmarking = false,
    required this.total,
    required this.publicEncryptionKey,
    required this.type,
    required this.summary,
  }) : super(ChatDataType.room);

  /// The unique identifier of the chat room.
  @override
  final String room;

  /// ID of the user associated with this chat.
  final String roommate;

  /// Name of the participant or chat room.
  @override
  final String name;

  /// Avatar URL or path.
  final String avatar;

  /// Category label for the chat room (e.g., "support", "social").
  final String category;

  /// Image used as a cover or thumbnail.
  final String image;

  /// Custom label or tag.
  final String label;

  /// Latest message in the conversation.
  final String message;

  /// Unique message identifier.
  final String messageId;

  /// Status of the last message (e.g., "read", "sent").
  final String status;

  /// Number of unread messages.
  final int count;

  /// Grouped messages by date or context.
  final List<ChatGroupMessage> groups;

  /// The last time the user interacted with the room, in string format.
  final String lastSeen;

  /// Time the last message was sent.
  final DateTime sentAt;

  /// Whether the room is currently bookmarked.
  final bool isBookmarked;

  /// Bookmark identifier or metadata.
  final String bookmark;

  /// Optional scheduled notification for this chat.
  final ScheduleNotification? schedule;

  /// Whether the room is actively open or participating in real-time.
  final bool isActive;

  /// Optional trip or contextual tag.
  final String trip;

  /// Temporary UI flag to indicate bookmarking in progress.
  final bool isBookmarking;

  /// Total number of messages in this chat room.
  final int total;

  /// Public encryption key for secure communication.
  final String publicEncryptionKey;

  /// Data type of the message content (e.g., "text", "media").
  final String type;

  /// Shortened summary of the latest interaction.
  @override
  final String summary;

  /// Creates a modified copy of this [ChatRoom] with selectively overridden fields.
  /// 
  /// {@macro chat_room}
  ChatRoom copyWith({
    String? room,
    String? roommate,
    String? name,
    String? avatar,
    String? category,
    String? image,
    String? label,
    String? message,
    String? messageId,
    String? status,
    int? count,
    List<ChatGroupMessage>? groups,
    String? lastSeen,
    DateTime? sentAt,
    bool? isBookmarked,
    String? bookmark,
    ScheduleNotification? schedule,
    bool? isActive,
    String? trip,
    bool? isBookmarking,
    int? total,
    String? publicEncryptionKey,
    String? type,
    String? summary,
  }) {
    return ChatRoom(
      room: room ?? this.room,
      roommate: roommate ?? this.roommate,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      category: category ?? this.category,
      image: image ?? this.image,
      label: label ?? this.label,
      message: message ?? this.message,
      messageId: messageId ?? this.messageId,
      status: status ?? this.status,
      count: count ?? this.count,
      groups: groups ?? this.groups,
      lastSeen: lastSeen ?? this.lastSeen,
      sentAt: sentAt ?? this.sentAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      bookmark: bookmark ?? this.bookmark,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      trip: trip ?? this.trip,
      isBookmarking: isBookmarking ?? this.isBookmarking,
      total: total ?? this.total,
      publicEncryptionKey: publicEncryptionKey ?? this.publicEncryptionKey,
      type: type ?? this.type,
      summary: summary ?? this.summary,
    );
  }

  /// Deserializes a [ChatRoom] from JSON data.
  /// 
  /// {@macro chat_room}
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      room: json["room"] ?? "",
      roommate: json["roommate"] ?? "",
      name: json["name"] ?? "",
      avatar: json["avatar"] ?? "",
      category: json["category"] ?? "",
      image: json["image"] ?? "",
      label: json["label"] ?? "",
      message: json["message"] ?? "",
      messageId: json["message_id"] ?? "",
      status: json["status"] ?? "",
      bookmark: json["bookmark"] ?? "",
      schedule: json["schedule"] != null
          ? ScheduleNotification.fromJson(json["schedule"])
          : null,
      count: json["count"] ?? 0,
      groups: json["groups"] == null
          ? []
          : List<ChatGroupMessage>.from(json["groups"].map((x) => ChatGroupMessage.fromJson(x))),
      lastSeen: json["last_seen"] ?? "",
      sentAt: DateTime.tryParse(json["sent_at"] ?? "") ?? DateTime.now(),
      isBookmarked: json["is_bookmarked"] ?? false,
      isActive: json["is_active"] ?? false,
      trip: json["trip"] ?? "",
      isBookmarking: json["is_bookmarking"] ?? false,
      total: json["total"] ?? 0,
      publicEncryptionKey: json["public_encryption_key"] ?? "",
      type: json["type"] ?? "",
      summary: json["summary"] ?? "",
    );
  }

  /// Converts the object to a JSON-compatible map.
  /// 
  /// {@macro chat_room}
  @override
  Map<String, dynamic> toJson() => {
    "room": room,
    "roommate": roommate,
    "name": name,
    "avatar": avatar,
    "category": category,
    "image": image,
    "label": label,
    "message": message,
    "message_id": messageId,
    "bookmark": bookmark,
    "schedule": schedule?.toJson(),
    "status": status,
    "count": count,
    "groups": groups.map((x) => x.toJson()).toList(),
    "last_seen": lastSeen,
    "sent_at": sentAt.toIso8601String(),
    "is_bookmarked": isBookmarked,
    "is_active": isActive,
    "trip": trip,
    "is_bookmarking": isBookmarking,
    "total": total,
    "public_encryption_key": publicEncryptionKey,
    "type": type,
    "summary": summary,
  };

  /// Converts the object to a JSON string.
  /// 
  /// {@macro chat_room}
  @override
  String toString() => jsonEncode(toJson());

  /// Parses the object from a JSON string.
  /// 
  /// {@macro chat_room}
  @override
  ChatRoom fromString(String source) => ChatRoom.fromJson(jsonDecode(source));
}

/// {@template chat_notification}
/// A model representing a one-time or persistent chat notification,
/// part of the [ChatResponse] sealed union.
///
/// Notifications can be system-generated or user-related and often include
/// public encryption keys, user metadata, and a summary of the event.
/// {@endtemplate}
class ChatNotification extends ChatResponse {
  /// Unique ID of the roommate related to this notification.
  final String roommate;

  /// Notification ID, usually globally unique.
  final String id;

  /// Room or topic identifier that this notification belongs to.
  @override
  final String room;

  /// Encoded or signed notification token or timestamp.
  final String snt;

  /// Optional image associated with the notification.
  final String image;

  /// Category or type of the notification (e.g., "alert", "info").
  final String category;

  /// Brief summary of the notification content.
  @override
  final String summary;

  /// Public encryption key associated with the user or notification sender.
  final String ePubKey;

  /// Name of the sender or subject.
  @override
  final String name;

  /// {@macro chat_notification}
  ChatNotification({
    required this.roommate,
    required this.id,
    required this.room,
    required this.snt,
    required this.image,
    required this.category,
    required this.summary,
    required this.ePubKey,
    required this.name,
  }) : super(ChatDataType.notification);

  /// Creates a [ChatNotification] from a JSON map.
  /// 
  /// {@macro chat_notification}
  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      roommate: json['roommate'] ?? '',
      id: json['id'] ?? '',
      room: json['room'] ?? '',
      snt: json['snt'] ?? '',
      image: json['image'] ?? '',
      category: json['category'] ?? '',
      summary: json['summary'] ?? '',
      ePubKey: json['e_pub_key'] ?? '',
      name: json['name'] ?? '',
    );
  }

  /// Converts the object to a JSON-compatible map.
  /// 
  /// {@macro chat_notification}
  @override
  Map<String, dynamic> toJson() {
    return {
      'roommate': roommate,
      'id': id,
      'room': room,
      'snt': snt,
      'image': image,
      'category': category,
      'summary': summary,
      'e_pub_key': ePubKey,
      'name': name,
    };
  }

  /// Creates a modified copy of this [ChatNotification].
  /// 
  /// {@macro chat_notification}
  ChatNotification copyWith({
    String? roommate,
    String? id,
    String? room,
    String? snt,
    String? image,
    String? category,
    String? summary,
    String? ePubKey,
    String? name,
  }) {
    return ChatNotification(
      roommate: roommate ?? this.roommate,
      id: id ?? this.id,
      room: room ?? this.room,
      snt: snt ?? this.snt,
      image: image ?? this.image,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      ePubKey: ePubKey ?? this.ePubKey,
      name: name ?? this.name,
    );
  }

  /// Converts the object to a JSON string.
  /// 
  /// {@macro chat_notification}
  @override
  String toString() => jsonEncode(toJson());

  /// Parses the object from a JSON string.
  /// 
  /// {@macro chat_notification}
  @override
  ChatNotification fromString(String source) => ChatNotification.fromJson(jsonDecode(source));
}