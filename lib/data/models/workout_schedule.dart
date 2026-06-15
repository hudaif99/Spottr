import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'workout_schedule.g.dart';

/// Stores the user's workout schedule and notification preferences.
/// workoutDays uses Dart's DateTime.weekday values: 1=Mon, 2=Tue … 7=Sun.
@HiveType(typeId: 6)
class WorkoutSchedule extends HiveObject {
  @HiveField(0)
  final int workoutHour;

  @HiveField(1)
  final int workoutMinute;

  @HiveField(2)
  final List<int> workoutDays;

  @HiveField(3)
  final bool remindersEnabled;

  /// Possible values: 'granted', 'denied', 'undetermined'
  @HiveField(4)
  final String notificationPermissionStatus;

  WorkoutSchedule({
    required this.workoutHour,
    required this.workoutMinute,
    required this.workoutDays,
    this.remindersEnabled = true,
    this.notificationPermissionStatus = 'undetermined',
  });

  TimeOfDay get workoutTime =>
      TimeOfDay(hour: workoutHour, minute: workoutMinute);

  WorkoutSchedule copyWith({
    int? workoutHour,
    int? workoutMinute,
    List<int>? workoutDays,
    bool? remindersEnabled,
    String? notificationPermissionStatus,
  }) {
    return WorkoutSchedule(
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
      workoutDays: workoutDays ?? this.workoutDays,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      notificationPermissionStatus:
          notificationPermissionStatus ?? this.notificationPermissionStatus,
    );
  }

  @override
  String toString() =>
      'WorkoutSchedule(hour: $workoutHour, minute: $workoutMinute, '
      'days: $workoutDays, reminders: $remindersEnabled)';
}
