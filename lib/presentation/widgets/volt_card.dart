import 'package:volt/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';

class VoltCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;
  final Color? borderColor;

  const VoltCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.color,
    this.hasBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder
            ? Border.all(color: borderColor ?? context.colors.divider)
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: context.colors.primaryAccent.withOpacity(0.1),
          highlightColor: context.colors.primaryAccent.withOpacity(0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
