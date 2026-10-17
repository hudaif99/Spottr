import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../domain/models/plan.dart';
import '../../domain/models/workout_day.dart';
import '../../domain/models/workout_log.dart';
import '../../domain/workout_rules.dart';
import '../../domain/weekly_progress.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_state.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_state.dart';
import '../blocs/workout/workout_event.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event.dart';
import '../blocs/history/history_state.dart';
import '../widgets/spottr_button.dart';
import '../formatters/workout_duration.dart';
import 'active_workout_screen.dart';
import 'create_plan_screen.dart';
import 'plan_management_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final DateTime Function()? now;
  const HomeScreen({super.key, this.now});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => BlocListener<WorkoutBloc, WorkoutState>(
    listener: (context, state) {
      if (state is WorkoutInitial) {
        context.read<HistoryBloc>().add(LoadHistory());
      }
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = IndexedStack(
          index: _tab,
          children: [
            _Today(now: widget.now),
            const PlanManagementScreen(embedded: true),
            const HistoryScreen(embedded: true),
          ],
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'spottr',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(letterSpacing: -1),
            ),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _tab,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (value) =>
                          setState(() => _tab = value),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.today_outlined),
                          selectedIcon: Icon(Icons.today_rounded),
                          label: Text('Today'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.view_agenda_outlined),
                          selectedIcon: Icon(Icons.view_agenda_rounded),
                          label: Text('Plans'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.bar_chart_outlined),
                          selectedIcon: Icon(Icons.bar_chart_rounded),
                          label: Text('Progress'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (value) =>
                      setState(() => _tab = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.today_outlined),
                      selectedIcon: Icon(Icons.today_rounded),
                      label: 'Today',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.view_agenda_outlined),
                      selectedIcon: Icon(Icons.view_agenda_rounded),
                      label: 'Plans',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart_rounded),
                      label: 'Progress',
                    ),
                  ],
                ),
        );
      },
    ),
  );
}

class _Today extends StatefulWidget {
  final DateTime Function()? now;
  const _Today({this.now});
  @override
  State<_Today> createState() => _TodayState();
}

