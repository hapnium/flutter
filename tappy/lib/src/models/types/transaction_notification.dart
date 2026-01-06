import 'dart:convert';

import '../../exception/tappy_exception.dart';

/// {@template transaction_data}
/// Represents the details of a financial or operational transaction.
///
/// This model is used to capture and transfer transaction-related metadata
/// such as the transaction ID, type (mode), reference info, and timestamps.
///
/// ### Example usage:
/// ```dart
/// final transaction = TransactionData(
///   id: "txn_123",
///   name: "Payment Received",
///   header: "Completed",
///   description: "Received from John Doe for invoice INV-0092",
///   reference: "REF20240601",
///   mode: "Bank Transfer",
///   date: "2025-06-23",
///   updatedAt: "2025-06-23T10:15:30Z",
/// );
///
/// print("Transaction ${transaction.name} on ${transaction.date}");
/// ```
/// {@endtemplate}
class TransactionData {
  /// Unique identifier for the transaction.
  ///
  /// Default: `""`
  final String id;

  /// Title or label representing the transaction (e.g., "Payment Received").
  ///
  /// Default: `""`
  final String name;

  /// Header or status of the transaction, typically used for display purposes.
  ///
  /// Default: `""`
  final String header;

  /// A detailed explanation of the transaction's purpose or contents.
  ///
  /// Default: `""`
  final String description;

  /// A reference string to correlate this transaction with external systems.
  ///
  /// Default: `""`
  final String reference;

  /// Mode through which the transaction was performed (e.g., "Bank Transfer", "Cash").
  ///
  /// Default: `""`
  final String mode;

  /// Date of the transaction as a formatted string.
  ///
  /// Default: `""`
  final String date;

  /// Last updated timestamp of the transaction record (ISO 8601 format).
  ///
  /// Default: `""`
  final String updatedAt;

  /// {@macro transaction_data}
  TransactionData({
    required this.id,
    required this.name,
    required this.header,
    required this.description,
    required this.reference,
    required this.mode,
    required this.date,
    required this.updatedAt,
  });

  /// Creates a new [TransactionData] from a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final transaction = TransactionData.fromJson({
  ///   "id": "txn_123",
  ///   "name": "Payment Received",
  ///   "header": "Completed",
  ///   "description": "Received from John Doe for invoice INV-0092",
  ///   "reference": "REF20240601",
  ///   "mode": "Bank Transfer",
  ///   "date": "2025-06-23",
  ///   "updated_at": "2025-06-23T10:15:30Z",
  /// });
  /// ```
  /// 
  /// {@macro transaction_data}
  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      header: json["header"] ?? "",
      description: json["description"] ?? "",
      reference: json["reference"] ?? "",
      mode: json["mode"] ?? "",
      date: json["date"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }

