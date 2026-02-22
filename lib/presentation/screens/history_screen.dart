import 'package:volt/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            return Center(
              child: CircularProgressIndicator(color: context.colors.primaryAccent),
            );
          }

          if (state is HistoryLoaded) {
            if (state.logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: context.colors.divider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Data Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete some workouts to see your stats.',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: context.colors.primaryAccent),
                            ),
                            Text(
                              _formatDate(log.startTime),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: context.colors.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.monitor_weight_outlined,
                                  size: 16,
                                  color: context.colors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${log.totalVolume.toStringAsFixed(0)} kg',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: context.colors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(log.totalDurationInSeconds),
                                  style: Theme.of(context).textTheme.bodyLarge,
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

          return Center(
            child: Text(
              'Failed to load history',
              style: TextStyle(color: context.colors.error),
            ),
          );
        },
      ),
    );
  }
}
