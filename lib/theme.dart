import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00288E);
  static const Color primaryContainer = Color(0xFF1E40AF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFFFA929);
  static const Color outline = Color(0xFF757684);
}

class AppSpacing {
  static const double unit = 4.0;
  static const double stackSm = 8.0;
  static const double stackMd = 16.0;
  static const double gutter = 16.0;
  static const double cardPadding = 24.0;
  static const double containerMargin = 24.0;
  static const double sectionGap = 40.0;
}

class AppRadius {
  static const double sm = 4.0;
  static const double defaultValue = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

ThemeData getAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 48, letterSpacing: -0.02, color: AppColors.textMain),
      headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.01, color: AppColors.textMain),
      headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 24, color: AppColors.textMain),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 18, color: AppColors.textMain),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.textMain),
      bodySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: AppColors.textMuted),
      labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.01, color: AppColors.textMain),
      labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.02, color: AppColors.textMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
  );
}
