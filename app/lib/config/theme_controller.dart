import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global light/dark toggle, persisted on device. Ported from kpop.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

const _prefsKey = 'theme_mode';

Future<void> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_prefsKey);
  themeModeNotifier.value = switch (stored) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.dark,
  };
}

Future<void> setThemeMode(ThemeMode mode) async {
  themeModeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, mode == ThemeMode.light ? 'light' : 'dark');
}
