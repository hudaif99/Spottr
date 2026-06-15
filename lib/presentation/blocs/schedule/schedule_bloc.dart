import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/workout_schedule.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../notifications/workout_reminder_scheduler.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

/// Manages the workout schedule domain.
///
/// Every mutating event follows the same three-step pattern:
///   1. Persist the updated schedule via [NotificationRepository].
///   2. Reschedule notifications via [WorkoutReminderScheduler].
///   3. Emit the new [ScheduleLoaded] state.
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final NotificationRepository _repo;
  final WorkoutReminderScheduler _scheduler;

  ScheduleBloc(this._repo, this._scheduler) : super(ScheduleInitial()) {
    on<LoadSchedule>(_onLoad);
    on<SaveSchedule>(_onSave);
    on<UpdateWorkoutTime>(_onUpdateTime);
    on<UpdateWorkoutDays>(_onUpdateDays);
    on<ToggleReminders>(_onToggleReminders);
    on<DeleteSchedule>(_onDelete);
  }

  void _onLoad(LoadSchedule event, Emitter<ScheduleState> emit) {
    try {
      final schedule = _repo.getSchedule();
      emit(ScheduleLoaded(schedule));
    } catch (e) {
      emit(ScheduleError('Failed to load schedule: $e'));
    }
  }

  Future<void> _onSave(SaveSchedule event, Emitter<ScheduleState> emit) async {
    try {
      await _repo.saveSchedule(event.schedule);
      await _scheduler.rescheduleAll(event.schedule);
      emit(ScheduleLoaded(event.schedule));
    } catch (e) {
      emit(ScheduleError('Failed to save schedule: $e'));
    }
  }

  Future<void> _onUpdateTime(
    UpdateWorkoutTime event,
    Emitter<ScheduleState> emit,
  ) async {
    final current = _currentSchedule();
    if (current == null) return;
    final updated = current.copyWith(
      workoutHour: event.time.hour,
      workoutMinute: event.time.minute,
    );
    await _persist(updated, emit);
  }

  Future<void> _onUpdateDays(
    UpdateWorkoutDays event,
    Emitter<ScheduleState> emit,
  ) async {
    final current = _currentSchedule();
    if (current == null) return;
    final updated = current.copyWith(workoutDays: event.days);
    await _persist(updated, emit);
  }

  Future<void> _onToggleReminders(
    ToggleReminders event,
    Emitter<ScheduleState> emit,
  ) async {
    final current = _currentSchedule();
    if (current == null) return;
    final updated = current.copyWith(remindersEnabled: event.enabled);
    await _persist(updated, emit);
  }

  Future<void> _onDelete(
    DeleteSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await _scheduler.cancelWorkoutReminders();
      await _scheduler.cancelStreakReminder();
      await _scheduler.cancelWeeklySummary();
      await _repo.deleteSchedule();
      emit(const ScheduleLoaded(null));
    } catch (e) {
      emit(ScheduleError('Failed to delete schedule: $e'));
    }
  }

  // ──────────────────────────────────────── helpers

  WorkoutSchedule? _currentSchedule() {
    if (state is ScheduleLoaded) return (state as ScheduleLoaded).schedule;
    return null;
  }

  Future<void> _persist(
    WorkoutSchedule schedule,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await _repo.saveSchedule(schedule);
      await _scheduler.rescheduleAll(schedule);
      emit(ScheduleLoaded(schedule));
    } catch (e) {
      emit(ScheduleError('Failed to update schedule: $e'));
    }
  }
}
