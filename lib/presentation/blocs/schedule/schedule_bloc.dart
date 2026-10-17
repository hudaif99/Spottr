import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/workout_schedule.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../notifications/workout_reminder_scheduler.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final NotificationRepository _repo;
  final WorkoutReminderScheduler _scheduler;

  ScheduleBloc(this._repo, this._scheduler) : super(ScheduleInitial()) {
    on<ScheduleEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  WorkoutSchedule? get _schedule => switch (state) {
    ScheduleLoaded(:final schedule) => schedule,
    ScheduleSaving(:final schedule) => schedule,
    ScheduleError(:final schedule) => schedule,
    _ => null,
  };

  Future<void> _handle(ScheduleEvent event, Emitter<ScheduleState> emit) async {
    if (event is LoadSchedule) {
      try {
        emit(ScheduleLoaded(_repo.getSchedule()));
      } catch (_) {
        emit(
          ScheduleError('Could not load your schedule.', schedule: _schedule),
        );
      }
      return;
    }
    if (event is SaveSchedule) {
      await _persist(event.schedule, emit);
      return;
    }
    final current = _schedule;
    if (event is DeleteSchedule) {
      emit(ScheduleSaving(current));
      try {
        await _scheduler.cancelWorkoutReminders();
        await _scheduler.cancelStreakReminder();
        await _scheduler.cancelWeeklySummary();
        await _repo.deleteSchedule();
        emit(const ScheduleLoaded(null));
      } catch (_) {
        emit(
          ScheduleError('Could not delete your schedule.', schedule: current),
        );
      }
      return;
    }
    if (current == null) return;
    if (event is UpdateWorkoutTime) {
      await _persist(
        current.copyWith(
          workoutHour: event.time.hour,
          workoutMinute: event.time.minute,
        ),
        emit,
      );
    } else if (event is UpdateWorkoutDays) {
      await _persist(
        current.copyWith(workoutDays: List.of(event.days)..sort()),
        emit,
      );
    } else if (event is ToggleReminders) {
      await _persist(current.copyWith(remindersEnabled: event.enabled), emit);
    }
  }

  Future<void> _persist(
    WorkoutSchedule schedule,
    Emitter<ScheduleState> emit,
  ) async {
    final previous = _schedule;
    emit(ScheduleSaving(previous));
    var persisted = false;
    try {
      await _repo.saveSchedule(schedule);
      persisted = true;
      await _scheduler.rescheduleAll(schedule);
      emit(ScheduleLoaded(schedule));
    } catch (_) {
      emit(
        ScheduleError(
          persisted
              ? 'Schedule saved, but reminders could not update. Retry.'
              : 'Could not save your schedule. Try again.',
          schedule: persisted ? schedule : previous,
          retrySchedule: schedule,
        ),
      );
    }
  }
}
