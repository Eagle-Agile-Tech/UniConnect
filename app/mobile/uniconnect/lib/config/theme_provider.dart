import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider =
AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const _key = "user_theme_mode";

  @override
  Future<ThemeMode> build() async {
    final prefs = ref.read(sharedPrefsProvider);
    final themeIndex = prefs.getInt(_key);

    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);

    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(_key, mode.index);
  }

  Future<void> toggleTheme() async {
    final currentMode = state.value ?? ThemeMode.system;
    final nextMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});