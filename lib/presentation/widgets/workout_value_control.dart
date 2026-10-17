import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';

String formatWeight(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

class WorkoutValueControl extends StatelessWidget {
  final String label;
  final num value;
  final num step;
  final ValueChanged<num> onChanged;
  final ValueChanged<num>? onStep;
  final bool enabled;
  const WorkoutValueControl({
    super.key,
    required this.label,
    required this.value,
    required this.step,
    required this.onChanged,
    this.onStep,
    this.enabled = true,
  });

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<num>(
      context: context,
      builder: (_) =>
          _ValueDialog(label: label, value: value, decimal: step is double),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      TextButton(
        onPressed: enabled ? () => _edit(context) : null,
        style: TextButton.styleFrom(
          foregroundColor: context.colors.primaryText,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
        child: Text(
          formatWeight(value),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            tooltip: 'Decrease $label',
            onPressed: enabled && value > 0
                ? () => onStep != null
                      ? onStep!(-step)
                      : onChanged((value - step).clamp(0, 2000))
                : null,
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 12),
          IconButton.outlined(
            tooltip: 'Increase $label',
            onPressed: enabled && value < 2000
                ? () => onStep != null
                      ? onStep!(step)
                      : onChanged((value + step).clamp(0, 2000))
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    ],
  );
}

class _ValueDialog extends StatefulWidget {
  final String label;
  final num value;
  final bool decimal;
  const _ValueDialog({
    required this.label,
    required this.value,
    required this.decimal,
  });
  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: formatWeight(widget.value),
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        validator: (input) {
          final value = widget.decimal
              ? double.tryParse(input ?? '')
              : int.tryParse(input ?? '');
          return value == null || !value.isFinite || value < 0 || value > 2000
              ? 'Use a value from 0 to 2000'
              : null;
        },
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Done')),
    ],
  );
  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.decimal
          ? double.parse(_controller.text)
          : int.parse(_controller.text),
    );
  }
}
