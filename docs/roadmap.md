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
| 2. Experience | Visual direction and workout flow; Today and Progress concepts | Review the main flow and resolve product decisions | Next |
| 3. Foundation | Shared UI, models, repositories, migration, session persistence | Focused persistence/migration tests and recoverable failures | Planned |
| 4. Core app | Plans, exercise library, notes, workout logging | Start/log/edit/resume/finish flows verified | Planned |
| 5. Complete | Progress, history, reminders, backup, adaptive polish | Agreed features usable across target layouts | Planned |
| 6. Release | Device/build checks and final review | Android/iOS validation, migration checks, approval to merge | Planned |

Complete each phase with a concise review: what changed, what was verified, and what remains.
Implementation phases may deliver small end-to-end slices; avoid building unused infrastructure.

## Phase 2 decisions

- Visual direction: palette, typography, icons, density, and motion.
- Focused exercise view with an overview versus a full scrolling workout.
- Shared exercise identity and ownership of exercise notes.
- Session changes versus permanent plan changes.
- Scope and calculation rules for timed/bodyweight exercises, warm-ups, and supersets.
- History and personal-record definitions.

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

The earlier analysis/test commands were stopped without completing. No passing baseline is claimed.
Establish a working toolchain and useful tests in Phase 3, before changing persistence.
Use a macOS/Xcode environment for the iOS build and simulator/device checks in Phase 6.
Record unavailable validation explicitly rather than inferring iOS readiness from Android results.

## Decisions recorded

- Kilograms only; offline-first app; no backend integration now.
- Keep BLoC initially and isolate storage/platform dependencies.
- Short, purposeful comments and focused tests.
- Skills are optional tools, selected by task; none needed for the documentation-only setup.
- Custom assets may be generated when useful, with precise prompts supplied if needed.
- Preserve classic; implement and review phase by phase; merge only after testing.