  /// Converts the [TransactionData] instance into a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final transaction = TransactionData(
  ///   id: "txn_123",
  ///   name: "Payment Received",
  ///   header: "Completed",
  ///   description: "Received from John Doe for invoice INV-0092",
  ///   reference: "REF20240601",
  ///   mode: "Bank Transfer",
  ///   date: "2025-06-23",
  ///   updatedAt: "2025-06-23T10:15:30Z",
  /// );
  /// final json = transaction.toJson();
  /// ```
  /// 
  /// {@macro transaction_data}
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "header": header,
    "description": description,
    "reference": reference,
    "mode": mode,
    "date": date,
    "updated_at": updatedAt,
  };

  /// Returns a new copy of the [TransactionData] with updated fields.
  /// 
  /// ### Example:
  /// ```dart
  /// final transaction = TransactionData(
  ///   id: "txn_123",
  ///   name: "Payment Received",
  ///   header: "Completed",
  ///   description: "Received from John Doe for invoice INV-0092",
  ///   reference: "REF20240601",
  ///   mode: "Bank Transfer",
  ///   date: "2025-06-23",
  ///   updatedAt: "2025-06-23T10:15:30Z",
  /// );
  /// final updatedTransaction = transaction.copyWith(
  ///   name: "Payment Received",
  /// );
  /// ```
  /// 
  /// {@macro transaction_data}
  TransactionData copyWith({
    String? id,
    String? name,
    String? header,
    String? description,
    String? reference,
    String? mode,
    String? date,
    String? updatedAt,
  }) {
    return TransactionData(
      id: id ?? this.id,
      name: name ?? this.name,
      header: header ?? this.header,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      mode: mode ?? this.mode,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// {@template transaction_profile_data}
/// Contains profile-related metadata tied to a transaction or user activity.
///
/// This model holds information useful for displaying a profile preview in transaction
/// history or logs, such as the name, category of service, profile picture, and rating.
///
/// ### Example usage:
/// ```dart
/// final profile = TransactionProfileData(
///   name: "John Doe",
///   category: "Plumber",
///   rating: 4.7,
///   avatar: "https://example.com/avatar.jpg",
///   image: "https://example.com/work_image.jpg",
/// );
///
/// print("Service provided by ${profile.name} with rating ${profile.rating}");
/// ```
/// {@endtemplate}
class TransactionProfileData {
  /// Full name of the service provider or user.
  ///
  /// Default: `""`
  final String name;

  /// Category of the service or role (e.g., "Electrician", "Cleaner").
  ///
  /// Default: `""`
  final String category;

  /// Star rating given to this profile (typically between 0.0 and 5.0).
  ///
  /// Default: `0.0`
  final double rating;

  /// URL or identifier of the avatar image.
  ///
  /// Default: `""`
  final String avatar;

  /// URL to an image that may represent the service or user’s work.
  ///
  /// Default: `""`
  final String image;

  /// {@macro transaction_profile_data}
  TransactionProfileData({
    required this.name,
    required this.category,
    required this.rating,
    required this.avatar,
    required this.image,
  });

  /// Creates a new instance of [TransactionProfileData] from a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final profile = TransactionProfileData.fromJson({
  ///   "name": "John Doe",
  ///   "category": "Plumber",
  ///   "rating": 4.7,
  ///   "avatar": "https://example.com/avatar.jpg",
  ///   "image": "https://example.com/work_image.jpg",
  /// });
  /// ```
  /// 
  /// {@macro transaction_profile_data}
  factory TransactionProfileData.fromJson(Map<String, dynamic> json) {
    return TransactionProfileData(
      name: json["name"] ?? "",
      category: json["category"] ?? "",
      rating: json["rating"] ?? 0.0,
      avatar: json["avatar"] ?? "",
      image: json["image"] ?? "",
    );
  }

  /// Converts the [TransactionProfileData] instance into a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final profile = TransactionProfileData(
  ///   name: "John Doe",
  ///   category: "Plumber",
  ///   rating: 4.7,
  ///   avatar: "https://example.com/avatar.jpg",
  ///   image: "https://example.com/work_image.jpg",
  /// );
  /// final json = profile.toJson();
  /// ```
  /// 
  /// {@macro transaction_profile_data}
  Map<String, dynamic> toJson() => {
    "name": name,
    "category": category,
    "rating": rating,
    "avatar": avatar,
    "image": image,
  };

  /// Returns a copy of this [TransactionProfileData] with optional new values.
  /// 
  /// ### Example:
  /// ```dart
  /// final profile = TransactionProfileData(
  ///   name: "John Doe",
  ///   category: "Plumber",
  ///   rating: 4.7,
  ///   avatar: "https://example.com/avatar.jpg",
  ///   image: "https://example.com/work_image.jpg",
  /// );
  /// final updatedProfile = profile.copyWith(
  ///   name: "John Doe",
  /// );
  /// ```
  /// 
  /// {@macro transaction_profile_data}
  TransactionProfileData copyWith({
    String? name,
    String? category,
    double? rating,
    String? avatar,
    String? image,
  }) {
    return TransactionProfileData(
      name: name ?? this.name,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      avatar: avatar ?? this.avatar,
      image: image ?? this.image,
    );
  }
}

/// {@template transaction}
/// A model representing a single financial or service-related transaction.
///
/// Inherits from [TransactionResponse] and includes key details like the recipient,
/// transaction amount, status, type, and embedded metadata such as [TransactionData]
/// and optional associated profile information [TransactionProfileData].
///
/// This model is useful for displaying transaction history, sending or receiving
/// transaction data, and generating user-facing summaries or analytics.
///
/// ### Example usage:
/// ```dart
/// final tx = Transaction(
///   recipient: "Jane Doe",
///   amount: "₦5000",
///   label: "Service Payment",
///   status: "COMPLETED",
///   type: "payment",
///   data: TransactionData.fromJson(rawData),
///   associate: TransactionProfileData.fromJson(profile),
///   isIncoming: true,
/// );
///
/// print("Received ${tx.amount} from ${tx.recipient}");
/// ```
/// {@endtemplate}
class Transaction extends TransactionResponse {
  /// Recipient's name or identifier for the transaction.
  ///
  /// Default: `""`
  final String recipient;

  /// Amount involved in the transaction (e.g., "₦5000").
  ///
  /// Default: `""`
  final String amount;

  /// Descriptive label for the transaction (e.g., "Payment for repairs").
  ///
  /// Default: `""`
  final String label;

  /// Status of the transaction (e.g., "PENDING", "COMPLETED").
  ///
  /// Default: `""`
  final String status;

  /// Type of transaction (e.g., "payment", "refund").
  ///
  /// Default: `""`
  final String type;

  /// Contains additional metadata about the transaction.
  final TransactionData data;

  /// Optional profile information of the person or business associated with the transaction.
  ///
  /// Default: `null`
  final TransactionProfileData? associate;

  /// Indicates whether the transaction is incoming (`true`) or outgoing (`false`).
  ///
  /// Default: `false`
  final bool isIncoming;

  /// {@macro transaction}
  Transaction({
    required this.recipient,
    required this.amount,
    required this.label,
    required this.status,
    required this.type,
    required this.data,
    required this.associate,
    required this.isIncoming,
  }) : super(TransactionDataType.transaction);

  /// Returns a new instance of [Transaction] with optional updated fields.
  /// 
  /// ### Example:
  /// ```dart
  /// final tx = Transaction(
  ///   recipient: "Jane Doe",
  ///   amount: "₦5000",
  ///   label: "Service Payment",
  ///   status: "COMPLETED",
  ///   type: "payment",
  ///   data: TransactionData.fromJson(rawData),
  ///   associate: TransactionProfileData.fromJson(profile),
  ///   isIncoming: true,
  /// );
  /// 
  /// final updatedTx = tx.copyWith(
  ///   amount: "₦6000",
  /// );
  /// ```
  /// 
  /// {@macro transaction}
  Transaction copyWith({
    String? recipient,
    String? amount,
    String? label,
    String? status,
    String? type,
    TransactionData? data,
    TransactionProfileData? associate,
    bool? isIncoming,
  }) {
    return Transaction(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      label: label ?? this.label,
      status: status ?? this.status,
      type: type ?? this.type,
      data: data ?? this.data,
      associate: associate ?? this.associate,
      isIncoming: isIncoming ?? this.isIncoming,
    );
  }

  /// Creates a [Transaction] object from a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final tx = Transaction.fromJson(json);
  /// ```
  /// 
  /// {@macro transaction}
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      recipient: json["recipient"] ?? "",
      amount: json["amount"] ?? "",
      label: json["label"] ?? "",
      status: json["status"] ?? "",
      type: json["type"] ?? "",
      data: TransactionData.fromJson(json["data"]),
      associate: json["associate"] == null
          ? null
          : TransactionProfileData.fromJson(json["associate"]),
      isIncoming: json["is_incoming"] ?? false,
    );
  }

  /// Converts this [Transaction] into a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final tx = Transaction(
  ///   recipient: "Jane Doe",
  ///   amount: "₦5000",
  ///   label: "Service Payment",
  ///   status: "COMPLETED",
  ///   type: "payment",
  ///   data: TransactionData.fromJson(rawData),
  ///   associate: TransactionProfileData.fromJson(profile),
  ///   isIncoming: true,
  /// );
  /// 
  /// final json = tx.toJson();
  /// ```
  /// 
  /// {@macro transaction}
  @override
  Map<String, dynamic> toJson() => {
    "recipient": recipient,
    "amount": amount,
    "label": label,
    "status": status,
    "type": type,
    "data": data.toJson(),
    "associate": associate?.toJson(),
    "is_incoming": isIncoming,
  };

  /// Serializes this [Transaction] object into a JSON string.
  @override
  String toString() => jsonEncode(toJson());

  /// Parses a JSON string and returns a [Transaction] instance.
  /// 
  /// ### Example:
  /// ```dart
  /// final tx = Transaction.fromString(json);
  /// ```
  /// 
  /// {@macro transaction}
  @override
  Transaction fromString(String source) => Transaction.fromJson(jsonDecode(source));
}

