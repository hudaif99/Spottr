import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'plans_event.dart';
import 'plans_state.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final WorkoutRepository _repository;

  PlansBloc(this._repository) : super(PlansInitial()) {
    on<PlansEvent>((event, emit) async {
      if (event is! LoadPlans) emit(PlansLoading());
      if (event is LoadPlans) await _onLoadPlans(event, emit);
      if (event is AddPlan) await _onAddPlan(event, emit);
      if (event is UpdatePlan) await _onUpdatePlan(event, emit);
      if (event is DeletePlan) await _onDeletePlan(event, emit);
      if (event is SetActivePlan) await _onSetActivePlan(event, emit);
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  Future<void> _onLoadPlans(LoadPlans event, Emitter<PlansState> emit) async {
    emit(PlansLoading());
    try {
      final plans = await _repository.getPlans();

      plans.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      final activePlan = await _repository.getActivePlan();
      emit(PlansLoaded(plans: plans, activePlan: activePlan));
    } catch (e) {
      emit(PlansError('Failed to load plans: $e'));
    }
  }

  Future<void> _onAddPlan(AddPlan event, Emitter<PlansState> emit) async {
    try {
      final existingPlans = await _repository.getPlans();
      await _repository.savePlan(event.plan);
      if (existingPlans.isEmpty) {
        await _repository.setActivePlan(event.plan.id);
      }
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
