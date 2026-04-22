import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';

abstract final class UCElevatedButtonTheme {
  static ElevatedButtonThemeData elevatedButtonThemeData(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.white : UCColors.primary),
        foregroundColor: isDark ? Colors.white : UCColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }
}


abstract final class UCOutlinedButtonTheme {
  static OutlinedButtonThemeData outlinedButtonThemeData(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.white : UCColors.primary),
        foregroundColor: isDark ? Colors.white : UCColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}