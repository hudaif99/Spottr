import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../data/models/plan.dart';
import '../../data/models/workout_day.dart';
import '../../data/models/exercise.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/plans/plans_state.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/spottr_button.dart';

class CreatePlanScreen extends StatefulWidget {
  final Plan? plan;
  const CreatePlanScreen({super.key, this.plan});
  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _name = TextEditingController();
  final _days = <WorkoutDay>[];
  final _dayNames = <TextEditingController>[];
  final _uuid = const Uuid();
  String? _savingId;
  @override
  void initState() {
    super.initState();
    _name.text = widget.plan?.name ?? '';
    _days.addAll(widget.plan?.days ?? []);
    _dayNames.addAll(_days.map((day) => TextEditingController(text: day.name)));
    if (_days.isEmpty) _addDay();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _dayNames) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    final name = 'Day ${_days.length + 1}';
    _days.add(WorkoutDay(id: _uuid.v4(), name: name));
    _dayNames.add(TextEditingController(text: name));
  }

  Future<void> _exercise(int dayIndex, {int? index}) async {
    final exercise = await showExerciseEditor(
      context,
      exercise: index == null ? null : _days[dayIndex].exercises[index],
    );
    if (exercise == null || !mounted) return;
    setState(() {
      final exercises = [..._days[dayIndex].exercises];
      if (index == null) {
        exercises.add(exercise);
      } else {
        exercises[index] = exercise;
      }
      _days[dayIndex] = _days[dayIndex].copyWith(exercises: exercises);
    });
  }

  void _updateExercises(int dayIndex, List<Exercise> exercises) => setState(() {
    _days[dayIndex] = _days[dayIndex].copyWith(exercises: exercises);
  });
  void _save() {
    if (_name.text.trim().isEmpty ||
        _days.isEmpty ||
        _days.any((day) => day.exercises.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a plan name and at least one exercise to each day.',
          ),
        ),
      );
      return;
    }
    final days = [
      for (final (index, day) in _days.indexed)
        day.copyWith(
          name: _dayNames[index].text.trim().isEmpty
              ? 'Day ${index + 1}'
              : _dayNames[index].text.trim(),
        ),
    ];
    final plan = Plan(
      id: widget.plan?.id ?? _uuid.v4(),
      name: _name.text.trim(),
      days: days,
      isActive: widget.plan?.isActive ?? false,
      createdAt: widget.plan?.createdAt,
    );
    setState(() => _savingId = plan.id);
    context.read<PlansBloc>().add(
      widget.plan == null ? AddPlan(plan) : UpdatePlan(plan),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<PlansBloc, PlansState>(
    listener: (context, state) {
      if (_savingId == null) return;
      if (state is PlansLoaded &&
          state.plans.any((plan) => plan.id == _savingId)) {
        Navigator.pop(context);
      }
      if (state is PlansError) {
        setState(() => _savingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your plan. Please try again.'),
          ),
        );
      }
    },
    child: PopScope(
      canPop: _savingId == null,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.plan == null ? 'Build your plan' : 'Edit your plan',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AbsorbPointer(
                  absorbing: _savingId != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A routine that fits you.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Arrange your days. Keep useful setup cues with each exercise.',
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _name,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Plan name',
                          hintText: 'Your weekly routine',
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final (dayIndex, day) in _days.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.colors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _dayNames[dayIndex],
                                        maxLength: 80,
                                        decoration: const InputDecoration(
                                          labelText: 'Workout day',
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Day options',
                                      onSelected: (_) {
                                        setState(() {
                                          _days.removeAt(dayIndex);
                                          _dayNames
                                              .removeAt(dayIndex)
                                              .dispose();
                                        });
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove day'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (final (index, exercise)
                                    in day.exercises.indexed)
                                  Material(
                                    color: context.colors.surface,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(exercise.name),
                                      subtitle: Text(
                                        '${exercise.targetSets} sets · ${exercise.targetReps} reps${exercise.note.isEmpty ? '' : '\n${exercise.note}'}',
                                      ),
                                      onTap: () =>
                                          _exercise(dayIndex, index: index),
                                      trailing: PopupMenuButton<String>(
                                        tooltip: '${exercise.name} options',
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _exercise(dayIndex, index: index);
                                            return;
                                          }
                                          final exercises = [...day.exercises];
                                          if (value == 'up' && index > 0) {
                                            exercises.removeAt(index);
                                            exercises.insert(
                                              index - 1,
                                              exercise,
                                            );
                                          }
                                          if (value == 'down' &&
                                              index < exercises.length - 1) {
                                            exercises.removeAt(index);
                                            exercises.insert(
                                              index + 1,
                                              exercise,
                                            );
                                          }
                                          if (value == 'remove') {
                                            exercises.removeAt(index);
                                          }
                                          _updateExercises(dayIndex, exercises);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit details'),
                                          ),
                                          if (index > 0)
                                            const PopupMenuItem(
                                              value: 'up',
                                              child: Text('Move up'),
                                            ),
                                          if (index < day.exercises.length - 1)
                                            const PopupMenuItem(
                                              value: 'down',
                                              child: Text('Move down'),
                                            ),
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Text('Remove exercise'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: () => _exercise(dayIndex),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add exercise'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SpottrButton(
                        text: 'Add workout day',
                        variant: SpottrButtonVariant.outline,
                        onPressed: () => setState(_addDay),
                      ),
                      const SizedBox(height: 24),
                      SpottrButton(
                        text: 'Save plan',
                        isLoading: _savingId != null,
                        onPressed: _save,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
