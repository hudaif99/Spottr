# Experience proposal

## Current implementation — 17 October 2026

The user rejected the Stitch concepts and authorized Phase 2 using the existing
Flutter identity. Active Workout now has tighter spacing, sentence-case set position,
explicit logged/unlogged labels and brief completion-check feedback. Reduced motion
disables that animation. Today gives the next workout more prominence than its heading.

Previous performance shows the corresponding completed-set position, falling back
to the final completed set when needed. Tapping it opens a scrollable list of completed
sets from the previous session. This changes display only; prefill and persistence rules remain.

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

## Navigation

- Today: next/resumable workout and a compact weekly view.
- Plans: routine, exercise selection, and editing.
- Progress: exercise trends and session details.
- Workout: a dedicated flow with an overview, easy return, and explicit finish.
- Preferences: available from app chrome rather than a fourth main tab.
- Tablet: workout overview beside the focused exercise when width permits.

## Data behavior and remaining work

- Setup notes and targets belong to plan entries; active sessions copy those entries.
- Session edits and added exercises affect that session. The plan editor makes permanent changes.
- Suggestions use completed sets from the latest session with the same existing entry ID.
- All explicitly completed sets, including warm-ups, count toward volume. Suggestions do not.
- New completed sessions save exercise names independently of future plan edits.
- Active sessions save the rest deadline. Countdown and duration use wall clock time.
- Shared catalog identity, replacement/reordering during sessions, and completed-session note snapshots remain for the next slice.
- Existing Hive models remain at the storage boundary for this slice. Storage-independent application models still need to be extracted before expanding the catalog or adding a backend.
- Defer detailed timed/bodyweight and superset interactions until the basic flow is reviewed.

## Implementation review

The app uses the existing Hive data and BLoC flow. It now includes prefilled set entry, completion undo,
rest extension/skip, exercise notes/targets, plan exercise ordering, saved session details, and tablet overview.
There are no new packages or generated graphics in this slice. Existing settings and onboarding remain for later refinement.

Review: visual character, ease of reading while tired, reachability of logging controls,
and the refined Focus design. Review empty/error states and native platform behavior in implementation.
