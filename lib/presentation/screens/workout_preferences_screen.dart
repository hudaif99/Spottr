import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class WorkoutPreferencesScreen extends StatelessWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Workout preferences')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: BlocConsumer<SettingsBloc, SettingsState>(
            listenWhen: (previous, current) => current.errorMessage != null,
            listener: (context, state) => ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!))),
            builder: (context, state) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Keep screen awake'),
                  subtitle: const Text('Keep the screen on while you train.'),
                  value: state.keepScreenAwake,
                  onChanged: (value) => context.read<SettingsBloc>().add(
                    UpdateKeepScreenAwake(value),
                  ),
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  title: const Text('Rest timer sound'),
                  subtitle: const Text('Play a sound when your rest ends.'),
                  value: state.playTimerSound,
                  onChanged: (value) => context.read<SettingsBloc>().add(
                    UpdatePlayTimerSound(value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
