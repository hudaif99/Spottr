# Experience proposal

## Current implementation — 17 October 2026

The user rejected the Stitch concepts and authorized Phase 2 using the existing
Flutter identity. Active Workout now has tighter spacing, sentence-case set position,
explicit logged/unlogged labels and brief completion-check feedback. Reduced motion
disables that animation. Today gives the next workout more prominence than its heading.

Previous performance shows the corresponding completed-set position, falling back
to the final completed set when needed. Tapping it opens a scrollable list of completed
sets from the previous session. This changes display only; prefill and persistence rules remain.

The shared exercise editor now groups name and targets, keeps the setup note compact,
and hides custom rest until requested. An existing override remains visible. Returning
to app defaults is explicit. The save action stays outside the scrolling form when space
permits; very short layouts scroll as a whole. Field controllers preserve typed input through
keyboard/width changes. Validation reveals the first invalid field. Outside taps do not
dismiss the editor; Close or platform Back cancel. Suggestions, custom names, name locks,
exercise IDs, images and existing targets remain supported. No storage format changed.

Settings now groups training, personal preferences and backup actions in readable rows.
The default-rest sheet uses themed presets and a validated custom value. Rest saves are
awaited; failures keep the last saved value. Existing backup services remain in use;
validated restore and complete state refresh were subsequently implemented in Phase 3;
see [backup-restore.md](backup-restore.md) for validation and native-check limits.

Onboarding keeps five steps with back navigation, scrollable content, accessible day
selection and platform-specific time pickers. Reminders are enabled only after permission
is granted; Not now and denial leave them off. Setup waits for schedule persistence and
rescheduling before marking onboarding complete, with busy states and retryable errors.
Failed completion writes can retry without saving the schedule again. No reminder-date
algorithms or Hive fields changed.

Profile now keeps appearance choices and optional details in a responsive form with a reachable
save action. Clearing a field removes its saved value. Saves wait for storage, retain input on
failure and report success only after completion. Existing BMI thresholds remain unchanged.

Schedule details retain the saved time and days during failures, with a visible retry action.
Day selection can be cancelled without saving. Enabling reminders requests permission; disabling
them does not. Schedule mutations are serialized, and notification failures distinguish a saved
schedule from failed reminder updates. Onboarding and Settings share the adaptive time picker.
Existing storage keys, Hive IDs and reminder-date algorithms are unchanged.

Progress now groups saved sessions by month and year, with all-time workout, logged-set and
volume totals. Session rows show the day, recorded duration and completed-set count. Details
retain saved exercise names over later plan names, exclude unfinished sets, preserve original
set positions and label existing warm-up/drop sets. Their completed volume rules are unchanged.
Legacy records without a valid end time show an unavailable duration rather than time since
the workout started. No history is rewritten. Charts, exercise identity and personal-record
rules remain for the foundation and progress feature work.

## Historical design review — 12 October 2026

The user rejected the earlier generated concepts and agreed on a direction drawn
from two Behance references: soft rounded healthcare composition with the nutrition
reference's warmth and accent treatment. See [DESIGN.md](../DESIGN.md) for the
proposed exact system and [workout prompt](stitch-reference-workout-prompt.md).

Review the proposed colors, type and Focus composition before a new light anchor.
Generate and inspect one screen first; derivatives and connected destinations follow
only when the core direction is coherent. No further Flutter implementation is implied.

## Earlier implementation baseline

The first app slice uses warm mineral/forest tokens, Today/Plans/Progress and Focus
logging. It exists as the behavior baseline; device review remains outstanding.
The prior direct-implementation decision applied to that earlier slice. The current
request is reference-informed design planning.

## Workout layouts to compare

| Layout | Benefit | Trade-off |
| --- | --- | --- |
| Focus | One set, large values, increment controls, and one completion action | Less visibility of future sets |
| Set list | All planned sets visible; edit and complete any row directly | Smaller entry controls and more visual density |

