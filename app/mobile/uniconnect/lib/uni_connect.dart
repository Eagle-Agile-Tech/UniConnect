import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/routing/router.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/core/theme/theme.dart';

import 'config/theme_provider.dart';

class UniConnect extends ConsumerWidget {
  const UniConnect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.when(
        data: (_) => FlutterNativeSplash.remove(),
        error: (_, __) => FlutterNativeSplash.remove(),
        loading: () => {},
      );
    });

    return  MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: UCTheme.lightTheme,
        darkTheme: UCTheme.darkTheme,
        themeMode: themeState.value ?? ThemeMode.system,
      );

  }
}