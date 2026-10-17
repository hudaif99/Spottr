# Phase 4 core-flow review

Reviewed 17 October 2026 on `spottr-redesign`. Implementation review is complete for
the agreed core flow. Native-device acceptance and release approval remain open.

## Flow and ownership

| Flow | Reviewed result |
| --- | --- |
| Start | Today starts the selected day. An existing cached session is recovered before another session can replace it. |
| Log and correct | Prefilled values need explicit completion. Queued adjustments use the latest set; completion and removal can be undone. Failed saves retain edits for retry. |
| Add and replace | The shared picker reuses movement identity with fresh entry IDs. Manual names remain available. Replacement cannot discard completed sets. |
| Reorder | Moves preserve set values, notes and identity. Focus follows the entry, and persisted/history order follows the session. |
| Resume | Cached sets, notes and rest deadlines survive reopen. Repeated resume requests do not overwrite unsaved in-memory edits. |
| Partial finish | The existing single finish confirmation saves completed work without requiring every exercise to be finished. Only completed sets contribute to totals and history details. |
| Empty finish and cancel | Empty finish creates no history; cancellation discards only the active session. Both wait for queued work before clearing the cache. |
| Completion recovery | A committed history ID prevents duplicate completion. Failed history checks lock mutation until retry establishes whether the session was already saved. |

Session changes leave the saved plan untouched. Entry notes and targets do not propagate
to other entries sharing movement identity. Existing Hive formats and adapters were not
changed during this review.

## Partial workouts and bypassed exercises

- Users can select another exercise from the overview at any time, then return later.
- Finishing a partial workout counts as one workout, with only explicitly completed sets
  contributing to progress and volume. Existing completed warm-up/drop-set flags remain intact.
- Untouched exercises do not appear as completed work in history details. Unfinished set
  snapshots may remain in the saved record, but do not affect totals or previous-set suggestions.
- There is no separate stored “skipped” status or extra partial-workout wizard. The app
  does not guess whether an unfinished exercise was skipped deliberately.
- Finishing with zero completed sets discards the session without advancing history.

## Fixes from this review

- A failed history lookup during resume previously left editing and finish available.
  Recovery now blocks writes until a successful check, then restores the unfinished session
  or clears a cache whose history was already committed.
- Repeated resume requests no longer replace retained unsaved edits with older cached data.
- Starting before resume completes cannot overwrite an existing cached session.
- Cache-read failures become visible errors with a recovery action on Today. Save/recovery
  status no longer claims unsaved work is already stored.
- Cleanup that completes before the workout screen attaches now returns to Today rather
  than leaving a loading screen. Successful completion bypasses only the pending-write back
  guard after persistence has finished.

## Verification

- All 72 focused workout BLoC, widget, history and real-storage tests passed.
- All four restore interaction tests passed after the recovery changes.
- Formatting and analysis of all seven changed Dart files are clean.
- Reviewed actual partial-finish and recovery renders in light mode and compact dark mode
  at 1.8x text scale. Existing regression renders also cover tablet layouts and both themes.
- Tests cover start/cache protection, retained unsaved edits, failed recovery checks, retry
  after already-committed history, partial totals, history filtering and return navigation.

No Android/iOS build, physical-device interruption, native keyboard or screen-reader
validation was performed. These remain release acceptance checks; host tests do not replace them.

## Next phase

Start Phase 5 with reminder dates and scheduling: midnight offsets, weekday selection,
completion-day suppression and time-zone behavior. Keep progress insights and new record
definitions in separate slices. Starter plans, timed/bodyweight modes, supersets, a permanent
session-custom library and completed-session note snapshots remain separate feature decisions.
