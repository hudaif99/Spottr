# Spottr — fresh art direction
11 October 2026. All earlier concepts rejected by the user. Earlier token files remain archived proposals, not generation constraints.

## Approach
A new private Stitch project with no inherited design system or source-screen layout. Generate one original light workout screen, critically review it, then ask for user design feedback. No Flutter changes.

Project: 12966667488605345694 (Spottr — Fresh art direction).

## Generation prompt

```text
Create ONE original, finished light-mode Active Workout screen for Spottr. This is a fresh project; develop a new visual identity and design system yourself. No existing design system or reference layout is prescribed.

Spottr is a native Flutter workout logger for Android/iPhone. A tired person between demanding sets should immediately see what to do and log an unchanged set with one tap. The requested standard is a visually authored consumer product: beautiful typography, clear composition, confident use of space, restrained color, and controls that feel considered together. Avoid a template fitness dashboard or an industrial telemetry panel.

Creative direction:
- Own the palette, font choice/pairing, iconography, proportions, and composition. Make a coherent choice, not an accumulation of fashionable details.
- Give the exercise identity, current-set entry, completed work, and next action a visual relationship. Use alignment, rhythm, contrast, and shapes with purpose.
- Treat logging as the central interaction. Do not stack a large generic exercise card over a large generic value card and leave half the screen blank. Use the available phone space deliberately.
- Explore an original grouping of editable values, adjustment controls and completion action. Numbers can be expressive but should not overpower exercise context. Quiet does not mean faint.
- Avoid all-caps microcopy, military/extended display type, techno monospace everywhere, gratuitous tinted chips, dashboard badges, and decorative borders around every element.
- No athlete photography, diagrams, gradients, glass, glow, large button shadows, mascot, or motivational copy. An original vector detail is acceptable only if it helps communicate workout state.
- Make it feel like a thoughtfully crafted everyday tool, with warmth and subtle energy. Choose the actual aesthetics freely rather than interpreting that as a specific beige palette.
- Render only the app screen, no phone hardware, pitch board, design annotations, sample palette swatches or marketing title.

Actual content and capabilities (do not add new features):
Dedicated Lower body workout, outside main tabs. Back returns to Today and retains session. Separate Finish and workout options with Discard inside options.
Workout at 34 min; 7 of 9 sets logged. Free exercise navigation through labeled Workout overview. Other exercises are Leg press 3/3 and Dumbbell Romanian deadlift 3/3.
Current Cable kickback, optional user note Pulley at knee level visible immediately. Last session: 12.5 kg × 12 reps.
Current Set 2 of 3, 12.5 kg and 12 reps prefilled, explicitly uncompleted. Weight and reps can each be decreased/increased with large minus/plus controls; numbers can be tapped for direct entry. kg only. A clearly dominant Log set 2 action completes these unchanged values with ONE tap. No slider, swipe or hold requirement.
Completed Set 1: 12.5 kg × 12 reps. Identify it through a check/Logged label and make editing and undo/removal accessible. Add set available. Session detail edit accessible; logged exercise names may be locked. Do not force advancing exercise.
This is READY state: no rest timer is active. Do NOT show 'rest timer ready', 'auto-rest', '90s target', an inactive rest panel or similar placeholder/filler. The later active-rest state must support countdown, Skip and +30s while still allowing logging and showing the exercise context.
No muscle-target coaching, tempo, recommendations, records, charts, accounts, unit selectors, cardio duration/distance, supersets, replacement/reorder or other new functionality.

Design at 390×844 logical pixels with safe areas. Large readable note/context, strong text contrast; >=48px touch targets, larger primary logging/adjustment controls. Main exercise context, current-set controls and Log set action should all be visible at normal text size. Plan credible reflow at 320px, large text, long names and numeric entry; don't fake fit with tiny labels. Visually distinguish editable prefill and recorded sets without relying solely on color.

Before finishing, critique your own output: does it have recognizable authorship beyond a recolor of a familiar stacked-card UI? Is any content invented? Are four adjustment actions and one-tap logging clear? Are supporting labels readable? Remove unnecessary surfaces and filler. Deliver only ONE strong direction, not a set of minor variations.
```

## Review status
The first fresh generation was still card-heavy and was not adopted. A second serif draft added an unrequested Guide action and was not adopted. The current candidate is the Codex-led tonal composition in [stitch-authored-direction.md](stitch-authored-direction.md). User review remains pending.

