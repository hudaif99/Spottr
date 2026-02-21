import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'plans_event.dart';
import 'plans_state.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final WorkoutRepository _repository;

  PlansBloc(this._repository) : super(PlansInitial()) {
    on<LoadPlans>(_onLoadPlans);
    on<AddPlan>(_onAddPlan);
    on<UpdatePlan>(_onUpdatePlan);
    on<DeletePlan>(_onDeletePlan);
    on<SetActivePlan>(_onSetActivePlan);
  }

  Future<void> _onLoadPlans(LoadPlans event, Emitter<PlansState> emit) async {
    emit(PlansLoading());
    try {
      final plans = await _repository.getPlans();
      final activePlan = await _repository.getActivePlan();
      emit(PlansLoaded(plans: plans, activePlan: activePlan));
    } catch (e) {
      emit(PlansError('Failed to load plans: $e'));
    }
  }

  Future<void> _onAddPlan(AddPlan event, Emitter<PlansState> emit) async {
    try {
      await _repository.savePlan(event.plan);
      add(LoadPlans());
    } catch (e) {
      emit(PlansError('Failed to add plan: $e'));
    }
  }

  Future<void> _onUpdatePlan(UpdatePlan event, Emitter<PlansState> emit) async {
    try {
      await _repository.savePlan(event.plan);
      add(LoadPlans());
    } catch (e) {
      emit(PlansError('Failed to update plan: $e'));
    }
  }

  Future<void> _onDeletePlan(DeletePlan event, Emitter<PlansState> emit) async {
    try {
      await _repository.deletePlan(event.id);
      add(LoadPlans());
    } catch (e) {
      emit(PlansError('Failed to delete plan: $e'));
    }
  }

  Future<void> _onSetActivePlan(
    SetActivePlan event,
    Emitter<PlansState> emit,
  ) async {
    try {
      await _repository.setActivePlan(event.id);
      add(LoadPlans());
    } catch (e) {
      emit(PlansError('Failed to set active plan: $e'));
    }
  }
}
