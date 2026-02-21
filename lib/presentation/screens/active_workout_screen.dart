import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_event.dart';
import '../blocs/workout/workout_state.dart';
import '../blocs/timer/timer_bloc.dart';
import '../blocs/timer/timer_event.dart';
import '../blocs/timer/timer_state.dart';
import '../widgets/set_row.dart';
import '../widgets/volt_button.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<TimerBloc, TimerState>(
          builder: (context, timerState) {
            String timeText = 'Workout';
            if (timerState.mode == TimerMode.stopwatch &&
                timerState.isRunning) {
              timeText = _formatDuration(timerState.currentSeconds);
            } else if (timerState.mode == TimerMode.countdown &&
                timerState.isRunning) {
              timeText = 'Rest: ${_formatDuration(timerState.currentSeconds)}';
            }
            return Text(
              timeText,
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                color: timerState.mode == TimerMode.countdown
                    ? AppColors.success
                    : AppColors.primaryText,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Finish Workout Logic
              context.read<WorkoutBloc>().add(FinishWorkout());
              Navigator.of(context).pop();
            },
            child: Text(
              'Finish',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutInProgress) {
            if (state.day.exercises.isEmpty) {
              return const Center(child: Text('No exercises for today.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              itemCount: state.day.exercises.length,
              itemBuilder: (context, index) {
                final exercise = state.day.exercises[index];
                final logs = state.exerciseLogs[exercise.id] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      exercise.name,
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Previous: 3x10 @ 60kg', // Placeholder for history
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(logs.length, (setIndex) {
                      return SetRow(
                        key: ValueKey(logs[setIndex].id),
                        index: setIndex,
                        setLog: logs[setIndex],
                        onChanged: (updated) {
                          context.read<WorkoutBloc>().add(
                            UpdateSet(exerciseId: exercise.id, setLog: updated),
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
                          // Auto Start Rest Timer
                          context.read<TimerBloc>().add(
                            StartRestTimer(exercise.restDurationSeconds),
                          );
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
                    VoltButton(
                      text: '+ Add Set',
                      variant: VoltButtonVariant.secondary,
                      onPressed: () {
                        context.read<WorkoutBloc>().add(AddSet(exercise.id));
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],
                );
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
