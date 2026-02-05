import 'package:flutter/material.dart';
import 'package:hapnium/hapnium.dart';

/// {@template dynamic_button_view}
/// Represents a dynamic icon button for navigation.
/// {@endtemplate}
final class DynamicButtonView<ButtonKey extends Object> with EqualsAndHashCode, ToString {
  /// Unique identifier for the widget/object.
  final ButtonKey? key;

  /// The default icon displayed when inactive.
  final IconData icon;

  /// The icon displayed when the button is active.
  final IconData active;

  /// The index associated with the button.
  final Integer index;

  /// The title of the button.
  final String title;

  /// The navigation path associated with the button.
  final String path;

  /// The image associated with the button.
  final String image;

  DynamicButtonView({
    this.key,
    this.icon = Icons.copy,
    this.index = 0,
    this.active = Icons.copy,
    this.title = "",
    this.path = "",
    this.image = "",
  });

  DynamicButtonView<ButtonKey> copyWith({
    ButtonKey? Function()? key,
    IconData? icon,
    IconData? active,
    Integer? index,
    String? title,
    String? path,
    String? image,
  }) {
    return DynamicButtonView<ButtonKey>(
      key: key != null ? key() : this.key,
      icon: icon ?? this.icon,
      active: active ?? this.active,
      index: index ?? this.index,
      title: title ?? this.title,
      path: path ?? this.path,
      image: image ?? this.image,
    );
  }

  @override
  List<Object?> equalizedProperties() => [key, icon.codePoint, index, active.codePoint, title, path, image];
}