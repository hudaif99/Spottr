import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors_extension.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../widgets/spottr_button.dart';

class ProfileAppearanceScreen extends StatefulWidget {
  const ProfileAppearanceScreen({super.key});
  @override
  State<ProfileAppearanceScreen> createState() =>
      _ProfileAppearanceScreenState();
}

class _ProfileAppearanceScreenState extends State<ProfileAppearanceScreen> {
  final _form = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(
    text: context.read<SettingsBloc>().state.userName ?? '',
  );
  late final _ageCtrl = TextEditingController(
    text: context.read<SettingsBloc>().state.userAge?.toString() ?? '',
  );
  late final _heightCtrl = TextEditingController(
    text: context.read<SettingsBloc>().state.userHeight?.toString() ?? '',
  );
  late final _weightCtrl = TextEditingController(
    text: context.read<SettingsBloc>().state.userWeight?.toString() ?? '',
  );

  @override
  void dispose() {
    for (final controller in [_nameCtrl, _ageCtrl, _heightCtrl, _weightCtrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      Scrollable.ensureVisible(invalid.first.context);
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<SettingsBloc>().add(
      UpdateProfile(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()),
        height: double.tryParse(_heightCtrl.text.trim()),
        weight: double.tryParse(_weightCtrl.text.trim()),
      ),
    );
  }

  Widget _number(
    String label,
    TextEditingController controller, {
    bool decimal = true,
  }) => TextFormField(
    key: ValueKey(label),
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    textInputAction: TextInputAction.next,
    onChanged: (_) => setState(() {}),
    validator: (input) {
      if (input == null || input.trim().isEmpty) return null;
      final value = decimal
          ? double.tryParse(input.trim())
          : int.tryParse(input.trim());
      return value == null || !value.isFinite || value <= 0
          ? 'Enter a positive ${decimal ? 'number' : 'whole number'}'
          : null;
    },
  );

  double? _calculateBMI(double? heightCm, double? weightKg) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0 ||
        !heightCm.isFinite ||
        !weightKg.isFinite) {
      return null;
    }
    final heightM = heightCm / 100;
    final value = weightKg / (heightM * heightM);
    return value.isFinite ? value : null;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal Weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget _buildBMIIndicator(double? heightCm, double? weightKg) {
    final bmi = _calculateBMI(heightCm, weightKg);
    if (bmi == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: context.colors.secondaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enter your height and weight to calculate your BMI.',
                style: TextStyle(color: context.colors.secondaryText),
              ),
            ),
          ],
        ),
      );
    }

    final category = _getBMICategory(bmi);
    Color getCategoryColor() {
      switch (category) {
        case 'Underweight':
          return Colors.blue;
        case 'Normal Weight':
          return context.colors.success;
        case 'Overweight':
          return Colors.orange;
        case 'Obese':
          return context.colors.error;
        default:
          return context.colors.primaryText;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getCategoryColor().withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Mass Index (BMI)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.colors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: getCategoryColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  category,
                  style: TextStyle(
                    color: getCategoryColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null ||
            previous.profileRevision != current.profileRevision,
        listener: (context, state) {
          final message = state.errorMessage ?? 'Profile saved.';
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) => PopScope(
          canPop: !state.isSaving,
          child: Scaffold(
            appBar: AppBar(title: const Text('Profile & appearance')),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SpottrButton(
                        text: 'Save profile',
                        isLoading: state.isSaving,
                        onPressed: _save,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AbsorbPointer(
                    absorbing: state.isSaving,
                    child: Form(
                      key: _form,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final entry in const {
                                  'system': 'System',
                                  'light': 'Light',
                                  'dark': 'Dark',
                                }.entries)
                                  ChoiceChip(
                                    label: Text(entry.value),
                                    selected: state.themeMode == entry.key,
                                    onSelected: (selected) {
                                      if (selected) {
                                        context.read<SettingsBloc>().add(
                                          UpdateThemeMode(entry.key),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Your details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text('All fields are optional.'),
                            const SizedBox(height: 20),
                            TextFormField(
                              key: const ValueKey('Profile name'),
                              controller: _nameCtrl,
                              maxLength: 100,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            _number('Age · years', _ageCtrl, decimal: false),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final height = _number(
                                  'Height · cm',
                                  _heightCtrl,
                                );
                                final weight = _number(
                                  'Body weight · kg',
                                  _weightCtrl,
                                );
                                if (constraints.maxWidth < 320 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        20) {
                                  return Column(
                                    children: [
                                      height,
                                      const SizedBox(height: 16),
                                      weight,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: height),
                                    const SizedBox(width: 16),
                                    Expanded(child: weight),
                                  ],
                                );
                              },
                            ),
                            if (_calculateBMI(
                                  double.tryParse(_heightCtrl.text),
                                  double.tryParse(_weightCtrl.text),
                                ) !=
                                null) ...[
                              const SizedBox(height: 24),
                              _buildBMIIndicator(
                                double.tryParse(_heightCtrl.text),
                                double.tryParse(_weightCtrl.text),
                              ),
                            ],
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
        ),
      );
}
