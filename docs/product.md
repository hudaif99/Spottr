# Spottr product direction

## Goal

A beautiful, simple workout companion that makes logging feel easy during demanding workouts.
The main action should be obvious, useful context visible, and repeated typing rare.

## Agreed requirements

- A fresh visual identity, navigation, and user experience.
- Kilograms only; no pounds setting.
- Flexible plans and sessions: add, replace, reorder, or skip exercises.
- Optional short exercise notes, such as equipment setup cues, shown quietly with the exercise.
- Offline suggestions for common exercise names while typing, with custom names always allowed.
- Offline use and reliable recovery of interrupted workouts.
- Clear storage boundaries so a backend can be integrated later. No backend integration in this redesign.
- Android and iOS support with responsive small-phone and iPad layouts.
- Purposeful animations, clean code, few dependencies, and focused tests.
- Device back on Today, Plans or Progress shows "Press back again to exit".
  A second press within two seconds exits; other routes retain normal back navigation.
- Preserve the current app in Git and protect existing user data during migration.
- Reminders use a user-approved 14-day dated window, refreshed when the app opens/resumes.
  They expire if the app stays unopened past that window. Completed workouts suppress that
  day's training nudges; future reminders remain available after refresh.

## Proposed first-release scope

These ideas guide design review; their detailed behavior is not yet approved.

| Area | Proposal |
| --- | --- |
| Today | Next workout, resume action, and a compact weekly summary |
| Plans | Simple plan editing, starter plans, exercise search, and custom exercises |
| Workout | Prefilled sets, one-tap completion, rest timer, undo, notes, and exercise changes |
| Progress | Session details, exercise history, useful trends, and personal records |
| Settings | Appearance, optional reminders, workout preferences, and safe backup/restore |

Additional candidates: empty workouts, repeat a session, bodyweight/timed exercises, warm-up sets,
and supersets. Introduce them only with simple interactions and clear calculation rules.
Accounts, social feeds, nutrition, and AI coaching are outside the proposed first release.

## Behavior to settle during design

- Prefer one exercise in focus with a compact overview and free movement between exercises.
- Suggested values become completed sets only after explicit confirmation.
- Final-set-only logging is a per-exercise shortcut to select the final existing set for entry.
  Selecting it never logs anything. Earlier sets remain unchanged, and only explicitly recorded
  sets contribute to volume/history. When the final set is recorded with earlier gaps, show
  "Final set logged" with Next exercise and Log earlier sets; do not claim the exercise is complete.
  Derive this state from saved set completion flags so it survives resume without a new preference
  or migration. Original set positions remain in saved history. Undo and out-of-order logging remain available.
- Prefer session-only exercise changes, with an explicit action to update the plan.
- Decide whether notes belong to the shared exercise, a plan entry, or both; avoid ambiguous inheritance.
- Give exercises stable identity across plans. Preserve session names and context when plans change.
- Define completed-set volume, warm-up inclusion, timed/bodyweight progress, and personal-record rules.
- Exercise progress shows saved completed sets by shared movement identity. Best logged set
  means highest recorded kg, then highest reps at that weight; logged warm-ups and drop sets
  count. Older entries without identity stay separate. No estimated strength or body mass is inferred.
- Today's weekly summary uses the local Monday-to-Sunday calendar week through the current
  time. Only recorded durations contribute to minutes; missing timing stays explicit. History
  loading/failures never appear as zero progress or a guessed next workout. Resume remains available.
- Partial workouts use the existing finish confirmation. Only completed sets count toward
  totals and appear in history details; untouched exercises are omitted. Users may bypass
  an exercise through the overview and return later. No separate skipped status is stored.

## Acceptance targets

- Start the next planned workout from Today with one tap.
- Complete a prefilled set with one tap; no keyboard required when values are unchanged.
- Logging a set carries its weight into the next untouched regular set. Preserve manual weights,
  different historical weight targets, completed sets and warm-up/drop sets; leave reps unchanged.
- See the current exercise, note, previous performance, and next action with minimal navigation.
- Correct mistakes and change exercises without abandoning the session.
- Resume the latest persisted session after restarting the app.
- Show save failures clearly and retain a recoverable session for retry.
- Preserve existing plans and history through a tested migration.
- Restore only validated backups, with recovery if replacement fails.

## Architecture direction

Retain BLoC and get_it initially. Rebuild around UI, workout logic, and storage/service boundaries.
Use repository interfaces and storage-independent models where they make future replacement possible.
Add no Firebase SDK, network client, sync engine, or speculative use-case layers now.

Reference: [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations).
