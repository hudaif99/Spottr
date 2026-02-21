import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../blocs/plans/plans_bloc.dart';
import '../blocs/plans/plans_event.dart';
import '../blocs/plans/plans_state.dart';
import '../widgets/volt_card.dart';
import '../widgets/volt_button.dart';
import 'create_plan_screen.dart';

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
          style: AppTypography.textTheme.headlineMedium,
        ),
      ),
      body: BlocBuilder<PlansBloc, PlansState>(
        builder: (context, state) {
          if (state is PlansLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            );
          } else if (state is PlansError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.error),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.background,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreatePlanScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('No Plans Yet', style: AppTypography.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Create your first workout plan to get started.',
            style: AppTypography.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: VoltButton(
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
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.plans.length,
      itemBuilder: (context, index) {
        final plan = state.plans[index];
        return VoltCard(
          color: plan.isActive ? AppColors.surface : AppColors.background,
          hasBorder: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      color: plan.isActive
                          ? AppColors.primaryAccent
                          : AppColors.primaryText,
                    ),
                  ),
                  if (plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryAccent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.days.length} Days',
                style: AppTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: VoltButton(
                      text: plan.isActive ? 'Active Plan' : 'Set Active',
                      variant: plan.isActive
                          ? VoltButtonVariant.secondary
                          : VoltButtonVariant.outline,
                      onPressed: plan.isActive
                          ? null
                          : () {
                              context.read<PlansBloc>().add(
                                SetActivePlan(plan.id),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () {
                      // Edit Plan
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
