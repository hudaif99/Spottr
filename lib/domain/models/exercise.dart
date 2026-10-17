class Exercise {
  final String id;
  final String name;
  final int targetSets;
  final int targetReps;
  final double? targetWeight;
  final int restDurationSeconds;
  final String? imageUrl;
  final String note;
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
