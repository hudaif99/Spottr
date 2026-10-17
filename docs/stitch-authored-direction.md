# Spottr — authored visual direction
11 October 2026. Candidate for user review; not approved for implementation.

## Design decision
The user asks Codex to lead the art direction without requiring external references.
Use a pale stone context zone and continuous deep-ink logging zone, with an apricot primary action. DM Sans provides a clear sans-serif heading and large tabular workout values. The tonal split, useful grouping and open context establish identity rather than decorative cards.

| Role | Candidate color |
| --- | --- |
| Upper background | #F3F5F4 |
| Upper main text / lower field | #182F3D |
| Upper secondary text | #52636A |
| Lower primary text | #F4F7F6 |
| Lower secondary text | #C0CED0 |
| Log set action | #FFB38A |
| Action text | #182F3D |

Typography: DM Sans; exercise 38/44 weight600, body16/23, supporting15/22, set numbers56 tabular, action17 semibold.
Controls: minimum48px, steppers56px, Log set64px; 24px gutters; open upper composition, continuous lower field with optional24px top corners. No nested value cards.
Dark theme and tablet adaptations are deferred until direction review.

## Generation
Private project: 12966667488605345694.
Screen: projects/12966667488605345694/screens/02d2a7c4469c4f8ca33dd50b1f850eca.
[Rendered preview](https://lh3.googleusercontent.com/aida/AEtjO1Xjlvc3S7kr2AlroRdYKSEOMu1wLfH6BO3iZEYs-s_aT3zG4B86TmsBW8BnTEw9uURYUID5blJvzr9egUJZJxEmNUIyQu13lPrAIjg7qwvFASibKut2C_BRhilehfCIENuY1TWi_KTgWWh_dglvvrde4jSw1D3hWoC08CWkB7MboZ5Lbefp3rKMZ9M1fMMPnX1nbh0daSgL2tefyDhWCWZflTNGioVRKqkCWsQpABWDifqCiuRvTai9Peoo).

## Exact prompt
```text
Create one precisely art-directed native Spottr Active Workout screen. Use the following original art direction as authoritative; replace all earlier project design-system defaults. This is a specific composition, not a beige editorial card theme.

Visual identity:
Pale stone upper canvas #F3F5F4; deep ink #182F3D lower logging field; apricot #FFB38A primary action with #182F3D text. Upper text #182F3D; secondary #52636A. Lower main text #F4F7F6; supporting #C0CED0. No gradients/glow/shadows/photography. Typeface DM Sans throughout, high-quality sans-serif hierarchy, no serif/italic headline, techno type or uppercase metadata.
Use the tonal split to create a distinctive silhouette. The LOWER LOGGING FIELD is a full-width continuous zone to the bottom safe area, not a small floating rounded card. The upper context is entirely open, no card containers. Rounded shapes are reserved for actual controls. No card nested inside card.

Exact reference layout: 390×844 logical pixels including safe areas. Raster may be 2× but layout must be 844 high.
- Top safe area + 56px chrome: back with accessible Return to Today, Lower body (18px semibold), separate text Finish and options ellipsis (48px targets).
- Compact progress line: 34 min at left, 7 of 9 sets logged at right (15px), thin progress rule. Under it a 48px labeled Workout overview · Exercise 3 of 3 trigger. No main tabs.
- Open exercise identity with 24px gutters: Cable kickback (DM Sans 38px/44, weight 600, slight negative tracking; wrap naturally); a 48px Session exercise options target. Setup note Pulley at knee level (16px/23), immediately visible. Last session · 12.5 kg × 12 reps (15px/22).
- One understated completed-work row on the pale upper canvas before the logging field: check + Set 1 logged, 12.5 kg × 12 reps, Edit and labeled set options. Use two lines if needed to keep >=48px action targets. Quiet Add set action alongside/below. No completed-work card.
- Start deep-ink logging field in the lower half, adjusting exact split position so context and controls all fit. 24px inner gutters, slight 24px top corners are acceptable; flush to edges and bottom safe area. No outlines/shadows.
- Set 2 of 3 · Prefilled header, clear 16px contrasting text. Not logged. This is the only main editable set.
- Weight · kg and Reps labeled columns. Values 12.5 and 12 in 56px DM Sans medium, tabular numerals, white against ink. Subtle vertical separator optional. Do NOT put numbers in separate inset cards.
- Four minus/plus controls: 56px touch targets with quiet lighter-ink filled backgrounds and readable white icons. Each number is also editable by tapping for direct entry. Weight changes in 2.5kg steps, reps by 1.
- Apricot full-width 64px minimum Log set 2 button near bottom, with clear dark 17px semibold label + check. It is ONE tap for unchanged prefilled values. Do not put the button at mid-screen or detach it beneath a vast empty region.
- Retain safe bottom inset. Use deliberate spacing and visual rhythm across the two zones; don't fill space with explanatory copy or decoration.

Behavior:
Cable kickback, current set2/3 at12.5kg/12. Previously completed exercises Leg press3/3 and Dumbbell Romanian deadlift3/3. Overall7/9. Only explicit completed sets count; prefill must be distinct.
Free exercise navigation through overview; no forced change. Completed sets editable, undo completion/removal accessible from options. Add set available. Session edits affect only workout; names with logged sets locked.
Ready state: no rest timer active. No 'rest ready', 'auto-rest', '90s target' or other inactive placeholder. Later active rest sits within logging field, with Skip/+30s and logging still possible.
Finish is separate from Log set; discard only in options. Back retains session.
DO NOT add Guide, instructions, coaching, tempo, muscle labels, records, new stats, suggestions, unit toggle, reorder, replacement, charts, accounts or backend features.
No side-panel explanation or phone hardware frame; only the real app screen.

Quality:
Readable body size and contrast, full notes, generous controls. On320px or enlarged text, wrap/reflow and allow scroll, don't shrink fonts/touch areas. Preserve core viewport visibility at normal scale. Use the upper open context + lower continuous ink logging field as the defining composition. The result should look intentionally designed, distinctive, clean and buildable in Flutter.
```

## Review findings
Inspected the rendered output. It follows the pale-context/deep-ink split, readable exercise note, completed row, unboxed current values, four adjustment controls and apricot Log set. No inactive-rest filler or invented coaching is visible.
The generator returned a presentation canvas with an inset phone-sized screen and subtle shadow, despite requesting only the app screen. Metadata is 2560×2048; exact logical viewport is not confirmed. Presentation wrapper must not ship. Actual touch targets, keyboard handling, compact-width layout, text scaling, contrast on rendered fonts, screen readers and Flutter/native behavior still need verification.
Earlier exploratory drafts in this project remain unapproved: Kinetic Chalk was too card-heavy; the subsequent serif draft added a Guide action and was not adopted. This authored candidate should drive further refinement only after user feedback.
No app code changed. Preserve product behavior, BLoC/get_it, Hive identifiers, serialized persistence and recovery. Shared DESIGN.md/tokens should be rebuilt after visual selection, not automatically copied from Stitch-generated metadata.

## Next review
Judge the composition, visual character, readable context and reachable logging. If selected, refine the phone-only export, complete ready/rest/edit/error states, and then derive light/dark tokens and tablet behavior. No additional destinations or features are approved by this artifact.

