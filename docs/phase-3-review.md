# Phase 3 implementation review

Reviewed 17 October 2026 on `spottr-redesign`. Foundation implementation review is
complete; native-device acceptance remains open. This review does not approve a release
or merge into `main`.

## Reviewed boundaries

| Area | Result and evidence |
| --- | --- |
| Application models | Domain models have no Hive or data-layer imports. Mappers copy nested collections at the repository boundary; mutation and real-disk round-trip tests cover ownership. |
| Storage compatibility | Existing type and field IDs remain intact. Classic and pre-identity fixtures reopen with notes, targets, set flags, names and totals preserved. New identity fields have compatible defaults. |
| Session persistence | One BLoC event queue serializes edits, finish and cancel. Writes are awaited; failed saves retain in-memory values for retry. Empty finish clears the cache without creating history. |
| Completion recovery | History is written before cache cleanup. A saved session ID prevents duplicate completion after cleanup failure or restart. Real-file tests cover resume, finish and cancel. |
| Shared identity | Exact catalog identities share completed history across plans. Custom names and ambiguous legacy history stay separate. Logged movements cannot be relabeled through session edits. |
| Backup replacement | Validation precedes live replacement. Maintenance drains accepted writes; a journal supports rollback and startup recovery. Active workouts block restore. Failure tests cover replacement, reopen and cleanup. |

No additional implementation blocker was identified in these reviewed paths. This is a
focused source and host-test review, not a claim that every failure mode has been tested.
See [storage-boundary.md](storage-boundary.md), [backup-restore.md](backup-restore.md) and
[exercise-identity.md](exercise-identity.md) for the detailed contracts.

## Verification

- Reran 43 tests across `exercise_identity_test.dart`, `storage_compatibility_test.dart`,
  `workout_repository_storage_test.dart`, `backup_restore_test.dart` and
  `workout_bloc_test.dart`: all passed.
- Compatibility fixtures intentionally override adapters to write old formats; their
  Hive override warnings are expected and do not occur in app initialization.
- The preceding implementation pass recorded 99 passing tests and clean formatting
  and changed-code analysis. This review changed documentation only; those broader
  checks were not repeated.
- No new UI was introduced, so no new visual review was required.

## Remaining acceptance checks

- Migrate real installed data on Android and iOS, including an active workout.
- Exercise native file pickers, sharing destinations and iPad share presentation.
- Interrupt a restore on a device and verify startup recovery. Host file-state tests
  do not establish power-loss guarantees.
- Verify notification permission changes and delivery after restore.
- Build and review iOS with macOS/Xcode; Windows checks cannot establish iOS readiness.
- Keep the existing generator/analyzer version warning for release-tooling review.

Reminder date calculations, completion-day suppression and time-zone behavior remain
Phase 5 work. A custom-exercise reuse picker, trends and new record definitions are
feature work rather than missing foundation infrastructure.

## Next implementation slice

Phase 4 starts with session-only exercise replacement and reordering:

- Make the change action obvious from the workout overview.
- Preserve completed sets and movement identity; replacement must not silently discard
  logged work. Reuse the existing logged-exercise protection.
- Keep the stored plan unchanged. Retain entry notes and targets when reordering;
  replacement uses the selected movement's context rather than old suggestions.
- Persist the resulting order and replacement through resume, save failures and finish.
- Provide visible move controls alongside any drag gesture. Check compact screens,
  large text, tablet layouts and both existing themes.

Settle any policy for replacing an already logged exercise before implementing it.
Do not bundle backend integration, charts or new record rules into this slice.
