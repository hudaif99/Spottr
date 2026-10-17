# Spottr — Stitch workout prompt pack
Superseded for visual styling by stitch-visual-exploration.md. Retain the behavior/state inventory; do not generate these exact-style prompts until the selected direction is reflected here.
Status: foundation complete; first visual anchor pending generation/review.

## How to use
Apply the project design system created from root DESIGN.md. Paste the shared prefix followed by ONE numbered prompt. For MCP concatenate both and use its listed device type. Generate 01 first; review it with the user before generating 02–06. Use the reviewed anchor as the reference for derivatives. Other destinations follow later.

## Shared prefix

```text
Design a native mobile workout screen for Spottr, an offline Flutter app for Android and iOS. Apply the project's Spottr design system and the exact rules below. Produce a single actual app screen, not a presentation board, hardware mockup, website, or marketing page.
Warm athletic editorial: Outfit throughout, mineral #F6F4ED canvas, #FFFEF9 focused surface, #202D25 main text, #626B61 supporting text, forest #284638 primary action with #FFFEF9 label, restrained clay #9B5035 accent. Thin #DEDFD4 separators; essential control boundaries #7B8578. Open composition; only the current set needs a surfaced container. No gradients, photos, illustrations, glow, decorative badges, huge dashboard stats, or repeated cards.
390×844 logical-pixel phone canvas including safe areas. 24px gutters, spacing on a 4px grid, 16px focus radius, 12px control radius. Outfit exercise heading 32/38 medium; numbers 48/56 medium and tabular; body/notes 16/22; supporting text 14/20. Material Symbols Rounded 24px. All targets >=48px; step buttons 56px; primary action 64px minimum. Use labels and checks as well as color.
Top chrome: Back (returns to Today and retains session), Lower body, labeled Workout options, text Finish. Put Discard in workout options, never beside logging. No main tabs on this dedicated workout. Include exercise options beside the heading for session-only edits; logged names are locked. Completed rows have visible Edit and set options for undo/remove, wrapping into two lines when needed.
Keep Log set in the lower reachable area above the safe area, a reserved rest slot directly above it. Exercise context and current controls are visible together. Completed rows are quieter and may scroll. No overlap. Let text wrap and accommodate keyboard and text scaling; never truncate notes.
Existing behavior only: prefilled values do not count until logged, editing/undo/removal undo, added sets, overview and free exercise selection, rest Skip/+30s, logging during rest, resume and persistence retry. Never force exercise switching. Session edits affect this session; names with logged sets are locked. No accounts, coaching, PRs, charts, timed/cardio entry, supersets, or planned replacement/reordering.
Sample routine Strength — 3 days; Lower body: Leg press 3×10 at 80kg, note Feet shoulder-width apart; Dumbbell Romanian deadlift 3×10 at 22.5kg, no note; Cable kickback 3×12 at 12.5kg, note Pulley at knee level. kg only. No exercise technique imagery.
```

## 01 · Ready to log — light
Device: MOBILE

```text
Create the first visual anchor: Active workout — Ready to log, light.
Top metadata: 34 min · 7 of 9 sets logged with a thin 7/9 progress rule. Labeled trigger Exercise 3 of 3 · Overview.
Open exercise heading Cable kickback, visible note Pulley at knee level, supporting Last session · 12.5 kg × 12 reps.
Focused surface: Set 2 of 3, plain Prefilled label and From last session; equal weight and reps columns with large editable 12.5 and 12. Below the values place separate large outlined minus/plus pairs. Weight · kg and Reps labels are explicit.
Below show only Set 1 · 12.5 kg × 12 reps · check Logged and Edit; Add set as a quiet labeled action. Do not repeat set 2 in a table or label it completed.
Reserve the rest slot without displaying a fake timer or instructional filler. Bottom forest action check + Log set 2. One tap logs unchanged values; tapping numbers allows entry.
Prioritize impeccable alignment, clear hierarchy, reachability, and a distinctive calm identity. Make the primary action and all four step controls visible in the initial viewport.
Only generate this one screen. Do not generate derivatives yet.
```

## 02 · Set logged — light
Device: MOBILE

```text
Use the reviewed ready screen as the reference. Create its immediate completed-set state with identical chrome, alignment, and primary-action position.
Cable kickback remains selected; 35 min · 8 of 9 sets logged. Set 2 is now explicitly check Logged at 12.5 kg × 12 reps; a compact Set 2 logged · Undo confirmation remains visible without covering controls. Set 1 and Set 2 completed rows offer Edit and a labeled set options action; the latter includes Undo completion and Remove set. Do not depend on swipe.
The focus is now Set 3 of 3 · Prefilled · From last session, values 12.5kg / 12 reps. Bottom action Log set 3, ready for the next permitted input without animation delay. Reserved rest slot now contains Rest 1:30 with +30s and Skip. No modal, celebratory graphic, or automatic exercise navigation.
Motion specification for implementation: 160ms check/numeric transition; state changes are immediately available; reduced motion gives immediate replacement. Do not render motion annotations inside the product UI.
```

## 03 · Rest in progress — light
Device: MOBILE

```text
Use the reviewed ready screen as reference. Create Active workout — Rest in progress. Cable kickback remains selected, its note and previous performance visible. Metadata 35 min · 8 of 9 sets logged, Set 3 of 3 prefilled at 12.5kg / 12 reps, completed sets 1 and 2 quiet below.
Reserved lower rest strip: Rest 1:12, +30s and Skip with >=48px targets. Keep Log set 3 enabled subject to existing save rules; rest is not a gate. No timer takeover, pulsing ring, or disabled overlay. Do not relocate the logging action between states.
Motion: 180ms content transition within reserved slot; tabular countdown; no ticking live announcements. Reduced motion immediate. Keep interaction/motion commentary outside product UI.
```

