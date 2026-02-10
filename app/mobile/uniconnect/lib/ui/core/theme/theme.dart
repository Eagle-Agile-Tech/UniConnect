import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';

abstract final class UCTheme{
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    textTheme: GoogleFonts.interTextTheme(),
    primaryColor: UCColors.primary,
    scaffoldBackgroundColor: UCColors.background
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    textTheme: GoogleFonts.interTextTheme(),
    primaryColor: UCColors.primary,
    scaffoldBackgroundColor: UCColors.darkBackground,
  );
}