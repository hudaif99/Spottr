import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../data/models/workout_log.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_state.dart';
import '../blocs/history/history_event.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_state.dart';
import '../widgets/workout_value_control.dart';

class HistoryScreen extends StatelessWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: embedded ? null : AppBar(title: const Text('Progress')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoading || state is HistoryInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is! HistoryLoaded) {
                return Center(
                  child: TextButton(
                    onPressed: () =>
                        context.read<HistoryBloc>().add(LoadHistory()),
                    child: const Text('Retry loading history'),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Work adds up.',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('A clear record of the effort you put in.'),
                  const SizedBox(height: 32),
                  Text(
                    '${state.logs.length}',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  Text(
                    state.logs.length == 1
                        ? 'workout completed'
                        : 'workouts completed',
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  if (state.logs.isEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Your first workout starts the story.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Log a session and your completed sets will appear here.',
                    ),
                  ],
                  for (final log in state.logs)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      title: Text(
                        log.dayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text(
                        '${DateFormat('EEE, d MMM').format(log.startTime)} · ${log.totalDurationInSeconds ~/ 60} min · ${log.exerciseLogs.values.expand((sets) => sets).where((set) => set.isCompleted).length} sets',
                      ),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailScreen(log: log),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutLog log;
  const WorkoutDetailScreen({super.key, required this.log});
  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlansBloc>().state;
    final names = <String, String>{};
    if (plans is PlansLoaded) {
      for (final plan in plans.plans) {
        for (final day in plan.days) {
          for (final exercise in day.exercises) {
            names[exercise.id] = exercise.name;
          }
        }
      }
    }
    names.addAll(log.exerciseNames);
    return Scaffold(
      appBar: AppBar(title: const Text('Workout details')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(log.startTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  log.dayName,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  '${log.totalDurationInSeconds ~/ 60} min · ${formatWeight(log.totalVolume)} kg lifted',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                for (final entry in log.exerciseLogs.entries.where(
                  (entry) => entry.value.any((set) => set.isCompleted),
                )) ...[
                  Text(
                    names[entry.key] ?? 'Exercise from an earlier plan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final (index, set) in entry.value.indexed)
                    if (set.isCompleted)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${formatWeight(set.weight)} kg × ${set.reps} reps${set.isWarmup
                                    ? ' · warm-up'
                                    : set.isDropSet
                                    ? ' · drop set'
                                    : ''}',
                              ),
                            ),
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: context.colors.success,
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