## 04 · Ready to log — dark
Device: MOBILE

```text
Create the exact ready-to-log composition in dark mode: 34 min, 7/9 completed, Cable kickback, visible note, Last session 12.5kg ×12, Set 2 of 3 Prefilled, values 12.5 and 12, Set 1 Logged, Add set, Log set 2.
Override light colors with exact dark tokens: canvas #161C19, surface #222A25, subtle surface #2B352E, main text #F2F1E9, supporting #AFB8AE, primary #C6D6BA with #202D25 label, clay #E2AD8D, success #A9C79A, error #FFB4AB, error surface #3C2524, divider #384139, control boundary #7F8D80. Dark surfaces are flat and quiet, never black glass or neon. Preserve sizes, spacing, hierarchy and behavior from the reviewed light screen.
```

## 05 · Workout overview — phone
Device: MOBILE

```text
Create a phone workout overview sheet over the reviewed light workout. Show enough dimmed background to retain workout context, with a 24px-top-radius mineral sheet, labeled Close and Your workout · Lower body.
Exercise rows: Leg press — 3 of 3 sets logged; Dumbbell Romanian deadlift — 3 of 3 sets logged; Cable kickback — 1 of 3 sets logged, Selected. Wrap the long name. A vertical forest marker, Selected text, and selected semantics identify Cable kickback, not color alone. Selecting a row returns to that exercise with its progress intact.
Open list with thin separators; Add exercise as a labeled action. Session-only edit accessible in row options; no unrestricted renaming logged exercises. No reorder handles or Replace actions, because those remain planned. Do not add a second Finish next to Add exercise. No extra dashboard cards. Sheet scrolls and closes by visible control as well as platform gestures.
```

## 06 · Workout — tablet landscape
Device: TABLET

```text
Adapt the reviewed light workout to 1194×834 logical-pixel tablet landscape with safe areas. Header spans workout with Return to Today, Lower body, 34 min, 7/9 logged, text Finish, Workout options.
Left 300px overview: Your workout, Leg press 3/3, Dumbbell Romanian deadlift 3/3, Cable kickback 1/3 selected with vertical marker + Selected, Add exercise. Use open rows and thin separators. A vertical rule separates panes.
Right: center a focus column max 600px with Cable kickback heading, visible note, last session context, Set 2/3 Prefilled, weight 12.5kg/reps 12 and 56px step controls, completed Set 1 with Edit, Add set. Bottom of this column has reserved rest slot and Log set 2. Do not stretch numbers across the entire tablet. No app navigation rail inside dedicated workout. Narrow split view below 840px returns to phone overview trigger without resetting session or input.
```

## Targeted review prompts
Append each individually to the shared prefix, using the reviewed anchor. They are validation concepts, not training prescriptions or proof of native behavior.

### Compact width and long name
Create a 320×740 variant. Select Dumbbell Romanian deadlift, no note, Set 1/3 prefilled at 22.5kg/10 reps from plan targets. Overall 3/9 completed: Leg press 3/3, others 0/3. Wrap full name, 16px gutters, 56px controls, reachable Log set 1. No empty note gap; history may scroll.

### Large text and large numeric value
Create a 390×844 Leg press variant at 1.8× text, editable stress-test value 999.5kg/10 reps. Preserve font scaling, note and labels; grow rows and reflow controls vertically if needed. Action remains reachable by scrolling with safe inset. No truncation or tiny auto-scaled text.

### Native numeric keyboard
Open Weight · kg entry containing 12.5 with Cancel and Done, persistent label, validation area, decimal keyboard and bottom inset. Preserve workout behind dialog and do not cover fields/actions. Reps uses integer keyboard. Do not imply a new transactional completed-set save contract.

### Save failure
Inline error: Couldn't save this change. Keep this workout open and retry. Icon plus Retry, Save pending status; retain values and completion markers. Finish failure instead exposes Retry finishing and retains the session. No success summary, lost input, or misleading network message.

### Exercise completed
Cable kickback 3/3, workout 9/9, 42 min. All 3 sets logged with check, View workout and Add set; Finish remains in chrome. No automatic switching or invented fourth set. Completed rows remain editable and undoable.

### Finish confirmation
Adaptive confirmation: Finish workout?; 9 completed sets will be saved. Unfinished sets stay out of your totals.; Keep training and Finish. Await saving, retry failure without leaving. Discard has separate destructive confirmation.

### Set actions and removal undo
Logged row opens labeled sheet: Edit values, Undo completion, Remove set. Preserve existing warm-up marker if present without inventing dedicated workflow. Removal shows Set removed · Undo without covering main action; undo restores position and completion.

## Review record
- First light anchor generated in the private Spottr project and refined once; user review pending. Derivative prompts prepared, not generated until review.
- Stitch project: 1205024972169220711; design system: assets/3e2db55708cb44bca8043dc85d691cba; anchor: b40784fc2e964ba48f4411c09bdf09d6.
- First rendered preview was inspected. Refinement removed inactive-rest filler and the Prefilled badge and added options. The returned screenshot URL still represents the earlier preview; inspect the live Stitch canvas for the refined result.
- Stitch reports a 780×1768 raster (390×884 at 2×), despite a requested 390×844 logical viewport. Exact-height and compact-layout acceptance remain open.
- Verify visible context and Log set, one-tap unchanged entry, distinct prefilled/logged states, note readability, separated Finish, nonblocking rest, and minimum targets.
- Verify exact accounting, agreed tokens and no unapproved features.
- Flutter keyboard, reduced motion, device, persistence/recovery, screen-reader and iOS behavior remain unverified by Stitch.

