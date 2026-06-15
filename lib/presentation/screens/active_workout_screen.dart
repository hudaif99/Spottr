import 'package:spottr/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_event.dart';
import '../blocs/workout/workout_state.dart';
import '../blocs/timer/timer_bloc.dart';
import '../blocs/timer/timer_event.dart';
import '../blocs/timer/timer_state.dart';
import '../blocs/settings/settings_bloc.dart';
import '../../data/models/set_log.dart';
import '../../data/datasources/local_database_service.dart';
import '../widgets/set_row.dart';
import '../widgets/spottr_button.dart';
import '../widgets/spottr_card.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<SettingsBloc>().state.keepScreenAwake) {
        WakelockPlus.enable();
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<TimerBloc>().add(ResetTimer());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: BlocBuilder<TimerBloc, TimerState>(
            builder: (context, timerState) {
              String timeText = 'Workout';
              bool isResting = timerState.mode == TimerMode.countdown;

              if (timerState.mode == TimerMode.stopwatch &&
                  timerState.isRunning) {
                timeText = _formatDuration(timerState.currentSeconds);
              } else if (isResting && timerState.isRunning) {
                timeText =
                    'Rest: ${_formatDuration(timerState.currentSeconds)}';
              }

              final color = isResting
                  ? context.colors.success
                  : context.colors.primaryAccent;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  boxShadow: timerState.isRunning
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isResting ? Icons.timer : Icons.timer_outlined,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<WorkoutBloc, WorkoutState>(
            builder: (context, state) {
              if (state is WorkoutInProgress) {
                if (state.day.exercises.isEmpty) {
                  return const Center(child: Text('No exercises for today.'));
                }
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final exercise = state.day.exercises[index];
                          final logs = state.exerciseLogs[exercise.id] ?? [];
                          final previousLogs =
                              state.previousExerciseLogs[exercise.id];
                          String previousText = 'No previous data';
                          SetLog? bestSet;
                          if (previousLogs != null && previousLogs.isNotEmpty) {
                            bestSet = previousLogs.reduce(
                              (a, b) => a.weight > b.weight ? a : b,
                            );
                            final weightStr =
                                bestSet.weight ==
                                    bestSet.weight.truncateToDouble()
                                ? bestSet.weight.toInt().toString()
                                : bestSet.weight.toString();
                            previousText =
                                'Previous Best: ${previousLogs.length}x${bestSet.reps} @ ${weightStr}kg';
                          }

                          final currentVolume = logs.fold(
                            0.0,
                            (sum, log) => sum + (log.weight * log.reps),
                          );
                          final currentVolumeStr =
                              currentVolume == currentVolume.truncateToDouble()
                              ? currentVolume.toInt().toString()
                              : currentVolume.toString();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SpottrCard(
                              padding: const EdgeInsets.all(20),
                              hasBorder: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                color: context
                                                    .colors
                                                    .primaryAccent,
                                              ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.colors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${index + 1} of ${state.day.exercises.length}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: context
                                                        .colors
                                                        .secondaryText,
                                                  ),
                                            ),
                                          ),
                                          if (currentVolume > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Vol: ${currentVolumeStr}kg',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: context
                                                        .colors
                                                        .primaryAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    previousText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: context.colors.secondaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...List.generate(logs.length, (setIndex) {
                                    return SetRow(
                                      key: ValueKey(logs[setIndex].id),
                                      index: setIndex,
                                      setLog: logs[setIndex],
                                      onChanged: (updated) {
                                        context.read<WorkoutBloc>().add(
                                          UpdateSet(
                                            exerciseId: exercise.id,
                                            setLog: updated,
                                          ),
                                        );
                                      },
                                      onComplete: () {
                                        context.read<WorkoutBloc>().add(
                                          UpdateSet(
                                            exerciseId: exercise.id,
                                            setLog: logs[setIndex].copyWith(
                                              isCompleted: true,
                                            ),
                                          ),
                                        );
                                        // Auto Start Rest Timer (only if the set has actual data)
                                        if (logs[setIndex].reps > 0) {
                                          context.read<TimerBloc>().add(
                                            StartRestTimer(
                                              GetIt.I<LocalDatabaseService>()
                                                  .getRestTime(),
                                            ),
                                          );
                                        }
                                      },
                                      onRemove: () {
                                        context.read<WorkoutBloc>().add(
                                          RemoveSet(
                                            exerciseId: exercise.id,
                                            setId: logs[setIndex].id,
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 16),
                                  SpottrButton(
                                    text: '+ Add Set',
                                    variant: SpottrButtonVariant.outline,
                                    onPressed: () {
                                      context.read<WorkoutBloc>().add(
                                        AddSet(exercise.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: state.day.exercises.length),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SpottrButton(
                                text: 'Finish Workout',
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  color: context.colors.background,
                                ),
                                onPressed: () {
                                  context.read<WorkoutBloc>().add(
                                    FinishWorkout(),
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                              if (state.hasProgress) ...[
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    context.read<WorkoutBloc>().add(
                                      CancelWorkout(),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Reset Workout',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: context.colors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Center(
                child: CircularProgressIndicator(
                  color: context.colors.primaryAccent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
