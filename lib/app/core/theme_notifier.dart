// lib/app/core/theme_notifier.dart
import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleDark(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => value == ThemeMode.dark;
}

final themeNotifier = ThemeNotifier();