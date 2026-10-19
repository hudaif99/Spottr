# Workout redesign review — 18 October 2026

Status: proposed direction; awaiting user review. No Flutter behavior or storage changes.
The user's new brief reopens the visual identity. Earlier green-theme decisions remain the
implementation baseline, not a restriction on this proposal.

## Recommendation

Use a hybrid workflow: review one small clickable workout concept, then implement the accepted
screen in Flutter using the existing BLoC and repository. Avoid a second implementation of the
whole app. Browser prototypes settle hierarchy and sequencing quickly, but cannot establish
native keyboard, focus, accessibility, recovery or persistence correctness.

Open [the interactive concept](core-workout.html). It contains sample data only. Browser refresh
resets it. Save/retry is simulated; it is not connected to Hive or the real workout engine.

## Audit evidence

Reviewed the current product/design/roadmap documents, theme, active-workout screen, numeric
controls, previous-set component, Today/navigation, exercise progress, workout mutation paths,
and existing UI coverage. The working tree began clean on `spottr-redesign`.

| Finding | Evidence and implication |
| --- | --- |
| Primary action loses the best screen position | Fresh Flutter render at 320 × 568 shows Log set below the fold while Finish stays pinned. Put logging in the bottom action area and finishing in the header. |
| Entry requires unnecessary context changes | `workout_value_control.dart` opens a separate modal for each number and requires Done. Inline weight/reps entry can remove these repeated modal transitions. Native focus behavior still needs testing. |
| Screen repeats the same set information | A large input card and a separate list both show current-set values. The fresh 390 × 844 render shows the third set below the initial viewport. Use a compact comparison ledger and one editor. |
| Rest can move out of view | `_focus` renders rest below the input panel inside the scrolling body. Keep rest controls with the logging controls. |
| Progress describes history more than a next action | Exercise list leads with best logged set; history remains useful but lacks an explicit next-session comparison. Put comparable previous sets beside current targets. |
| Existing navigation is already economical | Today, Plans and Progress are three clear destinations; start/resume is already one primary action. Preserve that structure. |
| Existing visual style is coherent but overly spacious for the task | Large headings, vertical gaps, rounded bordered panel and repeated outlined controls dominate the fresh renders. This is a design judgment, not a measured user-study result. |

Do not claim the app lacks undo, prefill, rest, resume or exercise replacement: they already exist.
Keep the persisted session, serialized writes, retry states, safe finish/cancel, setup notes,
offline library/custom movements, identity-aware history, validated backups and reminder behavior.
This review does not re-certify their complete implementation.

Untested hypotheses: a bottom editor will be easier one-handed; inline fields will reduce effort;
set comparison will improve next-workout decisions. Validate these with real use, including fatigue.

## Visual direction: a precise training log

- Chalk `#F4F5F7`, white `#FFFFFF`, graphite `#20252D`, secondary ink `#576172`, cobalt `#254EDB`.
- Dark: graphite `#181C24`, lifted surface `#242A35`, text `#F3F5FA`, muted `#B3BDCE`, pale cobalt `#A9BAFF`.
- Native system sans for labels and titles; tabular numbers for performance and timers. No new font dependency.
- Aligned set rows communicate sequence. One cobalt edge identifies the current row. Completed rows say Logged and include a check, so meaning is not color-only.
- Use surface contrast only for the input area; remove nested cards and ornamental gradients.
- Retain a consistent Flutter icon family, with labels for exercise actions. No icon-package migration.
- Brief completion feedback only; respect reduced motion. No movement of active fields while typing.

The redesign and frontend-design skills informed hierarchy, restraint, typography and preservation
of the existing stack. Their suggestions for texture, cinematic movement, decorative depth and
large marketing spacing are intentionally excluded because they compete with logging.

## Core interaction contract

1. Today starts/resumes the session. Workout opens on the next unfinished set.
2. Show exercise, setup note, set comparison and prefilled kg/reps. Previous values are evidence;
   drafts never count as completed work.
