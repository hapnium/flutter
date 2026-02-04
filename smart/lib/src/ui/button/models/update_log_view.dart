import 'package:hapnium/hapnium.dart';

/// {@template update_log_view}
/// Represents an entry in an update log.
/// {@endtemplate}
final class UpdateLogView<ButtonKey extends Object> with EqualsAndHashCode, ToString {
  /// Unique identifier for the object.
  final ButtonKey? key;

  /// The title or header of the update.
  final String header;

  /// The content list describing the update details.
  final StringCollection content;

  /// The date of the update.
  final String date;

  /// The index of the update in a list.
  final Integer index;

  UpdateLogView({
    this.key,
    required this.header,
    required this.content,
    required this.date,
    required this.index,
  });

  UpdateLogView copyWith({
    ButtonKey? Function()? key,
    String? header,
    StringCollection? content,
    String? date,
    Integer? index,
  }) {
    return UpdateLogView(
      key: key != null ? key() : this.key,
      header: header ?? this.header,
      content: content ?? this.content,
      date: date ?? this.date,
      index: index ?? this.index,
    );
  }

  @override
  List<Object?> equalizedProperties() => [key, header, content, date, index];
}