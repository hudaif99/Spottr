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
