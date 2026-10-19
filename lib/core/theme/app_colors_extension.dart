import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color background;
  final Color surface;
  final Color success;
  final Color error;
  final Color primaryText;
  final Color secondaryText;
  final Color divider;

  const AppColorsExtension({
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.background,
    required this.surface,
    required this.success,
    required this.error,
    required this.primaryText,
    required this.secondaryText,
    required this.divider,
  });

  @override
  AppColorsExtension copyWith({
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? background,
    Color? surface,
    Color? success,
    Color? error,
    Color? primaryText,
    Color? secondaryText,
    Color? divider,
  }) {
    return AppColorsExtension(
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      success: success ?? this.success,
      error: error ?? this.error,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension AppColorsExtensionHelper on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  Color get accentForeground => Theme.of(this).brightness == Brightness.light
      ? colors.primaryText
      : colors.primaryAccent;
}
