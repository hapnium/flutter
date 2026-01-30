import 'package:flutter/material.dart';

import 'enums.dart';

/// Signature for building a custom icon widget. The builder is passed
/// the current context, the notification state and a suggested color
/// derived from the state style. Builders can return any widget; a
/// common use case is to return an [Icon] or an animated SVG.
typedef ChimeNotificationDisplayIconBuilder = Widget Function(
  BuildContext context,
  ChimeInAppState state,
  Color color,
);

/// Signature for building the message portion of the notification. The
/// builder receives the context, the notification text, a suggested
/// [TextStyle], and the current state. It should return a widget
/// capable of rendering the message, such as a [Text] or a custom
/// rich text widget.
typedef ChimeNotificationDisplayMessageBuilder = Widget Function(
  BuildContext context,
  String message,
  TextStyle textStyle,
  ChimeInAppState state,
);

/// Signature for building a custom [BoxDecoration] for the container
/// around the notification. The builder receives the context, a
/// suggested state colour, and the current state. If provided, this
/// completely replaces the default decoration used by
/// [ChimeNotificationDisplay].
typedef ChimeNotificationDisplayDecorationBuilder = BoxDecoration Function(
  BuildContext context,
  Color stateColor,
  ChimeInAppState state,
);

typedef ChimeNotificationDisplayConfigurationBuilder =
    ChimeNotificationDisplayConfiguration Function(
  ChimeNotificationDisplayConfiguration config,
);

typedef ChimeNotificationDisplayThemeBuilder = ChimeNotificationDisplayTheme Function(
  ChimeNotificationDisplayTheme theme,
);

typedef ChimeNotificationDisplayStateStyleBuilder =
    ChimeNotificationDisplayStateStyle Function(
  ChimeNotificationDisplayStateStyle style,
);

/// Holds the visual configuration for a single notification state. It
/// specifies the default colour and icon for that state, and allows
/// an optional [iconBuilder] to override how the icon is built.
final class ChimeNotificationDisplayStateStyle {
  /// The primary colour associated with this state. This colour is
  /// applied to the icon and border, and is passed to builder
  /// callbacks.
  final Color color;

  /// The default [IconData] to use when building the icon for this
  /// state. If null, callers must provide an [iconBuilder] in
  /// [ChimeNotificationDisplayConfiguration] to render the icon.
  final IconData? icon;

  /// An optional builder to fully control how the icon is rendered.
  /// When provided, [icon] is ignored for this state. The builder
  /// receives the context, state and colour and must return a widget.
  final ChimeNotificationDisplayIconBuilder? iconBuilder;

  const ChimeNotificationDisplayStateStyle({
    required this.color,
    this.icon,
    this.iconBuilder,
  });

  /// Returns a new [ChimeNotificationDisplayStateStyle] with the given fields
  /// replaced. Unspecified fields retain their original values.
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

/// Theme-level styling for the notification display. It allows the
/// caller to specify separate background colours for light and dark
/// themes. Additional theme attributes can be added here over time.
final class ChimeNotificationDisplayTheme {
  /// Background colour used when the app’s theme brightness is
  /// [Brightness.light]. If null, a sensible default is used.
  final Color lightBackgroundColor;

  /// Background colour used when the app’s theme brightness is
  /// [Brightness.dark]. If null, a sensible default is used.
  final Color darkBackgroundColor;

  /// Text colour used when the app’s theme brightness is
  /// [Brightness.light]. If null, a sensible default is used.
  final Color lightTextColor;

  /// Text colour used when the app’s theme brightness is
  /// [Brightness.dark]. If null, a sensible default is used.
  final Color darkTextColor;

  const ChimeNotificationDisplayTheme({
    required this.lightBackgroundColor,
    required this.darkBackgroundColor,
    required this.lightTextColor,
    required this.darkTextColor,
  });

  /// Returns a copy of this theme with the given fields replaced.
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

/// Global configuration object for the [ChimeNotificationDisplay] widget. All
/// configurable aspects—including colours, padding, border styling,
/// typography, and state-specific styles—are defined here. Users can
/// derive new configurations from existing ones via [copyWith] to
/// customise just the parts they care about.
final class ChimeNotificationDisplayConfiguration {
  /// Mapping of each [ChimeInAppState] to its visual style. All
  /// possible states must be present in this map. Defaults are
  /// provided via [ChimeNotificationDisplayConfiguration.defaults].
  final Map<ChimeInAppState, ChimeNotificationDisplayStateStyle>
      stateStyles;

