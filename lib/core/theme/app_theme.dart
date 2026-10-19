import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'app_typography.dart';

class AppTheme {
  static const _darkColors = AppColorsExtension(
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
  static const _lightColors = AppColorsExtension(
    primaryAccent: Color(0xFFAC3E16),
    secondaryAccent: Color(0xFFAC3E16),
    background: Color(0xFFF4F3EE),
    surface: Color(0xFFFFFFFF),
    success: Color(0xFF3E6543),
    error: Color(0xFFAE342C),
    primaryText: Color(0xFF20241F),
    secondaryText: Color(0xFF5D655C),
    divider: Color(0xFFD3D7CF),
  );
  static ThemeData get darkTheme => _buildTheme(Brightness.dark, _darkColors);
  static ThemeData get lightTheme =>
      _buildTheme(Brightness.light, _lightColors);

  static ThemeData _buildTheme(
    Brightness brightness,
    AppColorsExtension colors,
  ) {
    final text = AppTypography.getTextTheme(colors);
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primaryAccent,
      brightness: brightness,
      primary: colors.primaryAccent,
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF25170F)
          : Colors.white,
      secondary: colors.secondaryAccent,
      surface: colors.surface,
      onSurface: colors.primaryText,
      onSurfaceVariant: colors.secondaryText,
      outline: colors.divider,
      error: colors.error,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: text,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: shape,
          textStyle: text.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          shape: shape,
          side: BorderSide(color: colors.divider),
          foregroundColor: colors.primaryText,
          textStyle: text.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        elevation: 0,
        indicatorColor: colors.primaryAccent.withValues(alpha: .12),
        labelTextStyle: WidgetStatePropertyAll(text.labelLarge),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primaryAccent
                : colors.secondaryText,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.background,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 640),
      ),
    );
  }
}
