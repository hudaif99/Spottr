import 'package:hive/hive.dart';
import 'workout_day.dart';

part 'plan.g.dart';

@HiveType(typeId: 3)
class Plan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isActive;

  @HiveField(3)
  final List<WorkoutDay> days;

  Plan({
    required this.id,
    required this.name,
    this.isActive = false,
    this.days = const [],
  });

  Plan copyWith({
    String? id,
    String? name,
    bool? isActive,
    List<WorkoutDay>? days,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      days: days ?? this.days,
    );
  }
}
