import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spottr/core/theme/app_colors_extension.dart';

import '../../../data/datasources/local_database_service.dart';
import '../../../data/models/workout_schedule.dart';
import '../../../notifications/notification_permission_handler.dart';
import '../../blocs/schedule/schedule_bloc.dart';
import '../../blocs/schedule/schedule_event.dart';
import '../home_screen.dart';

/// Five-step onboarding flow shown on first launch.
///
/// Steps:
///   1. Welcome
///   2. Workout Time
///   3. Workout Days
///   4. Enable Notifications
///   5. Finish / navigate to Home
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Collected data
  TimeOfDay? _selectedTime;
  final List<int> _selectedDays = []; // 1=Mon … 7=Sun

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  void _next() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final schedule = WorkoutSchedule(
      workoutHour: _selectedTime?.hour ?? 6,
      workoutMinute: _selectedTime?.minute ?? 0,
      workoutDays: _selectedDays.isNotEmpty ? _selectedDays : [1, 2, 3, 4, 5],
      remindersEnabled: true,
    );

    if (!mounted) return;
    context.read<ScheduleBloc>().add(SaveSchedule(schedule));
    await GetIt.I<LocalDatabaseService>().setOnboardingCompleted();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildProgressDots(),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onContinue: _next),
                  _WorkoutTimePage(
                    onTimeSelected: (t) => setState(() => _selectedTime = t),
                    selectedTime: _selectedTime,
                    onContinue: _next,
                  ),
                  _WorkoutDaysPage(
                    selectedDays: _selectedDays,
                    dayLabels: _dayLabels,
                    onToggle: (d) => setState(() {
                      _selectedDays.contains(d)
                          ? _selectedDays.remove(d)
                          : _selectedDays.add(d);
                    }),
                    onContinue: _next,
                  ),
                  _NotificationPermissionPage(onContinue: _next),
                  _FinishPage(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? context.colors.primaryAccent
                : context.colors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────── Page 1: Welcome

class _WelcomePage extends StatelessWidget {
  final VoidCallback onContinue;
  const _WelcomePage({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      icon: Icons.fitness_center_rounded,
      title: 'Never Miss a Workout',
      description:
          'Spottr can remind you about your workouts, help you stay consistent, '
          'protect your streaks, and celebrate your progress.',
      button: _PrimaryButton(label: 'Continue', onTap: onContinue),
    );
  }
}

class _WorkoutTimePage extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final VoidCallback onContinue;
  const _WorkoutTimePage({
    required this.selectedTime,
    required this.onTimeSelected,
    required this.onContinue,
  });

  @override
  State<_WorkoutTimePage> createState() => _WorkoutTimePageState();
}

class _WorkoutTimePageState extends State<_WorkoutTimePage> {
  // Default: 06:00 AM — keep as DateTime for CupertinoDatePicker
  late DateTime _pickerDate = DateTime(2000, 1, 1, 6, 0);

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      icon: Icons.access_time_rounded,
      title: 'When Do You Usually Work Out?',
      description: 'Choose the time you typically begin your workout.',
      extraContent: Column(
        children: [
          const SizedBox(height: 16),
          // Selected time badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colors.primaryAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _formatTime(_pickerDate),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: context.colors.primaryAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Theme.of(context).brightness,
                textTheme: CupertinoTextThemeData(
                  pickerTextStyle: TextStyle(
                    color: context.colors.primaryText,
                    fontSize: 22,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: _pickerDate,
                onDateTimeChanged: (dt) {
                  setState(() => _pickerDate = dt);
                  widget.onTimeSelected(
                    TimeOfDay(hour: dt.hour, minute: dt.minute),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      button: _PrimaryButton(label: 'Continue', onTap: onContinue),
    );
  }

  VoidCallback get onContinue => widget.onContinue;
}

class _WorkoutDaysPage extends StatelessWidget {
  final List<int> selectedDays;
  final List<String> dayLabels;
  final ValueChanged<int> onToggle;
  final VoidCallback onContinue;

  const _WorkoutDaysPage({
    required this.selectedDays,
    required this.dayLabels,
    required this.onToggle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      icon: Icons.calendar_today_rounded,
      title: 'Which Days Do You Train?',
      description: 'Select the days you usually work out.',
      extraContent: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(7, (i) {
            final weekday = i + 1; // 1=Mon…7=Sun
            final selected = selectedDays.contains(weekday);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () => onToggle(weekday),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.colors.primaryAccent
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? context.colors.primaryAccent
                          : context.colors.divider,
                    ),
                  ),
                  child: Text(
                    dayLabels[i],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selected
                          ? Colors.white
                          : context.colors.primaryText,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      button: _PrimaryButton(
        label: 'Continue',
        onTap: selectedDays.isEmpty ? null : onContinue,
      ),
    );
  }
}

class _NotificationPermissionPage extends StatefulWidget {
  final VoidCallback onContinue;
  const _NotificationPermissionPage({required this.onContinue});

  @override
  State<_NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<_NotificationPermissionPage> {
  bool _requested = false;

  Future<void> _requestAndContinue() async {
    await GetIt.I<NotificationPermissionHandler>().requestPermission();
    setState(() => _requested = true);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      icon: Icons.notifications_active_rounded,
      title: 'Stay Consistent',
      description:
          'Allow notifications so Spottr can remind you before workouts, '
          'help you maintain your streak, and keep you motivated.',
      button: Column(
        children: [
          _PrimaryButton(
            label: 'Enable Notifications',
            onTap: _requested ? null : _requestAndContinue,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onContinue,
            child: Text(
              'Skip for now',
              style: TextStyle(color: context.colors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishPage extends StatelessWidget {
  final VoidCallback onFinish;
  const _FinishPage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      icon: Icons.check_circle_rounded,
      title: "You're All Set!",
      description:
          'Your workout schedule has been saved.\n'
          'Spottr will remind you when it\'s time to train.',
      button: _PrimaryButton(label: 'Start Using Spottr', onTap: onFinish),
    );
  }
}

class _OnboardingScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? extraContent;
  final Widget button;

  const _OnboardingScaffold({
    required this.icon,
    required this.title,
    required this.description,
    this.extraContent,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          // Icon container with gradient
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primaryAccent,
                  context.colors.secondaryAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.secondaryText,
              height: 1.6,
            ),
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 8),
            extraContent!,
          ],
          const Spacer(),
          button,
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primaryAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