The user selected Focus. Keep one active set prominent, with the full workout accessible from the overview.
During rest, retain exercise context and the next set. Let users extend, skip, or continue logging.
Do not force an exercise change when its sets are complete; equipment availability can change the order.
Completed sets remain visible with undo. Suggested sets do not contribute to totals.
Users may bypass an exercise through the overview and return later. Partial finish uses
the existing single confirmation; untouched exercises stay out of history details. An empty
finish creates no history. There is no separate stored skipped status.

## Navigation

- Today: next/resumable workout and a compact weekly view.
- Today waits for readable history before recommending a next day. Read failures show retry;
  loading and failures do not display empty progress. Existing session resume remains available.
  Weekly minutes use recorded durations; unavailable timing is explained rather than estimated.
  Calendar context refreshes on foreground resume and uses local calendar dates.
- Plans: routine, exercise selection, and editing.
- Progress: saved workouts and searchable exercise history with best logged sets.
- Workout: a dedicated flow with an overview, easy return, and explicit finish.
- Preferences: available from app chrome rather than a fourth main tab.
- Tablet: workout overview beside the focused exercise when width permits.

## Data behavior and remaining work

- Setup notes and targets belong to plan entries; active sessions copy those entries.
- Session edits and added exercises affect that session. The plan editor makes permanent changes.
- Suggestions use the latest completed matching exercise identity across plans; legacy same-entry fallback
  remains when names do not contradict it. Old history is not merged by name; see [exercise-identity.md](exercise-identity.md).
- All explicitly completed sets, including warm-ups, count toward volume. Suggestions do not.
- New completed sessions save exercise names independently of future plan edits.
- Exercise progress groups explicit shared identity across plans and combines repeated entries
  in one workout into one session. Best sets rank recorded kg first, then reps at that weight.
  Original set numbers and logged warm-up/drop labels remain visible in expanded sessions.
  Legacy records stay separate by entry and saved name; no name-based join to newer movements.
  See [exercise-progress.md](exercise-progress.md) for the rules and remaining scope.
- Active sessions save the rest deadline. Countdown and duration use wall clock time.
- Shared identity and session replacement/reordering are implemented. The overview offers explicit move
  actions and replacement before any sets are logged. Logged exercises can move; add another exercise
  to switch movements without removing logged work. These changes affect only the session.
- Replacement creates a fresh entry and suggestions rather than inheriting the old movement's note or
  set values. The focused exercise stays selected when its position changes.
- Plan additions and session add/replace can reuse movements from current/draft exercises,
  saved plans and the existing exercise store. The picker preserves explicit custom identity,
  copies entry setup and keeps manual creation available. Completed-session note snapshots
  and a permanent library for session-only custom movements remain for later slices.
- Phase 3 extracted storage-independent application models behind the repository boundary. Existing Hive
  models and adapters remain in the data layer; see [storage-boundary.md](storage-boundary.md).
- Defer detailed timed/bodyweight and superset interactions until the basic flow is reviewed.

## Implementation review

The app uses the existing Hive data and BLoC flow. It now includes prefilled set entry, completion undo,
rest extension/skip, exercise notes/targets, plan exercise ordering, saved session details, and tablet overview.
There are no new packages or generated graphics in this slice. Settings and onboarding were subsequently
refined in Phase 2; the current flow review and remaining limits are in [phase-2-review.md](phase-2-review.md).

The final Phase 2 pass reduced Plans/editor heading emphasis, allowed long routine names full width,
stacked day counts for compact/large-text layouts and fixed repeated plan-save failure feedback.
Edits remain visible after failure; successful saves close the editor only after persistence.

The Phase 4 core-flow review is in [phase-4-review.md](phase-4-review.md). Failed history
checks during resume now block session mutations until recovery succeeds. Retry either
restores the unfinished session or cleans an already-saved cache without rewriting history.
Repeated resume requests retain unsaved edits; start cannot overwrite an existing cache.

Review: visual character, ease of reading while tired, reachability of logging controls,
and the refined Focus design. Review empty/error states and native platform behavior in implementation.
