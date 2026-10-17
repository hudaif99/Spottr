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
| 2. Experience | Visual direction and workout flow; Today and Progress concepts | Review the main flow and resolve product decisions | In progress: existing Flutter direction retained; Active Workout/Today polish implemented |
| 3. Foundation | Shared UI, models, repositories, migration, session persistence | Focused persistence/migration tests and recoverable failures | Session reliability and visual tokens implemented; model extraction remains |
| 4. Core app | Plans, exercise library, notes, workout logging | Start/log/edit/resume/finish flows verified | First implementation slice; catalog and session replacement remain |
| 5. Complete | Progress, history, reminders, backup, adaptive polish | Agreed features usable across target layouts | Session details implemented; remaining work planned |
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

Focus remains selected. Plan-entry notes copy into sessions; session edits affect only
the workout; prefill uses completed history for the existing entry identity; only
explicitly completed sets count, including existing completed warm-ups.
Shared exercise identity, session replacement/reordering, trends and record definitions
remain future work. Timed/bodyweight, dedicated warm-up/drop-set and supersets need
separate product decisions. Preserve current recovery, persistence and Hive contracts.

## Reliability backlog from the initial source review

Recheck these paths before fixing them; findings below are not device reproductions.

| Finding | Target phase |
| --- | --- |
| Unawaited session updates and clear-then-add persistence can overlap | 3 |
| Finish with no completed sets leaves the active cache behind | 3 |
| Finish closes the screen before saving succeeds | 4 |
| Backup restore lacks full validation, path containment, and rollback | 3 / 5 |
| Restore refreshes plans/history but leaves other state and reminders stale | 5 |
| Exercise identity is scoped to plan entries, fragmenting progress | 3 |
| Timers lack lifecycle reconciliation; stopwatch is not started | 4 |
| Reminder offsets crossing midnight retain the wrong weekday | 5 |
| Completing a workout cancels the recurring streak reminder | 5 |
| Previous-best values can include unfinished sets; live/saved volume rules differ | 4 / 5 |
| Only the template counter test exists; it does not initialize app dependencies | 3 |

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
