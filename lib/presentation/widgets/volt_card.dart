import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VoltCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;

  const VoltCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.color,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: AppColors.divider) : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryAccent.withOpacity(0.1),
          highlightColor: AppColors.primaryAccent.withOpacity(0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
