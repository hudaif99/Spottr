# Shared exercise identity

Implemented 17 October 2026 as a Phase 3 foundation slice.

## Identity and ownership

`Exercise.id` remains the plan/session entry ID. It still owns that entry's targets,
setup note, rest settings and set-log keys. `Exercise.identityId` identifies the movement
shared across entries. Changing plans does not change the saved workout's names or totals.

The existing common-name suggestions now use `exercise_catalog.dart`. Catalog IDs are
explicit persisted keys: never change a key when updating its display name. Only exact
canonical names, ignoring case and extra whitespace, resolve automatically. Search aliases
help find suggestions but do not silently identify movements. Barbell, dumbbell and other
listed variants remain separate catalog entries.

Custom entries receive separate IDs. Copying an exercise with its explicit identity can
reuse it across entries; typing the same custom name does not merge two movements. Phase 4
subsequently added a picker for current/draft exercises, saved plans and the existing exercise
store. Selecting one creates a new entry with that explicit identity and copied setup. Later
edits affect only the new entry. The picker does not infer identities for old history or
automatically save session-only custom movements to a permanent library.

Editing details without changing the name keeps identity. Selecting another canonical
movement uses its ID; changing to another custom movement gets a fresh custom identity.
Logged exercises cannot change name or identity through session events. An unlogged
identity change replaces old suggestions with the new movement's completed history/targets.

## History behavior

New completed sessions snapshot entry-to-identity mappings beside their existing saved
names. Previous-set lookup uses the latest completed, matching entry from history, including
other plans. Unfinished suggestions never become history. The lookup scans history without
sorting or mutating it for each exercise.

If the same movement appears more than once in a prior workout, the exact entry takes
precedence. A different entry does not combine multiple sequences into misleading previous
sets. Existing achievement weight/repetition rules remain; their comparison now uses matching
identities and all completed matching sets, so changing plans or reusing an entry ID cannot
compare different movements.

## Compatible migration

- Hive Exercise type `1` adds optional field `9`: `identityId`.
- Hive WorkoutLog type `4` adds field `8`: `exerciseIdentities`, defaulting to an empty map.
- Existing fields, type IDs, box names, keys and set-log grouping are unchanged.
- Hive adapters were regenerated with the existing tooling; no dependencies were upgraded.
- Legacy exercise records resolve known catalog names in app models on read. Stored records
  are not rewritten in bulk. Unknown custom entries retain a deterministic per-entry identity.
- Legacy history is not assigned identity by guessing its name or current plan. Same-entry
  fallback remains when identity is absent and saved names do not contradict the current name.
  A different entry cannot inherit that old history merely because its name is the same.

This deliberately leaves ambiguous old history separate. No completed sets or notes are
removed, combined or retroactively relabeled. Backup validation and round trips preserve
new metadata while accepting both classic and pre-identity stored formats.

## Verification and limits

All 99 app tests passed. A final 17-test storage/backup recheck also passed after the
equivalent profile-map syntax adjustment needed by the older generator. Formatting and
analysis of all 20 changed/new Dart files are clean. Generator tooling still warns that
its analyzer is older than the installed Dart SDK; dependency upgrades were not included.

Focused tests cover stable catalog lookup, custom separation/reuse, old-name safeguards,
duplicate entries, immutable identity snapshots, cross-plan prefill, independent entry targets
and notes, session changes/additions, record comparisons, disk round trips and backup restore.
Old-format fixtures cover both the original classic records and the immediately preceding
notes/default-rest/name-snapshot schema. UI regressions continue to cover suggestion selection.

Native Android/iOS builds and device migration checks remain release work. Phase 4 subsequently
added explicit session replacement/reordering: replacement has a fresh entry ID and the selected
movement's identity; reordering preserves both IDs. Logged entries cannot be replaced.
Exercise-specific charts, a permanent session-custom library and new personal-record rules remain later work.
