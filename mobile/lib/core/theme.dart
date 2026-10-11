import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TamBourColors {
  TamBourColors._();
  static const Color primary = Color(0xFF0A7C4E);
  static const Color primaryDark = Color(0xFF075C39);
  static const Color primaryLight = Color(0xFFF0FBF6);
  /// Vert et or du logo TamBour.
  static const Color marque = Color(0xFF0F4A3B);
  static const Color gold = Color(0xFFF2A93B);
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
  static const Color warning = Color(0xFFF2A93B);
  static const Color divider = Color(0xFFF0F0EE);
}

class TamBourTheme {
  TamBourTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TamBourColors.primary,
        brightness: Brightness.light,
        primary: TamBourColors.primary,
        onPrimary: Colors.white,
        secondary: TamBourColors.gold,
        surface: TamBourColors.surface,
        background: TamBourColors.background,
        error: TamBourColors.error,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: TamBourColors.background,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: TamBourColors.textPrimary, height: 1.2),
        displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary, height: 1.3),
        headlineLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary),
        headlineMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: TamBourColors.textPrimary),
        titleLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: TamBourColors.textPrimary),
        titleMedium: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: TamBourColors.textPrimary),
        bodyLarge: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w400, color: TamBourColors.textPrimary, height: 1.6),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: TamBourColors.textSecondary, height: 1.5),
        bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: TamBourColors.textHint),
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
          backgroundColor: TamBourColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TamBourColors.primary,
          side: const BorderSide(color: TamBourColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TamBourColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.outfit(color: TamBourColors.textHint, fontSize: 14),
        errorStyle: GoogleFonts.outfit(color: TamBourColors.error, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: TamBourColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: TamBourColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: TamBourColors.divider, thickness: 1, space: 0),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: TamBourColors.surface,
        selectedItemColor: TamBourColors.primary,
        unselectedItemColor: TamBourColors.textHint,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w400),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