/// Represents the type of transaction data, either a full transaction or a notification.
enum TransactionDataType { notification, transaction }

/// {@template transaction_response}
/// An abstract base class representing a server response that includes transaction data.
///
/// This can represent either a full [Transaction] or a [TransactionNotification].
/// It provides unified access to common functionality like JSON serialization and
/// helper accessors to differentiate and cast the response safely.
///
/// Useful in scenarios where transactions and transaction-related notifications are
/// handled using the same interface, such as in timeline views or unified API responses.
///
/// ### Example usage:
/// ```dart
/// final response = TransactionResponse.fromJson(responseJson);
/// if (response.isTransaction) {
///   print("Amount: ${response.transaction.amount}");
/// } else if (response.isNotification) {
///   print("Notification: ${response.notification.message}");
/// }
/// ```
/// {@endtemplate}
abstract class TransactionResponse {
  /// The type of transaction response.
  ///
  /// Can be either [TransactionDataType.transaction] or [TransactionDataType.notification].
  final TransactionDataType dataType;

  /// {@macro transaction_response}
  TransactionResponse(this.dataType);

  /// Creates a [TransactionResponse] from a JSON map.
  ///
  /// Automatically determines whether the data represents a [TransactionNotification]
  /// or a [Transaction] based on the presence of known keys.
  /// 
  /// ### Example:
  /// ```dart
  /// final response = TransactionResponse.fromJson(responseJson);
  /// ```
  /// 
  /// {@macro transaction_response}
  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("id") &&
        json.containsKey("sender_name") &&
        json.containsKey("sender_id")) {
      return TransactionNotification.fromJson(json);
    } else {
      return Transaction.fromJson(json);
    }
  }

  /// Whether this response is a [TransactionNotification].
  bool get isNotification => dataType == TransactionDataType.notification;

  /// Whether this response is a [Transaction].
  bool get isTransaction => dataType == TransactionDataType.transaction;

  /// Casts this response to a [TransactionNotification].
  ///
  /// Throws [TappyException] if this is not a notification type.
  TransactionNotification get notification => isNotification
      ? this as TransactionNotification
      : throw TappyException("This is not a TransactionNotification data");

  /// Casts this response to a [Transaction].
  ///
  /// Throws [TappyException] if this is not a transaction type.
  Transaction get transaction => isTransaction
      ? this as Transaction
      : throw TappyException("This is not a Transaction data");

  /// Returns the foreign identifier:
  /// - [TransactionNotification.id] if this is a notification.
  /// - [Transaction.data.id] if this is a full transaction.
  String get foreign => isNotification ? notification.id : transaction.data.id;

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() => isNotification ? notification.toJson() : transaction.toJson();

  /// Converts this response to a JSON string.
  @override
  String toString() => jsonEncode(toJson());

  /// Parses a JSON string and returns a [TransactionResponse].
  /// 
  /// ### Example:
  /// ```dart
  /// final response = TransactionResponse.fromString(json);
  /// ```
  /// 
  /// {@macro transaction_response}
  TransactionResponse fromString(String source) => TransactionResponse.fromJson(jsonDecode(source));
}