  /// The margin applied around the outer container. Defaults to
  /// horizontal spacing only (8px on the right).
  final EdgeInsets margin;

  /// The padding applied inside the container around the icon and
  /// message. Defaults to vertical: 6, horizontal: 16.
  final EdgeInsets padding;

  /// The border radius applied to the container. Defaults to a
  /// circular radius of 16.
  final BorderRadius borderRadius;

  /// The thickness of the border around the notification container.
  /// Defaults to a thin border with alpha applied to the state colour.
  final double borderWidth;

  /// The size of the icon. Default is 20.
  final double iconSize;

  /// The text style applied to the message. Defaults to size 12,
  /// semi-bold weight. The colour is not specified here; it is
  /// resolved at build time based on the app’s dark/light theme and
  /// passed into [messageBuilder].
  final TextStyle messageTextStyle;

  /// An optional builder to override how the message widget is
  /// constructed. When provided, [messageTextStyle] is still passed
  /// to the builder as a suggestion, but the builder may ignore it.
  final ChimeNotificationDisplayMessageBuilder? messageBuilder;

  /// An optional builder to override how the container’s decoration
  /// (colour, border, radius) is created. The builder receives the
  /// context, state colour and current state. When provided, it
  /// supersedes the default decoration built from [stateStyles],
  /// [borderRadius], [borderWidth] and the app theme. If null, the
  /// default decoration is used.
  final ChimeNotificationDisplayDecorationBuilder? decorationBuilder;

  /// Theme-level configuration such as light and dark backgrounds. If
  /// null, defaults will be used based on [CommonColors] and
  /// [Database.instance] when available.
  final ChimeNotificationDisplayTheme? theme;

  /// Creates a [ChimeNotificationDisplayConfiguration] with sensible defaults. You can
  /// override any field using [copyWith]. All undefined colours and
  /// icons fall back to Material defaults for each state.
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

  /// Returns a copy of this configuration with the given fields
  /// replaced by new values. Unspecified fields remain unchanged. Use
  /// this method to customise only the parts you need without
  /// constructing a whole new config from scratch.
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

/// A flexible and highly configurable notification widget. It retains
/// the same overall structure (a centred row containing a coloured
/// container with an icon and message) but exposes a rich set of
/// configuration options via [ChimeNotificationDisplayConfiguration]. Clients can
/// customise colours, icons, padding, borders, and even replace
/// internal widgets with their own builders.
class ChimeNotificationDisplay extends StatelessWidget {
  /// The text to display in the notification.
  final String message;

  /// The semantic state of the notification. Determines which
  /// [ChimeNotificationDisplayStateStyle] is used from [config.stateStyles].
  final ChimeInAppState state;

  /// Visual and behavioural configuration for this notification. If
  /// omitted, [ChimeNotificationDisplayConfiguration.defaults] are used.
  final ChimeNotificationDisplayConfiguration config;

  const ChimeNotificationDisplay({
    super.key,
    required this.message,
    required this.state,
    this.config = const ChimeNotificationDisplayConfiguration(),
  });

  @override
  Widget build(BuildContext context) {
    // Select the style for the current state.
    final stateStyle = config.stateStyles[state] ??
        const ChimeNotificationDisplayStateStyle(
          color: Colors.black,
        );

    // Determine the base colour and icon for the state. The caller can
    // override the icon entirely via [iconBuilder] on the state style.
    final Color stateColor = stateStyle.color;

    // Resolve the container’s background colour based on the current
    // theme. Use the configured theme if provided; otherwise fall back
    // to `CommonColors` when available. If neither is available,
    // default to transparent.
    final Brightness brightness = Theme.of(context).brightness;
    final Color backgroundColor;
    if (config.theme case ChimeNotificationDisplayTheme theme?) {
      backgroundColor = brightness == Brightness.dark ? theme.darkBackgroundColor : theme.lightBackgroundColor;
    } else {
      backgroundColor = brightness == Brightness.dark ? Colors.black : Colors.white;
    }

    // Build the icon using either a custom builder or the default
    // IconData. If neither is specified, an empty SizedBox is used.
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

    // Build the message widget. Use the custom builder if provided;
    // otherwise, use a default Text with the configured style
    // and theme-aware colour.
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

    // Build the decoration. Use custom builder if provided; else
    // default to theme-aware background, configured border radius and
    // state-coloured border.
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

    // Assemble the final widget tree. The structure mirrors the
    // original implementation but uses configuration parameters.
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