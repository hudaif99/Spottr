import 'package:flutter/material.dart';
import 'app_colors_extension.dart';

class AppTypography {
  static TextTheme getTextTheme(AppColorsExtension colors) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Outfit',
        color: colors.secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Outfit',
        color: colors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
