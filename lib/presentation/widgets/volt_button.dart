import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum VoltButtonVariant { primary, secondary, outline, ghost }

class VoltButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final VoltButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  const VoltButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = VoltButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<VoltButton> createState() => _VoltButtonState();
}

class _VoltButtonState extends State<VoltButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  Color get _backgroundColor {
    switch (widget.variant) {
      case VoltButtonVariant.primary:
        return AppColors.primaryAccent;
      case VoltButtonVariant.secondary:
        return AppColors.surface;
      case VoltButtonVariant.outline:
        return Colors.transparent;
      case VoltButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case VoltButtonVariant.primary:
        return AppColors.background;
      case VoltButtonVariant.secondary:
      case VoltButtonVariant.outline:
      case VoltButtonVariant.ghost:
        return AppColors.primaryText;
    }
  }

  Border? get _border {
    if (widget.variant == VoltButtonVariant.outline) {
      return Border.all(color: AppColors.divider, width: 1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : _onTapDown,
      onTapUp: isDisabled ? null : _onTapUp,
      onTapCancel: isDisabled ? null : _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 56, // Large tap area
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.surface.withOpacity(0.5)
                : _backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: _border,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: isDisabled
                              ? AppColors.secondaryText
                              : _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