class _TodayState extends State<_Today> with WidgetsBindingObserver {
  String? _selectedDay;
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  void _openWorkout() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
  );
  Future<void> _chooseDay(Plan plan, WorkoutDay selected) async {
    final day = await showModalBottomSheet<WorkoutDay>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose your workout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final day in plan.days)
              ListTile(
                title: Text(day.name),
                subtitle: Text('${day.exercises.length} exercises'),
                trailing: selected.id == day.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, day),
              ),
          ],
        ),
      ),
    );
    if (day != null && mounted) {
      setState(() {
        _selectedDay = day.id;
        _selectedPlan = plan.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlansBloc>().state;
    final history = context.watch<HistoryBloc>().state;
    final workout = context.watch<WorkoutBloc>().state;
    final logs = history is HistoryLoaded ? history.logs : <WorkoutLog>[];
    final plan = plans is PlansLoaded ? plans.activePlan : null;
    WorkoutDay? day;
    if (plan != null) {
      day = _selectedPlan == plan.id
          ? plan.days.where((day) => day.id == _selectedDay).firstOrNull
          : null;
      day ??= nextWorkoutDay(plan, logs);
    }
    final now = (widget.now?.call() ?? DateTime.now()).toLocal();
    final week = WeeklyProgress.fromLogs(logs, now: now);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(now),
                style: text.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                workout is WorkoutInProgress
                    ? 'Ready to continue?'
                    : 'Your next workout',
                style: text.headlineLarge,
              ),
              const SizedBox(height: 24),
              if (workout is WorkoutError) ...[
                Text(workout.message),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        context.read<WorkoutBloc>().add(ResumeWorkout()),
                    child: const Text('Retry recovery'),
                  ),
                ),
              ],
              if (plans is PlansLoading || plans is PlansInitial)
                const LinearProgressIndicator()
              else if (plans is PlansError)
                TextButton(
                  onPressed: () => context.read<PlansBloc>().add(LoadPlans()),
                  child: const Text('Retry loading plans'),
                ),
              if (workout is WorkoutInProgress)
                _workoutCard(
                  eyebrow: 'Workout in progress',
                  name: workout.day.name,
                  description:
                      '${workout.exerciseLogs.values.expand((sets) => sets).where((set) => set.isCompleted).length} sets logged · ${workout.isSaving
                          ? 'saving…'
                          : workout.historyCheckPending
                          ? 'recovery needs retry'
                          : workout.errorMessage != null
                          ? 'save needs retry'
                          : 'saved on this device'}',
                  action: 'Resume workout',
                  onPressed: _openWorkout,
                )
              else if (plan != null && day != null && history is HistoryLoaded)
                _workoutCard(
                  eyebrow: plan.name,
                  name: day.name,
                  description:
                      '${day.exercises.length} exercises · ${day.exercises.fold<int>(0, (sum, exercise) => sum + exercise.targetSets)} planned sets',
                  action: 'Start workout',
                  onPressed: () {
                    context.read<WorkoutBloc>().add(
                      StartWorkout(plan: plan, day: day!),
                    );
                    _openWorkout();
                    setState(() => _selectedDay = null);
                  },
                  extra: TextButton.icon(
                    onPressed: () => _chooseDay(plan, day!),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    label: const Text('Change workout'),
                  ),
                )
              else if (plans is PlansLoaded &&
                  (plan == null || plan.days.isEmpty))
                _workoutCard(
                  eyebrow: 'Your first plan',
                  name: 'Build your routine',
                  description:
                      'Add your exercises once. We’ll keep the logging simple.',
                  action: 'Create a plan',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
                  ),
                ),
              const SizedBox(height: 36),
              if (history is! HistoryLoaded) ...[
                if (history is HistoryError) ...[
                  const Text(
                    'Your workout history could not load. Retry to see your next workout and progress.',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          context.read<HistoryBloc>().add(LoadHistory()),
                      child: const Text('Retry loading history'),
                    ),
                  ),
                ] else ...[
                  const Text('Loading your workout history…'),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ] else ...[
                Text('This week', style: text.titleLarge),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var index = 0; index < 7; index++)
                      Expanded(
                        child: _weekDay(
                          week.days[index],
                          week.trainedOn(week.days[index]),
                          now,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 36,
                  runSpacing: 20,
                  children: [
                    _stat('${week.summary.workouts}', 'workouts'),
                    _stat(
                      week.missingDurations == week.summary.workouts &&
                              week.missingDurations > 0
                          ? '—'
                          : '${week.recordedDuration.inMinutes}',
                      week.missingDurations > 0
                          ? 'minutes recorded'
                          : 'minutes trained',
                    ),
                    _stat('${week.summary.completedSets}', 'sets logged'),
                  ],
                ),
                if (week.missingDurations > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Some workouts have no recorded duration.',
                    style: text.bodyMedium,
                  ),
                ],
                const SizedBox(height: 36),
                if (logs.isNotEmpty) ...[
                  Text('Last session', style: text.titleLarge),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(logs.first.dayName),
                    subtitle: Text(
                      '${DateFormat('d MMM').format(logs.first.startTime.toLocal())} · ${formatWorkoutDuration(logs.first)}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailScreen(log: logs.first),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: MediaQuery.textScalerOf(context).scale(14) > 20
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
  Widget _workoutCard({
    required String eyebrow,
    required String name,
    required String description,
    required String action,
    required VoidCallback onPressed,
    Widget? extra,
  }) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.colors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.colors.secondaryAccent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        SpottrButton(
          text: action,
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: onPressed,
        ),
        if (extra != null) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.center, child: extra),
        ],
      ],
    ),
  );
  Widget _weekDay(DateTime date, bool trained, DateTime now) {
    final today = DateUtils.isSameDay(now, date);
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = MediaQuery.textScalerOf(context)
            .scale(18)
            .clamp(30.0, 44.0)
            .clamp(0.0, constraints.maxWidth)
            .toDouble();
        return Semantics(
          label:
              '${DateFormat('EEEE, d MMMM yyyy').format(date)}${trained ? ', trained' : ''}${today ? ', today' : ''}',
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                DateFormat('EEEEE').format(date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: trained
                      ? context.colors.primaryAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: today
                        ? context.colors.primaryAccent
                        : context.colors.divider,
                  ),
                ),
                child: Center(
                  child: trained
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: context.colors.background,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${date.day}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
