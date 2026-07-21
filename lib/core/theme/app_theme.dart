import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ── LIGHT THEME ────────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textMain,
        outline: AppColors.borderSubtle,
        onSurfaceVariant: AppColors.textMuted,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 48, letterSpacing: -0.02, color: AppColors.textMain),
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.01, color: AppColors.textMain),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 24, color: AppColors.textMain),
        titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.textMain),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textMain),
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
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textMain),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceWhite,
        textStyle: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.borderSubtle)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMain),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textMain,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 8,
      ),
    );
  }

  // ── DARK THEME ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: Color(0xFF0F172A),
        primaryContainer: Color(0xFF1E3A8A),
        secondary: Color(0xFF10B981),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF065F46),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextMain,
        outline: AppColors.darkBorder,
        onSurfaceVariant: AppColors.darkTextMuted,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 48, letterSpacing: -0.02, color: AppColors.darkTextMain),
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.01, color: AppColors.darkTextMain),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 24, color: AppColors.darkTextMain),
        titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.darkTextMain),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.darkTextMain),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 18, color: AppColors.darkTextMain),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.darkTextMain),
        bodySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: AppColors.darkTextMuted),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.01, color: AppColors.darkTextMain),
        labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.02, color: AppColors.darkTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkPrimary),
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.darkTextMain),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        textStyle: const TextStyle(color: AppColors.darkTextMain, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.darkBorder)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: const TextStyle(color: AppColors.darkTextMuted),
        labelStyle: const TextStyle(color: AppColors.darkTextMain),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue), borderSide: const BorderSide(color: AppColors.darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue), borderSide: const BorderSide(color: AppColors.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue), borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkPrimary,
        textColor: AppColors.darkTextMain,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextMuted,
        elevation: 8,
      ),
    );
  }
}
