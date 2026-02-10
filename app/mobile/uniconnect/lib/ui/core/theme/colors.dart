import 'package:flutter/material.dart';

@immutable
abstract final class UCColors {
  // Brand Colors
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryVariant = Color(0xFFEADDFF);
  static const Color onPrimaryVariant = Color(0xFF21005D);

  // Tried blending this more with the background since it's used for less prominent secondary actons.
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // University Accent (Gold)
  static const Color tertiary = Color(0xFFE6B800);
  static const Color onTertiary = Color(0xFF312E00);

  // Background & Neutral
  static const Color background = Color(0xFFFEF7FF);
  static const Color onBackground = Color(0xFF1D1B20);
  static const Color darkBackground = Color(0xFF15202b);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1D1B20);
  static const Color surfaceVariant = Color(0xFFE7E0EC); // For search bars/input fields
  static const Color onSurfaceVariant = Color(0xFF49454F);

  static const Color outline = Color(0xFF79747E);

  // Semantic States
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);


  // static ColorScheme get scheme => const ColorScheme(
  //   brightness: Brightness.light,
  //   primary: primary,
  //   onPrimary: onPrimary,
  //   primaryContainer: primaryContainer,
  //   onPrimaryContainer: onPrimaryContainer,
  //   secondary: secondary,
  //   onSecondary: onSecondary,
  //   tertiary: tertiary,
  //   onTertiary: onTertiary,
  //   error: error,
  //   onError: onError,
  //   background: background,
  //   onBackground: onBackground,
  //   surface: surface,
  //   onSurface: onSurface,
  //   surfaceVariant: surfaceVariant,
  //   onSurfaceVariant: onSurfaceVariant,
  //   outline: outline,
  // );
}