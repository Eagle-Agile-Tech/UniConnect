import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/routing/router.dart';
import 'package:uniconnect/ui/core/theme/theme.dart';

class UniConnect extends StatelessWidget {
  const UniConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: UCTheme.lightTheme,
        darkTheme: UCTheme.darkTheme,
      ),
    );
  }
}