import 'package:flutter/material.dart';
import 'package:smart/src/ui/typedefs.dart';
import 'package:smart/utilities.dart';
import 'package:hapnium/hapnium.dart';

/// {@template button_view}
/// Represents a customizable button with an icon and additional properties.
/// {@endtemplate}
final class ButtonView<ButtonKey extends Object> with EqualsAndHashCode, ToString {
  /// Unique identifier for the widget/object.
  final ButtonKey? key;

  /// The button icon.
  final IconData icon;

  /// The index associated with the button.
  final Integer index;

  /// The main title/header of the button.
  final String header;

  /// The body text of the button.
  final String body;

  /// A numerical value associated with the button (optional).
  final Double number;

  /// The primary color of the button.
  final Color color;

  /// A list of colors for gradient or multiple states.
  final ColorList colors;

  /// The navigation path associated with the button.
  final String path;

  /// The URL or path of an image to be displayed.
  final String image;

  /// A callback function triggered when the button is clicked.
  final OnActionInvoked? onClick;

  /// An optional child widget inside the button.
  final Widget? child;

  /// An optional image widget that can replace icon and image view
  final Widget? imageWidget;

  final bool isEnabled;

  /// Children
  final List<ButtonView<ButtonKey>> children;

  ButtonView({
    this.key,
    this.icon = Icons.copy,
    this.index = 0,
    this.header = "",
    this.body = "",
    this.number = 0.0,
    this.color = Colors.white,
    this.path = "/",
    this.onClick,
    this.child,
    this.image = "",
    this.colors = const [],
    this.imageWidget,
    this.children = const [],
    this.isEnabled = true,
  });

  ButtonView<ButtonKey> copyWith({
    ButtonKey? Function()? key,
    IconData? icon,
    Integer? index,
    String? header,
    String? body,
    Double? number,
    Color? color,
    ColorList? colors,
    String? path,
    String? image,
    OnActionInvoked? Function()? onClick,
    Widget? Function()? child,
    Widget? Function()? imageWidget,
    List<ButtonView<ButtonKey>>? children,
    bool? isEnabled
  }) {
    return ButtonView<ButtonKey>(
      key: key != null ? key() : this.key,
      icon: icon ?? this.icon,
      index: index ?? this.index,
      header: header ?? this.header,
      body: body ?? this.body,
      number: number ?? this.number,
      color: color ?? this.color,
      colors: colors ?? this.colors,
      path: path ?? this.path,
      image: image ?? this.image,
      onClick: onClick != null ? onClick() : this.onClick,
      child: child != null ? child() : this.child,
      imageWidget: imageWidget != null ? imageWidget() : this.imageWidget,
      children: children ?? this.children,
      isEnabled: isEnabled ?? this.isEnabled
    );
  }

  @override
  List<Object?> equalizedProperties() => [
    key,
    icon.codePoint,
    index,
    header,
    body,
    number,
    path,
    isEnabled,
    image,
    colors,
    color,
    children
  ];
}