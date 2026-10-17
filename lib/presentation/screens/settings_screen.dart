import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/local_database_service.dart';
import '../../data/datasources/backup_restore_service.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event.dart';
import '../widgets/spottr_button.dart';
import 'profile_appearance_screen.dart';
import 'workout_preferences_screen.dart';
import 'workout_schedule_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  late int _restTime = GetIt.I<LocalDatabaseService>().getRestTime();

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _chooseRest() async {
    final seconds = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RestTimeSheet(seconds: _restTime),
    );
    if (seconds == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await GetIt.I<LocalDatabaseService>().saveRestTime(seconds);
      if (mounted) setState(() => _restTime = seconds);
    } catch (_) {
      _message('Could not save rest time. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup(bool restore) async {
    setState(() => _busy = true);
    try {
      final service = GetIt.I<BackupRestoreService>();
      final error = restore
          ? await service.importData()
          : await service.exportData();
      if (!mounted) return;
      if (error != null) {
        _message(error);
      } else {
        if (restore) {
          context.read<PlansBloc>().add(LoadPlans());
          context.read<HistoryBloc>().add(LoadHistory());
        }
        _message(restore ? 'Backup restored.' : 'Backup exported.');
      }
    } catch (_) {
      _message(
        restore
            ? 'Could not restore backup. Try again.'
            : 'Could not export backup. Try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showBackup() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Backup and restore',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Export a copy of your workout data, or restore an existing backup.',
          ),
          const SizedBox(height: 24),
          SpottrButton(
            text: 'Export backup',
            onPressed: () {
              Navigator.pop(sheetContext);
              _backup(false);
            },
          ),
          const SizedBox(height: 12),
          SpottrButton(
            text: 'Restore backup',
            variant: SpottrButtonVariant.outline,
            onPressed: () {
              Navigator.pop(sheetContext);
              _backup(true);
            },
          ),
        ],
      ),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _row(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _section('Training'),
                    _row(
                      Icons.calendar_today_outlined,
                      'Workout schedule',
                      'Training days and reminders',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkoutScheduleSettingsScreen(),
                        ),
                      ),
                    ),
                    const Divider(),
                    _row(
                      Icons.timer_outlined,
                      'Default rest time',
                      '$_restTime seconds between sets',
                      _chooseRest,
                    ),
                    const Divider(),
                    _row(
                      Icons.tune_rounded,
                      'Workout preferences',
                      'Screen awake and timer sound',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkoutPreferencesScreen(),
                        ),
                      ),
                    ),
                    _section('Personal'),
                    _row(
                      Icons.palette_outlined,
                      'Profile and appearance',
                      'Your details and theme',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileAppearanceScreen(),
                        ),
                      ),
                    ),
                    _section('Your data'),
                    _row(
                      Icons.backup_outlined,
                      'Backup and restore',
                      'Keep a copy of your workouts',
                      _showBackup,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Spottr · Crafted by Hudaif',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_busy) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Saving settings',
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _RestTimeSheet extends StatefulWidget {
  final int seconds;
  const _RestTimeSheet({required this.seconds});
  @override
  State<_RestTimeSheet> createState() => _RestTimeSheetState();
}

class _RestTimeSheetState extends State<_RestTimeSheet> {
  static const _options = [30, 45, 60, 90, 120, 150, 180];
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: '${widget.seconds}');
  late bool _custom = !_options.contains(widget.seconds);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Default rest time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Close rest settings',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Used unless an exercise has its own rest time.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final seconds in _options)
              ChoiceChip(
                label: Text('$seconds s'),
                selected: !_custom && widget.seconds == seconds,
                onSelected: (_) => Navigator.pop(context, seconds),
              ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _custom,
              onSelected: (_) => setState(() => _custom = true),
            ),
          ],
        ),
        if (_custom) ...[
          const SizedBox(height: 20),
          Form(
            key: _form,
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rest · seconds'),
              validator: (value) {
                final seconds = int.tryParse(value?.trim() ?? '');
                return seconds == null || seconds < 1 || seconds > 3599
                    ? 'Use 1–3599 seconds'
                    : null;
              },
            ),
          ),
          const SizedBox(height: 16),
          SpottrButton(
            text: 'Save rest time',
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, int.parse(_controller.text.trim()));
              }
            },
          ),
        ],
      ],
    ),
  );
}
