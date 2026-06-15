import 'package:flutter/material.dart';
import '../../../data/models/workout_schedule.dart';

abstract class ScheduleEvent {}

/// Load the persisted schedule from storage.
class LoadSchedule extends ScheduleEvent {}

/// Persist a complete schedule and reschedule all notifications.
class SaveSchedule extends ScheduleEvent {
  final WorkoutSchedule schedule;
  SaveSchedule(this.schedule);
}

/// Update only the workout time (hour + minute).
class UpdateWorkoutTime extends ScheduleEvent {
  final TimeOfDay time;
  UpdateWorkoutTime(this.time);
}

/// Update only the workout days list.
class UpdateWorkoutDays extends ScheduleEvent {
  final List<int> days;
  UpdateWorkoutDays(this.days);
}

/// Toggle the reminders-enabled flag.
class ToggleReminders extends ScheduleEvent {
  final bool enabled;
  ToggleReminders(this.enabled);
}

/// Delete the schedule and cancel all related notifications.
class DeleteSchedule extends ScheduleEvent {}
