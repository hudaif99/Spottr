# Spottr redesign roadmap

## Baseline

- Original app: `spottr-classic`, commit `6debc98` (Android build compatibility fixes).
- Redesign branch: `spottr-redesign`, created from the same commit.
- `main` remains at the original baseline until the redesign is reviewed and tested.
- The working tree was clean when the branches were created. Branches are local; no remote backup is claimed.

## Phases

| Phase | Deliverable | Exit criteria | Status |
| --- | --- | --- | --- |
| 1. Setup | Preserve app, create branch, add project guidance | Branch references and documentation verified | Complete |
| 2. Experience | Visual direction and workout flow; Today and Progress concepts | Review the main flow and resolve product decisions | Implementation reviewed; user/native-device sign-off pending |
| 3. Foundation | Shared UI, models, repositories, migration, session persistence | Focused persistence/migration tests and recoverable failures | Implementation review complete; native acceptance checks remain |
| 4. Core app | Plans, exercise library, notes, workout logging | Start/log/edit/resume/finish flows verified | Implementation review complete; native acceptance checks remain |
| 5. Complete | Progress, history, reminders, backup, adaptive polish | Agreed features usable across target layouts | Reminder scheduling implemented; progress insights remain |
| 6. Release | Device/build checks and final review | Android/iOS validation, migration checks, approval to merge | Planned |

Complete each phase with a concise review: what changed, what was verified, and what remains.
Implementation phases may deliver small end-to-end slices; avoid building unused infrastructure.

## Phase 2 decisions

### Current work — 17 October 2026

- The user authorized Phase 2 after choosing the existing Flutter UI over all Stitch concepts.
- Keep Outfit and the implemented mineral/forest light and deep green/sage dark themes.
- First polish slice: clearer set status, tighter workout spacing, relevant previous-set context,
  accessible previous-session details, quieter Today headings and brief completion feedback.
- Editors/settings, broader motion, remaining Progress decisions and native device review remain.
- The older Stitch decisions below are historical and do not authorize a different visual system.
- Verified this slice with 12 focused widget tests and clean analysis of changed code/tests.
  Reviewed captured Flutter screens in both themes, compact/large-text layouts and tablet layout.
  Native Android/iOS interaction, device and screen-reader checks remain outstanding.

### Exercise editor refinement — 17 October 2026

- Grouped targets, compact optional notes, explicit custom/default rest, and a clear primary action.
- Preserved inputs through keyboard/rotation changes; compact landscape can scroll the whole editor.
- Kept custom names, offline suggestions, locked logged names and existing exercise metadata.
- Passed 19 relevant tests, including edited-value round trips, invalid rest, default-rest reset,
  compact keyboard/landscape, large text, dark/tablet editing and existing workout/plan flows.
- Changed-code/test analysis is clean. Reviewed actual Flutter captures; native keyboard/iOS and
  screen-reader checks remain. Settings/onboarding consistency and remaining Phase 2 review are next.

### Settings and onboarding refinement — 17 October 2026

- Reworked Settings into clear training/personal/data groups; kept existing destinations and backup services.
- Added responsive default-rest presets/custom entry, awaited saves, recoverable errors and adaptive preference switches.
- Replaced onboarding's fixed decorative layout with scrollable steps, back/progress controls,
  platform time pickers, accessible day chips, shared actions and reduced-motion transitions.
- Fixed skipped/denied notifications enabling reminders and setup completing before schedule saves finished.
  Save/retry paths retain selections and wait for persistence and rescheduling; reminder-date algorithms are unchanged.
- Passed 22 tests: nine new settings/onboarding tests plus 13 existing UI regression tests.
  Changed-code/test analysis and formatting passed; reviewed Flutter renders in both themes,
  large text and tablet layouts. Native permissions/pickers, file backup operations and iOS builds remain unverified.
- Still in Phase 2. Next: profile/appearance and schedule-detail consistency, then remaining Progress/experience review.

### Profile and schedule refinement — 17 October 2026

- Refined profile with wrapping theme choices, optional validated details and a persistent save action.
- Profile fields can be cleared; writes are awaited and serialized, with retained input and retryable errors.
- Refined schedule rows and day selection, with shared Android/iOS time pickers and permission-aware reminders.
- Kept saved schedule context through failures and distinguished persistence from notification-update failures.
- Passed 33 focused tests covering settings/onboarding, profile save/clear/failure, schedule retry and queued
  edits, existing workout/editor flows and classic storage compatibility. No Hive IDs or fields changed.
