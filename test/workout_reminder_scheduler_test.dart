import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import 'package:spottr/domain/models/workout_schedule.dart';
import 'package:spottr/notifications/notification_ids.dart';
import 'package:spottr/notifications/notification_service.dart';
import 'package:spottr/notifications/workout_reminder_scheduler.dart';
import 'package:spottr/data/repositories/notification_repository.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_event.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_state.dart';
import 'support/fake_workout_repository.dart';

class _Service extends NotificationService {
  final pending = <int, tz.TZDateTime>{};
  final cancelled = <int>[];
  bool failCancel = false;
  bool failSchedule = false;
  Completer<void>? scheduleGate;
  Completer<void>? scheduleStarted;
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
    required String channelId,
  }) async {
    if (failSchedule) throw StateError('Unavailable');
    if (scheduleStarted != null && !scheduleStarted!.isCompleted) {
      scheduleStarted!.complete();
    }
    await scheduleGate?.future;
    pending[id] = date;
  }

  @override
  Future<void> cancel(int id) async {
    if (failCancel) throw StateError('Unavailable');
    cancelled.add(id);
    pending.remove(id);
  }
}

class _Schedules implements NotificationRepository {
  WorkoutSchedule? current;
  _Schedules(this.current);
  @override
  WorkoutSchedule? getSchedule() => current;
  @override
  Future<void> saveSchedule(WorkoutSchedule schedule) async =>
      current = schedule;
  @override
  Future<void> deleteSchedule() async => current = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(zones.initializeTimeZones);
  final plan = WorkoutSchedule(
    workoutHour: 18,
    workoutMinute: 0,
    workoutDays: [1],
  );
  tz.TZDateTime now() => tz.TZDateTime(tz.UTC, 2026, 10, 19, 10);

  test(
    'refresh replaces legacy and dated reminders while preserving unrelated IDs',
    () async {
      final service = _Service();
      service.pending.addAll({
        101: now(),
        400: now(),
        500: now(),
        NotificationIds.datedEarlyMax: now(),
        600: now(),
        999: now(),
      });
      final scheduler = WorkoutReminderScheduler(service, now: now);
      await scheduler.rescheduleAll(plan);
      expect(service.pending.keys, containsAll([600, 999]));
      expect(service.pending.keys, isNot(contains(101)));
      expect(service.pending.keys, isNot(contains(400)));
      expect(service.pending.keys, isNot(contains(500)));
      final first = Map.of(service.pending);
      await scheduler.rescheduleAll(plan);
      expect(service.pending, first);
      await scheduler.rescheduleAll(plan.copyWith(remindersEnabled: false));
      expect(service.pending.keys, [600, 999]);
    },
  );

  test(
    'time-zone refresh precedes calculation and calendar times use the new zone',
    () async {
      var zone = tz.UTC;
      var refreshes = 0;
      final service = _Service();
      final scheduler = WorkoutReminderScheduler(
        service,
        now: () => tz.TZDateTime.from(DateTime.utc(2026, 10, 19, 10), zone),
        refreshTimeZone: () async {
          refreshes++;
          zone = tz.getLocation('Asia/Kolkata');
        },
      );
      await scheduler.rescheduleAll(plan);
      expect(refreshes, 1);
      expect(
        service.pending.values.every((date) => date.location == zone),
        isTrue,
      );
      final early = service.pending.entries.firstWhere(
        (entry) =>
            entry.key >= NotificationIds.datedEarlyMin &&
            entry.key <= NotificationIds.datedEarlyMax,
      );
      expect([early.value.hour, early.value.minute], [17, 30]);
      await scheduler.scheduleTestNotification();
      expect(
        service.pending[999],
        tz.TZDateTime.from(DateTime.utc(2026, 10, 19, 10, 0, 10), zone),
      );
    },
  );

  test(
    'a history read failure leaves existing reminders intact and can retry',
    () async {
      final service = _Service()..pending[101] = now();
      final repository = FakeWorkoutRepository()
        ..schedule = plan
        ..failReadHistory = true;
      final scheduler = WorkoutReminderScheduler(
        service,
        workouts: repository,
        now: now,
      );
      await expectLater(scheduler.rescheduleAll(plan), throwsStateError);
      expect(service.pending.keys, [101]);
      repository.failReadHistory = false;
      await scheduler.rescheduleAll(plan);
      expect(service.pending.keys, isNot(contains(101)));
      expect(service.pending, isNotEmpty);
    },
  );

