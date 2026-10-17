import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/exercise.dart';
import '../../domain/exercise_name_suggestions.dart';
import 'spottr_button.dart';

Future<Exercise?> showExerciseEditor(
  BuildContext context, {
  Exercise? exercise,
  bool lockName = false,
}) => showDialog<Exercise>(
  context: context,
  builder: (_) => _ExerciseEditor(exercise: exercise, lockName: lockName),
);

class _ExerciseEditor extends StatefulWidget {
  final Exercise? exercise;
  final bool lockName;
  const _ExerciseEditor({this.exercise, required this.lockName});
  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.exercise?.name ?? '';
  late String _note = widget.exercise?.note ?? '';
  late int _sets = widget.exercise?.targetSets ?? 3;
  late int _reps = widget.exercise?.targetReps ?? 10;
  late double _weight = widget.exercise?.targetWeight ?? 0;
  late int _rest = widget.exercise?.restDurationSeconds ?? 90;
  late bool _useDefaultRest = widget.exercise?.useDefaultRest ?? true;

  Widget _number(
    String label,
    num value,
    void Function(String) save, {
    bool decimal = false,
    int min = 0,
    int max = 999,
  }) => TextFormField(
    initialValue: '$value',
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    validator: (input) {
      final value = decimal
          ? double.tryParse(input ?? '')
          : int.tryParse(input ?? '');
      return value == null || !value.isFinite || value < min || value > max
          ? 'Use $min–$max'
          : null;
    },
    onSaved: (value) => save(value!),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.exercise == null ? 'Add an exercise' : 'Exercise details',
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _name),
                optionsMaxHeight: 192,
                optionsBuilder: (value) => widget.lockName
                    ? const <String>[]
                    : suggestExerciseNames(value.text),
                fieldViewBuilder: (context, controller, focusNode, submit) =>
                    TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      readOnly: widget.lockName,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Exercise name',
                        hintText: 'Cable kickback',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a name'
                          : null,
                      onSaved: (value) => _name = value!.trim(),
                      onFieldSubmitted: (_) => submit(),
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _number(
                      'Sets',
                      _sets,
                      (value) => _sets = int.parse(value),
                      min: 1,
                      max: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _number(
                      'Reps',
                      _reps,
                      (value) => _reps = int.parse(value),
                      min: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _number(
                'Suggested weight · kg',
                _weight,
                (value) => _weight = double.parse(value),
                decimal: true,
                max: 2000,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _useDefaultRest ? '' : '$_rest',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rest · seconds',
                  hintText: 'App default',
                  helperText: 'Leave empty to use app settings',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final seconds = int.tryParse(value);
                  return seconds == null || seconds < 0 || seconds > 1800
                      ? 'Use 0–1800 seconds'
                      : null;
                },
                onSaved: (value) {
                  _useDefaultRest = value!.trim().isEmpty;
                  if (!_useDefaultRest) _rest = int.parse(value);
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _note,
                maxLength: 180,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Setup note · optional',
                  hintText: 'A small reminder for next time',
                ),
                onSaved: (value) => _note = value!.trim(),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      SpottrButton(
        text: widget.exercise == null ? 'Add exercise' : 'Save details',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          _form.currentState!.save();
          Navigator.pop(
            context,
            Exercise(
              id: widget.exercise?.id ?? const Uuid().v4(),
              name: _name,
              targetSets: _sets,
              targetReps: _reps,
              targetWeight: _weight,
              restDurationSeconds: _rest,
              useDefaultRest: _useDefaultRest,
              note: _note,
              imageUrl: widget.exercise?.imageUrl,
            ),
          );
        },
      ),
    ],
  );
}
