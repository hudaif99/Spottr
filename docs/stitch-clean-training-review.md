# Spottr — Clean Training exploration
13 October 2026. Status: rejected by the user. Continue with the existing Flutter UI.

The user rejected the earlier Stitch direction and supplied Home Workout and ClickUp as new references.
This pass creates a private, separate Stitch project. It does not change Flutter app code or approve a release design.

## Reference evidence
- [Home Workout](https://play.google.com/store/apps/details?id=homeworkout.homeworkouts.noequipment): visually inspected its exercise-sequence promotional screenshot. Borrow the clear exercise name/reps, readable white rows, and one obvious starting action.
- [ClickUp](https://play.google.com/store/apps/details?id=co.mangotechnologies.clickup): visually inspected its mobile home and inbox screenshots. Borrow disciplined row alignment, concise sections, quiet surfaces, small accent icons, and restrained lavender emphasis.
- Observations concern the app UI inside the promotional images. Athlete photos, hardware frames, marketing gradients, ads, coaching, workspace features, and branded assets are excluded.
- These are design adaptations, not exact sampled colors or fonts from the references.

## Review screens
Project: Spottr · Clean Training / October 13.
Resource: projects/11641049645513564059.

| Workout light | Workout dark |
| --- | --- |
| ![Workout light](https://lh3.googleusercontent.com/aida/AEtjO1WILWmEbADlX9jHhMZtwX58k6j6J1WTcUVfCRwqlMzWFwsxIwRw18D36-gr7ym2oWEyAS-7YOVPh6bOdB-Ybvjv_0al-PzEDfZ_c5rPudUZ1wZmb3ayEYPnQTmm2SJW2xYTaXni_ZuRQSLBVxFKeUIHszemwY2VQ1ojTvnw1vqL-LsgEEbCddwfXWosLbBSS31vNZuvoeAXoxwzcSAuXpMiGCwu6o_wDQTEG_749f17w_8b7F9_iohcF7nx) | ![Workout dark](https://lh3.googleusercontent.com/aida/AEtjO1UvNH57nYxTsLMobFhUeCBWaUvYgAm_aVCTMhU1kzwEqsWE1v-OcY8IosOZRGQGwy4xfGVmkTedkvM9FNyKWGUvq_RF1cg4lM63OWGVsoAhCXn-v4VyCTfJZwBrum0UtK19cby-7BybOb1IDSaoijvAyWIB4cUHCIoxvgfa6Cp0lf1gNmVHg4SdaX82IBxAPYgyGChox2-Ke8rZZHQMZ6zxjsxf2ELTDuZdGZYFkZiJWmiOOdh_q05HD4A) |

| Today light | Today dark |
| --- | --- |
| ![Today light](https://lh3.googleusercontent.com/aida/AEtjO1X506xnf90F9olcrj87IcGP8pdZanmrN_Ocev7VOqGcoRCT1LL6nAFRGKmrG2xDOyKhoLwGk0gZRLgvZRVwkykBTefJJQqcOzKK5_oHWh341E-SSXlRhiv-qyRjwKIx-2s7MlddfD9QBOfyTsN0KPfho6JCTEq8iA7psUTMWL7Apc22p12G5OUvFRFLJzdPVIxMDII18VLcD7VgN-rofKwujQDHDQyJZdErQfVjSh1mpJaTlWrQGmjw7WPS) | ![Today dark](https://lh3.googleusercontent.com/aida/AEtjO1VrRvAc8SDVcwsw7wVO4E_OcxIxroj_jeojqUMGFg5zQHNDqVSf4NoUs6Nj5lf1f1KtNPfQpSZOd8iwQdqHDKaEjv8G2tazmaNxC1dxXMSMJPtCRIxut2uXDEGOufMez3iZqSpTjchNnyGm3m1r-ETl6oxTShsj1JoY095xF5WiY-LKe3MIiBzNM4i008Nef-i-YxahzD8KS_TpuL9tmYJogdQmZSUzzEM83hJc6_grVp3u6vMmvK8H7_o) |

### Authoritative final screen resources
- Spottr · Workout · Light (Refined): projects/11641049645513564059/screens/6006ccda8f864d118a00c74394db2997
- Spottr · Today · Light (Refined): projects/11641049645513564059/screens/8433aa6a0cce4e0882b5d4f68bbffcbb
- Spottr · Workout · Dark (Refined): projects/11641049645513564059/screens/f96e6529784244e785eb2cc2cac297b4
- Spottr · Today · Dark (Refined): projects/11641049645513564059/screens/d46271e3ae2a4f01a53b6004b9c8dfaa

Earlier generated versions remain in the project; the resources above are the refined review set.

## Proposed visual system
Clean, approachable workout utility. DM Sans, clear numeric hierarchy, modest radii and functional violet.
Use open exercise context and weekly sections. Reserve a contained surface for the main logging/starting task.
Use consistent line icons with accessible labels. The small S mark is a concept, not a shipped app icon.

| Semantic role | Light proposal | Dark proposal |
| --- | --- | --- |
| Canvas | #F7F8FA | #17191F |
| Surface | #FFFFFF | #22252D |
| Raised control | #F7F8FA | #2E323D |
| Main text | #20232B | #F2F3F7 |
| Supporting text | #626975 | #B2B8C6 |
| Primary action | #6554C0 | #B9ADFF |
| Text on primary | #FFFFFF | #221A3C |
| Selected context | #EEEBF8 | #343048 |
| Completion | #237B69 | #85D4BF |
| Dark completion surface | — | #223A34 |

Colors are intended tokens. Stitch may deviate; reconcile actual renderings before implementation.
Typography: 400/500/600 primarily, sentence case, readable notes/context at least 14px, tabular numeric values.
Control radii approximately 12–18px; 48px minimum touch targets and 56px minimum primary CTA.
Those are requirements, not measurements verified from thumbnails.
Do not adopt Stitch's automatic system verbatim: it invented pounds, RPE/RIR and uppercase metadata conventions.
Our kg-only product rules and focused logging requirements take precedence.

## UX retained
- Focus one exercise/current set; one tap logs unchanged prefilled values.
- Setup note visible below the exercise name; previous completed performance nearby.
- Four adjustment controls, direct numeric entry, explicit Log set, Edit/Undo for completed work.
- Overview and free movement remain available. No forced exercise change.
- Finish/Discard stay separate from frequent actions.
- No main bottom tabs inside the active workout.
- Today has next workout, exercise sequence, Start, Change workout, quiet weekly information and last session.
- Today/Plans/Progress navigation stays simple.
- Sample values are illustrative, not real user activity or training prescriptions.
- Offline operation, optional notes, custom exercise names/suggestions, session recovery and safe saving remain required.

## Motion proposal for Flutter
- Immediate press feedback: 70–100ms.
- Completion check and row change: about 160ms, with Undo.
- Exercise changes: 180–220ms fade and short movement, preserving current input.
- Rest strip expansion: about 160ms, keeping logging available.
- Navigation: about 150ms fade.
- Reduced motion removes translation/scale and unnecessary animation. No animation blocks logging.
These are handoff specifications; static Stitch images do not verify working animations.

## Inspection and remaining limits
All four refined images were visually inspected in the browser.
Cleanup removed extra weight presets, RIR controls, invented duration estimates and unnecessary boxed weekly sections.
Dark workout still stacks the two value controls while light places them alongside each other.
Resolve that geometry according to width, not theme, during the next refinement/implementation.
Today dark still uses an uppercase section label and different weekday-marker geometry despite the
cleanup request. Reconcile those details before treating the themes as a shared final system.
Check minor generated exercise-position labels against the actual routine before using them.

Requested logical viewport was 390×844. Stitch returned raster metadata:
- Spottr · Workout · Light (Refined): 780×1768.
- Spottr · Today · Light (Refined): 780×1768.
- Spottr · Workout · Dark (Refined): 780×1876.
- Spottr · Today · Dark (Refined): 780×1768.
Do not equate those raster dimensions with a verified logical/native viewport.
No 320px reflow, keyboard, large text, contrast measurement, screen-reader or native interaction verification is claimed.
No Flutter files, assets, packages, Git branches or commits changed in this design pass.
Plans/Progress, rest/overview states, editor, onboarding, settings and tablet adaptation remain for later slices after direction review.

## Generation record
Initial light prompt and companion prompt are recorded in stitch-clean-training-prompts.md.
Two targeted cleanup passes corrected generator deviations.
Stitch's suggested follow-ups include rest/overview states, Plans/Progress companions, and exercise history;
they remain proposals rather than automatically approved scope.

