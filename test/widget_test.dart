import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/core/theme/app_theme.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/data/models/exercise.dart';
import 'package:spottr/data/models/plan.dart';
import 'package:spottr/data/models/workout_day.dart';
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
import 'package:spottr/presentation/screens/create_plan_screen.dart';
import 'package:spottr/presentation/widgets/exercise_editor.dart';
import 'support/fake_workout_repository.dart';

class _Preferences extends LocalDatabaseService {
  @override
  bool getPlayTimerSound() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final boundary = GlobalKey();
  late TimerBloc currentTimer;
  setUpAll(() async {
    final font = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf'));
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
    double textScale = 1,
    bool start = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeWorkoutRepository()..plans.add(plan);
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
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: workout),
          BlocProvider.value(value: plans),
          BlocProvider.value(value: history),
          BlocProvider.value(value: settings),
          BlocProvider.value(value: timer),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: RepaintBoundary(key: boundary, child: screen),
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
    await tester.ensureVisible(find.byTooltip('Undo set 1'));
    await tester.tap(find.byTooltip('Undo set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(repo.active!.exerciseLogs['kickback']!.first.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

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

  testWidgets('plan editor stays open when saving fails', (tester) async {
    final (repo, _) = await mount(tester, CreatePlanScreen(plan: plan));
    repo.failSave = true;
    await tester.ensureVisible(find.text('Save plan'));
    await tester.tap(find.text('Save plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.text('Could not save your plan. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Edit your plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
