Map<String, List<SetLog>> immutableSetLogs(Map<String, List<SetLog>> logs) =>
    Map.unmodifiable({
      for (final entry in logs.entries)
        entry.key: List<SetLog>.unmodifiable(entry.value),
    });

class SetLog {
  final String id;
  final int reps;
  final double weight;
  final bool isCompleted;
  final bool isWarmup;
  final bool isDropSet;
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
      // Explicit weight edits stop automatic suggestions, including 0 kg.
      canInheritWeight:
          canInheritWeight ?? (weight == null && this.canInheritWeight),
    );
  }
}
