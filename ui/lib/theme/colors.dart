import 'package:flutter/material.dart';
import 'package:netlyra_ui/theme/typography.dart';

/// NetLyra Cyberpunk color palette.
class NetLyraColors {
  NetLyraColors._();

  // Core colors
  static const Color background = Color(0xFF020617); // Deep Abyss
  static const Color surface = Color(0xFF0F172A); // Elevated surface
  static const Color primary = Color(0xFF22C55E); // Terminal Green
  static const Color warning = Color(0xFFEF4444); // Emergency Red
  static const Color accent = Color(0xFF38BDF8); // Digital Cyan
  static const Color error = Color(0xFFEF4444); // Same as warning

  // Text colors
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Border colors
  static const Color border = Color(0xFF1E293B);
  static const Color borderAccent = Color(0xFF334155);
}

/// Build the Cyberpunk dark theme.
ThemeData buildNetLyraTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NetLyraColors.background,
    colorScheme: const ColorScheme.dark(
      surface: NetLyraColors.background,
      primary: NetLyraColors.primary,
      secondary: NetLyraColors.accent,
      error: NetLyraColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: NetLyraTypography.h1,
      displayMedium: NetLyraTypography.h2,
      displaySmall: NetLyraTypography.h3,
      bodyLarge: NetLyraTypography.body,
      bodyMedium: NetLyraTypography.body,
      bodySmall: NetLyraTypography.bodySmall,
      labelLarge: NetLyraTypography.mono,
    ),
    cardTheme: const CardThemeData(
      color: NetLyraColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: NetLyraColors.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NetLyraColors.background,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

