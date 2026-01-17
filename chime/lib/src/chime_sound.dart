/// {@template chime_sound}
/// A value object representing a Chime notification sound name.
///
/// Use [ChimeSound] to reference known sound identifiers in a type-safe way.
/// It avoids string literals scattered across your code and provides a single
/// place to update sound names.
///
/// ### Example
/// ```dart
/// final sound = ChimeSound.MESSAGE;
/// final custom = ChimeSound.CUSTOM('doorbell');
///
/// print(sound.getKey()); // "message"
/// print(custom.getKey()); // "doorbell"
/// ```
/// {@endtemplate}
final class ChimeSound {
  /// The raw sound name identifier.
  final String _key;

  /// {@macro chime_sound}
  const ChimeSound._(this._key);

  /// Returns the sound name identifier used by notification plugins.
  ///
  /// ### Example
  /// ```dart
  /// final key = ChimeSound.INCOMING.getKey();
  /// ```
  String getKey() => _key;

  /// {@template chime_sound_connect}
  /// Sound name for connection events.
  ///
  /// ### Example
  /// ```dart
  /// final sound = ChimeSound.CONNECT;
  /// ```
  /// {@endtemplate}
  static const ChimeSound CONNECT = ChimeSound._("connect");

  /// {@template chime_sound_incoming}
  /// Sound name for incoming calls or requests.
  ///
  /// ### Example
  /// ```dart
  /// final sound = ChimeSound.INCOMING;
  /// ```
  /// {@endtemplate}
  static const ChimeSound INCOMING = ChimeSound._("incoming");

  /// {@template chime_sound_message}
  /// Sound name for new messages.
  ///
  /// ### Example
  /// ```dart
  /// final sound = ChimeSound.MESSAGE;
  /// ```
  /// {@endtemplate}
  static const ChimeSound MESSAGE = ChimeSound._("message");

  /// {@template chime_sound_notify}
  /// Sound name for general notifications.
  ///
  /// ### Example
  /// ```dart
  /// final sound = ChimeSound.NOTIFY;
  /// ```
  /// {@endtemplate}
  static const ChimeSound NOTIFY = ChimeSound._("notify");

  /// {@template chime_sound_schedule}
  /// Sound name for schedule reminders or alerts.
  ///
  /// ### Example
  /// ```dart
  /// final sound = ChimeSound.SCHEDULE;
  /// ```
  /// {@endtemplate}
  static const ChimeSound SCHEDULE = ChimeSound._("schedule");

  /// {@template chime_sound_custom}
  /// Creates a custom sound name.
  ///
  /// Use this when the sound asset is not covered by the built-in constants.
  ///
  /// ### Example
  /// ```dart
  /// final sound = ChimeSound.CUSTOM('ambient');
  /// ```
  /// {@endtemplate}
  static ChimeSound CUSTOM(String key) => ChimeSound._(key);
}