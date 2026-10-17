# Backup and restore

Implemented 17 October 2026 in Phase 3. No Hive type/field IDs or adapters changed.

## Archive contract

Exports contain the six known Spottr Hive files using portable basenames and a
`spottr.json` manifest with format `spottr`, version `1`. Other application files
are not exported. Existing flat ZIP backups without a manifest are accepted when
plans, exercises, history and settings are present. Legacy active-session and
schedule files are optional; missing optional boxes become empty, rather than
keeping unrelated current data.

Validation checks allowed names, duplicate entries, directory/link entries, archive
size, declared expanded size, ZIP checksums, manifest version, Hive decoding and
workout/settings values. Imports are limited to 64 MiB compressed and 128 MiB declared
expanded content. Exports use the same limits. Nothing is extracted using a supplied
path. Hive validates staged bytes in separate in-memory boxes without repairing or
truncating corrupt input. A small guarded zone handles Hive 2.2's additional internal
failed-open error; no production adapters are replaced.

## Ownership and recovery

All database writes share a queue. Maintenance waits for accepted writes and rejects
new writes until the operation ends, so stale changes cannot land after replacement.
A current cached or in-memory workout blocks restore; export may include its saved cache.

Restore validates before closing live boxes. It then saves flushed copies of all six
current files and a pending marker in `.spottr_restore`, installs the validated files,
reopens all boxes, and writes a committed marker. File replacement or reopen failures
attempt rollback and reopen. If recovery cannot finish, new writes stay blocked and
the app asks for a restart; recovery files remain available.

Startup recovers a pending transaction before opening boxes. Recovery is idempotent.
Committed cleanup first renames the journal to `.spottr_restore_done`; interruption
while deleting that directory cannot be mistaken for a pending restore or roll back
later edits. Unfinished cleanup is retried on startup. These are host-tested file-state
scenarios, not a claim of physical-device power-loss validation.

Exports reopen the database before opening the share sheet. Cancellation and unknown
share outcomes do not report a successful export. The share call receives an anchor
rectangle for iPad. Platform picker/sharing functions are injectable for focused tests.

## App refresh

The app confirms that restore replaces current data. After success it resets the timer,
reloads plans/history, profile/appearance, default rest and schedule, and recovers the
imported active session. Reminder refresh completes before success feedback. A missing
schedule cancels old reminders. Reminder failures retain restored data and offer an
independent retry in Workout schedule; the data restore is not repeated.

Restored notification choices do not grant OS permission on another device. Native
permission lifecycle and delivery checks remain required. Restored onboarding state
is preserved on disk; onboarding is not forcibly reopened during a restore.

## Verification

All 89 app tests passed, including 16 backup/recovery tests and four restore interaction
tests added in this slice. Formatting checks and analysis of all 49 pending changed/new
Dart files passed. The earlier model extraction remains uncommitted alongside this work.

Real-file tests cover current and legacy round trips, traversal/unknown entries,
incomplete/unsupported/damaged backups, checksums, duplicates, size limits, active
workout protection, injected replacement/reopen failures, pending-write barriers,
startup rollback, interrupted cleanup, and picker/share cancellation.
Widget tests cover confirmation/cancel, share anchoring, all restored BLoCs and rest
settings, active-session protection, reminder completion, empty schedules and independent
reminder retry. The compact dark confirmation was reviewed at 1.8x text scaling.

Device file pickers, share destinations, notification delivery, actual process termination
and iOS builds remain unverified. No new dependency or backend integration was added.
