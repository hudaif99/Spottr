# Phase 6 automated verification

17 October 2026, Windows 11, `spottr-redesign`, starting from `6622655`.
This is build/host-test evidence. Native acceptance and approval to merge remain open.

## Environment

- Flutter 3.47.2, Dart 3.13.2, Microsoft JDK 17.0.20.
- Android SDK/compile platform 37 and build-tools 37.0.0; Android licenses accepted.
- Gradle 8.14, Android Gradle Plugin 8.11.1, Kotlin 2.2.20.
- No connected Android device, configured AVD or installed emulator system image was available.
  Flutter listed Windows, Chrome and Edge only. Windows desktop build tools are incomplete;
  Windows desktop is outside this mobile validation scope.
- macOS/Xcode is unavailable on this host. No iOS build or simulator/device check was run.

## Checks

| Check | Result |
| --- | --- |
| `flutter test --reporter expanded` | All 175 tests passed again after cleanup. The initial baseline run also passed all 175. |
| `flutter analyze` | Final result: no issues. Eight pre-existing informational notices were resolved. |
| `dart format --output=none --set-exit-if-changed lib test test_hive.dart` | All 109 files pass; no formatting changes required after cleanup. |
| `flutter build apk --release --no-pub` | Completed successfully: `build/app/outputs/flutter-apk/app-release.apk`, reported 58.2 MB. The process had already exited when the user requested stopping builds. No further build was started. |
| Native Android/iOS interactions | Not run; required hardware/tooling unavailable. |

The suite covers classic/pre-identity storage compatibility, real-file persistence, session
recovery and write ordering, backup validation/rollback, shared identity, completed-set progress,
reminder date/time-zone rules, mocked platform payloads and primary UI/adaptive flows. Mocked
permissions/notifications and host widget layouts do not prove native delivery or device usability.

Local logs are under ignored `build/verification/`: `flutter-tests.log`,
`flutter-tests-final.log`, `flutter-analysis.log`, `android-build.log` and
`android-build-final.log`. Logs/build outputs are local artifacts and are not committed.

## Fixes made during validation

- Kotlin's incremental compiler failed when relativizing plugin sources on `C:` against this
  checkout on `E:`. The first build attempt was interrupted after the daemon/cache errors.
  Set `kotlin.incremental=false` in `android/gradle.properties` and rebuilt with the normal Flutter
  command. This disables Kotlin incremental compilation, with a build-speed tradeoff; it does not
  change app behavior. The setting is documented in the
  [Kotlin compiler/cache guide](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).
- Replaced unused callback names with Dart wildcards, migrated three deprecated color-alpha
  calls, formatted Splash and used `debugPrint` in the old manual Hive script. No persistence,
  scheduling, schema, dependency or signing configuration changed. The manual Hive script was
  not run because it writes through the normal local database service.

## Distribution and native acceptance

### Next-set weight follow-up — 18 October 2026

Logged weights now carry into the next untouched regular set. Tests cover zero-default sets,
manual 0 kg entries, distinct history targets, completed-set corrections, warm-up/drop protection,
save failure/retry, real-file resume, classic storage and backup restoration. The logging/storage/widget
run passed 80 tests; a follow-up with added set-type guards and backup checks passed 53 tests
(logging coverage overlaps). Scoped analysis of ten changed Dart files and formatting passed.
No APK build or native device test was run. Old active sessions retain their values; start a new
workout after upgrading to exercise the new suggestion behavior.

### Follow-up — 18 October 2026

The user hit the onboarding save message after granting notifications in an installed APK.
The UI was reproducing the wrong message for a scheduler exception after successful persistence.
It now distinguishes these cases and permits explicit continuation after the schedule is safely
stored, retaining reminder retry in Settings. Real save failures still block setup completion.

The Android app also lacked the release Gson/TypeToken keep rules documented in the notification
plugin's [v18.0.1 example](https://github.com/MaikuB/flutter_local_notifications/blob/flutter_local_notifications-v18.0.1/flutter_local_notifications/example/android/app/proguard-rules.pro).
Added those rules, kept notification model fields and retained the notification icon resource.
This is a likely release-specific cause, not a confirmed diagnosis of the device exception.
All 27 focused settings/onboarding tests, scoped Dart analysis, formatting and diff checks passed.
Reviewed actual light/dark, large-text and tablet failure-state renders. No new APK was built;
the updated release APK still needs a device retest. A debug run may not reproduce an R8 issue.

The APK's signature, installation and runtime behavior were not checked after the user took over
build/device testing. The existing release build type uses the debug signing configuration. A successful release-mode
build is therefore a local test artifact, not a store-ready signed release or proof of a safe
upgrade over an existing installation. Verify the intended signing identity and retained-data
upgrade before distribution. No production keys were created or changed.

Flutter reports future-support warnings for the current Gradle, Android Gradle Plugin and Kotlin
versions. No build-validation bypass or toolchain upgrade was introduced. Schedule a coordinated
toolchain update separately and recheck plugins on Android/iOS.

The iOS source currently uses bundle ID `com.hudaif.volt.volt`. Confirm the intended existing
identity on macOS before changing provisioning or distribution settings; no identifier was changed.

Use [device-checklist.md](device-checklist.md) for physical-device, native permission/delivery,
background/rest, keyboard, accessibility, migration and backup/share acceptance. Phase 6 stays open
until those results and the final review are complete. No merge, push or publishing was performed.
