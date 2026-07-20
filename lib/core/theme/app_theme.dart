import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get theme {
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
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        error: AppColors.error,
        onError: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 48, letterSpacing: -0.02, color: Colors.white),
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.01, color: Colors.white),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 24, color: Colors.white),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 18, color: Colors.white),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white),
        bodySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: Colors.white70),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.01, color: Colors.white),
        labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.02, color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
      ),
    );
  }
}
