import 'package:hive/hive.dart';

part 'set_log.g.dart';

@HiveType(typeId: 0)
class SetLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int reps;

  @HiveField(2)
  final double weight;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final bool isWarmup;

  @HiveField(5)
  final bool isDropSet;

  @HiveField(6, defaultValue: false)
  final bool canInheritWeight;

  SetLog({
    required this.id,
    this.reps = 0,
    this.weight = 0.0,
    this.isCompleted = false,
    this.isWarmup = false,
    this.isDropSet = false,
    this.canInheritWeight = false,
  });

  SetLog copyWith({
    String? id,
    int? reps,
    double? weight,
    bool? isCompleted,
    bool? isWarmup,
    bool? isDropSet,
    bool? canInheritWeight,
  }) {
    return SetLog(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      isWarmup: isWarmup ?? this.isWarmup,
      isDropSet: isDropSet ?? this.isDropSet,
      canInheritWeight:
          canInheritWeight ?? (weight == null && this.canInheritWeight),
    );
  }
}
