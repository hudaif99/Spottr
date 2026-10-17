import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/models/set_log.dart';
import 'package:spottr/presentation/widgets/previous_set_summary.dart';

void main() {
  final sets = [
    SetLog(id: 'first', weight: 10, reps: 12, isCompleted: true),
    SetLog(id: 'unfinished', weight: 100, reps: 30),
    SetLog(id: 'second', weight: 12.5, reps: 10, isCompleted: true),
  ];

  testWidgets('shows relevant completed performance and opens previous sets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(body: PreviousSetSummary(sets: sets, setIndex: 1)),
      ),
    );
    await tester.tap(find.text('Last time: 12.5 kg × 10 reps'));
    await tester.pumpAndSettle();
    expect(find.text('Previous session'), findsOneWidget);
    expect(find.text('10 kg × 12 reps'), findsOneWidget);
    expect(find.text('12.5 kg × 10 reps'), findsOneWidget);
    expect(find.text('100 kg × 30 reps'), findsNothing);
    await tester.tap(find.byTooltip('Close previous session'));
    await tester.pumpAndSettle();
    expect(find.text('Previous session'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the final completed set when there are more current sets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PreviousSetSummary(sets: sets, setIndex: 5)),
      ),
    );
    expect(find.text('Last time: 12.5 kg × 10 reps'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PreviousSetSummary(sets: [sets[1]], setIndex: 0)),
      ),
    );
    expect(find.byType(TextButton), findsNothing);
  });
}