- Reviewed Flutter renders in light/dark, compact/large-text and tablet layouts. Native notification behavior,
  device keyboards, screen readers and iOS builds still need supported tooling.
- Phase 2 remains in progress. Next: Progress and the remaining experience review.

### Progress and history refinement — 17 October 2026

- Replaced the oversized history introduction with a compact all-time summary and month/year grouping.
- Added readable session dates, logged-set counts, recorded durations and adaptive summary metrics.
- Refined session details while retaining saved names, original set positions and completed warm-up/drop sets.
- Legacy records without a valid end time no longer show an ever-growing duration. No stored data changed.
- Passed 21 focused tests: eight history/summary tests and 13 existing workout/editor regressions.
  Covered totals, missing end times, name snapshots, month/year order, retry, and light/dark compact,
  large-text and tablet layouts. Reviewed actual Flutter captures; scoped analysis is clean.
- Phase 2 remains open for the final experience review and native-device feedback. Exercise trends and
  personal records depend on the planned identity/model foundation; no chart or record rules were added.
- Next: review remaining Phase 2 gaps and agree the foundation slice before expanding features.

### Final experience review — 17 October 2026

- Recorded the flow review, open limitations and next foundation boundary in [phase-2-review.md](phase-2-review.md).
- Fixed repeated plan-save failures leaving the editor busy; verified retained input and delayed success.
- Refined Plans/editor hierarchy, full-width routine names and responsive day counts.
- Removed conflicting rejected Stitch instructions from the active design guide.
- Passed 16 focused widget tests; scoped analysis and formatting are clean. Reviewed actual rendered
  Plans/editor screens in light/dark, compact large-text and tablet layouts. Native sign-off remains open.
- Phase 2 implementation review is complete, with user/device review still pending. Next implementation
  slice: storage-independent models and compatible mapping, before catalog identity or backend work.

### Historical review — 12 October 2026

- The user provisionally accepted Spottr · Reference-led Workout and requested
  removal of unnecessary components. Keep this light direction and refine it;
  see stitch-image-reference-pass.md. The prior light/dark pair remains rejected.
  Dark and connected screens still need review. No Flutter implementation is authorized.

- The user rejected every earlier Stitch concept, including the ink/apricot proposal.
- Two Behance projects were visually inspected. The user agreed to combine Healthcare
  Mobile App Design's soft composition and rounded forms with the Nutrition/Fitness
  design's warmth and accent treatment. Links and observations are in root DESIGN.md.
- DESIGN.md and semantic tokens now propose cool gray/white surfaces, coral actions,
  sage completion feedback, Inter typography and a reachable soft logging panel.
- The user requested Stitch screens before Flutter and equal care for dark mode.
  The working image-reference light anchor is in docs/stitch-image-reference-pass.md.
  No Flutter changes. Review its cleanup before dark/completed/rest/tablet and other screens.
- Mathematical checks passed for the specified body, action, supporting, success,
  error and control-border color pairs in both themes. Rendered/device checks remain.
- Earlier exploration files are historical artifacts and are not current generation
  instructions. Use docs/stitch-image-reference-pass.md for the current working anchor.

At the Phase 2 checkpoint, Focus remained selected. Plan-entry notes copy into sessions; session edits affect only
the workout; prefill uses completed history for the existing entry identity; only
explicitly completed sets count, including existing completed warm-ups.
Shared exercise identity was subsequently implemented in Phase 3. Session replacement/reordering,
trends and record definitions remain future work. Timed/bodyweight, dedicated warm-up/drop-set and supersets need
separate product decisions. Preserve current recovery, persistence and Hive contracts.

## Phase 3 foundation

### Model and storage boundary — 17 October 2026

- Extracted plain Dart models for exercises, sets, days, plans, history, active workouts and schedules.
- Moved app consumers and repository contracts to those models; repositories map to existing Hive objects.
- Copied and protected nested collections in app models and workout state to prevent accidental mutation.
- Kept all Hive type/field IDs, generated adapters, box keys and stored formats unchanged.
- Added real-disk round trips, repository operations, classic-data mapping and BLoC reopen/resume/finish/cancel checks.
- Verification: all 69 tests passed; formatting and analysis of all 41 changed/new Dart files passed.
  Wider app/test analysis retains eight informational notices in untouched files. Native builds and
  physical-device recovery were not run. Hive models and generated adapter files have no diff.
