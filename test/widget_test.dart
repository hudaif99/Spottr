import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spottr/core/theme/app_theme.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/domain/models/exercise.dart';
import 'package:spottr/domain/models/active_workout.dart';
import 'package:spottr/domain/models/set_log.dart';
import 'package:spottr/domain/models/workout_log.dart';
import 'package:spottr/domain/models/plan.dart';
import 'package:spottr/domain/models/workout_day.dart';
import 'package:spottr/domain/repositories/workout_repository.dart';
import 'package:spottr/presentation/blocs/history/history_bloc.dart';
import 'package:spottr/presentation/blocs/history/history_event.dart';
import 'package:spottr/presentation/blocs/plans/plans_bloc.dart';
import 'package:spottr/presentation/blocs/plans/plans_event.dart';
import 'package:spottr/presentation/blocs/settings/settings_bloc.dart';
import 'package:spottr/presentation/blocs/timer/timer_bloc.dart';
import 'package:spottr/presentation/blocs/timer/timer_event.dart';
import 'package:spottr/presentation/blocs/workout/workout_bloc.dart';
import 'package:spottr/presentation/blocs/workout/workout_event.dart';
import 'package:spottr/presentation/blocs/workout/workout_state.dart';
import 'package:spottr/presentation/screens/active_workout_screen.dart';
import 'package:spottr/presentation/screens/home_screen.dart';
import 'package:spottr/presentation/screens/history_screen.dart';
import 'package:spottr/presentation/screens/plan_management_screen.dart';
import 'package:spottr/presentation/screens/create_plan_screen.dart';
import 'package:spottr/presentation/widgets/spottr_button.dart';
import 'package:spottr/presentation/widgets/exercise_editor.dart';
import 'package:spottr/presentation/widgets/exercise_picker.dart';
import 'package:spottr/presentation/widgets/workout_value_control.dart';
import 'support/fake_workout_repository.dart';

class _Preferences extends LocalDatabaseService {
  @override
  bool getPlayTimerSound() => false;

  @override
  int getRestTime() => 90;
}

class _LibraryRepository extends FakeWorkoutRepository {
  Completer<void>? loadGate;
  bool failLibrary = false;
  @override
  Future<List<Exercise>> getExercises() async {
    await loadGate?.future;
    if (failLibrary) throw StateError('Unavailable');
    return super.getExercises();
  }
}

