//===this file for constant value===
// example theme, localization, name routing, and other

import 'package:flutter/material.dart';

class AppColors {
  // === PRIMARY COLOR PALETTE - Vibrant Electric Blue ===
  // Base: RGB(33, 150, 243) - #2196F3 - Energetic untuk painting app
  static const primary1 = Color(0xFF2196F3); // #2196F3 - Electric blue yang vibrant
  static const primary2 = Color(0xFF1565C0); // Deep blue - lebih bold
  static const primary3 = Color(0xFF42A5F5); // Bright blue - energetic
  static const primary4 = Color(0xFF64B5F6); // Sky blue - playful
  static const primary5 = Color(0xFF90CAF9); // Light blue - soft accent
  
  // === COMPLEMENTARY COLORS - Creative & Vibrant Palette ===
  // Soft Cyan (Analogous) - untuk highlight & active states
  static const accent1 = Color(0xFF4DD0E1); // Soft cyan - friendly
  static const accent2 = Color(0xFF80DEEA); // Light cyan - gentle
  
  // Vibrant Orange (Complementary) - untuk CTAs & warmth
  static const accent3 = Color(0xFFFF6D00); // Vibrant orange - energetic
  static const accent4 = Color(0xFFFF9100); // Warm orange - friendly
  static const accent5 = Color(0xFFFFAB40); // Light orange - soft accent
  
  // Electric Purple (Triadic) - untuk creativity & premium feel
  static const accent6 = Color(0xFF9C27B0); // Electric purple - creative
  static const accent7 = Color(0xFFAB47BC); // Bright purple - artistic
  static const accent8 = Color(0xFFCE93D8); // Light purple - elegant
  
  // === LIGHT MODE - Bright & Colorful ===
  // Background colors - Clean white untuk canvas clarity
  static const lightBackground = Color(0xFFFAFAFA); // Off-white - soft on eyes
  static const lightSurface = Color(0xFFFFFFFF); // Pure white - clean canvas
  static const lightSurfaceVariant = Color(0xFFE3F2FD); // Pastel blue - subtle accent
  static const lightSurfaceHover = Color(0xFFBBDEFB); // Light blue hover - interactive
  
  // Primary variants - Vibrant & Playful
  static const lightPrimaryLight = Color(0xFF64B5F6); // Sky blue containers
  static const lightAccent = Color(0xFF00E5FF); // Neon cyan - eye-catching accents
  
  // Secondary colors - Electric blue derivatives
  static const lightSecondary = Color(0xFF1565C0); // Deep electric blue - bold
  static const lightSecondaryLight = Color(0xFF90CAF9); // Light sky blue - playful
  
  // Text colors - Strong contrast dengan personality
  static const lightTextPrimary = Color(0xFF0D47A1); // Deep blue - readable & vibrant
  static const lightTextSecondary = Color(0xFF1565C0); // Electric blue - engaging
  static const lightTextTertiary = Color(0xFF1976D2); // Medium blue - balanced
  static const lightTextDisabled = Color(0xFF90A4AE); // Blue grey - subtle
  
  // Border & Divider - Colorful tapi subtle
  static const lightBorder = Color(0xFFB0BEC5); // Blue-grey border - clear separation
  static const lightBorderVariant = Color(0xFFE0E0E0); // Light grey - minimal
  static const lightDivider = Color(0xFFBBDEFB); // Pastel blue - harmonious
  
  // State colors - Super Vibrant untuk feedback
  static const lightError = Color(0xFFD32F2F); // Vibrant red - clear warning
  static const lightSuccess = Color(0xFF388E3C); // Fresh green - positive
  static const lightWarning = Color(0xFFFF6D00); // Electric orange - attention
  static const lightInfo = Color(0xFF0288D1); // Info blue - helpful
  
  // Shadow colors - Subtle blue tint
  static const lightShadow = Color(0x1A2196F3); // 10% blue shadow
  static const lightShadowStrong = Color(0x332196F3); // 20% blue shadow
  
  // Overlay colors - Interactive feedback
  static const lightOverlay = Color(0x0A2196F3); // 4% blue hover
  static const lightOverlayStrong = Color(0x142196F3); // 8% blue pressed
  
  // Disabled state
  static const lightDisabled = Color(0xFFCFD8DC); // Light blue-grey
  static const lightOnDisabled = Color(0xFF90A4AE); // Medium blue-grey
  
  // === DARK MODE - True Dark (Proper Dark Mode) ===
  // Background colors - PROPER BLACK/DARK GREY
  static const darkBackground = Color(0xFF121212); // True black - OLED friendly
  static const darkSurface = Color(0xFF1E1E1E); // Dark grey - elevated surface
  static const darkSurfaceVariant = Color(0xFF2C2C2C); // Medium dark - cards
  static const darkSurfaceHover = Color(0xFF383838); // Lighter dark - interactive
  
