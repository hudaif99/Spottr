import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/models/workout_schedule.dart';
import '../../notifications/notification_permission_handler.dart';
import '../blocs/schedule/schedule_bloc.dart';
import '../blocs/schedule/schedule_event.dart';
import '../blocs/schedule/schedule_state.dart';
import '../widgets/spottr_button.dart';
import '../widgets/workout_time_picker.dart';

class WorkoutScheduleSettingsScreen extends StatefulWidget {
  const WorkoutScheduleSettingsScreen({super.key});
  @override
  State<WorkoutScheduleSettingsScreen> createState() =>
      _WorkoutScheduleSettingsScreenState();
}

class _WorkoutScheduleSettingsScreenState
    extends State<WorkoutScheduleSettingsScreen> {
  bool _requesting = false;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _editTime(WorkoutSchedule schedule) async {
    final time = await showWorkoutTimePicker(
      context,
      TimeOfDay(hour: schedule.workoutHour, minute: schedule.workoutMinute),
    );
    if (time != null && mounted) {
      context.read<ScheduleBloc>().add(UpdateWorkoutTime(time));
    }
  }

  Future<void> _editDays(WorkoutSchedule? schedule) async {
    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) =>
          _TrainingDaysSheet(days: schedule?.workoutDays ?? const []),
    );
    if (selected == null || !mounted) return;
    context.read<ScheduleBloc>().add(
      schedule == null
          ? SaveSchedule(
              WorkoutSchedule(
                workoutHour: 6,
                workoutMinute: 0,
                workoutDays: selected,
                remindersEnabled: false,
              ),
            )
          : UpdateWorkoutDays(selected),
    );
  }

  Future<void> _toggleReminders(WorkoutSchedule schedule, bool enabled) async {
    if (!enabled) {
      context.read<ScheduleBloc>().add(ToggleReminders(false));
      return;
    }
    setState(() => _requesting = true);
    try {
      final allowed = await GetIt.I<NotificationPermissionHandler>()
          .requestPermission();
      if (!mounted) return;
      context.read<ScheduleBloc>().add(
        SaveSchedule(
          schedule.copyWith(
            remindersEnabled: allowed,
            notificationPermissionStatus: allowed ? 'granted' : 'denied',
          ),
        ),
      );
      if (!allowed) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are blocked. Allow them in your device settings.',
              ),
            ),
          );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not check notifications. Try again.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ScheduleBloc, ScheduleState>(
    listenWhen: (previous, current) => current is ScheduleError,
    listener: (context, state) {
      if (!_scroll.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    },
    builder: (context, state) {
      final schedule = switch (state) {
        ScheduleLoaded(:final schedule) => schedule,
        ScheduleSaving(:final schedule) => schedule,
        ScheduleError(:final schedule) => schedule,
        _ => null,
      };
      final busy = state is ScheduleSaving || _requesting;
      return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('Workout schedule')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (busy) ...[
                      const LinearProgressIndicator(
                        semanticsLabel: 'Saving schedule',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state is ScheduleInitial)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Loading schedule',
                      ),
                    if (state is ScheduleError) ...[
                      Text(state.message),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            context.read<ScheduleBloc>().add(
                              state.retrySchedule == null
                                  ? LoadSchedule(refreshReminders: true)
                                  : SaveSchedule(state.retrySchedule!),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (schedule == null &&
                        state is! ScheduleInitial &&
                        !busy) ...[
                      Text(
                        'Choose your training days',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start with your usual days. Reminders stay off until you enable them.',
                      ),
                      const SizedBox(height: 24),
                      SpottrButton(
                        text: 'Choose days',
                        onPressed: () => _editDays(null),
                      ),
                    ],
                    if (schedule != null) ...[
                      Text(
                        'Your week',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Workout time'),
                        subtitle: Text(
                          TimeOfDay(
                            hour: schedule.workoutHour,
                            minute: schedule.workoutMinute,
                          ).format(context),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: busy ? null : () => _editTime(schedule),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Training days'),
                        subtitle: Text(
                          (List<int>.of(schedule.workoutDays)..sort())
                              .where((day) => day >= 1 && day <= 7)
                              .map((day) => _days[day - 1])
                              .join(', '),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: busy ? null : () => _editDays(schedule),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Reminders',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Workout reminders'),
                        subtitle: const Text(
                          'Get reminders on your training days.',
                        ),
                        value: schedule.remindersEnabled,
                        onChanged: busy
                            ? null
                            : (enabled) => _toggleReminders(schedule, enabled),
                      ),
                      const SizedBox(height: 12),
                      Text(switch (schedule.notificationPermissionStatus) {
                        'granted' => 'Notification access was allowed.',
                        'denied' =>
                          'Notifications are blocked. You can allow them in your device settings.',
                        _ =>
                          'Turning on reminders will ask for notification access.',
                      }, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TrainingDaysSheet extends StatefulWidget {
  final List<int> days;
  const _TrainingDaysSheet({required this.days});
  @override
  State<_TrainingDaysSheet> createState() => _TrainingDaysSheetState();
}

class _TrainingDaysSheetState extends State<_TrainingDaysSheet> {
  late final _selected = Set<int>.of(widget.days);
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Training days',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Cancel day changes',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(_WorkoutScheduleSettingsScreenState._days[day - 1]),
                selected: _selected.contains(day),
                onSelected: (selected) => setState(() {
                  selected ? _selected.add(day) : _selected.remove(day);
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        SpottrButton(
          text: 'Save days',
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()..sort()),
        ),
      ],
    ),
  );
}
