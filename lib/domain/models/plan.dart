import 'workout_day.dart';

class Plan {
  final String id;
  final String name;
  final bool isActive;
  final List<WorkoutDay> days;
  final DateTime createdAt;

  Plan({
    required this.id,
    required this.name,
    this.isActive = false,
    List<WorkoutDay> days = const [],
    DateTime? createdAt,
  }) : days = List.unmodifiable(days),
       createdAt = createdAt ?? DateTime.now();

  Plan copyWith({
    String? id,
    String? name,
    bool? isActive,
    List<WorkoutDay>? days,
    DateTime? createdAt,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
