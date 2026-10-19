# Spottr design guide

## App-wide athletic identity — 19 October 2026

The user clarified that the fitness identity must apply across screens and authorized direct
Flutter implementation. This supersedes the older green baseline and workout-only cobalt scope
below. Use one charcoal/chalk/electric-lime system across Today, Plans, Progress, onboarding,
settings, editors and Active Workout. Bundled Outfit uses stronger display and heading weights;
body text remains quiet and readable. No new fonts, dependencies or image assets are required.

Primary filled actions use electric lime `#C4F442` with charcoal `#20241F` text in both themes.
Use the same lime accent in both themes. In light mode, action text and unfilled icons use
charcoal; selected controls and navigation use lime fills with charcoal foregrounds. Never use
the earlier deep-green fallback or lime text on light surfaces. Headings and onboarding icon
badges use lime backgrounds with charcoal symbols. Keep errors independently readable, and
communicate light-theme completion with explicit labels and checkmarks rather than a separate green accent.

Today uses a dark training panel in both themes, with a fitness mark, lime upper edge and
primary start/resume action. Plans repeat the upper-edge treatment for the active routine.
Plans and embedded Progress share compact icon headings; the app navigation uses a training
symbol for Today. These are visual changes only: labels, navigation and workout rules remain.
The curved workout logging dock and optional final-set-only behavior are preserved. WorkoutTheme
now adjusts density while inheriting the shared palette, rather than introducing a separate brand.

Keep imagery secondary to the user's actual routine. Do not invent muscle targets or exercise
illustrations for custom movements. Existing restrained state transitions and reduced-motion
behavior are retained. Device and accessibility review is still required before release.


## Active Workout refinement — 19 October 2026

The user accepted the visual direction, especially the curved top of the bottom logging panel,
and requested direct Flutter refinement with no more mockups. Preserve that silhouette and the
scoped palette. Finish is quieter; the selected set has an accent edge as well as its status label.
Final set only appears below the exercise note when a final unlogged set exists. It selects the
last set without completing it. The editor explains that only this set will be recorded. After
logging, show the actual recorded count, Next exercise and Log earlier sets; retain all rows.
This is an optional per-exercise shortcut, not a global tracking mode or a claim that unlogged
sets were performed. Existing numeric dialogs, persistence and rest behavior remain intact.

## Direction under review — 18 October 2026

The user accepted the prototype flow and authorized creative development of the Active Workout
anchor. The first Flutter visual pass now uses scoped chalk/graphite/cobalt tokens in
`lib/core/theme/workout_theme.dart`, bundled Outfit with stronger exercise titles and tabular
values, a bottom logging surface, quieter overview controls and animated selection/progress.
This supersedes the green specification for Active Workout only. Other screens retain the baseline
below until this anchor receives visual review. No storage or workout-rule changes are involved.

Keep previous performance and rest with the logging controls. Finish is in the header. Compact
portrait retains the primary action; large text uses scrollable content and controls. Tablet keeps
an overview beside a constrained focused area. Selection/progress/check transitions take 160–220ms
and honor reduced motion. Numeric entry still uses the existing validated dialogs: the prototype's
inline keyboard interaction, repeat shortcut and progression guidance remain a separate follow-up.
Do not describe this visual slice as completing every prototype interaction.

## Current visual specification

On 13 October 2026 the user rejected the latest Stitch concepts and chose to
continue with the existing Flutter UI. Keep the implemented warm off-white,
forest/clay light theme, deep green/sage dark theme, and bundled Outfit typography.
The current theme source is `lib/core/theme/app_theme.dart`, with shared typography
in `lib/core/theme/app_typography.dart`. Improve this direction through actual
Flutter screens rather than more generated concepts.

Phase 2 began on 17 October 2026. Implemented tighter workout hierarchy and spacing,
shorter previous-set context with a details sheet, clearer set status, quieter Today
headings and brief completion-check feedback that respects reduced motion.
The shared exercise editor now keeps its primary action outside the scrolling form
when height permits, preserves input across keyboard/width changes, and places optional
rest customization behind an explicit action. Targets share a row on wide screens and
stack for large text. Tiny landscape/keyboard layouts scroll the whole editor.
Settings now uses open, grouped rows with constrained tablet width. Workout preferences
use adaptive switches. Onboarding uses the same typography/actions, scrollable steps,
clear progress/back controls and brief transitions that respect reduced motion.
Profile uses wrapping theme choices, optional validated details and a persistent save action.
Schedule details use open rows, accessible day selection, adaptive time pickers and visible retry
feedback. Both constrain content on tablets and scroll at large text sizes. Broader motion remains.
Native device and screen-reader review remain required.

The workout overview now provides move-earlier, move-later and replace actions in each
exercise's options menu. It stays live while the phone sheet is open and shares the same
rows on tablets. Selection follows entry identity through moves. Logged exercises show
why replacement is unavailable; users can add an alternative while retaining logged work.
Replacement uses the shared editor with a clear session-only explanation and fresh fields.
Keep these controls secondary to logging; no drag gesture is required.

Plan additions and session add/replace now open a searchable picker. Use open rows,
saved setup cues and quiet source labels, with your exercises before common choices.
Selection adds a fresh entry directly; the existing details editor handles later adjustments.
Keep custom creation available during loading, empty and error states. Short keyboard layouts
scroll the header and actions with the list; standard layouts keep the create action reachable.

