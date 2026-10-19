import 'package:flutter/material.dart';
import 'app_colors_extension.dart';

class AppTypography {
  static TextTheme getTextTheme(AppColorsExtension colors) {
    TextStyle style(
      double size,
      FontWeight weight, {
      bool secondary = false,
      double spacing = 0,
    }) => TextStyle(
      fontFamily: 'Outfit',
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
      letterSpacing: spacing,
      color: secondary ? colors.secondaryText : colors.primaryText,
    );
    return TextTheme(
      displayLarge: style(48, FontWeight.w600, spacing: -1.8),
      displayMedium: style(38, FontWeight.w600, spacing: -1.2),
      displaySmall: style(32, FontWeight.w600, spacing: -.8),
      headlineLarge: style(32, FontWeight.w700, spacing: -1),
      headlineMedium: style(28, FontWeight.w700, spacing: -.7),
      headlineSmall: style(22, FontWeight.w600),
      titleLarge: style(20, FontWeight.w600),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400, secondary: true),
      bodySmall: style(12, FontWeight.w400, secondary: true),
      labelLarge: style(14, FontWeight.w600),
      labelMedium: style(12, FontWeight.w600, secondary: true),
      labelSmall: style(11, FontWeight.w600, secondary: true),
    );
  }
}
