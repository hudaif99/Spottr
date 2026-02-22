import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors_extension.dart';

class AppTypography {
  static TextTheme getTextTheme(AppColorsExtension colors) {
    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.outfit(
        color: colors.secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: GoogleFonts.outfit(
        color: colors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