Progress uses a compact all-time summary and month-grouped session rows with a clear date
column. Large text switches metrics to compact inline values. Workout details preserve saved
exercise names, original set positions and logged-set types. Empty and load-error states explain
the next step without placeholder metrics. Workouts/Exercises tabs keep session browsing as the
default. Exercise history uses searchable open rows, one best-set summary and expandable past
workouts. Preserve original set positions and labels; offer a visible full-workout action.
Keep rule explanations secondary and searchable history usable with the keyboard open.
Further charts and estimated-strength metrics remain outside this slice.

Today distinguishes recorded minutes from missing timing and shows history loading/retry states
before recommending a workout. Weekly date markers fit the available width and provide full date
labels for accessibility. Large text uses smaller summary typography. In short Progress layouts,
omit the redundant embedded heading and tighten tab spacing so search stays reachable.

### Rejected design history

All Stitch directions were rejected on 13 October 2026. Their provisional approvals,
Inter/coral tokens and reference prompts are historical only. They do not authorize UI changes.
See [DESIGN.md](../DESIGN.md), [the reference pass](stitch-image-reference-pass.md) and
[the final retry](stitch-clean-training-review.md) for that exploration history.

## Direction

Keep the implemented mineral/off-white background, forest actions and restrained clay accents
in light mode, with deep green surfaces and sage emphasis in dark mode. Use bundled Outfit.
The Flutter theme and the current specification above are the active design authority.
Use open rows for preferences and history; reserve surfaces for meaningful groups such as a
routine or totals. Give logging controls priority over headings or decorative content.

## Design authorship

The UI should feel thoughtfully designed by an experienced, creative product designer.
Judge the result through concrete choices, not claims that a design is premium or beautiful.

- Establish a recognizable visual identity through type, proportion, rhythm, color, and interaction.
- Build layouts around the actual workout task. Avoid repeating generic dashboard cards on every screen.
- Use deliberate typography and restrained emphasis; do not make every label bold or every number oversized.
- Avoid gratuitous gradients, glass effects, glowing accents, decorative badges, and filler illustrations.
- Let whitespace and alignment establish hierarchy before adding boxes, borders, or shadows.
- Give each screen an appropriate composition while keeping shared controls and tokens consistent.
- Make animations explain an action or preserve continuity; omit motion with no useful role.
- Review realistic content and difficult states, not only a polished empty mockup.
- Rework anything visually generic or awkward to use, even if it is technically correct.
- Apply these criteria to every screen and both themes, including dialogs, editors, and error states.

## Workout interaction

- Make the current exercise and next set the primary focus.
- Keep weight, reps, previous performance, and the completion action easy to scan.
- Place optional notes below the exercise name in secondary text with readable contrast.
- Keep key actions within comfortable reach and separate destructive actions.
- Offer large increment/decrement controls and direct entry when needed.
- Preserve input and focus during rebuilds; avoid moving content while the user types.
- Before opening exercise dialogs or plan menus, dismiss the active text field so closing the
  popup does not reopen its keyboard. Keep entered text and explicit tap-to-edit behavior.
- Show rest with clear skip and extend actions. Keep workout context visible.
- Use gestures as shortcuts, with visible alternatives.
- Make mistakes recoverable. Avoid confirmation dialogs for easily reversible actions.

## Visual system

- Define shared semantic color, spacing, radius, and typography tokens before building screens.
- Give light and dark themes equal care, including errors, disabled controls, and contrast.
- Use a consistent icon family; pair unfamiliar icons with labels.
- Use tabular numerals where counters or timers would otherwise shift.
- Keep charts understandable without depending on color alone.
- Avoid decoration that competes with set logging.

## Adaptive layout and accessibility

- Design against available constraints, not device-name checks.
- Test compact widths, keyboard-open states, landscape, and large text.
- On tablets, consider an overview beside the focused exercise rather than stretching a phone layout.
- Keep content widths comfortable. Preserve session state when resizing or rotating.
- Aim for touch targets of at least 48 logical pixels; make primary logging controls larger.
- Provide screen-reader labels, sensible focus order, and sufficient contrast.
- Use platform-appropriate pickers, dialogs, navigation transitions, and back behavior.
- Review selected controls with TalkBack and VoiceOver before release.

## Motion and feedback

- Animate changes that benefit from explanation: set completion, rest transitions, and navigation.
- Prefer brief, interruptible transitions. Never block another tap while celebrating.
- Honor reduced-motion preferences and make sound/haptics optional.
- Keep personal-record feedback small during workouts; fuller celebrations can follow completion.

## Assets

- Prefer vector icons and code-drawn UI for sharp, lightweight controls.
- Generate custom bitmap illustrations only when they add value, such as onboarding or empty states.
- Keep a consistent visual style, size, and licensing/provenance record for shipped assets.
- If external generation is needed, provide a prompt with composition, palette, dimensions, and background needs.
- Check exercise illustrations for technique accuracy before presenting them as instruction.

## Design review

Start with Active Workout, then Today and Progress. Review realistic data and the actual interaction flow.
Include long exercise names, optional notes, large values, empty history, interrupted sessions, and save errors.
Review both visual concepts and rendered Flutter screens; static mockups do not prove usability.

## References

- [Adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)
- [Platform adaptations](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations)
- [Accessibility](https://docs.flutter.dev/ui/accessibility)
- [Effective Dart](https://dart.dev/effective-dart)
- [Flutter team agent skills](https://github.com/flutter/agent-plugins)

Use responsive-layout, layout-debugging, or testing skills only when needed. Review compatibility first;
the architecture skill's MVVM/ChangeNotifier instructions do not override our BLoC direction.
