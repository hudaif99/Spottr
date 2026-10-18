import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../domain/exercise_progress.dart';
import '../../domain/models/set_log.dart';
import '../../domain/models/workout_log.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event.dart';
import '../blocs/history/history_state.dart';
import '../widgets/workout_value_control.dart';

String _performance(SetLog set) =>
    '${formatWeight(set.weight)} kg × ${set.reps} reps';

class ExerciseProgressList extends StatefulWidget {
  final List<ExerciseProgress> exercises;
  final ValueChanged<WorkoutLog> openWorkout;

  const ExerciseProgressList({
    super.key,
    required this.exercises,
    required this.openWorkout,
  });

  @override
  State<ExerciseProgressList> createState() => _ExerciseProgressListState();
}

class _ExerciseProgressListState extends State<ExerciseProgressList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercises = widget.exercises
        .where(
          (exercise) =>
              exercise.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise history',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (exercises.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Text(
                widget.exercises.isEmpty
                    ? 'Log a set in a workout to start your exercise history.'
                    : 'No exercises match your search.',
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                title: Text(exercise.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text('Best  ${_performance(exercise.best)}'),
                    Text(
                      '${exercise.sessions.length} ${exercise.sessions.length == 1 ? 'workout' : 'workouts'} · ${DateFormat.yMMMd().format(exercise.sessions.first.workout.startTime)}',
                    ),
                    if (exercise.isLegacy) const Text('Earlier records'),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<HistoryBloc>(),
                        child: ExerciseProgressScreen(
                          exerciseKey: exercise.key,
                          openWorkout: widget.openWorkout,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ExerciseProgressScreen extends StatelessWidget {
  final ExerciseProgressKey exerciseKey;
  final ValueChanged<WorkoutLog> openWorkout;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseKey,
    required this.openWorkout,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exercise progress')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryInitial || state is HistoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is! HistoryLoaded) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Exercise history could not load.'),
                      TextButton(
                        onPressed: () =>
                            context.read<HistoryBloc>().add(LoadHistory()),
                        child: const Text('Retry loading history'),
                      ),
                    ],
                  ),
                );
              }
              final matches = state.exercises.where(
                (exercise) => exercise.key == exerciseKey,
              );
              if (matches.isEmpty) {
                return const SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No logged sets for this exercise in your saved history.',
                  ),
                );
              }
              final exercise = matches.first;
              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: exercise.sessions.length + 1,
                itemBuilder: (context, index) => index == 0
                    ? _ExerciseOverview(exercise: exercise)
                    : _SessionDetails(
                        session: exercise.sessions[index - 1],
                        openWorkout: openWorkout,
                      ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _ExerciseOverview extends StatelessWidget {
  final ExerciseProgress exercise;
  const _ExerciseOverview({required this.exercise});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(exercise.name, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      Container(
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
            const Text('Best logged set'),
            const SizedBox(height: 8),
            Text(
              _performance(exercise.best),
              style: MediaQuery.textScalerOf(context).scale(14) > 20
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineSmall,
            ),
            if (exercise.best.isWarmup) const Text('Warm-up'),
            if (exercise.best.isDropSet) const Text('Drop set'),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().format(exercise.bestDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '${exercise.sessions.length} ${exercise.sessions.length == 1 ? 'workout' : 'workouts'} · ${exercise.completedSets} ${exercise.completedSets == 1 ? 'set' : 'sets'} logged',
      ),
      const SizedBox(height: 12),
      Text(
        'Heaviest set; reps break ties. Includes logged warm-ups and drop sets.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (exercise.isLegacy) ...[
        const SizedBox(height: 12),
        const Text(
          'These older sets are grouped separately to keep your history accurate.',
        ),
      ],
      const SizedBox(height: 32),
      Text('Past workouts', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
    ],
  );
}

class _SessionDetails extends StatelessWidget {
  final ExerciseSession session;
  final ValueChanged<WorkoutLog> openWorkout;
  const _SessionDetails({required this.session, required this.openWorkout});

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey('exercise-session-${session.workout.id}'),
    expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    title: Text(DateFormat.yMMMd().format(session.workout.startTime)),
    subtitle: Text(
      '${session.workout.dayName}\n${session.sets.length} ${session.sets.length == 1 ? 'set' : 'sets'} · Best ${_performance(session.best)}',
    ),
    children: [
      for (final entry in session.sets)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set ${entry.number}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (session.sets.any(
                      (other) => other.entryId != entry.entryId,
                    ))
                      Text(
                        session.workout.exerciseNames[entry.entryId] ??
                            'Exercise',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_performance(entry.set)),
                    if (entry.set.isWarmup) const Text('Warm-up'),
                    if (entry.set.isDropSet) const Text('Drop set'),
                  ],
                ),
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => openWorkout(session.workout),
          child: const Text('View workout'),
        ),
      ),
    ],
  );
}
