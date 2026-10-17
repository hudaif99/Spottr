import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../domain/models/workout_log.dart';
import '../../domain/history_summary.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_state.dart';
import '../blocs/history/history_event.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_state.dart';
import '../widgets/workout_value_control.dart';
import 'exercise_progress_screen.dart';

String _duration(WorkoutLog log) {
  final duration = recordedWorkoutDuration(log);
  if (duration == null) return 'Duration unavailable';
  if (duration.inMinutes == 0) return 'Under 1 min';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
}

class HistoryScreen extends StatefulWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _exercises = false;

  void _openWorkout(WorkoutLog log) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => WorkoutDetailScreen(log: log)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded ? null : AppBar(title: const Text('Progress')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              if (widget.embedded)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Progress',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      selectedBackgroundColor: context.colors.primaryAccent,
                      selectedForegroundColor: context.colors.background,
                      foregroundColor: context.colors.primaryText,
                      side: BorderSide(color: context.colors.divider),
                    ),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Workouts')),
                      ButtonSegment(value: true, label: Text('Exercises')),
                    ],
                    selected: {_exercises},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _exercises = value.single),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<HistoryBloc, HistoryState>(
                  builder: (context, state) {
                    if (state is HistoryLoading || state is HistoryInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is! HistoryLoaded) {
                      return _HistoryMessage(
                        title: 'History could not load',
                        message:
                            'Your saved workouts could not be read. Try again.',
                        action: TextButton(
                          onPressed: () =>
                              context.read<HistoryBloc>().add(LoadHistory()),
                          child: const Text('Retry loading history'),
                        ),
                      );
                    }
                    if (state.logs.isEmpty) {
                      return const _HistoryMessage(
                        title: 'Your progress starts here',
                        message:
                            'Finish a workout to see your logged sets and session details here.',
                      );
                    }
                    if (_exercises) {
                      return ExerciseProgressList(
                        exercises: state.exercises,
                        openWorkout: _openWorkout,
                      );
                    }
                    final summary = HistorySummary.fromLogs(state.logs);
                    final groups = <DateTime, List<WorkoutLog>>{};
                    for (final log in state.logs) {
                      final month = DateTime(
                        log.startTime.year,
                        log.startTime.month,
                      );
                      groups.putIfAbsent(month, () => []).add(log);
                    }
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_Summary(summary: summary)],
                            ),
                          ),
                        ),
                        for (final group in groups.entries) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                DateFormat('MMMM yyyy').format(group.key),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList.builder(
                              itemCount: group.value.length,
                              itemBuilder: (context, index) =>
                                  _HistoryRow(log: group.value[index]),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HistoryMessage extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;
  const _HistoryMessage({
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.history_rounded,
          size: 32,
          color: context.colors.secondaryText,
        ),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(message),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  final HistorySummary summary;
  const _Summary({required this.summary});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All time', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 32,
          runSpacing: 20,
          children: [
            _Metric(
              value: '${summary.workouts}',
              label: summary.workouts == 1 ? 'workout saved' : 'workouts saved',
            ),
            _Metric(
              value: '${summary.completedSets}',
              label: summary.completedSets == 1 ? 'set logged' : 'sets logged',
            ),
            _Metric(value: formatWeight(summary.volume), label: 'kg lifted'),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WorkoutLog log;
  const _HistoryRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final summary = HistorySummary.fromLogs([log]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutDetailScreen(log: log)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d').format(log.startTime),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        DateFormat('EEE').format(log.startTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.dayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${summary.completedSets} ${summary.completedSets == 1 ? 'set' : 'sets'} logged',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _duration(log),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    final summary = HistorySummary.fromLogs([log]);
    final exercises = log.exerciseLogs.entries
        .where((entry) => entry.value.any((set) => set.isCompleted))
        .toList();
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
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _duration(log),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 32,
                  runSpacing: 20,
                  children: [
                    _Metric(
                      value: '${summary.completedSets}',
                      label: summary.completedSets == 1
                          ? 'set logged'
                          : 'sets logged',
                    ),
                    _Metric(
                      value: formatWeight(summary.volume),
                      label: 'kg lifted',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Only logged sets count toward these totals.'),
                const SizedBox(height: 32),
                if (exercises.isEmpty)
                  const Text('No completed sets were saved in this workout.'),
                for (final entry in exercises) ...[
                  Text(
                    names[entry.key] ?? 'Exercise from an earlier plan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final (index, set) in entry.value.indexed)
                    if (set.isCompleted)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text(
                                'Set ${index + 1}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formatWeight(set.weight)} kg × ${set.reps} reps',
                                  ),
                                  if (set.isWarmup || set.isDropSet)
                                    Text(
                                      [
                                        if (set.isWarmup) 'Warm-up',
                                        if (set.isDropSet) 'Drop set',
                                      ].join(', '),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_rounded,
                              semanticLabel: 'Logged',
                              size: 20,
                              color: context.colors.success,
                            ),
                          ],
                        ),
                      ),
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
