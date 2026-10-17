# Workout model boundary

Implemented 17 October 2026 as the first Phase 3 slice.

## Ownership

- `lib/domain/models/` contains plain Dart workout, plan, exercise, set and schedule models.
- Presentation, workout rules, repository contracts and reminder scheduling use these models.
- `lib/data/models/` retains the existing Hive objects and generated adapters.
- `lib/data/mappers/workout_storage_mapper.dart` converts both directions at repository boundaries.
- `LocalDatabaseService` handles stored objects; settings services are unchanged in this slice.

No domain model imports Flutter, Hive, a database service or a backend SDK. Model collections
copy their inputs and reject mutation, including nested set lists and saved exercise-name maps.
Active workout BLoC state also owns immutable snapshots of its current and previous sets.
Repositories return ordinary lists where callers need to sort; the models inside remain immutable.

## Compatibility

This is an application boundary change, not an on-disk migration. Hive class names, type IDs,
field IDs, adapter files, box names and keys are unchanged. Existing adapters still supply the
classic defaults for notes, rest preferences, saved names and rest deadlines. Conversion preserves
IDs, dates, exercise order, notes, targets, image references, warm-up/drop flags and schedule choices.
UI time pickers construct their own `TimeOfDay`; schedule models hold hour/minute values only.

No backend integration, catalog identity migration, record rules or backup changes were introduced.

## Verification

- Real Hive writes and reopen checks cover every model and repository reads/writes/deletes.
- Classic-format fixtures read through the application repository and save back without losing data.
- A real-disk BLoC flow starts, logs, reopens, resumes, finishes and cancels a subsequent session.
- Collection tests verify input aliasing cannot mutate app snapshots, including after storage conversion.
- Existing logging, history, editors, preferences and onboarding regressions run against the app models.

All 69 tests passed. Formatting and analysis of the 41 changed/new Dart files are clean.
Wider analysis of `lib` and `test` reports eight existing informational notices in untouched backup,
splash and shared widget files; it is not an entirely clean analyzer baseline. The first suite run
exposed a test teardown that cleared Hive's built-in adapters between cases; that fixture was
corrected and the complete suite passed afterward. Production adapter registration was unchanged.

Native Android/iOS builds, device recovery after process termination and notification delivery remain
release checks. These host tests do not establish native readiness.

## Remaining foundation work

Validated backup/restore was implemented in the next slice; see [backup-restore.md](backup-restore.md).
Keep stable cross-plan exercise identity as a separate slice. Storage
records must stay backward compatible until any future migration has explicit compatibility tests.
Settings still use their existing service boundary; this extraction adds no speculative infrastructure.
