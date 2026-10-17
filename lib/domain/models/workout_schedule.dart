/// Stores the user's workout schedule and notification preferences.
/// workoutDays uses Dart's DateTime.weekday values: 1=Mon, 2=Tue … 7=Sun.
class WorkoutSchedule {
  final int workoutHour;
  final int workoutMinute;
  final List<int> workoutDays;
  final bool remindersEnabled;

  /// Possible values: 'granted', 'denied', 'undetermined'
  final String notificationPermissionStatus;

  WorkoutSchedule({
    required this.workoutHour,
    required this.workoutMinute,
    required List<int> workoutDays,
    this.remindersEnabled = true,
    this.notificationPermissionStatus = 'undetermined',
  }) : workoutDays = List.unmodifiable(workoutDays);

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
