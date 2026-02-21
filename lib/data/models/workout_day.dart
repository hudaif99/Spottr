import 'package:hive/hive.dart';
import 'exercise.dart';

part 'workout_day.g.dart';

@HiveType(typeId: 2)
class WorkoutDay extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? notes;

  @HiveField(3)
  final List<Exercise> exercises;

  WorkoutDay({
    required this.id,
    required this.name,
    this.notes,
    this.exercises = const [],
  });

  WorkoutDay copyWith({
    String? id,
    String? name,
    String? notes,
    List<Exercise>? exercises,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
    );
  }
}
