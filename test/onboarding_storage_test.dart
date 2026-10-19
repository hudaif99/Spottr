import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/data/repositories/notification_repository.dart';
import 'package:spottr/domain/models/workout_schedule.dart';
import 'package:spottr/notifications/notification_service.dart';
import 'package:spottr/notifications/workout_reminder_scheduler.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_event.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_state.dart';

class _Reminders extends WorkoutReminderScheduler {
  _Reminders() : super(NotificationService());
  @override
  Future<void> rescheduleAll(WorkoutSchedule schedule) async {}
}

void main() {
  for (final permission in ['undetermined', 'granted', 'denied']) {
    test(
      'onboarding schedule persists and reopens with $permission permission',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'spottr_onboarding_',
        );
        final database = LocalDatabaseService();
        await database.init(path: directory.path);
        final repository = NotificationRepositoryImpl(database);
        final bloc = ScheduleBloc(repository, _Reminders());
        addTearDown(() async {
          await bloc.close();
          await Hive.close();
          await directory.delete(recursive: true);
        });
        final schedule = WorkoutSchedule(
          workoutHour: 6,
          workoutMinute: 0,
          workoutDays: [1, 3, 5],
          remindersEnabled: permission == 'granted',
          notificationPermissionStatus: permission,
        );
        final done = bloc.stream.firstWhere(
          (state) => state is ScheduleLoaded || state is ScheduleError,
        );
        bloc.add(SaveSchedule(schedule));
        expect(
          await done.timeout(const Duration(seconds: 5)),
          isA<ScheduleLoaded>(),
        );
        await database.setOnboardingCompleted();
        await database.closeAll();
        await database.init(path: directory.path);
        expect(database.isOnboardingCompleted(), isTrue);
        final restored = repository.getSchedule()!;
        expect(restored.workoutDays, [1, 3, 5]);
        expect(restored.workoutHour, 6);
        expect(restored.workoutMinute, 0);
        expect(restored.remindersEnabled, permission == 'granted');
        expect(restored.notificationPermissionStatus, permission);
      },
    );
  }
}
