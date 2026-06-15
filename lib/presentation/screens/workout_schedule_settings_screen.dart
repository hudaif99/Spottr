import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spottr/core/theme/app_colors_extension.dart';

import '../../data/models/workout_schedule.dart';
import '../../notifications/notification_permission_handler.dart';
// import '../../notifications/workout_reminder_scheduler.dart';
import '../blocs/schedule/schedule_bloc.dart';
import '../blocs/schedule/schedule_event.dart';
import '../blocs/schedule/schedule_state.dart';
import '../widgets/spottr_button.dart';
import '../widgets/spottr_card.dart';

/// Settings screen for editing the workout schedule and notification options.
class WorkoutScheduleSettingsScreen extends StatelessWidget {
  const WorkoutScheduleSettingsScreen({super.key});

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Schedule')),
      body: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          final schedule = state is ScheduleLoaded ? state.schedule : null;

          if (schedule == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: context.colors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Schedule Set',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No workout schedule has been configured yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SpottrCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.access_time_rounded,
                        title: 'Workout Time',
                        value: _formatTime(schedule.workoutTime),
                        onTap: () => _editTime(context, schedule),
                      ),
                      const Divider(),
                      _SettingsRow(
                        icon: Icons.calendar_today_rounded,
                        title: 'Workout Days',
                        value: _formatDays(schedule.workoutDays),
                        onTap: () => _editDays(context, schedule),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SpottrCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Reminders toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              color: context.colors.primaryText,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Workout Reminders',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            CupertinoSwitch(
                              value: schedule.remindersEnabled,
                              activeTrackColor: context.colors.primaryAccent,
                              onChanged: (v) => context
                                  .read<ScheduleBloc>()
                                  .add(ToggleReminders(v)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Permission status
                      _permissionRow(context, schedule),
                    ],
                  ),
                ),

                // const SizedBox(height: 24),
                // Text(
                //   'Developer',
                //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //     color: context.colors.secondaryText,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
                // const SizedBox(height: 10),
                // SpottrCard(
                //   padding: const EdgeInsets.all(16),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         'Send Test Notification',
                //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                //           color: context.colors.secondaryText,
                //         ),
                //       ),
                //       const SizedBox(height: 4),
                //       Text(
                //         'A notification will appear in approximately 10 seconds.',
                //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //           color: context.colors.secondaryText,
                //         ),
                //       ),
                //       const SizedBox(height: 12),
                //       SpottrButton(
                //         text: 'Send Test Notification',
                //         variant: SpottrButtonVariant.outline,
                //         icon: Icon(
                //           Icons.send_outlined,
                //           color: context.colors.primaryText,
                //         ),
                //         onPressed: () async {
                //           await GetIt.I<WorkoutReminderScheduler>()
                //               .scheduleTestNotification();
                //           if (context.mounted) {
                //             ScaffoldMessenger.of(context).showSnackBar(
                //               const SnackBar(
                //                 content: Text(
                //                   'Test notification in ~10 seconds.',
                //                 ),
                //               ),
                //             );
                //           }
                //         },
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _formatDays(List<int> days) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(days)..sort();
    if (sorted.isEmpty) return 'None';
    if (sorted.length == 7) return 'Every Day';
    return sorted.map((d) => labels[d - 1]).join(', ');
  }

  Widget _permissionRow(BuildContext context, WorkoutSchedule schedule) {
    final status = schedule.notificationPermissionStatus;
    final isGranted = status == 'granted';
    final isDenied = status == 'denied';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Icon(
            isGranted
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: isGranted ? context.colors.success : context.colors.error,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Permission',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  isGranted
                      ? 'Allowed'
                      : isDenied
                      ? 'Denied'
                      : 'Not Determined',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isGranted
                        ? context.colors.success
                        : context.colors.error,
                  ),
                ),
              ],
            ),
          ),
          if (isDenied)
            TextButton(
              onPressed: () =>
                  GetIt.I<NotificationPermissionHandler>().openAppSettings(),
              child: Text(
                'Open Settings',
                style: TextStyle(color: context.colors.primaryAccent),
              ),
            ),
        ],
      ),
    );
  }

  void _editTime(BuildContext context, WorkoutSchedule schedule) {
    DateTime pickerDate = DateTime(
      2000,
      1,
      1,
      schedule.workoutHour,
      schedule.workoutMinute,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: ctx.colors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sheetHandle(ctx),
                    const SizedBox(height: 24),
                    Text(
                      'Workout Time',
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 160,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness: Theme.of(ctx).brightness,
                          textTheme: CupertinoTextThemeData(
                            pickerTextStyle: TextStyle(
                              color: ctx.colors.primaryText,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: false,
                          initialDateTime: pickerDate,
                          onDateTimeChanged: (dt) {
                            setModalState(() => pickerDate = dt);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SpottrButton(
                      text: 'Save',
                      onPressed: () {
                        context.read<ScheduleBloc>().add(
                          UpdateWorkoutTime(
                            TimeOfDay(
                              hour: pickerDate.hour,
                              minute: pickerDate.minute,
                            ),
                          ),
                        );
                        Navigator.pop(sheetCtx);
                      },
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

  void _editDays(BuildContext context, WorkoutSchedule schedule) {
    final selected = List<int>.from(schedule.workoutDays);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: ctx.colors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sheetHandle(ctx),
                    const SizedBox(height: 24),
                    Text(
                      'Workout Days',
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(7, (i) {
                        final weekday = i + 1;
                        final isSelected = selected.contains(weekday);
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            isSelected
                                ? selected.remove(weekday)
                                : selected.add(weekday);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ctx.colors.primaryAccent
                                  : ctx.colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? ctx.colors.primaryAccent
                                    : ctx.colors.divider,
                              ),
                            ),
                            child: Text(
                              _dayLabels[i],
                              style: Theme.of(ctx).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.black
                                        : ctx.colors.primaryText,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SpottrButton(
                      text: 'Save',
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              context.read<ScheduleBloc>().add(
                                UpdateWorkoutDays(List.from(selected)),
                              );
                              Navigator.pop(sheetCtx);
                            },
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

  Widget _sheetHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: context.colors.primaryText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.primaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: context.colors.secondaryText),
          ],
        ),
      ),
    );
  }
}
