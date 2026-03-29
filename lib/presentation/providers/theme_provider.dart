// Theme Provider
// 
// Manages app theme (light/dark mode) state
// Author: CaloCam Team
// Last updated: 2025-10-21
// ⚠️ DARK MODE DISABLED - Always locked to light mode

import 'package:flutter/material.dart';

/// Theme provider for managing dark/light mode
/// ⚠️ DARK MODE DISABLED - Always uses light mode
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // ✅ Force light mode

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  bool get isLightMode {
    return _themeMode == ThemeMode.light;
  }

  bool get isSystemMode {
    return _themeMode == ThemeMode.system;
  }

  /// Initialize theme from saved preferences
  /// ⚠️ DISABLED: Always uses light mode
  Future<void> loadThemePreference() async {
    // Force light mode - ignore saved preferences
    _themeMode = ThemeMode.light;
    notifyListeners();
    debugPrint('✅ Theme locked to light mode');
  }

  /// Set theme mode and save to preferences
  /// ⚠️ DISABLED: Always locked to light mode
  Future<void> setThemeMode(ThemeMode mode) async {
    // Do nothing - theme locked to light mode
    debugPrint('⚠️ Theme change blocked - app locked to light mode');
    return;
  }

  /// Toggle between light and dark mode
  /// ⚠️ DISABLED: Always locked to light mode
  Future<void> toggleTheme() async {
    // Do nothing - theme locked to light mode
    debugPrint('⚠️ Theme toggle blocked - app locked to light mode');
    return;
  }

  /// Set system theme mode (follow system settings)
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}

