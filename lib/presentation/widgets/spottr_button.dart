import 'package:flutter/material.dart';

enum SpottrButtonVariant { primary, secondary, outline, ghost }

class SpottrButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: Semantics(
              label: '$text in progress',
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 10)],
              Flexible(child: Text(text, textAlign: TextAlign.center)),
            ],
          );
    final action = isLoading ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      child: switch (variant) {
        SpottrButtonVariant.primary => FilledButton(
          onPressed: action,
          child: child,
        ),
        SpottrButtonVariant.secondary => FilledButton.tonal(
          onPressed: action,
          child: child,
        ),
        SpottrButtonVariant.outline => OutlinedButton(
          onPressed: action,
          child: child,
        ),
        SpottrButtonVariant.ghost => TextButton(
          onPressed: action,
          child: child,
        ),
      },
    );
  }
}
