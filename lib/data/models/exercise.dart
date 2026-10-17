import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int targetSets;

  @HiveField(3)
  final int targetReps;

  @HiveField(4)
  final double? targetWeight;

  @HiveField(5)
  final int restDurationSeconds;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7, defaultValue: '')
  final String note;

  @HiveField(8, defaultValue: true)
  final bool useDefaultRest;

  Exercise({
    required this.id,
    required this.name,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight,
    this.restDurationSeconds = 90,
    this.imageUrl,
    this.note = '',
    this.useDefaultRest = true,
  });

  Exercise copyWith({
    String? id,
    String? name,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? restDurationSeconds,
    String? imageUrl,
    String? note,
    bool? useDefaultRest,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      imageUrl: imageUrl ?? this.imageUrl,
      note: note ?? this.note,
      useDefaultRest: useDefaultRest ?? this.useDefaultRest,
    );
  }
}
