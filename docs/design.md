# Spottr design guide

## Direction

Calm, confident, and energetic. Favor clear hierarchy, generous spacing, and readable numbers.
Exact colors, typography, icons, and component shapes will be chosen through visual concepts.
The earlier warm-white/charcoal palette is a candidate, not a locked decision.

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
