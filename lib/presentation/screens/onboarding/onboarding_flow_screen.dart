import '../../widgets/workout_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../data/datasources/local_database_service.dart';
import '../../../domain/models/workout_schedule.dart';
import '../../../notifications/notification_permission_handler.dart';
import '../../blocs/schedule/schedule_bloc.dart';
import '../../blocs/schedule/schedule_event.dart';
import '../../blocs/schedule/schedule_state.dart';
import '../../widgets/spottr_button.dart';
import '../home_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});
  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _moving = false;
  bool _requesting = false;
  bool _finishing = false;
  bool _scheduleSaved = false;
  bool _remindersFailed = false;
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  final _days = <int>[];
  String _permissionStatus = 'undetermined';
  WorkoutSchedule? _pendingSchedule;
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _go(int page) async {
    if (_moving || _finishing || _requesting) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
      return;
    }
    setState(() => _moving = true);
    await _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _moving = false);
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestPermission() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final granted = await GetIt.I<NotificationPermissionHandler>()
          .requestPermission();
      if (!mounted) return;
      setState(() {
        _permissionStatus = granted ? 'granted' : 'denied';
        _requesting = false;
        _scheduleSaved = false;
        _remindersFailed = false;
      });
      _go(4);
    } catch (_) {
      if (mounted) setState(() => _requesting = false);
      _error('Could not request notifications. Try again or choose Not now.');
    }
  }

  Future<void> _pickTime() async {
    final selected = await showWorkoutTimePicker(context, _time);
    if (selected != null && mounted) {
      setState(() {
        _time = selected;
        _scheduleSaved = false;
        _remindersFailed = false;
      });
    }
  }

  void _finish() {
    if (_finishing) return;
    setState(() => _finishing = true);
    if (_scheduleSaved) {
      _complete();
      return;
    }
    _pendingSchedule = WorkoutSchedule(
      workoutHour: _time.hour,
      workoutMinute: _time.minute,
      workoutDays: List.of(_days)..sort(),
      remindersEnabled: _permissionStatus == 'granted',
      notificationPermissionStatus: _permissionStatus,
    );
    context.read<ScheduleBloc>().add(SaveSchedule(_pendingSchedule!));
  }

  Future<void> _complete() async {
    try {
      await GetIt.I<LocalDatabaseService>().setOnboardingCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _finishing = false);
      _error('Could not finish setup. Try again.');
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<ScheduleBloc, ScheduleState>(
    listener: (context, state) {
      if (!_finishing || _pendingSchedule == null) return;
      if (state is ScheduleLoaded &&
          identical(state.schedule, _pendingSchedule)) {
        _pendingSchedule = null;
        _scheduleSaved = true;
        _complete();
      } else if (state is ScheduleError &&
          identical(state.retrySchedule, _pendingSchedule)) {
        final saved = identical(state.schedule, _pendingSchedule);
        setState(() {
          _finishing = false;
          _pendingSchedule = null;
          _scheduleSaved = saved;
          _remindersFailed = saved;
        });
        if (!saved) _error(state.message);
      }
    },
    child: PopScope(
      canPop: _page == 0 && !_finishing && !_requesting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _page > 0) _go(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (_page > 0)
                              IconButton(
                                tooltip: 'Previous step',
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: _finishing || _requesting || _moving
                                    ? null
                                    : () => _go(_page - 1),
                              ),
                            Expanded(
                              child: Text(
                                'Spottr',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Semantics(
                              label: 'Step ${_page + 1} of 5',
                              child: Text(
                                '${_page + 1} of 5',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_page + 1) / 5,
                          minHeight: 3,
                          backgroundColor: context.colors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        _OnboardingPage(
                          key: const ValueKey('welcome-step'),
                          icon: Icons.fitness_center_rounded,
                          title: 'Make every set easier to log',
                          description:
                              'Keep your routine, setup notes and workout progress together. Ready when you are.',
                          action: SpottrButton(
                            text: 'Continue',
                            onPressed: _moving ? null : () => _go(1),
                          ),
                        ),
                        _OnboardingPage(
                          key: const ValueKey('time-step'),
                          icon: Icons.schedule_rounded,
                          title: 'When do you train?',
                          description:
                              'Choose your usual workout time. You can change it in Settings.',
                          content: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                _time.format(context),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ),
                          ),
                          action: SpottrButton(
                            text: 'Continue',
                            onPressed: _moving ? null : () => _go(2),
                          ),
                        ),
                        _OnboardingPage(
                          key: const ValueKey('days-step'),
                          icon: Icons.calendar_today_outlined,
                          title: 'Choose your training days',
                          description: 'Select the days that fit your week.',
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < 7; i++)
                                FilterChip(
                                  label: Text(_dayLabels[i]),
                                  selected: _days.contains(i + 1),
                                  onSelected: (selected) => setState(() {
                                    selected
                                        ? _days.add(i + 1)
                                        : _days.remove(i + 1);
                                    _scheduleSaved = false;
                                    _remindersFailed = false;
                                  }),
                                ),
                            ],
                          ),
                          action: SpottrButton(
                            text: 'Continue',
                            onPressed: _days.isEmpty || _moving
                                ? null
                                : () => _go(3),
                          ),
                        ),
                        _OnboardingPage(
                          key: const ValueKey('notifications-step'),
                          icon: Icons.notifications_outlined,
                          title: 'A reminder, if you want one',
                          description:
                              'Allow notifications for workout reminders. You can also train without them.',
                          action: Column(
                            children: [
                              SpottrButton(
                                text: 'Allow notifications',
                                isLoading: _requesting,
                                onPressed: _requestPermission,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _requesting || _moving
                                    ? null
                                    : () {
                                        setState(() {
                                          _permissionStatus = 'undetermined';
                                          _scheduleSaved = false;
                                          _remindersFailed = false;
                                        });
                                        _go(4);
                                      },
                                child: const Text('Not now'),
                              ),
                            ],
                          ),
                        ),
                        _OnboardingPage(
                          key: const ValueKey('finish-step'),
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Ready for your first set',
                          description:
                              'Create your plan next. Your training preferences can always be changed in Settings.',
                          content: _remindersFailed
                              ? const Text(
                                  'Your schedule is saved, but reminders could not update. Continue to Spottr and retry them in Settings.',
                                )
                              : null,
                          action: SpottrButton(
                            text: _remindersFailed
                                ? 'Continue to Spottr'
                                : 'Start using Spottr',
                            isLoading: _finishing,
                            onPressed: _moving ? null : _finish,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? content;
  final Widget action;
  const _OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.content,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: context.colors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(title, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 28),
                    content!,
                  ],
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 32), child: action),
            ],
          ),
        ),
      ),
    ),
  );
}
