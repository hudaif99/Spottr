import 'package:flutter/material.dart';
import 'app_colors_extension.dart';
import 'app_typography.dart';

/// Scoped to the workout anchor until the connected screens are reviewed.
abstract final class WorkoutTheme {
  static ThemeData from(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final colors = AppColorsExtension(
      primaryAccent: Color(dark ? 0xFFB2C1FF : 0xFF244CDC),
      secondaryAccent: Color(dark ? 0xFFB2C1FF : 0xFF244CDC),
      background: Color(dark ? 0xFF151922 : 0xFFF2F3F6),
      surface: Color(dark ? 0xFF222836 : 0xFFFFFFFF),
      success: Color(dark ? 0xFFB2C1FF : 0xFF244CDC),
      error: Color(dark ? 0xFFFFB4AB : 0xFFAD3028),
      primaryText: Color(dark ? 0xFFF3F5FF : 0xFF182136),
      secondaryText: Color(dark ? 0xFFB3BDD1 : 0xFF566178),
      divider: Color(dark ? 0xFF49546A : 0xFFCFD5E1),
    );
    final text = AppTypography.getTextTheme(colors);
    final scheme = base.colorScheme.copyWith(
      primary: colors.primaryAccent,
      onPrimary: Color(dark ? 0xFF172451 : 0xFFFFFFFF),
      surface: colors.surface,
      onSurface: colors.primaryText,
      onSurfaceVariant: colors.secondaryText,
      outline: colors.divider,
      error: colors.error,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge!.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.1,
          height: 1.08,
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colors.background,
        foregroundColor: colors.primaryText,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: text.titleMedium,
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: colors.background,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: colors.primaryText,
        contentTextStyle: TextStyle(color: colors.background),
        actionTextColor: colors.background,
      ),
    );
  }
}
