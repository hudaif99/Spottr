import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/exercise.dart';
import '../../domain/exercise_name_suggestions.dart';
import '../../domain/exercise_identity.dart';
import 'spottr_button.dart';

Future<Exercise?> showExerciseEditor(
  BuildContext context, {
  Exercise? exercise,
  bool lockName = false,
  bool replacing = false,
  String initialName = '',
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Exercise>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExerciseEditor(
      exercise: exercise,
      lockName: lockName,
      replacing: replacing,
      initialName: initialName,
    ),
  );
}

class _ExerciseEditor extends StatefulWidget {
  final Exercise? exercise;
  final bool lockName;
  final bool replacing;
  final String initialName;
  const _ExerciseEditor({
    this.exercise,
    required this.lockName,
    required this.replacing,
    required this.initialName,
  });
  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  final _form = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final _name = TextEditingController(
    text: widget.exercise?.name ?? widget.initialName,
  );
  late final _note = TextEditingController(text: widget.exercise?.note ?? '');
  late final _sets = TextEditingController(
    text: '${widget.exercise?.targetSets ?? 3}',
  );
  late final _reps = TextEditingController(
    text: '${widget.exercise?.targetReps ?? 10}',
  );
  late final _weight = TextEditingController(
    text: '${widget.exercise?.targetWeight ?? 0}',
  );
  late final _rest = TextEditingController(
    text: '${widget.exercise?.restDurationSeconds ?? 90}',
  );
  late bool _useDefaultRest = widget.exercise?.useDefaultRest ?? true;

  @override
  void dispose() {
    _nameFocus.dispose();
    for (final controller in [_name, _note, _sets, _reps, _weight, _rest]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      Scrollable.ensureVisible(
        invalid.first.context,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        alignment: .15,
      );
      return;
    }
    final entryId = widget.exercise?.id ?? const Uuid().v4();
    final name = _name.text.trim();
    Navigator.pop(
      context,
      Exercise(
        id: entryId,
        name: name,
        identityId: identityForExerciseEdit(
          widget.exercise,
          name,
          'custom:${const Uuid().v4()}',
        ),
        targetSets: int.parse(_sets.text.trim()),
        targetReps: int.parse(_reps.text.trim()),
        targetWeight: double.parse(_weight.text.trim()),
        restDurationSeconds: _useDefaultRest
            ? widget.exercise?.restDurationSeconds ?? 90
            : int.parse(_rest.text.trim()),
        useDefaultRest: _useDefaultRest,
        note: _note.text.trim(),
        imageUrl: widget.exercise?.imageUrl,
      ),
    );
  }

  Widget _number(
    String label,
    TextEditingController controller, {
    bool decimal = false,
    int min = 0,
    int max = 999,
  }) => TextFormField(
    key: ValueKey(label),
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    textInputAction: TextInputAction.next,
    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
    validator: (input) {
      final value = decimal
          ? double.tryParse(input?.trim() ?? '')
          : int.tryParse(input?.trim() ?? '');
      return value == null || !value.isFinite || value < min || value > max
          ? 'Use $min–$max'
          : null;
    },
  );

  Widget _targets() => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final sets = _number('Sets', _sets, min: 1, max: 30);
      final reps = _number('Reps', _reps, min: 1);
      final weight = _number('Weight · kg', _weight, decimal: true, max: 2000);
      if (constraints.maxWidth >= 460 && !largeText) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sets),
            const SizedBox(width: 12),
            Expanded(child: reps),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: weight),
          ],
        );
      }
      return Column(
        children: [
          if (largeText) ...[
            sets,
            const SizedBox(height: 16),
            reps,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sets),
                const SizedBox(width: 12),
                Expanded(child: reps),
              ],
            ),
          const SizedBox(height: 16),
          weight,
        ],
      );
    },
  );

  Widget _fields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.replacing) ...[
        Text(
          'Replaces unlogged sets in this workout. Your plan stays unchanged.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
      ],
      Autocomplete<String>(
        textEditingController: _name,
        focusNode: _nameFocus,
        optionsMaxHeight: 160,
        optionsBuilder: (value) => widget.lockName
            ? const <String>[]
            : suggestExerciseNames(value.text),
        onSelected: (_) => FocusScope.of(context).nextFocus(),
        fieldViewBuilder: (context, controller, focusNode, submit) =>
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              readOnly: widget.lockName,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: InputDecoration(
                labelText: 'Exercise name',
                hintText: 'Cable kickback',
                counterText: '',
                helperText: widget.lockName
                    ? 'Name stays fixed after logging a set'
                    : null,
                helperMaxLines: 2,
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
      ),
      const SizedBox(height: 20),
      _targets(),
      const SizedBox(height: 20),
      TextFormField(
        key: const ValueKey('Setup note'),
        controller: _note,
        maxLength: 180,
        minLines: 1,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Setup note · optional',
          hintText: 'Pulley at knee level',
        ),
      ),
      const SizedBox(height: 4),
      if (_useDefaultRest)
        Text(
          'Rest uses app settings',
          style: Theme.of(context).textTheme.bodyMedium,
        )
      else
        _number('Rest · seconds', _rest, max: 1800),
      TextButton.icon(
        onPressed: () => setState(() => _useDefaultRest = !_useDefaultRest),
        icon: Icon(
          _useDefaultRest ? Icons.timer_outlined : Icons.restart_alt_rounded,
          size: 20,
        ),
        label: Text(
          _useDefaultRest ? 'Customize rest' : 'Use app default rest',
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    insetAnimationDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 560,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.replacing
                        ? 'Replace exercise'
                        : widget.exercise == null
                        ? 'Add an exercise'
                        : 'Exercise details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          );
          final footer = Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SpottrButton(
              text: widget.replacing
                  ? 'Replace exercise'
                  : widget.exercise == null
                  ? 'Add exercise'
                  : 'Save details',
              onPressed: _save,
            ),
          );
          final form = Form(
            key: _form,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _fields(),
            ),
          );
          if (constraints.maxHeight < 260) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [header, form, footer],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: form,
                ),
              ),
              footer,
            ],
          );
        },
      ),
    ),
  );
}
