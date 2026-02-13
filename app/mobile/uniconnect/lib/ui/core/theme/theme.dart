import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/elevated_button_theme.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/outlined_button_theme.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/text_field_theme.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/text_theme.dart';

import 'custom_themes/color_scheme_theme.dart';

abstract final class UCTheme{
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    textTheme: GoogleFonts.interTextTheme(),
    colorScheme: UCColorScheme.lightScheme,
    inputDecorationTheme: UCTextFormFieldTheme.lightInputDecorationThemeData,
    elevatedButtonTheme: UCElevatedButtonTheme.lightElevatedButtonThemeData,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    textTheme: GoogleFonts.interTextTheme(
      UCTextTheme.lightTextTheme
    ),
    inputDecorationTheme: UCTextFormFieldTheme.darkInputDecorationThemeData,
    colorScheme: UCColorScheme.darkScheme,
    // elevatedButtonTheme: UCElevatedButtonTheme.darkElevatedButtonThemeData,
  );
}