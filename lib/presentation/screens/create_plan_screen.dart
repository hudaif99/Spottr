import 'package:volt/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/plan.dart';
import '../../data/models/workout_day.dart';
import '../../data/models/exercise.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../widgets/volt_button.dart';

class CreatePlanScreen extends StatefulWidget {
  final Plan? plan;

  const CreatePlanScreen({super.key, this.plan});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _nameController = TextEditingController();
  final List<WorkoutDay> _days = [];
  final List<TextEditingController> _dayNameControllers = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _days.addAll(widget.plan!.days);
      for (var day in _days) {
        _dayNameControllers.add(TextEditingController(text: day.name));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var ctrl in _dayNameControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    setState(() {
      final defaultName = 'Day ${_days.length + 1}';
      _dayNameControllers.add(TextEditingController(text: defaultName));
      _days.add(WorkoutDay(id: _uuid.v4(), name: defaultName, exercises: []));
    });
  }

  void _addExercise(int dayIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        final extNameCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text(
            'Add Exercise',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            controller: extNameCtrl,
            style: TextStyle(color: context.colors.primaryText),
            decoration: InputDecoration(
              hintText: 'e.g. Bench Press',
              hintStyle: TextStyle(color: context.colors.secondaryText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colors.secondaryText),
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
              child: Text(
                'Add',
                style: TextStyle(color: context.colors.primaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editExercise(int dayIndex, int exerciseIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        final exercise = _days[dayIndex].exercises[exerciseIndex];
        final extNameCtrl = TextEditingController(text: exercise.name);
        return AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text(
            'Edit Exercise',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            controller: extNameCtrl,
            style: TextStyle(color: context.colors.primaryText),
            decoration: InputDecoration(
              hintText: 'e.g. Bench Press',
              hintStyle: TextStyle(color: context.colors.secondaryText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                if (extNameCtrl.text.isNotEmpty) {
                  setState(() {
                    final day = _days[dayIndex];
                    final updatedExercises = List<Exercise>.from(day.exercises);
                    updatedExercises[exerciseIndex] = exercise.copyWith(
                      name: extNameCtrl.text.trim(),
                    );
                    _days[dayIndex] = day.copyWith(exercises: updatedExercises);
                  });
                }
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Save',
                style: TextStyle(color: context.colors.primaryAccent),
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

    // Update days with their potentially changed names
    final updatedDays = List<WorkoutDay>.generate(_days.length, (i) {
      return _days[i].copyWith(
        name: _dayNameControllers[i].text.trim().isEmpty
            ? 'Day ${i + 1}'
            : _dayNameControllers[i].text.trim(),
      );
    });

    if (widget.plan != null) {
      final updatedPlan = widget.plan!.copyWith(
        name: _nameController.text.trim(),
        days: updatedDays,
      );
      context.read<PlansBloc>().add(UpdatePlan(updatedPlan));
    } else {
      final newPlan = Plan(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        days: updatedDays,
      );
      context.read<PlansBloc>().add(AddPlan(newPlan));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.plan != null ? 'Edit Plan' : 'Create Plan'),
          actions: [
            TextButton(
              onPressed: _savePlan,
              child: Text(
                'Save',
                style: TextStyle(color: context.colors.primaryAccent),
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
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: InputDecoration(
                  hintText: 'Plan Name (e.g. PPL)',
                  hintStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        color: context.colors.secondaryText.withValues(
                          alpha: 0.5,
                        ),
                      ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Workout Days',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...List.generate(_days.length, (index) {
                final day = _days[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dayNameControllers[index],
                              style: Theme.of(context).textTheme.titleMedium,
                              decoration: InputDecoration(
                                hintText: 'Workout Day Title (e.g. Chest)',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: context.colors.error,
                            ),
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            padding: EdgeInsets.all(5),
                            onPressed: () {
                              setState(() {
                                _dayNameControllers[index].dispose();
                                _dayNameControllers.removeAt(index);
                                _days.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 10),
                      // const SizedBox(height: 6),
                      ...day.exercises.asMap().entries.map((entry) {
                        final exIndex = entry.key;
                        final e = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: context.colors.secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: context.colors.secondaryText,
                                ),
                                onPressed: () => _editExercise(index, exIndex),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                style: ButtonStyle(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: context.colors.error,
                                ),
                                onPressed: () {
                                  setState(() {
                                    final updatedExercises =
                                        List<Exercise>.from(day.exercises)
                                          ..removeAt(exIndex);
                                    _days[index] = day.copyWith(
                                      exercises: updatedExercises,
                                    );
                                  });
                                },
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                style: ButtonStyle(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _addExercise(index),
                        icon: Icon(
                          Icons.add,
                          size: 16,
                          color: context.colors.primaryAccent,
                        ),
                        label: Text(
                          'Add Exercise',
                          style: TextStyle(color: context.colors.primaryAccent),
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
                icon: Icon(
                  Icons.add_circle_outline,
                  color: context.colors.primaryText,
                ),
                onPressed: _addDay,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