  // Primary variants - Soft blue glow (bukan cyan)
  static const darkPrimary = Color(0xFF64B5F6); // Soft sky blue - kalem
  static const darkAccent = Color(0xFF90CAF9); // Light blue - gentle accent
  
  // Secondary - Soft blue untuk dark
  static const darkSecondary = Color(0xFF81C784); // Soft green alternative
  static const darkSecondaryAlt = Color(0xFF90CAF9); // Light blue - soft accent
  
  // Text colors - High contrast white/blue
  static const darkTextPrimary = Color(0xFFFFFFFF); // Pure white - maximum readability
  static const darkTextSecondary = Color(0xFFE3F2FD); // Very light blue - subtle
  static const darkTextTertiary = Color(0xFFB3E5FC); // Light cyan - playful
  static const darkTextDisabled = Color(0xFF616161); // Grey - clearly disabled
  
  // Border & Divider - Subtle tapi visible
  static const darkBorder = Color(0xFF424242); // Dark grey - clear separation
  static const darkBorderVariant = Color(0xFF303030); // Darker grey - minimal
  static const darkDivider = Color(0xFF2C2C2C); // Very dark - subtle division
  
  // State colors - Vibrant untuk dark background
  static const darkError = Color(0xFFEF5350); // Bright red - visible warning
  static const darkSuccess = Color(0xFF66BB6A); // Bright green - clear success
  static const darkWarning = Color(0xFFFFAB40); // Bright orange - attention
  static const darkInfo = Color(0xFF42A5F5); // Bright blue - helpful
  
  // Shadow colors - Black shadows
  static const darkShadow = Color(0x33000000); // 20% black
  static const darkShadowStrong = Color(0x4D000000); // 30% black
  
  // Overlay colors - Subtle blue glow
  static const darkOverlay = Color(0x0A42A5F5); // 4% blue hover
  static const darkOverlayStrong = Color(0x1442A5F5); // 8% blue pressed
  
  // Disabled state
  static const darkDisabled = Color(0xFF424242); // Dark grey
  static const darkOnDisabled = Color(0xFF757575); // Medium grey
  
  // === GRADIENT COLORS - Creative & Dynamic ===
  // Primary gradient - Soft blue flow
  static const gradientStart = Color(0xFF2196F3); // Electric blue
  static const gradientMiddle = Color(0xFF64B5F6); // Soft blue
  static const gradientEnd = Color(0xFF90CAF9); // Light blue
  
  // Creative gradients untuk painting app
  static const gradientOrangeStart = Color(0xFFFF6D00); // Vibrant orange
  static const gradientOrangeEnd = Color(0xFFFFAB40); // Light orange
  
  static const gradientPurpleStart = Color(0xFF9C27B0); // Electric purple
  static const gradientPurpleEnd = Color(0xFFCE93D8); // Light purple
  
  // Sunset gradient - Warm & Creative
  static const gradientSunsetStart = Color(0xFFFF6D00); // Orange
  static const gradientSunsetMiddle = Color(0xFFFF9100); // Warm orange
  static const gradientSunsetEnd = Color(0xFFFFAB40); // Light orange
  
  // === SEMANTIC COLORS - Clear Feedback ===
  static const success = Color(0xFF388E3C); // Fresh green - positive action
  static const warning = Color(0xFFFF6D00); // Electric orange - caution
  static const info = Color(0xFF0288D1); // Info blue - helpful hint
  static const error = Color(0xFFD32F2F); // Vibrant red - clear error
  
  // === ADDITIONAL UI COLORS ===
  static const amber = Color(0xFFFFA726); // Amber/Gold for ratings
  static const semiBlack = Color(0x8A000000); // Semi-transparent black for overlays
  static const mediumGrey = Color.fromARGB(255, 24, 24, 24); // Medium grey for subtle text
  
  // === LEGACY COLORS (for backward compatibility) ===
  static const secondary1 = Color(0xFF578FCA);
  static const tertiaryLight = Color(0xFF1B263B); // Light blue tint
  static const tertiaryDark = Color(0xFF1B263B); // Dark navy

  static Color tertiary3(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? tertiaryLight
        : tertiaryDark;
  }
  
