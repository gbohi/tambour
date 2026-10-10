import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class YoBusColors {
  YoBusColors._();
  static const Color primary = Color(0xFF0A7C4E);
  static const Color primaryDark = Color(0xFF075C39);
  static const Color primaryLight = Color(0xFFF0FBF6);
  static const Color gold = Color(0xFFF5A623);
  static const Color goldLight = Color(0xFFFFF8EC);
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4F4F2);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color border = Color(0xFFE8E8E6);
  static const Color success = Color(0xFF0A7C4E);
  static const Color error = Color(0xFFD94040);
  static const Color warning = Color(0xFFF5A623);
  static const Color divider = Color(0xFFF0F0EE);
}

class YoBusTheme {
  YoBusTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YoBusColors.primary,
        brightness: Brightness.light,
        primary: YoBusColors.primary,
        onPrimary: Colors.white,
        secondary: YoBusColors.gold,
        surface: YoBusColors.surface,
        background: YoBusColors.background,
        error: YoBusColors.error,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: YoBusColors.background,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: YoBusColors.textPrimary, height: 1.2),
        displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary, height: 1.3),
        headlineLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary),
        headlineMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: YoBusColors.textPrimary),
        titleLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: YoBusColors.textPrimary),
        titleMedium: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: YoBusColors.textPrimary),
        bodyLarge: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w400, color: YoBusColors.textPrimary, height: 1.6),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: YoBusColors.textSecondary, height: 1.5),
        bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: YoBusColors.textHint),
        labelLarge: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YoBusColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YoBusColors.primary,
          side: const BorderSide(color: YoBusColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YoBusColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YoBusColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YoBusColors.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YoBusColors.error, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.outfit(color: YoBusColors.textHint, fontSize: 14),
        errorStyle: GoogleFonts.outfit(color: YoBusColors.error, fontSize: 12),
      ),
      cardTheme: CardTheme(
        color: YoBusColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: YoBusColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: YoBusColors.divider, thickness: 1, space: 0),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: YoBusColors.surface,
        selectedItemColor: YoBusColors.primary,
        unselectedItemColor: YoBusColors.textHint,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w400),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
