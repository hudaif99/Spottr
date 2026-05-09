import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spottr/core/theme/app_colors_extension.dart';
import '../../data/models/plan.dart';
import '../../data/models/workout_day.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_state.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_event.dart';
import '../blocs/workout/workout_state.dart';
import '../widgets/spottr_button.dart';
import '../widgets/spottr_card.dart';
import '../screens/active_workout_screen.dart';
import '../screens/plan_management_screen.dart';

class ActivePlanCard extends StatefulWidget {
  final Plan? activePlan;

  const ActivePlanCard({super.key, required this.activePlan});

  @override
  State<ActivePlanCard> createState() => _ActivePlanCardState();
}

class _ActivePlanCardState extends State<ActivePlanCard> {
  WorkoutDay? _selectedDay;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _computeNextDay();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActivePlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePlan != oldWidget.activePlan) {
      _computeNextDay();
    }
  }

  void _computeNextDay() {
    if (widget.activePlan == null || widget.activePlan!.days.isEmpty) {
      setState(() {
        _selectedDay = null;
      });
      return;
    }

    final historyState = context.read<HistoryBloc>().state;
    if (historyState is HistoryLoaded) {
      final planLogs = historyState.logs
          .where((log) => log.planId == widget.activePlan!.id)
          .toList();

      if (planLogs.isNotEmpty) {
        // Sort to find the most recent log
        planLogs.sort((a, b) => b.startTime.compareTo(a.startTime));
        final lastLog = planLogs.first;

        // Find the index of the last completed day in the current plan
        final lastDayIndex = widget.activePlan!.days.indexWhere(
          (day) => day.id == lastLog.dayId,
        );

        if (lastDayIndex != -1) {
          // Next day is the next index, wrapping around to 0
          final nextIndex = (lastDayIndex + 1) % widget.activePlan!.days.length;
          setState(() {
            _selectedDay = widget.activePlan!.days[nextIndex];
          });
          _scrollToSelectedDay();
          return;
        }
      }
    }

    // Default to the first day if no history or match found
    setState(() {
      _selectedDay = widget.activePlan!.days.first;
    });
    _scrollToSelectedDay();
  }

  void _scrollToSelectedDay() {
    if (_selectedDay == null || widget.activePlan == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final index = widget.activePlan!.days.indexOf(_selectedDay!);
      if (index == -1) return;

      // Estimated width of an unselected chip + padding
      // This centers the selected chip roughly well.
      final estimatedOffset = index * 100.0;

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          estimatedOffset,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCirc,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = widget.activePlan;

    if (activePlan == null) {
      return SpottrCard(
        padding: const EdgeInsets.all(24),
        hasBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Active Plan',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a workout plan and set it as active to start training.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SpottrButton(
              text: 'Create Plan',
              icon: Icon(Icons.add, color: context.colors.background),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PlanManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return BlocListener<HistoryBloc, HistoryState>(
      listener: (context, state) {
        if (state is HistoryLoaded) {
          _computeNextDay();
        }
      },
      child: SpottrCard(
        padding: EdgeInsets.zero,
        hasBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ACTIVE PLAN',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: context.colors.primaryAccent,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      Icon(
                        Icons.flash_on,
                        color: context.colors.primaryAccent,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activePlan.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (activePlan.days.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Up Next',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.colors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (activePlan.days.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 24, right: 16, bottom: 15),
                child: Row(
                  children: activePlan.days.map((day) {
                    final isSelected = _selectedDay?.id == day.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDay = day;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 20 : 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.primaryAccent
                                : context.colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? context.colors.primaryAccent
                                  : context.colors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: context.colors.primaryAccent
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  Icons.play_circle_fill,
                                  size: 18,
                                  color: context.colors.background,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                day.name,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? context.colors.background
                                          : context.colors.primaryText,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activePlan.days.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No workout days',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  BlocBuilder<WorkoutBloc, WorkoutState>(
                    builder: (context, workoutState) {
                      if (workoutState is WorkoutInProgress &&
                          workoutState.hasProgress) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SpottrButton(
                                    text: 'Resume',
                                    icon: Icon(
                                      Icons.play_arrow_rounded,
                                      color: context.colors.background,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ActiveWorkoutScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: SpottrButton(
                                    text: 'Reset',
                                    variant: SpottrButtonVariant.outline,
                                    onPressed: () {
                                      context.read<WorkoutBloc>().add(
                                        CancelWorkout(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          SpottrButton(
                            text: 'Start ${_selectedDay?.name ?? "Workout"}',
                            icon: Icon(
                              Icons.play_arrow_rounded,
                              color: context.colors.background,
                            ),
                            onPressed:
                                activePlan.days.isEmpty || _selectedDay == null
                                ? null
                                : () {
                                    context.read<WorkoutBloc>().add(
                                      StartWorkout(
                                        plan: activePlan,
                                        day: _selectedDay!,
                                      ),
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ActiveWorkoutScreen(),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
