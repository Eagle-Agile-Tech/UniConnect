import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';

abstract final class UCElevatedButtonTheme {
  static ElevatedButtonThemeData lightElevatedButtonThemeData = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      disabledBackgroundColor: Colors.grey.shade300,
      disabledForegroundColor: Colors.grey.shade600,
      side: const BorderSide(color: UCColors.primary),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      )
    )
  );
}