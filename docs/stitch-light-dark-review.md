# Spottr — light and dark workout review
12 October 2026. Both workout anchors were rejected by the user as below the Behance reference quality. Retained as history; not an approved visual direction. See stitch-reference-fidelity-review.md.

## Current Stitch project
Spottr — Behance direction · Light & Dark
Project: 9879336440749058644.
Generated design system: assets/5d3c2c11868747c5bc15398ce5dd1ec0.

## Current ready-state pair
- Light: projects/9879336440749058644/screens/6200cec310104db6beb53f09173a9a4c.
- Dark: projects/9879336440749058644/screens/8fffce94a85e433ba6944e1f1bf0c08e.
Earlier originals and the extra dark draft remain in the project. Use these cleaned screen IDs for further work.

| Light | Dark |
| --- | --- |
| ![Light workout](https://lh3.googleusercontent.com/aida/AEtjO1UjkvN5PjJVbNbGD0TgOWOKBaPAiuYsa2bnKmTzGke8jwUZOglDPP94fYHv0YXBohBinfOExV-oDSIZyPANDUJxBpGMuYPm0Ix4dvxbOPAW79VH_tKvVroWLlgeLIPGfXeCEPjQFRqvD1YVAfCOzkVV8lErAMcki-ocadDK8IUdxsPtFaG9EYXKCA6mZnyCc6kV0xO4XTF8QRVa6lxsy2FP9qFRl5LpoQAuuGN6JSUkxyrQYUDTgGoTcA) | ![Dark workout](https://lh3.googleusercontent.com/aida/AEtjO1WQg3ym76fFGbG1ppxJ4JsCPMG5cbFGTy-FBhZETXNY2KeJJBg0W5pcBt-LIiNJAn1vdgI8MZMOHyruTPJcE7YeNIKUNzpPRHfs20fJamkLlnTBtK7KGfLeaukTBppulmF2Qnc9Gaq0h88SZHDBxFxgMleUAs_ENUr3HSqvGTlBdaGfL4B7RncvZoM_iJBi69ZXENy2FYZ3N4E-7tTJvKQXqjQ5RRMOYvTHU6Zj4FJTj78LarN8jm-s8O8) |

## Direction
Light adapts the visually inspected Behance references: cool pale canvas, rounded white logging surface, restrained neutral depth and coral action.
Dark carries the same product identity through charcoal canvas/surface/control layers, readable supporting text, brighter values and warm coral with ink labels. It has independently specified tokens, not a simple inversion. No neon or colored shadow is intended.
Both preserve Cable kickback, visible Pulley at knee level note, previous12.5kg×12reps, Set2/3 prefilled, Set1 logged,7/9 overall and34min. Names and actions are proposals, not verified live functionality.
Cleanup removed the unrequested Reset control and colored light button shadow; dark CTA now matches the28px pill radius and64px requested minimum.

## Inspection and limitations
Both cleaned previews inspected in browser. No inactive-rest filler or invented coaching visible.
Light's Set1 label still wraps awkwardly; correction is open. Dark's completed label reads on one line. Typography and target measurements need full-size/native verification, not inference from thumbnail screenshots.
Tool raster metadata remains780×1768 (390×884 at2×) despite requested390×844. Exact viewport acceptance is open.
Behavior, keyboard/reflow, large text, screen readers, persistence and Android/iOS native execution are not verified by static Stitch output.

## Generation prompts
Light uses the reference-informed prompt with mobile-only presentation and no rejected style assets.
Dark shares content and geometry while overriding every theme role with the independent dark palette.

### Light prompt
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

Generate the LIGHT ready-to-log screen now, titled "Spottr · Workout · Light". The key visual qualities are those of the two Behance mobile UIs: sculpted rounded forms, soft neutral layering, precise readable sans-serif type, and vivid coral emphasis on one action. Do not reuse rejected forest, industrial, or split-ink layouts. Soft does not mean washed-out: body labels and context must be crisp and readable.
Keep the main current-set panel near the thumb area, connected visually to the exercise context. All parts of this one screen should feel intentionally composed, not a collection of generic component cards.
Render ONLY a mobile app viewport: body is the phone screen, 390 logical pixels wide, full bleed. No surrounding canvas, centered miniature phone, device border, drop shadow behind phone hardware, captions, or presentation background. The screen dimensions should represent the mobile screen itself, not a desktop webpage containing it.
A separate DARK counterpart will follow. Build coherent shapes and hierarchy that can translate to dark mode; do not generate that counterpart in this call. Avoid invented coaching and inactive rest placeholders.
```

### Dark prompt
```text
Create the DARK counterpart of "Spottr · Workout · Light", source screen projects/9879336440749058644/screens/0b833a983cc04a9aa2e39e5f5991b901, in this project. Title "Spottr · Workout · Dark". Generate only this one native phone screen, full bleed at 390×844 logical pixels including safe areas; no surrounding desktop canvas or phone hardware mockup.

Art direction: carry the same soft sculpted rounded forms, clear Inter type, friendly controls and refined spacing from the Behance-inspired light screen into a carefully designed night appearance. Adapt tonal depth and emphasis; do not perform automatic RGB inversion or add a neon/industrial personality.
Charcoal canvas #171A1F, main logging surface #22262D, lighter control wells #2D333C, main text #F3F5F7, supporting text #B8C0C9. Warm coral action #FF977D with DARK ink label #202329. Completion uses text/check #A8D9B9 on subtle #243B2E. Decorative separators #3A424D; essential outlines where needed #85919F. These dark tokens override the light design-system defaults.
Separate surfaces through intentional tone, not shadows, colored glow or rim lighting. Give exercise notes and previous values clear supporting contrast, not washed-out opacity. Coral should emphasize the Log action without filling every control. Soft gray step circles with readable icons, same >=48px/56px targets. Inter: exercise30/36 semibold, body16/24, support14/20, values44/52 tabular, action17/24 semibold.

Keep exact journey and data:
Top Back/Lower body/separate Finish/workout options. Back retains session; Discard only in options. 34 min ·7 of9 sets logged, thin progress, labeled Workout overview ·Exercise3of3.
Cable kickback heading and session exercise options; note Pulley at knee level visible; Last session ·12.5kg×12reps.
Completed Set1 row with check+Logged,12.5kg×12reps, Edit and Set options for undo/remove. Keep Set1 label on one line or intentionally move whole label to a second row; do not awkwardly break 'Set' and '1'. Quiet Add set.
Lower reachable rounded logging surface: Set2of3 ·Prefilled. Weight·kg12.5 and Reps12, direct entry and four56px minus/plus controls. Full-width64px coral Log set2. Use same locations and hierarchy as light. No tiny uppercase metadata or repeated nested decorative cards; gray control wells are functional and flat.
Ready state has no active rest timer. No inactive-rest filler. Rest later can show countdown/Skip/+30s while retaining context and logging availability.
One tap logs unchanged values; prefilled values never count until logged. Completed sets editable and undoable. No forced exercise switch. Logged names may be locked; session-only detail edits.
Remove the unrequested Reset control from the light draft; do NOT reproduce it here. Remove colored button shadow. No Guide, coaching, tempo, records, calorie gauge, new features, unit selection, replacement/reorder, main tabs, accounts or backend.
Show context, notes, both values, four adjustment controls and Log action together at normal text scale. Honor bottom safe area and 320px/large-text reflow.
Deliver a sophisticated, calm dark companion to the light app, with an equally clear next action.
```

## Next design slice
Review this pair together first. Refine visual hierarchy and remaining wrapping issues; then generate completed/rest/overview and tablet workout states. Continue Today/resume, Plans/day content, plan/exercise editors and Progress/details once the workout identity is coherent.
Both themes remain first-class across all later screens. Flutter implementation follows design review, with existing behavior/data/recovery preserved. No Flutter code, dependency, commit, merge or publish in this slice.