3. One tap logs unchanged values. Direct entry and 48px steppers change a draft. The primary
   action remains available at compact portrait sizes; the ledger scrolls independently.
4. On successful completion, select the next unfinished set, retain existing carry-forward rules,
   start rest and offer Undo. Show saving/pending/retry honestly in the Flutter implementation.
5. Rest has +30 sec and Skip beside entry. Users can prepare the next set without dismissing rest.
6. Selecting a logged row opens correction. Save correction does not create a second completion
   or restart rest. Undo restores the original values.
7. Use last set copies values into an unfinished draft; it never logs the set. First set can reuse
   last session. Without history, show no invented previous numbers.
8. Overview supports free exercise selection. Preserve the existing restriction against replacing
   logged exercises; offer adding an alternative instead. Never silently change the saved plan.
9. Finish reviews completed totals. In Flutter, leave only after persistence succeeds; failures
   remain recoverable using the existing engine.

The concept includes two sample exercises, corrections, undo, rest, repeat, exercise selection,
one example replacement, partial finish and simulated save failure. It does not implement the
complete picker, adding alternatives, persistence, screen-reader order or native keyboard behavior.

## Progression guidance

Essential first step: show the last comparable set next to the current input, with a clearly
optional extra-rep target. Never silently raise the load or overwrite a plan. If historical weight
differs from the current draft, compare cautiously rather than imply the targets are equivalent.
Legacy unmatched history remains separate. No estimated-strength or personal-record rule changes.

After the core review, refine this into user-controlled rep ranges and equipment increments if
needed. Those settings need a separately reviewed backward-compatible model change. No backend
is needed. Do not infer equipment increments, readiness or recovery from workout history alone.

| Priority | Improvement | Benefit | Effort |
| --- | --- | --- | --- |
| Essential | Bottom logging area with inline entry | Removes modal trips and keeps Log reachable | Medium; native keyboard/focus work |
| Essential | Previous/current set comparison with optional rep target | Makes the next decision visible | Low–medium using existing history |
| Essential | Rest, repeat and correction in the same working area | Fewer interruptions between sets | Low–medium; reuse existing logic |
| Later | Explicit rep ranges and equipment increments | More useful load progression suggestions | Medium; settings/model compatibility required |

## References

[Hevy's previous values](https://www.hevyapp.com/features/track-exercises/) show why set-by-set
context belongs at the moment of entry. [Strong's rest timer](https://help.strongapp.io/article/231-rest-timer)
demonstrates rest beginning on completion while remaining in the workout. These are interaction
references from official product documentation, not claims of hands-on testing or visual copying.

## Delivery gates

1. Review this direction and core concept. Do not replace app-wide tokens yet.
2. Implement Active Workout in Flutter with shared provisional tokens and the existing logic.
   Validate keyboard, long names, no history, correction, failed saves, resume and partial finish.
3. After the anchor is approved, extend to Today, Plans/editors, Progress and settings in focused slices.
4. Validate supported Android/iOS devices, accessibility and recovery before release. Preserve history
   and Hive IDs; review any new progression preferences separately.

## Verification in this review

- Six existing Flutter widget checks passed: Today one-tap start, logging/undo/setup cue, and workout
  layouts at compact width, 1.8× text, tablet and dark mode.
- Inspected newly rendered Flutter captures for Today and light/dark/compact Active Workout.
- Browser concept checks verified completion, undo, correction and correction undo, automatic rest,
  skipping rest, simulated save failure with no completed-count increase, and successful retry.
- Browser emulation checked 390 × 844 and 320 × 568 without horizontal overflow. Log remained visible;
  sampled visible phone buttons were at least 48 CSS pixels high. The final compact check included rest.
- Android device discovery succeeded, but this review did not install or exercise the app on that device.
- Native keyboards, TalkBack/VoiceOver, actual fatigue use, contrast automation, native interrupted
  recovery and iOS execution remain unverified. Browser success does not establish those properties.
- No Flutter code changed; no new build, broad regression suite or analysis run was needed for this
  documentation/prototype phase. Prior roadmap build results are historical, not rerun here.
