# Reminder scheduling

Implemented in Phase 5 on 17 October 2026. The user approved a rolling 14-day window
after reviewing its expiry trade-off. No dependency or Hive format changed.

## Delivery window

Reminders are dated, one-shot requests. Repeating calendar triggers cannot reliably skip
just today's occurrence by supplying a later starting date. The installed plugin's native
implementations reduce repeating requests to matching time/weekday components.

Refresh schedules the remaining part of today and the following 13 calendar days, ending
at local midnight on day 14. It runs on launch, foreground resume, schedule changes,
successful restore refresh, and persisted workout start/finish/cancel. Opening the app
replenishes the window. Reminders expire if the app remains unopened past that window;
there is no background refill or backend dependency. Settings explains the two-week requirement.

At most 58 planned requests are queued: 42 workout prompts, 14 daily motivation reminders
and two weekly summaries. The test notification uses a separate ID. This leaves room under
the [plugin's documented iOS limit of 64 pending requests](https://github.com/MaikuB/flutter_local_notifications/blob/flutter_local_notifications-v18.0.1/flutter_local_notifications/README.md#ios-pending-notifications-limit).

Stable date/type IDs prevent duplicates within a window. Every refresh removes both legacy
recurring IDs and the app's dated reminder ranges, without cancelling achievements or unrelated
IDs. Turning reminders off, deleting the schedule or selecting no workout days removes the
planned requests.

## Calendar and suppression rules

- Training prompts remain 30 minutes before, five minutes before and 30 minutes after
  the scheduled workout. Offsets use the workout's real instant and may cross midnight.
- Calendar dates are constructed in the current device time zone. Days are not advanced
  by fixed 24-hour durations, so normal wall-clock times survive DST changes.
- Spring times inside the missing hour move forward by the gap. Ambiguous autumn times
  use the first occurrence, with one request per type/date. These behaviors are host-tested
  with the installed timezone library; native delivery still needs device checks.
- A persisted active workout suppresses training prompts for its start date. Cancellation
  or empty finish rebuilds the remaining prompts; elapsed reminders are not replayed.
- A saved workout with completed sets suppresses training prompts on its local start and
  completion dates. This covers sessions crossing midnight. Partial workouts qualify.
- The daily 20:00 motivation reminder is omitted on the local completion date. Future dates
  remain scheduled. Legacy records without a valid end time use their start date.
- Existing daily motivation and Sunday 19:00 summary timing is retained. A weekly summary
  is still allowed after training that day. Unfinished suggestions never suppress reminders.

The device zone is refreshed before enabled scheduling, including foreground resume. If the
device changes zones while the app remains closed, existing requests retain the previously
scheduled zone until the next refresh.

## Failure and ownership

Scheduling/cancellation shares one queue across workout and schedule flows. Production refresh
reads the latest stored schedule when its queued operation starts, so an outdated caller cannot
reinstall an old preference. Schedule deletion persists first; a cancellation failure retains the
deletion and offers cleanup retry.

Time-zone and workout-history reads complete before existing requests are cancelled. Read failures
leave the previous requests intact. A native failure during installation may leave a partial batch;
the settings retry or next foreground refresh clears and rebuilds it. Disabling reminders needs
neither history nor time-zone lookup. Reminder failures never undo a saved workout.

## Verification and remaining checks

- 72 relevant tests passed across focused date, scheduler, workout and settings runs.
- Covered midnight/week/year boundaries, both DST changes and gap/fold hours, completion/active
  suppression, cancellation, slot limits, idempotence, stale queued updates, read/native failures,
  timezone refresh, lifecycle refresh, restore and workout integration.
- Mocked Android and iOS platform channels receive full dates without repeat components. These
  are payload checks, not native builds or delivery tests.
- Reviewed the settings note in light, compact large-text dark and tablet layouts.

Physical-device delivery, exact-alarm permission, reboot behavior, closed-app travel, native
notification permissions and an iOS build remain release checks. This slice does not claim
delivery guarantees from host tests.
