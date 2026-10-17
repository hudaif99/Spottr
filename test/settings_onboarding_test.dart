import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spottr/presentation/widgets/reminder_lifecycle.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spottr/core/theme/app_theme.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/domain/models/workout_models.dart';
import 'package:spottr/data/datasources/backup_restore_service.dart';
import 'package:spottr/data/repositories/notification_repository.dart';
import 'package:spottr/notifications/notification_permission_handler.dart';
import 'package:spottr/notifications/notification_service.dart';
import 'package:spottr/notifications/workout_reminder_scheduler.dart';
import 'package:spottr/presentation/blocs/history/history_bloc.dart';
import 'package:spottr/presentation/blocs/history/history_event.dart';
import 'package:spottr/presentation/blocs/history/history_state.dart';
import 'package:spottr/presentation/blocs/plans/plans_bloc.dart';
import 'package:spottr/presentation/blocs/plans/plans_event.dart';
import 'package:spottr/presentation/blocs/plans/plans_state.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_event.dart';
import 'package:spottr/presentation/blocs/schedule/schedule_state.dart';
import 'package:spottr/presentation/blocs/settings/settings_bloc.dart';
import 'package:spottr/presentation/screens/profile_appearance_screen.dart';
import 'package:spottr/presentation/screens/workout_schedule_settings_screen.dart';
import 'package:spottr/presentation/blocs/timer/timer_bloc.dart';
import 'package:spottr/presentation/blocs/workout/workout_bloc.dart';
import 'package:spottr/presentation/blocs/workout/workout_state.dart';
import 'package:spottr/presentation/screens/settings_screen.dart';
import 'package:spottr/presentation/screens/workout_preferences_screen.dart';
import 'package:spottr/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:spottr/presentation/widgets/spottr_button.dart';
import 'support/fake_workout_repository.dart';

class _Preferences extends LocalDatabaseService {
  int rest = 90;
  bool failRest = false;
  bool failComplete = false;
  int completionWrites = 0;
  bool? awake;
  bool? sound;
  Completer<void>? restGate;
  Completer<void>? profileGate;
  bool failProfile = false;
  String? name;
  int? age;
  double? height;
  double? weight;
  String theme = 'system';
  @override
  String? getUserName() => name;
  @override
  int? getUserAge() => age;
  @override
  String? getUserGender() => null;
  @override
  double? getUserHeight() => height;
  @override
  double? getUserWeight() => weight;
  @override
  String getThemeMode() => theme;
  @override
  bool getKeepScreenAwake() => awake ?? true;
  @override
  bool getPlayTimerSound() => sound ?? false;
  @override
  Future<void> saveProfile({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) async {
    await profileGate?.future;
    if (failProfile) throw StateError('Disk unavailable');
    this.name = name;
    this.age = age;
    this.height = height;
    this.weight = weight;
  }

  @override
  Future<void> saveThemeMode(String mode) async => theme = mode;
  @override
  int getRestTime() => rest;
  @override
  Future<void> saveRestTime(int seconds) async {
    await restGate?.future;
    if (failRest) throw StateError('Disk unavailable');
    rest = seconds;
  }

  @override
  Future<void> saveKeepScreenAwake(bool value) async => awake = value;
  @override
  Future<void> savePlayTimerSound(bool value) async => sound = value;
  @override
  Future<void> setOnboardingCompleted() async {
    completionWrites++;
    if (failComplete) throw StateError('Disk unavailable');
  }
}

class _ScheduleRepository implements NotificationRepository {
  WorkoutSchedule? schedule;
  Completer<void>? saveGate;
  int writes = 0;
  bool fail = false;
  @override
  WorkoutSchedule? getSchedule() => schedule;
  @override
  Future<void> deleteSchedule() async => schedule = null;
  @override
  Future<void> saveSchedule(WorkoutSchedule value) async {
    writes++;
    await saveGate?.future;
    if (fail) throw StateError('Disk unavailable');
    schedule = value;
  }
}

class _Scheduler extends WorkoutReminderScheduler {
  bool fail = false;
  int refreshes = 0;
  int cancellations = 0;
  Completer<void>? refreshGate;
  _Scheduler() : super(NotificationService());
  @override
  Future<void> rescheduleAll(WorkoutSchedule schedule) async {
    refreshes++;
    await refreshGate?.future;
    if (fail) throw StateError('Notification service unavailable');
  }