- See [storage-boundary.md](storage-boundary.md) for ownership and compatibility rules.
- Phase 3 remains in progress. Stable exercise identity and safe backup/restore remain separate work;
  no backend SDK or catalog migration was added. Phase 2 native/user sign-off is still open.

### Validated backup and restore — 17 October 2026

- Exported only known database files with portable names and a versioned manifest; retained compatible flat legacy ZIPs.
- Validated archive structure, checksums, limits, Hive data and settings before touching live files.
- Added a write barrier, rollback journal, startup recovery and cleanup that cannot trigger a later rollback.
- Added replacement confirmation and active-workout protection; refreshes plans, history, settings, schedule,
  rest defaults and imported sessions. Reminder failures retry separately without repeating the restore.
- Exports reopen storage before sharing, handle cancellation and provide an iPad share anchor.
- Full-suite and focused failure validation are recorded in [backup-restore.md](backup-restore.md).
- Verification: all 89 tests passed; formatting and analysis of all 49 pending Dart files passed.
  Reviewed the actual confirmation at compact width, dark theme and 1.8x text scaling.
- Native pickers/sharing, notification delivery, actual process interruption and iOS builds remain release checks.
- Next Phase 3 slice: stable exercise identity across plans, with a separately reviewed data migration.

### Shared exercise identity — 17 October 2026

- Kept plan-entry IDs and introduced movement identity shared by exact catalog matches across plans.
- Kept custom names separate unless their explicit identity is reused. Aliases only help suggestion search.
- Snapshotted identity with new history; preserved old names, notes, targets, set keys and totals.
- Used completed matching history for new plans and session additions; changing an unlogged movement
  resets suggestions, while logged names/identities stay protected. Existing record rules now compare matching movements.
- Added backward-compatible Exercise field 9 and WorkoutLog field 8; regenerated adapters and verified
  both classic and pre-identity fixtures. No bulk rewrite or name-based merging of old history was performed.
- Policy, compatible migration and custom-reuse UI limitations are in [exercise-identity.md](exercise-identity.md).
- Verification: all 99 tests passed; 17 storage/backup checks passed again after the generator-compatible
  profile-map adjustment. Formatting and changed-code analysis are clean. Native migration/build checks remain.
- Next: finish the Phase 3 implementation review, then session exercise replacement/reordering in Phase 4.

### Foundation review — 17 October 2026

- Completed the focused model, mapping, identity, session persistence and restore-recovery review.
- Reran 43 relevant identity, compatibility, real-storage, backup and workout tests: all passed.
- No additional implementation blocker was found in the reviewed paths. No app code changed in this review.
- Recorded acceptance limits and the next feature boundary in [phase-3-review.md](phase-3-review.md).
- Phase 3 implementation review is complete; native migration, interruption, sharing and iOS checks remain.
- Next: Phase 4 session-only exercise replacement/reordering, preserving logged work and the saved plan.

## Phase 4 core app

### Session exercise changes — 17 October 2026

- Added overview actions to move exercises earlier/later or replace an unlogged exercise.
  The phone sheet updates as changes save; the tablet overview uses the same controls.
- Kept focus attached to the exercise entry while reordering. Completed sets, notes,
  targets, movement identity and rest context survive moves. History follows session order.
- Replacement starts with a fresh editor and entry ID, uses the selected movement's
  completed history, and removes the replaced entry's unlogged suggestions. Old set actions
  cannot attach to its replacement. The saved plan remains unchanged.
- Logged exercises can move but cannot be replaced. To switch movements after logging,
  add another exercise; existing logged work is retained. No new discard policy was introduced.
- Changes share the session write queue and retained-state retry path. Real-file tests
  verify replacement/order after restart and finish, including preserved completed totals.
- Verification: 51 relevant BLoC, repository, editor and widget tests passed. Reviewed actual
  Flutter renders in light/dark, compact large-text and tablet layouts. Native interaction,
  screen-reader and iOS checks remain open.
- Formatting and analysis of all seven Dart files changed in this slice passed; diff whitespace checks passed.
- Next Phase 4 slice: a simple exercise-library picker to reuse saved custom movements
  and their identity when adding/replacing exercises; keep manual entry available.

### Reusable exercise picker — 17 October 2026

- Added a shared picker for plan additions and session add/replace. One tap copies an
  exercise into a fresh entry while preserving its movement identity, note, targets and rest settings.
