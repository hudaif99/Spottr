import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_log.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_event.dart';
import '../blocs/workout/workout_state.dart';
import '../blocs/timer/timer_bloc.dart';
import '../blocs/timer/timer_event.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/spottr_button.dart';
import '../widgets/previous_set_summary.dart';
import '../widgets/workout_value_control.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});
  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  String? _selectedExerciseId;
  int get _selected {
    final state = context.read<WorkoutBloc>().state;
    if (state is! WorkoutInProgress) return 0;
    final index = state.day.exercises.indexWhere(
      (exercise) => exercise.id == _selectedExerciseId,
    );
    return index < 0 ? 0 : index;
  }

  String? _editingSet;
  bool _hadSession = false;
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<SettingsBloc>().state.keepScreenAwake) {
        WakelockPlus.enable().catchError((_) {});
      }
      final state = context.read<WorkoutBloc>().state;
      if (state is WorkoutInProgress) {
        final unfinished = state.day.exercises.indexWhere(
          (exercise) => (state.exerciseLogs[exercise.id] ?? []).any(
            (set) => !set.isCompleted,
          ),
        );
        if (unfinished >= 0) _select(unfinished);
        _syncRest(state);
      }
    });
  }

  void _syncRest(WorkoutInProgress state) {
    final until = state.restUntil;
    if (until != null && until.isAfter(DateTime.now())) {
      context.read<TimerBloc>().add(
        StartRestTimer(until.difference(DateTime.now()).inSeconds + 1),
      );
    } else {
      context.read<TimerBloc>().add(ResetTimer());
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _select(int index) => setState(() {
    final state = context.read<WorkoutBloc>().state;
    if (state is! WorkoutInProgress ||
        index < 0 ||
        index >= state.day.exercises.length) {
      return;
    }
    _selectedExerciseId = state.day.exercises[index].id;
    _editingSet = null;
  });

  Future<void> _editExercise(Exercise exercise, bool hasCompleted) async {
    final updated = await showExerciseEditor(
      context,
      exercise: exercise,
      lockName: hasCompleted,
    );
    if (updated != null && mounted) {
      context.read<WorkoutBloc>().add(EditSessionExercise(updated));
    }
  }

  Future<void> _addExercise() async {
    final state = context.read<WorkoutBloc>().state;
    final exercise = await showExercisePicker(
      context,
      localExercises: state is WorkoutInProgress
          ? state.day.exercises
          : const [],
    );
    if (exercise != null && mounted) {
      setState(() {
        _selectedExerciseId = exercise.id;
        _editingSet = null;
      });
      context.read<WorkoutBloc>().add(AddSessionExercise(exercise));
    }
  }

  Future<void> _replaceExercise(String exerciseId) async {
    final state = context.read<WorkoutBloc>().state;
    final replacement = await showExercisePicker(
      context,
      replacing: true,
      localExercises: state is WorkoutInProgress
          ? state.day.exercises
          : const [],
    );
    if (replacement == null || !mounted) return;
    setState(() {
      _selectedExerciseId = replacement.id;
      _editingSet = null;
    });
    context.read<WorkoutBloc>().add(
      ReplaceSessionExercise(exerciseId: exerciseId, replacement: replacement),
    );
  }

  Future<void> _finish(WorkoutInProgress state, {bool discard = false}) async {
    if (state.completionPending) {
      context.read<WorkoutBloc>().add(RetryWorkoutSave());
      return;
    }
    final completed = state.exerciseLogs.values
        .expand((sets) => sets)
        .where((set) => set.isCompleted)
        .length;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(discard ? 'Discard this workout?' : 'Finish your workout?'),
        content: Text(
          discard
              ? 'The logged sets in this session will be removed.'
              : completed == 0
              ? 'No sets were logged. This session will be discarded.'
              : '$completed completed sets will be saved. Unfinished sets stay out of your totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep training'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(discard ? 'Discard' : 'Finish'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<WorkoutBloc>().add(
        discard ? CancelWorkout() : FinishWorkout(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<WorkoutBloc, WorkoutState>(
    listenWhen: (previous, current) =>
        current is! WorkoutInProgress ||
        previous is! WorkoutInProgress ||
        previous.restUntil != current.restUntil,
    listener: (context, state) {
      if (state is WorkoutInProgress) {
        _hadSession = true;
        _syncRest(state);
      } else if (state is WorkoutInitial && _hadSession) {
        context.read<TimerBloc>().add(ResetTimer());
        Navigator.pop(context);
      }
    },
    builder: (context, state) {
      if (state is! WorkoutInProgress) {
        return Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          body: Center(
            child: state is WorkoutError
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(state.message),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      }
      _hadSession = true;
      final exercises = state.day.exercises;
      final completed = state.exerciseLogs.values
          .expand((sets) => sets)
          .where((set) => set.isCompleted)
          .length;
      final total = state.exerciseLogs.values.fold<int>(
        0,
        (count, sets) => count + sets.length,
      );
      final elapsed = DateTime.now().difference(state.startTime).inMinutes;
      final canLeave = !state.isSaving && state.errorMessage == null;
      return PopScope(
        canPop: canLeave,
        child: Scaffold(
          appBar: AppBar(
            title: Text(state.day.name),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '${elapsed}m',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Workout options',
                enabled: !state.isSaving && !state.completionPending,
                onSelected: (_) => _finish(state, discard: true),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'discard',
                    child: Text('Discard workout'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;
                final focus = exercises.isEmpty
                    ? _emptyExercise()
                    : AbsorbPointer(
                        absorbing: state.completionPending,
                        child: _focus(
                          state,
                          exercises[_selected.clamp(0, exercises.length - 1)],
                        ),
                      );
                return Column(
                  children: [
                    if (state.errorMessage != null)
                      MaterialBanner(
                        content: Text(state.errorMessage!),
                        actions: [
                          TextButton(
                            onPressed: state.isSaving
                                ? null
                                : () => context.read<WorkoutBloc>().add(
                                    RetryWorkoutSave(),
                                  ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Text(
                                '$completed of $total sets logged',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                state.isSaving
                                    ? 'Saving…'
                                    : state.errorMessage == null
                                    ? 'Saved on device'
                                    : 'Save pending',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: total == 0 ? 0 : completed / total,
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: context.colors.divider,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 300,
                                      child: _overview(state),
                                    ),
                                    const VerticalDivider(width: 1),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(32),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 700,
                                            ),
                                            child: focus,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    0,
                                    24,
                                    24,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () => _showOverview(state),
                                          icon: const Icon(
                                            Icons.format_list_bulleted_rounded,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Exercise ${exercises.isEmpty ? 0 : _selected.clamp(0, exercises.length - 1) + 1} of ${exercises.length} · overview',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      focus,
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: SpottrButton(
                            text: state.completionPending
                                ? 'Retry finishing'
                                : 'Finish workout',
                            variant: SpottrButtonVariant.outline,
                            onPressed: state.isSaving
                                ? null
                                : () => _finish(state),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );

  Widget _emptyExercise() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Make it your workout.',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 12),
      const Text('Add an exercise to start logging.'),
      const SizedBox(height: 24),
      SpottrButton(text: 'Add exercise', onPressed: _addExercise),
    ],
  );

  Widget _focus(WorkoutInProgress state, Exercise exercise) {
    final sets = state.exerciseLogs[exercise.id] ?? [];
    final next = sets.where((set) => !set.isCompleted).firstOrNull;
    final selected =
        sets.where((set) => set.id == _editingSet).firstOrNull ?? next;
    final previous = state.previousExerciseLogs[exercise.id] ?? [];
    final until = state.restUntil;
    final restSeconds = until == null
        ? 0
        : (until.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(
            0,
            1800,
          );
    final text = Theme.of(context).textTheme;
    void update(SetLog set) => context.read<WorkoutBloc>().add(
      UpdateSet(exerciseId: exercise.id, setLog: set),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(exercise.name, style: text.headlineLarge)),
            IconButton(
              tooltip: 'Edit exercise for this session',
              onPressed: state.isSaving
                  ? null
                  : () => _editExercise(
                      exercise,
                      sets.any((set) => set.isCompleted),
                    ),
              icon: const Icon(Icons.tune_rounded, size: 22),
            ),
          ],
        ),
        if (exercise.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(exercise.note, style: text.bodyMedium),
          ),
        const SizedBox(height: 8),
        if (previous.any((set) => set.isCompleted))
          PreviousSetSummary(
            sets: previous,
            setIndex: selected == null
                ? sets.length - 1
                : sets.indexOf(selected),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${exercise.targetSets} sets · ${exercise.targetReps} reps · ${exercise.restDurationSeconds}s rest',
              style: text.bodyMedium,
            ),
          ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.divider),
          ),
          child: selected == null
              ? Column(
                  children: [
                    Icon(
                      Icons.check_rounded,
                      color: context.colors.success,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sets.isEmpty ? 'No sets yet' : 'Exercise complete',
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    SpottrButton(
                      text: sets.isEmpty
                          ? 'Add a set'
                          : _selected < state.day.exercises.length - 1
                          ? 'Next exercise'
                          : 'View workout',
                      onPressed: () {
                        if (sets.isEmpty) {
                          context.read<WorkoutBloc>().add(AddSet(exercise.id));
                          return;
                        }
                        if (_selected < state.day.exercises.length - 1) {
                          _select(_selected + 1);
                        } else {
                          _showOverview(state);
                        }
                      },
                    ),
                  ],
                )
              : Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          '${selected.isCompleted ? 'Editing set' : 'Set'} ${sets.indexOf(selected) + 1} of ${sets.length}',
                          style: text.titleMedium,
                        ),
                        if (selected.isWarmup || selected.isDropSet)
                          Text(
                            selected.isWarmup ? 'Warm-up' : 'Drop set',
                            style: text.labelMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: WorkoutValueControl(
                            label: 'Weight · kg',
                            value: selected.weight,
                            step: 2.5,
                            enabled:
                                !state.isSaving && !state.completionPending,
                            onChanged: (value) => update(
                              selected.copyWith(weight: value.toDouble()),
                            ),
                            onStep: (delta) => context.read<WorkoutBloc>().add(
                              AdjustSet(
                                exerciseId: exercise.id,
                                setId: selected.id,
                                weightDelta: delta.toDouble(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: WorkoutValueControl(
                            label: 'Reps',
                            value: selected.reps,
                            step: 1,
                            enabled:
                                !state.isSaving && !state.completionPending,
                            onChanged: (value) =>
                                update(selected.copyWith(reps: value.toInt())),
                            onStep: (delta) => context.read<WorkoutBloc>().add(
                              AdjustSet(
                                exerciseId: exercise.id,
                                setId: selected.id,
                                repsDelta: delta.toInt(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SpottrButton(
                      text: selected.isCompleted
                          ? 'Done editing'
                          : 'Log set ${sets.indexOf(selected) + 1}',
                      icon: const Icon(Icons.check_rounded),
                      onPressed:
                          state.isSaving ||
                              state.completionPending ||
                              selected.reps <= 0
                          ? null
                          : () {
                              if (!selected.isCompleted) {
                                context.read<WorkoutBloc>().add(
                                  SetCompletion(
                                    exerciseId: exercise.id,
                                    setId: selected.id,
                                    completed: true,
                                  ),
                                );
                              }
                              setState(() => _editingSet = null);
                            },
                    ),
                    if (selected.reps <= 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Add reps to log this set.'),
                      ),
                  ],
                ),
        ),
        if (restSeconds > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.divider),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    'Rest  ${restSeconds ~/ 60}:${(restSeconds % 60).toString().padLeft(2, '0')}',
                    style: text.titleLarge,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: state.isSaving
                            ? null
                            : () => context.read<WorkoutBloc>().add(
                                ChangeWorkoutRest(
                                  until!.add(const Duration(seconds: 30)),
                                ),
                              ),
                        child: const Text('+30s'),
                      ),
                      TextButton(
                        onPressed: state.isSaving
                            ? null
                            : () => context.read<WorkoutBloc>().add(
                                const ChangeWorkoutRest(null),
                              ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        for (final (index, set) in sets.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 32,
              child: Text('${index + 1}', style: text.bodyMedium),
            ),
            title: Text('${formatWeight(set.weight)} kg  ×  ${set.reps} reps'),
            subtitle: Text(
              [
                if (set.isCompleted)
                  'Logged'
                else if (set.id == selected?.id)
                  'Current set'
                else
                  'Not logged',
                if (set.isWarmup) 'Warm-up' else if (set.isDropSet) 'Drop set',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: set.isCompleted
                      ? 'Undo set ${index + 1}'
                      : 'Log set ${index + 1}',
                  onPressed:
                      state.isSaving || state.completionPending || set.reps <= 0
                      ? null
                      : () => context.read<WorkoutBloc>().add(
                          SetCompletion(
                            exerciseId: exercise.id,
                            setId: set.id,
                            completed: !set.isCompleted,
                          ),
                        ),
                  icon: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    child: Icon(
                      set.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(set.isCompleted),
                      color: set.isCompleted
                          ? context.colors.success
                          : context.colors.secondaryText,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Set ${index + 1} options',
                  enabled: !state.isSaving && !state.completionPending,
                  onSelected: (value) {
                    if (value == 'edit') {
                      setState(() => _editingSet = set.id);
                    }
                    if (value == 'remove') {
                      context.read<WorkoutBloc>().add(
                        RemoveSet(exerciseId: exercise.id, setId: set.id),
                      );
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Set removed'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              context.read<WorkoutBloc>().add(
                                RestoreSet(
                                  exerciseId: exercise.id,
                                  setLog: set,
                                  index: index,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                    if (value == 'warmup') {
                      update(set.copyWith(isWarmup: !set.isWarmup));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit values'),
                    ),
                    PopupMenuItem(
                      value: 'warmup',
                      child: Text(
                        set.isWarmup
                            ? 'Mark as working set'
                            : 'Mark as warm-up',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove set'),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => setState(() => _editingSet = set.id),
          ),
        TextButton.icon(
          onPressed: state.isSaving
              ? null
              : () => context.read<WorkoutBloc>().add(AddSet(exercise.id)),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add a set'),
        ),
        if (_selected < state.day.exercises.length - 1)
          TextButton.icon(
            onPressed: () => _select(_selected + 1),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text('Move to next exercise'),
          ),
      ],
    );
  }

  Widget _overview(WorkoutInProgress state, {bool dismiss = false}) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your workout', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Changes apply to this session only.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      for (final (index, exercise) in state.day.exercises.indexed)
        ListTile(
          key: ValueKey('overview-${exercise.id}'),
          selected: index == _selected,
          selectedTileColor: context.colors.primaryAccent.withValues(
            alpha: .08,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(exercise.name),
          subtitle: Text(
            '${(state.exerciseLogs[exercise.id] ?? []).where((set) => set.isCompleted).length} of ${(state.exerciseLogs[exercise.id] ?? []).length} sets',
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Options for ${exercise.name}',
            enabled: !state.isSaving && !state.completionPending,
            onSelected: (action) {
              if (action == 'replace') {
                if (dismiss) Navigator.pop(context);
                _replaceExercise(exercise.id);
              } else {
                context.read<WorkoutBloc>().add(
                  MoveSessionExercise(
                    exerciseId: exercise.id,
                    offset: action == 'earlier' ? -1 : 1,
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'earlier',
                enabled: index > 0,
                child: const Text('Move earlier'),
              ),
              PopupMenuItem(
                value: 'later',
                enabled: index < state.day.exercises.length - 1,
                child: const Text('Move later'),
              ),
              PopupMenuItem(
                value: 'replace',
                enabled: !(state.exerciseLogs[exercise.id] ?? []).any(
                  (set) => set.isCompleted,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Replace exercise'),
                    if ((state.exerciseLogs[exercise.id] ?? []).any(
                      (set) => set.isCompleted,
                    ))
                      Text(
                        'Already has logged sets',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            _select(index);
            if (dismiss) Navigator.pop(context);
          },
        ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: state.isSaving || state.completionPending
            ? null
            : () {
                if (dismiss) Navigator.pop(context);
                _addExercise();
              },
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
    ],
  );

  void _showOverview(WorkoutInProgress state) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          bloc: context.read<WorkoutBloc>(),
          builder: (_, current) => current is WorkoutInProgress
              ? _overview(current, dismiss: true)
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