class _HistoryRepository extends FakeWorkoutRepository {
  Completer<void>? historyGate;
  @override
  Future<List<WorkoutLog>> getWorkoutLogs() async {
    await historyGate?.future;
    return super.getWorkoutLogs();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final boundary = GlobalKey();
  late TimerBloc currentTimer;
  setUpAll(() async {
    final font = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-Bold.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final exercises = [
    Exercise(
      id: 'kickback',
      name: 'Cable kickback',
      targetWeight: 12.5,
      note: 'Position the pulley at knee level. Keep your hips square.',
    ),
    Exercise(id: 'legpress', name: 'Leg press', targetWeight: 80),
    Exercise(id: 'rdl', name: 'Dumbbell Romanian deadlift', targetWeight: 22.5),
  ];
  final day = WorkoutDay(id: 'lower', name: 'Lower body', exercises: exercises);
  final plan = Plan(
    id: 'routine',
    name: 'Strength, three days',
    isActive: true,
    days: [day],
  );

  Future<(FakeWorkoutRepository, WorkoutBloc)> mount(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    bool dark = false,
    TargetPlatform? platform,
    double textScale = 1,
    bool start = false,
    Plan? initialPlan,
    FakeWorkoutRepository? repository,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = (repository ?? FakeWorkoutRepository())
      ..plans.add(initialPlan ?? plan);
    final workout = WorkoutBloc(repo);
    final plans = PlansBloc(repo)..add(LoadPlans());
    final history = HistoryBloc(repo)..add(LoadHistory());
    final settings = SettingsBloc(_Preferences());
    final timer = TimerBloc(_Preferences());
    currentTimer = timer;
    addTearDown(() async {
      await workout.close();
      await plans.close();
      await history.close();
      await settings.close();
      await timer.close();
    });
    if (start) {
      final ready = workout.stream.firstWhere(
        (state) => state is WorkoutInProgress && !state.isSaving,
      );
      workout.add(StartWorkout(plan: plan, day: day));
      await ready;
    }
    await tester.pumpWidget(
      RepositoryProvider<WorkoutRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: workout),
            BlocProvider.value(value: plans),
            BlocProvider.value(value: history),
            BlocProvider.value(value: settings),
            BlocProvider.value(value: timer),
          ],
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: (dark ? AppTheme.darkTheme : AppTheme.lightTheme).copyWith(
                platform: platform,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: screen,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    return (repo, workout);
  }

  Future<void> unmount(WidgetTester tester) async {
    currentTimer.add(ResetTimer());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
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

  for (final (size, scale, dark, name) in [
    (const Size(390, 844), 1.0, false, 'exercise-picker-light'),
    (const Size(390, 844), 1.0, true, 'exercise-picker-dark'),
    (const Size(320, 568), 1.8, true, 'exercise-picker-large-text'),
    (const Size(1194, 834), 1.0, false, 'exercise-picker-tablet'),
  ]) {
    testWidgets('picker reuses setup with a new entry in $name', (
      tester,
    ) async {
      Exercise? selected;
      await mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => selected = await showExercisePicker(
                context,
                localExercises: exercises,
              ),
              child: const Text('Choose'),
            ),
          ),
        ),
        size: size,
        textScale: scale,
        dark: dark,
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      await capture(tester, name);
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'hex bar',
      );
      await tester.pumpAndSettle();
      expect(find.text('Trap bar deadlift'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'pulley',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('pick-${exercises.first.identityId}')),
      );
      await tester.tap(
        find.byKey(ValueKey('pick-${exercises.first.identityId}')),
      );
      await tester.pumpAndSettle();
      expect(selected!.id, isNot(exercises.first.id));
      expect(selected!.identityId, exercises.first.identityId);
      expect(selected!.note, exercises.first.note);
      expect(selected!.targetWeight, exercises.first.targetWeight);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'picker keeps custom entry and search usable through a compact keyboard',
    (tester) async {
      Exercise? selected;
      await mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  selected = await showExercisePicker(context),
              child: const Text('Choose'),
            ),
          ),
        ),
        size: const Size(568, 320),
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 160);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'My trainer movement',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Create exercise'),
        80,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Create exercise'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'My trainer movement',
      );
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add exercise'));
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      expect(selected!.name, 'My trainer movement');
      expect(selected!.identityId, startsWith('custom:'));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'adding a saved custom movement keeps shared history and plan ownership',
    (tester) async {
      final (repo, _) = await mount(
        tester,
        const ActiveWorkoutScreen(),
        start: true,
      );
      final custom = Exercise(
        id: 'saved-custom',
        name: 'Trainer row',
        note: 'Seat at 3',
        targetWeight: 30,
      );
      repo.exercises.add(custom);
      await tester.tap(find.text('Exercise 1 of 3 · overview'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'Trainer row',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('pick-${custom.identityId}')));
      await tester.pumpAndSettle();
      final added = repo.active!.day.exercises.last;
      expect(added.id, isNot(custom.id));
      expect(added.identityId, custom.identityId);
      expect(added.note, 'Seat at 3');
      expect(repo.active!.exerciseLogs[added.id]!.first.weight, 30);
      expect(repo.plans.single.days.single.exercises, hasLength(3));
      expect(repo.exercises.single, same(custom));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets('picker search stays responsive during load and error retry', (
    tester,
  ) async {
    final repo = _LibraryRepository()
      ..loadGate = Completer<void>()
      ..failLibrary = true;
    await mount(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showExercisePicker(context),
            child: const Text('Choose'),
          ),
        ),
      ),
      repository: repo,
      dark: true,
    );
    await tester.tap(find.text('Choose'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.widgetWithText(TextField, 'Search'), 'hex bar');
    await tester.pump();
    expect(find.text('Trap bar deadlift'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await capture(tester, 'exercise-picker-loading-dark');
    repo.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Trap bar deadlift'), findsOneWidget);
    await capture(tester, 'exercise-picker-error-dark');
    repo.failLibrary = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Trap bar deadlift'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Search'),
      'New custom movement',
    );
    await tester.pumpAndSettle();
    await capture(tester, 'exercise-picker-empty-dark');
    await tester.tap(find.text('Create exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Search'))
          .controller!
          .text,
      'New custom movement',
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('plan popups do not restore text focus on ${platform.name}', (
      tester,
    ) async {
      await mount(tester, const CreatePlanScreen(), platform: platform);
      final dayField = find.widgetWithText(TextField, 'Workout day');
      Future<void> focusDay() async {
        await tester.ensureVisible(dayField);
        await tester.enterText(dayField, 'Push day');
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);
      }

      void expectNoKeyboard() {
        expect(tester.testTextInput.isVisible, isFalse);
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .any((field) => field.focusNode.hasFocus),
          isFalse,
        );
        expect(tester.widget<TextField>(dayField).controller!.text, 'Push day');
      }

      await focusDay();
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('pick-${exercises.first.identityId}')),
      );
      await tester.pumpAndSettle();
      expectNoKeyboard();
      await capture(tester, 'plan-focus-dismissed-${platform.name}');

      await focusDay();
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expectNoKeyboard();

      for (final save in [false, true]) {
        await focusDay();
        await tester.tap(find.text('Cable kickback'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('Setup note')),
          'Seat at 3',
        );
        if (save) {
          await tester.ensureVisible(find.text('Save details'));
          await tester.tap(find.text('Save details'));
        } else {
          await tester.tap(find.byTooltip('Cancel'));
        }
        await tester.pumpAndSettle();
        expectNoKeyboard();
      }
      expect(find.textContaining('Seat at 3'), findsOneWidget);

      for (final tooltip in ['Day options', 'Cable kickback options']) {
        await focusDay();
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expectNoKeyboard();
      }
      await focusDay();
      await tester.tap(find.byTooltip('Cable kickback options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expectNoKeyboard();
      await focusDay();
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('custom editor does not restore picker search focus', (
    tester,
  ) async {
    await mount(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showExercisePicker(context),
            child: const Text('Choose'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    final search = find.widgetWithText(TextField, 'Search');
    await tester.enterText(search, 'Trainer movement');
    await tester.tap(find.text('Create exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Changed movement',
    );
    await tester.tap(find.byTooltip('Cancel').last);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      tester.widget<TextField>(search).controller!.text,
      'Trainer movement',
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final wide in [false, true]) {
    testWidgets(
      'progress navigation does not restore search focus with wide=$wide',
      (tester) async {
        GetIt.I.registerSingleton<LocalDatabaseService>(_Preferences());
        addTearDown(() => GetIt.I.unregister<LocalDatabaseService>());
        final repo = FakeWorkoutRepository()
          ..logs.add(
            WorkoutLog(
              id: 'logged',
              planId: plan.id,
              dayId: day.id,
              dayName: day.name,
              startTime: DateTime(2026, 10, 18),
              exerciseNames: {exercises.first.id: exercises.first.name},
              exerciseIdentities: {
                exercises.first.id: exercises.first.identityId,
              },
              exerciseLogs: {
                exercises.first.id: [
                  SetLog(id: 'set', weight: 20, reps: 10, isCompleted: true),
                ],
              },
            ),
          );
        await mount(
          tester,
          const HomeScreen(),
          repository: repo,
          size: wide ? const Size(1194, 834) : const Size(390, 844),
        );
        Finder destination(String label) => find.descendant(
          of: wide ? find.byType(NavigationRail) : find.byType(NavigationBar),
          matching: find.text(label),
        );
        await tester.tap(destination('Progress'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exercises'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Search'),
          'Cable',
        );
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);
        await tester.tap(find.text(exercises.first.name));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.enterText(
          find.widgetWithText(TextField, 'Search'),
          'Cable',
        );
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.enterText(
          find.widgetWithText(TextField, 'Search'),
          'Cable',
        );
        await tester.tap(destination('Plans'));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.tap(destination('Progress'));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        final search = tester.widget<EditableText>(find.byType(EditableText));
        expect(search.controller.text, 'Cable');
        expect(search.focusNode.hasFocus, isFalse);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      },
    );
  }

  testWidgets(
    'plan additions reuse custom identity while keeping entry details independent',
    (tester) async {
      final (repo, _) = await mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CreatePlanScreen(plan: plan),
                ),
              ),
              child: const Text('Edit routine'),
            ),
          ),
        ),
      );
      final custom = Exercise(
        id: 'saved-custom',
        name: 'Trainer row',
        note: 'Seat at 3',
      );
      repo.exercises.add(custom);
      await tester.tap(find.text('Edit routine'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add exercise'));
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'Trainer row',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('pick-${custom.identityId}')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save plan'));
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();
      final added = repo.plans.single.days.single.exercises.last;
      expect(added.id, isNot(custom.id));
      expect(added.identityId, custom.identityId);
      expect(added.note, 'Seat at 3');
      expect(repo.exercises.single, same(custom));
      expect(plan.days.single.exercises, hasLength(3));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'partial workout finishes after one confirmation and shows only logged work',
    (tester) async {
      final (repo, _) = await mount(tester, const HomeScreen());
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log set 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish workout'));
      await tester.pumpAndSettle();
      expect(find.text('Finish your workout?'), findsOneWidget);
      expect(
        find.text(
          '1 completed set will be saved. Unfinished sets stay out of your totals.',
        ),
        findsOneWidget,
      );
      await capture(tester, 'partial-workout-finish-light');
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveWorkoutScreen), findsNothing);
      expect(repo.logs, hasLength(1));
      expect(repo.logs.single.totalVolume, 125);
      expect(repo.active, isNull);
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lower body'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutDetailScreen), findsOneWidget);
      expect(find.text('Cable kickback'), findsOneWidget);
      expect(find.text('Leg press'), findsNothing);
      expect(find.text('Set 2'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  for (final (size, scale, dark, suffix) in [
    (const Size(390, 844), 1.0, false, 'light'),
    (const Size(320, 568), 1.8, true, 'large-text-dark'),
  ]) {
    testWidgets('recovery check blocks logging and retries in $suffix', (
      tester,
    ) async {
      final repo = FakeWorkoutRepository()
        ..failReadHistory = true
        ..active = ActiveWorkout(
          workoutLogId: 'recover',
          planId: plan.id,
          day: day,
          startTime: DateTime.now(),
          exerciseLogs: {
            for (final exercise in exercises)
              exercise.id: [
                SetLog(id: '${exercise.id}-set', reps: 10, weight: 12.5),
              ],
          },
        );
      final (_, workout) = await mount(
        tester,
        const ActiveWorkoutScreen(),
        repository: repo,
        size: size,
        textScale: scale,
        dark: dark,
      );
      workout.add(ResumeWorkout());
      await tester.pumpAndSettle();
      expect((workout.state as WorkoutInProgress).isReadOnly, isTrue);
      expect(
        tester
            .widget<SpottrButton>(
              find.widgetWithText(SpottrButton, 'Log set 1'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<PopupMenuButton<String>>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is PopupMenuButton<String> &&
                    widget.tooltip == 'Workout options',
              ),
            )
            .enabled,
        isFalse,
      );
      await capture(tester, 'workout-recovery-$suffix');
      expect(tester.takeException(), isNull);
      repo.failReadHistory = false;
      await tester.tap(find.text('Retry recovery'));
      await tester.pumpAndSettle();
      expect((workout.state as WorkoutInProgress).isReadOnly, isFalse);
      expect(repo.active!.workoutLogId, 'recover');
      expect(find.text('Finish workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('Today exposes failed cache recovery and can retry it', (
    tester,
  ) async {
    final repo = FakeWorkoutRepository()..failReadActive = true;
    final (_, workout) = await mount(
      tester,
      const HomeScreen(),
      repository: repo,
    );
    workout.add(ResumeWorkout());
    await tester.pumpAndSettle();
    expect(find.text('Retry recovery'), findsOneWidget);
    repo.failReadActive = false;
    await tester.tap(find.text('Retry recovery'));
    await tester.pumpAndSettle();
    expect(find.text('Retry recovery'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets(
    'starting with an already saved cache returns to Today after cleanup',
    (tester) async {
      final repo = FakeWorkoutRepository()
        ..active = ActiveWorkout(
          workoutLogId: 'committed',
          planId: plan.id,
          day: day,
          startTime: DateTime.now(),
          exerciseLogs: const {},
        );
      repo.logs.add(
        WorkoutLog(
          id: 'committed',
          planId: plan.id,
          dayId: day.id,
          dayName: day.name,
          startTime: DateTime.now(),
        ),
      );
      await mount(tester, const HomeScreen(), repository: repo);
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveWorkoutScreen), findsNothing);
      expect(find.text('Start workout'), findsOneWidget);
      expect(repo.active, isNull);
      expect(repo.logs, hasLength(1));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets('Today waits for history before recommending a workout', (
    tester,
  ) async {
    final repo = _HistoryRepository()..historyGate = Completer<void>();
    addTearDown(() {
      if (!repo.historyGate!.isCompleted) repo.historyGate!.complete();
    });
    await mount(tester, const HomeScreen(), repository: repo);
    expect(find.text('Loading your workout history…'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(find.text('This week'), findsNothing);
    repo.historyGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'Today retries history without inventing zero progress or a next day',
    (tester) async {
      final now = DateTime(2026, 10, 17, 18);
      final upper = WorkoutDay(
        id: 'upper',
        name: 'Upper body',
        exercises: exercises,
      );
      final routine = plan.copyWith(days: [day, upper]);
      final repo = FakeWorkoutRepository()
        ..failReadHistory = true
        ..logs.add(
          WorkoutLog(
            id: 'previous',
            planId: plan.id,
            dayId: day.id,
            dayName: day.name,
            startTime: now.subtract(const Duration(days: 1)),
            exerciseLogs: {
              'kickback': [SetLog(id: 'done', isCompleted: true)],
            },
          ),
        );
      await mount(
        tester,
        HomeScreen(now: () => now),
        repository: repo,
        initialPlan: routine,
      );
      await tester.pumpAndSettle();
      expect(find.text('Start workout'), findsNothing);
      expect(find.text('This week'), findsNothing);
      await capture(tester, 'today-history-error');
      repo.failReadHistory = false;
      await tester.tap(find.text('Retry loading history'));
      await tester.pumpAndSettle();
      expect(find.text('Upper body'), findsOneWidget);
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      expect(repo.active!.day.id, 'upper');
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  for (final (size, scale, dark, name) in [
    (const Size(390, 844), 1.0, false, 'today-week-light'),
    (const Size(320, 568), 1.8, true, 'today-week-large-text'),
    (const Size(1194, 834), 1.0, true, 'today-week-tablet'),
  ]) {
    testWidgets('Today shows only recorded duration in $name', (tester) async {
      final now = DateTime(2026, 10, 17, 18);
      final repo = FakeWorkoutRepository()
        ..logs.addAll([
          WorkoutLog(
            id: 'legacy',
            planId: plan.id,
            dayId: day.id,
            dayName: 'Older workout',
            startTime: now.subtract(const Duration(hours: 1)),
            exerciseLogs: {
              'kickback': [SetLog(id: 'legacy-set', isCompleted: true)],
            },
          ),
          WorkoutLog(
            id: 'valid',
            planId: plan.id,
            dayId: day.id,
            dayName: 'Recorded workout',
            startTime: now.subtract(const Duration(days: 1, minutes: 20)),
            endTime: now.subtract(const Duration(days: 1)),
            exerciseLogs: {
              'kickback': [SetLog(id: 'completed-set', isCompleted: true)],
            },
          ),
        ]);
      await mount(
        tester,
        HomeScreen(now: () => now),
        repository: repo,
        size: size,
        textScale: scale,
        dark: dark,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('This week'), 150);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('This week'));
      await tester.pumpAndSettle();
      await capture(tester, '$name-calendar');
      await tester.scrollUntilVisible(find.text('minutes recorded'), 150);
      await tester.pumpAndSettle();
      expect(find.text('20'), findsOneWidget);
      expect(
        find.text('Some workouts have no recorded duration.'),
        findsOneWidget,
      );
      await capture(tester, name);
      await tester.scrollUntilVisible(
        find.textContaining('Duration unavailable'),
        120,
      );
      await tester.pumpAndSettle();
      expect(find.text('Older workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('Today refreshes the calendar after resuming on a new day', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 18, 23, 59);
    await mount(tester, HomeScreen(now: () => now));
    expect(find.text('Sunday, 18 October'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 10, 19, 0, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Monday, 19 October'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Progress search remains reachable in compact landscape', (
    tester,
  ) async {
    final repo = FakeWorkoutRepository()
      ..logs.add(
        WorkoutLog(
          id: 'completed',
          planId: plan.id,
          dayId: day.id,
          dayName: day.name,
          startTime: DateTime(2026, 10, 17),
          exerciseNames: {'kickback': 'Cable kickback'},
          exerciseLogs: {
            'kickback': [
              SetLog(id: 'done', isCompleted: true, weight: 20, reps: 8),
            ],
          },
        ),
      );
    await mount(
      tester,
      const HomeScreen(),
      repository: repo,
      size: const Size(568, 320),
      textScale: 1.8,
      dark: true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'cable');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'progress-compact-landscape');
    await unmount(tester);
  });

  for (final tab in ['Today', 'Plans', 'Progress']) {
    testWidgets('$tab requires a second device back press to exit', (
      tester,
    ) async {
      final exitCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exitCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await mount(tester, const HomeScreen(), platform: TargetPlatform.android);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(exitCalls, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exitCalls, hasLength(1));
      await unmount(tester);
    });
  }

  testWidgets(
    'exit confirmation expires and child routes still navigate back',
    (tester) async {
      final exitCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exitCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await mount(tester, const HomeScreen(), platform: TargetPlatform.android);
      Navigator.of(tester.element(find.byType(HomeScreen))).push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Details')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsNothing);
      expect(find.text('Press back again to exit'), findsNothing);
      expect(exitCalls, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 3));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(exitCalls, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exitCalls, hasLength(1));
      await unmount(tester);
    },
  );

  testWidgets('Today starts the suggested workout with one tap', (
    tester,
  ) async {
    final (repo, _) = await mount(tester, const HomeScreen());
    expect(find.text('Start workout'), findsOneWidget);
    await capture(tester, 'today-light');
    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Log set 1'), findsOneWidget);
    expect(repo.active!.day.id, day.id);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final (size, scale, name) in [
    (const Size(390, 844), 1.0, 'today-dark'),
    (const Size(320, 568), 1.8, 'today-large-text'),
  ]) {
    testWidgets('Today remains usable in $name', (tester) async {
      final (repo, _) = await mount(
        tester,
        const HomeScreen(),
        size: size,
        textScale: scale,
        dark: true,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, name);
      await tester.ensureVisible(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.active!.day.id, day.id);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'logging a zero-default exercise carries its weight into the next set',
    (tester) async {
      final fresh = Exercise(id: 'fresh', name: 'Cable row');
      final freshDay = WorkoutDay(
        id: 'fresh-day',
        name: 'Pull',
        exercises: [fresh],
      );
      final freshPlan = Plan(
        id: 'fresh-plan',
        name: 'Pull routine',
        isActive: true,
        days: [freshDay],
      );
      final (repo, _) = await mount(
        tester,
        const HomeScreen(),
        initialPlan: freshPlan,
      );
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      final weight = find.byWidgetPredicate(
        (widget) =>
            widget is WorkoutValueControl && widget.label == 'Weight · kg',
      );
      expect(tester.widget<WorkoutValueControl>(weight).value, 0);
      await tester.tap(
        find.descendant(of: weight, matching: find.byType(TextButton)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '25');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log set 1'));
      await tester.pumpAndSettle();
      expect(find.text('Log set 2'), findsOneWidget);
      expect(tester.widget<WorkoutValueControl>(weight).value, 25);
      expect(repo.active!.exerciseLogs[fresh.id]![1].isCompleted, isFalse);
      await tester.tap(find.byTooltip('Increase Weight · kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log set 2'));
      await tester.pumpAndSettle();
      expect(find.text('Log set 3'), findsOneWidget);
      expect(tester.widget<WorkoutValueControl>(weight).value, 27.5);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  for (final dark in [false, true]) {
    testWidgets('compact logging stays reachable with history and rest $dark', (
      tester,
    ) async {
      final repo = FakeWorkoutRepository()
        ..active = ActiveWorkout(
          workoutLogId: 'anchor',
          planId: plan.id,
          day: day,
          startTime: DateTime.now(),
          exerciseLogs: {
            for (final e in exercises)
              e.id: [
                for (var i = 0; i < 3; i++)
                  SetLog(id: '${e.id}-$i', reps: 10, weight: 12.5),
              ],
          },
          previousExerciseLogs: {
            exercises.first.id: [
              SetLog(id: 'previous', reps: 9, weight: 12.5, isCompleted: true),
            ],
          },
        );
      final (_, workout) = await mount(
        tester,
        const ActiveWorkoutScreen(),
        size: const Size(320, 568),
        dark: dark,
        repository: repo,
      );
      workout.add(ResumeWorkout());
      await tester.pumpAndSettle();
      expect(find.text('Log set 1').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Log set 1'));
      await tester.pumpAndSettle();
      expect(find.text('Log set 2').hitTestable(), findsOneWidget);
      expect(find.text('+30s').hitTestable(), findsOneWidget);
      await capture(tester, 'workout-anchor-rest-${dark ? 'dark' : 'light'}');
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect((workout.state as WorkoutInProgress).restUntil, isNull);
      expect(
        repo.active!.exerciseLogs[exercises.first.id]!.first.isCompleted,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'final-set shortcut saves only the final set and preserves history position',
    (tester) async {
      final (repo, _) = await mount(tester, const HomeScreen());
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Final set only'));
      await tester.pumpAndSettle();
      expect(find.text('Set 3 of 3'), findsOneWidget);
      expect(
        repo.active!.exerciseLogs[exercises.first.id]!.any(
          (s) => s.isCompleted,
        ),
        isFalse,
      );
      await tester.tap(find.text('Log set 3'));
      await tester.pumpAndSettle();
      expect(find.text('Final set logged'), findsOneWidget);
      expect(find.text('Exercise complete'), findsNothing);
      await capture(tester, 'workout-final-set-logged');
      await tester.tap(find.text('Finish workout'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '1 completed set will be saved. Unfinished sets stay out of your totals.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      final saved = repo.logs.single;
      expect(saved.totalVolume, 125);
      expect(
        saved.exerciseLogs[exercises.first.id]!.map((s) => s.isCompleted),
        [false, false, true],
      );
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lower body'));
      await tester.pumpAndSettle();
      expect(find.text('Set 3'), findsOneWidget);
      expect(find.text('Set 1'), findsNothing);
      expect(find.text('Set 2'), findsNothing);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets('final-set logging retries, resumes and allows earlier sets', (
    tester,
  ) async {
    final (repo, _) = await mount(
      tester,
      const ActiveWorkoutScreen(),
      start: true,
      size: const Size(320, 568),
      dark: true,
    );
    await tester.tap(find.text('Final set only'));
    await tester.pumpAndSettle();
    expect(find.text('Log set 3').hitTestable(), findsOneWidget);
    await capture(tester, 'workout-final-set-entry-dark');
    repo.failSave = true;
    await tester.tap(find.text('Log set 3'));
    await tester.pumpAndSettle();
    expect(find.text('Save pending'), findsOneWidget);
    expect(
      repo.active!.exerciseLogs[exercises.first.id]!.last.isCompleted,
      isFalse,
    );
    repo.failSave = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      repo.active!.exerciseLogs[exercises.first.id]!.map((s) => s.isCompleted),
      [false, false, true],
    );
    await unmount(tester);
    final (_, restored) = await mount(
      tester,
      const ActiveWorkoutScreen(),
      repository: repo,
      size: const Size(320, 568),
      dark: true,
    );
    restored.add(ResumeWorkout());
    await tester.pumpAndSettle();
    expect(find.text('Final set logged'), findsOneWidget);
    await tester.ensureVisible(find.text('Log earlier sets'));
    await tester.tap(find.text('Log earlier sets'));
    await tester.pumpAndSettle();
    expect(find.text('Log set 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Log set 1'));
    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();
    expect(
      repo.active!.exerciseLogs[exercises.first.id]!.map((s) => s.isCompleted),
      [true, false, true],
    );
    await tester.ensureVisible(find.byTooltip('Undo set 3'));
    await tester.tap(find.byTooltip('Undo set 3'));
    await tester.pumpAndSettle();
    expect(find.text('Log set 2'), findsOneWidget);
    expect(
      repo.active!.exerciseLogs[exercises.first.id]!.map((s) => s.isCompleted),
      [true, false, false],
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('focused workout logs, undoes, and retains the setup cue', (
    tester,
  ) async {
    final (repo, _) = await mount(
      tester,
      const ActiveWorkoutScreen(),
      start: true,
    );
    expect(find.text(exercises.first.note), findsOneWidget);
    await capture(tester, 'workout-light');
    await tester.tap(find.text('Log set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(repo.active!.exerciseLogs['kickback']!.first.isCompleted, isTrue);
    expect(find.text('Log set 2'), findsOneWidget);
    expect(find.text('Set 2 of 3'), findsOneWidget);
    expect(find.text('Logged'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Undo set 1'));
    await tester.tap(find.byTooltip('Undo set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(repo.active!.exerciseLogs['kickback']!.first.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final (size, scale, dark, name) in [
    (const Size(390, 844), 1.0, false, 'workout-overview-light'),
    (const Size(390, 844), 1.0, true, 'workout-overview-dark'),
    (const Size(320, 568), 1.8, true, 'workout-overview-large-text'),
    (const Size(1194, 834), 1.0, false, 'workout-overview-tablet'),
  ]) {
    testWidgets('session moves preserve focus and logged work in $name', (
      tester,
    ) async {
      final (repo, _) = await mount(
        tester,
        const ActiveWorkoutScreen(),
        start: true,
        size: size,
        textScale: scale,
        dark: dark,
      );
      await tester.ensureVisible(find.text('Log set 1'));
      await tester.tap(find.text('Log set 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      if (size.width < 840) {
        await tester.ensureVisible(find.text('Exercise 1 of 3 · overview'));
        await tester.tap(find.text('Exercise 1 of 3 · overview'));
        await tester.pumpAndSettle();
      }
      await capture(tester, name);
      await tester.ensureVisible(find.byTooltip('Options for Leg press'));
      await tester.tap(find.byTooltip('Options for Leg press'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move earlier'));
      await tester.pumpAndSettle();
      expect(repo.active!.day.exercises.map((exercise) => exercise.id), [
        'legpress',
        'kickback',
        'rdl',
      ]);
      expect(repo.active!.exerciseLogs['kickback']!.first.isCompleted, isTrue);
      final rows = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .where(
            (row) =>
                row.key is ValueKey<String> &&
                (row.key! as ValueKey<String>).value.startsWith('overview-'),
          )
          .toList();
      expect(rows.first.key, const ValueKey('overview-legpress'));
      expect(rows[1].selected, isTrue);
      await tester.ensureVisible(find.byTooltip('Options for Cable kickback'));
      await tester.tap(find.byTooltip('Options for Cable kickback'));
      await tester.pumpAndSettle();
      final replace = tester.widget<PopupMenuItem<String>>(
        find.ancestor(
          of: find.text('Replace exercise'),
          matching: find.byType(PopupMenuItem<String>),
        ),
      );
      expect(replace.enabled, isFalse);
      await capture(tester, '$name-options');
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'overview replacement starts fresh and saves only to the session',
    (tester) async {
      final (repo, _) = await mount(
        tester,
        const ActiveWorkoutScreen(),
        start: true,
      );
      await tester.tap(find.text('Exercise 1 of 3 · overview'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Options for Cable kickback'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create exercise'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Replaces unlogged sets in this workout. Your plan stays unchanged.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('Setup note')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(find.byType(TextFormField).first, 'Barbell squat');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      await capture(tester, 'workout-replacement-light');
      await tester.tap(find.widgetWithText(SpottrButton, 'Replace exercise'));
      await tester.pumpAndSettle();
      final updated = repo.active!.day.exercises.first;
      expect(updated.name, 'Barbell squat');
      expect(updated.id, isNot('kickback'));
      expect(updated.note, isEmpty);
      expect(repo.active!.exerciseLogs.containsKey('kickback'), isFalse);
      expect(
        repo.plans.single.days.single.exercises.first.name,
        'Cable kickback',
      );
      expect(find.text('Barbell squat'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  for (final (size, scale, dark, name) in [
    (const Size(320, 568), 1.0, false, 'workout-small'),
    (const Size(320, 568), 1.8, true, 'workout-large-text'),
    (const Size(1194, 834), 1.0, false, 'workout-tablet'),
    (const Size(390, 844), 1.0, true, 'workout-dark'),
  ]) {
    testWidgets('workout fits $name', (tester) async {
      final (repo, _) = await mount(
        tester,
        const ActiveWorkoutScreen(),
        start: true,
        size: size,
        textScale: scale,
        dark: dark,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, name);
      await tester.ensureVisible(find.text('Log set 1'));
      await tester.tap(find.text('Log set 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(repo.active!.exerciseLogs['kickback']!.first.isCompleted, isTrue);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'exercise editor rejects invalid targets and saves optional notes',
    (tester) async {
      Exercise? saved;
      await mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await showExerciseEditor(context);
              },
              child: const Text('Add'),
            ),
          ),
        ),
        size: const Size(320, 568),
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await capture(tester, 'exercise-editor-small');
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Cable kickback',
      );
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Pulley at knee level',
      );
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      expect(saved!.note, 'Pulley at knee level');
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  for (final (size, scale, dark, name) in [
    (const Size(390, 844), 1.0, true, 'exercise-editor-dark'),
    (const Size(320, 568), 1.8, false, 'exercise-editor-large-text'),
    (const Size(1194, 834), 1.0, false, 'exercise-editor-tablet'),
  ]) {
    testWidgets('exercise details preserve values in $name', (tester) async {
      Exercise? saved;
      final original = exercises.first.copyWith(
        useDefaultRest: false,
        restDurationSeconds: 120,
      );
      await mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await showExerciseEditor(context, exercise: original);
              },
              child: const Text('Edit exercise'),
            ),
          ),
        ),
        size: size,
        dark: dark,
        textScale: scale,
      );
      await tester.tap(find.text('Edit exercise'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, name);
      await tester.ensureVisible(find.text('Save details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save details'));
      await tester.pumpAndSettle();
      expect(saved?.note, original.note);
      expect(saved?.restDurationSeconds, 120);
      expect(saved?.useDefaultRest, isFalse);
      expect(saved?.targetWeight, original.targetWeight);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  for (final (size, scale, dark, name) in [
    (const Size(390, 844), 1.0, false, 'plans-light'),
    (const Size(320, 568), 1.8, true, 'plans-large-text-dark'),
    (const Size(1194, 834), 1.0, true, 'plans-tablet-dark'),
  ]) {
    testWidgets('plans and routine editing remain usable in $name', (
      tester,
    ) async {
      final longPlan = plan.copyWith(
        name: 'Strength and conditioning for the whole week',
        days: [day.copyWith(name: 'Lower body, glutes and posterior chain')],
      );
      await mount(
        tester,
        const PlanManagementScreen(),
        size: size,
        textScale: scale,
        dark: dark,
        initialPlan: longPlan,
      );
      expect(find.text('Current routine'), findsOneWidget);
      await capture(tester, name);
      await tester.ensureVisible(find.text('Edit routine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit routine'));
      await tester.pumpAndSettle();
      expect(find.text('Edit your plan'), findsOneWidget);
      await capture(tester, '$name-editor');
      await tester.ensureVisible(find.text('Save plan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PlanManagementScreen), findsOneWidget);
      expect(find.text('Edit your plan'), findsNothing);
      await unmount(tester);
    });
  }

  testWidgets('plan editor retries repeated failures and waits for saving', (
    tester,
  ) async {
    final (repo, _) = await mount(tester, const PlanManagementScreen());
    await tester.ensureVisible(find.text('Edit routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit routine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My updated routine');
    repo.failSave = true;
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.ensureVisible(find.text('Save plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save plan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.text('Could not save your plan. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Edit your plan'), findsOneWidget);
      final save = tester.widget<SpottrButton>(
        find.widgetWithText(SpottrButton, 'Save plan'),
      );
      expect(save.isLoading, isFalse);
      expect(find.text('My updated routine'), findsOneWidget);
    }
    repo.failSave = false;
    repo.planSaveGate = Completer<void>();
    addTearDown(() {
      if (!repo.planSaveGate!.isCompleted) repo.planSaveGate!.complete();
    });
    await tester.ensureVisible(find.text('Save plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save plan'));
    await tester.pump();
    expect(find.text('Edit your plan'), findsOneWidget);
    expect(repo.plans.single.name, plan.name);
    repo.planSaveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Edit your plan'), findsNothing);
    expect(repo.plans.single.name, 'My updated routine');
    expect(
      repo.plans.single.days.single.exercises.first.note,
      exercises.first.note,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
