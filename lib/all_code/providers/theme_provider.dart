import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider for managing dark/light mode
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themePrefKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(_themePrefKey) ?? 'system';
    
    switch (themeValue) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    await _saveThemePreference();
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String themeValue;
    
    switch (_themeMode) {
      case ThemeMode.light:
        themeValue = 'light';
        break;
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      default:
        themeValue = 'system';
    }
    
    await prefs.setString(_themePrefKey, themeValue);
  }
}
