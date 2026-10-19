import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';

class TrainingHeading extends StatelessWidget {
  final String title;
  final IconData icon;
  const TrainingHeading({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.primaryAccent.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colors.primaryAccent, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    ],
  );
}
