import 'package:get_it/get_it.dart';
import '../../data/datasources/local_database_service.dart';
import '../../data/datasources/backup_restore_service.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../presentation/blocs/plans/plans_bloc.dart';
import '../../presentation/blocs/workout/workout_bloc.dart';
import '../../presentation/blocs/timer/timer_bloc.dart';
import '../../presentation/blocs/history/history_bloc.dart';
import '../../domain/repositories/workout_repository.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // Data sources
  final localDb = LocalDatabaseService();
  await localDb.init();
  sl.registerSingleton<LocalDatabaseService>(localDb);

  sl.registerLazySingleton<BackupRestoreService>(
    () => BackupRestoreService(sl()),
  );

  // Repositories
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(sl()),
  );

  // Blocs
  sl.registerFactory(() => PlansBloc(sl()));
  sl.registerFactory(() => WorkoutBloc(sl()));
  sl.registerFactory(() => TimerBloc());
  sl.registerFactory(() => HistoryBloc(sl()));
}
