# Spottr — reference fidelity review
12 October 2026. The user rejected the generated light/dark pair as substantially below the Behance references. No current generated visual is approved for implementation.

## Findings from actual reference artwork
Healthcare artwork inspected directly:
https://mir-s3-cdn-cf.behance.net/project_modules/1400_webp/1de7f7254164097.6a8e336e9674a.png
Original project:
https://www.behance.net/gallery/254164097/Healthcare-Mobile-App-Design
Nutrition reference:
https://www.behance.net/gallery/254567479/AI-Food-Calorie-Tracker-App-UIUX-Nutrition-Fitness

The healthcare screen uses a continuous pale gray background with a softly tinted upper area, a large sentence-case greeting, broad white rounded surfaces and visible stacked layering. Small secondary controls are integrated into the composition; cards vary by purpose. Its visual hierarchy reads as one composed screen.
The nutrition reference combines a white canvas and coral focus with strongly grouped progress content and friendly secondary controls. Its photographs, nutrition-specific graphics and phone presentation are not Spottr features.

Our drafts reduced these qualities to exact hex colors, uniform rounded fields and small metadata. The layout remained a generic logging form. Weight/reps wells competed with too many distinct rows, the header had little presence, supporting copy became small, and the reference's surface choreography was missing.
Color matching and accessibility-token arithmetic do not establish visual fidelity or design quality.

## Workflow correction
The available Stitch MCP tools support text prompts/design markdown but have no dedicated image-reference upload parameter. Including Behance URLs in a prompt did not establish that the generator visually ingested those references.
The user signed into the Stitch browser editor. Image file inputs are present, but two automated filechooser attempts timed out. Both direct artwork URLs were instead attached using Website URL. Stitch fetched both and accurately described distinctive content and labels not supplied in the inspection prompt. A new light workout is now being generated in that conversation using those fetched images as references. Reference files and attribution are in docs/design-references/README.md.
Google's [official Stitch announcement](https://developers.googleblog.com/en/stitch-a-new-way-to-design-uis/) documents uploading sketches/screenshots as image input. This supports trying the web image-input workflow; it does not establish that a URL in an MCP text prompt was visually ingested.
Use actual reference panels as visual context if supported; do not keep producing loose text-only recolors and asking the user to choose them.

## Art-direction corrections
- Start from reference composition and proportions, then adapt content; do not force the rejected row order or old component geometry.
- Give the exercise name real typographic presence, with readable note and last performance immediately associated.
- Group the current set, adjustments and logging into one broad coherent surface. Avoid layers of nested control cards and tiny separate badges.
- Use deliberate surface transitions and quiet stacking where they clarify ownership; reassess blanket styling bans against the user-approved reference qualities.
- Preserve friendly reachable controls and clear completed/prefilled meaning. Completion and correction must remain visible and one-tap unchanged logging preserved.
- Establish the light screen's composition before adapting dark surfaces/contrast. Dark remains a first-class design deliverable, not an inversion or an industrial variant.
- Do not add avatar/profile prerequisites, fitness coaching, nutrition features, decorative charts, photos or unavailable workout actions.

## Fixed constraints and review
Focus workout remains chosen; kg only, immediate optional note, previous completed performance, free exercise selection, edit/undo/removal undo, added sets, rest Skip/+30s and logging during rest, separate Finish/Discard, recoverable persistence.
Test design against long names, absent note, 320px width, large text, keyboard and large values. Static screenshot review does not verify native behavior.
The proposed exact palette, type and spacing remain revisable. Rebuild the shared visual spec only after a rendered reference-informed result passes review.
Earlier screens/files remain for history; no Flutter implementation, commits, merge or publish.

