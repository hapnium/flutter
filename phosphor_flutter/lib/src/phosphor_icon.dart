library phosphor_flutter;

import 'package:flutter/material.dart';

class PhosphorIcon extends Icon {
  const PhosphorIcon(
    super.icon, {
    super.key,
    super.size,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.color,
    super.shadows,
    super.semanticLabel,
    super.textDirection,
    this.duotoneSecondaryOpacity = 0.20,
    this.duotoneSecondaryColor,
  });

  final double duotoneSecondaryOpacity;
  final Color? duotoneSecondaryColor;
}
