import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volt/core/theme/app_colors_extension.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../widgets/volt_button.dart';
import '../widgets/volt_text_field.dart';

class ProfileAppearanceScreen extends StatefulWidget {
  const ProfileAppearanceScreen({super.key});

  @override
  State<ProfileAppearanceScreen> createState() =>
      _ProfileAppearanceScreenState();
}

class _ProfileAppearanceScreenState extends State<ProfileAppearanceScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    _nameCtrl = TextEditingController(text: state.userName ?? '');
    _ageCtrl = TextEditingController(text: state.userAge?.toString() ?? '');
    _heightCtrl = TextEditingController(
      text: state.userHeight?.toString() ?? '',
    );
    _weightCtrl = TextEditingController(
      text: state.userWeight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    context.read<SettingsBloc>().add(
      UpdateProfile(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text),
        height: double.tryParse(_heightCtrl.text),
        weight: double.tryParse(_weightCtrl.text),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile saved successfully'),
        backgroundColor: context.colors.success,
      ),
    );
  }

  double? _calculateBMI(double? heightCm, double? weightKg) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Appearance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Preference',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'system',
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: 'light',
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    context.read<SettingsBloc>().add(
                      UpdateThemeMode(newSelection.first),
                    );
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return context.colors.primaryAccent.withValues(
                          alpha: 0.2,
                        );
                      }
                      return context.colors.surface;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return context.colors.primaryAccent;
                      }
                      return context.colors.primaryText;
                    }),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Your Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                VoltTextField(
                  label: 'Name',
                  hintText: 'Enter your name',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: VoltTextField(
                        label: 'Age',
                        hintText: 'Years',
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: VoltTextField(
                        label: 'Height',
                        hintText: 'cm',
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: VoltTextField(
                        label: 'Weight',
                        hintText: 'kg',
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBMIIndicator(
                  double.tryParse(_heightCtrl.text),
                  double.tryParse(_weightCtrl.text),
                ),
                const SizedBox(height: 48),
                VoltButton(text: 'Save Changes', onPressed: _saveProfile),
              ],
            ),
          );
        },
      ),
    );
  }
}
