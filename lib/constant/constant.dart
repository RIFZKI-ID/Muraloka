//===this file for constant value===
// example theme, localization, name routing, and other

import 'package:flutter/material.dart';

class AppColors {
  // Primary color - Blue
  static const primary1 = Color(0xFF2196F3); // Material Blue
  
  // Light mode colors
  static const lightBackground = Color(0xFFF5F7FA); // Light gray-blue background
  static const lightSurface = Color(0xFFFFFFFF); // White surface
  static const lightSecondary = Color(0xFF5B9BD5); // Lighter blue
  static const lightAccent = Color(0xFF4A90E2); // Accent blue
  
  // Dark mode colors
  static const darkBackground = Color(0xFF1A1D2E); // Dark blue-gray
  static const darkSurface = Color(0xFF2C3E50); // Dark surface
  static const darkSecondary = Color(0xFF34495E); // Secondary dark
  static const darkAccent = Color(0xFF5DADE2); // Bright accent for dark mode
  
  // Legacy colors (for backward compatibility)
  static const secondary1 = Color(0xFF578FCA);
  static const tertiaryLight = Color(0xFFA1E3F9);
  static const tertiaryDark = Color(0xFFD1F8EF);

  static Color tertiary3(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? tertiaryLight
        : tertiaryDark;
  }
}

class ThemeConfig {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Primary colors
    primaryColor: AppColors.primary1,
    scaffoldBackgroundColor: AppColors.lightBackground,
    
    // Color scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primary1,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
      error: const Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
      onBackground: const Color(0xFF1A1A1A),
      onError: Colors.white,
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary1,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    
    // Card theme
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary1,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary1.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary1.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary1, width: 2),
      ),
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: AppColors.primary1,
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFF333333)),
      bodyMedium: TextStyle(color: Color(0xFF555555)),
      bodySmall: TextStyle(color: Color(0xFF777777)),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Primary colors
    primaryColor: AppColors.darkAccent,
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkAccent,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      error: const Color(0xFFEF5350),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFE0E0E0),
      onBackground: const Color(0xFFE0E0E0),
      onError: Colors.white,
    ),
    
    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    
    // Card theme
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.darkAccent.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.darkAccent.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkAccent, width: 2),
      ),
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: AppColors.darkAccent,
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFFCCCCCC)),
      bodyMedium: TextStyle(color: Color(0xFFAAAAAA)),
      bodySmall: TextStyle(color: Color(0xFF888888)),
    ),
  );
}

abstract class ThemeManager {
  static ThemeManager of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? LightModeTheme() : DarkModeTheme();
  }

  Color get primary1;
  Color get secondary1;
  Color get tertiary1;
}

class LightModeTheme extends ThemeManager {
  @override
  Color get primary1 => AppColors.primary1;
  @override
  Color get secondary1 => AppColors.secondary1;
  @override
  Color get tertiary1 => AppColors.tertiaryLight;
}

class DarkModeTheme extends ThemeManager {
  @override
  Color get primary1 => AppColors.secondary1;
  @override
  Color get secondary1 => AppColors.primary1;
  @override
  Color get tertiary1 => AppColors.tertiaryDark;
}