  // Helper methods untuk mendapatkan warna sesuai theme
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightTextPrimary
        : darkTextPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightTextSecondary
        : darkTextSecondary;
  }
  
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightTextTertiary
        : darkTextTertiary;
  }
  
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightSurface
        : darkSurface;
  }
  
  static Color getSurfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightSurfaceVariant
        : darkSurfaceVariant;
  }
  
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightBackground
        : darkBackground;
  }
  
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primary1
        : darkPrimary;
  }
  
  static Color getAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightAccent
        : darkAccent;
  }
  
  static Color getError(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightError
        : darkError;
  }
  
  // Border & UI element helpers
  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightBorder
        : darkBorder;
  }
  
  static Color getBorderVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightBorderVariant
        : darkBorderVariant;
  }
  
  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightDivider
        : darkDivider;
  }
  
  static Color getShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightShadow
        : darkShadow;
  }
  
  static Color getOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightOverlay
        : darkOverlay;
  }
  
  static Color getDisabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightDisabled
        : darkDisabled;
  }
  
  static Color getTextDisabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightTextDisabled
        : darkTextDisabled;
  }
}

class ThemeConfig {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Primary colors
    primaryColor: AppColors.primary1,
    scaffoldBackgroundColor: AppColors.lightBackground,
    
    // Color scheme - Modern blue-based palette
    colorScheme: ColorScheme.light(
      primary: AppColors.primary1, // Main blue #2196F3
      primaryContainer: AppColors.lightPrimaryLight, // Light blue container
      secondary: AppColors.lightSecondary, // Darker blue - turunan dari primary
      secondaryContainer: AppColors.lightSecondaryLight, // Pastel blue
      tertiary: AppColors.accent1, // Vibrant cyan
      tertiaryContainer: AppColors.accent2, // Bright cyan
      surface: AppColors.lightSurface, // White
      surfaceVariant: AppColors.lightSurfaceVariant, // Light blue surface
      background: AppColors.lightBackground, // Blue-tinted white
      error: AppColors.lightError,
      onPrimary: AppColors.lightSurface, // White text on blue
      onPrimaryContainer: AppColors.lightTextPrimary, // Dark text on light blue
      onSecondary: AppColors.lightSurface, // White text on darker blue
      onSecondaryContainer: AppColors.lightTextPrimary, // Dark text on pastel blue
      onSurface: AppColors.lightTextPrimary, // Dark text on white
      onBackground: AppColors.lightTextPrimary, // Dark text on background
      onError: AppColors.lightSurface,
      outline: AppColors.lightBorder, // Blue-grey borders
      shadow: AppColors.lightShadow,
    ),
    
