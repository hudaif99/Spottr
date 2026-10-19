import 'package:flutter/material.dart';

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
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    ],
  );
}
