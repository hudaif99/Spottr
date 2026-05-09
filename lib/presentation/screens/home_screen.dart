import 'package:spottr/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import '../widgets/spottr_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/plan.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_state.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/workout/workout_state.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event.dart' as he;
import '../blocs/history/history_state.dart';
import 'plan_management_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import '../widgets/active_plan_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/ic/spottr_icon.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Spottr',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: context.colors.primaryAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: context.colors.secondaryText,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to crush it?',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 32),

                // Active Plan Section
                BlocBuilder<PlansBloc, PlansState>(
                  builder: (context, state) {
                    Plan? activePlan;
                    if (state is PlansLoaded) {
                      activePlan = state.activePlan;
                    }
                    return ActivePlanCard(activePlan: activePlan);
                  },
                ),

                const SizedBox(height: 32),

                // Weekly Volume / Stats
                _buildWeeklyStatsSection(context),

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

  Widget _buildWeeklyStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Summary', style: Theme.of(context).textTheme.titleLarge),
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
                  child: SpottrCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workouts',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$weeklyWorkouts',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: context.colors.primaryAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SpottrCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volume',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weeklyVolume > 1000
                              ? '${(weeklyVolume / 1000).toStringAsFixed(1)}k kg'
                              : '${weeklyVolume.toStringAsFixed(0)} kg',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: context.colors.secondaryAccent),
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
        Text('Manage', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SpottrCard(
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
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.divider),
                    ),
                    child: Icon(
                      Icons.list_alt,
                      color: context.colors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Workout Plans',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: context.colors.secondaryText),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpottrCard(
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
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.divider),
                    ),
                    child: Icon(
                      Icons.history,
                      color: context.colors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'History & Analytics',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: context.colors.secondaryText),
            ],
          ),
        ),
      ],
    );
  }
}