  test(
    'queued updates use the latest saved preference and cannot reinstall stale reminders',
    () async {
      final service = _Service()
        ..scheduleGate = Completer<void>()
        ..scheduleStarted = Completer<void>();
      final repository = FakeWorkoutRepository()..schedule = plan;
      final scheduler = WorkoutReminderScheduler(
        service,
        workouts: repository,
        now: now,
      );
      final first = scheduler.rescheduleAll(plan);
      await service.scheduleStarted!.future;
      repository.schedule = plan.copyWith(remindersEnabled: false);
      final disabled = scheduler.rescheduleAll(plan);
      service.scheduleGate!.complete();
      await Future.wait([first, disabled]);
      expect(service.pending, isEmpty);
      repository.schedule = null;
      await scheduler.rescheduleAll(plan);
      expect(service.pending, isEmpty);
    },
  );

  test(
    'a failed native schedule can retry without poisoning the scheduling queue',
    () async {
      final service = _Service()..failSchedule = true;
      final scheduler = WorkoutReminderScheduler(service, now: now);
      await expectLater(scheduler.rescheduleAll(plan), throwsStateError);
      service.failSchedule = false;
      await scheduler.rescheduleAll(plan);
      expect(service.pending, isNotEmpty);
      final first = Map.of(service.pending);
      await scheduler.rescheduleAll(plan);
      expect(service.pending, first);
    },
  );

  test(
    'disabling reminders does not require history or a working device-time-zone service',
    () async {
      final service = _Service()..pending[400] = now();
      final repository = FakeWorkoutRepository()
        ..schedule = plan.copyWith(remindersEnabled: false)
        ..failReadHistory = true;
      final scheduler = WorkoutReminderScheduler(
        service,
        workouts: repository,
        now: now,
        refreshTimeZone: () async => throw StateError('Unavailable'),
      );
      await scheduler.rescheduleAll(plan.copyWith(remindersEnabled: false));
      expect(service.pending, isEmpty);
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test(
      'native scheduling receives a one-shot full date on $platform',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        if (platform == TargetPlatform.android) {
          AndroidFlutterLocalNotificationsPlugin.registerWith();
        } else {
          IOSFlutterLocalNotificationsPlugin.registerWith();
        }
        const channel = MethodChannel(
          'dexterous.com/flutter/local_notifications',
        );
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        await NotificationService().schedule(
          id: 10000,
          title: 'Workout',
          body: 'Soon',
          date: now(),
          channelId: NotificationChannels.workoutReminders,
        );
        final call = calls.singleWhere(
          (call) => call.method == 'zonedSchedule',
        );
        final arguments = call.arguments as Map;
        expect(arguments['matchDateTimeComponents'], isNull);
        expect(
          arguments['scheduledDateTime'],
          startsWith('2026-10-19T10:00:00'),
        );
        expect(arguments['timeZoneName'], 'UTC');
      },
    );
  }

  test(
    'failed cancellation after schedule removal retains deletion and retries cleanup',
    () async {
      final service = _Service()..failCancel = true;
      final repository = _Schedules(plan);
      final scheduler = WorkoutReminderScheduler(service, now: now);
      final bloc = ScheduleBloc(repository, scheduler);
      addTearDown(bloc.close);
      final failed = bloc.stream.firstWhere((state) => state is ScheduleError);
      bloc.add(DeleteSchedule());
      await failed;
      expect(repository.current, isNull);
      expect((bloc.state as ScheduleError).schedule, isNull);
      service.failCancel = false;
      final loaded = bloc.stream.firstWhere((state) => state is ScheduleLoaded);
      bloc.add(LoadSchedule(refreshReminders: true));
      await loaded;
      expect(service.pending, isEmpty);
      expect((bloc.state as ScheduleLoaded).schedule, isNull);
    },
  );
}
