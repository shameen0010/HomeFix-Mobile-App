import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same palette as `AppColors` in onboarding_screen.dart, plus admin extras.
class AdminColors {
  AdminColors._();
  static const primary = Color(0xFF11768F);
  static const dark = Color(0xFF0F2A43);
  static const grey = Color(0xFF6B7A8D);
  static const bg = Color(0xFFF6F8FF);
  static const chipBg = Color(0xFFDCEBFA);
  static const field = Color(0xFFEEF3FC);
  static const border = Color(0xFFE3E9F4);
  static const orange = Color(0xFFF59E0B);
  static const orangeBg = Color(0xFFFEF3C7);
  static const green = Color(0xFF10B981);
  static const greenBg = Color(0xFFD1FAE5);
  static const red = Color(0xFFDC2626);
  static const redBg = Color(0xFFFDE8E8);
}

class AdminConfig {
  AdminConfig._();
  static const currency = r'$';
  static const pageSize = 10;
  static const queryLimit = 500;
}

/// Poppins text style helper (use instead of raw TextStyle so weights load).
TextStyle ts(
  double size, {
  FontWeight w = FontWeight.w500,
  Color color = AdminColors.dark,
  double? height,
}) =>
    GoogleFonts.poppins(
        fontSize: size, fontWeight: w, color: color, height: height);

ThemeData? _cachedTheme;
ThemeData get adminTheme => _cachedTheme ??= _buildTheme();

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AdminColors.primary),
    scaffoldBackgroundColor: AdminColors.bg,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AdminColors.chipBg,
      elevation: 3,
      height: 68,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
