import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/elevated_button_theme.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/text_field_theme.dart';
import 'package:uniconnect/ui/core/theme/custom_themes/text_theme.dart';

import 'custom_themes/color_scheme_theme.dart';

abstract final class UCTheme {
  static ThemeData lightTheme = ThemeData(
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: UCColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    brightness: Brightness.light,
    textTheme: GoogleFonts.interTextTheme(),
    colorScheme: UCColorScheme.lightScheme,
    inputDecorationTheme: UCTextFormFieldTheme.lightInputDecorationThemeData,
    elevatedButtonTheme: UCElevatedButtonTheme.lightElevatedButtonThemeData,
    //bottomSheetTheme:
  );

  static ThemeData darkTheme = ThemeData(
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: UCColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    brightness: Brightness.dark,
    textTheme: GoogleFonts.interTextTheme(UCTextTheme.lightTextTheme),
    inputDecorationTheme: UCTextFormFieldTheme.darkInputDecorationThemeData,
    colorScheme: UCColorScheme.darkScheme,
    // elevatedButtonTheme: UCElevatedButtonTheme.darkElevatedButtonThemeData,
  );
}
