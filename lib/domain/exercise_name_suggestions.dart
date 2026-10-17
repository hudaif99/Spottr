import 'exercise_catalog.dart';

final commonExerciseNames = List<String>.unmodifiable(
  commonExerciseCatalog.values,
);

const _aliases = <String, String>{
  'Barbell bench press': 'bench press flat bench',
  'Barbell row': 'bent over row',
  'Barbell shoulder press': 'overhead press military press ohp',
  'Cable chest fly': 'cable crossover',
  'Cable kickback': 'glute kickback',
  'Farmer carry': 'farmers walk',
  'Lat pulldown': 'lat pull down',
  'Pec deck fly': 'butterfly chest fly',
  'Rear delt machine fly': 'reverse pec deck',
  'Romanian deadlift': 'rdl',
  'Dumbbell Romanian deadlift': 'dumbbell rdl',
  'Single-leg Romanian deadlift': 'single leg rdl',
  'Skull crusher': 'lying triceps extension',
  'Squat': 'back squat bodyweight squat',
  'Stationary bike': 'cycling exercise bike',
  'Trap bar deadlift': 'hex bar deadlift',
};

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

List<String> suggestExerciseNames(String input) {
  final query = _normalize(input);
  if (query.isEmpty) return const [];
  final words = input
      .toLowerCase()
      .split(RegExp(r'[\s-]+'))
      .map(_normalize)
      .where((word) => word.isNotEmpty)
      .toList();
  final startsWith = <String>[];
  final otherMatches = <String>[];
  for (final name in commonExerciseNames) {
    final normalizedName = _normalize(name);
    final searchable = '$normalizedName ${_normalize(_aliases[name] ?? '')}';
    if (normalizedName.startsWith(query)) {
      startsWith.add(name);
    } else if (words.every(searchable.contains)) {
      otherMatches.add(name);
    }
  }
  return [...startsWith, ...otherMatches];
}
