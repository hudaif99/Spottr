import 'package:hive/hive.dart';

part 'set_log.g.dart';

@HiveType(typeId: 0)
class SetLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  int reps;

  @HiveField(2)
  double weight;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  bool isWarmup;

  @HiveField(5)
  bool isDropSet;

  SetLog({
    required this.id,
    this.reps = 0,
    this.weight = 0.0,
    this.isCompleted = false,
    this.isWarmup = false,
    this.isDropSet = false,
  });

  SetLog copyWith({
    String? id,
    int? reps,
    double? weight,
    bool? isCompleted,
    bool? isWarmup,
    bool? isDropSet,
  }) {
    return SetLog(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      isWarmup: isWarmup ?? this.isWarmup,
      isDropSet: isDropSet ?? this.isDropSet,
    );
  }
}
