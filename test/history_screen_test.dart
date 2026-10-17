import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/core/theme/app_theme.dart';
import 'package:spottr/data/models/exercise.dart';
import 'package:spottr/data/models/plan.dart';
import 'package:spottr/data/models/set_log.dart';
import 'package:spottr/data/models/workout_day.dart';
import 'package:spottr/data/models/workout_log.dart';
import 'package:spottr/domain/history_summary.dart';
import 'package:spottr/presentation/blocs/history/history_bloc.dart';
import 'package:spottr/presentation/blocs/history/history_event.dart';
import 'package:spottr/presentation/blocs/plans/plans_bloc.dart';
import 'package:spottr/presentation/blocs/plans/plans_event.dart';
import 'package:spottr/presentation/screens/history_screen.dart';
import 'support/fake_workout_repository.dart';

class _Repository extends FakeWorkoutRepository {
  bool unreadable = false;
  Completer<void>? readGate;
  @override
  Future<List<WorkoutLog>> getWorkoutLogs() async {
    await readGate?.future;
    if (unreadable) throw StateError('Private storage error');
    return super.getWorkoutLogs();
  }
}

WorkoutLog _log(
  String id,
  DateTime date, {
  String name = 'Lower body',
  DateTime? end,
}) => WorkoutLog(
  id: id,
  planId: 'plan',
  dayId: 'day',
  dayName: name,
  startTime: date,
  endTime: end,
  exerciseNames: const {'squat': 'Saved cable squat'},
  exerciseLogs: {
    'squat': [
      SetLog(
        id: 'warmup',
        weight: 10,
        reps: 5,
        isCompleted: true,
        isWarmup: true,
      ),
      SetLog(id: 'unfinished', weight: 999, reps: 99),
      SetLog(
        id: 'drop',
        weight: 20,
        reps: 8,
        isCompleted: true,
        isDropSet: true,
      ),
    ],
    'removed': [SetLog(id: 'older', weight: 5, reps: 2, isCompleted: true)],
    'skipped': [SetLog(id: 'skipped-set', weight: 100, reps: 10)],
  },
);

void main() {
  final date = DateTime(2026, 10, 17, 18);
  final log = _log('latest', date, end: date.add(const Duration(minutes: 65)));

  test(
    'history totals include logged warm-ups and drops, exclude suggestions',
    () {
      final totals = HistorySummary.fromLogs([log, log.copyWith(id: 'second')]);
      expect(totals.workouts, 2);
      expect(totals.completedSets, 6);
      expect(totals.volume, 440);
      expect(HistorySummary.fromLogs([]).completedSets, 0);
    },
  );

  test('historical duration never uses the current time', () {
    expect(recordedWorkoutDuration(log), const Duration(minutes: 65));
    expect(recordedWorkoutDuration(_log('old', date)), isNull);
    expect(
      recordedWorkoutDuration(
        log.copyWith(endTime: date.subtract(const Duration(minutes: 1))),
      ),
      isNull,
    );
  });

  final boundary = GlobalKey();
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

  Future<void> mount(
    WidgetTester tester,
    _Repository repo, {
    Size size = const Size(390, 844),
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final history = HistoryBloc(repo)..add(LoadHistory());
    final plans = PlansBloc(repo)..add(LoadPlans());
    addTearDown(() async {
      if (repo.readGate != null && !repo.readGate!.isCompleted) {
        repo.readGate!.complete();
      }
      await history.close();
      await plans.close();
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: history),
          BlocProvider.value(value: plans),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const HistoryScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
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

  for (final variant in [
    ('light', const Size(390, 844), false, 1.0),
    ('large-text-dark', const Size(320, 720), true, 1.8),
    ('tablet-dark', const Size(1194, 834), true, 1.0),
  ]) {
    testWidgets('history and details work in ${variant.$1}', (tester) async {
      final repo = _Repository()
        ..logs.addAll([
          _log('older', DateTime(2025, 10, 2)),
          log,
          _log('previous-month', DateTime(2026, 9, 30)),
        ]);
      repo.plans.add(
        Plan(
          id: 'plan',
          name: 'Plan',
          days: [
            WorkoutDay(
              id: 'day',
              name: 'Day',
              exercises: [Exercise(id: 'squat', name: 'Renamed squat')],
            ),
          ],
        ),
      );
      await mount(
        tester,
        repo,
        size: variant.$2,
        dark: variant.$3,
        scale: variant.$4,
      );
      await tester.pumpAndSettle();
      expect(find.text('9'), findsOneWidget);
      expect(find.text('660'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      await capture(tester, 'progress-${variant.$1}');
      final row = find.text('Lower body').first;
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('1h 5m'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('220'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Saved cable squat'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Renamed squat'), findsNothing);
      expect(find.text('Set 2'), findsNothing);
      await capture(tester, 'history-detail-${variant.$1}');
      await tester.scrollUntilVisible(
        find.text('Exercise from an earlier plan'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('999 kg × 99 reps'), findsNothing);
      expect(find.text('5 kg × 2 reps'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('October 2025'), 150);
      expect(find.text('October 2025'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty history explains how to begin without fake metrics', (
    tester,
  ) async {
    await mount(tester, _Repository(), size: const Size(320, 600), scale: 1.8);
    await tester.pumpAndSettle();
    expect(find.text('Your progress starts here'), findsOneWidget);
    expect(find.text('workouts saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history exposes loading and retries storage failure', (
    tester,
  ) async {
    final repo = _Repository()
      ..unreadable = true
      ..readGate = Completer<void>();
    await mount(tester, repo);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('History could not load'), findsOneWidget);
    expect(find.textContaining('Private storage'), findsNothing);
    repo.unreadable = false;
    await tester.tap(find.text('Retry loading history'));
    await tester.pumpAndSettle();
    expect(find.text('Your progress starts here'), findsOneWidget);
  });

  testWidgets('legacy history does not invent an ongoing duration', (
    tester,
  ) async {
    final repo = _Repository()..logs.add(_log('legacy', date));
    await mount(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Duration unavailable'), findsOneWidget);
    await tester.tap(find.text('Lower body'));
    await tester.pumpAndSettle();
    expect(find.text('Duration unavailable'), findsOneWidget);
  });
}
