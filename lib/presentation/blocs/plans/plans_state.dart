import 'package:equatable/equatable.dart';
import '../../../domain/models/plan.dart';

abstract class PlansState extends Equatable {
  const PlansState();

  @override
  List<Object?> get props => [];
}

class PlansInitial extends PlansState {}

class PlansLoading extends PlansState {}

class PlansLoaded extends PlansState {
  final List<Plan> plans;
  final Plan? activePlan;

  const PlansLoaded({required this.plans, this.activePlan});

  @override
  List<Object?> get props => [plans, activePlan];
}

class PlansError extends PlansState {
  final String message;
  const PlansError(this.message);

  @override
  List<Object?> get props => [message];
}
