import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History & Analytics')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text('No Data Yet', style: AppTypography.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Complete some workouts to see your stats.',
              style: AppTypography.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
