import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_state.dart';
import '../widgets/volt_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History & Analytics')),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            );
          }

          if (state is HistoryLoaded) {
            if (state.logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Data Yet',
                      style: AppTypography.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete some workouts to see your stats.',
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: VoltCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.dayName,
                              style: AppTypography.textTheme.titleLarge
                                  ?.copyWith(color: AppColors.primaryAccent),
                            ),
                            Text(
                              _formatDate(log.startTime),
                              style: AppTypography.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.monitor_weight_outlined,
                                  size: 16,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${log.totalVolume.toStringAsFixed(0)} kg',
                                  style: AppTypography.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(log.totalDurationInSeconds),
                                  style: AppTypography.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: Text(
              'Failed to load history',
              style: TextStyle(color: AppColors.error),
            ),
          );
        },
      ),
    );
  }
}