  @override
  Future<void> cancelWorkoutReminders() async {
    cancellations++;
  }

  @override
  Future<void> cancelStreakReminder() async {
    cancellations++;
  }

  @override
  Future<void> cancelWeeklySummary() async {
    cancellations++;
  }
}

class _Backup extends BackupRestoreService {
  int imports = 0;
  Completer<void>? gate;
  void Function()? restore;
  String? error;
  Rect? shareOrigin;
  _Backup(super.database);
  @override
  Future<String?> exportData({Rect? sharePositionOrigin}) async {
    shareOrigin = sharePositionOrigin;
    return null;
  }

  @override
  Future<String?> importData() async {
    imports++;
    await gate?.future;
    if (error == null) restore?.call();
    return error;
  }
}

class _Permission extends NotificationPermissionHandler {
  bool granted = false;
  int requests = 0;
  _Permission() : super(NotificationService());
  @override
  Future<bool> requestPermission() async {
    requests++;
    return granted;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final boundary = GlobalKey();
  late _Preferences prefs;
  late _ScheduleRepository schedules;
  late _Permission permission;
  late _Scheduler reminderScheduler;

  setUpAll(() async {
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    prefs = _Preferences();
    schedules = _ScheduleRepository();
    permission = _Permission();
    reminderScheduler = _Scheduler();
    GetIt.I.registerSingleton<LocalDatabaseService>(prefs);
    GetIt.I.registerSingleton<NotificationPermissionHandler>(permission);
  });
  tearDown(() async => GetIt.I.reset());

  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    double scale = 1,
    bool dark = false,
    bool ios = false,
    FakeWorkoutRepository? repository,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final workouts = repository ?? FakeWorkoutRepository();
    final settings = SettingsBloc(prefs);
    final schedule = ScheduleBloc(schedules, reminderScheduler)
      ..add(LoadSchedule());
    final plans = PlansBloc(workouts)..add(LoadPlans());
    final history = HistoryBloc(workouts)..add(LoadHistory());
    final workout = WorkoutBloc(workouts);
    final timer = TimerBloc(prefs);
    addTearDown(() async {
      for (final gate in [
        prefs.restGate,
        prefs.profileGate,
        schedules.saveGate,
        reminderScheduler.refreshGate,
      ]) {
        if (gate != null && !gate.isCompleted) gate.complete();
      }
      await settings.close();
      await schedule.close();
      await plans.close();
      await history.close();
      await workout.close();
      await timer.close();
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: schedule),
          BlocProvider.value(value: plans),
          BlocProvider.value(value: history),
          BlocProvider.value(value: workout),
          BlocProvider.value(value: timer),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: (dark ? AppTheme.darkTheme : AppTheme.lightTheme).copyWith(
              platform: ios ? TargetPlatform.iOS : TargetPlatform.android,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('SPOTTR_CAPTURE_UI')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/design-review').create(recursive: true);
      await File(
        'build/design-review/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder inStep(String step, String label) => find.descendant(
    of: find.byKey(ValueKey('$step-step')),
    matching: find.text(label),
  );

  Future<void> toNotifications(WidgetTester tester) async {
    await tap(tester, inStep('welcome', 'Continue'));
    await tap(tester, inStep('time', 'Continue'));
    await tap(tester, inStep('days', 'Mon'));
    await tap(tester, inStep('days', 'Wed'));
    await tap(tester, inStep('days', 'Continue'));
  }

  for (final (size, scale, dark, suffix) in [
    (const Size(390, 844), 1.0, false, 'light'),
    (const Size(320, 568), 1.8, true, 'large-text-dark'),
    (const Size(1194, 834), 1.0, true, 'tablet-dark'),
  ]) {
    testWidgets('settings remain usable and save rest in $suffix', (
      tester,
    ) async {
      await mount(
        tester,
        const SettingsScreen(),
        size: size,
        scale: scale,
        dark: dark,
      );
      await capture(tester, 'settings-$suffix');
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('Default rest time'));
      await capture(tester, 'rest-settings-$suffix');
      await tap(tester, find.text('120 s'));
      expect(prefs.rest, 120);
      expect(find.text('120 seconds between sets'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('app resume refreshes the reminder window', (tester) async {
    schedules.schedule = WorkoutSchedule(
      workoutHour: 18,
      workoutMinute: 0,
      workoutDays: [1, 3, 5],
    );
    await mount(
      tester,
      const ReminderLifecycle(child: Scaffold(body: Text('Training'))),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(reminderScheduler.refreshes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest saving handles errors and waits for storage', (
    tester,
  ) async {
    await mount(tester, const SettingsScreen());
    prefs.failRest = true;
    await tap(tester, find.text('Default rest time'));
    await tap(tester, find.text('120 s'));
    expect(find.text('Could not save rest time. Try again.'), findsOneWidget);
    expect(prefs.rest, 90);
    prefs.failRest = false;
    await tap(tester, find.text('Default rest time'));
    await tap(tester, find.text('Custom'));
    await tester.enterText(find.byType(TextFormField), '0');
    await tap(tester, find.text('Save rest time'));
    expect(find.text('Use 1–3599 seconds'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '75');
    prefs.restGate = Completer<void>();
    await tester.tap(find.text('Save rest time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(prefs.rest, 90);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    prefs.restGate!.complete();
    await tester.pumpAndSettle();
    expect(prefs.rest, 75);
    expect(find.text('75 seconds between sets'), findsOneWidget);
  });

  testWidgets('workout preference switches still persist changes', (
    tester,
  ) async {
    await mount(
      tester,
      const WorkoutPreferencesScreen(),
      size: const Size(320, 568),
      scale: 1.8,
      dark: true,
    );
    await capture(tester, 'workout-preferences-dark');
    await tap(tester, find.text('Keep screen awake'));
    await tap(tester, find.text('Rest timer sound'));
    expect(prefs.awake, isFalse);
    expect(prefs.sound, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale, dark, choice) in [
    (const Size(390, 844), 1.0, false, 'skip'),
    (const Size(320, 568), 1.8, true, 'granted'),
    (const Size(1194, 834), 1.0, false, 'denied'),
  ]) {
    testWidgets(
      'onboarding completes with $choice reminders and waits for saving',
      (tester) async {
        permission.granted = choice == 'granted';
        await mount(
          tester,
          const OnboardingFlowScreen(),
          size: size,
          scale: scale,
          dark: dark,
          ios: choice == 'denied',
        );
        await capture(tester, 'onboarding-welcome-$choice');
        await tap(tester, inStep('welcome', 'Continue'));
        await capture(tester, 'onboarding-time-$choice');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        expect(
          choice == 'denied'
              ? find.byType(CupertinoDatePicker)
              : find.byType(TimePickerDialog),
          findsOneWidget,
        );
        await tap(tester, find.text('Cancel'));
        await tap(tester, inStep('time', 'Continue'));
        await tap(tester, inStep('days', 'Mon'));
        await tap(tester, inStep('days', 'Wed'));
        await capture(tester, 'onboarding-days-$choice');
        await tap(tester, inStep('days', 'Continue'));
        await capture(tester, 'onboarding-notifications-$choice');
        await tap(
          tester,
          inStep(
            'notifications',
            choice == 'skip' ? 'Not now' : 'Allow notifications',
          ),
        );
        await capture(tester, 'onboarding-finish-$choice');
        schedules.saveGate = Completer<void>();
        await tester.ensureVisible(inStep('finish', 'Start using Spottr'));
        await tester.pumpAndSettle();
        await tester.tap(inStep('finish', 'Start using Spottr'));
        await tester.pump();
        expect(prefs.completionWrites, 0);
        expect(schedules.writes, 1);
        schedules.saveGate!.complete();
        await tester.pumpAndSettle();
        expect(prefs.completionWrites, 1);
        expect(schedules.schedule!.workoutDays, [1, 3]);
        expect(schedules.schedule!.workoutHour, 6);
        expect(schedules.schedule!.remindersEnabled, choice == 'granted');
        expect(permission.requests, choice == 'skip' ? 0 : 1);
        expect(find.text('Create a plan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('onboarding retries repeated save errors and completion errors', (
    tester,
  ) async {
    await mount(tester, const OnboardingFlowScreen());
    await toNotifications(tester);
    await tap(tester, inStep('notifications', 'Not now'));
    schedules.fail = true;
    for (var attempt = 0; attempt < 2; attempt++) {
      await tap(tester, inStep('finish', 'Start using Spottr'));
      expect(
        find.text('Could not save your schedule. Try again.'),
        findsOneWidget,
      );
      expect(prefs.completionWrites, 0);
      expect(
        tester
            .widget<SpottrButton>(
              find.widgetWithText(SpottrButton, 'Start using Spottr'),
            )
            .isLoading,
        isFalse,
      );
    }
    expect(schedules.writes, 2);
    schedules.fail = false;
    prefs.failComplete = true;
    await tap(tester, inStep('finish', 'Start using Spottr'));
    expect(find.text('Could not finish setup. Try again.'), findsOneWidget);
    expect(schedules.writes, 3);
    prefs.failComplete = false;
    await tap(tester, inStep('finish', 'Start using Spottr'));
    expect(schedules.writes, 3);
    expect(prefs.completionWrites, 2);
    expect(find.text('Create a plan'), findsOneWidget);
  });

  Future<void> enter(WidgetTester tester, String key, String value) async {
    final field = find.byKey(ValueKey(key));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  for (final (size, scale, dark, suffix) in [
    (const Size(390, 844), 1.0, false, 'light'),
    (const Size(320, 568), 1.8, true, 'large-text-dark'),
    (const Size(1194, 834), 1.0, true, 'tablet-dark'),
  ]) {
    testWidgets('profile saves and clears optional fields in $suffix', (
      tester,
    ) async {
      await mount(
        tester,
        const ProfileAppearanceScreen(),
        size: size,
        scale: scale,
        dark: dark,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Dark'));
      expect(prefs.theme, 'dark');
      await enter(tester, 'Profile name', 'Alex');
      await enter(tester, 'Age · years', '30');
      await enter(tester, 'Height · cm', '178');
      await enter(tester, 'Body weight · kg', '78');
      await tester.ensureVisible(find.text('Appearance'));
      await tester.pumpAndSettle();
      await capture(tester, 'profile-$suffix');
      await tap(tester, find.text('Save profile'));
      expect(find.text('Profile saved.'), findsOneWidget);
      expect(prefs.name, 'Alex');
      expect(prefs.age, 30);
      expect(prefs.height, 178);
      expect(prefs.weight, 78);
      for (final key in [
        'Profile name',
        'Age · years',
        'Height · cm',
        'Body weight · kg',
      ]) {
        await enter(tester, key, '');
      }
      await tap(tester, find.text('Save profile'));
      expect(prefs.name, isNull);
      expect(prefs.age, isNull);
      expect(prefs.height, isNull);
      expect(prefs.weight, isNull);
      final state = tester
          .element(find.byType(ProfileAppearanceScreen))
          .read<SettingsBloc>()
          .state;
      expect(state.userName, isNull);
      expect(state.userHeight, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'schedule retains selections through cancel, failure and retry in $suffix',
      (tester) async {
        schedules.schedule = WorkoutSchedule(
          workoutHour: 18,
          workoutMinute: 30,
          workoutDays: [1, 3],
          remindersEnabled: false,
        );
        await mount(
          tester,
          const WorkoutScheduleSettingsScreen(),
          size: size,
          scale: scale,
          dark: dark,
          ios: suffix == 'tablet-dark',
        );
        await capture(tester, 'schedule-$suffix');
        await tester.ensureVisible(
          find.text('Open Spottr every two weeks to keep reminders scheduled.'),
        );
        await tester.pumpAndSettle();
        await capture(tester, 'schedule-reminder-note-$suffix');
        await tap(tester, find.text('Training days'));
        await tap(tester, find.widgetWithText(FilterChip, 'Tue'));
        await capture(tester, 'schedule-days-$suffix');
        await tap(tester, find.byTooltip('Cancel day changes'));
        expect(schedules.schedule!.workoutDays, [1, 3]);
        await tap(tester, find.text('Training days'));
        await tap(tester, find.widgetWithText(FilterChip, 'Tue'));
        schedules.fail = true;
        await tap(tester, find.text('Save days'));
        expect(
          find.text('Could not save your schedule. Try again.'),
          findsOneWidget,
        );
        expect(find.text('Mon, Wed'), findsOneWidget);
        schedules.fail = false;
        await tap(tester, find.text('Retry'));
        expect(schedules.schedule!.workoutDays, [1, 2, 3]);
        await tap(tester, find.text('Workout time'));
        if (suffix == 'tablet-dark') {
          tester
              .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
              .onDateTimeChanged(DateTime(2000, 1, 1, 20, 15));
          await tap(tester, find.text('Done'));
          expect(schedules.schedule!.workoutHour, 20);
          expect(schedules.schedule!.workoutMinute, 15);
        } else {
          await tap(tester, find.text('Cancel'));
          expect(schedules.schedule!.workoutHour, 18);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('profile validates, waits for saving and retains failed input', (
    tester,
  ) async {
    await mount(tester, const ProfileAppearanceScreen());
    await enter(tester, 'Profile name', 'Alex');
    await enter(tester, 'Height · cm', '-1');
    await tap(tester, find.text('Save profile'));
    expect(find.text('Enter a positive number'), findsOneWidget);
    expect(prefs.name, isNull);
    await enter(tester, 'Height · cm', '180');
    prefs.failProfile = true;
    await tap(tester, find.text('Save profile'));
    expect(
      find.text('Could not save your changes. Try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('Profile name')))
          .controller!
          .text,
      'Alex',
    );
    prefs.failProfile = false;
    prefs.profileGate = Completer<void>();
    await tester.tap(find.text('Save profile'));
    await tester.pump();
    expect(prefs.name, isNull);
    expect(
      tester.widget<SpottrButton>(find.byType(SpottrButton)).isLoading,
      isTrue,
    );
    prefs.profileGate!.complete();
    await tester.pumpAndSettle();
    expect(prefs.name, 'Alex');
    expect(find.text('Profile saved.'), findsOneWidget);
  });

  testWidgets(
    'schedule reminder switch respects permission and turning off does not request it',
    (tester) async {
      schedules.schedule = WorkoutSchedule(
        workoutHour: 6,
        workoutMinute: 0,
        workoutDays: [1, 3],
        remindersEnabled: false,
      );
      await mount(tester, const WorkoutScheduleSettingsScreen());
      await tap(tester, find.text('Workout reminders'));
      expect(schedules.schedule!.remindersEnabled, isFalse);
      expect(schedules.schedule!.notificationPermissionStatus, 'denied');
      permission.granted = true;
      await tap(tester, find.text('Workout reminders'));
      expect(schedules.schedule!.remindersEnabled, isTrue);
      expect(permission.requests, 2);
      await tap(tester, find.text('Workout reminders'));
      expect(schedules.schedule!.remindersEnabled, isFalse);
      expect(permission.requests, 2);
    },
  );

  testWidgets(
    'schedule preserves persisted edits when notification rescheduling fails',
    (tester) async {
      schedules.schedule = WorkoutSchedule(
        workoutHour: 6,
        workoutMinute: 0,
        workoutDays: [1],
        remindersEnabled: false,
      );
      await mount(tester, const WorkoutScheduleSettingsScreen());
      reminderScheduler.fail = true;
      await tap(tester, find.text('Training days'));
      await tap(tester, find.widgetWithText(FilterChip, 'Wed'));
      await tap(tester, find.text('Save days'));
      expect(
        find.text('Schedule saved, but reminders could not update. Retry.'),
        findsOneWidget,
      );
      expect(find.text('Mon, Wed'), findsOneWidget);
      expect(schedules.schedule!.workoutDays, [1, 3]);
      reminderScheduler.fail = false;
      await tap(tester, find.text('Retry'));
      expect(
        find.text('Schedule saved, but reminders could not update. Retry.'),
        findsNothing,
      );
      expect(schedules.schedule!.workoutDays, [1, 3]);
    },
  );

  testWidgets('restore confirmation can cancel without opening the picker', (
    tester,
  ) async {
    final backup = _Backup(prefs);
    GetIt.I.registerSingleton<BackupRestoreService>(backup);
    await mount(
      tester,
      const SettingsScreen(),
      size: const Size(320, 568),
      scale: 1.8,
      dark: true,
    );
    await tester.scrollUntilVisible(find.text('Backup and restore'), 200);
    await tap(tester, find.text('Backup and restore'));
    await tap(tester, find.text('Restore backup'));
    expect(find.text('Replace current data?'), findsOneWidget);
    await capture(tester, 'restore-confirmation-large-text-dark');
    await tap(tester, find.text('Cancel'));
    expect(backup.imports, 0);
    expect(find.text('Backup restored.'), findsNothing);
    await tap(tester, find.text('Backup and restore'));
    await tap(tester, find.text('Export backup'));
    expect(backup.shareOrigin?.isEmpty, isFalse);
    expect(find.text('Backup shared.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore refreshes every screen and waits for reminder updates', (
    tester,
  ) async {
    final repository = FakeWorkoutRepository();
    final backup = _Backup(prefs)..gate = Completer<void>();
    GetIt.I.registerSingleton<BackupRestoreService>(backup);
    await mount(tester, const SettingsScreen(), repository: repository);
    reminderScheduler.refreshGate = Completer<void>();
    addTearDown(() {
      if (!backup.gate!.isCompleted) backup.gate!.complete();
      if (!reminderScheduler.refreshGate!.isCompleted) {
        reminderScheduler.refreshGate!.complete();
      }
    });
    final date = DateTime(2026, 10, 17);
    final day = WorkoutDay(
      id: 'day',
      name: 'Restored day',
      exercises: [Exercise(id: 'exercise', name: 'Squat')],
    );
    backup.restore = () {
      prefs.rest = 150;
      prefs.name = 'Restored name';
      prefs.theme = 'dark';
      repository.plans.add(
        Plan(id: 'plan', name: 'Restored routine', days: [day]),
      );
      repository.logs.add(
        WorkoutLog(
          id: 'history',
          planId: 'plan',
          dayId: 'day',
          dayName: day.name,
          startTime: date,
        ),
      );
      repository.active = ActiveWorkout(
        workoutLogId: 'restored-active',
        planId: 'plan',
        day: day,
        startTime: date,
        exerciseLogs: {},
      );
      schedules.schedule = WorkoutSchedule(
        workoutHour: 18,
        workoutMinute: 0,
        workoutDays: [2, 4],
        remindersEnabled: false,
      );
    };
    await tap(tester, find.text('Backup and restore'));
    await tap(tester, find.text('Restore backup'));
    await tester.tap(find.text('Choose backup'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(backup.imports, 1);
    expect(find.text('Backup restored.'), findsNothing);
    backup.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Backup restored.'), findsNothing);
    reminderScheduler.refreshGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Backup restored.'), findsOneWidget);
    final context = tester.element(find.byType(SettingsScreen));
    expect(
      (context.read<PlansBloc>().state as PlansLoaded).plans.single.name,
      'Restored routine',
    );
    expect(
      (context.read<HistoryBloc>().state as HistoryLoaded).logs,
      hasLength(1),
    );
    expect(context.read<SettingsBloc>().state.userName, 'Restored name');
    expect(context.read<SettingsBloc>().state.themeMode, 'dark');
    expect(
      (context.read<ScheduleBloc>().state as ScheduleLoaded)
          .schedule!
          .workoutDays,
      [2, 4],
    );
    expect(context.read<WorkoutBloc>().state, isA<WorkoutInProgress>());
    await tester.ensureVisible(find.text('150 seconds between sets'));
    expect(reminderScheduler.refreshes, 1);
    await tester.scrollUntilVisible(find.text('Backup and restore'), 200);
    await tap(tester, find.text('Backup and restore'));
    await tap(tester, find.text('Restore backup'));
    expect(
      find.text(
        'Finish or discard your current workout before restoring a backup.',
      ),
      findsOneWidget,
    );
    expect(backup.imports, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed restore keeps state and a restored empty schedule cancels old reminders',
    (tester) async {
      final backup = _Backup(prefs)..error = 'This backup is incomplete.';
      GetIt.I.registerSingleton<BackupRestoreService>(backup);
      schedules.schedule = WorkoutSchedule(
        workoutHour: 6,
        workoutMinute: 0,
        workoutDays: [1],
      );
      await mount(tester, const SettingsScreen());
      Future<void> restore() async {
        await tap(tester, find.text('Backup and restore'));
        await tap(tester, find.text('Restore backup'));
        await tap(tester, find.text('Choose backup'));
      }

      await restore();
      expect(find.text('This backup is incomplete.'), findsOneWidget);
      expect(schedules.schedule, isNotNull);
      expect(reminderScheduler.cancellations, 0);
      backup.error = null;
      backup.restore = () => schedules.schedule = null;
      await restore();
      expect(find.text('Backup restored.'), findsOneWidget);
      expect(reminderScheduler.cancellations, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restored data survives reminder failure and schedule retries independently',
    (tester) async {
      final backup = _Backup(prefs)
        ..restore = () {
          prefs.rest = 180;
          schedules.schedule = WorkoutSchedule(
            workoutHour: 18,
            workoutMinute: 0,
            workoutDays: [1],
            remindersEnabled: false,
          );
        };
      GetIt.I.registerSingleton<BackupRestoreService>(backup);
      await mount(tester, const SettingsScreen());
      reminderScheduler.fail = true;
      await tap(tester, find.text('Backup and restore'));
      await tap(tester, find.text('Restore backup'));
      await tap(tester, find.text('Choose backup'));
      expect(
        find.text(
          'Backup restored. Open Workout schedule to retry reminder updates.',
        ),
        findsOneWidget,
      );
      expect(prefs.rest, 180);
      reminderScheduler.fail = false;
      await tester.scrollUntilVisible(find.text('Workout schedule'), -200);
      await tap(tester, find.text('Workout schedule'));
      await tap(tester, find.text('Retry'));
      final context = tester.element(
        find.byType(WorkoutScheduleSettingsScreen),
      );
      expect(context.read<ScheduleBloc>().state, isA<ScheduleLoaded>());
      expect(backup.imports, 1);
      expect(reminderScheduler.refreshes, 2);
    },
  );

  testWidgets('queued schedule edits keep both time and day changes', (
    tester,
  ) async {
    schedules.schedule = WorkoutSchedule(
      workoutHour: 6,
      workoutMinute: 0,
      workoutDays: [1],
      remindersEnabled: false,
    );
    final bloc = ScheduleBloc(schedules, reminderScheduler)
      ..add(LoadSchedule());
    addTearDown(bloc.close);
    await tester.pump();
    schedules.saveGate = Completer<void>();
    bloc.add(UpdateWorkoutDays([2, 4]));
    bloc.add(UpdateWorkoutTime(const TimeOfDay(hour: 8, minute: 30)));
    await tester.pump();
    expect(schedules.writes, 1);
    schedules.saveGate!.complete();
    await bloc.stream.firstWhere(
      (state) => state is ScheduleLoaded && state.schedule?.workoutHour == 8,
    );
    expect(schedules.schedule!.workoutDays, [2, 4]);
    expect(schedules.schedule!.workoutMinute, 30);
  });
}