/// {@template transaction_notification}
/// A notification model representing a transaction-related event or alert.
///
/// This is a lightweight alternative to a full [Transaction], typically used
/// to inform the user of an incoming or completed transaction without
/// exposing all details.
///
/// Extends [TransactionResponse] and is distinguished by
/// [TransactionDataType.notification].
///
/// ### Example usage:
/// ```dart
/// final notification = TransactionNotification.fromJson(json);
/// print(notification.senderName);
/// ```
/// {@endtemplate}
class TransactionNotification extends TransactionResponse {
  /// Unique identifier for this notification.
  final String id;

  /// Name of the sender associated with this transaction notification.
  final String senderName;

  /// Identifier of the sender.
  final String senderId;

  /// {@macro transaction_notification}
  TransactionNotification({
    required this.id,
    required this.senderName,
    required this.senderId,
  }) : super(TransactionDataType.notification);

  /// Creates a [TransactionNotification] from a JSON map.
  /// 
  /// ### Example:
  /// ```dart
  /// final notification = TransactionNotification.fromJson(json);
  /// ```
  /// 
  /// {@macro transaction_notification}
  factory TransactionNotification.fromJson(Map<String, dynamic> json) {
    return TransactionNotification(
      id: json["id"] ?? "",
      senderName: json['sender_name'] ?? '',
      senderId: json['sender_id'] ?? '',
    );
  }

  /// Converts this [TransactionNotification] into a JSON map.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'sender_id': senderId,
    };
  }

  /// Creates a copy of this [TransactionNotification] with optionally updated fields.
  /// 
  /// ### Example:
  /// ```dart
  /// final notification = TransactionNotification.copyWith(id: "new_id");
  /// ```
  /// 
  /// {@macro transaction_notification}
  TransactionNotification copyWith({
    String? id,
    String? senderName,
    String? senderId,
  }) {
    return TransactionNotification(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderId: senderId ?? this.senderId,
    );
  }

  /// Converts this notification into a JSON string.
  @override
  String toString() => jsonEncode(toJson());

  /// Parses a JSON string into a [TransactionNotification].
  /// 
  /// ### Example:
  /// ```dart
  /// final notification = TransactionNotification.fromString(json);
  /// ```
  /// 
  /// {@macro transaction_notification}
  @override
  TransactionNotification fromString(String source) => TransactionNotification.fromJson(jsonDecode(source));
}