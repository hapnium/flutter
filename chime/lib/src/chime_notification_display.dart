import 'package:flutter/material.dart';

import 'enums.dart';

/// {@template chime_notification_display_icon_builder}
/// Signature for building a custom icon widget for a [ChimeNotificationDisplay].
///
/// The builder receives:
/// - [context] — the current build context
/// - [state] — the semantic notification state (success, error, etc.)
/// - [color] — a suggested colour derived from the [ChimeNotificationDisplayStateStyle]
///
/// Return any widget; a common use case is an [Icon] or animated SVG.
/// {@endtemplate}
typedef ChimeNotificationDisplayIconBuilder = Widget Function(
  BuildContext context,
  ChimeInAppState state,
  Color color,
);

/// {@template chime_notification_display_message_builder}
/// Signature for building the message portion of a [ChimeNotificationDisplay].
///
/// The builder receives:
/// - [context] — the current build context
/// - [message] — the notification text
/// - [textStyle] — a suggested [TextStyle] with theme-aware colour applied
/// - [state] — the semantic notification state
///
/// Return a widget capable of rendering the message, such as [Text] or a
/// custom rich text widget.
/// {@endtemplate}
typedef ChimeNotificationDisplayMessageBuilder = Widget Function(
  BuildContext context,
  String message,
  TextStyle textStyle,
  ChimeInAppState state,
);

/// {@template chime_notification_display_decoration_builder}
/// Signature for building a custom [BoxDecoration] for the container
/// surrounding a [ChimeNotificationDisplay].
///
/// The builder receives:
/// - [context] — the current build context
/// - [stateColor] — the primary colour for the current notification state
/// - [state] — the semantic notification state
///
/// When provided, this completely replaces the default decoration built
/// from [ChimeNotificationDisplayConfiguration.borderRadius],
/// [ChimeNotificationDisplayConfiguration.borderWidth], and the app theme.
/// {@endtemplate}
typedef ChimeNotificationDisplayDecorationBuilder = BoxDecoration Function(
  BuildContext context,
  Color stateColor,
  ChimeInAppState state,
);

/// {@template chime_notification_display_configuration_builder}
/// Signature for deriving a new [ChimeNotificationDisplayConfiguration]
/// from an existing one.
///
/// Used to selectively override configuration fields while preserving
/// defaults for unspecified values.
/// {@endtemplate}
typedef ChimeNotificationDisplayConfigurationBuilder = ChimeNotificationDisplayConfiguration Function(
  ChimeNotificationDisplayConfiguration config,
);

/// {@template chime_notification_display_theme_builder}
/// Signature for deriving a new [ChimeNotificationDisplayTheme]
/// from an existing one.
///
/// Used to selectively override theme fields while preserving defaults
/// for unspecified values.
/// {@endtemplate}
typedef ChimeNotificationDisplayThemeBuilder = ChimeNotificationDisplayTheme Function(
  ChimeNotificationDisplayTheme theme,
);

/// {@template chime_notification_display_state_style_builder}
/// Signature for deriving a new [ChimeNotificationDisplayStateStyle]
/// from an existing one.
///
/// Used to selectively override state style fields while preserving
/// defaults for unspecified values.
/// {@endtemplate}
typedef ChimeNotificationDisplayStateStyleBuilder = ChimeNotificationDisplayStateStyle Function(
  ChimeNotificationDisplayStateStyle style,
);

/// {@template chime_notification_display_state_style}
/// Holds the visual configuration for a single notification state
/// ([ChimeInAppState]).
///
/// Specifies the default colour and icon for a state, and allows an
/// optional [iconBuilder] to fully control icon rendering. When
/// [iconBuilder] is provided, [icon] is ignored for that state.
///
/// Use this inside [ChimeNotificationDisplayConfiguration.stateStyles]
/// to define per-state appearance.
///
/// ### Example
/// ```dart
/// const style = ChimeNotificationDisplayStateStyle(
///   color: Colors.green,
///   icon: Icons.check_circle,
/// );
/// ```
/// {@endtemplate}
final class ChimeNotificationDisplayStateStyle {
  /// The primary colour associated with this state.
  ///
  /// Applied to the icon tint and container border. Also passed to
  /// [ChimeNotificationDisplayIconBuilder] and
  /// [ChimeNotificationDisplayDecorationBuilder] as a suggestion.
  final Color color;

