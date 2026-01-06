import 'package:flutter/material.dart';
import 'package:smart/utilities.dart';

import '../text/text_builder.dart';

/// A customizable fake input field that mimics a search bar with an optional button.
///
/// This widget is useful when you want to create a **non-editable search field**
/// that triggers an action when tapped.
///
/// Example usage:
/// ```dart
/// FakeField(
///   buttonText: "Search",
///   searchText: "Enter keyword...",
///   onTap: () => print("Fake field tapped"),
/// )
/// ```
class FakeField extends StatelessWidget {
  /// The text displayed inside the button (if `showSearchButton` is `true`).
  final String buttonText;

  /// The placeholder or text inside the search field.
  final String searchText;

  /// Determines whether padding should be applied around the field.
  ///
  /// Defaults to `true`.
  final bool needPadding;

  /// Determines whether the search button should be displayed.
  ///
  /// Defaults to `true`.
  final bool showSearchButton;

  /// Callback function that is triggered when the field is tapped.
  final VoidCallback? onTap;

  /// The background color of the fake search field.
  final Color? color;

  /// The text color of the `searchText`.
  final Color? searchTextColor;

  /// The background color of the button (if `showSearchButton` is `true`).
  final Color? buttonColor;

  /// The text color of the `buttonText`.
  final Color? buttonTextColor;

  /// Padding applied to the entire widget.
  final EdgeInsetsGeometry? padding;

  /// Padding applied inside the field container.
  final EdgeInsetsGeometry? fieldPadding;

  /// Padding applied inside the search button.
  final EdgeInsetsGeometry? buttonPadding;

  /// Padding applied to the spacer at the end of the field.
  final EdgeInsetsGeometry? endSpacePadding;

  /// Font size of the `searchText`.
  final double? searchTextSize;

  /// Font size of the `buttonText`.
  final double? buttonTextSize;

  /// The width of the field container.
  ///
  /// Defaults to the full screen width.
  final double? fieldWidth;

  /// Border radius of the fake search field.
  ///
  /// Defaults to `16.0`.
  final BorderRadiusGeometry? borderRadius;

  /// Border radius of the button (if `showSearchButton` is `true`).
  ///
  /// Defaults to a **rounded right edge**.
  final BorderRadiusGeometry? buttonBorderRadius;

  /// A widget that acts as a spacer when the button is **not** shown.
  ///
  /// Defaults to an empty container with padding.
  final Widget? spacer;

  /// Creates a new instance of [FakeField].
  ///
  /// - [buttonText] and [searchText] are **required**.
  /// - [showSearchButton] and [needPadding] default to `true`.
  ///
  /// Example:
  /// ```dart
  /// FakeField(
  ///   buttonText: "Search",
  ///   searchText: "Enter keyword...",
  ///   onTap: () => print("Field tapped"),
  ///   color: Colors.white,
  /// )
  /// ```
  const FakeField({
    super.key,
    required this.buttonText,
    required this.searchText,
    this.onTap,
    this.showSearchButton = true,
    this.needPadding = true,
    this.color,
    this.searchTextColor,
    this.buttonColor,
    this.buttonTextColor,
    this.padding,
    this.fieldPadding,
    this.buttonPadding,
    this.endSpacePadding,
    this.searchTextSize,
    this.buttonTextSize,
    this.fieldWidth,
    this.borderRadius,
    this.buttonBorderRadius,
    this.spacer,
  });

  @override
  Widget build(BuildContext context) {
    // Default padding if `needPadding` is true
    EdgeInsetsGeometry padding = this.padding ?? (needPadding ? const EdgeInsets.symmetric(horizontal: 12.0) : EdgeInsets.zero);

    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Material(
          color: color ?? Theme.of(context).appBarTheme.backgroundColor,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: fieldPadding ?? const EdgeInsets.only(left: 16.0),
              width: fieldWidth ?? MediaQuery.sizeOf(context).width,
              child: Row(
                children: [
                  // Search text
                  Expanded(
                    child: TextBuilder(
                      text: searchText,
                      size: Sizing.font(searchTextSize ?? 14),
                      color: searchTextColor ?? Theme.of(context).primaryColor,
                      flow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Show button if `showSearchButton` is true
                  if (showSearchButton && buttonText.isNotEmpty) ...[
                    const SizedBox(width: 20),
                    Container(
                      padding: buttonPadding ?? const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: buttonBorderRadius ?? const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        color: buttonColor ?? Theme.of(context).primaryColor,
                      ),
                      child: TextBuilder(
                        text: buttonText,
                        size: Sizing.font(buttonTextSize ?? 14),
                        color: buttonTextColor ?? Theme.of(context).scaffoldBackgroundColor,
                      ),
                    )
                  ] else ...[
                    // If button is hidden, use spacer
                    spacer ?? Container(padding: endSpacePadding ?? const EdgeInsets.all(26.0)),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}