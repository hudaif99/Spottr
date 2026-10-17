import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/models/exercise.dart';
import 'package:spottr/domain/exercise_name_suggestions.dart';
import 'package:spottr/presentation/widgets/exercise_editor.dart';

void main() {
  test('matches prefixes, multiple words, punctuation and common aliases', () {
    expect(suggestExerciseNames('  '), isEmpty);
    expect(suggestExerciseNames('cAbLe').first, 'Cable chest fly');
    expect(
      suggestExerciseNames('bench dumbbell'),
      contains('Dumbbell bench press'),
    );
    expect(suggestExerciseNames('pushup'), contains('Push-up'));
    expect(suggestExerciseNames('RDL'), contains('Romanian deadlift'));
    expect(suggestExerciseNames('my custom movement'), isEmpty);
    expect(commonExerciseNames.toSet().length, commonExerciseNames.length);
  });

  Future<void> openEditor(
    WidgetTester tester,
    ValueChanged<Exercise?> onSaved, {
    Exercise? exercise,
    bool lockName = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => onSaved(
                await showExerciseEditor(
                  context,
                  exercise: exercise,
                  lockName: lockName,
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets('selects a suggestion and saves it on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Exercise? saved;
    await openEditor(tester, (value) => saved = value);
    await tester.enterText(find.byType(TextFormField).first, 'lat pull');
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('Lat pulldown'), findsOneWidget);
    await tester.tap(find.text('Lat pulldown'));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'Lat pulldown');
    expect(saved?.identityId, 'catalog:lat-pulldown');
    expect(tester.takeException(), isNull);
  });

  testWidgets('allows a custom name without selecting a suggestion', (
    tester,
  ) async {
    Exercise? saved;
    await openEditor(tester, (value) => saved = value);
    await tester.enterText(
      find.byType(TextFormField).first,
      '  My custom movement  ',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'My custom movement');
    expect(saved?.identityId, startsWith('custom:'));
  });

  testWidgets('keeps edits through keyboard and compact landscape changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final original = Exercise(
      id: 'custom',
      name: 'Cable kickback',
      note: 'Old note',
      imageUrl: 'local-image',
      targetSets: 3,
      targetReps: 10,
      targetWeight: 12.5,
    );
    Exercise? saved;
    await openEditor(tester, (value) => saved = value, exercise: original);
    await tester.enterText(find.byKey(const ValueKey('Sets')), '4');
    await tester.enterText(find.byKey(const ValueKey('Reps')), '8');
    await tester.enterText(find.byKey(const ValueKey('Weight · kg')), '22.5');
    await tester.ensureVisible(find.byKey(const ValueKey('Setup note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('Setup note')),
      'Pulley at knee level',
    );
    await tester.ensureVisible(find.text('Customize rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize rest'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Rest · seconds')), '120');
    tester.view.physicalSize = const Size(568, 320);
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Save details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();
    expect(saved?.id, original.id);
    expect(saved?.identityId, original.identityId);
    expect(saved?.name, original.name);
    expect(saved?.imageUrl, original.imageUrl);
    expect(saved?.note, 'Pulley at knee level');
    expect(saved?.targetSets, 4);
    expect(saved?.targetReps, 8);
    expect(saved?.targetWeight, 22.5);
    expect(saved?.restDurationSeconds, 120);
    expect(saved?.useDefaultRest, isFalse);
    expect(original.note, 'Old note');
  });

  testWidgets(
    'rejects invalid custom rest and allows returning to app default',
    (tester) async {
      Exercise? saved;
      await openEditor(tester, (value) => saved = value);
      await tester.enterText(find.byType(TextFormField).first, 'My exercise');
      await tester.ensureVisible(find.text('Customize rest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize rest'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('Rest · seconds')),
        '-1',
      );
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(find.text('Use 0–1800'), findsOneWidget);
      await tester.ensureVisible(find.text('Use app default rest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use app default rest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      expect(saved?.useDefaultRest, isTrue);
      expect(saved?.name, 'My exercise');
    },
  );

  testWidgets('keeps logged exercise names locked without suggestions', (
    tester,
  ) async {
    final exercise = Exercise(
      id: 'logged',
      name: 'Cable kickback',
      targetSets: 3,
      targetReps: 10,
      targetWeight: 5,
      restDurationSeconds: 90,
    );
    Exercise? saved;
    await openEditor(
      tester,
      (value) => saved = value,
      exercise: exercise,
      lockName: true,
    );
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      isTrue,
    );
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();
    expect(saved?.name, exercise.name);
    expect(saved?.id, exercise.id);
  });
}