  /// The default [IconData] for this state.
  ///
  /// If null, callers must provide an [iconBuilder] in the same state
  /// style or in [ChimeNotificationDisplayConfiguration] to render the icon.
  final IconData? icon;

  /// An optional builder to fully control how the icon is rendered.
  ///
  /// When provided, [icon] is ignored for this state. The builder
  /// receives the current context, the notification state, and the
  /// state colour, and must return a widget.
  final ChimeNotificationDisplayIconBuilder? iconBuilder;

  /// {@macro chime_notification_display_state_style}
  const ChimeNotificationDisplayStateStyle({
    required this.color,
    this.icon,
    this.iconBuilder,
  });

  /// Returns a new [ChimeNotificationDisplayStateStyle] with the given
  /// fields replaced. Unspecified fields retain their original values.
  ChimeNotificationDisplayStateStyle copyWith({
    Color? color,
    IconData? icon,
    ChimeNotificationDisplayIconBuilder? iconBuilder,
  }) {
    return ChimeNotificationDisplayStateStyle(
      color: color ?? this.color,
      icon: icon ?? this.icon,
      iconBuilder: iconBuilder ?? this.iconBuilder,
    );
  }
}

/// {@template chime_notification_display_theme}
/// Theme-level styling for [ChimeNotificationDisplay].
///
/// Allows specifying separate background and text colours for light and
/// dark themes. Additional theme attributes can be added over time.
///
/// When provided via [ChimeNotificationDisplayConfiguration.theme],
/// the widget resolves colours based on the current [ThemeData.brightness].
///
/// ### Example
/// ```dart
/// const theme = ChimeNotificationDisplayTheme(
///   lightBackgroundColor: Colors.white,
///   darkBackgroundColor: Color(0xFF1E1E1E),
///   lightTextColor: Colors.black,
///   darkTextColor: Colors.white,
/// );
/// ```
/// {@endtemplate}
final class ChimeNotificationDisplayTheme {
  /// Background colour used when [Brightness.light].
  final Color lightBackgroundColor;

  /// Background colour used when [Brightness.dark].
  final Color darkBackgroundColor;

  /// Text colour used when [Brightness.light].
  final Color lightTextColor;

  /// Text colour used when [Brightness.dark].
  final Color darkTextColor;

  /// {@macro chime_notification_display_theme}
  const ChimeNotificationDisplayTheme({
    required this.lightBackgroundColor,
    required this.darkBackgroundColor,
    required this.lightTextColor,
    required this.darkTextColor,
  });

  /// Returns a copy of this theme with the given fields replaced.
  /// Unspecified fields retain their original values.
  ChimeNotificationDisplayTheme copyWith({
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightTextColor,
    Color? darkTextColor,
  }) {
    return ChimeNotificationDisplayTheme(
      lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
      darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
      lightTextColor: lightTextColor ?? this.lightTextColor,
      darkTextColor: darkTextColor ?? this.darkTextColor,
    );
  }
}

/// {@template chime_notification_display_configuration}
/// Global configuration object for [ChimeNotificationDisplay].
///
/// All configurable aspects — colours, padding, border styling, typography,
/// and state-specific styles — are defined here. Derive new configurations
/// from existing ones via [copyWith] to customise only the parts you need.
///
/// ### Example
/// ```dart
/// final config = ChimeNotificationDisplayConfiguration(
///   iconSize: 24,
///   borderWidth: 2,
///   theme: ChimeNotificationDisplayTheme(
///     lightBackgroundColor: Colors.white,
///     darkBackgroundColor: Colors.grey.shade900,
///     lightTextColor: Colors.black87,
///     darkTextColor: Colors.white70,
///   ),
/// );
/// ```
/// {@endtemplate}
final class ChimeNotificationDisplayConfiguration {
  /// Mapping of each [ChimeInAppState] to its visual style.
  ///
  /// All possible states should be present in this map. Defaults cover
  /// success, error, warning, and info with Material accent colours.
  final Map<ChimeInAppState, ChimeNotificationDisplayStateStyle> stateStyles;

