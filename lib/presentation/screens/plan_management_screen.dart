import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors_extension.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/plans/plans_state.dart';
import '../widgets/spottr_button.dart';
import '../widgets/training_heading.dart';
import 'create_plan_screen.dart';

class PlanManagementScreen extends StatelessWidget {
  final bool embedded;
  const PlanManagementScreen({super.key, this.embedded = false});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: embedded ? null : AppBar(title: const Text('Plans')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: BlocBuilder<PlansBloc, PlansState>(
            builder: (context, state) {
              if (state is PlansLoading || state is PlansInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PlansError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load your plans.'),
                      TextButton(
                        onPressed: () =>
                            context.read<PlansBloc>().add(LoadPlans()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state is! PlansLoaded) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const TrainingHeading(
                    title: 'Your plans',
                    icon: Icons.fitness_center_rounded,
                  ),
                  const SizedBox(height: 8),
                  const Text('Choose a routine or build your own.'),
                  const SizedBox(height: 28),
                  if (state.plans.isEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Start with your own routine.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add the exercises you already do. You can change them any time.',
                    ),
                    const SizedBox(height: 28),
                  ],
                  for (final plan in state.plans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          border: Border(
                            top: BorderSide(
                              color: plan.isActive
                                  ? context.colors.primaryAccent
                                  : context.colors.divider,
                              width: 3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.isActive
                                        ? 'Current routine'
                                        : '${plan.days.length} workout days',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: plan.isActive
                                              ? context.colors.success
                                              : null,
                                        ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: '${plan.name} options',
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CreatePlanScreen(plan: plan),
                                        ),
                                      );
                                    }
                                    if (value == 'active') {
                                      context.read<PlansBloc>().add(
                                        SetActivePlan(plan.id),
                                      );
                                    }
                                    if (value == 'delete') {
                                      final confirmed =
                                          await showAdaptiveDialog<bool>(
                                            context: context,
                                            builder: (context) =>
                                                AlertDialog.adaptive(
                                                  title: const Text(
                                                    'Delete this plan?',
                                                  ),
                                                  content: const Text(
                                                    'Your saved workout history will stay available.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Keep plan',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                      if (confirmed == true &&
                                          context.mounted) {
                                        context.read<PlansBloc>().add(
                                          DeletePlan(plan.id),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit plan'),
                                    ),
                                    if (!plan.isActive)
                                      const PopupMenuItem(
                                        value: 'active',
                                        child: Text('Use this plan'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete plan'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              plan.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            for (final day in plan.days)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final count = Text(
                                      '${day.exercises.length} ${day.exercises.length == 1 ? 'exercise' : 'exercises'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    );
                                    if (constraints.maxWidth < 320 ||
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(14) >
                                            20) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(day.name),
                                          const SizedBox(height: 4),
                                          count,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: Text(day.name)),
                                        const SizedBox(width: 16),
                                        count,
                                      ],
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 12),
                            SpottrButton(
                              text: 'Edit routine',
                              variant: SpottrButtonVariant.outline,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreatePlanScreen(plan: plan),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SpottrButton(
                    text: 'Create a plan',
                    icon: const Icon(Icons.add),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePlanScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
