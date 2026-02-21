import 'package:equatable/equatable.dart';
import '../../../data/models/plan.dart';

abstract class PlansEvent extends Equatable {
  const PlansEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlans extends PlansEvent {}

class AddPlan extends PlansEvent {
  final Plan plan;
  const AddPlan(this.plan);

  @override
  List<Object?> get props => [plan];
}

class UpdatePlan extends PlansEvent {
  final Plan plan;
  const UpdatePlan(this.plan);

  @override
  List<Object?> get props => [plan];
}

class DeletePlan extends PlansEvent {
  final String id;
  const DeletePlan(this.id);

  @override
  List<Object?> get props => [id];
}

class SetActivePlan extends PlansEvent {
  final String id;
  const SetActivePlan(this.id);

  @override
  List<Object?> get props => [id];
}
