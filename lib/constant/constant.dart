//===this file for constant value===
// example theme, localization, name routing, and other

import 'package:flutter/material.dart';

class AppColors {
  static const primary1 = Color(0xFF3674B5);
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
    primaryColor: AppColors.primary1,
    scaffoldBackgroundColor: AppColors.secondary1,
  );
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.secondary1,
    scaffoldBackgroundColor: AppColors.primary1,
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