- Shows current/draft exercises and saved plan/library entries before the common catalog.
  Deduplicates by identity, not name; independently created custom names stay separate.
  Current setup takes precedence over saved setup, then catalog defaults.
- Search finds names, setup notes and existing catalog aliases. Search stays responsive
  while saved sources load. Partial failures retain usable sources and offer retry.
- Manual creation remains available throughout; the search text carries into the editor.
  Cancelling the editor returns to the picker with the query intact. Short keyboard layouts
  scroll the full picker rather than squeezing fixed actions into the viewport.
- The picker reads existing sources without writing a second exercise copy or changing
  the source plan. Reused notes/targets remain entry-owned; edits do not propagate to other entries.
  Session-only custom movements are not added to a permanent library by this slice.
- Verification: 58 relevant tests passed; the large-text case passed again after shortening
  the search label and simplifying the create action. Reviewed actual light/dark, large-text,
  tablet, loading, empty and error renders. Native keyboard/VoiceOver/TalkBack and iOS checks remain.
- Formatting and scoped analysis of all nine changed/new Dart files are clean; diff whitespace checks passed.
- Next: review the remaining Phase 4 core-flow gaps and clarify skip/partial-workout behavior
  before adding another feature slice. No starter plans, history charts or new record rules were added.

### Core-flow review — 17 October 2026

- Reviewed start, log/correct, add/replace/reorder, resume, partial finish and cancel together.
- Confirmed partial finish uses the existing single confirmation. Only completed sets count;
  untouched exercises stay out of history details. No new skipped-status schema was added.
- Fixed failed recovery checks permitting mutation, repeated resume losing retained edits,
  start replacing an existing cache, cache-read errors and cleanup leaving a loading screen.
- Recovery retry now verifies history before allowing writes. Already-committed sessions are
  cleaned up without rewriting history; unfinished sessions retain their cached progress.
- Verification: 72 focused workout/UI/history/storage tests and four restore interaction tests
  passed. Formatting and scoped analysis of all seven changed Dart files are clean.
- Reviewed actual partial-finish and recovery renders, including compact dark mode at 1.8x
  text scale. Native-device, screen-reader and iOS checks remain release acceptance work.
- See [phase-4-review.md](phase-4-review.md) for the final behavior and remaining scope.
- Phase 4 implementation review is complete. Next: Phase 5 reminder date and scheduling fixes.

## Phase 5 completion

### Dated reminder scheduling — 17 October 2026

- The user approved a 14-day rolling window, including expiry when the app stays unopened.
- Replaced recurring triggers with dated reminders, refreshed on launch/resume, schedule changes,
  restore and workout start/finish/cancel. Settings includes a brief two-week reminder note.
- Fixed midnight weekday offsets, calendar-day arithmetic across DST and current-zone refresh.
- Completed/active sessions suppress the relevant dates without losing future reminders.
  Cancellation and empty finish restore remaining prompts; unfinished suggestions do not suppress them.
- Serialized native changes, read current saved preferences at execution time and retained deletion
  on cancellation failure. Native/read failures remain retryable without undoing workout saves.
- Verification: 72 relevant tests passed across focused runs. Android/iOS platform-channel payloads
  are dated and non-repeating. Native delivery, reboot/permission behavior and iOS builds remain open.
- The approved window, suppression rules, pending-request budget and limits are in
  [reminder-scheduling.md](reminder-scheduling.md).
- Next: define a small, useful exercise-progress view and personal-record rules before implementing charts.

## Reliability backlog from the initial source review

Current source-review disposition follows. Host-test evidence does not replace device acceptance.

| Finding | Status / remaining work |
| --- | --- |
| Unawaited session updates and clear-then-add persistence can overlap | Implemented: serialized session events, awaited writes and keyed cache saves; queue/retry tests pass |
| Finish with no completed sets leaves the active cache behind | Implemented: empty finish clears the cache without history; covered by workout tests |
| Finish closes the screen before saving succeeds | Implemented: completion follows history save and cleanup; failed finish remains recoverable |
| Backup restore validation, path containment and rollback | Implemented in Phase 3; native interruption checks remain |
| Restore refreshes app state and reminders | Implemented in Phase 3; native permission/delivery checks remain |
| Shared exercise identity across plans | Implemented for exact catalog matches and explicit identity reuse; ambiguous legacy history stays separate |
| Timers lack lifecycle reconciliation; stopwatch is not started | Workout elapsed time and rest use wall-clock time; rest reconciliation is tested. Native background/audio behavior remains open |
| Reminder offsets crossing midnight retain the wrong weekday | Implemented in Phase 5 with dated calendar calculations; boundary/DST tests pass |
| Completing a workout cancels the recurring streak reminder | Replaced with dated completion-day suppression; future dates remain scheduled inside the approved rolling window. Native delivery checks remain |
| Previous-best values can include unfinished sets; live/saved volume rules differ | Completed-set filtering implemented in history lookup, record comparison and volume; new record definitions remain Phase 5 |
| Only the template counter test exists; it does not initialize app dependencies | Replaced with focused coverage; preceding full-suite run passed 99 tests, foundation review reran 43 |

