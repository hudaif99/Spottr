import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../data/datasources/local_database_service.dart';
import '../../data/datasources/backup_restore_service.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/repositories/notification_repository.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/notification_permission_handler.dart';
import '../../notifications/workout_reminder_scheduler.dart';
import '../../presentation/blocs/plans/plans_bloc.dart';
import '../../presentation/blocs/workout/workout_bloc.dart';
import '../../presentation/blocs/timer/timer_bloc.dart';
import '../../presentation/blocs/history/history_bloc.dart';
import '../../presentation/blocs/schedule/schedule_bloc.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // ─── Timezone ──────────────────────────────────────────────────────────────
  // Must initialise before any zonedSchedule calls.
  tz.initializeTimeZones();
  await _refreshLocalTimeZone();

  // ─── Data sources ──────────────────────────────────────────────────────────
  final localDb = LocalDatabaseService();
  await localDb.init();
  sl.registerSingleton<LocalDatabaseService>(localDb);

  sl.registerLazySingleton<BackupRestoreService>(
    () => BackupRestoreService(sl()),
  );

  // ─── Notification infrastructure ───────────────────────────────────────────
  final notificationService = NotificationService();
  await notificationService.initialize();
  sl.registerSingleton<NotificationService>(notificationService);

  sl.registerLazySingleton<NotificationPermissionHandler>(
    () => NotificationPermissionHandler(sl()),
  );

  sl.registerLazySingleton<WorkoutReminderScheduler>(
    () => WorkoutReminderScheduler(
      sl(),
      workouts: sl<WorkoutRepository>(),
      refreshTimeZone: _refreshLocalTimeZone,
    ),
  );

  // ─── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  // ─── Blocs ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => PlansBloc(sl()));
  sl.registerFactory(() => WorkoutBloc(sl(), sl<WorkoutReminderScheduler>()));
  sl.registerFactory(() => TimerBloc(sl()));
  sl.registerFactory(() => HistoryBloc(sl()));
  sl.registerFactory(() => SettingsBloc(sl()));
  sl.registerFactory(() => ScheduleBloc(sl(), sl()));
}

Future<void> _refreshLocalTimeZone() async {
  final localTz = await FlutterTimezone.getLocalTimezone();
  tzlib.setLocalLocation(tzlib.getLocation(localTz.identifier));
}