  /// The margin applied around the outer container.
  ///
  /// Defaults to `EdgeInsets.only(right: 8.0)`.
  final EdgeInsets margin;

  /// The padding applied inside the container around the icon and message.
  ///
  /// Defaults to `EdgeInsets.symmetric(vertical: 6, horizontal: 16)`.
  final EdgeInsets padding;

  /// The border radius applied to the container.
  ///
  /// Defaults to `BorderRadius.all(Radius.circular(16))`.
  final BorderRadius borderRadius;

  /// The thickness of the border around the notification container.
  ///
  /// Defaults to `1.0`. The border colour is the state colour at 20% alpha.
  final double borderWidth;

  /// The size of the icon in logical pixels.
  ///
  /// Defaults to `20.0`.
  final double iconSize;

  /// The text style applied to the message.
  ///
  /// Defaults to size 12, `FontWeight.w500`. The colour is not specified
  /// here; it is resolved at build time based on the app's theme and
  /// passed into [messageBuilder] or used directly in the default [Text].
  final TextStyle messageTextStyle;

  /// An optional builder to override how the message widget is constructed.
  ///
  /// When provided, [messageTextStyle] is still passed to the builder as
  /// a suggestion, but the builder may ignore it.
  final ChimeNotificationDisplayMessageBuilder? messageBuilder;

  /// An optional builder to override the container's [BoxDecoration].
  ///
  /// Receives the context, state colour, and current state. When provided,
  /// it supersedes the default decoration built from [stateStyles],
  /// [borderRadius], [borderWidth], and the app theme.
  final ChimeNotificationDisplayDecorationBuilder? decorationBuilder;

  /// Theme-level configuration for light and dark backgrounds and text.
  ///
  /// If null, defaults to white/black backgrounds and black/white text
  /// based on the current brightness.
  final ChimeNotificationDisplayTheme? theme;

  /// {@macro chime_notification_display_configuration}
  ///
  /// Creates a configuration with sensible defaults for all fields.
  /// Override any field using [copyWith].
  const ChimeNotificationDisplayConfiguration({
    this.stateStyles = const {
      ChimeInAppState.success: ChimeNotificationDisplayStateStyle(
        color: Colors.greenAccent,
        icon: Icons.check_circle_outline,
      ),
      ChimeInAppState.error: ChimeNotificationDisplayStateStyle(
        color: Colors.redAccent,
        icon: Icons.error_outline,
      ),
      ChimeInAppState.warning: ChimeNotificationDisplayStateStyle(
        color: Colors.orangeAccent,
        icon: Icons.warning_amber_rounded,
      ),
      ChimeInAppState.info: ChimeNotificationDisplayStateStyle(
        color: Colors.blueAccent,
        icon: Icons.info_outline,
      ),
    },
    this.margin = const EdgeInsets.only(right: 8.0),
    this.padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    this.borderRadius =
        const BorderRadius.all(Radius.circular(16)),
    this.borderWidth = 1.0,
    this.iconSize = 20.0,
    this.messageTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    this.messageBuilder,
    this.decorationBuilder,
    this.theme,
  });

  /// Returns a copy of this configuration with the given fields replaced
  /// by new values. Unspecified fields remain unchanged.
  ChimeNotificationDisplayConfiguration copyWith({
    Map<ChimeInAppState, ChimeNotificationDisplayStateStyle>? stateStyles,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double? borderWidth,
    double? iconSize,
    TextStyle? messageTextStyle,
    ChimeNotificationDisplayMessageBuilder? messageBuilder,
    ChimeNotificationDisplayDecorationBuilder? decorationBuilder,
    ChimeNotificationDisplayTheme? theme,
  }) {
    return ChimeNotificationDisplayConfiguration(
      stateStyles: stateStyles ?? this.stateStyles,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      iconSize: iconSize ?? this.iconSize,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      messageBuilder: messageBuilder ?? this.messageBuilder,
      decorationBuilder: decorationBuilder ?? this.decorationBuilder,
      theme: theme ?? this.theme,
    );
  }
}

