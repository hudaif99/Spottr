import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'app_typography.dart';

class AppTheme {
  static final AppColorsExtension _darkColors = const AppColorsExtension(
    primaryAccent: AppColors.primaryAccent,
    secondaryAccent: AppColors.secondaryAccent,
    background: AppColors.background,
    surface: AppColors.surface,
    success: AppColors.success,
    error: AppColors.error,
    primaryText: AppColors.primaryText,
    secondaryText: AppColors.secondaryText,
    divider: AppColors.divider,
  );

  static final AppColorsExtension _lightColors = const AppColorsExtension(
    primaryAccent: Color(0xFF6B9900), // Darker lime for contrast
    secondaryAccent: Color(0xFF00AA6E), // Darker green
    background: Color(0xFFF2F2F7), // Light gray background
    surface: Color(0xFFFFFFFF), // White surface
    success: Color(0xFF2ECC71),
    error: Color(0xFFFF3B3B),
    primaryText: Color(0xFF000000), // Black text
    secondaryText: Color(0xFF8E8E93), // Gray secondary text
    divider: Color(0xFFE5E5EA), // Light divider
  );

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark, _darkColors);
  }

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light, _lightColors);
  }

  static ThemeData _buildTheme(
    Brightness brightness,
    AppColorsExtension colors,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: colors.primaryAccent,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primaryAccent,
        brightness: brightness,
        primary: colors.primaryAccent,
        secondary: colors.secondaryAccent,
        surface: colors.surface,
        error: colors.error,
        onPrimary: colors.background,
        onSecondary: colors.background,
        onSurface: colors.primaryText,
        onError: colors.primaryText,
      ),
      textTheme: AppTypography.getTextTheme(colors),
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: colors.background,
          elevation: 0,
          textStyle: AppTypography.getTextTheme(colors).labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.background,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
