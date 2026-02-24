import 'package:volt/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../widgets/volt_button.dart';
import '../widgets/volt_card.dart';
import '../../data/datasources/local_database_service.dart';
import '../../data/datasources/backup_restore_service.dart';
import 'profile_appearance_screen.dart';
import 'workout_preferences_screen.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  int _restTime = 90;

  @override
  void initState() {
    super.initState();
    _restTime = GetIt.I<LocalDatabaseService>().getRestTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VoltCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingRow(
                        context,
                        Icons.person_outline,
                        'Profile & Appearance',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileAppearanceScreen(),
                          ),
                        ),
                      ),
                      const Divider(),
                      _buildSettingRow(
                        context,
                        Icons.fitness_center,
                        'Workout Preferences',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkoutPreferencesScreen(),
                          ),
                        ),
                      ),
                      const Divider(),
                      _buildSettingRow(
                        context,
                        Icons.timer_outlined,
                        'Rest Time',
                        value: '${_restTime}s',
                        onTap: () => _showRestTimePickerBottomSheet(context),
                      ),
                      const Divider(),
                      _buildSettingRow(
                        context,
                        Icons.storage_outlined,
                        'Backup & Restore Data',
                        onTap: () => _showBackupRestoreBottomSheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Volt v1.0.0',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crafted by Hudaif',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.colors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showRestTimePickerBottomSheet(BuildContext context) {
    final List<int> options = [30, 45, 60, 90, 120, 150, 180];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24.0,
                24.0,
                24.0,
                MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Default Rest Time',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the automatic countdown duration between your sets.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: [
                        ...options.map((int seconds) {
                          final bool isSelected = _restTime == seconds;
                          final String label = seconds >= 60
                              ? (seconds % 60 == 0
                                    ? '${seconds ~/ 60}m'
                                    : '${seconds ~/ 60}m ${seconds % 60}s')
                              : '${seconds}s';

                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: context.colors.primaryAccent,
                            backgroundColor: context.colors.surface,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : context.colors.primaryText,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (bool selected) async {
                              if (selected) {
                                setModalState(() => _restTime = seconds);
                                setState(() => _restTime = seconds);
                                await GetIt.I<LocalDatabaseService>()
                                    .saveRestTime(seconds);
                                if (context.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              }
                            },
                          );
                        }),
                        Builder(
                          builder: (context) {
                            final bool isCustomSelected = !options.contains(
                              _restTime,
                            );
                            final String label = isCustomSelected
                                ? 'Custom (${_restTime}s)'
                                : 'Custom';
                            return ChoiceChip(
                              label: Text(label),
                              selected: isCustomSelected,
                              selectedColor: context.colors.primaryAccent,
                              backgroundColor: context.colors.surface,
                              labelStyle: TextStyle(
                                color: isCustomSelected
                                    ? Colors.black
                                    : context.colors.primaryText,
                                fontWeight: isCustomSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (bool selected) async {
                                await showCupertinoModalPopup<int>(
                                  context: context,
                                  builder: (BuildContext popupContext) {
                                    Duration tempDuration = Duration(
                                      seconds: isCustomSelected ? _restTime : 0,
                                    );
                                    return Container(
                                      height: 300,
                                      color: context.colors.background,
                                      child: SafeArea(
                                        top: false,
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                CupertinoButton(
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: context
                                                          .colors
                                                          .secondaryText,
                                                    ),
                                                  ),
                                                  onPressed: () => Navigator.of(
                                                    popupContext,
                                                  ).pop(),
                                                ),
                                                CupertinoButton(
                                                  child: Text(
                                                    'Set',
                                                    style: TextStyle(
                                                      color: context
                                                          .colors
                                                          .primaryAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(
                                                      popupContext,
                                                    ).pop(
                                                      tempDuration.inSeconds,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: CupertinoTheme(
                                                data: CupertinoThemeData(
                                                  brightness: Theme.of(
                                                    context,
                                                  ).brightness,
                                                  textTheme:
                                                      CupertinoTextThemeData(
                                                        pickerTextStyle:
                                                            TextStyle(
                                                              color: context
                                                                  .colors
                                                                  .primaryText,
                                                              fontSize: 22,
                                                            ),
                                                      ),
                                                ),
                                                child: CupertinoTimerPicker(
                                                  mode: CupertinoTimerPickerMode
                                                      .ms,
                                                  initialTimerDuration:
                                                      tempDuration,
                                                  onTimerDurationChanged:
                                                      (Duration newDuration) {
                                                        tempDuration =
                                                            newDuration;
                                                      },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ).then((customValue) async {
                                  if (customValue != null && customValue > 0) {
                                    setModalState(
                                      () => _restTime = customValue,
                                    );
                                    setState(() => _restTime = customValue);
                                    await GetIt.I<LocalDatabaseService>()
                                        .saveRestTime(customValue);
                                    if (context.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBackupRestoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Backup & Restore',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your workout data to keep it safe, or restore it to a new device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                VoltButton(
                  text: 'Export Backup (.zip)',
                  icon: Icon(
                    Icons.upload_file,
                    color: context.colors.background,
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _handleExport(context);
                  },
                ),
                const SizedBox(height: 16),
                VoltButton(
                  text: 'Restore from Backup',
                  variant: VoltButtonVariant.outline,
                  icon: Icon(Icons.restore, color: context.colors.primaryText),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _handleImport(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    setState(() => _isLoading = true);
    final error = await GetIt.I<BackupRestoreService>().exportData();
    setState(() => _isLoading = false);

    if (context.mounted) {
      if (error != null) {
        _showSnackBar(context, error, true);
      } else {
        _showSnackBar(context, 'Backup extracted successfully!', false);
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    setState(() => _isLoading = true);
    final error = await GetIt.I<BackupRestoreService>().importData();
    setState(() => _isLoading = false);

    if (context.mounted) {
      if (error != null) {
        _showSnackBar(context, error, true);
      } else {
        // Refresh entire app state from the newly imported database
        context.read<PlansBloc>().add(LoadPlans());
        context.read<HistoryBloc>().add(LoadHistory());
        _showSnackBar(
          context,
          'Data restored completely! Pull down to refresh if needed.',
          false,
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? context.colors.error
            : context.colors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    IconData icon,
    String title, {
    String? value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: context.colors.primaryText),
                const SizedBox(width: 16),
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            if (value != null)
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.primaryAccent,
                ),
              )
            else
              Icon(Icons.chevron_right, color: context.colors.secondaryText),
          ],
        ),
      ),
    );
  }
}
