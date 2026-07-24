/// The phosphor_flutter library.
///
/// Provides the complete Phosphor icon set for Flutter, with six weight
/// variants (Regular, Thin, Light, Bold, Fill, Duotone) and a convenience
/// accessor class.
///
/// ## Quick start
///
/// ```dart
/// import 'package:phosphor_flutter/phosphor_flutter.dart';
///
/// // Using a specific style class:
/// Icon(PhosphorIconsBold.acorn);
///
/// // Using the convenience accessor with a style parameter:
/// Icon(PhosphorIcons.acorn(PhosphorIconsStyle.bold));
/// ```
///
/// ## Available style classes
///
/// - [PhosphorIconsRegular] — the default weight, suitable for most use cases.
/// - [PhosphorIconsThin] — a delicate, lightweight stroke.
/// - [PhosphorIconsLight] — slightly heavier than Thin.
/// - [PhosphorIconsBold] — a thick, commanding stroke.
/// - [PhosphorIconsFill] — a solid, filled variant.
/// - [PhosphorIconsDuotone] — a two-tone variant with primary and secondary colors.
///
/// ## Convenience accessor
///
/// [PhosphorIcons] provides static methods that accept a [PhosphorIconsStyle]
/// parameter and return the correct [IconData] for the requested style.
/// The default style is [PhosphorIconsStyle.regular].
///
/// ## Custom widget
///
/// [PhosphorIcon] extends Flutter's [Icon] widget with duotone-specific
/// properties ([duotoneSecondaryOpacity], [duotoneSecondaryColor]).
library;

export 'src/styles/phosphor_icons_bold.dart';
export 'src/styles/phosphor_icons_duotone.dart';
export 'src/styles/phosphor_icons_fill.dart';
export 'src/styles/phosphor_icons_light.dart';
export 'src/styles/phosphor_icons_regular.dart';
export 'src/styles/phosphor_icons_thin.dart';

export 'src/phosphor_icon.dart';
export 'src/phosphor_icons.dart';
