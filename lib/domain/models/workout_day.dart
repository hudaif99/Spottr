import 'exercise.dart';

class WorkoutDay {
  final String id;
  final String name;
  final String? notes;
  final List<Exercise> exercises;

  WorkoutDay({
    required this.id,
    required this.name,
    this.notes,
    List<Exercise> exercises = const [],
  }) : exercises = List.unmodifiable(exercises);

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
