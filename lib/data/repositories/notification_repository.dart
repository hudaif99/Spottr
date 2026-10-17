import '../../data/datasources/local_database_service.dart';
import '../../domain/models/workout_schedule.dart';
import '../mappers/workout_storage_mapper.dart';

/// Abstract interface for schedule persistence.
abstract class NotificationRepository {
  WorkoutSchedule? getSchedule();
  Future<void> saveSchedule(WorkoutSchedule schedule);
  Future<void> deleteSchedule();
}

/// Implementation backed by [LocalDatabaseService] / Hive.
class NotificationRepositoryImpl implements NotificationRepository {
  final LocalDatabaseService _db;

  NotificationRepositoryImpl(this._db);

  @override
  WorkoutSchedule? getSchedule() => _db.getWorkoutSchedule()?.toDomain();

  @override
  Future<void> saveSchedule(WorkoutSchedule schedule) =>
      _db.saveWorkoutSchedule(schedule.toStorage());

  @override
  Future<void> deleteSchedule() => _db.deleteWorkoutSchedule();
}