    // App bar theme - Modern gradient-ready blue
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary1,
      foregroundColor: AppColors.lightSurface,
      elevation: 0,
      centerTitle: false,
      shadowColor: AppColors.primary1.withOpacity(0.3),
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.lightSurface, size: 24),
      titleTextStyle: const TextStyle(
        color: AppColors.lightSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    ),
    
    // Card theme - Clean with subtle shadow
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shadowColor: AppColors.lightShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Elevated button theme - Bold and modern
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary1,
        foregroundColor: AppColors.lightSurface,
        elevation: 2,
        shadowColor: AppColors.primary1.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary1,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        side: const BorderSide(color: AppColors.primary1, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary1,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    
    // Input decoration theme - Modern with subtle backgrounds
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary1, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightDisabled, width: 1),
      ),
      labelStyle: const TextStyle(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: AppColors.lightTextTertiary, fontWeight: FontWeight.w400),
    ),
    
    // Bottom Navigation Bar - Clean and modern
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary1,
      unselectedItemColor: AppColors.lightTextTertiary,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      showUnselectedLabels: true,
    ),
    
    // Navigation Rail theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedIconTheme: const IconThemeData(color: AppColors.primary1, size: 28),
      unselectedIconTheme: IconThemeData(color: AppColors.lightTextTertiary, size: 24),
      selectedLabelTextStyle: const TextStyle(color: AppColors.primary1, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500),
    ),
    
    // FAB theme - Prominent action
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary1,
      foregroundColor: AppColors.lightSurface,
      elevation: 4,
      hoverElevation: 6,
      focusElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceVariant,
      selectedColor: AppColors.lightPrimaryLight,
      labelStyle: const TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: AppColors.lightSurface, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    
    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.primary1,
      size: 24,
    ),
    
    // Text theme - Optimized hierarchy
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w800, fontSize: 57, letterSpacing: -0.5),
      displayMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w800, fontSize: 45, letterSpacing: -0.5),
      displaySmall: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 36),
      headlineLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 32),
      headlineMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 28),
      headlineSmall: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 24),
      titleLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 0),
      titleMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.15),
      titleSmall: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
      bodyLarge: TextStyle(color: AppColors.lightTextPrimary, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: AppColors.lightTextPrimary, fontSize: 14, letterSpacing: 0.25, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: AppColors.lightTextSecondary, fontSize: 12, letterSpacing: 0.4, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
      labelMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5),
      labelSmall: TextStyle(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 1,
    ),
    
    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary1,
      linearTrackColor: AppColors.lightSurfaceVariant,
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightTextPrimary,
      contentTextStyle: const TextStyle(color: AppColors.lightSurface, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Primary colors
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    // Color scheme - Modern dark with blue accents
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary, // Bright blue
      primaryContainer: AppColors.darkPrimary, // Bright blue container
      secondary: AppColors.darkSecondary, // Very light blue - turunan dari primary
      secondaryContainer: AppColors.darkSecondaryAlt, // Pastel blue alternative
      tertiary: AppColors.darkAccent, // Neon cyan
      tertiaryContainer: AppColors.accent2, // Bright cyan
      surface: AppColors.darkSurface, // Navy surface
      surfaceVariant: AppColors.darkSurfaceVariant, // Elevated navy
      background: AppColors.darkBackground, // Deep navy
      error: AppColors.darkError,
      onPrimary: AppColors.darkBackground, // Dark text on bright blue
      onPrimaryContainer: AppColors.darkTextPrimary, // Light text on blue
      onSecondary: AppColors.darkBackground, // Dark text on light blue
      onSecondaryContainer: AppColors.darkTextPrimary, // Light text on pastel blue
      onSurface: AppColors.darkTextPrimary, // Light text on dark surface
      onBackground: AppColors.darkTextPrimary, // Light text on dark background
      onError: AppColors.darkSurface,
      outline: AppColors.darkBorder, // Dark blue-grey borders
      shadow: AppColors.darkShadow,
    ),
    
    // App bar theme - Premium dark
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      shadowColor: AppColors.darkShadowStrong,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      titleTextStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    ),
    
    // Card theme - Elevated with glow
    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceVariant,
      elevation: 0,
      shadowColor: AppColors.darkShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Elevated button theme - Glowing blue
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkBackground,
        elevation: 3,
        shadowColor: AppColors.darkPrimary.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        side: const BorderSide(color: AppColors.darkPrimary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    
    // Input decoration theme - Dark with subtle glow
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkDisabled, width: 1),
      ),
      labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: AppColors.darkTextTertiary, fontWeight: FontWeight.w400),
    ),
    
    // Bottom Navigation Bar - Premium dark
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.darkPrimary,
      unselectedItemColor: AppColors.darkTextTertiary,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      showUnselectedLabels: true,
    ),
    
    // Navigation Rail theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedIconTheme: const IconThemeData(color: AppColors.darkPrimary, size: 28),
      unselectedIconTheme: IconThemeData(color: AppColors.darkTextTertiary, size: 24),
      selectedLabelTextStyle: const TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500),
    ),
    
    // FAB theme - Bright accent
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkBackground,
      elevation: 4,
      hoverElevation: 6,
      focusElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      selectedColor: AppColors.darkPrimary,
      labelStyle: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    
    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.darkPrimary,
      size: 24,
    ),
    
    // Text theme - Optimized for dark backgrounds
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w800, fontSize: 57, letterSpacing: -0.5),
      displayMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w800, fontSize: 45, letterSpacing: -0.5),
      displaySmall: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 36),
      headlineLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 32),
      headlineMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 28),
      headlineSmall: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 24),
      titleLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 0),
      titleMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.15),
      titleSmall: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: AppColors.darkTextPrimary, fontSize: 14, letterSpacing: 0.25, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, letterSpacing: 0.4, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
      labelMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5),
      labelSmall: TextStyle(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),
    
    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.darkPrimary,
      linearTrackColor: AppColors.darkSurfaceVariant,
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

abstract class ThemeManager {
  static ThemeManager of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? LightModeTheme() : DarkModeTheme();
  }

  // Primary colors
  Color get primary;
  Color get primaryLight;
  Color get accent;
  
  // Alias for compatibility
  Color get primary1 => primary;
  Color get primary2 => primaryLight;
  
  // Secondary colors
  Color get secondary;
  Color get secondaryLight;
  Color get secondaryAlt;
  
  // Alias for compatibility
  Color get secondary1 => secondary;
  Color get secondary2 => secondaryLight;
  
  // Tertiary/Accent alias
  Color get tertiary1 => accent;
  
  // Background & Surface
  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get surfaceHover;
  
  // Text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textDisabled;
  
  // Border & Divider
  Color get border;
  Color get borderVariant;
  Color get divider;
  
  // State colors
  Color get error;
  Color get success;
  Color get warning;
  Color get info;
  
  // Shadow & Overlay
  Color get shadow;
  Color get shadowStrong;
  Color get overlay;
  Color get overlayStrong;
  
  // Disabled state
  Color get disabled;
  Color get onDisabled;
  
  // Gradient colors
  Color get gradientStart;
  Color get gradientMiddle;
  Color get gradientEnd;
}

