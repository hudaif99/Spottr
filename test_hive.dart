import 'package:flutter/widgets.dart';
import 'lib/data/datasources/local_database_service.dart';
import 'lib/data/models/workout_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = LocalDatabaseService();
  await db.init();
  try {
    final log = WorkoutLog(
      id: "abc",
      planId: "plan1",
      dayId: "day1",
      dayName: "Day 1",
      startTime: DateTime.now(),
      exerciseLogs: {"ex1": []},
    );
    await db.saveWorkoutLog(log);
    debugPrint("Saved successfully");
  } catch (e) {
    debugPrint("Error saving: $e");
  }
}
