import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/volt_card.dart';
import '../widgets/volt_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/plan.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_state.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_event.dart';
import '../blocs/workout/workout_state.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event.dart' as he;
import '../blocs/history/history_state.dart';
import 'plan_management_screen.dart';
import 'active_workout_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Volt',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.secondaryText,
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: BlocListener<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutInitial) {
            context.read<HistoryBloc>().add(he.LoadHistory());
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome / Date
                Text(
                  _getFormattedDate(),
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to crush it?',
                  style: AppTypography.textTheme.displaySmall,
                ),
                const SizedBox(height: 32),

                // Active Plan Section
                BlocBuilder<PlansBloc, PlansState>(
                  builder: (context, state) {
                    Plan? activePlan;
                    if (state is PlansLoaded) {
                      activePlan = state.activePlan;
                    }
                    return _buildActivePlanSection(context, activePlan);
                  },
                ),

                const SizedBox(height: 32),

                // Weekly Volume / Stats
                _buildWeeklyStatsSection(),

                const SizedBox(height: 24),

                // Quick Access
                _buildQuickAccess(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePlanSection(BuildContext context, Plan? activePlan) {
    if (activePlan == null) {
      return VoltCard(
        padding: const EdgeInsets.all(24),
        hasBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Active Plan',
              style: AppTypography.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a workout plan and set it as active to start training.',
              style: AppTypography.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            VoltButton(
              text: 'Create Plan',
              icon: const Icon(Icons.add, color: AppColors.background),
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

    return VoltCard(
      padding: const EdgeInsets.all(24),
      hasBorder: true,
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
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE PLAN',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryAccent,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.flash_on,
                color: AppColors.primaryAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(activePlan.name, style: AppTypography.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            activePlan.days.isNotEmpty
                ? '${activePlan.days.length} Days Workout'
                : 'No workout days',
            style: AppTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          VoltButton(
            text: 'Start Workout',
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.background,
            ),
            onPressed: activePlan.days.isEmpty
                ? null
                : () {
                    context.read<WorkoutBloc>().add(
                      StartWorkout(
                        plan: activePlan,
                        day: activePlan.days.first,
                      ),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveWorkoutScreen(),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Today, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildWeeklyStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Summary', style: AppTypography.textTheme.titleLarge),
        const SizedBox(height: 16),
        BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            int weeklyWorkouts = 0;
            double weeklyVolume = 0;

            if (state is HistoryLoaded) {
              final now = DateTime.now();
              // Calculate start of the week (Monday)
              final startOfWeek = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(Duration(days: now.weekday - 1));

              final weeklyLogs = state.logs
                  .where((log) => log.startTime.isAfter(startOfWeek))
                  .toList();
              weeklyWorkouts = weeklyLogs.length;
              weeklyVolume = weeklyLogs.fold(
                0.0,
                (sum, log) => sum + log.totalVolume,
              );
            }

            return Row(
              children: [
                Expanded(
                  child: VoltCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workouts',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$weeklyWorkouts',
                          style: AppTypography.textTheme.headlineMedium
                              ?.copyWith(color: AppColors.primaryAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: VoltCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volume',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weeklyVolume > 1000
                              ? '${(weeklyVolume / 1000).toStringAsFixed(1)}k kg'
                              : '${weeklyVolume.toStringAsFixed(0)} kg',
                          style: AppTypography.textTheme.headlineMedium
                              ?.copyWith(color: AppColors.secondaryAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage', style: AppTypography.textTheme.titleLarge),
        const SizedBox(height: 16),
        VoltCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlanManagementScreen()),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Workout Plans',
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
        const SizedBox(height: 12),
        VoltCard(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'History & Analytics',
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
      ],
    );
  }
}