/// {@template chime_notification_display}
/// A flexible and highly configurable notification widget.
///
/// Retains the same overall structure — a centred row containing a coloured
/// container with an icon and message — but exposes a rich set of
/// configuration options via [ChimeNotificationDisplayConfiguration].
///
/// Clients can customise colours, icons, padding, borders, and even replace
/// internal widgets with their own builders.
///
/// ### Example
/// ```dart
/// ChimeNotificationDisplay(
///   message: 'File uploaded successfully',
///   state: ChimeInAppState.success,
///   config: ChimeNotificationDisplayConfiguration(
///     theme: ChimeNotificationDisplayTheme(
///       lightBackgroundColor: Colors.white,
///       darkBackgroundColor: Color(0xFF1E1E1E),
///       lightTextColor: Colors.black,
///       darkTextColor: Colors.white,
///     ),
///   ),
/// )
/// ```
/// {@endtemplate}
class ChimeNotificationDisplay extends StatelessWidget {
  /// The text to display in the notification.
  final String message;

  /// The semantic state of the notification.
  ///
  /// Determines which [ChimeNotificationDisplayStateStyle] is used from
  /// [config.stateStyles] to resolve the icon, colour, and border.
  final ChimeInAppState state;

  /// Visual and behavioural configuration for this notification.
  ///
  /// If omitted, [ChimeNotificationDisplayConfiguration]'s const defaults
  /// are used.
  final ChimeNotificationDisplayConfiguration config;

  /// {@macro chime_notification_display}
  const ChimeNotificationDisplay({
    super.key,
    required this.message,
    required this.state,
    this.config = const ChimeNotificationDisplayConfiguration(),
  });

  @override
  Widget build(BuildContext context) {
    final stateStyle = config.stateStyles[state] ?? const ChimeNotificationDisplayStateStyle(color: Colors.black);

    final Color stateColor = stateStyle.color;

    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor;
    if (config.theme case ChimeNotificationDisplayTheme theme?) {
      backgroundColor = brightness == Brightness.dark ? theme.darkBackgroundColor : theme.lightBackgroundColor;
    } else {
      backgroundColor = brightness == Brightness.dark ? Colors.black : Colors.white;
    }

    Widget iconWidget;
    if (stateStyle.iconBuilder case var builder?) {
      iconWidget = builder(context, state, stateColor);
    } else if (stateStyle.icon case IconData icon?) {
      iconWidget = Icon(
        icon,
        color: stateColor,
        size: config.iconSize,
      );
    } else {
      iconWidget = const SizedBox.shrink();
    }

    final Color textColor;
    if (config.theme case ChimeNotificationDisplayTheme theme?) {
      textColor = brightness == Brightness.dark ? theme.darkTextColor : theme.lightTextColor;
    } else {
      textColor = brightness == Brightness.dark ? Colors.white : Colors.black;
    }

    final TextStyle baseStyle = config.messageTextStyle.copyWith(color: textColor);
    Widget messageWidget;
    if (config.messageBuilder case var msgBuilder?) {
      messageWidget = msgBuilder(
        context,
        message,
        baseStyle,
        state,
      );
    } else {
      messageWidget = Text(
        message,
        style: baseStyle,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      );
    }

    final BoxDecoration decoration = config.decorationBuilder != null
        ? config.decorationBuilder!(context, stateColor, state)
        : BoxDecoration(
            color: backgroundColor,
            borderRadius: config.borderRadius,
            border: Border.all(
              color: stateColor.withValues(alpha: 0.2),
              width: config.borderWidth,
            ),
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            margin: config.margin,
            padding: config.padding,
            decoration: decoration,
            child: Row(
              spacing: 12,
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                Flexible(child: messageWidget),
              ],
            ),
          ),
        ),
      ],
    );
  }
}