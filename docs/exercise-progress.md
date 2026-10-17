# Exercise progress

## Behavior

- Progress opens on Workouts. Exercises offers a search over saved exercise names,
  ordered by most recent logged workout. Search and browsing work offline.
- An exercise opens its best logged set, date, workout/set counts and newest-first sessions.
  Expand a session to see actual completed sets or open the full workout.
- Only explicitly completed sets count. Suggested and unfinished sets are absent.
  Completed warm-ups and drop sets retain their labels and count as before.
- Best means highest recorded weight, then most reps at that weight. Exact ties display
  the most recent occurrence; equal session dates use workout ID for deterministic order.
  Zero kg remains the recorded load, with no inferred body mass or estimated strength.
- Record notifications use the same comparison. Their existing milestone priority and
  requirement to beat previous matching completed sets remain unchanged.

## Identity and ownership

- Explicit movement identity joins history across plans, including reused custom movements.
  Identically named custom movements with different identities stay separate.
- Multiple entries for one movement in a workout form one session, keeping every completed
  set and its original entry ID and set number. Entries are not deduplicated by set ID.
- Legacy history without identity is grouped by entry ID and normalized saved name.
  It stays separate from explicit identities. Missing snapshots are not guessed from current plans.
  This conservative grouping may show several rows for similar older exercises.
- Names come from the latest matching saved snapshot. Old session snapshots and data stay intact.
  No stored format, Hive field, migration, dependency or write path changed.
- History state owns an immutable snapshot and builds the groups once per load. Open exercise
  pages follow refreshed state; removed records show an empty state instead of stale results.

## Scope and validation

This slice adds readable performance history and the existing best-set rule. Charts, estimated
strength, timed/bodyweight rules, supersets and new record categories remain separate decisions.

Focused tests cover grouping, legacy separation, repeated entries, original positions, completed
sets, record comparison, immutable snapshots, search, navigation, refresh/retry and keyboard layouts.
Flutter renders are reviewed in light/dark, compact large-text and tablet layouts, including
empty and error states. Native keyboards, TalkBack/VoiceOver and Android/iOS devices remain
release acceptance checks; Windows widget renders do not verify an iOS build.
