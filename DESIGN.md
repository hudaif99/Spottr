# Spottr design system
Updated 13 October 2026.
Status: The user rejected the Stitch concepts and chose the existing Flutter UI. Keep warm off-white/forest/clay in light mode, deep green/sage in dark mode, and Outfit typography. The current authority is [docs/design.md](docs/design.md) and the implemented Flutter theme. Refine that direction in the app. All Stitch and Behance tokens below are rejected history and must not drive new implementation.

## Direction and reference evidence
A soft, bright, contemporary mobile product: cool pale canvas, generous rounded forms, clear dark sans-serif typography, restrained depth, and an energetic coral action.
The user agreed to combine the healthcare reference's composition and rounded forms with the nutrition reference's warmth and accent treatment. Previous forest/mineral, industrial, serif and ink/apricot concepts were rejected.

References inspected visually in the browser:
- [Healthcare Mobile App Design](https://www.behance.net/gallery/254164097/Healthcare-Mobile-App-Design): soft gray/light surfaces, broad rounded sections, dark typographic hierarchy, green accents and compact rounded navigation.
- [AI Food Calorie Tracker App UI/UX](https://www.behance.net/gallery/254567479/AI-Food-Calorie-Tracker-App-UIUX-Nutrition-Fitness): white surfaces, coral-orange emphasis, pastel supporting tones and softly elevated controls.

These observations guide an original Spottr composition. The colors/font below are our proposed tokens, not extracted measurements from the references. Borrow visual qualities, not healthcare/nutrition features, photos, illustrations or branded assets.
Separate app UI from Behance presentation: tilted phones, lighting, shadows behind hardware, people, decorative backgrounds and promotional charts do not belong in the workout screen.

## Product rules
A tired person should see exercise context and log an unchanged prefilled set in one tap. Offline routines, history and interrupted-session recovery remain essential.
Use kg only. Notes are optional, readable immediately beside/below the exercise name, up to 180 characters; absent notes leave no empty placeholder.
Focus one exercise and current set, retain completed work and an accessible workout overview. No forced exercise change. Rest allows logging, Skip and +30 seconds.
Only explicitly completed sets contribute to counts and volume; existing explicitly completed warm-ups count. Session edits affect the current workout; permanent edits belong in Plans. Logged exercise names may be locked.
Finish waits for persistence; failures retain recoverable session/input with retry. Discard is separate. BLoC/get_it and repository/service boundaries remain, with compatible Hive IDs and serialized awaited writes.

## Semantic colors
Exact proposed tokens are also in docs/design-tokens.json. Coral carries actions; sage supports completion, never a second competing primary action.

| Role | Light | Dark |
| --- | --- | --- |
| Background | #F5F6F7 | #171A1F |
| Surface | #FFFFFF | #22262D |
| Subtle surface | #ECEFF1 | #2D333C |
| Main text | #202329 | #F3F5F7 |
| Supporting text | #60666E | #B8C0C9 |
| Primary action | #F46B4B | #FF977D |
| Text on action | #202329 | #202329 |
| Accent text / focus ring | #A83B25 | #FF977D |
| Completion text/icon | #34694A | #A8D9B9 |
| Completion surface | #E6F2E9 | #243B2E |
| Error text/icon | #B3261E | #FFB4AB |
| Error surface | #FCEAE7 | #432826 |
| Decorative separator | #E1E5E8 | #3A424D |
| Essential control border | #7A848E | #85919F |

Use dark ink labels on bright coral; white ordinary text does not meet the intended contrast on this light action color.
Body text target >=4.5:1; large text and essential control indicators >=3:1. Check focus rings against adjacent colors too. Decorative separators need not identify controls alone.
Selection/completion/error also use a marker, check, label or error icon. No color-only meaning. No arbitrary low-opacity text; use semantic colors.

## Typography and rhythm
Proposed font: Inter, one family, native-bundled in eventual Flutter implementation after font files/license verification. Reference imagery does not establish an exact font.
Use weights 400/500/600, with 700 sparingly. Sentence case; avoid tiny uppercase technical eyebrows. Numeric values and countdowns use tabular lining figures.

| Role | Size / line height | Weight |
| --- | --- | --- |
| Screen heading | 28 / 34 | 600 |
| Exercise heading | 30 / 36 | 600 |
| Section heading | 20 / 26 | 600 |
| Current weight/reps | 44 / 52 | 600 |
| Timer | 24 / 30 | 600 |
| Note and body | 16 / 24 | 400 |
| Supporting context | 14 / 20 | 400 |
| Action label | 17 / 24 | 600 |
| Compact label | 14 / 20 | 500 |

Spacing: 4, 8, 12, 16, 20, 24, 32, 40. Phone gutters 20px, 16px below 360px. Shared text alignment matters more than repeated boxing.
Surface radius 24px; sheet top 28px; field 16px; primary button 28px; selection row 16px. Step controls can be circles sized56px.
Quiet elevation only for the main logging surface or overlays: at most 0px 4px 16px, black at4% in light theme. Dark theme uses tonal separation instead of shadows. No colored shadows, glow, glass or decorative gradients.
Use Material Symbols Rounded consistently, size24px/weight400; match perceived stroke weight. Pair unfamiliar actions with visible labels and all icon actions with accessible names.
Minimum touch target48px; steppers56px; Log set64px. Containers grow with content; no fixed-height text blocks or tiny auto-scaling.

## Proposed phone workout composition
Reference viewport390×844 logical pixels including safe areas. Ready state must show exercise name, note, previous performance, both values, all four adjustment controls and Log set at ordinary text size.

1. **Chrome:** Back, Lower body, text Finish and Workout options. Back returns to Today with session retained; Discard stays inside options. No main tabs during workout.
2. **Workout context:** a compact 34 min / 7 of 9 sets logged line with a thin progress rule. A labeled Workout overview · Exercise 3 of 3 trigger supports free movement. No calorie-style progress gauge or statistic cards.
3. **Exercise identity:** open dark heading Cable kickback with Session exercise options. Note Pulley at knee level directly below in16px text. Last session · 12.5 kg × 12 reps in readable supporting text. No standalone exercise card, portrait or illustration.
4. **Completed work:** a quiet Set 1 row with check + Logged, 12.5kg ×12 reps, visible Edit and Set options. Options provide Undo completion/Remove; removal offers Undo. Add set is labeled. Extra completed rows scroll; they do not consume the current-set focus.
5. **Reachable logging panel:** a single broad white24px-radius panel near the bottom, with slight neutral elevation. Set 2 of 3 · Prefilled at top. Weight · kg and Reps columns share alignment and open space; editable44px numbers12.5 and12 with soft gray56px minus/plus pairs. No nested value cards, industrial outlined grids or badges.
6. **Primary action:** full-width coral Log set 2 with ink text and check. It belongs to the logging panel and stays above the bottom safe area. Finish never competes here.

Anchor the logging panel's primary action; allow the body and panel content to scroll/reflow at compact height or large text. Do not cover notes/history/input with the panel. Remove gratuitous gaps rather than shrinking targets. Never jump fields while the user is entering a number.
Direct entry uses a keyboard-safe native adaptive dialog/sheet with persistent label, Cancel/Done and validation. Preserve input/focus through rebuilds and retry; weight entry accepts decimals, reps integers. Keep existing2.5kg/1rep step behavior.

## Connected workout states
- **Ready:**7/9 overall, Cable kickback Set2/3, Set1 logged. Prefill stays distinct from completed rows; no active/inactive rest filler.
- **Just logged:**8/9, Set2 now check Logged, Set3 prefilled, brief Undo feedback. Remain on Cable kickback; no automatic exercise navigation.
- **Rest:**compact90-second strip within the lower logging area above the primary action, with Skip/+30s; note and current controls remain visible and logging remains available. Keep the action anchored; scroll/reflow content above it. No modal timer takeover, pulsing ring or countdown gate.
- **Editing completed:**reuse controls with explicit Editing logged set label. Reflect current save-on-edit behavior; Done editing returns to logging. Do not invent a separate draft transaction.
- **All sets completed:**All3 sets logged, Add set and View workout/Next exercise available, Finish stays in chrome.
- **Save/finish failure:**persistent inline error icon/text and Retry/Retry finishing; preserve values/session. Show Save pending, not Saved. No navigation or success feedback until persistence succeeds.
- **Overview:**soft rounded sheet, full exercise names and completed counts, selected marker plus Selected semantics, visible Close and Add exercise. No replacement/reordering controls in this first slice.

## Shared system across later screens
Phone destinations remain Today, Plans, Progress; Settings from chrome. Use a softly rounded, labeled three-item navigation bar with clear selection; reserve safe-area space. Wide app layouts use labeled rail.
Today combines open greeting/context with one purposeful next-workout/resume surface; resume takes priority. Plans uses ordered rows and selected-day content, not a duplicate dashboard-card grid. Progress uses an aligned session list and completed-set detail.
Plan and exercise editors share soft fields, stable labels, keyboard-safe actions and retained input on errors. Custom names stay available alongside offline suggestions; no forced catalog selection.
Appearance, secondary local profile, rest preferences, reminders and backup remain later screens. Personal fields do not gate logging; existing reminder/backup correctness is not assumed verified.

## Adaptive and accessible behavior
At available width>=840px, use a280–320px workout overview beside a focused area max560px. Keep the same panel/controls, not a stretched phone or a second dashboard. Below840px use the overview trigger, including narrow tablet split view.
Check320px and390px width,1194×834 tablet, short landscape,1.8× text, keyboard insets, safe areas and rotation. Keep state, draft input and rest deadline when resizing.
Use full long names (Dumbbell Romanian deadlift), absent notes, and999.5kg as layout stress data. Reflow vertically if two value columns no longer fit; no cropped note or reduced touch targets.
Screen-reader focus follows context, overview, exercise actions, history, current values and adjustments, rest controls, Log set. Announce completion once, not every timer tick. Accessibility activation and tapping perform identical actions.

## Motion and assets
Selection120ms, completion160ms, rest/content transition180ms; input availability follows logic, never animation. Brief changes explain selection/completion, no celebration delay.
Reduced motion gives immediate updates with check/status intact. No new sound/haptic preference is added. Keep existing optional timer-sound behavior.
No custom bitmap is needed for this workout. Reference food photos and doctor portraits are not appropriate logging assets.
Any later illustration needs purpose, composition, palette, aspect ratio, background, intended size and a separate generation prompt; unchecked technique instruction is excluded.

## Samples and scope labels
Strength —3 days; Lower body:
- Leg press:3×10 at80kg; note Feet shoulder-width apart.
- Dumbbell Romanian deadlift:3×10 at22.5kg; no note.
- Cable kickback:3×12 at12.5kg; note Pulley at knee level.
Finished example42min/9 completed sets; if volume is shown,3,525kg =2,400+675+450. Use stored weight×reps without an invented unilateral/dumbbell multiplier. These are display examples, not prescriptions.
Existing: Focus logging, notes, prefill, undo/edit/removal, added sets, overview, session additions/detail edits, rest, resume, finish, plan editing and saved detail.
Planned but omitted: session replacement/reordering, shared cross-plan identity, exercise trends/defined records.
Unapproved: starter plans, ad hoc/repeat workouts, timed/bodyweight-specific entry, dedicated warm-up/drop-set flows, supersets.
Excluded: accounts, social feeds, nutrition, AI coaching, subscriptions and backend.

## Review sequence
Review the generated light/dark workout pair together before extending the screen family. Both themes require deliberate surface and contrast choices; do not treat dark as automatic inversion. The user explicitly requested Stitch screens before any Flutter implementation. Do not reuse rejected style assets or perform another loose-variant batch.
Inspect actual rendered app-sized screen, not just generator claims or Behance hardware presentation. Then refine ready/completed/rest and derive dark/tablet counterparts; only after that extend to Today, Plans and Progress.
Token contrast checks are mathematical, not screen-reader/device/native keyboard validation. No Flutter UI changes, migration, commit, merge or publishing follow from this document alone.

