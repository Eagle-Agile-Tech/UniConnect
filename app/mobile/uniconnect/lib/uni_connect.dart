import 'package:flutter/material.dart';
import 'package:uniconnect/ui/auth/login/widgets/login_screen.dart';
import 'package:uniconnect/ui/core/theme/theme.dart';

class UniConnect extends StatelessWidget {
  const UniConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: UCTheme.lightTheme,
      darkTheme: UCTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}