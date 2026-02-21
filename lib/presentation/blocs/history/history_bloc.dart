import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final WorkoutRepository _repository;

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final logs = await _repository.getWorkoutLogs();
      logs.sort((a, b) => b.startTime.compareTo(a.startTime));
      emit(HistoryLoaded(logs));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}
