import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1E40AF); // Vibrant Indigo
  static const Color primaryContainer = Color(0xFF3B82F6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF059669); // Emerald
  static const Color secondaryContainer = Color(0xFF10B981);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Light Mode Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF0F172A);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color outline = Color(0xFF94A3B8);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextMain = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF60A5FA);

  // Dynamic Context Helpers for Theme Responsiveness
  static Color bg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  static Color cardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : surfaceWhite;
  }

  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextMain
        : textMain;
  }

  static Color mutedText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextMuted
        : textMuted;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : borderSubtle;
  }

  static Color primaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimary
        : primary;
  }
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