class LightModeTheme extends ThemeManager {
  @override
  Color get primary => AppColors.primary1;
  @override
  Color get primaryLight => AppColors.lightPrimaryLight;
  @override
  Color get accent => AppColors.lightAccent;
  
  @override
  Color get secondary => AppColors.lightSecondary;
  @override
  Color get secondaryLight => AppColors.lightSecondaryLight;
  @override
  Color get secondaryAlt => AppColors.primary3; // Lighter blue alternative
  
  @override
  Color get background => AppColors.lightBackground;
  @override
  Color get surface => AppColors.lightSurface;
  @override
  Color get surfaceVariant => AppColors.lightSurfaceVariant;
  @override
  Color get surfaceHover => AppColors.lightSurfaceHover;
  
  @override
  Color get textPrimary => AppColors.lightTextPrimary;
  @override
  Color get textSecondary => AppColors.lightTextSecondary;
  @override
  Color get textTertiary => AppColors.lightTextTertiary;
  @override
  Color get textDisabled => AppColors.lightTextDisabled;
  
  @override
  Color get border => AppColors.lightBorder;
  @override
  Color get borderVariant => AppColors.lightBorderVariant;
  @override
  Color get divider => AppColors.lightDivider;
  
  @override
  Color get error => AppColors.lightError;
  @override
  Color get success => AppColors.lightSuccess;
  @override
  Color get warning => AppColors.lightWarning;
  @override
  Color get info => AppColors.lightInfo;
  
  @override
  Color get shadow => AppColors.lightShadow;
  @override
  Color get shadowStrong => AppColors.lightShadowStrong;
  @override
  Color get overlay => AppColors.lightOverlay;
  @override
  Color get overlayStrong => AppColors.lightOverlayStrong;
  
  @override
  Color get disabled => AppColors.lightDisabled;
  @override
  Color get onDisabled => AppColors.lightOnDisabled;
  
  @override
  Color get gradientStart => AppColors.gradientStart;
  @override
  Color get gradientMiddle => AppColors.gradientMiddle;
  @override
  Color get gradientEnd => AppColors.gradientEnd;
}

class DarkModeTheme extends ThemeManager {
  @override
  Color get primary => AppColors.darkPrimary;
  @override
  Color get primaryLight => AppColors.darkPrimary;
  @override
  Color get accent => AppColors.darkAccent;
  
  @override
  Color get secondary => AppColors.darkSecondary;
  @override
  Color get secondaryLight => AppColors.darkSecondaryAlt;
  @override
  Color get secondaryAlt => AppColors.primary3; // Lighter blue alternative
  
  @override
  Color get background => AppColors.darkBackground;
  @override
  Color get surface => AppColors.darkSurface;
  @override
  Color get surfaceVariant => AppColors.darkSurfaceVariant;
  @override
  Color get surfaceHover => AppColors.darkSurfaceHover;
  
  @override
  Color get textPrimary => AppColors.darkTextPrimary;
  @override
  Color get textSecondary => AppColors.darkTextSecondary;
  @override
  Color get textTertiary => AppColors.darkTextTertiary;
  @override
  Color get textDisabled => AppColors.darkTextDisabled;
  
  @override
  Color get border => AppColors.darkBorder;
  @override
  Color get borderVariant => AppColors.darkBorderVariant;
  @override
  Color get divider => AppColors.darkDivider;
  
  @override
  Color get error => AppColors.darkError;
  @override
  Color get success => AppColors.darkSuccess;
  @override
  Color get warning => AppColors.darkWarning;
  @override
  Color get info => AppColors.darkInfo;
  
  @override
  Color get shadow => AppColors.darkShadow;
  @override
  Color get shadowStrong => AppColors.darkShadowStrong;
  @override
  Color get overlay => AppColors.darkOverlay;
  @override
  Color get overlayStrong => AppColors.darkOverlayStrong;
  
  @override
  Color get disabled => AppColors.darkDisabled;
  @override
  Color get onDisabled => AppColors.darkOnDisabled;
  
  @override
  Color get gradientStart => AppColors.gradientStart;
  @override
  Color get gradientMiddle => AppColors.gradientMiddle;
  @override
  Color get gradientEnd => AppColors.gradientEnd;
}
