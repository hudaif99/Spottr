import 'package:spottr/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/plans/plans_state.dart';
import '../widgets/spottr_card.dart';
import '../widgets/spottr_button.dart';
import 'create_plan_screen.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import '../../data/models/plan.dart';

class PlanManagementScreen extends StatelessWidget {
  const PlanManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger load if not already loaded (In a real app, do this at the app root or router level)
    context.read<PlansBloc>().add(LoadPlans());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Workout Plans',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocBuilder<PlansBloc, PlansState>(
        builder: (context, state) {
          if (state is PlansLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: context.colors.primaryAccent,
              ),
            );
          } else if (state is PlansError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: context.colors.error),
              ),
            );
          } else if (state is PlansLoaded) {
            if (state.plans.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildPlansList(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<PlansBloc, PlansState>(
        builder: (context, state) {
          if (state is PlansLoaded && state.plans.isNotEmpty) {
            return FloatingActionButton(
              backgroundColor: context.colors.primaryAccent,
              foregroundColor: context.colors.background,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
                );
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: context.colors.divider),
          const SizedBox(height: 16),
          Text(
            'No Plans Yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workout plan to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: SpottrButton(
              text: 'Create Plan',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, PlansLoaded state) {
    return ImplicitlyAnimatedList<Plan>(
      padding: const EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: 116.0,
      ),
      items: state.plans,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: (context, animation, plan, index) {
        return SizeFadeTransition(
          sizeFraction: 0.7,
          curve: Curves.easeInOut,
          animation: animation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SpottrCard(
              color: context.colors.surface,
              hasBorder: true,
              borderColor: plan.isActive ? context.colors.primaryAccent : null,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: plan.isActive
                                        ? context.colors.primaryAccent
                                        : context.colors.primaryText,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.days.length} Workout Days',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: context.colors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (plan.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.primaryAccent.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.colors.primaryAccent.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: context.colors.primaryAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVE',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: context.colors.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Workout Day Chips
                  if (plan.days.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...plan.days.take(4).map((day) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.colors.divider),
                            ),
                            child: Text(
                              day.name,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: context.colors.primaryText),
                            ),
                          );
                        }),
                        if (plan.days.length > 4)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${plan.days.length - 4} more',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.colors.secondaryText,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: SpottrButton(
                          text: plan.isActive
                              ? 'Current Plan'
                              : 'Set as Active',
                          variant: plan.isActive
                              ? SpottrButtonVariant.secondary
                              : SpottrButtonVariant.outline,
                          icon: plan.isActive
                              ? Icon(
                                  Icons.fitness_center,
                                  color: context.colors.background,
                                )
                              : null,
                          onPressed: plan.isActive
                              ? null
                              : () {
                                  context.read<PlansBloc>().add(
                                    SetActivePlan(plan.id),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: context.colors.primaryText,
                              ),
                              tooltip: 'Edit Plan',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreatePlanScreen(plan: plan),
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: context.colors.divider,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: context.colors.error,
                              ),
                              tooltip: 'Delete Plan',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: context.colors.surface,
                                    title: Text(
                                      'Delete Plan',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete ${plan.name}?\nThis cannot be undone.',
                                      style: TextStyle(
                                        color: context.colors.primaryText,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: context.colors.secondaryText,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context.read<PlansBloc>().add(
                                            DeletePlan(plan.id),
                                          );
                                          Navigator.of(ctx).pop();
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: context.colors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
