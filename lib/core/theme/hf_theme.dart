import 'package:flutter/material.dart';

class HfColors {
  // Primary colors
  static const primary = Color(0xFF11768F);
  static const primarySoft = Color(0xFFE8F4FD);
  static const primaryDark = Color(0xFF0B5F7A);

  // Secondary colors
  static const orange = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const emergency = Color(0xFFEF4444);

  // New colors from auth screens
  static const peach = Color(0xFFFCD5B8);
  static const gold = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Neutral colors
  static const navy = Color(0xFF0F2A43);
  static const dark = Color(0xFF1E293B);
  static const grey = Color(0xFF6B7A8D);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const field = Color(0xFFF1F5F9);
  static const bg = Color(0xFFF6F8FF);

  // Status colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
}

class HfTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HfColors.primary,
        primary: HfColors.primary,
        secondary: HfColors.orange,
        surface: HfColors.bg,
        background: HfColors.bg,
      ),
      scaffoldBackgroundColor: HfColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: HfColors.bg,
        elevation: 0,
        foregroundColor: HfColors.navy,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HfColors.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HfColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: HfColors.navy,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: HfColors.navy,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: HfColors.navy,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: HfColors.navy,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: HfColors.navy,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: HfColors.navy,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: HfColors.dark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: HfColors.dark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: HfColors.grey,
        ),
      ),
    );
  }
}