## Verification baseline

Flutter 3.47.2 / Dart 3.13.2 work when SDK cache access is allowed. The initial analyzer reported
existing informational lints but no compile errors. The counter template test was replaced with focused tests.
Use a macOS/Xcode environment for the iOS build and simulator/device checks in Phase 6.
Record unavailable validation explicitly rather than inferring iOS readiness from Android results.

## Decisions recorded

- Kilograms only; offline-first app; no backend integration now.
- Keep BLoC initially and isolate storage/platform dependencies.
- Short, purposeful comments and focused tests.
- Skills are optional tools, selected by task; none needed for the documentation-only setup.
- Custom assets may be generated when useful, with precise prompts supplied if needed.
- Preserve classic; implement and review phase by phase; merge only after testing.

## First implementation review — 11 October 2026

- Implemented warm light/dark themes, Today/Plans/Progress navigation, and a focused workout screen.
- Added prefilled targets, direct entry and step controls, completion/removal undo, setup notes,
  rest extension/skip, editable plans, session-only exercise additions/edits, and saved session details.
- Serialized session and plan writes, removed clear-before-save gaps, retained failed edits for retry,
  waited for finish persistence before leaving, and prevented duplicate completion after interrupted cleanup.
- Preserved app default rest settings; an exercise can override its rest duration. Kept Hive type IDs
  and existing field IDs, with backwards-compatible defaults for added fields.
- Passed 22 focused tests: save/resume/finish/cancel, queued edits, save failures, classic Hive files,
  timers, optional notes, plan-save failures, and logging at compact/tablet widths and 1.8× text.
- Analysis of all changed Dart code and tests: no issues. Full-project analysis retains 13 existing
  informational lints in untouched backup, onboarding, splash, shared widgets, and the root Hive demo.
- Android debug APK built successfully. Existing Gradle/AGP/Kotlin versions emit future-support warnings;
  platform upgrades belong to release preparation. No iOS build, physical-device, or screen-reader pass is claimed.
- `main` and `spottr-classic` still reference `6debc98`; implementation remains uncommitted on `spottr-redesign`.

Next: device review of this slice, then extract storage-independent application models and add the shared
exercise catalog. Continue with session replacement/reordering, progress trends, onboarding/settings,
validated backup/restore, reminder-date fixes, and release checks. Existing plan-entry IDs are still used
for historical suggestions; cross-plan identity has not been migrated yet.

## Exercise name suggestions — 11 October 2026

- Added an offline list of common strength, bodyweight, machine, cable, and cardio exercise names.
- The shared exercise editor suggests names while typing; tap to select or enter any custom name.
- Search ignores case and punctuation, supports multiple words and common aliases such as RDL,
  and places names beginning with the query first. Suggestions do not change exercise identity or targets.
- Verification: 12 focused tests passed, including suggestion selection with the keyboard inset on a
  compact screen, custom-name saving, locked names, and existing editor/logging flows. Changed-code
  analysis and diff whitespace checks passed. Native keyboard/device checks remain for release review.

## Reference-inspired design retry — 13 October 2026

- The user rejected the prior Stitch direction and supplied Home Workout and ClickUp references.
- Generated and visually inspected four refined Workout/Today concepts in a separate private project.
- Recorded the candidate system, motion intent, screen resources and review limitations in
  `docs/stitch-clean-training-review.md`. Previous design specifications are marked superseded.
- Direction review remains open. No Flutter code or assets changed in this pass.

## Continue the Flutter direction — 13 October 2026

- The user rejected the latest Stitch screens and chose the existing Flutter UI.
- Restored the implemented forest/mineral, Outfit direction as the design authority.
- Next candidate slice: polish Active Workout and Today, then bring editors/settings into the same system.
- UI improvements are under discussion. No Flutter code changed in this decision update.
