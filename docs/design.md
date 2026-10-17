# Spottr design guide

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
Keyboard-friendly exercise editing, consistent secondary screens and broader motion
remain future polish. Native device and screen-reader review remain required.

### Stitch directions — rejected history

The user provisionally accepted **Spottr · Reference-led Workout** on 12 October
2026 and requested a focused cleanup. This is the current working light anchor;
see the [image-reference pass](stitch-image-reference-pass.md) for the refinements.
The previous light/dark pair remains rejected. Dark mode and the connected screens
still need review before Flutter implementation. Exact tokens remain revisable.

The user agreed on 12 October 2026 to combine the healthcare reference's soft
composition and rounded forms with the nutrition reference's warmth and accent
treatment. All earlier generated concepts were rejected.

[DESIGN.md](../DESIGN.md) is the current shared specification, with
[semantic tokens](design-tokens.json) and the
[first reference-informed workout prompt](stitch-reference-workout-prompt.md).
The direction is agreed; the [previous pair](stitch-light-dark-review.md) is a
historical rejected exploration. Both themes must be designed before
Flutter implementation, with deliberate dark surface/contrast choices. Flutter
code remains on the earlier implementation theme until a slice is authorized.

## Direction

Soft cool-gray backgrounds, white rounded surfaces, crisp dark Inter typography,
coral primary actions with readable ink labels, and quiet sage completion feedback.
Use controlled neutral elevation on the main logging panel, open exercise context,
and quieter completed rows. Dark mode mirrors hierarchy using charcoal surfaces.
These tokens are proposed adaptations, not measurements extracted from Behance.
The references' photographs, tilted hardware, lighting and promotional presentation
do not belong in the logging UI. Keep source attribution in DESIGN.md.

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
