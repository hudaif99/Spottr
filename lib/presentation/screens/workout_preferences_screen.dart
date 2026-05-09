import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spottr/core/theme/app_colors_extension.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class WorkoutPreferencesScreen extends StatelessWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                'During a Workout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSwitchRow(
                context,
                title: 'Keep Screen Awake',
                subtitle:
                    'Prevents your phone from locking while an active workout session is running.',
                icon: Icons.lightbulb_outline,
                value: state.keepScreenAwake,
                onChanged: (val) {
                  context.read<SettingsBloc>().add(UpdateKeepScreenAwake(val));
                },
              ),
              const SizedBox(height: 24),
              _buildSwitchRow(
                context,
                title: 'Rest Timer Sound',
                subtitle:
                    'Play a notification chime when the rest timer reaches zero.',
                icon: Icons.volume_up_outlined,
                value: state.playTimerSound,
                onChanged: (val) {
                  context.read<SettingsBloc>().add(UpdatePlayTimerSound(val));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.colors.primaryAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: context.colors.primaryAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
