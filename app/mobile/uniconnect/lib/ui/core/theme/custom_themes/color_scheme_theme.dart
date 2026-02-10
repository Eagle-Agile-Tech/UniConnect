import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';

abstract final class UCColorScheme {
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: UCColors.primary,
    surface: UCColors.background,
    secondary: UCColors.secondary,
    tertiary: UCColors.tertiary,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: UCColors.primary,
    brightness: Brightness.dark,
    surface: UCColors.darkBackground,
    secondary: UCColors.secondary,
  );
}
