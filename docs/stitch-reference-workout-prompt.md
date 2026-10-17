# Spottr — reference-informed workout prompt
12 October 2026. The user authorized Stitch generation before Flutter implementation. This prompt produced the light anchor; see stitch-light-dark-review.md for the current cleaned light/dark pair and dark prompt. Visual review pending.

## Source
Root DESIGN.md is the current system. Older Stitch style assets and prompts were rejected. Start a clean reference-informed generation; do not apply those assets.

## Copy-ready prompt

```text
Create one native Spottr Active Workout screen using the agreed reference-inspired direction. Design for Flutter Android/iOS at 390 × 844 logical pixels including safe areas. This is a visual proposal, not a web application. No hardware mockup, presentation board or promotional artwork.

Visual references:
https://www.behance.net/gallery/254164097/Healthcare-Mobile-App-Design
https://www.behance.net/gallery/254567479/AI-Food-Calorie-Tracker-App-UIUX-Nutrition-Fitness
The first contributes soft gray/light surfaces, broad rounded sections and confident hierarchy. The second contributes white surfaces, coral emphasis and friendly softly elevated controls. Adapt their actual mobile UI qualities to workout logging. Do not copy healthcare/nutrition features or presentation photography. URLs are attribution/context; do not claim to have visually ingested them unless image access actually succeeds. Use supplied screen crops if the generation interface supports visual references.

Proposed precise system:
Cool-gray canvas#F5F6F7, white#FFFFFF main surface, subtle gray#ECEFF1 controls, ink#202329, supporting#60666E. Coral#F46B4B primary action with INK#202329 label; accent text#A83B25. Completion#34694A on#E6F2E9. Inter typography: exercise30/36 semibold, note16/24 regular, supporting14/20 regular, values44/52 semibold tabular, action17/24 semibold.
20px gutters (16px on320px), 4px spacing rhythm, main surface24px corners, primary button28px radius,56px soft-gray step controls,64px primary action. Use at most a restrained neutral4% black shadow for the main logging surface. Essential control boundaries, if required, use#7A848E. No tiny all-caps labels, gradients, colored glow, industrial outlines, decorative badges or repeated card grids.

Composition, top to bottom:
1. Back, Lower body, separate text Finish and workout options. Back retains resumable session; Discard lives in options. No main navigation tabs here.
2. Compact34min /7of9 sets logged line and thin progress rule. Labeled Workout overview · Exercise 3 of 3 trigger.
3. Open exercise context: Cable kickback, session exercise options; visible Pulley at knee level note; Last session ·12.5kg×12reps. No separate exercise card or hero image.
4. Quiet completed Set 1 row: check+Logged,12.5kg×12reps, Edit and set options for Undo completion/Remove; Add set labeled. Use two lines where needed; preserve48px targets. Do not repeat the uncompleted current set in this ledger.
5. One broad soft white logging panel near the lower reachable area. Header Set 2 of 3 · Prefilled. Aligned Weight ·kg and Reps columns; editable12.5 and12; four56px gray minus/plus controls as a cohesive group, without nested value cards. Numbers support direct entry.
6. Full-width coral check+Log set 2 inside panel above safe area,64px, readable ink label, one tap for unchanged values. Finish stays separate in chrome. The action anchors while body/panel content can scroll/reflow at short heights; do not cover inputs or notes or leave a vast decorative gap.

State and behavior:
Ready state, no countdown active. Do not show 'rest ready', 'auto-rest', '90s target' or similar filler. Later rest strip appears above Log set with countdown/Skip/+30s and allows logging; exercise context remains visible.
Current set uncompleted; earlier Leg press 3/3 and Dumbbell Romanian deadlift 3/3, current Cable kickback 1/3 give 7/9 overall. Prefill never counts until explicit completion. kg only.
Completed work editable and undoable; removed sets have Undo; free exercise selection; no automatic exercise change. Session-only edits, logged names may be locked. Preserve existing offline/save/resume/finish contracts.
No Guide, tempo, muscle coaching, charts/records, avatar prerequisite, calorie-style gauge, new features, unit toggle, reorder/replacement, AI, accounts or backend.
At ordinary text size show exercise/note/previous performance, both values, all four adjustment controls and Log set in initial viewport. Plan 320px, long names, large values and large-text reflow; never shrink text/targets to fake fit.
Judge the rendered screen on alignment, balanced rounded geometry, readable supporting text, deliberate soft depth and a clear next action. Return only one actual phone UI screen.
```

## Review gate
Generate one light ready screen first. Inspect the actual viewport, useful context, single-tap logging, completed/prefilled distinction, targets and typography. No inactive-rest filler, speculative features or Behance hardware presentation. Only then refine ready/completed/rest and dark/tablet counterparts before other destinations. Native behavior still requires Flutter/device verification.

