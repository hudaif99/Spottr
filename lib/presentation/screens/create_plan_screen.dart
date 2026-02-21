import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/plan.dart';
import '../../data/models/workout_day.dart';
import '../../data/models/exercise.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../widgets/volt_button.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _nameController = TextEditingController();
  final List<WorkoutDay> _days = [];
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addDay() {
    setState(() {
      _days.add(
        WorkoutDay(
          id: _uuid.v4(),
          name: 'Day ${_days.length + 1}',
          exercises: [],
        ),
      );
    });
  }

  void _addExercise(int dayIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        final extNameCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add Exercise',
            style: AppTypography.textTheme.titleLarge,
          ),
          content: TextField(
            controller: extNameCtrl,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: const InputDecoration(
              hintText: 'e.g. Bench Press',
              hintStyle: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                if (extNameCtrl.text.isNotEmpty) {
                  setState(() {
                    final day = _days[dayIndex];
                    final updatedExercises = List<Exercise>.from(day.exercises)
                      ..add(
                        Exercise(id: _uuid.v4(), name: extNameCtrl.text.trim()),
                      );
                    _days[dayIndex] = day.copyWith(exercises: updatedExercises);
                  });
                }
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Add',
                style: TextStyle(color: AppColors.primaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _savePlan() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a plan name')));
      return;
    }

    final newPlan = Plan(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      days: _days,
    );

    context.read<PlansBloc>().add(AddPlan(newPlan));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Plan'),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: AppTypography.textTheme.headlineMedium,
              decoration: InputDecoration(
                hintText: 'Plan Name (e.g. PPL)',
                hintStyle: AppTypography.textTheme.headlineMedium?.copyWith(
                  color: AppColors.secondaryText.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            Text('Workout Days', style: AppTypography.textTheme.titleLarge),
            const SizedBox(height: 16),
            ...List.generate(_days.length, (index) {
              final day = _days[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day.name,
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            setState(() {
                              _days.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    ...day.exercises.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.name,
                              style: AppTypography.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _addExercise(index),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primaryAccent,
                      ),
                      label: const Text(
                        'Add Exercise',
                        style: TextStyle(color: AppColors.primaryAccent),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            VoltButton(
              text: 'Add Workout Day',
              variant: VoltButtonVariant.outline,
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryText,
              ),
              onPressed: _addDay,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
