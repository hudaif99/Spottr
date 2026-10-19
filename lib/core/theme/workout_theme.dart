import 'package:flutter/material.dart';
import 'app_colors_extension.dart';

/// Workout density adjustments use the same identity as the rest of Spottr.
abstract final class WorkoutTheme {
  static ThemeData from(ThemeData base) {
    final colors = base.extension<AppColorsExtension>()!;
    final text = base.textTheme;
    final scheme = base.colorScheme;
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
        style: base.filledButtonTheme.style!.copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
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
