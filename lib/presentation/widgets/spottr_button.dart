import 'package:spottr/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SpottrButtonVariant { primary, secondary, outline, ghost }

class SpottrButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SpottrButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  const SpottrButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SpottrButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<SpottrButton> createState() => _SpottrButtonState();
}

class _SpottrButtonState extends State<SpottrButton>
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
      case SpottrButtonVariant.primary:
        return context.colors.primaryAccent;
      case SpottrButtonVariant.secondary:
        return context.colors.surface;
      case SpottrButtonVariant.outline:
        return Colors.transparent;
      case SpottrButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case SpottrButtonVariant.primary:
        return context.colors.background;
      case SpottrButtonVariant.secondary:
      case SpottrButtonVariant.outline:
      case SpottrButtonVariant.ghost:
        return context.colors.primaryText;
    }
  }

  Border? get _border {
    if (widget.variant == SpottrButtonVariant.outline) {
      return Border.all(color: context.colors.divider, width: 1);
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
        child: Container(
          height: 56, // Large tap area
          decoration: BoxDecoration(
            color: isDisabled
                ? context.colors.surface.withOpacity(0.5)
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDisabled
                              ? context.colors.secondaryText
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
