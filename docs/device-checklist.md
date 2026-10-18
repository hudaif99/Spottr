# Device acceptance checks

Use a test device and keep a backup of any existing workouts before installing a test build.
Do not uninstall an existing app to work around a signing mismatch; preserve its data first.
Record device/OS, app version, theme and any failed step.

## Android

- [ ] Start a workout, change kg/reps, log/undo a set and verify totals.
- [ ] Add, replace and reorder exercises. Check notes and the previous-session values.
- [ ] Background and reopen during rest. Check the remaining time and optional sound.
- [ ] Close/reopen the app during a workout. Resume the saved sets and notes.
- [ ] Finish a partial workout. Confirm that only logged sets appear in Progress.
- [ ] Cancel a separate test workout. Confirm that no completed history is added.
- [ ] Browse/search exercise history and open a full workout from it.
- [ ] Export a backup, then restore it on a test installation. Verify plans, history,
  settings, reminders and an imported active session. Check the native picker/share sheet.
- [ ] Grant/deny notification permission. Set a near-future reminder and verify delivery
  while backgrounded. Finish before another reminder and confirm same-day suppression.
- [ ] Reboot the test device and check a future reminder. Reopen after changing time zone.
- [ ] Check light/dark, large text, keyboard-open entry and phone rotation.
- [ ] Use TalkBack for navigation, set controls, selection states and save/retry feedback.
- [ ] Try a real workout: logging should remain quick, readable and comfortable while tired.

## iPhone and iPad

Run the same core flows above after a macOS/Xcode build. Also check notification permission,
foreground/background delivery, native time pickers, safe areas, back navigation, VoiceOver,
iPad rotation and the anchored share sheet. Record simulator and physical-device results separately.

## Before merging or distributing

- [ ] Complete native upgrade/migration and interrupted-session checks with retained data.
- [ ] Verify the intended signing identity and update path. A debug-signed test APK is not
  a store-ready release. Confirm the existing iOS bundle identity before provisioning.
- [ ] Resolve failed acceptance checks and review the final changes.
- [ ] Obtain approval before merging into `main`, pushing or publishing.
